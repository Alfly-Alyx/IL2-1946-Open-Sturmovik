/*
 * Open Sturmovik cached wrapper for the 32-bit IL-2 1946 4.09m modded EXE.
 *
 * Hashing and loose-file lookup semantics are derived from SAS IL-2 Wrapper
 * 3.3.0 by SAS~Storebror, distributed under DWTFYWWI 1.01. See LICENSE.txt.
 *
 * This variant fixes the 4.09m ABI, initializes outside DllMain, writes caches
 * atomically and rejects a stale cache whenever the directory topology changes.
 */

#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0501
#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <io.h>

#include "sfs.h"

#define CACHE_FORMAT "OSWRAPCACHE1"
#define MANIFEST_FORMAT "OSWRAPDIRS1"
#define CACHE_DIRECTORY ".open-sturmovik-cache"
#define PATH_BUFFER 4096
#define LINE_BUFFER 8192

typedef unsigned int (__cdecl *SFS_OPEN)(char *filename, int flags);
typedef unsigned int (__cdecl *SFS_OPENF)(unsigned __int64 hash, int flags);

typedef struct FileEntry {
    unsigned __int64 hash;
    char *path;
    unsigned int order;
} FileEntry;

static FileEntry *g_entries = NULL;
static size_t g_entry_count = 0;
static size_t g_entry_capacity = 0;
static unsigned int g_next_order = 0;
static SFS_OPEN g_sfs_open = NULL;
static SFS_OPENF g_sfs_openf = NULL;
static char g_exe_directory[PATH_BUFFER];
static volatile LONG g_init_state = 0;

static int path_printf(char *buffer, size_t size, const char *format, const char *a, const char *b)
{
    int written = _snprintf(buffer, size, format, a, b);
    if (written < 0 || (size_t)written >= size) {
        if (size != 0) buffer[size - 1] = '\0';
        return 0;
    }
    return 1;
}

static int join_path(char *buffer, size_t size, const char *left, const char *right)
{
    size_t length = strlen(left);
    const char *separator = (length != 0 && (left[length - 1] == '\\' || left[length - 1] == '/')) ? "" : "\\";
    int written = _snprintf(buffer, size, "%s%s%s", left, separator, right);
    if (written < 0 || (size_t)written >= size) {
        if (size != 0) buffer[size - 1] = '\0';
        return 0;
    }
    return 1;
}

static int is_none(const char *value)
{
    return value == NULL || value[0] == '\0' || _stricmp(value, "none") == 0;
}

static int directory_exists(const char *path)
{
    DWORD attributes = GetFileAttributesA(path);
    return attributes != INVALID_FILE_ATTRIBUTES && (attributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
}

static int safe_relative_path(const char *path)
{
    const char *cursor;
    if (path == NULL || path[0] == '\0' || path[0] == '\\' || path[0] == '/' || strchr(path, ':') != NULL) return 0;
    cursor = path;
    while (*cursor != '\0') {
        if ((cursor == path || cursor[-1] == '\\' || cursor[-1] == '/') &&
            cursor[0] == '.' && cursor[1] == '.' &&
            (cursor[2] == '\0' || cursor[2] == '\\' || cursor[2] == '/')) return 0;
        ++cursor;
    }
    return 1;
}

static unsigned __int64 file_time_value(const FILETIME *time)
{
    ULARGE_INTEGER value;
    value.LowPart = time->dwLowDateTime;
    value.HighPart = time->dwHighDateTime;
    return value.QuadPart;
}

static int directory_stamp(const char *path, unsigned __int64 *stamp)
{
    WIN32_FILE_ATTRIBUTE_DATA data;
    if (!GetFileAttributesExA(path, GetFileExInfoStandard, &data)) return 0;
    if ((data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0) return 0;
    *stamp = file_time_value(&data.ftLastWriteTime);
    return 1;
}

static void rollback_entries(size_t original_count)
{
    while (g_entry_count > original_count) {
        --g_entry_count;
        free(g_entries[g_entry_count].path);
        g_entries[g_entry_count].path = NULL;
    }
}

static int add_entry(unsigned __int64 hash, const char *path, FILE *cache)
{
    FileEntry *resized;
    size_t length;
    char *copy;
    if (g_entry_count == g_entry_capacity) {
        size_t capacity = g_entry_capacity == 0 ? 4096 : g_entry_capacity * 2;
        resized = (FileEntry *)realloc(g_entries, capacity * sizeof(FileEntry));
        if (resized == NULL) return 0;
        g_entries = resized;
        g_entry_capacity = capacity;
    }
    length = strlen(path);
    copy = (char *)malloc(length + 1);
    if (copy == NULL) return 0;
    memcpy(copy, path, length + 1);
    g_entries[g_entry_count].hash = hash;
    g_entries[g_entry_count].path = copy;
    g_entries[g_entry_count].order = g_next_order++;
    ++g_entry_count;
    if (cache != NULL && fprintf(cache, "%016I64X?%s\n", hash, path) < 0) return 0;
    return 1;
}

static unsigned __int64 sfs_hash(unsigned __int64 hash, const void *buffer, int length)
{
    const unsigned char *bytes = (const unsigned char *)buffer;
    unsigned int a = (unsigned int)(hash & 0xFFFFFFFFu);
    unsigned int b = (unsigned int)((hash >> 32) & 0xFFFFFFFFu);
    int i;
    for (i = 0; i < length; ++i) {
        unsigned char c = bytes[i];
        a = (a << 8 | c) ^ FPaTable[a >> 24];
        b = (b << 8 | c) ^ FPbTable[b >> 24];
    }
    return ((unsigned __int64)a & 0xFFFFFFFFu) | ((unsigned __int64)b << 32);
}

static unsigned int int_fn(unsigned int initial, const char *text)
{
    unsigned int a = initial;
    const unsigned char *cursor = (const unsigned char *)text;
    while (*cursor != 0) {
        unsigned int c = *cursor++;
        a = (a << 8 | (c & 0xFFu)) ^ FPaTable[a >> 24];
        a = (a << 8) ^ FPaTable[a >> 24];
    }
    return a;
}

static unsigned __int64 long_fn(unsigned __int64 initial, const char *text)
{
    unsigned int a = (unsigned int)(initial & 0xFFFFFFFFu);
    unsigned int b = (unsigned int)((initial >> 32) & 0xFFFFFFFFu);
    const unsigned char *cursor = (const unsigned char *)text;
    while (*cursor != 0) {
        unsigned int c = *cursor++;
        if (c > 96 && c < 123) c &= 223;
        else if (c == '/') c = '\\';
        a = (a << 8 | c) ^ FPaTable[a >> 24];
        b = (b << 8 | c) ^ FPbTable[b >> 24];
    }
    return ((unsigned __int64)a & 0xFFFFFFFFu) | ((unsigned __int64)b << 32);
}

static int is_hex_class_name(const char *name)
{
    size_t i;
    if (strlen(name) != 16) return 0;
    for (i = 0; i < 16; ++i) {
        if (!isxdigit((unsigned char)name[i])) return 0;
    }
    return 1;
}

static int ends_with_class(const char *name)
{
    size_t length = strlen(name);
    return length > 6 && _stricmp(name + length - 6, ".class") == 0;
}

static unsigned __int64 loose_file_hash(const char *virtual_name, const char *file_name)
{
    char work[PATH_BUFFER];
    size_t i;
    if (is_hex_class_name(file_name)) return _strtoui64(file_name, NULL, 16);
    if (ends_with_class(file_name)) {
        char class_seed[PATH_BUFFER];
        char cod_seed[64];
        size_t length = strlen(virtual_name) - 6;
        if (length >= sizeof(work)) length = sizeof(work) - 1;
        memcpy(work, virtual_name, length);
        work[length] = '\0';
        for (i = 0; work[i] != '\0'; ++i) {
            if (work[i] == '\\' || work[i] == '/') work[i] = '.';
        }
        if (!path_printf(class_seed, sizeof(class_seed), "sdw%scwc2w9e", work, "")) return 0;
        _snprintf(cod_seed, sizeof(cod_seed), "cod/%d", (int32_t)int_fn(0, class_seed));
        cod_seed[sizeof(cod_seed) - 1] = '\0';
        return long_fn(0, cod_seed);
    }
    strncpy(work, virtual_name, sizeof(work) - 1);
    work[sizeof(work) - 1] = '\0';
    CharUpperBuffA(work, (DWORD)strlen(work));
    return sfs_hash(0, work, (int)strlen(work));
}

static int write_directory_stamp(FILE *manifest, const char *full_path, unsigned int *count)
{
    unsigned __int64 stamp;
    const char *relative;
    if (manifest == NULL) return 1;
    if (!directory_stamp(full_path, &stamp)) return 0;
    if (_strnicmp(full_path, g_exe_directory, strlen(g_exe_directory)) != 0) return 0;
    relative = full_path + strlen(g_exe_directory);
    while (*relative == '\\' || *relative == '/') ++relative;
    if (!safe_relative_path(relative)) return 0;
    if (fprintf(manifest, "%016I64X?%s\n", stamp, relative) < 0) return 0;
    ++*count;
    return 1;
}

static int scan_tree(const char *full_directory, const char *root_directory,
                     const char *open_prefix, FILE *cache, FILE *manifest,
                     unsigned int *cache_count, unsigned int *directory_count)
{
    WIN32_FIND_DATAA data;
    HANDLE find;
    char pattern[PATH_BUFFER];
    char full_path[PATH_BUFFER];
    char open_path[PATH_BUFFER];
    const char *virtual_name;
    size_t root_length = strlen(root_directory);
    int ok = 1;
    if (!write_directory_stamp(manifest, full_directory, directory_count)) return 0;
    if (!join_path(pattern, sizeof(pattern), full_directory, "*")) return 0;
    find = FindFirstFileA(pattern, &data);
    if (find == INVALID_HANDLE_VALUE) return GetLastError() == ERROR_FILE_NOT_FOUND;
    do {
        if (strcmp(data.cFileName, ".") == 0 || strcmp(data.cFileName, "..") == 0) continue;
        if (!join_path(full_path, sizeof(full_path), full_directory, data.cFileName)) { ok = 0; break; }
        if ((data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
            if (!scan_tree(full_path, root_directory, open_prefix, cache, manifest, cache_count, directory_count)) { ok = 0; break; }
            continue;
        }
        virtual_name = full_path + root_length;
        while (*virtual_name == '\\' || *virtual_name == '/') ++virtual_name;
        if (!join_path(open_path, sizeof(open_path), open_prefix, virtual_name)) { ok = 0; break; }
        if (!add_entry(loose_file_hash(virtual_name, data.cFileName), open_path, cache)) { ok = 0; break; }
        ++*cache_count;
    } while (FindNextFileA(find, &data));
    if (ok && GetLastError() != ERROR_NO_MORE_FILES) ok = 0;
    FindClose(find);
    return ok;
}

static int scan_files_root(const char *root_name, FILE *cache, FILE *manifest,
                           unsigned int *cache_count, unsigned int *directory_count)
{
    char full_root[PATH_BUFFER];
    if (!join_path(full_root, sizeof(full_root), g_exe_directory, root_name)) return 0;
    return scan_tree(full_root, full_root, root_name, cache, manifest, cache_count, directory_count);
}

static int scan_mods_root(const char *root_name, FILE *cache, FILE *manifest,
                          unsigned int *cache_count, unsigned int *directory_count)
{
    WIN32_FIND_DATAA data;
    HANDLE find;
    char full_root[PATH_BUFFER];
    char pattern[PATH_BUFFER];
    int ok = 1;
    if (!join_path(full_root, sizeof(full_root), g_exe_directory, root_name)) return 0;
    if (!write_directory_stamp(manifest, full_root, directory_count)) return 0;
    if (!join_path(pattern, sizeof(pattern), full_root, "*")) return 0;
    find = FindFirstFileA(pattern, &data);
    if (find == INVALID_HANDLE_VALUE) return GetLastError() == ERROR_FILE_NOT_FOUND;
    do {
        char mod_full[PATH_BUFFER];
        char open_prefix[PATH_BUFFER];
        if (strcmp(data.cFileName, ".") == 0 || strcmp(data.cFileName, "..") == 0 || data.cFileName[0] == '-') continue;
        if ((data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0) continue;
        if (!join_path(mod_full, sizeof(mod_full), full_root, data.cFileName) ||
            !join_path(open_prefix, sizeof(open_prefix), root_name, data.cFileName) ||
            !scan_tree(mod_full, mod_full, open_prefix, cache, manifest, cache_count, directory_count)) {
            ok = 0;
            break;
        }
    } while (FindNextFileA(find, &data));
    if (ok && GetLastError() != ERROR_NO_MORE_FILES) ok = 0;
    FindClose(find);
    return ok;
}

static void trim_line(char *line)
{
    size_t length = strlen(line);
    while (length > 0 && (line[length - 1] == '\r' || line[length - 1] == '\n')) line[--length] = '\0';
}

static int validate_manifest(const char *path, const char *root_name)
{
    FILE *file = fopen(path, "rb");
    char line[LINE_BUFFER];
    char expected_header[PATH_BUFFER];
    unsigned int count = 0;
    int footer_seen = 0;
    if (file == NULL) return 0;
    _snprintf(expected_header, sizeof(expected_header), "#%s?%s", MANIFEST_FORMAT, root_name);
    expected_header[sizeof(expected_header) - 1] = '\0';
    if (fgets(line, sizeof(line), file) == NULL) goto invalid;
    trim_line(line);
    if (strcmp(line, expected_header) != 0) goto invalid;
    while (fgets(line, sizeof(line), file) != NULL) {
        char *separator;
        char full_path[PATH_BUFFER];
        unsigned __int64 cached_stamp;
        unsigned __int64 current_stamp;
        size_t i;
        trim_line(line);
        if (strncmp(line, "#END?", 5) == 0) {
            unsigned long expected_count = strtoul(line + 5, NULL, 10);
            if (expected_count != count) goto invalid;
            footer_seen = 1;
            break;
        }
        if (strlen(line) < 18 || line[16] != '?') goto invalid;
        for (i = 0; i < 16; ++i) if (!isxdigit((unsigned char)line[i])) goto invalid;
        separator = line + 16;
        *separator++ = '\0';
        if (!safe_relative_path(separator)) goto invalid;
        cached_stamp = _strtoui64(line, NULL, 16);
        if (!join_path(full_path, sizeof(full_path), g_exe_directory, separator)) goto invalid;
        if (!directory_stamp(full_path, &current_stamp) || current_stamp != cached_stamp) goto invalid;
        ++count;
    }
    fclose(file);
    return footer_seen && count != 0;
invalid:
    fclose(file);
    return 0;
}

static int read_cache(const char *path, const char *root_name)
{
    FILE *file = fopen(path, "rb");
    char line[LINE_BUFFER];
    char expected_header[PATH_BUFFER];
    size_t original_count = g_entry_count;
    unsigned int count = 0;
    int footer_seen = 0;
    if (file == NULL) return 0;
    _snprintf(expected_header, sizeof(expected_header), "#%s?%s", CACHE_FORMAT, root_name);
    expected_header[sizeof(expected_header) - 1] = '\0';
    if (fgets(line, sizeof(line), file) == NULL) goto invalid;
    trim_line(line);
    if (strcmp(line, expected_header) != 0) goto invalid;
    while (fgets(line, sizeof(line), file) != NULL) {
        char *path_part;
        unsigned __int64 hash;
        size_t i;
        trim_line(line);
        if (strncmp(line, "#END?", 5) == 0) {
            unsigned long expected_count = strtoul(line + 5, NULL, 10);
            if (expected_count != count) goto invalid;
            footer_seen = 1;
            break;
        }
        if (strlen(line) < 18 || line[16] != '?') goto invalid;
        for (i = 0; i < 16; ++i) if (!isxdigit((unsigned char)line[i])) goto invalid;
        path_part = line + 17;
        if (!safe_relative_path(path_part)) goto invalid;
        line[16] = '\0';
        hash = _strtoui64(line, NULL, 16);
        if (!add_entry(hash, path_part, NULL)) goto invalid;
        ++count;
    }
    fclose(file);
    if (!footer_seen) { rollback_entries(original_count); return 0; }
    return 1;
invalid:
    fclose(file);
    rollback_entries(original_count);
    return 0;
}

static int flush_file(FILE *file)
{
    return fflush(file) == 0 && _commit(_fileno(file)) == 0;
}

static int load_or_build_root(const char *root_name, const char *cache_key, int mods_style, int use_cache)
{
    char full_root[PATH_BUFFER];
    char cache_directory[PATH_BUFFER];
    char cache_path[PATH_BUFFER];
    char manifest_path[PATH_BUFFER];
    char cache_temp[PATH_BUFFER];
    char manifest_temp[PATH_BUFFER];
    FILE *cache = NULL;
    FILE *manifest = NULL;
    unsigned int cache_count = 0;
    unsigned int directory_count = 0;
    int scanned;
    if (is_none(root_name)) return 1;
    if (!join_path(full_root, sizeof(full_root), g_exe_directory, root_name) || !directory_exists(full_root)) return 1;
    if (!join_path(cache_directory, sizeof(cache_directory), g_exe_directory, CACHE_DIRECTORY)) return 0;
    CreateDirectoryA(cache_directory, NULL);
    if (!path_printf(cache_path, sizeof(cache_path), "%s\\%s.cache", cache_directory, cache_key) ||
        !path_printf(manifest_path, sizeof(manifest_path), "%s\\%s.dirs", cache_directory, cache_key) ||
        !path_printf(cache_temp, sizeof(cache_temp), "%s\\%s.cache.tmp", cache_directory, cache_key) ||
        !path_printf(manifest_temp, sizeof(manifest_temp), "%s\\%s.dirs.tmp", cache_directory, cache_key)) return 0;
    if (use_cache && validate_manifest(manifest_path, root_name) && read_cache(cache_path, root_name)) return 1;
    DeleteFileA(cache_temp);
    DeleteFileA(manifest_temp);
    if (use_cache) {
        cache = fopen(cache_temp, "wb");
        manifest = fopen(manifest_temp, "wb");
        if (cache == NULL || manifest == NULL ||
            fprintf(cache, "#%s?%s\n", CACHE_FORMAT, root_name) < 0 ||
            fprintf(manifest, "#%s?%s\n", MANIFEST_FORMAT, root_name) < 0) {
            if (cache != NULL) fclose(cache);
            if (manifest != NULL) fclose(manifest);
            cache = NULL;
            manifest = NULL;
            DeleteFileA(cache_temp);
            DeleteFileA(manifest_temp);
        }
    }
    scanned = mods_style
        ? scan_mods_root(root_name, cache, manifest, &cache_count, &directory_count)
        : scan_files_root(root_name, cache, manifest, &cache_count, &directory_count);
    if (cache != NULL && manifest != NULL) {
        int durable = scanned &&
            fprintf(cache, "#END?%u\n", cache_count) >= 0 &&
            fprintf(manifest, "#END?%u\n", directory_count) >= 0 &&
            flush_file(cache) && flush_file(manifest);
        fclose(cache);
        fclose(manifest);
        if (durable &&
            MoveFileExA(cache_temp, cache_path, MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH) &&
            MoveFileExA(manifest_temp, manifest_path, MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
            return scanned;
        }
        DeleteFileA(cache_temp);
        DeleteFileA(manifest_temp);
    }
    return scanned;
}

static int compare_entries(const void *left, const void *right)
{
    const FileEntry *a = (const FileEntry *)left;
    const FileEntry *b = (const FileEntry *)right;
    if (a->hash < b->hash) return -1;
    if (a->hash > b->hash) return 1;
    if (a->order < b->order) return -1;
    if (a->order > b->order) return 1;
    return 0;
}

static void sort_and_compact(void)
{
    size_t read_index;
    size_t write_index = 0;
    if (g_entry_count < 2) return;
    qsort(g_entries, g_entry_count, sizeof(FileEntry), compare_entries);
    for (read_index = 0; read_index < g_entry_count; ++read_index) {
        if (write_index != 0 && g_entries[read_index].hash == g_entries[write_index - 1].hash) {
            free(g_entries[read_index].path);
            continue;
        }
        if (write_index != read_index) g_entries[write_index] = g_entries[read_index];
        ++write_index;
    }
    g_entry_count = write_index;
}

static const char *find_loose_file(unsigned __int64 hash)
{
    size_t first = 0;
    size_t last = g_entry_count;
    while (first < last) {
        size_t middle = first + (last - first) / 2;
        if (g_entries[middle].hash < hash) first = middle + 1;
        else last = middle;
    }
    if (first < g_entry_count && g_entries[first].hash == hash) return g_entries[first].path;
    return NULL;
}

static void read_configuration(char *files_root, size_t files_size, char *mods_root, size_t mods_size, int *use_cache)
{
    char ini_path[PATH_BUFFER];
    char section[32];
    int mod_type;
    if (!join_path(ini_path, sizeof(ini_path), g_exe_directory, "il2fb.ini")) ini_path[0] = '\0';
    mod_type = GetPrivateProfileIntA("Settings", "ModType", 1, ini_path);
    _snprintf(section, sizeof(section), "Modtype_%02d", mod_type);
    section[sizeof(section) - 1] = '\0';
    GetPrivateProfileStringA(section, "Files", "Files", files_root, (DWORD)files_size, ini_path);
    GetPrivateProfileStringA(section, "Mods", "Mods", mods_root, (DWORD)mods_size, ini_path);
    *use_cache = GetPrivateProfileIntA("Settings", "UseCachedFileLists", 1, ini_path) != 0;
}

static int initialize_wrapper(void)
{
    HMODULE executable;
    char executable_path[PATH_BUFFER];
    char files_root[MAX_PATH];
    char mods_root[MAX_PATH];
    char *separator;
    int use_cache;
    DWORD length = GetModuleFileNameA(NULL, executable_path, sizeof(executable_path));
    if (length == 0 || length >= sizeof(executable_path)) return 0;
    separator = strrchr(executable_path, '\\');
    if (separator == NULL) return 0;
    separator[1] = '\0';
    strncpy(g_exe_directory, executable_path, sizeof(g_exe_directory) - 1);
    g_exe_directory[sizeof(g_exe_directory) - 1] = '\0';
    executable = GetModuleHandleA(NULL);
    if (executable == NULL) return 0;
    g_sfs_open = (SFS_OPEN)GetProcAddress(executable, "SFS_open");
    if (g_sfs_open == NULL) g_sfs_open = (SFS_OPEN)GetProcAddress(executable, MAKEINTRESOURCEA(7));
    g_sfs_openf = (SFS_OPENF)GetProcAddress(executable, "SFS_openf");
    if (g_sfs_openf == NULL) g_sfs_openf = (SFS_OPENF)GetProcAddress(executable, MAKEINTRESOURCEA(8));
    if (g_sfs_open == NULL || g_sfs_openf == NULL) return 0;
    read_configuration(files_root, sizeof(files_root), mods_root, sizeof(mods_root), &use_cache);
    if (!load_or_build_root(mods_root, "mods", 1, use_cache) ||
        !load_or_build_root(files_root, "files", 0, use_cache)) return 0;
    sort_and_compact();
    return 1;
}

static int ensure_initialized(void)
{
    LONG state = InterlockedCompareExchange(&g_init_state, 1, 0);
    if (state == 0) {
        int ok = initialize_wrapper();
        InterlockedExchange(&g_init_state, ok ? 2 : -1);
        return ok;
    }
    while ((state = InterlockedCompareExchange(&g_init_state, 0, 0)) == 1) Sleep(0);
    return state == 2;
}

void __stdcall ReadDump(void *buffer, unsigned int length)
{
    (void)buffer;
    (void)length;
}

int __stdcall __SFS_openf(const unsigned __int64 hash, const int flags)
{
    const char *path = NULL;
    int file_pointer = -1;
    if (ensure_initialized()) {
        char hash_text[32];
        path = find_loose_file(hash);
        if (path == NULL) {
            _snprintf(hash_text, sizeof(hash_text), "%016I64X", hash);
            hash_text[sizeof(hash_text) - 1] = '\0';
            path = find_loose_file(sfs_hash(0, hash_text, (int)strlen(hash_text)));
        }
        if (path != NULL) file_pointer = (int)g_sfs_open((char *)path, flags);
    }
    if (file_pointer == -1 && g_sfs_openf != NULL) file_pointer = (int)g_sfs_openf(hash, flags);
    return file_pointer;
}

BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID reserved)
{
    (void)reserved;
    if (reason == DLL_PROCESS_ATTACH) DisableThreadLibraryCalls(instance);
    return TRUE;
}

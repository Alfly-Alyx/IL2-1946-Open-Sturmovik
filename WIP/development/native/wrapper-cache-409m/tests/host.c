#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>

typedef int (__stdcall *WRAPPER_OPENF)(unsigned __int64 hash, int flags);

unsigned int __cdecl SFS_open(char *filename, int flags)
{
    DWORD attributes;
    (void)flags;
    attributes = GetFileAttributesA(filename);
    return attributes == INVALID_FILE_ATTRIBUTES ? (unsigned int)-1 : 42u;
}

unsigned int __cdecl SFS_openf(unsigned __int64 hash, int flags)
{
    (void)hash;
    (void)flags;
    return (unsigned int)-1;
}

int main(int argc, char **argv)
{
    HMODULE wrapper;
    WRAPPER_OPENF openf;
    unsigned __int64 hash;
    int result;
    if (argc != 2) return 2;
    wrapper = LoadLibraryA("wrapper.dll");
    if (wrapper == NULL) return 3;
    openf = (WRAPPER_OPENF)GetProcAddress(wrapper, "__SFS_openf");
    if (openf == NULL) return 4;
    hash = _strtoui64(argv[1], NULL, 16);
    result = openf(hash, 0);
    printf("%d\n", result);
    FreeLibrary(wrapper);
    return result == 42 ? 0 : 5;
}

package com.maddox.il2.engine;

import java.io.*;
import java.security.MessageDigest;
import java.util.*;

/**
 * Optional startup-only rotation. Uses APIs available to IL-2's Java 1.3 runtime.
 * No EXE, archive, original material or texture is changed during startup.
 */
public final class OpenSturmovikLoadingRotation {
    private static boolean attempted;
    private static String chosen;
    private static final Random random = new Random();
    private static final String ORIGINAL = "gui/background0.mat";
    private static final String POOL = "Files/gui/backgrounds";
    private static final String DATA = ".open-sturmovik-loading-rotation";

    private OpenSturmovikLoadingRotation() { }

    public static synchronized String choose(String original) {
        if (!ORIGINAL.equals(original)) return original;
        if (attempted) return chosen == null ? original : chosen;
        attempted = true;
        chosen = original;
        try {
            String result = select(new File(System.getProperty("user.dir")));
            if (result != null) chosen = result;
        } catch (Throwable problem) {
            // An optional background must never prevent the original startup.
            System.out.println("Open Sturmovik: rotation inactive (" + problem.toString() + ")");
        }
        return chosen;
    }

    private static String select(File root) throws Exception {
        File pool = new File(root, POOL);
        File configFile = new File(pool, "rotation.properties");
        if (!configFile.isFile()) return null;
        Properties config = read(configFile);
        if (!"true".equals(config.getProperty("enabled", "false"))) return null;
        String[] ids = split(config.getProperty("images", ""));
        String official = config.getProperty("official", "").trim();
        String mode = config.getProperty("mode", "shuffle");
        if (!"shuffle".equals(mode) && !"ordered".equals(mode)) throw new IOException("Invalid rotation mode");
        validateSelection(ids, official);
        StringBuffer signatureText = new StringBuffer(mode).append('|').append(official);
        Hashtable hashes = new Hashtable();
        for (int i = 0; i < ids.length; i++) {
            File material = new File(pool, ids[i] + ".mat");
            if (!material.isFile() || material.length() < 1 || material.length() > 4096)
                throw new IOException("Missing rotation material: " + ids[i]);
            String hash = validateTexture(new File(pool, ids[i] + ".tga"));
            if (hashes.put(hash, ids[i]) != null) throw new IOException("Duplicate rotation picture");
            signatureText.append('|').append(ids[i]).append(':').append(hash);
        }
        String signature = digest(signatureText.toString().getBytes("US-ASCII"));
        File data = new File(root, DATA);
        if (!data.isDirectory() && !data.mkdir()) throw new IOException("Cannot create rotation state directory");
        File lock = new File(data, "selection.lock");
        if (!lock.createNewFile()) return null;
        try {
            File stateFile = new File(data, "state.properties");
            recover(data);
            Properties state = stateFile.isFile() ? read(stateFile) : new Properties();
            String last = state.getProperty("last", "");
            if (last.length() > 0 && !validId(last)) throw new IOException("Invalid previous image");
            String[] cycle;
            int position;
            if (signature.equals(state.getProperty("signature", ""))) {
                if (!"1".equals(state.getProperty("schema"))) throw new IOException("Invalid state version");
                cycle = split(state.getProperty("cycle", ""));
                position = Integer.parseInt(state.getProperty("position", "-1"));
                validateCycle(cycle, ids, official);
                if (position < 1 || position > cycle.length || !last.equals(cycle[position - 1]))
                    throw new IOException("Invalid cycle position");
                if (position == cycle.length) {
                    cycle = buildCycle(ids, official, last, "shuffle".equals(mode));
                    position = 0;
                }
            } else {
                if (state.size() > 0 && !"1".equals(state.getProperty("schema")))
                    throw new IOException("Damaged rotation state");
                cycle = buildCycle(ids, official, last, "shuffle".equals(mode));
                position = 0;
            }
            String next = cycle[position];
            if (next.equals(last)) throw new IOException("Repeated picture");
            String materialPath = "gui/backgrounds/" + next + ".mat";
            // Qualify the selected material in the actual engine before advancing.
            if (Mat.New(materialPath) == null) return null;
            Properties after = new Properties();
            after.setProperty("schema", "1");
            after.setProperty("signature", signature);
            after.setProperty("cycle", join(cycle));
            after.setProperty("position", Integer.toString(position + 1));
            after.setProperty("last", next);
            save(data, after);
            return materialPath;
        } finally {
            if (!lock.delete()) System.out.println("Open Sturmovik: could not remove selection.lock");
        }
    }

    private static void validateSelection(String[] ids, String official) throws IOException {
        if (ids.length < 2 || ids.length > 4) throw new IOException("Choose two to four pictures");
        Hashtable unique = new Hashtable();
        boolean found = official.length() == 0;
        for (int i = 0; i < ids.length; i++) {
            if (!validId(ids[i]) || unique.put(ids[i], ids[i]) != null) throw new IOException("Invalid image identifier");
            if (ids[i].equals(official)) found = true;
        }
        if (!found) throw new IOException("Official picture is not selected");
        if (official.length() > 0 && ids.length < 3)
            throw new IOException("Double frequency requires at least three pictures");
    }

    private static boolean validId(String id) {
        if (id.length() < 1 || id.length() > 64) return false;
        for (int i = 0; i < id.length(); i++) {
            char c = id.charAt(i);
            if (!((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || (i > 0 && c == '-'))) return false;
        }
        return true;
    }

    static String[] buildCycle(String[] ids, String official, String last, boolean shuffle) throws IOException {
        validateSelection(ids, official);
        int[] counts = new int[ids.length];
        int total = 0;
        for (int i = 0; i < ids.length; i++) {
            counts[i] = ids[i].equals(official) ? 2 : 1;
            total += counts[i];
        }
        String[] result = new String[total];
        if (!fillCycle(ids, counts, result, 0, last, shuffle)) throw new IOException("Impossible rotation");
        return result;
    }

    private static boolean fillCycle(String[] ids, int[] counts, String[] result, int position, String last, boolean shuffle) {
        if (position == result.length) return true;
        int[] order = new int[ids.length];
        for (int i = 0; i < order.length; i++) order[i] = i;
        if (shuffle) {
            for (int i = order.length - 1; i > 0; i--) {
                int j = random.nextInt(i + 1);
                int swap = order[i]; order[i] = order[j]; order[j] = swap;
            }
        }
        for (int i = 0; i < order.length; i++) {
            int index = order[i];
            if (counts[index] == 0 || ids[index].equals(last)) continue;
            counts[index]--;
            result[position] = ids[index];
            if (fillCycle(ids, counts, result, position + 1, ids[index], shuffle)) return true;
            counts[index]++;
        }
        return false;
    }

    private static void validateCycle(String[] cycle, String[] ids, String official) throws IOException {
        int[] expected = new int[ids.length];
        int total = 0;
        for (int i = 0; i < ids.length; i++) { expected[i] = ids[i].equals(official) ? 2 : 1; total += expected[i]; }
        if (cycle.length != total) throw new IOException("Invalid saved cycle length");
        String last = "";
        for (int i = 0; i < cycle.length; i++) {
            if (cycle[i].equals(last)) throw new IOException("Repeated saved picture");
            boolean found = false;
            for (int j = 0; j < ids.length; j++) {
                if (ids[j].equals(cycle[i])) {
                    if (--expected[j] < 0) throw new IOException("Invalid saved weights");
                    found = true; break;
                }
            }
            if (!found) throw new IOException("Unknown saved picture");
            last = cycle[i];
        }
    }

    private static String[] split(String csv) throws IOException {
        if (csv.length() == 0) return new String[0];
        if (csv.charAt(0) == ',' || csv.charAt(csv.length() - 1) == ',' || csv.indexOf(",,") >= 0)
            throw new IOException("Invalid image list");
        StringTokenizer tokens = new StringTokenizer(csv, ",");
        if (tokens.countTokens() > 8) throw new IOException("Image list too long");
        String[] result = new String[tokens.countTokens()];
        for (int i = 0; i < result.length; i++) result[i] = tokens.nextToken().trim();
        return result;
    }

    private static String join(String[] ids) {
        StringBuffer buffer = new StringBuffer();
        for (int i = 0; i < ids.length; i++) { if (i > 0) buffer.append(','); buffer.append(ids[i]); }
        return buffer.toString();
    }

    private static String digest(byte[] bytes) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA");
        return hex(digest.digest(bytes));
    }

    private static String hex(byte[] data) {
        StringBuffer buffer = new StringBuffer();
        for (int i = 0; i < data.length; i++) {
            int value = data[i] & 255;
            if (value < 16) buffer.append('0');
            buffer.append(Integer.toHexString(value));
        }
        return buffer.toString();
    }

    private static String validateTexture(File file) throws Exception {
        FileInputStream stream = new FileInputStream(file);
        try {
            byte[] header = new byte[18];
            new DataInputStream(stream).readFully(header);
            int width = (header[12] & 255) | ((header[13] & 255) << 8);
            int height = (header[14] & 255) | ((header[15] & 255) << 8);
            if (header[1] != 0 || header[2] != 2 || header[16] != 24 || width < 1 || height < 1 ||
                width > 4096 || height > 4096 ||
                file.length() < 18L + (header[0] & 255) + 3L * width * height)
                throw new IOException("Invalid TGA picture");
            MessageDigest digest = MessageDigest.getInstance("SHA");
            digest.update(header);
            byte[] buffer = new byte[16384];
            int count;
            while ((count = stream.read(buffer)) != -1) digest.update(buffer, 0, count);
            return hex(digest.digest());
        } finally { stream.close(); }
    }

    private static Properties read(File file) throws IOException {
        if (file.length() > 16384) throw new IOException("Rotation properties too large");
        FileInputStream stream = new FileInputStream(file);
        try { Properties p = new Properties(); p.load(stream); return p; }
        finally { stream.close(); }
    }

    private static void requireFiles(File[] files) throws IOException {
        for (int i = 0; i < files.length; i++) {
            if (files[i].exists() && !files[i].isFile()) throw new IOException("State path is not a file");
        }
    }

    private static void recover(File data) throws IOException {
        File current = new File(data, "state.properties");
        File previous = new File(data, "state.previous");
        File next = new File(data, "state.next");
        requireFiles(new File[] { current, previous, next });
        if (!current.exists() && previous.exists() && !previous.renameTo(current))
            throw new IOException("Cannot recover rotation state");
        if (current.exists()) {
            Properties state = read(current);
            if (!"1".equals(state.getProperty("schema"))) throw new IOException("Damaged rotation state");
        }
        if (next.exists() && !next.delete()) throw new IOException("Cannot remove interrupted state");
        if (previous.exists() && !previous.delete()) throw new IOException("Cannot finish state recovery");
    }

    private static void save(File data, Properties state) throws IOException {
        File current = new File(data, "state.properties");
        File previous = new File(data, "state.previous");
        File next = new File(data, "state.next");
        requireFiles(new File[] { current, previous, next });
        FileOutputStream output = new FileOutputStream(next);
        try { state.store(output, "Open Sturmovik loading rotation"); output.flush(); output.getFD().sync(); }
        finally { output.close(); }
        boolean hadCurrent = current.exists();
        if (hadCurrent && !current.renameTo(previous)) {
            next.delete();
            throw new IOException("Cannot preserve previous rotation state");
        }
        if (!next.renameTo(current)) {
            if (hadCurrent) previous.renameTo(current);
            throw new IOException("Cannot publish rotation state");
        }
        // The new state is committed. A leftover previous file is recoverable.
        if (previous.exists() && !previous.delete())
            System.out.println("Open Sturmovik: previous rotation state retained");
    }
}

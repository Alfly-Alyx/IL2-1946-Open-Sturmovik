package com.maddox.il2.engine;

/** Test-only replacement for the native renderer. Never packaged in the mod. */
public class Mat {
    public static int calls;
    public static String lastPath;
    public static boolean fail;
    public static boolean returnNull;
    public static Runnable onNew;

    public static Mat New(String path) {
        calls++;
        lastPath = path;
        if (onNew != null) onNew.run();
        if (fail) throw new RuntimeException("Injected material preload failure.");
        if (returnNull) return null;
        return new Mat();
    }

    public static void reset() {
        calls = 0;
        lastPath = null;
        fail = false;
        returnNull = false;
        onNew = null;
    }
}

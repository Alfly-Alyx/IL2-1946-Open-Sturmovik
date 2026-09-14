package com.maddox.il2.engine;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.Properties;
import java.util.StringTokenizer;
import java.util.TreeMap;

/**
 * Behavioral checks for the direct startup hook. Uses synthetic tiny RGB TGAs
 * and a test-only Mat stub, never the native game, renderer, EXE or SFS files.
 * Written against the Java 1.3 language/API surface used by the helper.
 */
public final class LoadingRotationTest {
    private static final String ORIGINAL = "gui/background0.mat";
    private static final String[] IDS = { "first", "second", "third", "fourth" };
    private static final String DATA = ".open-sturmovik-loading-rotation";
    private static final String RESOURCES = "Files/gui/backgrounds";
    private static File testRoot;
    private static File current;
    private static int fixtureNumber;
    private static int assertions;

    private static void check(boolean condition, String message) {
        assertions++;
        if (!condition) throw new RuntimeException(message);
    }

    private static void inside(File file) throws IOException {
        String boundary = testRoot.getCanonicalPath() + File.separator;
        String absolute = file.getCanonicalPath();
        if (!absolute.startsWith(boundary)) throw new IOException("Outside test fixtures: " + absolute);
    }

    private static void write(File file, byte[] bytes) throws IOException {
        inside(file);
        File parent = file.getParentFile();
        if (!parent.isDirectory() && !parent.mkdirs()) throw new IOException("Cannot create " + parent);
        FileOutputStream output = new FileOutputStream(file);
        try { output.write(bytes); } finally { output.close(); }
    }

    private static byte[] read(File file) throws IOException {
        if (!file.isFile()) return null;
        FileInputStream input = new FileInputStream(file);
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        try {
            byte[] buffer = new byte[4096];
            int count;
            while ((count = input.read(buffer)) >= 0) output.write(buffer, 0, count);
            return output.toByteArray();
        } finally { input.close(); }
    }

    private static boolean equal(byte[] first, byte[] second) {
        if (first == null || second == null) return first == second;
        return Arrays.equals(first, second);
    }

    private static void properties(File file, Properties values) throws IOException {
        inside(file);
        File parent = file.getParentFile();
        if (!parent.isDirectory() && !parent.mkdirs()) throw new IOException("Cannot create " + parent);
        FileOutputStream output = new FileOutputStream(file);
        try { values.store(output, "Loading rotation test fixture"); } finally { output.close(); }
    }

    private static Properties properties(File file) throws IOException {
        Properties values = new Properties();
        FileInputStream input = new FileInputStream(file);
        try { values.load(input); } finally { input.close(); }
        return values;
    }

    private static String digest(byte[] bytes) throws Exception {
        MessageDigest sha = MessageDigest.getInstance("SHA-1");
        byte[] result = sha.digest(bytes);
        StringBuffer text = new StringBuffer();
        for (int i = 0; i < result.length; i++) {
            int value = result[i] & 255;
            if (value < 16) text.append('0');
            text.append(Integer.toHexString(value));
        }
        return text.toString();
    }

    private static void snapshot(File root, File directory, TreeMap values) throws Exception {
        File[] entries = directory.listFiles();
        if (entries == null) throw new IOException("Cannot list " + directory);
        for (int i = 0; i < entries.length; i++) {
            File entry = entries[i];
            String relative = entry.getCanonicalPath().substring(root.getCanonicalPath().length());
            if (entry.isDirectory()) {
                values.put(relative, "<directory>");
                snapshot(root, entry, values);
            } else {
                values.put(relative, digest(read(entry)));
            }
        }
    }

    private static String snapshot(File root) throws Exception {
        TreeMap values = new TreeMap();
        snapshot(root, root, values);
        return values.toString();
    }

    private static String csv(String[] values) {
        StringBuffer text = new StringBuffer();
        for (int i = 0; i < values.length; i++) {
            if (i != 0) text.append(',');
            text.append(values[i]);
        }
        return text.toString();
    }

    private static File state() { return new File(current, DATA + "/state.properties"); }
    private static File config() { return new File(current, RESOURCES + "/rotation.properties"); }
    private static File image(String id) { return new File(current, RESOURCES + "/" + id + ".tga"); }

    private static void resetProcess() throws Exception {
        Field attempted = OpenSturmovikLoadingRotation.class.getDeclaredField("attempted");
        Field chosen = OpenSturmovikLoadingRotation.class.getDeclaredField("chosen");
        attempted.setAccessible(true);
        chosen.setAccessible(true);
        attempted.setBoolean(null, false);
        chosen.set(null, null);
        Mat.reset();
    }

    private static File fixture() throws Exception {
        fixtureNumber++;
        current = new File(testRoot, "fixture-" + fixtureNumber);
        inside(current);
        if (!current.mkdirs()) throw new IOException("Cannot create fixture " + current);
        System.setProperty("user.dir", current.getCanonicalPath());
        for (int index = 0; index < IDS.length; index++) {
            byte[] tga = new byte[18 + 4 * 4 * 3];
            tga[2] = 2;
            tga[12] = 4;
            tga[14] = 4;
            tga[16] = 24;
            tga[17] = 32;
            for (int pixel = 18; pixel < tga.length; pixel++) tga[pixel] = (byte)(index * 49 + pixel);
            write(image(IDS[index]), tga);
            write(new File(current, RESOURCES + "/" + IDS[index] + ".mat"),
                ("[ClassInfo]\r\n ClassName TMaterial\r\n[Layer0]\r\n TextureName " + IDS[index] + ".tga\r\n tfNoDegradation 1\r\n").getBytes("US-ASCII"));
        }
        write(new File(current, "Files/gui/Background.tga"), "Original user background".getBytes("US-ASCII"));
        write(new File(current, "Files/gui/background0_ru.mat"), "Original user material".getBytes("US-ASCII"));
        resetProcess();
        return current;
    }

    private static void configure(String[] ids, String official, String mode, boolean enabled) throws Exception {
        Properties values = new Properties();
        values.setProperty("enabled", enabled ? "true" : "false");
        values.setProperty("images", csv(ids));
        values.setProperty("official", official);
        values.setProperty("mode", mode);
        properties(config(), values);
    }

    private static String choose() { return OpenSturmovikLoadingRotation.choose(ORIGINAL); }

    private static String chosenId(String path) {
        for (int i = 0; i < IDS.length; i++) {
            if (path != null && path.replace('\\', '/').endsWith("/" + IDS[i] + ".mat")) return IDS[i];
        }
        throw new RuntimeException("No catalog material chosen: " + path);
    }

    private static void testWeightedCycles() throws Exception {
        for (int mode = 0; mode < 2; mode++) {
            String previous = "";
            for (int round = 0; round < 150; round++) {
                String[] cycle = OpenSturmovikLoadingRotation.buildCycle(IDS, IDS[0], previous, mode == 1);
                check(cycle.length == 6, "Weighted cycle length must be six.");
                int[] counts = new int[4];
                for (int index = 0; index < cycle.length; index++) {
                    check(!cycle[index].equals(previous), "Adjacent duplicate at cycle boundary or inside cycle.");
                    boolean known = false;
                    for (int id = 0; id < IDS.length; id++) {
                        if (cycle[index].equals(IDS[id])) { counts[id]++; known = true; }
                    }
                    check(known, "Unexpected cycle identifier.");
                    previous = cycle[index];
                }
                for (int id = 0; id < counts.length; id++) check(counts[id] == (id == 0 ? 3 : 1), "Weighted occurrence count differs.");
            }
        }
    }

    private static void testUniformCycles() throws Exception {
        for (int size = 2; size <= 4; size++) {
            String[] selected = new String[size];
            System.arraycopy(IDS, 0, selected, 0, size);
            for (int mode = 0; mode < 2; mode++) {
                String previous = "";
                for (int round = 0; round < 30; round++) {
                    String[] cycle = OpenSturmovikLoadingRotation.buildCycle(selected, "", previous, mode == 1);
                    check(cycle.length == size, "Uniform cycle has wrong size.");
                    int[] counts = new int[size];
                    for (int index = 0; index < cycle.length; index++) {
                        check(!cycle[index].equals(previous), "Uniform adjacent duplicate.");
                        for (int id = 0; id < size; id++) if (selected[id].equals(cycle[index])) counts[id]++;
                        previous = cycle[index];
                    }
                    for (int id = 0; id < size; id++) check(counts[id] == 1, "Uniform image missing or duplicated.");
                }
            }
        }
    }

    private static void testImpossibleWeightedSelections() throws Exception {
        for (int size = 2; size <= 3; size++) {
            String[] selected = new String[size];
            System.arraycopy(IDS, 0, selected, 0, size);
            for (int mode = 0; mode < 2; mode++) {
                boolean rejected = false;
                try { OpenSturmovikLoadingRotation.buildCycle(selected, IDS[0], "", mode == 1); }
                catch (IOException expected) { rejected = true; }
                check(rejected, "Weight three requires four images to avoid repeats across all launches.");
            }
        }
    }

    private static void testDisabledNoWrites() throws Exception {
        fixture();
        String before = snapshot(current);
        check(ORIGINAL.equals(choose()), "No configuration should leave startup unchanged.");
        check(before.equals(snapshot(current)), "No configuration wrote files or directories.");
        check(Mat.calls == 0, "Disabled rotation preloaded a material.");
        configure(IDS, IDS[0], "ordered", false);
        resetProcess();
        before = snapshot(current);
        check(ORIGINAL.equals(choose()), "Explicitly disabled rotation changed startup.");
        check(before.equals(snapshot(current)), "Disabled rotation wrote files or directories.");
        check(Mat.calls == 0, "Explicitly disabled rotation preloaded a material.");
    }

    private static void testOnlyStartupMaterial() throws Exception {
        fixture();
        configure(IDS, IDS[0], "ordered", true);
        String before = snapshot(current);
        String unrelated = "gui/other-screen.mat";
        check(unrelated.equals(OpenSturmovikLoadingRotation.choose(unrelated)), "Unrelated material was intercepted.");
        check(before.equals(snapshot(current)), "Unrelated material consumed rotation state.");
        check(Mat.calls == 0, "Unrelated material was preloaded.");
        check(!ORIGINAL.equals(choose()), "Earlier unrelated material prevented later startup selection.");
    }

    private static void testOneDecisionPerProcess() throws Exception {
        fixture();
        configure(IDS, IDS[0], "ordered", true);
        byte[] background = read(new File(current, "Files/gui/Background.tga"));
        byte[] material = read(new File(current, "Files/gui/background0_ru.mat"));
        String selected = choose();
        chosenId(selected);
        check(selected.equals(Mat.lastPath), "Helper did not preload the selected material.");
        byte[] firstState = read(state());
        check(firstState != null, "Successful selection did not persist state.");
        for (int i = 0; i < 12; i++) check(selected.equals(choose()), "One process chose more than one material.");
        check(equal(firstState, read(state())), "Repeated calls consumed another image.");
        check(Mat.calls == 1, "Repeated calls loaded the selected material again.");
        check(equal(background, read(new File(current, "Files/gui/Background.tga"))), "Original background was overwritten.");
        check(equal(material, read(new File(current, "Files/gui/background0_ru.mat"))), "Original material was overwritten.");
        check(!new File(current, DATA + "/selection.lock").exists(), "Owned selection lock remained after success.");
    }

    private static void testWeightedPersistentLaunches() throws Exception {
        fixture();
        configure(IDS, IDS[0], "ordered", true);
        String previous = "";
        int[] counts = new int[IDS.length];
        for (int launch = 0; launch < 24; launch++) {
            resetProcess();
            String selected = chosenId(choose());
            check(!selected.equals(previous), "Persistent launch sequence repeated an image.");
            previous = selected;
            for (int id = 0; id < IDS.length; id++) if (selected.equals(IDS[id])) counts[id]++;
            Properties stored = properties(state());
            check("1".equals(stored.getProperty("schema")), "State schema differs.");
            check(selected.equals(stored.getProperty("last")), "Persisted last choice differs.");
            check(Integer.parseInt(stored.getProperty("position")) == launch % 6 + 1, "Persisted position advanced incorrectly.");
            if (launch % 6 == 5) {
                for (int id = 0; id < IDS.length; id++) {
                    check(counts[id] == (id == 0 ? 3 : 1), "Six actual selections violated exact weights.");
                    counts[id] = 0;
                }
            }
        }
    }

    private static String fixtureSignature(String mode, boolean includeWeight) throws Exception {
        StringBuffer text = new StringBuffer(mode).append('|').append(IDS[0]);
        if (includeWeight) text.append("|weight=3");
        for (int id = 0; id < IDS.length; id++) {
            text.append('|').append(IDS[id]).append(':').append(digest(read(image(IDS[id]))));
        }
        return digest(text.toString().getBytes("US-ASCII"));
    }

    private static void testLegacyWeightedStateMigration() throws Exception {
        // Every old position is valid for the previous 2:1:1:1 implementation.
        String[] legacyCycle = { IDS[0], IDS[1], IDS[0], IDS[2], IDS[3] };
        for (int mode = 0; mode < 2; mode++) {
            String selectedMode = mode == 0 ? "ordered" : "shuffle";
            for (int oldPosition = 1; oldPosition <= legacyCycle.length; oldPosition++) {
                fixture();
                configure(IDS, IDS[0], selectedMode, true);
                Properties legacy = new Properties();
                legacy.setProperty("schema", "1");
                legacy.setProperty("signature", fixtureSignature(selectedMode, false));
                legacy.setProperty("cycle", csv(legacyCycle));
                legacy.setProperty("position", Integer.toString(oldPosition));
                String previous = legacyCycle[oldPosition - 1];
                legacy.setProperty("last", previous);
                properties(state(), legacy);
                byte[] oldBytes = read(state());

                Mat.fail = true;
                check(ORIGINAL.equals(choose()), "Failed migration preload did not fall back.");
                check(Mat.calls == 1, "Legacy state was not usable before migration preload.");
                check(equal(oldBytes, read(state())), "Failed migration consumed or rewrote legacy state.");

                int[] counts = new int[IDS.length];
                for (int launch = 0; launch < 6; launch++) {
                    resetProcess();
                    String selected = chosenId(choose());
                    check(!selected.equals(previous), "Migration repeated the old last image or a new neighbor.");
                    previous = selected;
                    for (int id = 0; id < IDS.length; id++) if (selected.equals(IDS[id])) counts[id]++;
                    Properties stored = properties(state());
                    check("1".equals(stored.getProperty("schema")), "Migration changed the state schema.");
                    check(fixtureSignature(selectedMode, true).equals(stored.getProperty("signature")),
                        "Migrated signature does not include official weight three.");
                    check(new StringTokenizer(stored.getProperty("cycle"), ",").countTokens() == 6,
                        "Legacy five-entry cycle was not rebuilt as six entries.");
                    check(Integer.parseInt(stored.getProperty("position")) == launch + 1,
                        "Migrated cycle did not start at its first entry or advance once.");
                    check(selected.equals(stored.getProperty("last")), "Migration lost the actual last selection.");
                }
                for (int id = 0; id < IDS.length; id++) {
                    check(counts[id] == (id == 0 ? 3 : 1), "Migrated cycle violated 3:1:1:1 weights.");
                }
                resetProcess();
                String next = chosenId(choose());
                check(!next.equals(previous), "Migrated cycle boundary repeated its last image.");
                check("1".equals(properties(state()).getProperty("position")),
                    "The cycle following migration did not start at position one.");
                check(!new File(current, DATA + "/selection.lock").exists(), "Migration left its selection lock.");
            }
        }
    }

    private static void testMissingCandidateDoesNotConsumeState() throws Exception {
        fixture();
        configure(IDS, IDS[0], "ordered", true);
        chosenId(choose());
        byte[] before = read(state());
        File missing = image(IDS[3]);
        inside(missing);
        check(missing.delete(), "Cannot remove fixture candidate.");
        resetProcess();
        check(ORIGINAL.equals(choose()), "Missing candidate did not fall back to original.");
        check(equal(before, read(state())), "Missing candidate consumed persisted state.");
        check(Mat.calls == 0, "Missing candidate was not rejected before preload.");
    }

    private static void testCorruptCandidateDoesNotConsumeState() throws Exception {
        fixture();
        configure(IDS, IDS[0], "ordered", true);
        chosenId(choose());
        byte[] before = read(state());
        write(image(IDS[1]), new byte[] { 1, 2, 3 });
        resetProcess();
        check(ORIGINAL.equals(choose()), "Truncated TGA did not fall back to original.");
        check(equal(before, read(state())), "Truncated TGA consumed persisted state.");
        check(Mat.calls == 0, "Truncated TGA reached material preload.");
    }

    private static void testCorruptStateIsPreserved() throws Exception {
        fixture();
        configure(IDS, IDS[0], "ordered", true);
        chosenId(choose());
        Properties values = properties(state());
        values.setProperty("schema", "99");
        properties(state(), values);
        byte[] corrupt = read(state());
        resetProcess();
        check(ORIGINAL.equals(choose()), "Unsupported state schema did not fall back.");
        check(equal(corrupt, read(state())), "Corrupt state was silently replaced.");
    }

    private static void testInvalidStatePositionAndCycle() throws Exception {
        for (int mutation = 0; mutation < 2; mutation++) {
            fixture();
            configure(IDS, IDS[0], "ordered", true);
            chosenId(choose());
            Properties values = properties(state());
            if (mutation == 0) values.setProperty("position", "999");
            else values.setProperty("cycle", "first,first,first,first,first,first");
            properties(state(), values);
            byte[] corrupt = read(state());
            resetProcess();
            check(ORIGINAL.equals(choose()), "Invalid state position or cycle was accepted.");
            check(equal(corrupt, read(state())), "Invalid state position or cycle was overwritten.");
        }
    }

    private static void testBusyLockIsPreserved() throws Exception {
        fixture();
        configure(IDS, IDS[0], "ordered", true);
        chosenId(choose());
        byte[] before = read(state());
        File lock = new File(current, DATA + "/selection.lock");
        byte[] lockBytes = "Owned by another launch".getBytes("US-ASCII");
        write(lock, lockBytes);
        resetProcess();
        check(ORIGINAL.equals(choose()), "Busy lock did not fall back.");
        check(equal(before, read(state())), "Busy lock consumed state.");
        check(equal(lockBytes, read(lock)), "Another launch's lock was overwritten or removed.");
        check(Mat.calls == 0, "Busy lock did not prevent material preload.");
    }

    private static void testMaterialPreloadFailureDoesNotConsumeState() throws Exception {
        for (int failure = 0; failure < 2; failure++) {
            fixture();
            configure(IDS, IDS[0], "ordered", true);
            chosenId(choose());
            byte[] before = read(state());
            resetProcess();
            Mat.fail = failure == 0;
            Mat.returnNull = failure == 1;
            check(ORIGINAL.equals(choose()), "Failed or null Mat.New did not fall back.");
            check(Mat.calls == 1, "Material preload was not attempted exactly once.");
            check(equal(before, read(state())), "Failed material preload consumed state.");
            check(!new File(current, DATA + "/selection.lock").exists(), "Selection lock remained after material failure.");
        }
    }

    private static void testPersistenceFailureAfterPreload() throws Exception {
        fixture();
        configure(IDS, IDS[0], "ordered", true);
        final File blocker = state();
        Mat.onNew = new Runnable() {
            public void run() {
                if (!blocker.mkdir()) throw new RuntimeException("Cannot create state-write blocker.");
            }
        };
        check(ORIGINAL.equals(choose()), "State persistence failure after preload did not fall back.");
        check(Mat.calls == 1, "Persistence failure test did not reach preload.");
        check(blocker.isDirectory(), "Persistence failure modified the external obstruction.");
        check(!new File(current, DATA + "/selection.lock").exists(), "Owned lock remained after persistence failure.");
    }

    private static void testInvalidConfigurationNeverConsumesState() throws Exception {
        for (int invalid = 0; invalid < 6; invalid++) {
            fixture();
            configure(IDS, IDS[0], "ordered", true);
            chosenId(choose());
            byte[] before = read(state());
            Properties values = properties(config());
            if (invalid == 0) values.setProperty("images", "first,second");
            if (invalid == 1) values.setProperty("images", "first,first,third");
            if (invalid == 2) values.setProperty("official", "absent");
            if (invalid == 3) values.setProperty("mode", "invalid-mode");
            if (invalid == 4) values.setProperty("images", "first,../outside,third");
            if (invalid == 5) values.setProperty("images", "first,second,third");
            properties(config(), values);
            resetProcess();
            check(ORIGINAL.equals(choose()), "Invalid configuration was accepted (case " + invalid + ").");
            check(equal(before, read(state())), "Invalid configuration consumed state.");
            check(Mat.calls == 0, "Invalid configuration reached material preload.");
        }
    }

    private static void testInterruptedStateRecovery() throws Exception {
        for (int committed = 0; committed < 2; committed++) {
            fixture();
            configure(IDS, IDS[0], "ordered", true);
            chosenId(choose());
            byte[] before = read(state());
            File previous = new File(current, DATA + "/state.previous");
            File next = new File(current, DATA + "/state.next");
            inside(previous);
            if (committed == 0) check(state().renameTo(previous), "Cannot stage interrupted prior state.");
            else write(previous, before);
            write(next, "Incomplete staged state".getBytes("US-ASCII"));
            resetProcess();
            Mat.fail = true;
            check(ORIGINAL.equals(choose()), "Recovery followed by failed preload should fall back.");
            check(Mat.calls == 1, "Recovered state was not usable for selecting the next material.");
            check(equal(before, read(state())), "Recovery lost or consumed the previous selection.");
            check(!previous.exists() && !next.exists(), "Recovered transaction artifacts remain.");
        }
    }

    private static void testDuplicatePictureBytesRejected() throws Exception {
        fixture();
        configure(IDS, IDS[0], "ordered", true);
        chosenId(choose());
        byte[] before = read(state());
        write(image(IDS[1]), read(image(IDS[0])));
        resetProcess();
        check(ORIGINAL.equals(choose()), "Two identifiers with identical picture bytes were accepted.");
        check(equal(before, read(state())), "Duplicate pictures consumed saved state.");
        check(Mat.calls == 0, "Duplicate pictures reached material preload.");
    }

    private static void testStateDirectoriesAreNeverMovedOrDeleted() throws Exception {
        String[] filenames = { "state.properties", "state.previous", "state.next" };
        for (int index = 0; index < filenames.length; index++) {
            fixture();
            configure(IDS, IDS[0], "ordered", true);
            File blocker = new File(current, DATA + "/" + filenames[index]);
            inside(blocker);
            check(blocker.mkdirs(), "Cannot create fixture state obstruction.");
            check(ORIGINAL.equals(choose()), "State directory obstruction did not fall back.");
            check(blocker.isDirectory(), "A state-path directory was moved or deleted.");
            check(Mat.calls == 0, "A pre-existing state obstruction was not rejected before preload.");
        }
    }
    public static void main(String[] args) throws Exception {
        String originalDirectory = System.getProperty("user.dir");
        if (args.length != 1) throw new IllegalArgumentException("Pass one fresh fixture directory under the package build directory.");
        File allowed = new File(originalDirectory, "build").getCanonicalFile();
        testRoot = new File(args[0]).getCanonicalFile();
        if (!testRoot.getPath().startsWith(allowed.getPath() + File.separator)) throw new IOException("Fixtures must remain under " + allowed);
        if (testRoot.exists() || !testRoot.mkdirs()) throw new IOException("Fixture root must be a fresh directory: " + testRoot);
        String[] tests = {
            "testWeightedCycles", "testUniformCycles", "testImpossibleWeightedSelections",
            "testDisabledNoWrites", "testOnlyStartupMaterial", "testOneDecisionPerProcess",
            "testWeightedPersistentLaunches", "testLegacyWeightedStateMigration",
            "testMissingCandidateDoesNotConsumeState",
            "testCorruptCandidateDoesNotConsumeState", "testCorruptStateIsPreserved",
            "testInvalidStatePositionAndCycle", "testBusyLockIsPreserved",
            "testMaterialPreloadFailureDoesNotConsumeState", "testPersistenceFailureAfterPreload",
            "testInvalidConfigurationNeverConsumesState", "testInterruptedStateRecovery",
            "testDuplicatePictureBytesRejected", "testStateDirectoriesAreNeverMovedOrDeleted"
        };
        int failed = 0;
        Properties report = new Properties();
        report.setProperty("gameLaunched", "false");
        report.setProperty("nativeRenderingValidated", "false");
        report.setProperty("fixtureRoot", testRoot.getPath());
        report.setProperty("javaVersion", System.getProperty("java.version"));
        try {
            for (int index = 0; index < tests.length; index++) {
                String test = tests[index];
                report.setProperty("test." + index + ".name", test);
                try {
                    Method method = LoadingRotationTest.class.getDeclaredMethod(test, new Class[0]);
                    method.invoke(null, new Object[0]);
                    report.setProperty("test." + index + ".result", "PASS");
                    System.out.println("PASS: " + test);
                } catch (Throwable failure) {
                    failed++;
                    if (failure instanceof InvocationTargetException) failure = ((InvocationTargetException)failure).getTargetException();
                    StringWriter trace = new StringWriter();
                    failure.printStackTrace(new PrintWriter(trace));
                    report.setProperty("test." + index + ".result", "FAIL");
                    report.setProperty("test." + index + ".error", trace.toString());
                    System.out.println("FAIL: " + test + " - " + failure.toString());
                }
            }
        } finally {
            System.setProperty("user.dir", originalDirectory);
            Mat.reset();
        }
        report.setProperty("assertions", Integer.toString(assertions));
        report.setProperty("passed", Integer.toString(tests.length - failed));
        report.setProperty("failed", Integer.toString(failed));
        report.setProperty("result", failed == 0 ? "PASS" : "FAIL");
        File reportPath = new File(testRoot, "result.properties");
        properties(reportPath, report);
        System.out.println("Report: " + reportPath);
        System.out.println("Assertions: " + assertions + "; passed: " + (tests.length - failed) + "; failed: " + failed);
        if (failed != 0) throw new RuntimeException(failed + " loading rotation test(s) failed.");
    }
}

import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Arrays;
import java.util.StringTokenizer;
import java.io.ByteArrayInputStream;
import java.io.FilterInputStream;
import java.io.InputStream;
import jdk.internal.org.objectweb.asm.*;
import jdk.internal.org.objectweb.asm.tree.*;

/** Executes registration and the effective late loader with minimal API/input doubles.
 * This is NOT an IL-2 runtime/flight test. The installer separately verifies
 * all real 4.09m member signatures against the effective loose classes.
 */
public class TestCW21Loadouts implements Opcodes {
    public static class Property {
        public static final Map<Object, Map<String, Object>> values = new HashMap<>();
        public static void set(Object owner, String key, Object value) {
            values.computeIfAbsent(owner, k -> new HashMap<>()).put(key, value);
        }
        public static Object value(Object owner, String key, Object fallback) {
            Map<String, Object> map = values.get(owner);
            return map == null ? fallback : map.getOrDefault(key, fallback);
        }
        public static Object value(Class<?> owner, String key, Object fallback) {
            return value((Object)owner, key, fallback);
        }
    }
    public static class Finger {
        // Consistency double only, not a reimplementation of IL-2's hash.
        public static int Int(String value) { return value.hashCode(); }
        public static final byte[] kTable = {0};
        public static int incInt(int initial, String value) { return initial ^ value.hashCode(); }
        public static long LongFN(long initial, String value) { return initial ^ value.hashCode(); }
    }
    public static class HashMapInt {
        public final Map<Integer, Object> values = new HashMap<>();
        public int puts;
        public Object put(int key, Object value) { ++puts; return values.put(key, value); }
        public Object get(int key) { return values.get(key); }
    }
    // Input doubles only: this test does not implement SFS/Krypto decryption.
    // The fixture reproduces the two original loadouts, including trigger/ammo.
    public static class SFSInputStream extends ByteArrayInputStream {
        public SFSInputStream(long ignored) {
            super(("default,0 MGunBrowning303ki 300,0 MGunBrowning303ki 300,0 MGunBrowning303ki 300,0 MGunBrowning303ki 300\n"
                + "none, , , , \n").getBytes(java.nio.charset.StandardCharsets.US_ASCII));
        }
    }
    public static class KryptoInputFilter extends FilterInputStream {
        public KryptoInputFilter(InputStream input, int[] ignored) { super(input); }
    }
    public static class NumberTokenizer {
        private final StringTokenizer tokens;
        public NumberTokenizer(String value) { tokens = new StringTokenizer(value); }
        public String next(String fallback) { return tokens.hasMoreTokens() ? tokens.nextToken() : fallback; }
        public int next(int fallback) { return tokens.hasMoreTokens() ? Integer.parseInt(tokens.nextToken()) : fallback; }
    }
    public static class WeaponSlot {
        public final int trigger, bullets;
        public final String gun;
        public WeaponSlot(int trigger, String gun, int bullets) {
            this.trigger = trigger; this.gun = gun; this.bullets = bullets;
        }
    }
    private static String remap(String name) {
        return name.replace("com/maddox/rts/Property", "TestCW21Loadouts$Property")
            .replace("com/maddox/rts/Finger", "TestCW21Loadouts$Finger")
            .replace("com/maddox/util/HashMapInt", "TestCW21Loadouts$HashMapInt")
            .replace("com/maddox/il2/objects/air/Aircraft$_WeaponSlot", "TestCW21Loadouts$WeaponSlot")
            .replace("com/maddox/il2/objects/air/Aircraft", "CW21LoaderProbe")
            .replace("com/maddox/rts/SFSInputStream", "TestCW21Loadouts$SFSInputStream")
            .replace("com/maddox/rts/KryptoInputFilter", "TestCW21Loadouts$KryptoInputFilter")
            .replace("com/maddox/util/NumberTokenizer", "TestCW21Loadouts$NumberTokenizer");
    }
    private static void check(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }
    private static void remapMethod(MethodNode method) {
        method.desc = remap(method.desc);
        for (AbstractInsnNode insn : method.instructions) {
            if (insn instanceof TypeInsnNode) {
                TypeInsnNode type = (TypeInsnNode)insn;
                type.desc = remap(type.desc);
            } else if (insn instanceof MethodInsnNode) {
                MethodInsnNode call = (MethodInsnNode)insn;
                call.owner = remap(call.owner); call.desc = remap(call.desc);
            } else if (insn instanceof FieldInsnNode) {
                FieldInsnNode field = (FieldInsnNode)insn;
                field.owner = remap(field.owner); field.desc = remap(field.desc);
            }
        }
    }
    private static class ProbeLoader extends ClassLoader {
        ProbeLoader() { super(TestCW21Loadouts.class.getClassLoader()); }
        Class<?> define(byte[] bytes) { return defineClass(null, bytes, 0, bytes.length); }
    }
    public static void main(String[] args) throws Exception {
        ClassNode aircraft = new ClassNode();
        new ClassReader(Files.readAllBytes(Paths.get(args[0]))).accept(aircraft, 0);
        check(aircraft.version == 47, "not Java 1.3");
        MethodNode registration = null;
        int calls = 0;
        for (MethodNode method : aircraft.methods) {
            if (method.name.equals("osRegisterLoadouts")) registration = method;
            if (method.name.equals("<clinit>")) for (AbstractInsnNode insn : method.instructions) {
                if (insn instanceof MethodInsnNode && ((MethodInsnNode)insn).name.equals("osRegisterLoadouts")) ++calls;
            }
        }
        check(registration != null && calls == 1, "registration absent or not invoked exactly once");
        registration.access = ACC_PUBLIC | ACC_STATIC;
        remapMethod(registration);
        ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
        writer.visit(47, ACC_PUBLIC, "CW21RegistrationProbe", null, "java/lang/Object", null);
        registration.accept(writer);
        writer.visitEnd();
        byte[] bytes = writer.toByteArray();
        ProbeLoader loader = new ProbeLoader();
        if (args.length > 2) {
            byte[] helper = Files.readAllBytes(Paths.get(args[2]));
            check(new ClassReader(helper).readShort(6) == 47, "helper not Java 1.3");
            Class<?> helperClass = loader.define(helper);
            Object example = helperClass.getConstructor().newInstance();
            java.lang.reflect.Method add = helperClass.getMethod("add", Object.class);
            check(Boolean.TRUE.equals(add.invoke(example, "future_choice")), "new choice rejected");
            check(Boolean.FALSE.equals(add.invoke(example, new String("future_choice"))), "equal choice duplicated");
            check(Boolean.TRUE.equals(add.invoke(example, "another_choice")), "distinct choice rejected");
            check(((ArrayList<?>)example).equals(Arrays.asList("future_choice", "another_choice")),
                "helper changed first occurrence order");
        }
        Class<?> probe = loader.define(bytes);
        ClassNode realAircraft = new ClassNode();
        new ClassReader(Files.readAllBytes(Paths.get(args[1]))).accept(realAircraft, ClassReader.SKIP_FRAMES);
        ClassWriter loaderWriter = new ClassWriter(ClassWriter.COMPUTE_MAXS);
        loaderWriter.visit(47, ACC_PUBLIC, "CW21LoaderProbe", null, "java/lang/Object", null);
        int loaderMethods = 0;
        for (MethodNode method : realAircraft.methods) {
            if (Arrays.asList("weapons", "getSwTbl", "weaponsListProperty", "weaponsMapProperty",
                              "getWeaponsRegistered", "getWeaponSlotsRegistered").contains(method.name)) {
                remapMethod(method);
                method.accept(loaderWriter);
                ++loaderMethods;
            }
        }
        check(loaderMethods == 6, "effective loader contract changed");
        loaderWriter.visitEnd();
        Class<?> realLoader = loader.define(loaderWriter.toByteArray());
        for (int pass = 0; pass < 2; ++pass) {
            probe.getMethod("osRegisterLoadouts", Class.class).invoke(null, TestCW21Loadouts.class);
            for (int importPass = 0; importPass < 3; ++importPass) {
                // Exercise the actual Aircraft.weapons bytecode after registration,
                // not just the isolated initializer that missed the reported bug.
                if (importPass != 0) realLoader.getMethod("weapons", Class.class).invoke(null, TestCW21Loadouts.class);
                String[] visible = (String[])realLoader.getMethod("getWeaponsRegistered", Class.class)
                    .invoke(null, TestCW21Loadouts.class);
                check(Arrays.equals(visible, new String[]{"default", "2x303_2x50", "none"}),
                    "late loader duplicated menu: " + Arrays.toString(visible));
                Map<String, Object> properties = Property.values.get(TestCW21Loadouts.class);
                ArrayList<?> names = (ArrayList<?>)properties.get("weaponsList");
                check(names.equals(Arrays.asList("default", "2x303_2x50", "none")), "wrong list/order");
                HashMapInt map = (HashMapInt)properties.get("weaponsMap");
                check(map.values.size() == 3, "wrong map size");
                check(map.puts == 3 + 2 * importPass, "late loader did not finish importing both stock choices");
                for (Object name : names) {
                    WeaponSlot[] slots = (WeaponSlot[])map.values.get(Finger.Int((String)name));
                    check(slots != null && slots.length == 4, "hook/slot count mismatch");
                    for (int i = 0; i < 4; ++i) {
                        if (name.equals("none")) check(slots[i] == null, "armed none");
                        else {
                            boolean heavy = name.equals("2x303_2x50") && i >= 2;
                            check(slots[i].trigger == 0, "wrong trigger");
                            check(slots[i].gun.equals(heavy ? "MGunBrowning50si" : "MGunBrowning303ki"), "wrong gun");
                            check(slots[i].bullets == (heavy ? 230 : 300), "wrong ammunition");
                        }
                    }
                }
            }
        }
        System.out.println("PASS: emitted registration AND effective late loader; three unique choices, four hooks, exact guns/ammunition, repeat safe. Runtime pending.");
    }
}

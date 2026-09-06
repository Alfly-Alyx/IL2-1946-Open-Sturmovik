import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import jdk.internal.org.objectweb.asm.*;
import jdk.internal.org.objectweb.asm.tree.*;

/** Executes the emitted registration method with deliberately minimal API doubles.
 * This is NOT an IL-2 runtime/flight test. The installer separately verifies
 * all real 4.09m member signatures against the effective loose classes.
 */
public class TestCW21Loadouts implements Opcodes {
    public static class Property {
        public static final Map<Object, Map<String, Object>> values = new HashMap<>();
        public static void set(Object owner, String key, Object value) {
            values.computeIfAbsent(owner, k -> new HashMap<>()).put(key, value);
        }
    }
    public static class Finger {
        // Consistency double only, not a reimplementation of IL-2's hash.
        public static int Int(String value) { return value.hashCode(); }
    }
    public static class HashMapInt {
        public final Map<Integer, Object> values = new HashMap<>();
        public Object put(int key, Object value) { return values.put(key, value); }
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
            .replace("com/maddox/il2/objects/air/Aircraft$_WeaponSlot", "TestCW21Loadouts$WeaponSlot");
    }
    private static void check(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
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
        for (AbstractInsnNode insn : registration.instructions) {
            if (insn instanceof TypeInsnNode) {
                TypeInsnNode type = (TypeInsnNode)insn;
                type.desc = remap(type.desc);
            } else if (insn instanceof MethodInsnNode) {
                MethodInsnNode call = (MethodInsnNode)insn;
                call.owner = remap(call.owner); call.desc = remap(call.desc);
            }
        }
        ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
        writer.visit(47, ACC_PUBLIC, "CW21RegistrationProbe", null, "java/lang/Object", null);
        registration.accept(writer);
        writer.visitEnd();
        byte[] bytes = writer.toByteArray();
        Class<?> probe = new ClassLoader(TestCW21Loadouts.class.getClassLoader()) {
            Class<?> define() { return defineClass(null, bytes, 0, bytes.length); }
        }.define();
        for (int pass = 0; pass < 2; ++pass) {
            probe.getMethod("osRegisterLoadouts", Class.class).invoke(null, TestCW21Loadouts.class);
            Map<String, Object> properties = Property.values.get(TestCW21Loadouts.class);
            ArrayList<?> names = (ArrayList<?>)properties.get("weaponsList");
            check(names.equals(java.util.Arrays.asList("default", "2x303_2x50", "none")), "wrong list/order");
            HashMapInt map = (HashMapInt)properties.get("weaponsMap");
            check(map.values.size() == 3, "wrong map size");
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
        System.out.println("PASS: emitted registration executes; three choices, four hooks, exact guns/ammunition, repeat safe. Runtime pending.");
    }
}

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import jdk.internal.org.objectweb.asm.ClassReader;
import jdk.internal.org.objectweb.asm.ClassWriter;
import jdk.internal.org.objectweb.asm.Opcodes;
import jdk.internal.org.objectweb.asm.tree.AbstractInsnNode;
import jdk.internal.org.objectweb.asm.tree.ClassNode;
import jdk.internal.org.objectweb.asm.tree.InsnList;
import jdk.internal.org.objectweb.asm.tree.InsnNode;
import jdk.internal.org.objectweb.asm.tree.FieldInsnNode;
import jdk.internal.org.objectweb.asm.tree.LdcInsnNode;
import jdk.internal.org.objectweb.asm.tree.MethodInsnNode;
import jdk.internal.org.objectweb.asm.tree.MethodNode;
import jdk.internal.org.objectweb.asm.tree.VarInsnNode;
import jdk.internal.org.objectweb.asm.tree.TypeInsnNode;
import jdk.internal.org.objectweb.asm.tree.analysis.Analyzer;
import jdk.internal.org.objectweb.asm.tree.analysis.AnalyzerException;
import jdk.internal.org.objectweb.asm.tree.analysis.BasicInterpreter;
import jdk.internal.org.objectweb.asm.tree.analysis.BasicValue;

public final class OpenSturmovikAircraftPatcher implements Opcodes {
    private static final int JAVA_13_CLASS_VERSION = 47;
    private static final String KB_29P = "com/maddox/il2/objects/air/KB_29P";
    private static final String KB_29 = "com/maddox/il2/objects/air/KB_29";
    private static final String PROPERTY = "com/maddox/rts/Property";
    private static final String COCKPIT_B29 = "com.maddox.il2.objects.air.CockpitB29";

    private OpenSturmovikAircraftPatcher() {
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2 && args.length != 3) {
            throw new IllegalArgumentException("Expected: sourceClass outputClass [CW-21]");
        }

        Path source = Paths.get(args[0]);
        Path output = Paths.get(args[1]);
        boolean cw21 = args.length == 3 && "CW-21".equals(args[2]);
        if (args.length == 3 && !cw21) {
            throw new IllegalArgumentException("Unsupported aircraft selector");
        }
        byte[] patched = patchCockpit(Files.readAllBytes(source),
            cw21 ? "com/maddox/il2/objects/air/CW_21" : KB_29P,
            cw21 ? "com/maddox/il2/objects/air/CW21xyz" : KB_29,
            cw21 ? "com.maddox.il2.objects.air.CockpitCW_21" : COCKPIT_B29,
            cw21 ? "FlightModels/CW-21.fmd" : "FlightModels/B-29.fmd");
        Files.createDirectories(output.getParent());
        Files.write(output, patched);
    }

    private static byte[] patchCockpit(byte[] source, String aircraft, String parent,
                                      String cockpit, String flightModel) throws Exception {
        ClassNode node = parse(source);
        if (node.version != JAVA_13_CLASS_VERSION ||
            !aircraft.equals(node.name) ||
            !parent.equals(node.superName)) {
            throw new IllegalStateException("Unexpected aircraft identity or Java version");
        }

        MethodNode initializer = findMethod(node, "<clinit>", "()V");
        if (containsString(initializer, "cockpitClass")) {
            throw new IllegalStateException("Aircraft already declares a cockpitClass");
        }
        if (!containsString(initializer, flightModel)) {
            throw new IllegalStateException("Unexpected aircraft flight model");
        }
        int originalObjectPropertyCalls = countCalls(
            initializer,
            PROPERTY,
            "set",
            "(Ljava/lang/Object;Ljava/lang/String;Ljava/lang/Object;)V"
        );

        AbstractInsnNode returnInstruction = null;
        for (AbstractInsnNode instruction = initializer.instructions.getFirst();
             instruction != null;
             instruction = instruction.getNext()) {
            if (instruction.getOpcode() == RETURN) {
                if (returnInstruction != null) {
                    throw new IllegalStateException("KB-29P has more than one static return");
                }
                returnInstruction = instruction;
            }
        }
        if (returnInstruction == null) {
            throw new IllegalStateException("KB-29P static initializer has no return");
        }

        InsnList cockpitProperty = new InsnList();
        cockpitProperty.add(new VarInsnNode(ALOAD, 0));
        cockpitProperty.add(new LdcInsnNode("cockpitClass"));
        cockpitProperty.add(new LdcInsnNode(cockpit));
        cockpitProperty.add(new MethodInsnNode(
            INVOKESTATIC,
            aircraft,
            "class$",
            "(Ljava/lang/String;)Ljava/lang/Class;",
            false
        ));
        cockpitProperty.add(new MethodInsnNode(
            INVOKESTATIC,
            PROPERTY,
            "set",
            "(Ljava/lang/Object;Ljava/lang/String;Ljava/lang/Object;)V",
            false
        ));
        initializer.instructions.insertBefore(returnInstruction, cockpitProperty);

        if (aircraft.endsWith("/CW_21")) {
            // Aircraft.weaponsRegister is EMPTY in the effective 4.09m class.
            // Use the donor port's weaponsList/weaponsMap contract instead.
            node.methods.add(cw21Loadouts());
            node.methods.add(cw21SoundDiagnostic(parent));
            InsnList weapons = new InsnList();
            weapons.add(new VarInsnNode(ALOAD, 0));
            weapons.add(new MethodInsnNode(INVOKESTATIC, aircraft,
                "osRegisterLoadouts", "(Ljava/lang/Class;)V", false));
            initializer.instructions.insertBefore(returnInstruction, weapons);
        }

        node.version = JAVA_13_CLASS_VERSION;
        ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
        node.accept(writer);
        byte[] result = writer.toByteArray();

        ClassNode verification = parse(result);
        MethodNode verifiedInitializer = findMethod(verification, "<clinit>", "()V");
        if (!containsString(verifiedInitializer, "cockpitClass") ||
            !containsString(verifiedInitializer, cockpit) ||
            countCalls(
                verifiedInitializer,
                PROPERTY,
                "set",
                "(Ljava/lang/Object;Ljava/lang/String;Ljava/lang/Object;)V"
            ) != originalObjectPropertyCalls + 1) {
            throw new IllegalStateException("KB-29P cockpit property was not emitted exactly once");
        }
        verifyBytecode(verification);
        return result;
    }

    private static MethodNode cw21Loadouts() {
        MethodNode method = new MethodNode(ACC_PRIVATE | ACC_STATIC,
            "osRegisterLoadouts", "(Ljava/lang/Class;)V", null, null);
        InsnList code = method.instructions;
        String slot = "com/maddox/il2/objects/air/Aircraft$_WeaponSlot";
        String map = "com/maddox/util/HashMapInt";
        String[] containers = {"java/util/ArrayList", map};
        for (int i = 0; i < containers.length; ++i) {
            code.add(new TypeInsnNode(NEW, containers[i]));
            code.add(new InsnNode(DUP));
            code.add(new MethodInsnNode(INVOKESPECIAL, containers[i], "<init>", "()V", false));
            code.add(new VarInsnNode(ASTORE, i + 1));
        }
        String[] names = {"default", "2x303_2x50", "none"};
        for (int loadout = 0; loadout < names.length; ++loadout) {
            // Four hooks, four slots. The donor's surplus sixteen null slots
            // are unnecessary; the stock CW-21 defines exactly four hooks.
            code.add(new InsnNode(ICONST_4));
            code.add(new TypeInsnNode(ANEWARRAY, slot));
            code.add(new VarInsnNode(ASTORE, 3));
            if (loadout != 2) {
                for (int i = 0; i < 4; ++i) {
                    boolean heavy = loadout == 1 && i >= 2;
                    code.add(new VarInsnNode(ALOAD, 3));
                    code.add(new InsnNode(ICONST_0 + i));
                    code.add(new TypeInsnNode(NEW, slot));
                    code.add(new InsnNode(DUP));
                    code.add(new InsnNode(ICONST_0));
                    code.add(new LdcInsnNode(heavy ? "MGunBrowning50si" : "MGunBrowning303ki"));
                    code.add(new LdcInsnNode(heavy ? 230 : 300));
                    code.add(new MethodInsnNode(INVOKESPECIAL, slot, "<init>",
                        "(ILjava/lang/String;I)V", false));
                    code.add(new InsnNode(AASTORE));
                }
            }
            code.add(new VarInsnNode(ALOAD, 1));
            code.add(new LdcInsnNode(names[loadout]));
            code.add(new MethodInsnNode(INVOKEVIRTUAL, "java/util/ArrayList", "add",
                "(Ljava/lang/Object;)Z", false));
            code.add(new InsnNode(POP));
            code.add(new VarInsnNode(ALOAD, 2));
            code.add(new LdcInsnNode(names[loadout]));
            code.add(new MethodInsnNode(INVOKESTATIC, "com/maddox/rts/Finger", "Int",
                "(Ljava/lang/String;)I", false));
            code.add(new VarInsnNode(ALOAD, 3));
            code.add(new MethodInsnNode(INVOKEVIRTUAL, map, "put",
                "(ILjava/lang/Object;)Ljava/lang/Object;", false));
            code.add(new InsnNode(POP));
        }
        // Publish only after all slots have been constructed successfully.
        String[] properties = {"weaponsList", "weaponsMap"};
        for (int i = 0; i < properties.length; ++i) {
            code.add(new VarInsnNode(ALOAD, 0));
            code.add(new LdcInsnNode(properties[i]));
            code.add(new VarInsnNode(ALOAD, i + 1));
            code.add(new MethodInsnNode(INVOKESTATIC, PROPERTY, "set",
                "(Ljava/lang/Object;Ljava/lang/String;Ljava/lang/Object;)V", false));
        }
        code.add(new InsnNode(RETURN));
        return method;
    }

    private static MethodNode cw21SoundDiagnostic(String parent) {
        // Observe the resolved engine, without changing audio or flight physics.
        // A single line per loaded CW-21 is enough for the next listening test.
        MethodNode method = new MethodNode(ACC_PUBLIC, "onAircraftLoaded", "()V", null, null);
        InsnList code = method.instructions;
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new MethodInsnNode(INVOKESPECIAL, parent, "onAircraftLoaded", "()V", false));
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new FieldInsnNode(GETFIELD, "com/maddox/il2/objects/sounds/SndAircraft",
            "FM", "Lcom/maddox/il2/fm/FlightModel;"));
        code.add(new FieldInsnNode(GETFIELD, "com/maddox/il2/fm/FlightModelMain",
            "EI", "Lcom/maddox/il2/fm/EnginesInterface;"));
        code.add(new FieldInsnNode(GETFIELD, "com/maddox/il2/fm/EnginesInterface",
            "engines", "[Lcom/maddox/il2/fm/Motor;"));
        code.add(new InsnNode(ICONST_0));
        code.add(new InsnNode(AALOAD));
        code.add(new VarInsnNode(ASTORE, 1));
        code.add(new FieldInsnNode(GETSTATIC, "java/lang/System", "out", "Ljava/io/PrintStream;"));
        code.add(new TypeInsnNode(NEW, "java/lang/StringBuffer"));
        code.add(new InsnNode(DUP));
        code.add(new LdcInsnNode("[OS CW-21]"));
        code.add(new MethodInsnNode(INVOKESPECIAL, "java/lang/StringBuffer", "<init>",
            "(Ljava/lang/String;)V", false));
        String[] fields = {"soundName", "startStopName", "propName"};
        for (String field : fields) {
            code.add(new LdcInsnNode(" " + field + "="));
            code.add(new MethodInsnNode(INVOKEVIRTUAL, "java/lang/StringBuffer", "append",
                "(Ljava/lang/String;)Ljava/lang/StringBuffer;", false));
            code.add(new VarInsnNode(ALOAD, 1));
            code.add(new FieldInsnNode(GETFIELD, "com/maddox/il2/fm/Motor", field,
                "Ljava/lang/String;"));
            code.add(new MethodInsnNode(INVOKEVIRTUAL, "java/lang/StringBuffer", "append",
                "(Ljava/lang/String;)Ljava/lang/StringBuffer;", false));
        }
        code.add(new MethodInsnNode(INVOKEVIRTUAL, "java/lang/StringBuffer", "toString",
            "()Ljava/lang/String;", false));
        code.add(new MethodInsnNode(INVOKEVIRTUAL, "java/io/PrintStream", "println",
            "(Ljava/lang/String;)V", false));
        code.add(new InsnNode(RETURN));
        return method;
    }

    private static ClassNode parse(byte[] data) {
        ClassNode node = new ClassNode();
        new ClassReader(data).accept(node, ClassReader.SKIP_FRAMES);
        return node;
    }

    private static MethodNode findMethod(ClassNode node, String name, String descriptor) {
        for (MethodNode method : node.methods) {
            if (name.equals(method.name) && descriptor.equals(method.desc)) {
                return method;
            }
        }
        throw new IllegalStateException("Method not found: " + name + descriptor);
    }

    private static boolean containsString(MethodNode method, String value) {
        for (AbstractInsnNode instruction = method.instructions.getFirst();
             instruction != null;
             instruction = instruction.getNext()) {
            if (instruction instanceof LdcInsnNode && value.equals(((LdcInsnNode)instruction).cst)) {
                return true;
            }
        }
        return false;
    }

    private static int countCalls(MethodNode method, String owner, String name, String descriptor) {
        int count = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst();
             instruction != null;
             instruction = instruction.getNext()) {
            if (!(instruction instanceof MethodInsnNode)) {
                continue;
            }
            MethodInsnNode call = (MethodInsnNode)instruction;
            if (owner.equals(call.owner) && name.equals(call.name) && descriptor.equals(call.desc)) {
                ++count;
            }
        }
        return count;
    }

    private static void verifyBytecode(ClassNode node) {
        for (MethodNode method : node.methods) {
            if ((method.access & (ACC_ABSTRACT | ACC_NATIVE)) != 0) {
                continue;
            }
            try {
                new Analyzer<BasicValue>(new BasicInterpreter()).analyze(node.name, method);
            }
            catch (AnalyzerException error) {
                throw new IllegalStateException(
                    "Invalid bytecode in " + node.name + "." + method.name + method.desc,
                    error
                );
            }
        }
    }
}

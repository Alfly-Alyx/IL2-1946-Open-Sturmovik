import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import jdk.internal.org.objectweb.asm.ClassReader;
import jdk.internal.org.objectweb.asm.ClassWriter;
import jdk.internal.org.objectweb.asm.Opcodes;
import jdk.internal.org.objectweb.asm.tree.AbstractInsnNode;
import jdk.internal.org.objectweb.asm.tree.ClassNode;
import jdk.internal.org.objectweb.asm.tree.FieldInsnNode;
import jdk.internal.org.objectweb.asm.tree.FieldNode;
import jdk.internal.org.objectweb.asm.tree.InsnList;
import jdk.internal.org.objectweb.asm.tree.InsnNode;
import jdk.internal.org.objectweb.asm.tree.JumpInsnNode;
import jdk.internal.org.objectweb.asm.tree.LabelNode;
import jdk.internal.org.objectweb.asm.tree.LdcInsnNode;
import jdk.internal.org.objectweb.asm.tree.MethodInsnNode;
import jdk.internal.org.objectweb.asm.tree.MethodNode;
import jdk.internal.org.objectweb.asm.tree.TypeInsnNode;
import jdk.internal.org.objectweb.asm.tree.VarInsnNode;
import jdk.internal.org.objectweb.asm.tree.analysis.Analyzer;
import jdk.internal.org.objectweb.asm.tree.analysis.BasicInterpreter;
import jdk.internal.org.objectweb.asm.tree.analysis.BasicValue;

/**
 * Merge the complete AOC 1a engine consumers recovered from HSFX 4 into the
 * compatible 4.09m base; the retired mission extension is absent from the inputs.
 */
public final class OpenSturmovikAocPatcher implements Opcodes {
    private static final int JAVA_13_CLASS_VERSION = 47;
    private static final String FMM = "com/maddox/il2/fm/FlightModelMain";
    private static final String MOTOR = "com/maddox/il2/fm/Motor";
    private static final String FLIGHT_MODEL = "com/maddox/il2/fm/FlightModel";
    private static final String REAL_FLIGHT_MODEL = "com/maddox/il2/fm/RealFlightModel";
    private static final String HUD = "com/maddox/il2/game/HUD";

    private OpenSturmovikAocPatcher() {
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 5) {
            throw new IllegalArgumentException(
                "Expected: baseFlightModelMain baseMotor baseRealFlightModel donorAocMotor outputDir"
            );
        }

        Path output = Paths.get(args[4]);
        Files.createDirectories(output);

        byte[] flightModelMain = patchFlightModelMain(Files.readAllBytes(Paths.get(args[0])));
        byte[] motor = patchMotor(
            Files.readAllBytes(Paths.get(args[1])),
            Files.readAllBytes(Paths.get(args[3]))
        );
        byte[] realFlightModel = patchRealFlightModel(Files.readAllBytes(Paths.get(args[2])));

        requireNoRetiredExtension(flightModelMain);
        requireNoRetiredExtension(motor);
        requireNoRetiredExtension(realFlightModel);
        validateFlightModelMain(flightModelMain);
        validateMotor(motor);
        validateRealFlightModel(realFlightModel);

        Files.write(output.resolve("FlightModelMain.class"), flightModelMain);
        Files.write(output.resolve("Motor.class"), motor);
        Files.write(output.resolve("RealFlightModel.class"), realFlightModel);
    }

    private static void requireNoRetiredExtension(byte[] data) {
        String raw = new String(data, java.nio.charset.StandardCharsets.ISO_8859_1);
        if (raw.toLowerCase(java.util.Locale.ROOT).contains("zuti")) {
            throw new IllegalStateException("Retired mission extension remains in AOC class");
        }
    }
    private static byte[] patchFlightModelMain(byte[] data) {
        ClassNode node = parse(data);
        requireClass(node, FMM);
        requireVersion(node);

        int replacements = 0;
        for (MethodNode method : node.methods) {
            for (AbstractInsnNode instruction = method.instructions.getFirst();
                 instruction != null;
                 instruction = instruction.getNext()) {
                if (!(instruction instanceof LdcInsnNode)) {
                    continue;
                }
                LdcInsnNode constant = (LdcInsnNode)instruction;
                if ("Mod_AOC_Public/".equals(constant.cst)) {
                    constant.cst = "_Game_Enhancements/Mod_AOC_Public/";
                    ++replacements;
                } else if ("Mod_AOC_Public/Defaut.txt".equals(constant.cst)) {
                    constant.cst = "_Game_Enhancements/Mod_AOC_Public/Defaut.txt";
                    ++replacements;
                }
            }
        }
        if (replacements != 2) {
            throw new IllegalStateException("Expected two AOC profile path constants, got " + replacements);
        }

        return write(node);
    }

    private static byte[] patchMotor(byte[] baseData, byte[] donorData) {
        ClassNode base = parse(baseData);
        ClassNode donor = parse(donorData);
        requireClass(base, MOTOR);
        requireClass(donor, MOTOR);
        requireVersion(base);
        requireVersion(donor);


        copyFieldIfMissing(base, donor, "t_underheat", "F");
        copyFieldIfMissing(base, donor, "coef_coldstart", "I");
        copyFieldIfMissing(base, donor, "t_undergnegat", "F");

        MethodNode starts = replaceMethod(base, donor, "doSetEngineStarts", "()V");
        replaceAirportDistance(starts, 1);
        MethodNode stage = replaceMethod(base, donor, "computeStage", "(F)V");
        replaceAirportDistance(stage, 2);
        replaceMethod(base, donor, "computeTemperature", "(F)V");

        MethodNode forces = requireMethod(base, "computeForces", "(F)V");
        insertFuelQualityMultiplier(forces);
        addEngineInformationMethod(base);
        insertEngineInformationCall(forces);

        return write(base);
    }

    private static byte[] patchRealFlightModel(byte[] data) {
        ClassNode node = parse(data);
        requireClass(node, REAL_FLIGHT_MODEL);
        requireVersion(node);
        MethodNode update = requireMethod(node, "update", "(F)V");

        int additions = 0;
        for (AbstractInsnNode instruction = update.instructions.getFirst();
             instruction != null;) {
            AbstractInsnNode next = instruction.getNext();
            if (instruction instanceof FieldInsnNode) {
                FieldInsnNode field = (FieldInsnNode)instruction;
                if (field.getOpcode() == GETFIELD && MOTOR.equals(field.owner) &&
                    "addVside".equals(field.name) && "D".equals(field.desc)) {
                    VarInsnNode store = findNextDoubleStore(instruction, 8);
                    InsnList multiplier = new InsnList();
                    multiplier.add(new VarInsnNode(DLOAD, store.var));
                    multiplier.add(new VarInsnNode(ALOAD, 0));
                    multiplier.add(new FieldInsnNode(GETFIELD, FMM, "coefTorque", "F"));
                    multiplier.add(new InsnNode(F2D));
                    multiplier.add(new InsnNode(DMUL));
                    multiplier.add(new VarInsnNode(DSTORE, store.var));
                    update.instructions.insert(store, multiplier);
                    ++additions;
                    next = store.getNext();
                }
            }
            instruction = next;
        }
        if (additions != 2) {
            throw new IllegalStateException("Expected two propeller torque sites, got " + additions);
        }

        return write(node);
    }

    private static void insertFuelQualityMultiplier(MethodNode method) {
        FieldInsnNode anchor = null;
        int anchors = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst();
             instruction != null;
             instruction = instruction.getNext()) {
            if (instruction instanceof FieldInsnNode) {
                FieldInsnNode field = (FieldInsnNode)instruction;
                if (field.getOpcode() == PUTFIELD && MOTOR.equals(field.owner) &&
                    "momForFuel".equals(field.name) && "D".equals(field.desc)) {
                    anchor = field;
                    ++anchors;
                }
            }
        }
        if (anchors != 1 || anchor == null) {
            throw new IllegalStateException("Expected one momForFuel assignment, got " + anchors);
        }

        InsnList code = new InsnList();
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new InsnNode(DUP));
        code.add(new FieldInsnNode(GETFIELD, MOTOR, "engineMoment", "F"));
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new FieldInsnNode(GETFIELD, MOTOR, "reference", "Lcom/maddox/il2/fm/FlightModel;"));
        code.add(new FieldInsnNode(GETFIELD, FMM, "coefQualFuel", "F"));
        code.add(new InsnNode(FMUL));
        code.add(new FieldInsnNode(PUTFIELD, MOTOR, "engineMoment", "F"));
        method.instructions.insert(anchor, code);
    }

    private static void insertEngineInformationCall(MethodNode method) {
        FieldInsnNode anchor = null;
        int anchors = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst();
             instruction != null;
             instruction = instruction.getNext()) {
            if (!(instruction instanceof MethodInsnNode)) {
                continue;
            }
            MethodInsnNode call = (MethodInsnNode)instruction;
            if (!MOTOR.equals(call.owner) || !"getFrictionMoment".equals(call.name) ||
                !"(F)F".equals(call.desc)) {
                continue;
            }
            AbstractInsnNode candidate = nextOpcode(instruction);
            while (candidate != null && !(candidate instanceof FieldInsnNode)) {
                candidate = nextOpcode(candidate);
            }
            if (candidate instanceof FieldInsnNode) {
                FieldInsnNode field = (FieldInsnNode)candidate;
                if (field.getOpcode() == PUTFIELD && MOTOR.equals(field.owner) &&
                    "engineMoment".equals(field.name) && "F".equals(field.desc)) {
                    anchor = field;
                    ++anchors;
                }
            }
        }
        if (anchors != 1 || anchor == null) {
            throw new IllegalStateException("Expected one friction-adjusted engine moment, got " + anchors);
        }

        LabelNode skip = new LabelNode();
        InsnList code = new InsnList();
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new FieldInsnNode(GETFIELD, MOTOR, "reference", "Lcom/maddox/il2/fm/FlightModel;"));
        code.add(new FieldInsnNode(GETFIELD, FMM, "bInfoMotor", "Z"));
        code.add(new JumpInsnNode(IFEQ, skip));
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new MethodInsnNode(INVOKESPECIAL, MOTOR, "aocLogEngineInfo", "()V", false));
        code.add(skip);
        method.instructions.insert(anchor, code);
    }

    private static void addEngineInformationMethod(ClassNode node) {
        if (findMethod(node, "aocLogEngineInfo", "()V") != null) {
            throw new IllegalStateException("AOC engine information method already exists");
        }

        MethodNode method = new MethodNode(ACC_PRIVATE, "aocLogEngineInfo", "()V", null, null);
        InsnList code = method.instructions;
        code.add(new TypeInsnNode(NEW, "java/lang/StringBuffer"));
        code.add(new InsnNode(DUP));
        code.add(new MethodInsnNode(INVOKESPECIAL, "java/lang/StringBuffer", "<init>", "()V", false));
        appendText(code, "P_mot: ");
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new FieldInsnNode(GETFIELD, MOTOR, "engineMoment", "F"));
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new FieldInsnNode(GETFIELD, MOTOR, "w", "F"));
        code.add(new InsnNode(FMUL));
        code.add(new LdcInsnNode(Float.valueOf(746.0F)));
        code.add(new InsnNode(FDIV));
        code.add(new InsnNode(F2I));
        code.add(new MethodInsnNode(INVOKEVIRTUAL, "java/lang/StringBuffer", "append", "(I)Ljava/lang/StringBuffer;", false));
        appendText(code, " hp  P_hel: ");
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new FieldInsnNode(GETFIELD, MOTOR, "propMoment", "F"));
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new FieldInsnNode(GETFIELD, MOTOR, "w", "F"));
        code.add(new InsnNode(FMUL));
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new FieldInsnNode(GETFIELD, MOTOR, "propReductor", "F"));
        code.add(new InsnNode(FMUL));
        code.add(new LdcInsnNode(Float.valueOf(746.0F)));
        code.add(new InsnNode(FDIV));
        code.add(new InsnNode(F2I));
        code.add(new MethodInsnNode(INVOKEVIRTUAL, "java/lang/StringBuffer", "append", "(I)Ljava/lang/StringBuffer;", false));
        appendText(code, " hp  T_hel: ");
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new FieldInsnNode(GETFIELD, MOTOR, "propForce", "F"));
        code.add(new LdcInsnNode(Float.valueOf(10.0F)));
        code.add(new InsnNode(FDIV));
        code.add(new InsnNode(F2I));
        code.add(new MethodInsnNode(INVOKEVIRTUAL, "java/lang/StringBuffer", "append", "(I)Ljava/lang/StringBuffer;", false));
        appendText(code, " daN");
        code.add(new MethodInsnNode(INVOKEVIRTUAL, "java/lang/StringBuffer", "toString", "()Ljava/lang/String;", false));
        code.add(new MethodInsnNode(INVOKESTATIC, HUD, "log", "(Ljava/lang/String;)V", false));
        code.add(new InsnNode(RETURN));
        node.methods.add(method);
    }

    private static void appendText(InsnList code, String text) {
        code.add(new LdcInsnNode(text));
        code.add(new MethodInsnNode(
            INVOKEVIRTUAL,
            "java/lang/StringBuffer",
            "append",
            "(Ljava/lang/String;)Ljava/lang/StringBuffer;",
            false
        ));
    }

    private static VarInsnNode findNextDoubleStore(AbstractInsnNode start, int maximumOpcodes) {
        int seen = 0;
        for (AbstractInsnNode instruction = start.getNext();
             instruction != null && seen < maximumOpcodes;
             instruction = instruction.getNext()) {
            if (instruction.getOpcode() < 0) {
                continue;
            }
            ++seen;
            if (instruction instanceof VarInsnNode && instruction.getOpcode() == DSTORE) {
                return (VarInsnNode)instruction;
            }
        }
        throw new IllegalStateException("No nearby DSTORE after Motor.addVside");
    }

    private static AbstractInsnNode nextOpcode(AbstractInsnNode instruction) {
        AbstractInsnNode next = instruction.getNext();
        while (next != null && next.getOpcode() < 0) {
            next = next.getNext();
        }
        return next;
    }

    private static MethodNode replaceMethod(ClassNode base, ClassNode donor, String name, String descriptor) {
        MethodNode replacement = requireMethod(donor, name, descriptor);
        int replaced = 0;
        for (int index = 0; index < base.methods.size(); ++index) {
            MethodNode method = base.methods.get(index);
            if (name.equals(method.name) && descriptor.equals(method.desc)) {
                base.methods.set(index, replacement);
                ++replaced;
            }
        }
        if (replaced != 1) {
            throw new IllegalStateException("Expected one base method " + name + descriptor + ", got " + replaced);
        }
        return replacement;
    }

    private static void replaceAirportDistance(MethodNode method, int expected) {
        int replacements = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst();
             instruction != null;
             instruction = instruction.getNext()) {
            if (instruction instanceof LdcInsnNode) {
                LdcInsnNode constant = (LdcInsnNode)instruction;
                if (constant.cst instanceof Double &&
                    Double.compare(((Double)constant.cst).doubleValue(), 1050.0D) == 0) {
                    constant.cst = Double.valueOf(1200.0D);
                    ++replacements;
                }
            }
        }
        if (replacements != expected) {
            throw new IllegalStateException(
                "Expected " + expected + " HSFX airport distances in " + method.name + ", got " + replacements
            );
        }
    }

    private static void copyFieldIfMissing(ClassNode base, ClassNode donor, String name, String descriptor) {
        if (findField(base, name, descriptor) != null) {
            throw new IllegalStateException("Base field already exists: " + name);
        }
        FieldNode source = findField(donor, name, descriptor);
        if (source == null) {
            throw new IllegalStateException("Donor field is absent: " + name);
        }
        base.fields.add(new FieldNode(source.access, source.name, source.desc, source.signature, source.value));
    }

    private static void validateFlightModelMain(byte[] data) throws Exception {
        ClassNode node = parse(data);
        requireClass(node, FMM);
        requireVersion(node);
        String[][] fields = {
            {"coefTorque", "F"}, {"tempOilMin", "F"}, {"wOilMin", "F"},
            {"timeMinToStart", "F"}, {"bInfoTemp", "Z"}, {"timeMaxNegatG", "F"},
            {"bShowAccel", "Z"}, {"coefQualFuel", "F"}, {"bInfoMotor", "Z"},
            {"bSwitchMagnetoOn", "Z"}
        };
        for (String[] field : fields) {
            if (findField(node, field[0], field[1]) == null) {
                throw new IllegalStateException("Missing FlightModelMain AOC field: " + field[0]);
            }
        }
        if (countString(node, "_Game_Enhancements/Mod_AOC_Public/") != 1 ||
            countString(node, "_Game_Enhancements/Mod_AOC_Public/Defaut.txt") != 1 ||
            countString(node, "Files/maps/aoc/") != 0 ||
            countString(node, "Mod_AOC_Public/") != 0) {
            throw new IllegalStateException("AOC profile path rewrite is incomplete");
        }
        analyze(node);
    }

    private static void validateMotor(byte[] data) throws Exception {
        ClassNode node = parse(data);
        requireClass(node, MOTOR);
        requireVersion(node);
        requireMethod(node, "aocLogEngineInfo", "()V");
        if (findField(node, "t_underheat", "F") == null ||
            findField(node, "coef_coldstart", "I") == null ||
            findField(node, "t_undergnegat", "F") == null) {
            throw new IllegalStateException("AOC engine state fields are incomplete");
        }
        String[] requiredReads = {
            "bSwitchMagnetoOn", "tempOilMin", "wOilMin", "timeMinToStart",
            "bInfoTemp", "timeMaxNegatG", "bShowAccel", "coefQualFuel", "bInfoMotor"
        };
        for (String field : requiredReads) {
            if (countFieldRead(node, FMM, field) < 1) {
                throw new IllegalStateException("AOC setting is not consumed by Motor: " + field);
            }
        }
        if (countCalls(node, MOTOR, "aocLogEngineInfo") != 1) {
            throw new IllegalStateException("AOC engine information hook must be called once");
        }
        analyze(node);
    }

    private static void validateRealFlightModel(byte[] data) throws Exception {
        ClassNode node = parse(data);
        requireClass(node, REAL_FLIGHT_MODEL);
        requireVersion(node);
        if (countFieldRead(node, FMM, "coefTorque") != 2) {
            throw new IllegalStateException("RealFlightModel must apply coefTorque at two propeller sites");
        }
        analyze(node);
    }

    private static int countString(ClassNode node, String value) {
        int count = 0;
        for (MethodNode method : node.methods) {
            for (AbstractInsnNode instruction = method.instructions.getFirst();
                 instruction != null;
                 instruction = instruction.getNext()) {
                if (instruction instanceof LdcInsnNode && value.equals(((LdcInsnNode)instruction).cst)) {
                    ++count;
                }
            }
        }
        return count;
    }

    private static int countFieldRead(ClassNode node, String owner, String name) {
        int count = 0;
        for (MethodNode method : node.methods) {
            for (AbstractInsnNode instruction = method.instructions.getFirst();
                 instruction != null;
                 instruction = instruction.getNext()) {
                if (instruction instanceof FieldInsnNode) {
                    FieldInsnNode field = (FieldInsnNode)instruction;
                    if (field.getOpcode() == GETFIELD && owner.equals(field.owner) && name.equals(field.name)) {
                        ++count;
                    }
                }
            }
        }
        return count;
    }

    private static int countCalls(ClassNode node, String owner, String name) {
        int count = 0;
        for (MethodNode method : node.methods) {
            for (AbstractInsnNode instruction = method.instructions.getFirst();
                 instruction != null;
                 instruction = instruction.getNext()) {
                if (instruction instanceof MethodInsnNode) {
                    MethodInsnNode call = (MethodInsnNode)instruction;
                    if (owner.equals(call.owner) && name.equals(call.name)) {
                        ++count;
                    }
                }
            }
        }
        return count;
    }

    private static void analyze(ClassNode node) throws Exception {
        for (MethodNode method : node.methods) {
            if ((method.access & (ACC_ABSTRACT | ACC_NATIVE)) != 0) {
                continue;
            }
            Analyzer<BasicValue> analyzer = new Analyzer<BasicValue>(new BasicInterpreter());
            analyzer.analyze(node.name, method);
        }
    }

    private static FieldNode findField(ClassNode node, String name, String descriptor) {
        for (FieldNode field : node.fields) {
            if (name.equals(field.name) && descriptor.equals(field.desc)) {
                return field;
            }
        }
        return null;
    }

    private static MethodNode findMethod(ClassNode node, String name, String descriptor) {
        for (MethodNode method : node.methods) {
            if (name.equals(method.name) && descriptor.equals(method.desc)) {
                return method;
            }
        }
        return null;
    }

    private static MethodNode requireMethod(ClassNode node, String name, String descriptor) {
        MethodNode method = findMethod(node, name, descriptor);
        if (method == null) {
            throw new IllegalStateException("Missing method: " + node.name + "." + name + descriptor);
        }
        return method;
    }

    private static void requireClass(ClassNode node, String expected) {
        if (!expected.equals(node.name)) {
            throw new IllegalStateException("Expected class " + expected + ", got " + node.name);
        }
    }

    private static void requireVersion(ClassNode node) {
        int major = node.version & 0xFFFF;
        if (major > JAVA_13_CLASS_VERSION) {
            throw new IllegalStateException(
                "Class " + node.name + " targets Java major " + major + ", maximum is 47"
            );
        }
    }

    private static ClassNode parse(byte[] data) {
        ClassNode node = new ClassNode();
        new ClassReader(data).accept(node, 0);
        return node;
    }

    private static byte[] write(ClassNode node) {
        ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
        node.accept(writer);
        return writer.toByteArray();
    }
}

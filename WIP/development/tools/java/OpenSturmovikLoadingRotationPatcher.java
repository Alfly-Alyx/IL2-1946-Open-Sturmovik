import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.util.Arrays;
import jdk.internal.org.objectweb.asm.ClassReader;
import jdk.internal.org.objectweb.asm.ClassWriter;
import jdk.internal.org.objectweb.asm.Opcodes;
import jdk.internal.org.objectweb.asm.Type;
import jdk.internal.org.objectweb.asm.commons.ClassRemapper;
import jdk.internal.org.objectweb.asm.commons.SimpleRemapper;
import jdk.internal.org.objectweb.asm.tree.*;
import jdk.internal.org.objectweb.asm.tree.analysis.Analyzer;
import jdk.internal.org.objectweb.asm.tree.analysis.BasicInterpreter;
import jdk.internal.org.objectweb.asm.tree.analysis.BasicValue;

/** Build-time tool only: adds a fail-open startup hook to the verified IL-2 class. */
public final class OpenSturmovikLoadingRotationPatcher implements Opcodes {
    private static final String CONSOLE = "com/maddox/il2/engine/ConsoleGL0";
    private static final String HELPER = "com/maddox/il2/engine/OpenSturmovikLoadingRotation";
    private static final String SOURCE_HASH = "1C36806AA965835949125E09518425DD45D6E927EB1E055B3E701A5647215D9C";
    private static final String METHOD_DESC = "(Ljava/lang/String;)V";
    private static final String CHOOSE_DESC = "(Ljava/lang/String;)Ljava/lang/String;";

    private OpenSturmovikLoadingRotationPatcher() {}

    public static void main(String[] args) throws Exception {
        if (args.length != 3) throw new IllegalArgumentException("Usage: patch|legacy input.class output.class");
        byte[] input = Files.readAllBytes(Paths.get(args[1]));
        byte[] output;
        if ("patch".equals(args[0])) output = patch(input);
        else if ("legacy".equals(args[0])) output = legacy(input);
        else throw new IllegalArgumentException("Unknown mode: " + args[0]);
        Path target = Paths.get(args[2]);
        if (target.getParent() != null) Files.createDirectories(target.getParent());
        Files.write(target, output);
        System.out.println(args[0] + " " + parse(output).name + " major=47 sha256=" + hash(output));
    }

    private static byte[] patch(byte[] input) throws Exception {
        if (!SOURCE_HASH.equals(hash(input))) throw new IllegalArgumentException("ConsoleGL0 source SHA-256 is not the verified 4.08/4.09 class.");
        ClassNode original = parse(input);
        ClassNode node = parse(input);
        if (!CONSOLE.equals(node.name) || node.version != V1_3) throw new IllegalArgumentException("Unexpected source name or class version.");
        MethodNode method = requireMethod(node, "exclusiveDraw", METHOD_DESC);
        if ((method.access & ACC_STATIC) == 0 || hookCount(node) != 0) throw new IllegalArgumentException("Source already hooked or method not static.");
        int originalHandlers = method.tryCatchBlocks.size();
        LabelNode begin = new LabelNode();
        LabelNode end = new LabelNode();
        LabelNode failure = new LabelNode();
        LabelNode resume = new LabelNode();
        InsnList hook = new InsnList();
        hook.add(begin);
        hook.add(new VarInsnNode(ALOAD, 0));
        hook.add(new MethodInsnNode(INVOKESTATIC, HELPER, "choose", CHOOSE_DESC, false));
        // The caller argument changes only after the helper returns successfully.
        hook.add(new VarInsnNode(ASTORE, 0));
        hook.add(end);
        hook.add(new JumpInsnNode(GOTO, resume));
        hook.add(failure);
        hook.add(new InsnNode(POP));
        hook.add(resume);
        method.instructions.insert(hook);
        // This handler covers only the new hook. Existing handlers keep their order.
        method.tryCatchBlocks.add(0, new TryCatchBlockNode(begin, end, failure, "java/lang/Throwable"));
        byte[] output = emit(node);
        ClassNode checked = parse(output);
        MethodNode checkedMethod = requireMethod(checked, "exclusiveDraw", METHOD_DESC);
        if (hookCount(checked) != 1 || checkedMethod.tryCatchBlocks.size() != originalHandlers + 1 ||
            !"java/lang/Throwable".equals(checkedMethod.tryCatchBlocks.get(0).type)) {
            throw new IllegalStateException("Invalid startup hook or handler count.");
        }
        for (MethodNode oldMethod : original.methods) {
            if ("exclusiveDraw".equals(oldMethod.name) && METHOD_DESC.equals(oldMethod.desc)) continue;
            MethodNode newMethod = requireMethod(checked, oldMethod.name, oldMethod.desc);
            if (!Arrays.equals(methodBytes(oldMethod), methodBytes(newMethod))) {
                throw new IllegalStateException("An unrelated method changed: " + oldMethod.name + oldMethod.desc);
            }
        }
        return output;
    }

    private static byte[] legacy(byte[] input) throws Exception {
        ClassNode source = parse(input);
        if (!HELPER.equals(source.name)) throw new IllegalArgumentException("Unexpected helper class: " + source.name);
        MethodNode choose = requireMethod(source, "choose", CHOOSE_DESC);
        if ((choose.access & ACC_STATIC) == 0) throw new IllegalArgumentException("choose must be static.");
        ClassNode remapped = new ClassNode();
        source.accept(new ClassRemapper(remapped, new SimpleRemapper("java/lang/StringBuilder", "java/lang/StringBuffer")));
        for (MethodNode method : remapped.methods) {
            for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
                if (instruction instanceof InvokeDynamicInsnNode ||
                    (instruction instanceof LdcInsnNode && ((LdcInsnNode)instruction).cst instanceof Type)) {
                    throw new IllegalArgumentException("Helper uses bytecode unsupported by Java 1.3.");
                }
                if (instruction instanceof MethodInsnNode) {
                    MethodInsnNode call = (MethodInsnNode)instruction;
                    if (call.owner.contains("StringBuilder") || call.desc.contains("StringBuilder") || call.owner.startsWith("java/lang/invoke/")) {
                        throw new IllegalArgumentException("Unconverted helper dependency: " + call.owner);
                    }
                }
            }
        }
        byte[] result = emit(remapped);
        if (new String(result, "ISO-8859-1").contains("java/lang/StringBuilder")) {
            throw new IllegalStateException("StringBuilder remains in the helper constant pool.");
        }
        return result;
    }

    private static int hookCount(ClassNode node) {
        int count = 0;
        for (MethodNode method : node.methods) {
            for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
                if (instruction instanceof MethodInsnNode) {
                    MethodInsnNode call = (MethodInsnNode)instruction;
                    if (HELPER.equals(call.owner) && "choose".equals(call.name) && CHOOSE_DESC.equals(call.desc)) count++;
                }
            }
        }
        return count;
    }

    private static ClassNode parse(byte[] bytes) {
        ClassNode node = new ClassNode();
        new ClassReader(bytes).accept(node, ClassReader.SKIP_FRAMES);
        return node;
    }

    private static byte[] emit(ClassNode node) throws Exception {
        node.version = V1_3;
        ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
        node.accept(writer);
        byte[] bytes = writer.toByteArray();
        ClassNode checked = parse(bytes);
        if (checked.version != V1_3) throw new IllegalStateException("Output must use Java class major 47.");
        for (MethodNode method : checked.methods) {
            if ((method.access & (ACC_ABSTRACT | ACC_NATIVE)) == 0) {
                new Analyzer<BasicValue>(new BasicInterpreter()).analyze(checked.name, method);
            }
        }
        return bytes;
    }

    private static byte[] methodBytes(MethodNode method) {
        ClassWriter writer = new ClassWriter(0);
        writer.visit(V1_3, ACC_PUBLIC, "MethodComparison", null, "java/lang/Object", null);
        method.accept(writer);
        writer.visitEnd();
        return writer.toByteArray();
    }

    private static MethodNode requireMethod(ClassNode node, String name, String descriptor) {
        for (MethodNode method : node.methods) if (name.equals(method.name) && descriptor.equals(method.desc)) return method;
        throw new IllegalArgumentException("Missing method: " + name + descriptor);
    }

    private static String hash(byte[] bytes) throws Exception {
        byte[] digest = MessageDigest.getInstance("SHA-256").digest(bytes);
        StringBuilder text = new StringBuilder();
        for (byte value : digest) text.append(String.format("%02X", value & 255));
        return text.toString();
    }
}

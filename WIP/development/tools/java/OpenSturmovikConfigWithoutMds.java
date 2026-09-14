import java.io.PrintWriter;
import java.io.StringWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import jdk.internal.org.objectweb.asm.ClassReader;
import jdk.internal.org.objectweb.asm.ClassWriter;
import jdk.internal.org.objectweb.asm.Opcodes;
import jdk.internal.org.objectweb.asm.tree.*;
import jdk.internal.org.objectweb.asm.tree.analysis.Analyzer;
import jdk.internal.org.objectweb.asm.tree.analysis.BasicVerifier;
import jdk.internal.org.objectweb.asm.util.Textifier;
import jdk.internal.org.objectweb.asm.util.TraceMethodVisitor;

/** Removes MDS server history from the identified Config, retaining window branding. */
public final class OpenSturmovikConfigWithoutMds implements Opcodes {
    private static final String OWNER = "com/maddox/il2/engine/Config";
    private static final String SOURCE = "8cef8d5ec9eaaac27d2797462e33b9fc5eed4506c3b8b273b4553292cba20a94";

    private static void require(boolean condition, String message) {
        if (!condition) throw new IllegalStateException(message);
    }

    private static ClassNode parse(byte[] bytes) {
        ClassNode node = new ClassNode();
        new ClassReader(bytes).accept(node, ClassReader.SKIP_DEBUG);
        return node;
    }

    private static String sha(byte[] bytes) throws Exception {
        StringBuilder result = new StringBuilder();
        for (byte b : MessageDigest.getInstance("SHA-256").digest(bytes)) result.append(String.format("%02x", b & 255));
        return result.toString();
    }

    private static AbstractInsnNode previousCode(AbstractInsnNode instruction) {
        AbstractInsnNode previous = instruction.getPrevious();
        while (previous != null && previous.getOpcode() < 0) previous = previous.getPrevious();
        return previous;
    }

    private static String describe(MethodNode method) {
        Textifier textifier = new Textifier();
        method.accept(new TraceMethodVisitor(textifier));
        StringWriter text = new StringWriter();
        textifier.print(new PrintWriter(text));
        return method.access + ":" + method.signature + ":" + method.exceptions + ":" + text;
    }

    private static Map<String, String> unaffectedMethods(ClassNode node) {
        Map<String, String> result = new TreeMap<>();
        for (MethodNode method : node.methods) {
            if (!method.name.startsWith("zuti") && !List.of("loadNet", "saveNet", "<init>").contains(method.name)) {
                result.put(method.name + method.desc, describe(method));
            }
        }
        return result;
    }

    public static void main(String[] args) throws Exception {
        require(args.length == 2, "Expected original Config path and candidate output path");
        byte[] original = Files.readAllBytes(Path.of(args[0]));
        require(sha(original).equals(SOURCE), "Unrecognised source Config");
        ClassNode node = parse(original);
        require(node.name.equals(OWNER), "Unexpected class name");
        Map<String, String> preserved = unaffectedMethods(node);
        int fieldsBefore = node.fields.size();
        node.fields.removeIf(field -> field.name.equals("zutiServerNames"));
        require(node.fields.size() == fieldsBefore - 1, "Expected one server-history field");
        int methodsBefore = node.methods.size();
        node.methods.removeIf(method -> List.of("zutiLoadServers", "zutiGetServerNames", "zutiAddServerName").contains(method.name));
        require(node.methods.size() == methodsBefore - 3, "Expected three server-history methods");
        int loadCalls = 0, constructorWrites = 0, saveLoops = 0;
        for (MethodNode method : node.methods) {
            if (method.name.equals("loadNet")) {
                for (AbstractInsnNode instruction : method.instructions.toArray()) {
                    if (instruction instanceof MethodInsnNode call && call.owner.equals(OWNER) && call.name.equals("zutiLoadServers")) {
                        AbstractInsnNode receiver = previousCode(instruction);
                        require(receiver instanceof VarInsnNode && receiver.getOpcode() == ALOAD && ((VarInsnNode)receiver).var == 0, "Unexpected server-history receiver");
                        method.instructions.remove(receiver);
                        method.instructions.remove(instruction);
                        loadCalls++;
                    }
                }
            } else if (method.name.equals("<init>")) {
                for (AbstractInsnNode instruction : method.instructions.toArray()) {
                    if (instruction instanceof FieldInsnNode field && field.owner.equals(OWNER) && field.name.equals("zutiServerNames")) {
                        require(field.getOpcode() == PUTFIELD, "Unexpected constructor field access");
                        AbstractInsnNode before = previousCode(instruction);
                        List<AbstractInsnNode> remove = new ArrayList<>();
                        remove.add(instruction);
                        if (before.getOpcode() == ACONST_NULL) {
                            remove.add(before);
                            before = previousCode(before);
                        } else {
                            require(before instanceof MethodInsnNode, "Expected ArrayList constructor");
                            MethodInsnNode call = (MethodInsnNode)before;
                            require(call.getOpcode() == INVOKESPECIAL && call.owner.equals("java/util/ArrayList") && call.name.equals("<init>") && call.desc.equals("()V"), "Unexpected allocation");
                            remove.add(before);
                            before = previousCode(before);
                            require(before.getOpcode() == DUP, "Expected allocation DUP");
                            remove.add(before);
                            before = previousCode(before);
                            require(before instanceof TypeInsnNode && before.getOpcode() == NEW && ((TypeInsnNode)before).desc.equals("java/util/ArrayList"), "Unexpected allocation type");
                            remove.add(before);
                            before = previousCode(before);
                        }
                        require(before instanceof VarInsnNode && before.getOpcode() == ALOAD && ((VarInsnNode)before).var == 0, "Unexpected constructor receiver");
                        remove.add(before);
                        for (AbstractInsnNode part : remove) method.instructions.remove(part);
                        constructorWrites++;
                    }
                }
            } else if (method.name.equals("saveNet")) {
                LabelNode afterRender = null;
                AbstractInsnNode loopStart = null;
                for (AbstractInsnNode instruction : method.instructions.toArray()) {
                    if (instruction instanceof MethodInsnNode call && call.owner.equals(OWNER) && call.name.equals("isUSE_RENDER")) {
                        AbstractInsnNode jump = instruction.getNext();
                        while (jump != null && jump.getOpcode() < 0) jump = jump.getNext();
                        require(jump instanceof JumpInsnNode && jump.getOpcode() == IFEQ, "Expected rendering guard");
                        afterRender = ((JumpInsnNode)jump).label;
                    }
                    if (instruction.getOpcode() == ISTORE && ((VarInsnNode)instruction).var == 1) {
                        require(loopStart == null, "Ambiguous history loop");
                        loopStart = previousCode(instruction);
                        require(loopStart.getOpcode() == ICONST_0, "Unexpected loop initializer");
                    }
                }
                require(loopStart != null && afterRender != null, "Missing history-loop bounds");
                boolean historyReference = false;
                AbstractInsnNode instruction = loopStart;
                while (instruction != afterRender) {
                    require(instruction != null, "History loop exceeds rendering guard");
                    if (instruction instanceof FieldInsnNode field && field.name.equals("zutiServerNames")) historyReference = true;
                    AbstractInsnNode next = instruction.getNext();
                    method.instructions.remove(instruction);
                    instruction = next;
                }
                require(historyReference, "Expected history field in removed loop");
                saveLoops++;
            }
        }
        require(loadCalls == 1 && constructorWrites == 2 && saveLoops == 1, "Unexpected edit counts");
        require(preserved.equals(unaffectedMethods(node)), "Unrelated Config methods changed");
        for (MethodNode method : node.methods) {
            if ((method.access & (ACC_NATIVE | ACC_ABSTRACT)) == 0) new Analyzer<>(new BasicVerifier()).analyze(node.name, method);
        }
        ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
        node.accept(writer);
        byte[] output = writer.toByteArray();
        require(!new String(output, StandardCharsets.ISO_8859_1).toLowerCase().contains("zuti"), "Residual MDS constant");
        require(preserved.equals(unaffectedMethods(parse(output))), "Output changed unrelated methods");
        Files.createDirectories(Path.of(args[1]).toAbsolutePath().getParent());
        Files.write(Path.of(args[1]), output);
        System.out.println("PASS Config: 3 MDS methods and 1 field removed; server history load/save/initialization removed; " + preserved.size() + " unrelated methods preserved; bytecode verifier passed. SHA256=" + sha(output));
    }
}

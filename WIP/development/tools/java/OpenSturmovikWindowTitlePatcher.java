import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import jdk.internal.org.objectweb.asm.ClassReader;
import jdk.internal.org.objectweb.asm.ClassWriter;
import jdk.internal.org.objectweb.asm.Opcodes;
import jdk.internal.org.objectweb.asm.tree.AbstractInsnNode;
import jdk.internal.org.objectweb.asm.tree.ClassNode;
import jdk.internal.org.objectweb.asm.tree.FieldInsnNode;
import jdk.internal.org.objectweb.asm.tree.LdcInsnNode;
import jdk.internal.org.objectweb.asm.tree.MethodNode;
import jdk.internal.org.objectweb.asm.tree.VarInsnNode;

/** Changes only the window title assigned by com.maddox.il2.engine.Config. */
public final class OpenSturmovikWindowTitlePatcher implements Opcodes {
    private static final String CONFIG = "com/maddox/il2/engine/Config";
    private static final String CONSTRUCTOR = "<init>";
    private static final String CONSTRUCTOR_DESCRIPTOR = "(Lcom/maddox/rts/IniFile;Z)V";
    private static final String CREATE_CONTEXT = "createGlContext";
    private static final String CREATE_CONTEXT_DESCRIPTOR = "(Ljava/lang/String;)Lcom/maddox/opengl/GLContext;";
    private static final String OLD_TITLE = "Il2";
    private static final String NEW_TITLE = "Open Sturmovik";

    private OpenSturmovikWindowTitlePatcher() {
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            throw new IllegalArgumentException("Expected: inputConfigClass outputConfigClass");
        }

        Path input = Paths.get(args[0]);
        Path output = Paths.get(args[1]);
        byte[] patched = patch(Files.readAllBytes(input));
        if (output.getParent() != null) {
            Files.createDirectories(output.getParent());
        }
        Files.write(output, patched);
        validate(patched);
    }

    private static byte[] patch(byte[] data) {
        ClassNode node = parse(data);
        if (!CONFIG.equals(node.name)) {
            throw new IllegalStateException("Unexpected class: " + node.name);
        }

        MethodNode constructor = requireMethod(node, CONSTRUCTOR, CONSTRUCTOR_DESCRIPTOR);
        int replacements = 0;
        for (AbstractInsnNode instruction = constructor.instructions.getFirst();
             instruction != null;
             instruction = instruction.getNext()) {
            if (!(instruction instanceof LdcInsnNode)) {
                continue;
            }
            LdcInsnNode constant = (LdcInsnNode)instruction;
            if (!OLD_TITLE.equals(constant.cst) && !NEW_TITLE.equals(constant.cst)) {
                continue;
            }
            FieldInsnNode assignment = nextFieldInstruction(instruction);
            if (assignment != null && assignment.getOpcode() == PUTFIELD &&
                CONFIG.equals(assignment.owner) && "windowTitle".equals(assignment.name) &&
                "Ljava/lang/String;".equals(assignment.desc)) {
                constant.cst = NEW_TITLE;
                ++replacements;
            }
        }
        if (replacements != 1) {
            throw new IllegalStateException("Expected one window-title assignment, got " + replacements);
        }

        // Main3D passes [il2] title here AFTER construction. Changing only the
        // constructor default therefore never affected a normal game startup.
        MethodNode createContext = requireMethod(node, CREATE_CONTEXT, CREATE_CONTEXT_DESCRIPTOR);
        int effectiveReplacements = 0;
        for (AbstractInsnNode instruction = createContext.instructions.getFirst();
             instruction != null;) {
            AbstractInsnNode next = instruction.getNext();
            FieldInsnNode assignment = nextFieldInstruction(instruction);
            if (assignment != null && assignment.getOpcode() == PUTFIELD &&
                CONFIG.equals(assignment.owner) && "windowTitle".equals(assignment.name)) {
                boolean inputTitle = instruction instanceof VarInsnNode &&
                    instruction.getOpcode() == ALOAD && ((VarInsnNode)instruction).var == 1;
                boolean alreadyBranded = instruction instanceof LdcInsnNode &&
                    NEW_TITLE.equals(((LdcInsnNode)instruction).cst);
                if (!inputTitle && !alreadyBranded) {
                    throw new IllegalStateException("Unexpected effective window-title assignment");
                }
                createContext.instructions.set(instruction, new LdcInsnNode(NEW_TITLE));
                ++effectiveReplacements;
            }
            instruction = next;
        }
        if (effectiveReplacements != 1) {
            throw new IllegalStateException("Expected one effective title assignment, got " + effectiveReplacements);
        }

        ClassWriter writer = new ClassWriter(0);
        node.accept(writer);
        return writer.toByteArray();
    }

    private static void validate(byte[] data) {
        ClassNode node = parse(data);
        MethodNode constructor = requireMethod(node, CONSTRUCTOR, CONSTRUCTOR_DESCRIPTOR);
        int brandedAssignments = 0;
        int legacyAssignments = 0;
        for (AbstractInsnNode instruction = constructor.instructions.getFirst();
             instruction != null;
             instruction = instruction.getNext()) {
            if (!(instruction instanceof LdcInsnNode)) {
                continue;
            }
            LdcInsnNode constant = (LdcInsnNode)instruction;
            FieldInsnNode assignment = nextFieldInstruction(instruction);
            if (assignment == null || assignment.getOpcode() != PUTFIELD ||
                !CONFIG.equals(assignment.owner) || !"windowTitle".equals(assignment.name)) {
                continue;
            }
            if (NEW_TITLE.equals(constant.cst)) {
                ++brandedAssignments;
            } else if (OLD_TITLE.equals(constant.cst)) {
                ++legacyAssignments;
            }
        }
        if (brandedAssignments != 1 || legacyAssignments != 0) {
            throw new IllegalStateException(
                "Invalid patched title: branded=" + brandedAssignments + ", legacy=" + legacyAssignments
            );
        }
        MethodNode createContext = requireMethod(node, CREATE_CONTEXT, CREATE_CONTEXT_DESCRIPTOR);
        int effectiveTitles = 0;
        for (AbstractInsnNode instruction = createContext.instructions.getFirst();
             instruction != null; instruction = instruction.getNext()) {
            FieldInsnNode assignment = nextFieldInstruction(instruction);
            if (assignment != null && assignment.getOpcode() == PUTFIELD &&
                CONFIG.equals(assignment.owner) && "windowTitle".equals(assignment.name)) {
                if (!(instruction instanceof LdcInsnNode) ||
                    !NEW_TITLE.equals(((LdcInsnNode)instruction).cst)) {
                    throw new IllegalStateException("The configuration title can still replace the branded title");
                }
                ++effectiveTitles;
            }
        }
        if (effectiveTitles != 1) {
            throw new IllegalStateException("Missing effective branded window title");
        }
    }

    private static FieldInsnNode nextFieldInstruction(AbstractInsnNode instruction) {
        AbstractInsnNode current = instruction.getNext();
        while (current != null && current.getOpcode() < 0) {
            current = current.getNext();
        }
        return current instanceof FieldInsnNode ? (FieldInsnNode)current : null;
    }

    private static ClassNode parse(byte[] data) {
        ClassNode node = new ClassNode();
        new ClassReader(data).accept(node, 0);
        return node;
    }

    private static MethodNode requireMethod(ClassNode node, String name, String descriptor) {
        for (MethodNode method : node.methods) {
            if (name.equals(method.name) && descriptor.equals(method.desc)) {
                return method;
            }
        }
        throw new IllegalStateException("Required method missing: " + name + descriptor);
    }
}

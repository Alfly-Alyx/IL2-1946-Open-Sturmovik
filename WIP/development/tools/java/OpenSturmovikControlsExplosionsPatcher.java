import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import jdk.internal.org.objectweb.asm.ClassReader;
import jdk.internal.org.objectweb.asm.ClassWriter;
import jdk.internal.org.objectweb.asm.Opcodes;
import jdk.internal.org.objectweb.asm.tree.*;
import jdk.internal.org.objectweb.asm.tree.analysis.*;

/** Removes the MDS-only additions from the two mixed v1.15 classes.
 * Input classes are fingerprinted. No game files are installed by this tool.
 */
public final class OpenSturmovikControlsExplosionsPatcher implements Opcodes {
    private static final String CONTROLS = "com/maddox/il2/fm/Controls";
    private static final String EXPLOSIONS = "com/maddox/il2/objects/effects/Explosions";
    private static final String MAIN = "com/maddox/il2/game/Main";
    private static final String MISSION = "com/maddox/il2/game/Mission";
    private static final String CONTROLS_SHA = "fd7983c25155a9dea555d0b87ecd507bd0680a052a227ce524f65828eaff1667";
    private static final String EXPLOSIONS_SHA = "24ccb92f1ad8bcad777caf03b9357cd7756e3e1248986a2c3b7fd317ddd2cf9a";
    private static final Set<String> CARGO_METHODS = new HashSet<String>(Arrays.asList(
        "zutiProcessDropCargoEvent(Ljava/lang/String;)V", "zutiIsDropOverRequiredArea()Z",
        "zutiDropOverHomeBase(IIDD)Z", "zutiDropOverFrictionArea(IIDD)Z",
        "zutiDropOverTargetArea(DD)Z"));

    public static void main(String[] args) throws Exception {
        if (args.length != 3) throw new IllegalArgumentException("Controls.class Explosions.class output-directory");
        byte[] controls = Files.readAllBytes(Paths.get(args[0]));
        byte[] explosions = Files.readAllBytes(Paths.get(args[1]));
        require(sha256(controls).equals(CONTROLS_SHA), "Unrecognised Controls source");
        require(sha256(explosions).equals(EXPLOSIONS_SHA), "Unrecognised Explosions source");
        Path output = Paths.get(args[2]);
        Files.createDirectories(output);
        byte[] cleanControls = cleanControls(controls);
        byte[] cleanExplosions = cleanExplosions(explosions);
        Files.write(output.resolve("Controls.class"), cleanControls);
        Files.write(output.resolve("Explosions.class"), cleanExplosions);
        require(Arrays.equals(cleanExplosions, cleanExplosions(cleanExplosions)), "Explosions cleanup is not idempotent");
        System.out.println("Controls SHA256 " + sha256(cleanControls));
        System.out.println("Explosions SHA256 " + sha256(cleanExplosions));
        System.out.println("PASS: Java 1.3 compatible versions preserved, complete bytecode analysis, untouched methods preserved, no MDS constants");
    }

    public static byte[] cleanControls(byte[] data) throws Exception {
        ClassNode original = parse(data);
        ClassNode node = parse(data);
        require(node.name.equals(CONTROLS), "Wrong Controls class");
        int removed = 0;
        for (int i = node.methods.size() - 1; i >= 0; --i) {
            MethodNode m = node.methods.get(i);
            if (CARGO_METHODS.contains(m.name + m.desc)) {
                require((m.access & ACC_PRIVATE) != 0, "Cargo method unexpectedly public");
                node.methods.remove(i);
                removed++;
            }
        }
        require(removed == 5, "Expected five private cargo methods");
        int fields = node.fields.size();
        node.fields.removeIf(f -> f.name.equals("ZUTI_PROCESS_CARGO_DROPS") && f.desc.equals("Z"));
        require(node.fields.size() == fields - 1, "Expected one cargo state field");
        int calls = 0, initializers = 0;
        Set<String> touched = new HashSet<String>();
        for (MethodNode m : node.methods) {
            for (AbstractInsnNode insn : m.instructions.toArray()) {
                if (isCall(insn, INVOKESPECIAL, CONTROLS, "zutiProcessDropCargoEvent", "(Ljava/lang/String;)V")) {
                    AbstractInsnNode[] seq = preceding(insn, 8);
                    require(isVar(seq[0], ALOAD, 0) && isVar(seq[1], ALOAD, 0), "Cargo receiver pattern");
                    require(isField(seq[2], GETFIELD, CONTROLS, "Weapons", "[[Lcom/maddox/il2/ai/BulletEmitter;"), "Cargo weapon array");
                    require(isVar(seq[3], ILOAD, 13) && seq[4].getOpcode() == AALOAD &&
                        isVar(seq[5], ILOAD, 16) && seq[6].getOpcode() == AALOAD, "Cargo weapon index pattern");
                    require(isCall(seq[7], INVOKEVIRTUAL, "java/lang/Object", "toString", "()Ljava/lang/String;"), "Cargo string conversion");
                    for (AbstractInsnNode n : seq) m.instructions.remove(n);
                    m.instructions.remove(insn);
                    touched.add(m.name + m.desc);
                    calls++;
                } else if (isField(insn, PUTSTATIC, CONTROLS, "ZUTI_PROCESS_CARGO_DROPS", "Z")) {
                    AbstractInsnNode value = previous(insn);
                    require(m.name.equals("<clinit>") && value.getOpcode() == ICONST_1, "Cargo initializer pattern");
                    m.instructions.remove(value);
                    m.instructions.remove(insn);
                    touched.add(m.name + m.desc);
                    initializers++;
                }
            }
        }
        require(calls == 1 && initializers == 1, "Expected one cargo dispatch and initializer");
        assertUntouchedMethods(original, node, touched, CARGO_METHODS);
        // Every field except the dedicated cargo state remains identical.
        for (FieldNode f : node.fields) require(hasField(original, f.name, f.desc, f.access), "Unexpected field change");
        require(hasField(node, "bMoveSideDoor", "Z", ACC_PUBLIC), "Side-door API missing");
        require(hasField(node, "bHasBayDoors", "Z", ACC_PUBLIC), "Bomb-bay API missing");
        find(node, "setActiveDoor", "(I)V");
        return emit(node);
    }

    /** Also used as the final step of the nuclear builder, preventing reintroduction. */
    public static byte[] cleanExplosions(byte[] data) throws Exception {
        ClassNode original = parse(data);
        ClassNode node = parse(data);
        require(node.name.equals(EXPLOSIONS), "Wrong Explosions class");
        if (!hasMds(data)) { verify(node); return data; }
        // The input is the reviewed final v1.15 Silverplate/lifecycle class.
        require(sha256(data).equals(EXPLOSIONS_SHA), "Unrecognised mixed Explosions source");
        MethodNode fontain = find(node, "fontain", "(Lcom/maddox/JGP/Point3d;FFII)V");
        List<FieldInsnNode> settings = craterSettings(fontain);
        require(settings.size() == 3, "Expected three fountain crater settings");
        // Remove the category selection introduced only for MDS multipliers.
        AbstractInsnNode start = previous(previous(previous(previous(previous(previous(previous(previous(settings.get(0)))))))));
        require(isVar(start, ILOAD, 4), "Fountain category selector changed");
        AbstractInsnNode end = next(next(settings.get(2)));
        require(isCall(end, INVOKESTATIC, EXPLOSIONS, "SurfaceCrater", "(IFF)V"), "Fountain crater end changed");
        List<AbstractInsnNode> block = interval(start, end);
        require(realOpcodes(block).equals(Arrays.asList(ILOAD,ICONST_2,IF_ICMPNE,
            ILOAD,FLOAD,LDC,INVOKESTATIC,GETFIELD,GETFIELD,FMUL,INVOKESTATIC,GOTO,
            ILOAD,IFNE,ILOAD,FLOAD,LDC,INVOKESTATIC,GETFIELD,GETFIELD,FMUL,INVOKESTATIC,GOTO,
            ILOAD,FLOAD,LDC,INVOKESTATIC,GETFIELD,GETFIELD,FMUL,INVOKESTATIC)), "Fountain instruction shape changed");
        assertNoExternalEntry(fontain, block);
        InsnList replacement = new InsnList();
        replacement.add(new VarInsnNode(ILOAD, 3));
        replacement.add(new VarInsnNode(FLOAD, 10));
        replacement.add(new LdcInsnNode(Float.valueOf(80.0F)));
        replacement.add(new MethodInsnNode(INVOKESTATIC, EXPLOSIONS, "SurfaceCrater", "(IFF)V", false));
        fontain.instructions.insertBefore(start, replacement);
        for (AbstractInsnNode n : block) fontain.instructions.remove(n);

        MethodNode heavy = find(node, "bomb1000_land", "(Lcom/maddox/JGP/Point3d;FF)V");
        removeMultiplier(heavy, "zutiMisc_BombsCat4_CratersVisibilityMultiplier", 600.0F);
        MethodNode nuclear = find(node, "bombFatMan_land", "(Lcom/maddox/JGP/Point3d;FF)V");
        FieldInsnNode setting = singleSetting(nuclear, "zutiMisc_BombsCat3_CratersVisibilityMultiplier");
        AbstractInsnNode first = preceding(setting, 5)[0];
        AbstractInsnNode[] seq = preceding(setting, 5);
        require(seq[0].getOpcode() == ICONST_0 && isFloat(seq[1], 312.1F) && isFloat(seq[2], 900.0F), "Discarded nuclear crater arguments changed");
        require(isMainMission(seq[3], seq[4]), "Discarded nuclear mission lookup changed");
        AbstractInsnNode last = next(next(next(next(setting))));
        require(next(setting).getOpcode() == FMUL && next(next(setting)).getOpcode() == POP &&
            next(next(next(setting))).getOpcode() == POP && last.getOpcode() == POP, "Nuclear crater must already be disabled");
        List<AbstractInsnNode> discarded = interval(first, last);
        assertNoExternalEntry(nuclear, discarded);
        for (AbstractInsnNode n : discarded) nuclear.instructions.remove(n);

        assertUntouchedMethods(original, node, new HashSet<String>(Arrays.asList(
            fontain.name + fontain.desc, heavy.name + heavy.desc, nuclear.name + nuclear.desc)), new HashSet<String>());
        find(node, "generate", "(Lcom/maddox/il2/engine/Actor;Lcom/maddox/JGP/Point3d;FIFI)V");
        return emit(node);
    }

    private static void removeMultiplier(MethodNode m, String name, float base) {
        FieldInsnNode f = singleSetting(m, name);
        AbstractInsnNode mission = previous(f), main = previous(mission), value = previous(main), multiply = next(f);
        require(isMainMission(main, mission) && isFloat(value, base) && multiply.getOpcode() == FMUL, "Unexpected crater expression");
        m.instructions.remove(main); m.instructions.remove(mission); m.instructions.remove(f); m.instructions.remove(multiply);
    }
    private static boolean isMainMission(AbstractInsnNode main, AbstractInsnNode mission) {
        return isCall(main, INVOKESTATIC, MAIN, "cur", "()L"+MAIN+";") && isField(mission, GETFIELD, MAIN, "mission", "L"+MISSION+";");
    }
    private static List<FieldInsnNode> craterSettings(MethodNode m) {
        List<FieldInsnNode> result = new ArrayList<FieldInsnNode>();
        for (AbstractInsnNode n : m.instructions.toArray()) if (n instanceof FieldInsnNode) {
            FieldInsnNode f = (FieldInsnNode)n;
            if (f.owner.equals(MISSION) && f.name.startsWith("zutiMisc_BombsCat") && f.desc.equals("F")) result.add(f);
        }
        return result;
    }
    private static FieldInsnNode singleSetting(MethodNode m, String name) {
        List<FieldInsnNode> fields = craterSettings(m);
        require(fields.size() == 1 && fields.get(0).name.equals(name), "Crater setting changed in "+m.name);
        return fields.get(0);
    }
    private static void assertUntouchedMethods(ClassNode before, ClassNode after, Set<String> changed, Set<String> removed) {
        require(before.methods.size() - removed.size() == after.methods.size(), "Unexpected method count");
        int checked = 0;
        for (MethodNode m : before.methods) {
            String id = m.name + m.desc;
            if (removed.contains(id) || changed.contains(id)) continue;
            require(Arrays.equals(methodBytes(m), methodBytes(find(after, m.name, m.desc))), "Unrelated method changed: " + id);
            checked++;
        }
        System.out.println(before.name + ": " + checked + " unrelated methods byte-for-byte preserved after canonical serialization");
    }
    private static byte[] methodBytes(MethodNode method) {
        ClassWriter w = new ClassWriter(0);
        w.visit(47, ACC_PUBLIC, "MethodComparison", null, "java/lang/Object", null);
        method.accept(w); w.visitEnd(); return w.toByteArray();
    }
    private static void assertNoExternalEntry(MethodNode m, List<AbstractInsnNode> block) {
        Set<AbstractInsnNode> set = new HashSet<AbstractInsnNode>(block);
        for (AbstractInsnNode n : m.instructions.toArray()) if (!set.contains(n)) {
            if (n instanceof JumpInsnNode) require(!set.contains(((JumpInsnNode)n).label), "Branch enters removed block");
            if (n instanceof TableSwitchInsnNode) {
                TableSwitchInsnNode s=(TableSwitchInsnNode)n;
                require(!set.contains(s.dflt), "Switch enters removed block");
                for(LabelNode l:s.labels) require(!set.contains(l), "Switch enters removed block");
            }
            if (n instanceof LookupSwitchInsnNode) {
                LookupSwitchInsnNode s=(LookupSwitchInsnNode)n;
                require(!set.contains(s.dflt), "Switch enters removed block");
                for(LabelNode l:s.labels) require(!set.contains(l), "Switch enters removed block");
            }
        }
        for(TryCatchBlockNode t:m.tryCatchBlocks) require(!set.contains(t.start)&&!set.contains(t.end)&&!set.contains(t.handler), "Exception boundary removed");
    }
    private static List<Integer> realOpcodes(List<AbstractInsnNode> block) {
        List<Integer> result = new ArrayList<Integer>();
        for(AbstractInsnNode n:block) if(n.getOpcode()>=0) result.add(n.getOpcode());
        return result;
    }
    private static List<AbstractInsnNode> interval(AbstractInsnNode start, AbstractInsnNode end) {
        List<AbstractInsnNode> nodes=new ArrayList<AbstractInsnNode>();
        for(AbstractInsnNode n=start;n!=null;n=n.getNext()) { nodes.add(n); if(n==end) return nodes; }
        throw new IllegalStateException("Invalid instruction interval");
    }
    private static AbstractInsnNode[] preceding(AbstractInsnNode n,int count) {
        AbstractInsnNode[] result=new AbstractInsnNode[count];
        for(int i=count-1;i>=0;--i) { n=previous(n); result[i]=n; }
        return result;
    }
    private static AbstractInsnNode previous(AbstractInsnNode n) { do { n=n.getPrevious(); } while(n!=null&&n.getOpcode()<0); return n; }
    private static AbstractInsnNode next(AbstractInsnNode n) { do { n=n.getNext(); } while(n!=null&&n.getOpcode()<0); return n; }
    private static boolean isVar(AbstractInsnNode n,int op,int var) { return n instanceof VarInsnNode&&n.getOpcode()==op&&((VarInsnNode)n).var==var; }
    private static boolean isFloat(AbstractInsnNode n,float value) { return n instanceof LdcInsnNode&&Float.valueOf(value).equals(((LdcInsnNode)n).cst); }
    private static boolean isCall(AbstractInsnNode n,int op,String owner,String name,String desc) {
        if(!(n instanceof MethodInsnNode)) return false; MethodInsnNode m=(MethodInsnNode)n;
        return m.getOpcode()==op&&m.owner.equals(owner)&&m.name.equals(name)&&m.desc.equals(desc);
    }
    private static boolean isField(AbstractInsnNode n,int op,String owner,String name,String desc) {
        if(!(n instanceof FieldInsnNode)) return false; FieldInsnNode f=(FieldInsnNode)n;
        return f.getOpcode()==op&&f.owner.equals(owner)&&f.name.equals(name)&&f.desc.equals(desc);
    }
    private static boolean hasField(ClassNode n,String name,String desc,int access) {
        for(FieldNode f:n.fields) if(f.name.equals(name)&&f.desc.equals(desc)&&f.access==access) return true;
        return false;
    }
    private static MethodNode find(ClassNode n,String name,String desc) {
        for(MethodNode m:n.methods) if(m.name.equals(name)&&m.desc.equals(desc)) return m;
        throw new IllegalStateException("Missing method "+n.name+"."+name+desc);
    }
    private static ClassNode parse(byte[] data) { ClassNode n=new ClassNode(); new ClassReader(data).accept(n,ClassReader.SKIP_DEBUG); return n; }
    private static byte[] emit(ClassNode n) throws Exception {
        require((n.version & 65535) <= 47,"Expected a Java 1.3 compatible ClassFile version");
        ClassWriter w=new ClassWriter(ClassWriter.COMPUTE_MAXS); n.accept(w); byte[] data=w.toByteArray();
        verify(parse(data)); require(!hasMds(data),"MDS constant remains after cleanup"); return data;
    }
    private static void verify(ClassNode n) throws AnalyzerException {
        for(MethodNode m:n.methods) if((m.access&(ACC_NATIVE|ACC_ABSTRACT))==0)
            new Analyzer<BasicValue>(new BasicVerifier()).analyze(n.name,m);
    }
    private static boolean hasMds(byte[] data) {
        return new String(data, java.nio.charset.StandardCharsets.ISO_8859_1).toLowerCase(Locale.ROOT).contains("zuti");
    }
    private static String sha256(byte[] data) throws Exception {
        StringBuilder b=new StringBuilder(); for(byte v:MessageDigest.getInstance("SHA-256").digest(data)) b.append(String.format("%02x",v&255)); return b.toString();
    }
    private static void require(boolean ok,String message) { if(!ok) throw new IllegalStateException(message); }
}

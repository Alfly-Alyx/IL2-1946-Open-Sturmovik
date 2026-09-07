import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import jdk.internal.org.objectweb.asm.ClassReader;
import jdk.internal.org.objectweb.asm.ClassWriter;
import jdk.internal.org.objectweb.asm.Opcodes;
import jdk.internal.org.objectweb.asm.Type;
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
import jdk.internal.org.objectweb.asm.tree.analysis.AnalyzerException;
import jdk.internal.org.objectweb.asm.tree.analysis.BasicInterpreter;
import jdk.internal.org.objectweb.asm.tree.analysis.BasicValue;

public final class OpenSturmovikNuclearPatcher implements Opcodes {
    private static final int JAVA_13_CLASS_VERSION = 47;
    private static final String EXPLOSIONS = "com/maddox/il2/objects/effects/Explosions";
    private static final String NUCLEAR_BLAST = "com/maddox/il2/objects/effects/NuclearBlast";
    private static final String EFF3D = "com/maddox/il2/engine/Eff3D";
    private static final String ACTOR = "com/maddox/il2/engine/Actor";
    private static final String ACTOR_POS = "com/maddox/il2/engine/ActorPos";
    private static final String ENGINE = "com/maddox/il2/engine/Engine";
    private static final String LANDSCAPE = "com/maddox/il2/engine/Landscape";
    private static final String POINT3D = "com/maddox/JGP/Point3d";
    private static final String BOMB = "com/maddox/il2/objects/weapons/Bomb";

    private OpenSturmovikNuclearPatcher() {
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 8) {
            throw new IllegalArgumentException(
                "Expected: zutiExplosions silverplateExplosions Explosion MsgExplosion LittleBoy FatMan compiledNuclear outputDir"
            );
        }

        Path output = Paths.get(args[7]);
        Files.createDirectories(output);

        write(output.resolve("Explosions.class"), patchExplosions(read(args[0]), read(args[1])));
        write(output.resolve("Explosion.class"), patchExplosionFalloff(read(args[2])));
        write(output.resolve("MsgExplosion.class"), patchMsgExplosion(read(args[3])));
        write(output.resolve("BombLittleBoy.class"), patchBomb(read(args[4]), 600.0, 15000000.0F, 2150.0F, 4400.0F, 0.894F));
        write(output.resolve("BombFatMan.class"), patchBomb(read(args[5]), 503.0, 21000000.0F, 2360.0F, 4670.0F, 1.0F));

        Path compiledNuclear = Paths.get(args[6]);
        validateShockVectorAbi(Files.readAllBytes(compiledNuclear.resolve("NuclearBlast$ShockAction.class")));
        validateVisualEffectAbi(Files.readAllBytes(compiledNuclear.resolve("NuclearBlast$VisualAction.class")));
        validatePausePreservationAbi(
            Files.readAllBytes(compiledNuclear.resolve("NuclearBlast.class")),
            Files.readAllBytes(compiledNuclear.resolve("NuclearBlast$VisualAction.class"))
        );
        copyDowngraded(compiledNuclear.resolve("NuclearBlast.class"), output.resolve("NuclearBlast.class"));
        copyDowngraded(compiledNuclear.resolve("NuclearBlast$DamageAction.class"), output.resolve("NuclearBlast$DamageAction.class"));
        copyDowngraded(compiledNuclear.resolve("NuclearBlast$DamageData.class"), output.resolve("NuclearBlast$DamageData.class"));
        copyDowngraded(compiledNuclear.resolve("NuclearBlast$ShockAction.class"), output.resolve("NuclearBlast$ShockAction.class"));
        copyDowngraded(compiledNuclear.resolve("NuclearBlast$ShockData.class"), output.resolve("NuclearBlast$ShockData.class"));
        copyDowngraded(compiledNuclear.resolve("NuclearBlast$VisualAction.class"), output.resolve("NuclearBlast$VisualAction.class"));
        copyDowngraded(compiledNuclear.resolve("NuclearBlast$VisualData.class"), output.resolve("NuclearBlast$VisualData.class"));
    }

    private static void validateShockVectorAbi(byte[] data) {
        ClassNode node = parse(data);
        MethodNode method = findMethod(node, "doAction", "(Ljava/lang/Object;)V");
        int compatibleAdds = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
            if (!(instruction instanceof MethodInsnNode)) {
                continue;
            }
            MethodInsnNode call = (MethodInsnNode)instruction;
            if (call.owner.equals("com/maddox/JGP/Vector3d") && call.name.equals("add")) {
                if (!call.desc.equals("(Lcom/maddox/JGP/Tuple3d;)V")) {
                    throw new IllegalStateException("Incompatible IL-2 4.09m Vector3d.add ABI: " + call.desc);
                }
                ++compatibleAdds;
            }
        }
        if (compatibleAdds != 1) {
            throw new IllegalStateException("Expected one IL-2 4.09m-compatible Vector3d.add call, got " + compatibleAdds);
        }
    }

    private static void validateVisualEffectAbi(byte[] data) {
        ClassNode node = parse(data);
        MethodNode method = findMethod(node, "doAction", "(Ljava/lang/Object;)V");
        int locConstructors = 0;
        int timerSelections = 0;
        int effectFactories = 0;
        int visualRegistrations = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
            if (!(instruction instanceof MethodInsnNode)) {
                continue;
            }
            MethodInsnNode call = (MethodInsnNode)instruction;
            if (call.owner.equals("com/maddox/il2/engine/Loc") && call.name.equals("<init>")) {
                if (!call.desc.equals("(Lcom/maddox/JGP/Tuple3d;)V")) {
                    throw new IllegalStateException("Incompatible IL-2 4.09m Loc ABI: " + call.desc);
                }
                ++locConstructors;
            }
            if (call.getOpcode() == INVOKESTATIC && call.owner.equals(EFF3D) &&
                call.name.equals("initSetTypeTimer") && call.desc.equals("(Z)V")) {
                AbstractInsnNode timerValue = previousReal(call);
                if (timerValue == null || timerValue.getOpcode() != ICONST_0) {
                    throw new IllegalStateException("Stabilized cloud must use IL-2 simulation time");
                }
                ++timerSelections;
            }
            if (isNuclearEffectFactoryCall(call)) {
                ++effectFactories;
            }
            if (call.getOpcode() == INVOKESTATIC && call.owner.equals(NUCLEAR_BLAST) &&
                call.name.equals("registerVisual") &&
                call.desc.equals("(Lcom/maddox/il2/engine/Eff3DActor;)V")) {
                ++visualRegistrations;
            }
        }
        if (locConstructors != 1 || timerSelections != 1 || effectFactories != 1 || visualRegistrations != 1) {
            throw new IllegalStateException(
                "Expected one compatible stabilized-cloud constructor/timer/factory/registration, got " +
                locConstructors + "/" + timerSelections + "/" + effectFactories + "/" + visualRegistrations
            );
        }
    }

    private static void validatePausePreservationAbi(byte[] rootData, byte[] visualActionData) {
        ClassNode root = parse(rootData);
        MethodNode register = findMethod(
            root,
            "registerVisual",
            "(Lcom/maddox/il2/engine/Eff3DActor;)V"
        );
        MethodNode pause = findMethod(
            root,
            "setVisualPaused",
            "(Lcom/maddox/il2/engine/Eff3DActor;Z)V"
        );
        if ((register.access & (ACC_PUBLIC | ACC_STATIC)) != (ACC_PUBLIC | ACC_STATIC)) {
            throw new IllegalStateException("NuclearBlast.registerVisual must remain public static");
        }
        if (countCalls(root, "com/maddox/rts/Time", "isPaused") < 2 ||
            countCalls(pause, "java/lang/reflect/Method", "invoke") != 1) {
            throw new IllegalStateException("Nuclear visual pause watcher ABI is incomplete");
        }

        ClassNode action = parse(visualActionData);
        if (!action.superName.equals("com/maddox/rts/MsgAction")) {
            throw new IllegalStateException("Nuclear visual watcher must extend MsgAction");
        }
        MethodNode realTimeConstructor = findMethod(action, "<init>", "(J)V");
        int realTimeConstructors = 0;
        for (AbstractInsnNode instruction = realTimeConstructor.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
            if (instruction instanceof MethodInsnNode) {
                MethodInsnNode call = (MethodInsnNode)instruction;
                if (call.getOpcode() == INVOKESPECIAL && call.owner.equals("com/maddox/rts/MsgAction") &&
                    call.name.equals("<init>") && call.desc.equals("(IJLjava/lang/Object;)V")) {
                    ++realTimeConstructors;
                }
            }
        }
        if (realTimeConstructors != 1) {
            throw new IllegalStateException("Nuclear pause watcher must use one real-time MsgAction constructor");
        }
    }

    private static int countCalls(ClassNode node, String owner, String name) {
        int count = 0;
        for (MethodNode method : node.methods) {
            count += countCalls(method, owner, name);
        }
        return count;
    }

    private static byte[] read(String path) throws IOException {
        return Files.readAllBytes(Paths.get(path));
    }

    private static void write(Path path, byte[] data) throws IOException {
        Files.write(path, data);
    }

    private static ClassNode parse(byte[] data) {
        ClassNode node = new ClassNode();
        new ClassReader(data).accept(node, ClassReader.SKIP_FRAMES);
        return node;
    }

    private static byte[] emit(ClassNode node) {
        node.version = JAVA_13_CLASS_VERSION;
        ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
        node.accept(writer);
        byte[] result = writer.toByteArray();
        verifyBytecode(parse(result));
        return result;
    }

    private static void verifyBytecode(ClassNode node) {
        for (MethodNode method : node.methods) {
            if ((method.access & (ACC_ABSTRACT | ACC_NATIVE)) != 0) {
                continue;
            }
            try {
                new Analyzer<BasicValue>(new BasicInterpreter()).analyze(node.name, method);
            } catch (AnalyzerException error) {
                throw new IllegalStateException(
                    "Invalid bytecode in " + node.name + "." + method.name + method.desc,
                    error
                );
            }
        }
    }

    private static byte[] patchExplosions(byte[] zutiData, byte[] silverplateData) {
        ClassNode zuti = parse(zutiData);
        if (isAlreadyPatchedExplosions(zuti)) {
            verifyBytecode(zuti);
            return zutiData;
        }
        if (isMergedExplosions(zuti)) {
            forceSimulationTimerForNuclearEffects(zuti);
            registerNuclearVisuals(zuti);
            return emit(zuti);
        }
        ClassNode silverplate = parse(silverplateData);
        List<MethodNode> replacements = new ArrayList<MethodNode>();

        for (MethodNode method : silverplate.methods) {
            if (method.name.equals("generate") && (
                method.desc.equals("(Lcom/maddox/il2/engine/Actor;Lcom/maddox/JGP/Point3d;FIF)V") ||
                method.desc.equals("(Lcom/maddox/il2/engine/Actor;Lcom/maddox/JGP/Point3d;FIFI)V")
            )) {
                replacements.add(method);
            }
        }
        if (replacements.size() != 2) {
            throw new IllegalStateException("Silverplate must provide exactly two generate overloads");
        }

        Iterator<MethodNode> iterator = zuti.methods.iterator();
        while (iterator.hasNext()) {
            MethodNode method = iterator.next();
            if (method.name.equals("generate") && (
                method.desc.equals("(Lcom/maddox/il2/engine/Actor;Lcom/maddox/JGP/Point3d;FIF)V") ||
                method.desc.equals("(Lcom/maddox/il2/engine/Actor;Lcom/maddox/JGP/Point3d;FIFI)V")
            )) {
                iterator.remove();
            }
        }

        int removedFallbacks = 0;
        for (MethodNode method : replacements) {
            if (method.desc.endsWith("FIFI)V")) {
                removedFallbacks += removeNuclearConventionalFallback(method);
            }
            zuti.methods.add(method);
        }
        if (removedFallbacks != 1) {
            throw new IllegalStateException("Expected to remove one nuclear bomb50_land fallback, got " + removedFallbacks);
        }
        removeNuclearAirburstCrater(zuti);
        scaleNuclearVisualsFromArgument(zuti);
        forceSimulationTimerForNuclearEffects(zuti);
        registerNuclearVisuals(zuti);
        return emit(zuti);
    }

    private static boolean isAlreadyPatchedExplosions(ClassNode node) {
        if (!isMergedExplosions(node)) {
            return false;
        }
        MethodNode land = findMethod(node, "bombFatMan_land", "(Lcom/maddox/JGP/Point3d;FF)V");
        MethodNode water = findMethod(node, "bombFatMan_water", "(Lcom/maddox/JGP/Point3d;FF)V");
        return countSimulationTimerGuards(land) + countSimulationTimerGuards(water) == 12 &&
            countVisualRegistrations(land) + countVisualRegistrations(water) == 12;
    }

    private static boolean isMergedExplosions(ClassNode node) {
        MethodNode generate = findMethodOrNull(
            node,
            "generate",
            "(Lcom/maddox/il2/engine/Actor;Lcom/maddox/JGP/Point3d;FIFI)V"
        );
        MethodNode land = findMethodOrNull(node, "bombFatMan_land", "(Lcom/maddox/JGP/Point3d;FF)V");
        MethodNode water = findMethodOrNull(node, "bombFatMan_water", "(Lcom/maddox/JGP/Point3d;FF)V");
        return generate != null && land != null && water != null &&
            countCalls(generate, EXPLOSIONS, "bombFatMan_land") > 0 &&
            countCalls(generate, EXPLOSIONS, "bombFatMan_water") > 0 &&
            countCalls(land, EXPLOSIONS, "SurfaceCrater") == 0 &&
            countParameterizedEffects(land) + countParameterizedEffects(water) == 12;
    }

    private static void forceSimulationTimerForNuclearEffects(ClassNode node) {
        int changes = 0;
        String[] methods = {"bombFatMan_land", "bombFatMan_water"};
        for (String methodName : methods) {
            MethodNode method = findMethod(node, methodName, "(Lcom/maddox/JGP/Point3d;FF)V");
            for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
                if (!isNuclearEffectFactoryCall(instruction) || hasSimulationTimerGuard(instruction)) {
                    continue;
                }
                InsnList guard = new InsnList();
                guard.add(new InsnNode(ICONST_0));
                guard.add(new MethodInsnNode(INVOKESTATIC, EFF3D, "initSetTypeTimer", "(Z)V", false));
                method.instructions.insertBefore(instruction, guard);
                ++changes;
            }
        }
        MethodNode land = findMethod(node, "bombFatMan_land", "(Lcom/maddox/JGP/Point3d;FF)V");
        MethodNode water = findMethod(node, "bombFatMan_water", "(Lcom/maddox/JGP/Point3d;FF)V");
        int total = countSimulationTimerGuards(land) + countSimulationTimerGuards(water);
        if (total != 12) {
            throw new IllegalStateException(
                "Expected 12 nuclear visual emitters guarded by simulation time, got " + total +
                " after " + changes + " changes"
            );
        }
    }

    private static void registerNuclearVisuals(ClassNode node) {
        int changes = 0;
        String[] methods = {"bombFatMan_land", "bombFatMan_water"};
        for (String methodName : methods) {
            MethodNode method = findMethod(node, methodName, "(Lcom/maddox/JGP/Point3d;FF)V");
            for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
                if (!isNuclearEffectFactoryCall(instruction) || hasVisualRegistration(instruction)) {
                    continue;
                }
                InsnList registration = new InsnList();
                registration.add(new InsnNode(DUP));
                registration.add(new MethodInsnNode(
                    INVOKESTATIC,
                    NUCLEAR_BLAST,
                    "registerVisual",
                    "(Lcom/maddox/il2/engine/Eff3DActor;)V",
                    false
                ));
                method.instructions.insert(instruction, registration);
                ++changes;
            }
        }

        MethodNode land = findMethod(node, "bombFatMan_land", "(Lcom/maddox/JGP/Point3d;FF)V");
        MethodNode water = findMethod(node, "bombFatMan_water", "(Lcom/maddox/JGP/Point3d;FF)V");
        int total = countVisualRegistrations(land) + countVisualRegistrations(water);
        if (total != 12) {
            throw new IllegalStateException(
                "Expected 12 nuclear visual emitters registered for pause preservation, got " + total +
                " after " + changes + " changes"
            );
        }
    }

    private static boolean hasVisualRegistration(AbstractInsnNode factory) {
        AbstractInsnNode duplicate = nextReal(factory);
        AbstractInsnNode registration = nextReal(duplicate);
        if (duplicate == null || duplicate.getOpcode() != DUP || !(registration instanceof MethodInsnNode)) {
            return false;
        }
        MethodInsnNode call = (MethodInsnNode)registration;
        return call.getOpcode() == INVOKESTATIC && call.owner.equals(NUCLEAR_BLAST) &&
            call.name.equals("registerVisual") &&
            call.desc.equals("(Lcom/maddox/il2/engine/Eff3DActor;)V");
    }

    private static int countVisualRegistrations(MethodNode method) {
        int count = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
            if (instruction instanceof MethodInsnNode) {
                MethodInsnNode call = (MethodInsnNode)instruction;
                if (call.getOpcode() == INVOKESTATIC && call.owner.equals(NUCLEAR_BLAST) &&
                    call.name.equals("registerVisual") &&
                    call.desc.equals("(Lcom/maddox/il2/engine/Eff3DActor;)V")) {
                    ++count;
                }
            }
        }
        return count;
    }

    private static int countSimulationTimerGuards(MethodNode method) {
        int count = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
            if (isNuclearEffectFactoryCall(instruction) && hasSimulationTimerGuard(instruction)) {
                ++count;
            }
        }
        return count;
    }

    private static boolean hasSimulationTimerGuard(AbstractInsnNode instruction) {
        AbstractInsnNode timerCall = previousReal(instruction);
        if (!(timerCall instanceof MethodInsnNode)) {
            return false;
        }
        MethodInsnNode call = (MethodInsnNode)timerCall;
        AbstractInsnNode timerValue = previousReal(timerCall);
        return call.getOpcode() == INVOKESTATIC && call.owner.equals(EFF3D) &&
            call.name.equals("initSetTypeTimer") && call.desc.equals("(Z)V") &&
            timerValue != null && timerValue.getOpcode() == ICONST_0;
    }

    private static boolean isNuclearEffectFactoryCall(AbstractInsnNode instruction) {
        if (!(instruction instanceof MethodInsnNode)) {
            return false;
        }
        MethodInsnNode call = (MethodInsnNode)instruction;
        return call.getOpcode() == INVOKESTATIC && call.owner.equals("com/maddox/il2/engine/Eff3DActor") &&
            call.name.equals("New") &&
            call.desc.equals("(Lcom/maddox/il2/engine/Loc;FLjava/lang/String;F)Lcom/maddox/il2/engine/Eff3DActor;");
    }

    private static int countCalls(MethodNode method, String owner, String name) {
        int count = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
            if (instruction instanceof MethodInsnNode) {
                MethodInsnNode call = (MethodInsnNode)instruction;
                if (call.owner.equals(owner) && call.name.equals(name)) {
                    ++count;
                }
            }
        }
        return count;
    }

    private static int countParameterizedEffects(MethodNode method) {
        int count = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
            if (!isNuclearEffectFactoryCall(instruction)) {
                continue;
            }
            AbstractInsnNode duration = previousReal(instruction);
            if (hasSimulationTimerGuard(instruction)) {
                duration = previousReal(previousReal(duration));
            }
            AbstractInsnNode effectName = previousReal(duration);
            AbstractInsnNode scale = previousReal(effectName);
            if (scale instanceof VarInsnNode && scale.getOpcode() == FLOAD && ((VarInsnNode)scale).var == 2) {
                ++count;
            }
        }
        return count;
    }

    private static void removeNuclearAirburstCrater(ClassNode node) {
        MethodNode method = findMethod(node, "bombFatMan_land", "(Lcom/maddox/JGP/Point3d;FF)V");
        int removed = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null;) {
            AbstractInsnNode next = instruction.getNext();
            if (instruction instanceof MethodInsnNode) {
                MethodInsnNode call = (MethodInsnNode)instruction;
                if (call.getOpcode() == INVOKESTATIC && call.owner.equals(EXPLOSIONS) &&
                    call.name.equals("SurfaceCrater") && call.desc.equals("(IFF)V")) {
                    InsnList discardArguments = new InsnList();
                    discardArguments.add(new InsnNode(POP));
                    discardArguments.add(new InsnNode(POP));
                    discardArguments.add(new InsnNode(POP));
                    method.instructions.insertBefore(instruction, discardArguments);
                    method.instructions.remove(instruction);
                    ++removed;
                }
            }
            instruction = next;
        }
        if (removed != 1) {
            throw new IllegalStateException("Expected one nuclear SurfaceCrater call, got " + removed);
        }
    }

    private static void scaleNuclearVisualsFromArgument(ClassNode node) {
        int changes = 0;
        String[] methods = {"bombFatMan_land", "bombFatMan_water"};
        for (String methodName : methods) {
            MethodNode method = findMethod(node, methodName, "(Lcom/maddox/JGP/Point3d;FF)V");
            for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
                if (!(instruction instanceof MethodInsnNode)) {
                    continue;
                }
                MethodInsnNode call = (MethodInsnNode)instruction;
                if (call.getOpcode() != INVOKESTATIC || !call.owner.equals("com/maddox/il2/engine/Eff3DActor") ||
                    !call.name.equals("New") ||
                    !call.desc.equals("(Lcom/maddox/il2/engine/Loc;FLjava/lang/String;F)Lcom/maddox/il2/engine/Eff3DActor;")) {
                    continue;
                }
                AbstractInsnNode duration = previousReal(instruction);
                AbstractInsnNode effectName = previousReal(duration);
                AbstractInsnNode scale = previousReal(effectName);
                if (scale != null && scale.getOpcode() == FCONST_1) {
                    method.instructions.set(scale, new VarInsnNode(FLOAD, 2));
                    ++changes;
                }
            }
        }
        if (changes != 12) {
            throw new IllegalStateException("Expected to parameterize 12 nuclear visual emitters, got " + changes);
        }
    }

    private static int removeNuclearConventionalFallback(MethodNode method) {
        int removed = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null;) {
            AbstractInsnNode next = instruction.getNext();
            if (instruction instanceof MethodInsnNode) {
                MethodInsnNode call = (MethodInsnNode)instruction;
                if (call.getOpcode() == INVOKESTATIC && call.owner.equals(EXPLOSIONS) &&
                    call.name.equals("bomb50_land") && call.desc.equals("(Lcom/maddox/JGP/Point3d;FF)V")) {
                    AbstractInsnNode third = previousReal(instruction);
                    AbstractInsnNode second = previousReal(third);
                    AbstractInsnNode first = previousReal(second);
                    if (first instanceof VarInsnNode && first.getOpcode() == ALOAD && ((VarInsnNode)first).var == 1 &&
                        isFloatConstant(second, -1.0F) && isFloatConstant(third, 10.0F)) {
                        method.instructions.remove(first);
                        method.instructions.remove(second);
                        method.instructions.remove(third);
                        method.instructions.remove(instruction);
                        ++removed;
                        // The first matching call is Silverplate's nuclear
                        // fallback. A later identical-looking call belongs to
                        // the stock large-bomb/object branch and must remain.
                        return removed;
                    }
                }
            }
            instruction = next;
        }
        return removed;
    }

    private static AbstractInsnNode previousReal(AbstractInsnNode instruction) {
        AbstractInsnNode current = instruction.getPrevious();
        while (current != null && current.getOpcode() < 0) {
            current = current.getPrevious();
        }
        return current;
    }

    private static boolean isFloatConstant(AbstractInsnNode instruction, float value) {
        return instruction instanceof LdcInsnNode && ((LdcInsnNode)instruction).cst instanceof Float &&
            Float.compare(((Float)((LdcInsnNode)instruction).cst).floatValue(), value) == 0;
    }

    private static byte[] patchExplosionFalloff(byte[] data) {
        ClassNode node = parse(data);
        MethodNode method = findMethod(node, "receivedTNT_1meter", "(F)F");
        int removed = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null;) {
            AbstractInsnNode next = instruction.getNext();
            if (instruction instanceof FieldInsnNode) {
                FieldInsnNode field = (FieldInsnNode)instruction;
                if (field.getOpcode() == GETFIELD && field.name.equals("bNuke") && field.desc.equals("Z")) {
                    AbstractInsnNode loadThis = previousReal(instruction);
                    AbstractInsnNode jump = nextReal(instruction);
                    if (loadThis != null && loadThis.getOpcode() == ALOAD && jump instanceof JumpInsnNode && jump.getOpcode() == IFEQ) {
                        method.instructions.remove(loadThis);
                        method.instructions.remove(instruction);
                        ((JumpInsnNode)jump).setOpcode(GOTO);
                        ++removed;
                    }
                }
            }
            instruction = next;
        }
        if (removed == 0) {
            verifyBytecode(node);
            return data;
        }
        if (removed != 1) {
            throw new IllegalStateException("Expected one bNuke constant-damage branch, got " + removed);
        }
        return emit(node);
    }

    private static AbstractInsnNode nextReal(AbstractInsnNode instruction) {
        AbstractInsnNode current = instruction.getNext();
        while (current != null && current.getOpcode() < 0) {
            current = current.getNext();
        }
        return current;
    }

    private static byte[] patchMsgExplosion(byte[] data) {
        ClassNode node = parse(data);
        MethodNode method = findMethod(
            node,
            "send",
            "(Lcom/maddox/il2/engine/Actor;Ljava/lang/String;Lcom/maddox/JGP/Point3d;Lcom/maddox/il2/engine/Actor;FFIFI)V"
        );
        if (countCalls(method, NUCLEAR_BLAST, "schedule") == 1) {
            verifyBytecode(node);
            return data;
        }
        for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
            if (!(instruction instanceof MethodInsnNode)) {
                continue;
            }
            MethodInsnNode call = (MethodInsnNode)instruction;
            AbstractInsnNode load = previousReal(instruction);
            if (call.getOpcode() == INVOKESTATIC && call.owner.equals(ACTOR) && call.name.equals("isValid") &&
                call.desc.equals("(Lcom/maddox/il2/engine/Actor;)Z") && load instanceof VarInsnNode &&
                load.getOpcode() == ALOAD && ((VarInsnNode)load).var == 0) {
                LabelNode skip = new LabelNode();
                InsnList addition = new InsnList();
                addition.add(new VarInsnNode(ILOAD, 8));
                addition.add(new InsnNode(ICONST_1));
                addition.add(new JumpInsnNode(IF_ICMPNE, skip));
                addition.add(new VarInsnNode(ALOAD, 2));
                addition.add(new VarInsnNode(ALOAD, 3));
                addition.add(new VarInsnNode(FLOAD, 5));
                addition.add(new VarInsnNode(ILOAD, 6));
                addition.add(new VarInsnNode(FLOAD, 7));
                addition.add(new MethodInsnNode(
                    INVOKESTATIC,
                    NUCLEAR_BLAST,
                    "schedule",
                    "(Lcom/maddox/JGP/Point3d;Lcom/maddox/il2/engine/Actor;FIF)V",
                    false
                ));
                addition.add(new InsnNode(RETURN));
                addition.add(skip);
                method.instructions.insertBefore(load, addition);
                return emit(node);
            }
        }
        throw new IllegalStateException("Could not find authoritative MsgExplosion dispatch block");
    }

    private static byte[] patchBomb(
        byte[] data,
        double airburstMeters,
        float power,
        float radius,
        float mass,
        float visualScale
    ) {
        ClassNode node = parse(data);
        for (FieldNode field : node.fields) {
            if (field.name.equals("osAirburstTriggered")) {
                verifyBytecode(node);
                return data;
            }
        }
        patchProperty(node, "power", Float.valueOf(power));
        patchProperty(node, "radius", Float.valueOf(radius));
        patchProperty(node, "massa", Float.valueOf(mass));
        node.fields.add(new FieldNode(ACC_PRIVATE, "osAirburstTriggered", "Z", null, null));

        for (MethodNode existing : node.methods) {
            if (existing.name.equals("interpolateTick") && existing.desc.equals("()V")) {
                throw new IllegalStateException(node.name + " already overrides interpolateTick");
            }
        }

        MethodNode method = new MethodNode(ACC_PUBLIC, "interpolateTick", "()V", null, null);
        LabelNode done = new LabelNode();
        InsnList code = method.instructions;
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new MethodInsnNode(INVOKESPECIAL, BOMB, "interpolateTick", "()V", false));
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new FieldInsnNode(GETFIELD, node.name, "osAirburstTriggered", "Z"));
        code.add(new JumpInsnNode(IFNE, done));
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new MethodInsnNode(INVOKEVIRTUAL, node.name, "isDestroyed", "()Z", false));
        code.add(new JumpInsnNode(IFNE, done));
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new FieldInsnNode(GETFIELD, ACTOR, "pos", "Lcom/maddox/il2/engine/ActorPos;"));
        code.add(new MethodInsnNode(INVOKEVIRTUAL, ACTOR_POS, "getAbsPoint", "()Lcom/maddox/JGP/Point3d;", false));
        code.add(new VarInsnNode(ASTORE, 1));
        code.add(new VarInsnNode(ALOAD, 1));
        code.add(new FieldInsnNode(GETFIELD, POINT3D, "z", "D"));
        code.add(new MethodInsnNode(INVOKESTATIC, ENGINE, "land", "()Lcom/maddox/il2/engine/Landscape;", false));
        code.add(new VarInsnNode(ALOAD, 1));
        code.add(new FieldInsnNode(GETFIELD, POINT3D, "x", "D"));
        code.add(new VarInsnNode(ALOAD, 1));
        code.add(new FieldInsnNode(GETFIELD, POINT3D, "y", "D"));
        code.add(new MethodInsnNode(INVOKEVIRTUAL, LANDSCAPE, "HQ", "(DD)D", false));
        code.add(new InsnNode(DSUB));
        code.add(new VarInsnNode(DSTORE, 2));
        code.add(new VarInsnNode(DLOAD, 2));
        code.add(new LdcInsnNode(Double.valueOf(airburstMeters)));
        code.add(new InsnNode(DCMPG));
        code.add(new JumpInsnNode(IFGT, done));
        code.add(new VarInsnNode(DLOAD, 2));
        code.add(new LdcInsnNode(Double.valueOf(5.0)));
        code.add(new InsnNode(DCMPL));
        code.add(new JumpInsnNode(IFLE, done));
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new InsnNode(ICONST_1));
        code.add(new FieldInsnNode(PUTFIELD, node.name, "osAirburstTriggered", "Z"));
        code.add(new TypeInsnNode(NEW, POINT3D));
        code.add(new InsnNode(DUP));
        code.add(new VarInsnNode(ALOAD, 1));
        code.add(new MethodInsnNode(INVOKESPECIAL, POINT3D, "<init>", "(Lcom/maddox/JGP/Point3d;)V", false));
        code.add(new VarInsnNode(ASTORE, 4));
        code.add(new MethodInsnNode(INVOKESTATIC, ENGINE, "land", "()Lcom/maddox/il2/engine/Landscape;", false));
        code.add(new VarInsnNode(ALOAD, 4));
        code.add(new FieldInsnNode(GETFIELD, POINT3D, "x", "D"));
        code.add(new VarInsnNode(ALOAD, 4));
        code.add(new FieldInsnNode(GETFIELD, POINT3D, "y", "D"));
        code.add(new MethodInsnNode(INVOKEVIRTUAL, LANDSCAPE, "isWater", "(DD)Z", false));
        LabelNode landEffect = new LabelNode();
        LabelNode afterEffect = new LabelNode();
        code.add(new JumpInsnNode(IFEQ, landEffect));
        code.add(new VarInsnNode(ALOAD, 4));
        code.add(new LdcInsnNode(Float.valueOf(-1.0F)));
        code.add(new LdcInsnNode(Float.valueOf(visualScale)));
        code.add(new MethodInsnNode(INVOKESTATIC, EXPLOSIONS, "bombFatMan_water", "(Lcom/maddox/JGP/Point3d;FF)V", false));
        code.add(new JumpInsnNode(GOTO, afterEffect));
        code.add(landEffect);
        code.add(new VarInsnNode(ALOAD, 4));
        code.add(new LdcInsnNode(Float.valueOf(-1.0F)));
        code.add(new LdcInsnNode(Float.valueOf(visualScale)));
        code.add(new MethodInsnNode(INVOKESTATIC, EXPLOSIONS, "bombFatMan_land", "(Lcom/maddox/JGP/Point3d;FF)V", false));
        code.add(afterEffect);
        code.add(new VarInsnNode(ALOAD, 0));
        code.add(new MethodInsnNode(INVOKESTATIC, ENGINE, "actorLand", "()Lcom/maddox/il2/engine/Actor;", false));
        code.add(new LdcInsnNode("Body"));
        code.add(new TypeInsnNode(NEW, POINT3D));
        code.add(new InsnNode(DUP));
        code.add(new VarInsnNode(ALOAD, 1));
        code.add(new MethodInsnNode(INVOKESPECIAL, POINT3D, "<init>", "(Lcom/maddox/JGP/Point3d;)V", false));
        code.add(new MethodInsnNode(
            INVOKEVIRTUAL,
            BOMB,
            "doExplosion",
            "(Lcom/maddox/il2/engine/Actor;Ljava/lang/String;Lcom/maddox/JGP/Point3d;)V",
            false
        ));
        code.add(done);
        code.add(new InsnNode(RETURN));
        node.methods.add(method);
        return emit(node);
    }

    private static void patchProperty(ClassNode node, String propertyName, Float replacement) {
        MethodNode clinit = findMethod(node, "<clinit>", "()V");
        int changes = 0;
        for (AbstractInsnNode instruction = clinit.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
            if (!(instruction instanceof LdcInsnNode) || !propertyName.equals(((LdcInsnNode)instruction).cst)) {
                continue;
            }
            AbstractInsnNode value = nextReal(instruction);
            if (!(value instanceof LdcInsnNode) || !(((LdcInsnNode)value).cst instanceof Float)) {
                throw new IllegalStateException("Unexpected " + propertyName + " property layout in " + node.name);
            }
            ((LdcInsnNode)value).cst = replacement;
            ++changes;
        }
        if (changes != 1) {
            throw new IllegalStateException("Expected one " + propertyName + " property in " + node.name + ", got " + changes);
        }
    }

    private static MethodNode findMethod(ClassNode node, String name, String descriptor) {
        MethodNode method = findMethodOrNull(node, name, descriptor);
        if (method != null) {
            return method;
        }
        throw new IllegalStateException("Method not found: " + node.name + "." + name + descriptor);
    }

    private static MethodNode findMethodOrNull(ClassNode node, String name, String descriptor) {
        for (MethodNode method : node.methods) {
            if (method.name.equals(name) && method.desc.equals(descriptor)) {
                return method;
            }
        }
        return null;
    }

    private static void copyDowngraded(Path source, Path destination) throws IOException {
        if (!Files.isRegularFile(source)) {
            throw new IOException("Compiled class missing: " + source);
        }
        ClassNode node = parse(Files.readAllBytes(source));
        write(destination, emit(node));
    }
}

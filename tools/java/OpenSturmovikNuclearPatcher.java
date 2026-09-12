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
                "Expected: baseExplosions silverplateExplosions Explosion MsgExplosion LittleBoy FatMan compiledNuclear outputDir"
            );
        }

        Path output = Paths.get(args[7]);
        Files.createDirectories(output);

        // Clean the reviewed mixed input before rebuilding. Validate the final
        // result too, so a donor cannot reintroduce removed MDS dependencies.
        byte[] cleanBase = OpenSturmovikControlsExplosionsPatcher.cleanExplosions(read(args[0]));
        byte[] rebuiltExplosions = patchExplosions(cleanBase, read(args[1]));
        write(output.resolve("Explosions.class"), OpenSturmovikControlsExplosionsPatcher.cleanExplosions(rebuiltExplosions));
        write(output.resolve("Explosion.class"), patchExplosionFalloff(read(args[2])));
        write(output.resolve("MsgExplosion.class"), patchMsgExplosion(read(args[3])));
        write(output.resolve("BombLittleBoy.class"), patchBomb(read(args[4]), 600.0, 15000000.0F, 2150.0F, 4400.0F, 0.894F));
        write(output.resolve("BombFatMan.class"), patchBomb(read(args[5]), 503.0, 21000000.0F, 2360.0F, 4670.0F, 1.0F));

        Path compiledNuclear = Paths.get(args[6]);
        validateShockVectorAbi(Files.readAllBytes(compiledNuclear.resolve("NuclearBlast$ShockAction.class")));
        validateVisualLifecycleAbi(
            Files.readAllBytes(compiledNuclear.resolve("NuclearBlast.class")),
            Files.readAllBytes(compiledNuclear.resolve("NuclearBlast$PhaseAction.class")),
            Files.readAllBytes(compiledNuclear.resolve("NuclearBlast$VisualTickAction.class")),
            Files.readAllBytes(compiledNuclear.resolve("NuclearBlast$State.class"))
        );
        copyDowngraded(compiledNuclear.resolve("NuclearBlast.class"), output.resolve("NuclearBlast.class"));
        copyDowngraded(compiledNuclear.resolve("NuclearBlast$DamageAction.class"), output.resolve("NuclearBlast$DamageAction.class"));
        copyDowngraded(compiledNuclear.resolve("NuclearBlast$DamageData.class"), output.resolve("NuclearBlast$DamageData.class"));
        copyDowngraded(compiledNuclear.resolve("NuclearBlast$ShockAction.class"), output.resolve("NuclearBlast$ShockAction.class"));
        copyDowngraded(compiledNuclear.resolve("NuclearBlast$ShockData.class"), output.resolve("NuclearBlast$ShockData.class"));
        copyDowngraded(compiledNuclear.resolve("NuclearBlast$PhaseAction.class"), output.resolve("NuclearBlast$PhaseAction.class"));
        copyDowngraded(compiledNuclear.resolve("NuclearBlast$VisualTickAction.class"), output.resolve("NuclearBlast$VisualTickAction.class"));
        copyDowngraded(compiledNuclear.resolve("NuclearBlast$State.class"), output.resolve("NuclearBlast$State.class"));
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

    private static void validateVisualLifecycleAbi(
        byte[] rootData,
        byte[] phaseActionData,
        byte[] visualTickActionData,
        byte[] stateData
    ) {
        ClassNode root = parse(rootData);
        MethodNode begin = findMethod(
            root,
            "beginVisual",
            "(Lcom/maddox/JGP/Point3d;FZ)V"
        );
        MethodNode register = findMethod(
            root,
            "registerVisual",
            "(Lcom/maddox/il2/engine/Eff3DActor;)V"
        );
        MethodNode end = findMethod(
            root,
            "endVisual",
            "()V"
        );
        MethodNode destroy = findMethod(
            root,
            "destroyActors",
            "(Lcom/maddox/il2/objects/effects/NuclearBlast$State;)V"
        );
        if ((begin.access & (ACC_PUBLIC | ACC_STATIC)) != (ACC_PUBLIC | ACC_STATIC) ||
            (register.access & (ACC_PUBLIC | ACC_STATIC)) != (ACC_PUBLIC | ACC_STATIC) ||
            (end.access & (ACC_PUBLIC | ACC_STATIC)) != (ACC_PUBLIC | ACC_STATIC)) {
            throw new IllegalStateException("Nuclear visual transaction methods must remain public static");
        }
        if (countCalls(root, "com/maddox/rts/Time", "current") < 3 ||
            countCalls(root, "com/maddox/rts/Time", "currentReal") != 0 ||
            countCalls(root, "com/maddox/rts/Time", "isPaused") != 0 ||
            countCalls(root, "java/lang/reflect/Method", "invoke") != 0) {
            throw new IllegalStateException(
                "Nuclear age must use simulation time only; real-time pause reconstruction is forbidden"
            );
        }
        if (countCalls(destroy, "com/maddox/il2/engine/Eff3DActor", "postDestroy") != 1 ||
            countCalls(root, "java/util/ArrayList", "clear") < 1 ||
            countCalls(root, "java/util/ArrayList", "remove") < 1) {
            throw new IllegalStateException("Nuclear visual actor cleanup ABI is incomplete");
        }

        ClassNode action = parse(phaseActionData);
        if (!action.superName.equals("com/maddox/rts/MsgAction")) {
            throw new IllegalStateException("Nuclear phase action must extend MsgAction");
        }
        MethodNode constructor = findMethod(
            action,
            "<init>",
            "(DLcom/maddox/il2/objects/effects/NuclearBlast$State;I)V"
        );
        int transitionCalls = countCalls(action, NUCLEAR_BLAST, "transition") +
            countSyntheticAccessCalls(
                action,
                NUCLEAR_BLAST,
                "(Lcom/maddox/il2/objects/effects/NuclearBlast$State;I)V"
            );
        if (countCalls(constructor, "com/maddox/rts/MsgAction", "<init>") != 1 ||
            transitionCalls != 1) {
            throw new IllegalStateException("Nuclear phase action must use one simulation-time MsgAction");
        }

        ClassNode visualAction = parse(visualTickActionData);
        if (!visualAction.superName.equals("com/maddox/rts/MsgAction")) {
            throw new IllegalStateException("Nuclear visual tick action must extend MsgAction");
        }
        MethodNode visualConstructor = findMethod(
            visualAction,
            "<init>",
            "(DLcom/maddox/il2/objects/effects/NuclearBlast$State;)V"
        );
        int visualTickCalls = countCalls(visualAction, NUCLEAR_BLAST, "visualTick") +
            countSyntheticAccessCalls(
                visualAction,
                NUCLEAR_BLAST,
                "(Lcom/maddox/il2/objects/effects/NuclearBlast$State;)V"
            );
        if (countCalls(visualConstructor, "com/maddox/rts/MsgAction", "<init>") != 1 ||
            visualTickCalls != 1) {
            throw new IllegalStateException("Nuclear visual tick must use one simulation-time MsgAction");
        }

        ClassNode state = parse(stateData);
        if (countCalls(state, "com/maddox/rts/Time", "currentReal") != 0) {
            throw new IllegalStateException("Persistent nuclear state must not depend on real time");
        }
        String[] requiredFields = {
            "detonationTime", "position", "altitudeMeters", "groundAltitudeMeters", "yieldKilotonnes",
            "water", "phase", "actors", "actorRoles", "actorsCreated", "actorsDestroyed",
            "lastVisualTickSimulation", "visualTicks", "stabilizedCreated", "transientsRetired",
            "riseRetired", "nextRiseLayerIndex", "riseLayersCreated", "riseLayersSkipped",
            "emissionComplete", "complete"
        };
        for (String fieldName : requiredFields) {
            boolean found = false;
            for (FieldNode field : state.fields) {
                if (field.name.equals(fieldName)) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                throw new IllegalStateException("Persistent nuclear state field missing: " + fieldName);
            }
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

    private static byte[] patchExplosions(byte[] baseData, byte[] silverplateData) {
        ClassNode base = parse(baseData);
        if (isAlreadyPatchedExplosions(base)) {
            scaleNuclearDispatchFromYield(base);
            verifyBytecode(base);
            return emit(base);
        }
        if (isMergedExplosions(base)) {
            scaleNuclearDispatchFromYield(base);
            forceSimulationTimerForNuclearEffects(base);
            registerNuclearVisuals(base);
            instrumentNuclearVisualLifecycle(base);
            return emit(base);
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

        Iterator<MethodNode> iterator = base.methods.iterator();
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
            base.methods.add(method);
        }
        if (removedFallbacks != 1) {
            throw new IllegalStateException("Expected to remove one nuclear bomb50_land fallback, got " + removedFallbacks);
        }
        removeNuclearAirburstCrater(base);
        scaleNuclearDispatchFromYield(base);
        scaleNuclearVisualsFromArgument(base);
        forceSimulationTimerForNuclearEffects(base);
        registerNuclearVisuals(base);
        instrumentNuclearVisualLifecycle(base);
        return emit(base);
    }

    private static void scaleNuclearDispatchFromYield(ClassNode node) {
        MethodNode generate = findMethod(
            node,
            "generate",
            "(Lcom/maddox/il2/engine/Actor;Lcom/maddox/JGP/Point3d;FIFI)V"
        );
        int dispatches = 0;
        for (AbstractInsnNode instruction = generate.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
            if (!(instruction instanceof MethodInsnNode)) {
                continue;
            }
            MethodInsnNode call = (MethodInsnNode)instruction;
            if (call.getOpcode() != INVOKESTATIC || !call.owner.equals(EXPLOSIONS) ||
                !(call.name.equals("bombFatMan_land") || call.name.equals("bombFatMan_water")) ||
                !call.desc.equals("(Lcom/maddox/JGP/Point3d;FF)V")) {
                continue;
            }
            // Silverplate also contains a later conventional very-large-bomb
            // branch with the same two calls. Only the first water/land pair
            // is selected by newEffect=1 for Little Boy and Fat Man.
            if (dispatches >= 2) {
                continue;
            }
            ++dispatches;
            AbstractInsnNode scale = previousReal(call);
            if (scale instanceof MethodInsnNode) {
                MethodInsnNode scaleCall = (MethodInsnNode)scale;
                if (scaleCall.getOpcode() == INVOKESTATIC && scaleCall.owner.equals(NUCLEAR_BLAST) &&
                    scaleCall.name.equals("visualScaleForPower") && scaleCall.desc.equals("(F)F")) {
                    continue;
                }
            }
            if (scale.getOpcode() != FCONST_1 && !isFloatConstant(scale, 1.0F)) {
                throw new IllegalStateException("Unexpected nuclear dispatch scale before " + call.name);
            }
            VarInsnNode loadPower = new VarInsnNode(FLOAD, 2);
            generate.instructions.set(scale, loadPower);
            generate.instructions.insert(
                loadPower,
                new MethodInsnNode(INVOKESTATIC, NUCLEAR_BLAST, "visualScaleForPower", "(F)F", false)
            );
        }
        if (dispatches != 2) {
            throw new IllegalStateException("Expected two yield-scaled nuclear visual dispatches, got " + dispatches);
        }
    }

    private static boolean isAlreadyPatchedExplosions(ClassNode node) {
        if (!isMergedExplosions(node)) {
            return false;
        }
        MethodNode land = findMethod(node, "bombFatMan_land", "(Lcom/maddox/JGP/Point3d;FF)V");
        MethodNode water = findMethod(node, "bombFatMan_water", "(Lcom/maddox/JGP/Point3d;FF)V");
        return countSimulationTimerGuards(land) + countSimulationTimerGuards(water) == 12 &&
            countVisualRegistrations(land) + countVisualRegistrations(water) == 12 &&
            countCalls(land, NUCLEAR_BLAST, "beginVisual") == 1 &&
            countCalls(water, NUCLEAR_BLAST, "beginVisual") == 1 &&
            countCalls(land, NUCLEAR_BLAST, "endVisual") == 1 &&
            countCalls(water, NUCLEAR_BLAST, "endVisual") == 1;
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
                "Expected 12 initial nuclear visual emitters registered for lifecycle ownership, got " + total +
                " after " + changes + " changes"
            );
        }
    }

    private static void instrumentNuclearVisualLifecycle(ClassNode node) {
        String[] methods = {"bombFatMan_land", "bombFatMan_water"};
        for (int methodIndex = 0; methodIndex < methods.length; ++methodIndex) {
            MethodNode method = findMethod(node, methods[methodIndex], "(Lcom/maddox/JGP/Point3d;FF)V");
            int beginCalls = countCalls(method, NUCLEAR_BLAST, "beginVisual");
            int endCalls = countCalls(method, NUCLEAR_BLAST, "endVisual");
            if (beginCalls == 0) {
                AbstractInsnNode earlyReturn = null;
                for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
                    if (instruction.getOpcode() == RETURN) {
                        earlyReturn = instruction;
                        break;
                    }
                }
                AbstractInsnNode bodyStart = nextReal(earlyReturn);
                if (earlyReturn == null || bodyStart == null) {
                    throw new IllegalStateException("Could not find rendered nuclear method entry: " + methods[methodIndex]);
                }
                InsnList begin = new InsnList();
                begin.add(new VarInsnNode(ALOAD, 0));
                begin.add(new VarInsnNode(FLOAD, 2));
                begin.add(new InsnNode(methodIndex == 1 ? ICONST_1 : ICONST_0));
                begin.add(new MethodInsnNode(
                    INVOKESTATIC,
                    NUCLEAR_BLAST,
                    "beginVisual",
                    "(Lcom/maddox/JGP/Point3d;FZ)V",
                    false
                ));
                method.instructions.insertBefore(bodyStart, begin);
            } else if (beginCalls != 1) {
                throw new IllegalStateException("Unexpected beginVisual count in " + methods[methodIndex] + ": " + beginCalls);
            }

            if (endCalls == 0) {
                AbstractInsnNode finalReturn = null;
                for (AbstractInsnNode instruction = method.instructions.getLast(); instruction != null; instruction = instruction.getPrevious()) {
                    if (instruction.getOpcode() == RETURN) {
                        finalReturn = instruction;
                        break;
                    }
                }
                if (finalReturn == null) {
                    throw new IllegalStateException("Could not find rendered nuclear method exit: " + methods[methodIndex]);
                }
                method.instructions.insertBefore(
                    finalReturn,
                    new MethodInsnNode(INVOKESTATIC, NUCLEAR_BLAST, "endVisual", "()V", false)
                );
            } else if (endCalls != 1) {
                throw new IllegalStateException("Unexpected endVisual count in " + methods[methodIndex] + ": " + endCalls);
            }
        }

        MethodNode land = findMethod(node, "bombFatMan_land", "(Lcom/maddox/JGP/Point3d;FF)V");
        MethodNode water = findMethod(node, "bombFatMan_water", "(Lcom/maddox/JGP/Point3d;FF)V");
        if (countCalls(land, NUCLEAR_BLAST, "beginVisual") != 1 ||
            countCalls(water, NUCLEAR_BLAST, "beginVisual") != 1 ||
            countCalls(land, NUCLEAR_BLAST, "endVisual") != 1 ||
            countCalls(water, NUCLEAR_BLAST, "endVisual") != 1) {
            throw new IllegalStateException("Nuclear visual transactions are incomplete");
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

    private static int countSyntheticAccessCalls(MethodNode method, String owner, String descriptor) {
        int count = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null; instruction = instruction.getNext()) {
            if (instruction instanceof MethodInsnNode) {
                MethodInsnNode call = (MethodInsnNode)instruction;
                if (call.owner.equals(owner) && call.name.startsWith("access$") && call.desc.equals(descriptor)) {
                    ++count;
                }
            }
        }
        return count;
    }

    private static int countSyntheticAccessCalls(ClassNode node, String owner, String descriptor) {
        int count = 0;
        for (MethodNode method : node.methods) {
            count += countSyntheticAccessCalls(method, owner, descriptor);
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
                MethodNode existing = findMethod(node, "interpolateTick", "()V");
                int removed = removeExplicitNuclearVisualCalls(existing);
                if (removed != 0 && removed != 2) {
                    throw new IllegalStateException(node.name + " has an incomplete duplicate visual dispatch: " + removed);
                }
                verifyBytecode(node);
                return removed == 0 ? data : emit(node);
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

    private static int removeExplicitNuclearVisualCalls(MethodNode method) {
        int removed = 0;
        for (AbstractInsnNode instruction = method.instructions.getFirst(); instruction != null;) {
            AbstractInsnNode next = instruction.getNext();
            if (instruction instanceof MethodInsnNode) {
                MethodInsnNode call = (MethodInsnNode)instruction;
                if (call.getOpcode() == INVOKESTATIC && call.owner.equals(EXPLOSIONS) &&
                    (call.name.equals("bombFatMan_land") || call.name.equals("bombFatMan_water")) &&
                    call.desc.equals("(Lcom/maddox/JGP/Point3d;FF)V")) {
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
        return removed;
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

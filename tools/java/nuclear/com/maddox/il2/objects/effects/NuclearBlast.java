package com.maddox.il2.objects.effects;

import com.maddox.JGP.Point3d;
import com.maddox.JGP.Vector3d;
import com.maddox.il2.ai.Explosion;
import com.maddox.il2.ai.MsgExplosionListener;
import com.maddox.il2.engine.Actor;
import com.maddox.il2.engine.Eff3D;
import com.maddox.il2.engine.Eff3DActor;
import com.maddox.il2.engine.Engine;
import com.maddox.il2.engine.Loc;
import com.maddox.il2.engine.Orient;
import com.maddox.il2.objects.air.Aircraft;
import com.maddox.rts.MsgAction;
import com.maddox.rts.Time;
import java.io.File;
import java.util.ArrayList;

/**
 * Bounded nuclear effects and delayed blast coupling for IL-2 4.09m.
 *
 * The damage and shock calculations deliberately remain independent from the
 * visual lifecycle. Simulation time is the sole source of visual age. A pause
 * therefore freezes the lifecycle without destroying or recreating an effect:
 * recreating an IL-2 4.09m emitter always restarts its internal particle age.
 */
public final class NuclearBlast {
    private static final double SPEED_OF_SOUND_METERS_PER_SECOND = 343.0;

    static final int PHASE_DETONATION = 0;
    static final int PHASE_EARLY_RISE = 1;
    static final int PHASE_MATURE_RISE = 2;
    static final int PHASE_LATE_RISE = 3;
    static final int PHASE_STABILIZED = 4;
    static final int PHASE_DISSIPATING = 5;
    static final int PHASE_COMPLETE = 6;

    static final long EARLY_RISE_AT_MILLISECONDS = 1000L;
    static final long MATURE_RISE_AT_MILLISECONDS = 30000L;
    static final long LATE_RISE_AT_MILLISECONDS = 120000L;
    static final long STABILIZED_AT_MILLISECONDS = 600000L;
    static final long DISSIPATING_AT_MILLISECONDS = 1800000L;
    static final long COMPLETE_AT_MILLISECONDS = 3600000L;
    static final long CLEANUP_DEADLINE_MILLISECONDS = 3728000L;
    static final long TRANSIENT_DRAIN_END_MILLISECONDS = 130000L;
    static final long RISE_DRAIN_END_MILLISECONDS = 728000L;
    private static final double VISUAL_TICK_SECONDS = 1.0;
    private static final long RISE_LAYER_MAX_AGE_MILLISECONDS = 190000L;
    private static final float RISE_LAYER_ACTOR_DURATION_SECONDS = 190.0F;
    private static final long[] RISE_LAYER_CHECKPOINTS_MILLISECONDS = {
        30000L, 90000L, 150000L, 210000L, 270000L,
        330000L, 390000L, 450000L, 510000L, 570000L
    };

    private static final String PARTICLE_PROBE_MARKER = "_OS_TEST_NUCLEAR_PARTICLE_AB.enabled";
    private static final boolean PARTICLE_CAPACITY_PROBE_ENABLED = new File(PARTICLE_PROBE_MARKER).isFile();
    private static final long PARTICLE_PROBE_COMPLETE_MILLISECONDS = 310000L;
    private static final long[] PARTICLE_PROBE_CHECKPOINTS_MILLISECONDS = {
        10000L, 60000L, 120000L, 130000L, 150000L, 180000L, 240000L, 300000L
    };

    private static final int ROLE_TRANSIENT = 0;
    private static final int ROLE_CLOUD_HEAD = 1;
    private static final int ROLE_CLOUD_TORUS = 2;
    private static final int ROLE_CLOUD_COLUMN = 3;
    private static final int ROLE_STABILIZED = 4;
    private static final int ROLE_PARTICLE_PROBE = 5;

    private static final double LITTLE_BOY_YIELD_KT = 15.0;
    private static final double FAT_MAN_YIELD_KT = 21.0;
    private static final double LITTLE_BOY_CLOUD_SUMMIT_AGL_METERS = 12000.0;
    private static final double FAT_MAN_CLOUD_SUMMIT_AGL_METERS = 13500.0;

    private static final String EFFECT_STABILIZED = "3DO/Effects/Fireworks/FatMan(stabilized).eff";
    private static final String EFFECT_RISE_HEAD = "3DO/Effects/Fireworks/FatMan(rise-head).eff";
    private static final String EFFECT_RISE_TORUS = "3DO/Effects/Fireworks/FatMan(rise-torus).eff";
    private static final String EFFECT_PARTICLE_PROBE_A =
        "3DO/Effects/OpenSturmovikTest/NuclearParticleCapacity-A.eff";
    private static final String EFFECT_PARTICLE_PROBE_B =
        "3DO/Effects/OpenSturmovikTest/NuclearParticleCapacity-B.eff";

    private static final ArrayList ACTIVE_STATES = new ArrayList();
    private static State currentVisualState;
    private static long nextEventId = 1L;
    private static long eventsCreated;
    private static long eventsCompleted;
    private static long actorsCreated;
    private static long actorsDestroyed;
    private static long phaseTransitions;
    private static long cleanupFailures;
    private static long visualTicks;
    private static Point3d pendingVisualPosition;
    private static double pendingVisualYieldKilotonnes;

    private NuclearBlast() {
    }

    /** Starts a visual transaction before the six initial emitters are made. */
    public static void beginVisual(Point3d burstPoint, float visualScale, boolean water) {
        if (burstPoint == null) {
            currentVisualState = null;
            return;
        }
        pruneCompletedStates();
        double inferredYieldKt = FAT_MAN_YIELD_KT * visualScale * visualScale * visualScale;
        if (pendingVisualPosition != null && pendingVisualPosition.distance(burstPoint) <= 25.0) {
            inferredYieldKt = pendingVisualYieldKilotonnes;
            pendingVisualPosition = null;
            pendingVisualYieldKilotonnes = 0.0;
        }
        State state = new State(
            nextEventId++,
            Time.current(),
            new Point3d(burstPoint),
            inferredYieldKt,
            water
        );
        ACTIVE_STATES.add(state);
        currentVisualState = state;
        ++eventsCreated;
        logState(state, "created");
        new PhaseAction(EARLY_RISE_AT_MILLISECONDS / 1000.0, state, PHASE_EARLY_RISE);
        new PhaseAction(MATURE_RISE_AT_MILLISECONDS / 1000.0, state, PHASE_MATURE_RISE);
        new PhaseAction(LATE_RISE_AT_MILLISECONDS / 1000.0, state, PHASE_LATE_RISE);
        new PhaseAction(STABILIZED_AT_MILLISECONDS / 1000.0, state, PHASE_STABILIZED);
        new PhaseAction(DISSIPATING_AT_MILLISECONDS / 1000.0, state, PHASE_DISSIPATING);
        new PhaseAction(COMPLETE_AT_MILLISECONDS / 1000.0, state, PHASE_COMPLETE);
        new VisualTickAction(VISUAL_TICK_SECONDS, state);
    }

    /** Registers one actor created by the initial nuclear visual method. */
    public static void registerVisual(Eff3DActor visual) {
        if (visual == null || !Actor.isValid(visual)) {
            return;
        }
        if (currentVisualState == null) {
            ++cleanupFailures;
            visual.postDestroy(Time.current());
            ++actorsDestroyed;
            System.out.println("Open Sturmovik nuclear: rejected an unowned visual actor");
            return;
        }
        int role = roleForInitialRegistration(currentVisualState.initialRegistrations++);
        if (currentVisualState.particleCapacityProbe) {
            ++currentVisualState.actorsCreated;
            ++actorsCreated;
            visual.postDestroy(Time.current());
            ++currentVisualState.actorsDestroyed;
            ++actorsDestroyed;
            return;
        }
        addActor(currentVisualState, visual, role);
    }

    /** Closes the synchronous Explosions visual transaction. */
    public static void endVisual() {
        if (currentVisualState != null && currentVisualState.initialRegistrations != 6) {
            ++cleanupFailures;
            StringBuffer message = new StringBuffer(96);
            message.append("Open Sturmovik nuclear: event=").append(currentVisualState.id);
            message.append(" initial_visuals=").append(currentVisualState.initialRegistrations);
            message.append(" expected=6");
            System.out.println(message.toString());
        }
        if (currentVisualState != null && currentVisualState.particleCapacityProbe) {
            startParticleCapacityProbe(currentVisualState);
        }
        currentVisualState = null;
    }

    public static void schedule(
        Point3d burstPoint,
        Actor initiator,
        float yieldKilogramsTnt,
        int powerType,
        float damageRadius
    ) {
        bindExactYield(burstPoint, yieldKilogramsTnt);
        if (burstPoint == null || yieldKilogramsTnt <= 0.0F || damageRadius <= 0.0F || Engine.collideEnv() == null) {
            return;
        }

        double yieldKilotonnes = yieldKilogramsTnt / 1000000.0;
        double cubeRootScale = Math.pow(yieldKilotonnes / 10.0, 1.0 / 3.0);
        double outerRadius = 4500.0 * cubeRootScale;
        ArrayList actors = new ArrayList();
        Engine.collideEnv().getSphere(actors, burstPoint, outerRadius);
        DamageData damage = new DamageData(
            new Point3d(burstPoint),
            initiator,
            yieldKilogramsTnt,
            powerType,
            damageRadius
        );

        for (int index = 0; index < actors.size(); ++index) {
            Object candidate = actors.get(index);
            if (!(candidate instanceof Actor)) {
                continue;
            }
            Actor aircraft = (Actor)candidate;
            if (!Actor.isValid(aircraft) || aircraft.pos == null) {
                continue;
            }

            Point3d aircraftPoint = aircraft.pos.getAbsPoint();
            double distance = aircraftPoint.distance(burstPoint);
            double delaySeconds = distance / SPEED_OF_SOUND_METERS_PER_SECOND;
            if (distance < damageRadius && candidate instanceof MsgExplosionListener) {
                new DamageAction(delaySeconds, aircraft, damage);
            }
            if (!(candidate instanceof Aircraft)) {
                continue;
            }
            double scaledDistance = distance / cubeRootScale;
            double pressurePsi = pressureAtTenKilotonScaledDistance(scaledDistance);
            double impulseMetersPerSecond = coupledAircraftImpulse(pressurePsi);
            if (impulseMetersPerSecond <= 0.0) {
                continue;
            }

            ShockData shock = new ShockData(new Point3d(burstPoint), impulseMetersPerSecond);
            new ShockAction(delaySeconds, aircraft, shock);
        }
    }

    /** Converts the explosive yield used by Explosions.generate to a visual scale. */
    public static float visualScaleForPower(float yieldKilogramsTnt) {
        if (yieldKilogramsTnt <= 0.0F) {
            return 1.0F;
        }
        return (float)Math.pow((yieldKilogramsTnt / 1000000.0) / FAT_MAN_YIELD_KT, 1.0 / 3.0);
    }

    static int phaseForAgeMilliseconds(long ageMilliseconds) {
        if (ageMilliseconds < EARLY_RISE_AT_MILLISECONDS) {
            return PHASE_DETONATION;
        }
        if (ageMilliseconds < MATURE_RISE_AT_MILLISECONDS) {
            return PHASE_EARLY_RISE;
        }
        if (ageMilliseconds < LATE_RISE_AT_MILLISECONDS) {
            return PHASE_MATURE_RISE;
        }
        if (ageMilliseconds < STABILIZED_AT_MILLISECONDS) {
            return PHASE_LATE_RISE;
        }
        if (ageMilliseconds < DISSIPATING_AT_MILLISECONDS) {
            return PHASE_STABILIZED;
        }
        if (ageMilliseconds < COMPLETE_AT_MILLISECONDS) {
            return PHASE_DISSIPATING;
        }
        return PHASE_COMPLETE;
    }

    public static String diagnosticSnapshot() {
        StringBuffer result = new StringBuffer(160);
        result.append("active=").append(ACTIVE_STATES.size());
        result.append(" events_created=").append(eventsCreated);
        result.append(" events_completed=").append(eventsCompleted);
        result.append(" actors_created=").append(actorsCreated);
        result.append(" actors_destroyed=").append(actorsDestroyed);
        result.append(" phase_transitions=").append(phaseTransitions);
        result.append(" visual_ticks=").append(visualTicks);
        result.append(" cleanup_failures=").append(cleanupFailures);
        return result.toString();
    }

    private static void bindExactYield(Point3d burstPoint, float yieldKilogramsTnt) {
        if (burstPoint == null || yieldKilogramsTnt <= 0.0F) {
            return;
        }
        State nearest = null;
        double nearestDistance = 25.0;
        for (int index = ACTIVE_STATES.size() - 1; index >= 0; --index) {
            State state = (State)ACTIVE_STATES.get(index);
            if (state.complete) {
                continue;
            }
            double distance = state.position.distance(burstPoint);
            if (distance <= nearestDistance) {
                nearest = state;
                nearestDistance = distance;
            }
        }
        if (nearest != null) {
            nearest.yieldKilotonnes = yieldKilogramsTnt / 1000000.0;
        } else {
            pendingVisualPosition = new Point3d(burstPoint);
            pendingVisualYieldKilotonnes = yieldKilogramsTnt / 1000000.0;
        }
    }

    private static void transition(State state, int requestedPhase) {
        if (state == null || state.complete || !ACTIVE_STATES.contains(state)) {
            return;
        }
        long age = Time.current() - state.detonationTime;
        int actualPhase = phaseForAgeMilliseconds(age);
        if (actualPhase < requestedPhase) {
            actualPhase = requestedPhase;
        }
        if (actualPhase <= state.phase) {
            return;
        }

        int previousPhase = state.phase;
        state.phase = actualPhase;
        ++phaseTransitions;
        if (age >= CLEANUP_DEADLINE_MILLISECONDS) {
            completeState(state);
            return;
        }
        // Phase transitions never replace an existing actor. Fixed, overlapping
        // rise layers are scheduled by visualTick so camera culling cannot move
        // their emission origin or send the cloud back to ground level.
        if (previousPhase < PHASE_STABILIZED && actualPhase >= PHASE_STABILIZED &&
            actualPhase < PHASE_COMPLETE && !state.stabilizedCreated) {
            createPhaseActors(state, PHASE_STABILIZED);
            state.stabilizedCreated = true;
        }
        if (actualPhase >= PHASE_COMPLETE) {
            state.emissionComplete = true;
        }
        logState(state, "phase");
    }

    private static void createPhaseActors(State state, int phase) {
        Point3d point = new Point3d(state.position);
        point.z += 5.0;
        if (phase == PHASE_STABILIZED) {
            point.z = state.groundAltitudeMeters + cloudSummitMeters(state.yieldKilotonnes);
            // The emitter stops before 3 600 s in its .eff. Keep its actor
            // alive through the 128-second particle drain, then use the
            // 3 728-second deadline as an explicit cleanup guard.
            float durationSeconds =
                (CLEANUP_DEADLINE_MILLISECONDS - STABILIZED_AT_MILLISECONDS) / 1000.0F;
            createEffect(state, point, EFFECT_STABILIZED, state.visualScale, durationSeconds, ROLE_STABILIZED);
        }
    }

    private static void createScheduledRiseLayers(State state, long age) {
        while (state.nextRiseLayerIndex < RISE_LAYER_CHECKPOINTS_MILLISECONDS.length) {
            int layerIndex = state.nextRiseLayerIndex;
            long checkpoint = RISE_LAYER_CHECKPOINTS_MILLISECONDS[layerIndex];
            if (checkpoint > age) {
                return;
            }
            ++state.nextRiseLayerIndex;
            if (age - checkpoint >= RISE_LAYER_MAX_AGE_MILLISECONDS) {
                ++state.riseLayersSkipped;
                continue;
            }

            Point3d point = cloudHeadPoint(state, checkpoint);
            createEffect(
                state,
                point,
                EFFECT_RISE_HEAD,
                state.visualScale,
                RISE_LAYER_ACTOR_DURATION_SECONDS,
                ROLE_CLOUD_HEAD
            );
            // One toroidal layer every 120 seconds limits the 16-bomb stress
            // case while preserving the widening mushroom cap.
            if ((layerIndex & 1) != 0) {
                createEffect(
                    state,
                    point,
                    EFFECT_RISE_TORUS,
                    state.visualScale,
                    RISE_LAYER_ACTOR_DURATION_SECONDS,
                    ROLE_CLOUD_TORUS
                );
            }
            ++state.riseLayersCreated;
            StringBuffer event = new StringBuffer(32);
            event.append("rise-layer-").append(checkpoint / 1000L).append('s');
            logState(state, event.toString());
        }
    }

    /**
     * Development-only A/B probe. The marker is never installed by the normal
     * add-on path. It suppresses the six Silverplate visuals and replaces them
     * with two colour-coded emitters which differ only by nParticles (64/512).
     */
    private static void startParticleCapacityProbe(State state) {
        Point3d lowCapacity = new Point3d(state.position);
        Point3d highCapacity = new Point3d(state.position);
        lowCapacity.x -= 750.0;
        highCapacity.x += 750.0;
        createEffect(
            state,
            lowCapacity,
            EFFECT_PARTICLE_PROBE_A,
            state.visualScale,
            312.0F,
            ROLE_PARTICLE_PROBE
        );
        createEffect(
            state,
            highCapacity,
            EFFECT_PARTICLE_PROBE_B,
            state.visualScale,
            312.0F,
            ROLE_PARTICLE_PROBE
        );
        logState(state, "particle-probe-start");
    }

    private static void createEffect(
        State state,
        Point3d point,
        String effect,
        float scale,
        float durationSeconds,
        int role
    ) {
        Eff3D.initSetTypeTimer(false);
        Orient orientation = new Orient();
        orientation.set(0.0F, 90.0F, 0.0F);
        Loc location = new Loc();
        location.set(point, orientation);
        Eff3DActor actor = Eff3DActor.New(location, scale, effect, durationSeconds);
        if (actor != null && Actor.isValid(actor)) {
            addActor(state, actor, role);
        }
    }

    private static void addActor(State state, Eff3DActor actor, int role) {
        state.actors.add(actor);
        state.actorRoles.add(new Integer(role));
        ++state.actorsCreated;
        ++actorsCreated;
    }

    private static void destroyActors(State state) {
        for (int index = 0; index < state.actors.size(); ++index) {
            Eff3DActor actor = (Eff3DActor)state.actors.get(index);
            if (actor != null && Actor.isValid(actor)) {
                actor.postDestroy(Time.current());
            }
            ++state.actorsDestroyed;
            ++actorsDestroyed;
        }
        state.actors.clear();
        state.actorRoles.clear();
    }

    private static void destroyActorsByRole(State state, int firstRole, int lastRole) {
        for (int index = state.actors.size() - 1; index >= 0; --index) {
            int role = ((Integer)state.actorRoles.get(index)).intValue();
            if (role < firstRole || role > lastRole) {
                continue;
            }
            Eff3DActor actor = (Eff3DActor)state.actors.remove(index);
            state.actorRoles.remove(index);
            if (actor != null && Actor.isValid(actor)) {
                actor.postDestroy(Time.current());
            }
            ++state.actorsDestroyed;
            ++actorsDestroyed;
        }
    }

    private static int roleForInitialRegistration(int index) {
        if (index == 1) {
            return ROLE_CLOUD_HEAD;
        }
        if (index == 2) {
            return ROLE_CLOUD_TORUS;
        }
        if (index == 3) {
            return ROLE_CLOUD_COLUMN;
        }
        return ROLE_TRANSIENT;
    }

    private static void visualTick(State state) {
        if (state == null || state.complete || !ACTIVE_STATES.contains(state)) {
            return;
        }

        long simulationNow = Time.current();
        long age = simulationNow - state.detonationTime;
        ++visualTicks;
        ++state.visualTicks;

        if (state.particleCapacityProbe) {
            logParticleProbeCheckpoints(state, age);
            state.lastVisualTickSimulation = simulationNow;
            if (age >= PARTICLE_PROBE_COMPLETE_MILLISECONDS) {
                completeState(state);
            } else {
                new VisualTickAction(VISUAL_TICK_SECONDS, state);
            }
            return;
        }

        if (!state.transientsRetired && age >= TRANSIENT_DRAIN_END_MILLISECONDS) {
            destroyActorsByRole(state, ROLE_TRANSIENT, ROLE_TRANSIENT);
            state.transientsRetired = true;
            logState(state, "transients-drained");
        }
        if (!state.riseRetired && age >= RISE_DRAIN_END_MILLISECONDS) {
            destroyActorsByRole(state, ROLE_CLOUD_HEAD, ROLE_CLOUD_COLUMN);
            state.riseRetired = true;
            logState(state, "rise-drained");
        }
        if (!state.riseRetired) {
            createScheduledRiseLayers(state, age);
        }

        state.lastVisualTickSimulation = simulationNow;
        if (age >= CLEANUP_DEADLINE_MILLISECONDS) {
            completeState(state);
        } else if (!state.complete) {
            new VisualTickAction(VISUAL_TICK_SECONDS, state);
        }
    }

    private static void logParticleProbeCheckpoints(State state, long age) {
        while (state.particleProbeCheckpoint < PARTICLE_PROBE_CHECKPOINTS_MILLISECONDS.length &&
            age >= PARTICLE_PROBE_CHECKPOINTS_MILLISECONDS[state.particleProbeCheckpoint]) {
            long checkpoint = PARTICLE_PROBE_CHECKPOINTS_MILLISECONDS[state.particleProbeCheckpoint];
            ++state.particleProbeCheckpoint;
            StringBuffer event = new StringBuffer(32);
            event.append("particle-probe-").append(checkpoint / 1000L).append('s');
            logState(state, event.toString());
        }
    }

    private static Point3d cloudHeadPoint(State state, long age) {
        Point3d point = new Point3d(state.position);
        double summit = state.groundAltitudeMeters + cloudSummitMeters(state.yieldKilotonnes);
        double availableRise = summit - state.position.z;
        if (availableRise < 0.0) {
            availableRise = 0.0;
        }
        double fraction = age <= 0L ? 0.0 : age / (double)STABILIZED_AT_MILLISECONDS;
        if (fraction > 1.0) {
            fraction = 1.0;
        }
        // Quadratic ease-out: fast buoyant rise, then progressive stabilization.
        double eased = 1.0 - (1.0 - fraction) * (1.0 - fraction);
        point.z += availableRise * eased + 5.0 * (1.0 - fraction);
        return point;
    }

    private static void completeState(State state) {
        if (!state.actors.isEmpty()) {
            destroyActors(state);
        }
        state.complete = true;
        state.phase = PHASE_COMPLETE;
        ACTIVE_STATES.remove(state);
        ++eventsCompleted;
        logState(state, "complete");
    }

    private static void pruneCompletedStates() {
        long now = Time.current();
        for (int index = ACTIVE_STATES.size() - 1; index >= 0; --index) {
            State state = (State)ACTIVE_STATES.get(index);
            if (state.complete || now < state.detonationTime ||
                now - state.detonationTime >= CLEANUP_DEADLINE_MILLISECONDS) {
                destroyActors(state);
                state.complete = true;
                ACTIVE_STATES.remove(index);
                ++eventsCompleted;
            }
        }
    }

    private static double cloudSummitMeters(double yieldKilotonnes) {
        if (yieldKilotonnes <= (LITTLE_BOY_YIELD_KT + FAT_MAN_YIELD_KT) * 0.5) {
            return LITTLE_BOY_CLOUD_SUMMIT_AGL_METERS;
        }
        return FAT_MAN_CLOUD_SUMMIT_AGL_METERS;
    }

    private static void logState(State state, String event) {
        long age = Time.current() - state.detonationTime;
        StringBuffer message = new StringBuffer(192);
        message.append("Open Sturmovik nuclear: event=").append(state.id);
        message.append(" action=").append(event);
        message.append(" phase=").append(phaseName(state.phase));
        message.append(" age_ms=").append(age);
        message.append(" surface=").append(state.water ? "water" : "land");
        message.append(" actors=").append(state.actors.size());
        message.append(" created=").append(state.actorsCreated);
        message.append(" destroyed=").append(state.actorsDestroyed);
        message.append(" ticks=").append(state.visualTicks);
        message.append(" rise_layers=").append(state.riseLayersCreated);
        message.append(" skipped_layers=").append(state.riseLayersSkipped);
        message.append(" target_agl_m=").append(
            Math.round(cloudHeadPoint(state, age).z - state.groundAltitudeMeters)
        );
        message.append(" transient_drain=").append(state.transientsRetired ? "done" : "pending");
        message.append(" rise_drain=").append(state.riseRetired ? "done" : "pending");
        message.append(" emission=").append(state.emissionComplete ? "complete" : "active");
        System.out.println(message.toString());
    }

    private static String phaseName(int phase) {
        switch (phase) {
            case PHASE_DETONATION:
                return "detonation";
            case PHASE_EARLY_RISE:
                return "early-rise";
            case PHASE_MATURE_RISE:
                return "mature-rise";
            case PHASE_LATE_RISE:
                return "late-rise";
            case PHASE_STABILIZED:
                return "stabilized";
            case PHASE_DISSIPATING:
                return "dissipating";
            default:
                return "complete";
        }
    }

    private static double pressureAtTenKilotonScaledDistance(double distanceMeters) {
        if (distanceMeters <= 480.0) {
            return 20.0;
        }
        if (distanceMeters <= 710.0) {
            return interpolate(distanceMeters, 480.0, 20.0, 710.0, 10.0);
        }
        if (distanceMeters <= 970.0) {
            return interpolate(distanceMeters, 710.0, 10.0, 970.0, 5.0);
        }
        if (distanceMeters <= 1800.0) {
            return interpolate(distanceMeters, 970.0, 5.0, 1800.0, 2.0);
        }
        if (distanceMeters <= 2700.0) {
            return interpolate(distanceMeters, 1800.0, 2.0, 2700.0, 1.0);
        }
        if (distanceMeters <= 4500.0) {
            return interpolate(distanceMeters, 2700.0, 1.0, 4500.0, 0.5);
        }
        return 0.0;
    }

    private static double coupledAircraftImpulse(double pressurePsi) {
        if (pressurePsi >= 20.0) {
            return 40.0;
        }
        if (pressurePsi >= 10.0) {
            return interpolate(pressurePsi, 10.0, 30.0, 20.0, 40.0);
        }
        if (pressurePsi >= 5.0) {
            return interpolate(pressurePsi, 5.0, 20.0, 10.0, 30.0);
        }
        if (pressurePsi >= 2.0) {
            return interpolate(pressurePsi, 2.0, 8.0, 5.0, 20.0);
        }
        if (pressurePsi >= 1.0) {
            return interpolate(pressurePsi, 1.0, 3.0, 2.0, 8.0);
        }
        if (pressurePsi >= 0.5) {
            return interpolate(pressurePsi, 0.5, 1.0, 1.0, 3.0);
        }
        return 0.0;
    }

    private static double interpolate(double value, double x1, double y1, double x2, double y2) {
        double fraction = (value - x1) / (x2 - x1);
        return y1 + fraction * (y2 - y1);
    }

    private static final class State {
        final long id;
        final long detonationTime;
        final Point3d position;
        final double altitudeMeters;
        final double groundAltitudeMeters;
        final boolean water;
        final float visualScale;
        final boolean particleCapacityProbe;
        final ArrayList actors = new ArrayList();
        final ArrayList actorRoles = new ArrayList();
        double yieldKilotonnes;
        long lastVisualTickSimulation;
        int phase = PHASE_DETONATION;
        int actorsCreated;
        int actorsDestroyed;
        int initialRegistrations;
        int visualTicks;
        int particleProbeCheckpoint;
        int nextRiseLayerIndex;
        int riseLayersCreated;
        int riseLayersSkipped;
        boolean stabilizedCreated;
        boolean transientsRetired;
        boolean riseRetired;
        boolean emissionComplete;
        boolean complete;

        State(long id, long detonationTime, Point3d position, double yieldKilotonnes, boolean water) {
            this.id = id;
            this.detonationTime = detonationTime;
            this.position = position;
            this.altitudeMeters = position.z;
            this.groundAltitudeMeters = Engine.land() == null ? 0.0 : Engine.land().HQ(position.x, position.y);
            this.yieldKilotonnes = yieldKilotonnes;
            this.water = water;
            this.visualScale = (float)Math.pow(yieldKilotonnes / FAT_MAN_YIELD_KT, 1.0 / 3.0);
            this.particleCapacityProbe = PARTICLE_CAPACITY_PROBE_ENABLED;
            this.lastVisualTickSimulation = detonationTime;
        }
    }

    private static final class VisualTickAction extends MsgAction {
        VisualTickAction(double delaySeconds, State state) {
            super(delaySeconds, state);
        }

        public void doAction(Object object) {
            if (object instanceof State) {
                visualTick((State)object);
            }
        }
    }

    private static final class PhaseAction extends MsgAction {
        private final int requestedPhase;

        PhaseAction(double delaySeconds, State state, int requestedPhase) {
            super(delaySeconds, state);
            this.requestedPhase = requestedPhase;
        }

        public void doAction(Object object) {
            if (object instanceof State) {
                transition((State)object, this.requestedPhase);
            }
        }
    }

    private static final class ShockData {
        final Point3d burstPoint;
        final double impulseMetersPerSecond;

        ShockData(Point3d burstPoint, double impulseMetersPerSecond) {
            this.burstPoint = burstPoint;
            this.impulseMetersPerSecond = impulseMetersPerSecond;
        }
    }

    private static final class ShockAction extends MyMsgAction {
        private final ShockData shock;

        ShockAction(double delaySeconds, Actor aircraft, ShockData shock) {
            super(delaySeconds, aircraft, shock);
            this.shock = shock;
        }

        public void doAction(Object object) {
            if (!(object instanceof Actor)) {
                return;
            }
            Actor aircraft = (Actor)object;
            if (!Actor.isValid(aircraft) || aircraft.pos == null) {
                return;
            }

            Point3d currentPoint = aircraft.pos.getAbsPoint();
            Vector3d radial = new Vector3d(
                currentPoint.x - this.shock.burstPoint.x,
                currentPoint.y - this.shock.burstPoint.y,
                currentPoint.z - this.shock.burstPoint.z
            );
            if (radial.lengthSquared() < 0.000001) {
                radial.set(0.0, 0.0, 1.0);
            } else {
                radial.normalize();
            }
            radial.scale(this.shock.impulseMetersPerSecond);

            Vector3d velocity = new Vector3d();
            aircraft.getSpeed(velocity);
            velocity.add(radial);
            aircraft.setSpeed(velocity);
        }
    }

    private static final class DamageData {
        final Point3d burstPoint;
        final Actor initiator;
        final float power;
        final int powerType;
        final float radius;

        DamageData(Point3d burstPoint, Actor initiator, float power, int powerType, float radius) {
            this.burstPoint = burstPoint;
            this.initiator = initiator;
            this.power = power;
            this.powerType = powerType;
            this.radius = radius;
        }
    }

    private static final class DamageAction extends MyMsgAction {
        private final DamageData damage;

        DamageAction(double delaySeconds, Actor actor, DamageData damage) {
            super(delaySeconds, actor, damage);
            this.damage = damage;
        }

        public void doAction(Object object) {
            if (!(object instanceof Actor) || !(object instanceof MsgExplosionListener)) {
                return;
            }
            Actor actor = (Actor)object;
            if (!Actor.isValid(actor)) {
                return;
            }

            Explosion explosion = new Explosion();
            explosion.chunkName = null;
            explosion.p = new Point3d(this.damage.burstPoint);
            explosion.radius = this.damage.radius;
            explosion.initiator = this.damage.initiator;
            explosion.power = this.damage.power;
            explosion.powerType = this.damage.powerType;
            explosion.bNuke = true;
            ((MsgExplosionListener)object).msgExplosion(explosion);
        }
    }
}

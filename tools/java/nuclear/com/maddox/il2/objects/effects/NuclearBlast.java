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
import com.maddox.il2.objects.air.Aircraft;
import com.maddox.rts.MsgAction;
import com.maddox.rts.Time;
import java.lang.reflect.Method;
import java.util.ArrayList;

/**
 * Performance-bounded nuclear blast coupling for aircraft.
 *
 * The damage message remains handled by IL-2. This class adds the delayed
 * arrival of the pressure wave and a bounded velocity impulse to aircraft.
 * Delays use MsgAction's simulation clock, so pausing the game pauses the
 * propagation instead of consuming it in real time.
 */
public final class NuclearBlast {
    private static final double SPEED_OF_SOUND_METERS_PER_SECOND = 343.0;
    private static final double ACTIVE_CLOUD_RISE_SECONDS = 600.0;
    private static final double STABILIZED_CLOUD_HEIGHT_10KT_METERS = 5000.0;
    private static final String STABILIZED_CLOUD_EFFECT =
        "3DO/Effects/Fireworks/FatMan(stabilized).eff";
    private static final int REAL_TIME_MESSAGE_FLAG = 64;
    private static final long PAUSE_WATCH_INTERVAL_MILLISECONDS = 25L;
    private static final ArrayList ACTIVE_VISUALS = new ArrayList();
    private static boolean pauseWatchScheduled = false;
    private static boolean visualsPaused = false;
    private static Method effectPauseMethod;
    private static boolean effectPauseMethodUnavailable = false;

    private NuclearBlast() {
    }

    public static void schedule(
        Point3d burstPoint,
        Actor initiator,
        float yieldKilogramsTnt,
        int powerType,
        float damageRadius
    ) {
        if (burstPoint == null || yieldKilogramsTnt <= 0.0F || damageRadius <= 0.0F || Engine.collideEnv() == null) {
            return;
        }

        double yieldKilotonnes = yieldKilogramsTnt / 1000000.0;
        double cubeRootScale = Math.pow(yieldKilotonnes / 10.0, 1.0 / 3.0);
        double visualScale = Math.pow(yieldKilotonnes / 21.0, 1.0 / 3.0);
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

        Point3d stabilizedCloudPoint = new Point3d(burstPoint);
        stabilizedCloudPoint.z += STABILIZED_CLOUD_HEIGHT_10KT_METERS * cubeRootScale;
        new VisualAction(
            ACTIVE_CLOUD_RISE_SECONDS,
            stabilizedCloudPoint,
            new VisualData((float)visualScale)
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

    /**
     * Retains each nuclear particle actor so its native emitter can be frozen
     * before IL-2 switches render focus to the pause menu. Without this native
     * pause, 4.09m rebuilds the emitter on return and visibly replays its age.
     */
    public static void registerVisual(Eff3DActor visual) {
        if (visual == null || !Actor.isValid(visual)) {
            return;
        }
        ACTIVE_VISUALS.add(visual);
        if (visualsPaused) {
            setVisualPaused(visual, true);
        }
        if (!pauseWatchScheduled) {
            pauseWatchScheduled = true;
            visualsPaused = Time.isPaused();
            new VisualAction(Time.currentReal() + PAUSE_WATCH_INTERVAL_MILLISECONDS);
        }
    }

    private static void pollVisualPause() {
        for (int index = ACTIVE_VISUALS.size() - 1; index >= 0; --index) {
            Eff3DActor visual = (Eff3DActor)ACTIVE_VISUALS.get(index);
            if (!Actor.isValid(visual)) {
                ACTIVE_VISUALS.remove(index);
            }
        }

        if (ACTIVE_VISUALS.isEmpty()) {
            pauseWatchScheduled = false;
            visualsPaused = false;
            return;
        }

        boolean paused = Time.isPaused();
        if (paused != visualsPaused) {
            visualsPaused = paused;
            for (int index = 0; index < ACTIVE_VISUALS.size(); ++index) {
                setVisualPaused((Eff3DActor)ACTIVE_VISUALS.get(index), paused);
            }
        }
        new VisualAction(Time.currentReal() + PAUSE_WATCH_INTERVAL_MILLISECONDS);
    }

    private static void setVisualPaused(Eff3DActor visual, boolean paused) {
        if (effectPauseMethodUnavailable || !Actor.isValid(visual)) {
            return;
        }
        try {
            Object effect = visual.getClass().getField("draw").get(visual);
            if (effect == null) {
                return;
            }
            if (effectPauseMethod == null) {
                effectPauseMethod = Class.forName("com.maddox.il2.engine.Eff3D").getDeclaredMethod(
                    "pause",
                    new Class[] { Boolean.TYPE }
                );
                effectPauseMethod.setAccessible(true);
            }
            effectPauseMethod.invoke(effect, new Object[] { paused ? Boolean.TRUE : Boolean.FALSE });
        } catch (Exception error) {
            effectPauseMethodUnavailable = true;
            System.out.println("Open Sturmovik: native nuclear effect pause unavailable: " + error);
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

    private static final class ShockData {
        final Point3d burstPoint;
        final double impulseMetersPerSecond;

        ShockData(Point3d burstPoint, double impulseMetersPerSecond) {
            this.burstPoint = burstPoint;
            this.impulseMetersPerSecond = impulseMetersPerSecond;
        }
    }

    private static final class VisualData {
        final float scale;

        VisualData(float scale) {
            this.scale = scale;
        }
    }

    private static final class VisualAction extends MsgAction {
        private final VisualData visual;

        VisualAction(double delaySeconds, Point3d cloudPoint, VisualData visual) {
            super(delaySeconds, cloudPoint);
            this.visual = visual;
        }

        VisualAction(long realTime) {
            super(REAL_TIME_MESSAGE_FLAG, realTime, null);
            this.visual = null;
        }

        public void doAction(Object object) {
            if (this.visual == null) {
                pollVisualPause();
                return;
            }
            if (!(object instanceof Point3d)) {
                return;
            }
            Eff3D.initSetTypeTimer(false);
            registerVisual(Eff3DActor.New(
                new Loc((Point3d)object),
                this.visual.scale,
                STABILIZED_CLOUD_EFFECT,
                -1.0F
            ));
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

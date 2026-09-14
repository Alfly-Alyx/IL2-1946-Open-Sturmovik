package com.maddox.il2.engine;

import com.maddox.JGP.Vector3d;

/** Compile-time signature stub. The game provides the real implementation. */
public abstract class Actor {
    public ActorPos pos;

    public static boolean isValid(Actor actor) {
        return false;
    }

    public double getSpeed(Vector3d speed) {
        return 0.0;
    }

    public void setSpeed(Vector3d speed) {
    }

    public void postDestroy(long simulationTime) {
    }
}

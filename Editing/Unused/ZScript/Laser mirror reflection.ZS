    Vector3 dirNormal;

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        dirNormal = vel.Unit ();
    }

    override void PostMovement () {
        vel = dirNormal * Speed;
    }

    override void S7_ExplodeMissile (Line l, Actor targ, bool onSky) {
        hitSky = onSky;
        if (onSky && !bSkyExplode) {
            Destroy ();
            return;
        }

        if (l && l.special == 182) {
            let wallNormal = (AngleToVector (VectorAngle (l.delta.X, l.delta.Y) - 90, 1.), 0).Unit ();

            if ((wallNormal dot dirNormal.Unit ()) > 0)
                wallNormal = -wallNormal;

            dirNormal = -S7_Math.ReflectVector (dirNormal.Unit (), wallNormal.Unit ());
            return;
        }

        ExplodeMissile (l, targ, onSky);
        dirNormal = (0, 0, 0);
    }
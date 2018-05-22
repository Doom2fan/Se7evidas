//-------------------------------------------------------------------------------------------
//
// M-400 Autogun
//
//-------------------------------------------------------------------------------------------
class S7_M400AutogunTracer : S7_BulletTracer {
    default {
        S7_BaseTracer.TrueSpeed 240;
        DamageFunction (fRandom [monsterDMG] (1.0, 3.0) * 3.875);
        DamageType "RifleTracer";
    }
}

class S7_M400AutogunStored : Inventory {
    int integrity;
    int ammo;
    property Integrity: integrity;
    property Ammo: ammo;

    default {
        Inventory.Amount 1;
        Inventory.MaxAmount 1;
        Inventory.Icon "graphics/Inventory/TurretIcon.png";
        Inventory.PickupMessage "$AUTOGUN";
        Tag "$AUTOGUN";

        S7_M400AutogunStored.Integrity 500;
        S7_M400AutogunStored.Ammo 1000;

        +INVENTORY.INVBAR
    }

    override bool Use (bool pickup) {
        if (integrity <= 0 || ammo <= 0)
            return false;

        bool success; Actor act;
        [success, act] = owner.A_SpawnItemEx ("S7_M400Autogun", owner.radius + (25*2), flags: SXF_TransferTranslation | SXF_SetMaster);

        if (!success || !act)
            return false;

        let autogun = S7_M400Autogun (act);

        if (autogun) {
            autogun.health = integrity;
            autogun.ammo = ammo;

            autogun.CopyFriendliness (owner, false, false);
            autogun.master = owner;
            autogun.SetFriendPlayer (owner.player);

            return true;
        }

        return false;
    }

    states {
    Spawn:
        TRT1 Z -1;
        stop;
    }
}

class S7_M400Autogun : S7_MonsterBase {
    default {
        Radius 25;
        Height 50;
        Mass 750;
        Speed 0;

        Health 500;
        PainChance 0;

        Obituary "$OBM400AUTOGUN";
        Species "M400Autogun";
        Tag "$AUTOGUN";

        DamageFactor "Plasma", 1.0;
        DamageFactor "LaserTracer", 1.0;
        DamageFactor "NerveGas", 0.0;

        +NOBLOOD
    }

    S7_XPSystem xpSys;
    int ammo;

    double initialAngle;
    double lookTime;
    bool turnCos;
    Actor aimMarkers [12];

    int useTimer;
    override bool Used (Actor user) {
        if (user != master)
            return false;

        if (user.CheckInventory ("S7_M400AutogunStored", 1)) {
            useTimer = 0;
            return false;
        }

        if (useTimer > 0) {
            user.GiveInventory ("S7_M400AutogunStored", 1);
            let stored = S7_M400AutogunStored (user.FindInventory ("S7_M400AutogunStored"));

            stored.integrity = health;
            stored.ammo = ammo;

            Destroy ();

            return false;
        } else
            useTimer = 35 * 2;

        return false;
    }

    override void PostBeginPlay () {
        if (!xpSys) {
            GiveInventory ("S7_XPSystem", 1);
            xpSys = S7_XPSystem (FindInventory ("S7_XPSystem", true));
        }

        let serverData = S7_ServerData.Get ();
        xpSys.canLevelUp = true;

        // Vitality
        startHealth = health *= 1.0 + (.05 * xpSys.GetStat (S7Stat_Vitality));

        ammo = 1000;

        initialAngle = angle;
        lookTime = 0;
        turnCos = (random [monsterSpc] (0, 1) == 1);
    }

    override bool OkayToSwitchTarget (Actor other) {
        return false; // NO
    }

    override void Tick () {
        useTimer--;

        if (!xpSys) {
            xpSys = S7_XPSystem (FindInventory ("S7_XPSystem", true));
            if (!xpSys) {
                GiveInventory ("S7_XPSystem", 1);
                xpSys = S7_XPSystem (FindInventory ("S7_XPSystem", true));
            }
        }

        // Strength
        damageMultiply = 1.0 + (0.02 * xpSys.GetStat (S7Stat_Strength / 2));
        // Defense
        damageFactor = clamp (1.0 - (0.01 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);

        Super.Tick ();
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source && source != master) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, 80 * max (1, level / 3));
            source.GiveInventory ("S7_Cash", 75 * max (1, level / 4));
        }
    }

    void SpawnMarker (out Actor aimMarker, out FLineTraceData data, double pitchOffs = 0.) {
        bool markerHit = LineTrace (angle, (1 << 16), pitch + pitchOffs, flags: TRF_NoSky, offsetz: 38.5, data: data);

        if (aimMarker) {
            aimMarker.SetOrigin (data.HitLocation, !(aimMarker.alpha ~== 0.));
            aimMarker.alpha = (markerHit ? 1. : 0.);
        } else {
            aimMarker = Spawn ("S7_TurretRedDot", data.HitLocation);
            aimMarker.target = self;
            aimMarker.alpha = 0.;
        }
    }

    static const double HitLocations [] = {
        0.65, 0.5 , 0.75,
        0.85, 0.25, 0.35,
        0.15, 0.9 , 0.0
    };

    void FindTarget () {
        static const double AimPitchOffsets [] = {
                0,
            -1, 1,
            -2, 2,
            -3, 3,
            -4, 4,
            -5, 5
        };

        if (target) {
            SetState (ResolveState ("Missile"));
            return;
        }

        Array<Actor> possibleTargets;
        possibleTargets.Clear ();

        for (int i = 0; i < AimPitchOffsets.Size (); i++) {
            FLineTraceData data;

            SpawnMarker (aimMarkers [i], data, AimPitchOffsets [i]);

            if (data.HitType == FLineTraceData.TRACE_HitActor)
                possibleTargets.Push (data.HitActor);
        }

        if (ammo <= 0)
            return;

        Actor newTarget = null;
        double closestDist = double.infinity;
        for (int i = 0; i < possibleTargets.Size (); i++) {
            let mo = possibleTargets [i];

            if (IsFriend (mo) || mo == master || mo.health <= 0 || mo.bInvulnerable || mo.bDormant)
                continue;

            double dist = Distance3D (mo);
            if (dist <= closestDist) {
                if (FindShootingPos (mo) != double.infinity) {
                    closestDist = dist;
                    newTarget = mo;
                }
            }
        }

        target = newTarget;

        if (target)
            SetState (ResolveState ("Missile"));
    }

    double FindShootingPos (Actor mo) {
        for (int i = 0; i < HitLocations.Size (); i++) {
            FLineTraceData data;
            double traceAngle, tracePitch;
            {
                let vecDiff = level.Vec3Diff (pos + (0, 0, 38.5), mo.pos + (0, 0, height * HitLocations [i]));
                traceAngle = atan2 (vecDiff.Y, vecDiff.X);
                tracePitch = atan2 (vecDiff.Z, vecDiff.XY.Length ());
            }
            bool result = LineTrace (traceAngle, (1 << 16), tracePitch, flags: TRF_NoSky, offsetz: 38.5, data: data);

            if (result && data.HitType == FLineTraceData.TRACE_HitActor && data.HitActor == mo)
                return HitLocations [i];
        }

        return double.infinity;
    }

    virtual Vector3 LeadTarget (Actor targ, double heightMod, double projSpeed) {
        if (!target)
            return (double.NaN, double.NaN, double.NaN);

        Vector3 targPos = targ.pos;
        targPos.z += targ.height * heightMod;
        if (targ.vel.x != 0 || targ.vel.y != 0 || targ.vel.z != 0) { // If the target is moving, lead it.
            Vector3 tempTargPos = S7_Math.CalculateInterceptShotPosition (pos, targPos, targ.vel, projSpeed);

            if (!(targPos.x != targPos.x) && !(targPos.y != targPos.y) && !(targPos.z != targPos.z))
                targPos = tempTargPos;
        }

        let marker = Spawn ("S7_PositionMarker", targPos);
        A_Face (marker, 0, 0);
        marker.Destroy ();
        return targPos;
    }

    states {
    Spawn:
    Idle:
        TRT1 A 1 {
            if (ammo <= 0) {
                for (int i = 0; i < aimMarkers.Size (); i++) {
                    if (aimMarkers [i])
                        aimMarkers [i].alpha = 0;
                }
            }

            double lookTimeSin = (turnCos ? cos (lookTime * 1.5) : sin (lookTime * 1.5));
            A_SetAngle (initialAngle + (90 * lookTimeSin), SPF_Interpolate);
            lookTime++;

            invoker.FindTarget ();
        }
        loop;

    Missile:
        TRT1 A 1 {
            for (int i = 0; i < aimMarkers.Size (); i++) {
                if (aimMarkers [i])
                    aimMarkers [i].alpha = 0;
            }

            double heightMod = FindShootingPos (target);

            if (ammo <= 0 || target.health <= 0 || target.bInvulnerable || target.bDormant || heightMod == double.infinity) {
                target = null;
                return ResolveState ("Idle");
            }

            LeadTarget (target, heightMod, 240);

            return ResolveState (null);
        }
        TRT1 A 1 {
            double heightMod = FindShootingPos (target);

            if (heightMod == double.infinity)
                heightMod = fRandom [monsterSpc] (0.25, 0.85);

            LeadTarget (target, heightMod, 240);
            A_SpawnProjectile ("S7_M400AutogunTracer", 38.5, 0.0, fRandom [monsterSpread] (-1., 1.), 0, fRandom [monsterSpread] (-1., 1.));

            A_SetTics (random [monsterSpc] (1, 2));
        }
        loop;

    Death:
        TRT1 A -1 {
            for (int i = 0; i < invoker.aimMarkers.Size (); i++) {
                if (invoker.aimMarkers [i])
                    invoker.aimMarkers [i].Destroy ();

                invoker.aimMarkers [i] = null;
            }
        }
        stop;

        //firing height: 38.5
    }
}

class S7_TurretRedDot : S7_EffectsBase {
    default {
        RenderStyle "Add";
        Scale .25;

        +NOGRAVITY +NOINTERACTION
    }

    states {
    Spawn:
        BAL1 A 1 bright {
            if (!target || target.health <= 0)
                Destroy ();
        }
        loop;
    }
}
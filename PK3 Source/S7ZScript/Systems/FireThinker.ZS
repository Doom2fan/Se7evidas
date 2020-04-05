/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2019 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

class S7_FireThinker_Data {
    S7_FireThinker_Group group;
    Actor source;

    double fireSize;
    int timeLeft;

    int DamageDelayTime;
    int damageTimer;
    name damageType;
    int damage;
    double damageMul;

    // Stick to actor
    double stickActorAngle;
    double stickActorRadius;
    double stickActorHeight;
    // Stick to wall
    Vector2 stickPlaneXYCoords;
    double  stickPlaneOffset;

    Vector3 GetCoords () {
        Vector3 ret = (0, 0, 0);

        switch (group.stickType) {
            case S7_FireThinker.StickType_Actor:
                let targ = group.stickActor;

                if (!targ)
                    return (0, 0, 0);

                ret.XY = Actor.AngleToVector (targ.angle + stickActorAngle, targ.radius * stickActorRadius);
                ret.Z = targ.Height * stickActorHeight;

                ret = level.Vec3Offset (targ.pos, ret);
            break;
            case S7_FireThinker.StickType_Plane:
                ret.XY = stickPlaneXYCoords;
                ret.Z = group.StickPlane_GetPlane ().ZAtPoint (stickPlaneXYCoords);

                ret = level.Vec3Offset (ret, (0, 0, stickPlaneOffset));
                break;
            default:
                ThrowAbortException ("S7_FireThinker: Unknown attachment type.");
            break;
        }

        return ret;
    }
}

class S7_FireThinker_Group {
    Vector3 centerCoords;

    int stickType;

    int SmokeDelayTime;
    int smokeDelay;
    int smokeMinDensity;
    int smokeMaxDensity;
    Class<S7_FireThinker_Smoke> smokeActor;

    int flameMinDelay;
    int flameMaxDelay;
    int flameDelay;
    int flameMinDensity;
    int flameMaxDensity;
    Class<S7_FireThinker_Flame> flameActor;

    // Stick to actor
    Actor stickActor;
    // Stick to plane
    Sector stickPlaneSector;
    bool   stickPlaneCeil;

    SecPlane StickPlane_GetPlane () {
        if (stickType != S7_FireThinker.StickType_Plane)
            return null;

        if (!stickPlaneSector)
            return null;

        if (stickPlaneCeil)
            return stickPlaneSector.CeilingPlane;

        return stickPlaneSector.FloorPlane;
    }

    Array<S7_FireThinker_Data> fireData;
}

class S7_FireThinker_BaseInfo {
    int duration;
    double fireSize;

    int damage;
    double damageMul;
    int damageDelay;
    name damageType;

    int smokeDelay;
    int smokeMinDensity;
    int smokeMaxDensity;
    Class<S7_FireThinker_Smoke> smokeActor;

    int flameMinDelay;
    int flameMaxDelay;
    int flameMinDensity;
    int flameMaxDensity;
    Class<S7_FireThinker_Flame> flameActor;
}

class S7_FireThinker : Actor {
    default {
        +NODAMAGETHRUST +BLOODLESSIMPACT +NOBLOCKMAP
        +FORCERADIUSDMG +NOEXTREMEDEATH
    }

    enum StickType {
        StickType_Actor = 1,
        StickType_Plane,
    }

    const stickPlane_MaxGroupDistance = 48.;

    S7_FastRNG smokeRNG;
    S7_FastRNG miscRNG;
    Array<S7_FireThinker_Group> fireGroups;

    void DoRadiusDamage (S7_FireThinker_Data fireData) {
        let firePos = fireData.GetCoords ();

        int damage = int (fireData.damage * fireData.damageMul);
        double maxDistSquared = fireData.fireSize * fireData.fireSize;

        let it = BlockThingsIterator.CreateFromPos (firePos.X, firePos.Y, firePos.Z, fireData.fireSize, fireData.fireSize, false);

        let chpData = new ('S7_CanHitPointData');
        chpData.ignoreAllActors = true;
        chpData.lineBlockFlags = Line.ML_BlockSight;

        if (fireData.group.stickActor) {
            fireData.group.stickActor.DamageMobj (
                null, fireData.source,
                damage,
                fireData.damageType,
                flags: DMG_No_Armor | DMG_Thrustless | DMG_No_Pain
            );
        }

        while (it.Next ()) {
            if (it.Thing == fireData.group.stickActor)
                continue;

            let act = it.Thing;

            // Vulnerable actors can be damaged by radius attacks even if not shootable
            if (!(act.bShootable || act.bVulnerable))
                continue;

            let diff = level.Vec3Diff (act.pos, firePos);

            if (!S7_Math.TestSphereAABB (firePos, fireData.fireSize, act.pos, (act.radius, act.height)))
                continue;

            if (!S7_ActorExtensions.CanHitPoint (level, firePos, act.pos, chpData))
                continue;

            act.DamageMobj (
                null, fireData.source,
                damage,
                fireData.damageType,
                flags: DMG_No_Armor | DMG_Thrustless | DMG_No_Pain
            );
        }
    }

    override void BeginPlay () {
        ChangeStatNum (STAT_User_Max);

        int time = MSTime ();

        if (!smokeRNG)
            smokeRNG = S7_FastRNG.CreateWithSeed (
                (time >>> 8) ^ (~time << 16) ^ (time >> 24)
            );
        if (!miscRNG)
            miscRNG = S7_FastRNG.CreateWithSeed (
                (~time << 8) ^ (time >>> 16) ^ (~time << 24)
            );
    }

    override void Tick () {
        if (isFrozen ())
            return;

        for (int i = fireGroups.Size () - 1; i >= 0; i--) {
            let group = fireGroups [i];

            if (group.stickType == StickType_Actor && !group.stickActor) {
                for (int j = group.fireData.Size () - 1; j >= 0; j--) {
                    group.fireData [j].Destroy ();
                    group.fireData.Delete (j, 1);
                }

                fireGroups.Delete (i, 1);
                group.Destroy ();
                continue;
            }

            for (int j = group.fireData.Size () - 1; j >= 0; j--) {
                let fire = group.fireData [j];
                if (++fire.damageTimer >= fire.damageDelayTime) {
                    DoRadiusDamage (fire);
                    fire.damageTimer = 0;
                }

                if (--fire.timeLeft < 1) {
                    group.fireData.Delete (j, 1);
                    fire.Destroy ();
                }
            }

            if (group.smokeActor && --group.smokeDelay < 1) {
                int smokeCount;
                if (group.smokeMinDensity != group.smokeMaxDensity)
                    smokeCount = min (smokeRNG.GetInt (group.smokeMinDensity, group.smokeMaxDensity), group.fireData.Size ());
                else
                    smokeCount = min (group.smokeMaxDensity, group.fireData.Size ());

                for (int j = smokeCount; j > 0; j--) {
                    int idx = smokeRNG.GetInt (0, group.fireData.Size () - 1);
                    let fireData = group.fireData [idx];

                    let smoke = S7_FireThinker_Smoke (Spawn (group.smokeActor, fireData.GetCoords (), ALLOW_REPLACE));

                    if (smoke) {
                        smoke.smokeRNG = smokeRNG;
                        smoke.fireSize = fireData.fireSize;
                    }
                }

                group.smokeDelay = group.SmokeDelayTime;
            }

            if (group.flameActor && --group.flameDelay < 1) {
                int flameCount;
                if (group.flameMinDensity != group.flameMaxDensity)
                    flameCount = min (smokeRNG.GetInt (group.flameMinDensity, group.flameMaxDensity), group.fireData.Size ());
                else
                    flameCount = min (group.flameMaxDensity, group.fireData.Size ());

                for (int j = flameCount; j > 0; j--) {
                    int idx = smokeRNG.GetInt (0, group.fireData.Size () - 1);
                    let fireData = group.fireData [idx];

                    let flame = S7_FireThinker_Flame (Spawn (group.flameActor, fireData.GetCoords (), ALLOW_REPLACE));

                    if (flame) {
                        flame.flameRNG = smokeRNG;
                        flame.fireSize = fireData.fireSize;
                    }
                }

                if (group.flameMinDelay != group.flameMaxDelay)
                    group.flameDelay = smokeRNG.GetInt (group.flameMinDelay, group.flameMaxDelay);
                else
                    group.flameDelay = group.flameMaxDelay;
            }

            if (group.fireData.Size () < 1) {
                fireGroups.Delete (i, 1);
                group.Destroy ();
            }
        }
    }

    protected S7_FireThinker_Data GetNewFireData (S7_FireThinker_Group group, Actor source, S7_FireThinker_BaseInfo info) {
        let fireData = new ('S7_FireThinker_Data');

        fireData.group = group;
        fireData.source = source;

        fireData.fireSize = info.fireSize;
        fireData.timeLeft = info.duration;

        fireData.DamageDelayTime = info.damageDelay;
        fireData.damageTimer = int (clamp (info.damageDelay * miscRNG.GetFloat (0.0, 1.0), 0, info.damageDelay));
        fireData.damage = info.damage;
        fireData.damageMul = info.damageMul;
        fireData.damageType = info.damageType;

        group.fireData.Push (fireData);

        return fireData;
    }

    protected S7_FireThinker_Group GetNewFireGroup (Vector3 centerCoords, S7_FireThinker_BaseInfo info) {
        let group = new ('S7_FireThinker_Group');

        group.centerCoords = centerCoords;
        group.fireData.Clear ();

        group.smokeActor = info.smokeActor;
        group.SmokeDelayTime = info.smokeDelay;
        group.smokeDelay = int (clamp (info.smokeDelay * smokeRNG.GetFloat (0.0, 1.0), 0, info.smokeDelay));
        group.smokeMinDensity = info.smokeMinDensity;
        group.smokeMaxDensity = info.smokeMaxDensity;

        group.flameActor = info.flameActor;
        group.flameMinDelay = info.flameMinDelay;
        group.flameMaxDelay = info.flameMaxDelay;
        group.flameMinDensity = info.flameMinDensity;
        group.flameMaxDensity = info.flameMaxDensity;

        group.flameDelay = int (clamp (group.flameMaxDelay * smokeRNG.GetFloat (0.0, 1.0), 0, group.flameMaxDelay));

        fireGroups.Push (group);

        return group;
    }

    static bool CheckGroupBaseInfo (S7_FireThinker_Group group, S7_FireThinker_BaseInfo info) {
        return (
            group.smokeActor == info.smokeActor &&
            group.smokeDelay == info.smokeDelay &&
            group.smokeMinDensity == info.smokeMinDensity &&
            group.smokeMaxDensity == info.smokeMaxDensity &&

            group.flameActor == info.flameActor &&
            group.flameMinDelay == info.flameMinDelay &&
            group.flameMaxDelay == info.flameMaxDelay &&
            group.flameMinDensity == info.flameMinDensity &&
            group.flameMaxDensity == info.flameMaxDensity
        );
    }

    static void AttachFire_Actor (Actor target, Actor source, Vector3 fireCoords, S7_FireThinker_BaseInfo info) {
        let manager = Get ();

        S7_FireThinker_Group group = null;
        for (int i = manager.fireGroups.Size () - 1; i >= 0; i--) {
            let fireGroup = manager.fireGroups [i];

            if (fireGroup.stickType != StickType_Actor)
                continue;
            if (fireGroup.stickActor != target)
                continue;
            if (CheckGroupBaseInfo (fireGroup, info))
                continue;

            group = fireGroup;
            break;
        }

        if (group == null) {
            group = manager.GetNewFireGroup (fireCoords, info);

            group.stickType = StickType_Actor;
            group.stickActor = target;
        }

        let fireData = manager.GetNewFireData (group, source, info);
        let posDiff = level.Vec3Diff (target.pos, fireCoords);

        fireData.stickActorAngle = DeltaAngle (target.angle, atan2 (posDiff.Y, posDiff.X));
        fireData.stickActorRadius = (posDiff.XY.Length () / target.radius);
        fireData.stickActorHeight = (posDiff.Z / target.height);
    }

    static void AttachFire_Plane (Sector sec, bool ceil, Actor source, Vector3 fireCoords, S7_FireThinker_BaseInfo info) {
        let manager = Get ();

        S7_FireThinker_Group group = null;
        for (int i = manager.fireGroups.Size () - 1; i >= 0; i--) {
            let fireGroup = manager.fireGroups [i];

            if (fireGroup.stickType != StickType_Plane)
                continue;
            if (fireGroup.stickPlaneSector != sec || fireGroup.stickPlaneCeil != ceil)
                continue;
            if (CheckGroupBaseInfo (fireGroup, info))
                continue;

            let diff = level.Vec3Diff (fireGroup.centerCoords, fireCoords);
            if (abs (diff dot diff) > stickPlane_MaxGroupDistance*stickPlane_MaxGroupDistance)
                continue;

            group = fireGroup;
            break;
        }

        if (group == null) {
            group = manager.GetNewFireGroup (fireCoords, info);

            group.stickType = StickType_Plane;
            group.stickPlaneSector = sec;
            group.stickPlaneCeil = ceil;
        }

        let fireData = manager.GetNewFireData (group, source, info);

        fireData.stickPlaneXYCoords = fireCoords.XY;
        fireData.stickPlaneOffset = fireCoords.Z - group.StickPlane_GetPlane ().ZAtPoint (fireCoords.XY);
    }

    static bool StickFromActor (Actor act, Actor source, Actor targAct, S7_FireThinker_BaseInfo info) {
        if (targAct) {
            AttachFire_Actor (targAct, source, act.pos, info);
            return true;
        } else if (act.pos.Z <= act.floorZ || act.BlockingFloor) {
            Sector sec = act.BlockingFloor;

            if (!sec)
                sec = act.CurSector;

            AttachFire_Plane (sec, false, source, act.pos, info);

            return true;
        } else if ((act.pos.Z + act.height) >= act.ceilingZ || act.BlockingCeiling) {
            Sector sec = act.BlockingCeiling;

            if (!sec)
                sec = act.CurSector;

            AttachFire_Plane (sec, true, source, act.pos, info);

            return true;
        } else if (act.BlockingLine) {
            Line ld = act.BlockingLine;
            int lineSide = S7_Math.PointOnLineSidePrecise (act.pos.X, act.pos.Y, ld);

            Sector sec = null;
            bool ceil = false;

            if (!ld.sidedef [!lineSide]) {
                sec = ld.sidedef [lineSide].Sector;
                ceil = false;
            } else {
                let thisSec = ld.sidedef [!lineSide].Sector;

                if (act.pos.Z <= thisSec.FloorPlane.ZAtPoint (act.pos.XY)) {
                    sec = thisSec;
                    ceil = false;
                } else if ((act.pos.Z + act.height) >= thisSec.CeilingPlane.ZAtPoint (act.pos.XY)) {
                    sec = thisSec;
                    ceil = true;
                }
            }

            if (sec) {
                AttachFire_Plane (sec, ceil, source, act.pos, info);
                return true;
            }
        }

        return false;
    }

    protected static S7_FireThinker Get () {
        ThinkerIterator it = ThinkerIterator.Create ('S7_FireThinker', STAT_User_Max);
        let p = S7_FireThinker (it.Next ());

        if (!p)
            p = S7_FireThinker (Spawn ('S7_FireThinker', replace: NO_REPLACE));

        return p;
    }
}

class S7_FireThinker_Smoke : S7_WhiteSmoke {
    default {
        RenderStyle "Translucent";
        Alpha 0.75;

        // Enforce determinism
        FloatBobPhase 0;

        +ROLLSPRITE
    }

    S7_FastRNG smokeRNG;
    double fireSize;

    int chosenFrame;
    int fadeTime;
    double scaleTarget;
    double scaleSpeed;
    double alphaSpeed;

    override void PostBeginPlay () {
        chosenFrame = smokeRNG.GetInt (0, 24);

        double offsMax = fireSize / 3.;
        SetOrigin (Vec3Offset (
            smokeRNG.GetFloat (-offsMax, offsMax),
            smokeRNG.GetFloat (-offsMax, offsMax),
            smokeRNG.GetFloat (-offsMax, offsMax)
        ), false);

        if ((pos.Z + height) < ceilingZ)
            vel.Z = smokeRNG.GetFloat (0., 2.);

        alpha += smokeRNG.GetFloat (-0.1, 0.1);
        alphaSpeed = 0.05;

        roll = smokeRNG.GetFloat (0, 360);
        bSpriteFlip = smokeRNG.GetInt (0, 1);

        A_SetScale (smokeRNG.GetFloat (0.01, 0.065));
        scaleTarget = smokeRNG.GetFloat (.1, .2);
        if (scale.X < 0)
            scaleTarget = -scaleTarget;

        fadeTime = smokeRNG.GetInt (5, 8);
    }

    override void Tick () {
        frame = chosenFrame;

        if (!(vel ~== (0, 0, 0))) {
            let newPos = level.Vec3Offset (pos, vel);
            bool xyPosEqual = (newPos.XY ~== pos.XY);

            if (xyPosEqual && !(vel.Z ~== 0)) {
                Prev.Z = pos.Z;
                SetZ (newPos.Z);
            } else if (!xyPosEqual)
                SetOrigin (pos + vel, true);
        }

        if (fadeTime > 0)
            fadeTime--;
        else if ((alpha -= alphaSpeed) < alphaSpeed) {
            Destroy ();
            return;
        }

        scaleSpeed = S7_Math.DampedSpring (scale.x, scaleTarget, scaleSpeed, .25, .5);
        scale.X = scale.X + scaleSpeed;
        scale.Y = scale.X;
    }

    states {
    Spawn:
        SMK3 A -1;
        stop;
    }
}

class S7_FireThinker_Flame : S7_FireBase {
    S7_FastRNG flameRNG;
    double fireSize;
}
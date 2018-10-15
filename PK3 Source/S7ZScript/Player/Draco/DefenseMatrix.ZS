/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

extend class S7_DracoPlayer {
    const MaxDefMatEnergy = 500;
    int defenseMatrixEnergy;
    int dmEnergyRegenTime;
    int laserCooldown;

    void Tick_DefenseMatrix () {
        if (laserCooldown > 0)
            laserCooldown--;

        if (defenseMatrixEnergy > MaxDefMatEnergy)
            defenseMatrixEnergy = MaxDefMatEnergy;
        else if (defenseMatrixEnergy < MaxDefMatEnergy && !dmEnergyRegenTime) {
            defenseMatrixEnergy = min (defenseMatrixEnergy + 5, MaxDefMatEnergy);
            dmEnergyRegenTime = 17;
        } else if (dmEnergyRegenTime > 0)
            dmEnergyRegenTime--;

        if (defenseMatrixEnergy > 0) {
            ThinkerIterator actorFinder = ThinkerIterator.Create ("Actor", Thinker.STAT_DEFAULT);

            Actor mo;
            while (mo = Actor (actorFinder.Next ())) {
                if (mo is "S7_EffectsBase" || !mo.bMissile || mo.bKilled || !mo.target || mo.target == self || isFriend (mo.target))
                    continue;

                if (defenseMatrixEnergy >= 5 && abs (Distance3D (mo)) <= 160.0 && !(random [dracoADM] () < 8)) {
                    let zap = Spawn ("S7_DracoADMZap", mo.pos, ALLOW_REPLACE);
                    zap.target = self;
                    mo.ExplodeMissile (NULL, zap, false);

                    defenseMatrixEnergy -= 5;
                    continue;
                }

                if (defenseMatrixEnergy >= 6 && !laserCooldown && !(random [dracoADM] () < 16)) {
                    if (mo.bSeekerMissile && mo.tracer == self && abs (mo.Distance2D (mo.target)) >= (mo.target.radius * 1.5)) {
                        laserCooldown = 0;

                        if (defenseMatrixEnergy >= 3 && FireLaser (mo, -5)) {
                            laserCooldown += 5;
                            defenseMatrixEnergy -= 3;
                        }
                        if (defenseMatrixEnergy >= 3 && FireLaser (mo,  5)) {
                            laserCooldown += 5;
                            defenseMatrixEnergy -= 3;
                        }
                    }
                }
            }
        }
    }

    bool FireLaser (Actor mo, double xy_off) {
        if (!mo)
            return false;

        double angCos = cos (angle), angSin = sin (angle);
        let misPos = mo.Vec3Offset (0, 0, mo.height / 2);
        let laserStartPos = Vec3Offset (xy_off * angCos, xy_off * angSin, 50);

        bool canIntercept;
        Vector3 aimPos;
        [canIntercept, aimPos] = S7_Math.CalculateInterceptShotPosition (laserStartPos, misPos, mo.vel, 350);

        if (!canIntercept)
            return false;

        let chpData = new ("S7_CanHitPointData");
        chpData.ignoredActors.Push (self);
        chpData.ignoredActors.Push (mo);
        chpData.lineBlockFlags = Line.ML_BLOCKPROJECTILE;
        if (!S7_ActorExtensions.CanHitPoint (laserStartPos, misPos, chpData)) {
            if (S7_ActorExtensions.CanHitPoint (laserStartPos, mo.pos, chpData))
                aimPos = mo.pos;
            else
                return false;
        }

        let laser = A_SpawnProjectile ("S7_DracoADMLaser", 50, xy_off, chpData.AngleTo, CMF_AimDirection | CMF_AbsoluteAngle | CMF_AbsolutePitch, chpData.PitchTo);

        if (laser)
            laser.tracer = mo;

        return true;
    }
}

class S7_DracoADMZap : S7_DebrisGeneral {
    default {
        RenderStyle "add";
        Alpha 1.0;
        Scale 0.5;

        +THRUACTORS
    }

    states {
    Spawn:
        TNT1 A 0 A_Jump (256, "FrameA", "FrameB", "FrameC", "FrameD", "FrameE");
        wait;

    FrameA: ZAP1 A 0 { return ResolveState ("Anim"); }
    FrameB: ZAP1 B 0 { return ResolveState ("Anim"); }
    FrameC: ZAP1 C 0 { return ResolveState ("Anim"); }
    FrameD: ZAP1 D 0 { return ResolveState ("Anim"); }
    FrameE: ZAP1 E 0 { return ResolveState ("Anim"); }

    Anim:
        #### # 2 bright {
            int spawnCount = random [sfx] (4, 7);

            for (int i = 0; i < spawnCount; i++) {
                double spd = fRandom [sfx] (-5.0, 5.0);
                double ang = fRandom [sfx] (0, 360);

                A_SpawnItemEx ("S7_DracoADMZapSparks", fRandom [sfx] (-2.0, 2.0), fRandom [sfx] (-2.0, 2.0), fRandom [sfx] (-2.0, 2.0),
                    spd * cos (ang), spd * sin (ang), fRandom [sfx] (1.5, 3.0), flags: SXF_NoCheckPosition | SXF_Clientside | SXF_SetTarget);
            }
        }
        stop;
    }
}

class S7_DracoADMZapSparks : S7_DebrisGeneral {
    default {
        RenderStyle "add";
        Alpha 1.0;
        Gravity 0.25;

        +THRUACTORS -NOGRAVITY
    }

    states {
    Spawn:
        TNT1 A 0 A_Jump (256, "Frame1", "Frame2", "Frame3");
        wait;

    Frame1: PLSE B 0 { return ResolveState ("Anim"); }
    Frame2: PLSE C 0 { return ResolveState ("Anim"); }
    Frame3: PLSE D 0 { return ResolveState ("Anim"); }

    Anim:
        #### # 2 bright A_SetScale (fRandom [sfx] (0.08, 0.25) * randomPick [sfx] (1, -1));
        #### # 1 bright A_FadeOut (0.05);
        wait;
    }
}

class S7_DracoADMLaser : S7_BaseTracer {
    default {
        S7_Projectile.MovementMode OldFastProj;
        DamageFunction (fRandom [weaponDamage] (1.0, 4.0));
        Speed 350;
        DamageType "LaserTracer";
        Scale 0.015;
        MissileType "S7_LaserTracerTrail";
        Decal "S7_LaserDecal";

        -BLOODSPLATTER
    }

    override void Effect () {
        Super.Effect ();

        if (tracer && S7_Math.CheckActorCollision (self, tracer)) {
            tracer.ExplodeMissile (NULL, self, false);
            ExplodeMissile (NULL, tracer);
        }
    }

    states {
    Spawn:
        TNT1 A 0;
    Idle:
        LSFL A 1 bright;
        wait;

    Death:
    Crash:
        TNT1 A 3; //A_SpawnItemEx ("S7_LaserPuff")
        stop;
    XDeath:
        TNT1 A 3;
        stop;
    }
}

class S7_DracoADMLaserMarker : S7_PositionMarker {
    default {
        Radius 20;
        Height 16;

        +SHOOTABLE
        -NOBLOCKMAP -NOINTERACTION -NOCLIP
    }
}
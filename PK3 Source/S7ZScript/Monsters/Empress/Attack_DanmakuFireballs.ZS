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

extend class S7_Empress {
    const DanmakuFireballs_Time_CreateTetragram = 3;
    const DanmakuFireballs_Time_SpawnMissiles = 10;
    const DanmakuFireballs_Time_ChangeFrame = DanmakuFireballs_Time_LaunchMissiles - 2;
    const DanmakuFireballs_Time_Warn = 44;
    const DanmakuFireballs_Time_LaunchMissiles = 45;
    const DanmakuFireballs_Time_End = 65;

    const DanmakuFireballs_FireballCount = 6;
    const DanmakuFireballs_Tetragram_Steps = 16;
    const DanmakuFireballs_Tetragram_Dist = 96.;

    int attackDanmakuFireballs_Time;
    Array<S7_Empress_DanmakuFireball> attackDanmakuFireballs_Fireballs;
    action state DanmakuFireballs_DoAttack () {
        int time = invoker.attackDanmakuFireballs_Time;

        if (time >= DanmakuFireballs_Time_CreateTetragram) {
            int tetragramTime = time - DanmakuFireballs_Time_CreateTetragram;

            int fireSteps = clamp (
                int (DanmakuFireballs_Tetragram_Steps * (double (tetragramTime) / 17)),
                0, DanmakuFireballs_Tetragram_Steps
            );

            int initialStep = clamp ((time - (DanmakuFireballs_Time_LaunchMissiles - 5)) * 2, 0, DanmakuFireballs_Tetragram_Steps);

            for (int k = 0; k < 2; k++) {
                for (int i = 0; i < 4; i++) {
                    double angLeaf = 90 * i;
                    double angSpin = tetragramTime * 2. % 360;

                    for (int j = initialStep; j < fireSteps; j++) {
                        double angStep = (45. / DanmakuFireballs_Tetragram_Steps) * j;
                        double xOffs = (DanmakuFireballs_Tetragram_Dist / DanmakuFireballs_Tetragram_Steps) * (DanmakuFireballs_Tetragram_Steps - j);

                        if (k == 0)
                            angStep =  angStep;
                        else
                            angStep = -angStep;

                        Vector2 spawnPos = (
                            (xOffs * cos (angLeaf + angSpin + angStep + angle)),
                            (xOffs * sin (angLeaf + angSpin + angStep + angle))
                        );

                        bool success; Actor act;
                        [success, act] = A_SpawnItemEx ("S7_Empress_DanmakuFireballsFire",
                            spawnPos.X, spawnPos.Y, 95.,
                            0., 0., fRandom [S7_ProjSFXRNG] (0., 5.),
                            flags: SXF_NoCheckPosition | SXF_Clientside | SXF_AbsoluteAngle | SXF_AbsolutePosition
                        );

                        if (success && act) {
                            Vector2 prevPos = (
                                (xOffs * cos (angLeaf + angSpin - 2 + angStep + angle)),
                                (xOffs * sin (angLeaf + angSpin - 2 + angStep + angle))
                            );

                            act.Prev = (pos.XY + prevPos, act.pos.Z);
                        }
                    }
                }
            }
        }

        if (time >= DanmakuFireballs_Time_ChangeFrame)
            frame++;

        if (time == 0)
            A_StartSound ("Monsters/Empress/DanmakuFireballsStart", slot: CHAN_Body, attenuation: 0.5);
        else if (time == DanmakuFireballs_Time_SpawnMissiles) {
            A_StartSound ("Monsters/Empress/DanmakuFireballsLoop", slot: CHAN_5, attenuation: 0.5);
            invoker.attackDanmakuFireballs_Fireballs.Clear ();

            for (int i = 0; i < DanmakuFireballs_FireballCount; i++) {
                let proj = S7_Empress_DanmakuFireball (A_SpawnProjectile ("S7_Empress_DanmakuFireball", flags: CMF_AimDirection));

                if (proj) {
                    invoker.attackDanmakuFireballs_Fireballs.Push (proj);

                    proj.tracer = target;
                    proj.phaseToTarg = (360. / DanmakuFireballs_FireballCount) * i;
                    proj.bonusDMGFactor = invoker.GetDamageBonus ();
                }
            }
        } else if (time == DanmakuFireballs_Time_Warn)
            A_StartSound ("Monsters/Empress/DanmakuFireballsEnd", slot: CHAN_6, attenuation: ATTN_None);
        else if (time == DanmakuFireballs_Time_LaunchMissiles) {
            for (int i = 0; i < invoker.attackDanmakuFireballs_Fireballs.Size (); i++) {
                let proj = invoker.attackDanmakuFireballs_Fireballs [i];

                if (proj)
                    proj.doLaunch = true;
            }

            invoker.attackDanmakuFireballs_Fireballs.Clear ();
        } else if (time == DanmakuFireballs_Time_End)
            return ResolveState ("See");

        invoker.attackDanmakuFireballs_Time++;

        return ResolveState (null);
    }

    states {
    Attack.DanmakuFireballs:
        HRFR AAAAAA 1 A_FaceTarget (60, 30);
        TNT1 A 0 { attackDanmakuFireballs_Time = 0; }
        HRFR I 1 DanmakuFireballs_DoAttack ();
        wait;
    }
}

class S7_Empress_DanmakuFireballsFire : S7_FireBase {
    default {
        Alpha 1.;
        Scale .15;

        +NOINTERACTION +CLIENTSIDEONLY
    }

    states {
    Spawn:
        FIR1 ACE 1 bright;
        FIR1 H  1 bright A_Jump (128, "Null");
        stop;
    }
}

class S7_Empress_DanmakuFireball : S7_Projectile {
    default {
        Radius 20;
        Height 20;

        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.EffectStepMul .125 * 2;
        S7_Projectile.InterpMove false;

        Speed 25;
        DamageFunction (((35. / S7_Empress.DanmakuFireballs_FireballCount) + fRandom [monsterDMG] (-2., 2.)) * (1. + bonusDMGFactor));

        MissileType 'S7_EmpressMissile1Trail';
        MissileHeight 8;
        RenderStyle "add";

        DeathSound "Misc/Common/FireballHit";
        Obituary "$OB_EMPRESSFB";
        Species 'S7EmpressCrap';

        +FORCEXYBILLBOARD +THRUSPECIES
    }

    double phaseToTarg, targAngle;
    bool doLaunch;
    double launchAngle, launchPitch;

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        bMissile = false;
        vel = (0, 0, 0);
    }

    override Actor StepEffects (Vector3 initialPos, Vector3 stepDiff, Vector3 realVel) {
        Actor act = Super.StepEffects (initialPos, stepDiff, realVel);

        if (act) {
            let newPos = act.Vec3Offset (fRandom [S7_ProjSFXRNG] (-2.5, 2.5), fRandom [S7_ProjSFXRNG] (-2.5, 2.5), fRandom [S7_ProjSFXRNG] (-3, 3));
            S7_ActorExtensions.SetActorPosition (act, newPos);
            act.ClearInterpolation ();
            act.vel = (0., 0, fRandom [S7_ProjSFXRNG] (.5, 3.));
        }

        return act;
    }

    states {
    Spawn:
        TNT1 A 1 bright {
            let empress = S7_Empress (target);
            if (CheckInventory ('S7_IsDead', 1, AAPTR_Target) || !target)
                return ResolveState ("DieOut");
            if (empress.attackDanmakuFireballs_Time < S7_Empress.DanmakuFireballs_Time_SpawnMissiles)
                return ResolveState ("DieOut");
            if (doLaunch)
                return ResolveState ("Flight");

            if (GetAge () >= 1) {
                invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));
                invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));
            }

            if (self && !bDestroyed && tracer) {
                double spinSpeed = clamp (S7_Empress.DanmakuFireballs_Time_ChangeFrame - empress.attackDanmakuFireballs_Time, 0, 5);
                phaseToTarg += spinSpeed;

                Warp (tracer,
                    tracer.radius + 128., 0, tracer.height * .35,
                    angle: phaseToTarg,
                    flags: WARPF_NoCheckPosition | WARPF_Interpolate
                );

                Vector3 targPos = tracer.Vec3Offset (0., 0., tracer.height * .25);
                bool canIntercept;
                Vector3 interceptPos;

                [canIntercept, interceptPos] = S7_Math.CalculateInterceptShotPosition (level,
                    pos, tracer.pos,
                    tracer.vel, Speed
                );
                if (canIntercept)
                    targPos = interceptPos;

                [launchAngle, launchPitch] = S7_Math.GetAnglesTo (level, pos, targPos);
            }
            if (GetAge () < 1) {
                ClearInterpolation ();

                invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));
                invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));
            }

            return ResolveState (null);
        }
        loop;

    Flight:
        TNT1 A 0 {
            bMissile = true; // Make it a projectile again

            Vel3DFromAngle (Speed, launchAngle, launchPitch);
        }
        TNT1 A 1 bright;
        wait;

    DieOut:
        TNT1 A 0 A_Die;
    Death:
        CP00 DEFGH 2 bright;
        stop;
    }
}
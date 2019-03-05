/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
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
    bool midAttack_Fireball;

    states {
    Attack.Fireball:
        TNT1 A    0 { midAttack_Fireball = true; }
        HRFR AAA  1 A_FaceTarget (19, 9.5);
        HRFR HHHH 2 bright A_FaceTarget (19, 9.5);
        HRFR HHHH 2 bright A_FaceTarget (19, 9.5);

        HRFR H    1 {
            A_FaceTarget (0, 0);

            let proj = S7_EmpressMissile1 (A_SpawnProjectile ('S7_EmpressMissile1', 105.));
            if (proj)
                proj.bonusDMGFactor = GetDamageBonus ();
        }
        HRFR HHHH 1 A_FaceTarget (90, 45);

        HRFR H    1 {
            A_FaceTarget (0, 0);

            let proj = S7_EmpressMissile1 (A_SpawnProjectile ('S7_EmpressMissile1', 105.));
            if (proj)
                proj.bonusDMGFactor = GetDamageBonus ();
        }
        HRFR HHHH 1 A_FaceTarget (90, 45);

        HRFR H    1 {
            A_FaceTarget (0, 0);

            let proj = S7_EmpressMissile1 (A_SpawnProjectile ('S7_EmpressMissile1', 105.));
            if (proj)
                proj.bonusDMGFactor = GetDamageBonus ();
        }
        HRFR HHHH 1 A_FaceTarget (90, 45);
        TNT1 A 0 A_PlaySound ("Misc/Common/Fireball2", attenuation: 0.5);
        HRFR HHHH 5;
        goto See;
    }
}

class S7_EmpressMissile1 : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.EffectStepMul .125 * 2;
        S7_Projectile.InterpMove false;

        Speed 45;
        DamageFunction ((21. + fRandom [monsterDMG] (-3., 3.)) * (1. + bonusDMGFactor));

        MissileType 'S7_EmpressMissile1Trail';
        MissileHeight 8;
        RenderStyle "add";
        DeathSound "Misc/Common/FireballHit";
        Obituary "$OB_EMPRESSFB";
        Species 'S7EmpressCrap';

        +FORCEXYBILLBOARD +SEEKERMISSILE +THRUSPECIES
    }

    double rotAngle;
    double loopCount;
    Vector3 savedVel;

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        bMissile = false; // remove the MISSILE flag so the Draco's defense system won't target it
        rotAngle = angle;
        loopCount = 15;
        savedVel = vel;
        vel = (0, 0, 0);
    }

    override Actor StepEffects (Vector3 initialPos, Vector3 stepDiff, Vector3 realVel) {
        Actor act = Super.StepEffects (initialPos, stepDiff, realVel);

        if (act) {
            act.SetOrigin (act.Vec3Offset (fRandom [S7_ProjSFXRNG] (-2.5, 2.5), fRandom [S7_ProjSFXRNG] (-2.5, 2.5), fRandom [S7_ProjSFXRNG] (-3, 3)), false);
            act.vel = (0., 0, fRandom [S7_ProjSFXRNG] (.5, 3.));
        }

        return act;
    }

    states {
    Spawn:
        TNT1 A 1 bright {
            if (CheckInventory ('S7_IsDead', 1, AAPTR_Target) || !(target is 'S7_Empress') || !(S7_Empress (target)).midAttack_Fireball)
                return ResolveState ("DieOut");
            if (loopCount < 1)
                return ResolveState ("Flight");

            invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));
            invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));

            if (self && target)
                Warp (target, 25., 0, 105., rotAngle, WARPF_AbsoluteAngle | WARPF_NoCheckPosition | WARPF_Interpolate);
            rotAngle += 24;
            loopCount--;

            return ResolveState (null);
        }
        loop;

    Flight:
        TNT1 A 1 bright {
            if (self && target)
                Warp (target, 25., 0, 105., 360, WARPF_AbsoluteAngle | WARPF_NoCheckPosition | WARPF_Interpolate);
        }
        TNT1 A 0 {
            bMissile = true; // Make it a projectile again
            vel = savedVel; // Restore the projectile's velocity
            A_FaceTracer (0, 0); // Face the target
            A_SeekerMissile (1, 360, SMF_Precise | SMF_CurSpeed); // Make sure our direction gets adjusted
            A_SeekerMissile (1, 360, SMF_Precise | SMF_CurSpeed);
        }
        TNT1 AAAAA 2 bright A_SeekerMissile (6, 6, SMF_Precise | SMF_CurSpeed);
        TNT1 A 2 bright;
        wait;

    DieOut:
        TNT1 A 0 A_Die;
    Death:
        CP00 DEFGH 2 bright;
        stop;
    }
}

class S7_EmpressMissile1Trail : S7_FireBase {
    default {
        Alpha 1.;
        Scale .25;

        +NOINTERACTION +CLIENTSIDEONLY
    }

    states {
    Spawn:
        FIR1 ACEHJ 1 bright;
        stop;
    }
}
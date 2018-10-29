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

//-------------------------------------------------------------------------------------------
//
// Shrapnel
//
//-------------------------------------------------------------------------------------------
class S7_Shrapnel : S7_Projectile { // By Chronos "phantombeta" Ouroboros. (Heavily) Based on Hideous Destructor's shrapnel actor
    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.FastProjCollision ColMode_Center;
        S7_Projectile.EffectStepMul 0.0625;

        Radius 1;
        Height 1;
        Scale .5;
        Speed 1;
        Mass 0;

        //MissileType 'S7_ShrapnelSmoke';
        MissileHeight 8;

        DamageFunction (0);
        DamageType 'Shrapnel';
        Obituary "$OB_SHRAPNEL";

        +FORCEXYBILLBOARD +NOEXTREMEDEATH +BLOODSPLATTER +NODAMAGETHRUST
        +CANNOTPUSH
    }

    int minVel, maxVel;
    double keScale;
    double realDamage;

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        A_RearrangePointers (AAPTR_Null, AAPTR_Target, AAPTR_Default);

        if (mass == 0) mass = random [shrapnel] (25, 50);
        if (minVel == 0) minVel = 150;
        if (maxVel == 0) maxVel = 200;
        if (keScale == 0) keScale = 100;
        if (keScale < 0)
            keScale = abs (keScale);

        if (pos.z - floorZ >= 0 && pos.z - floorZ < 8)
            pitch = fRandom [shrapnel] (0, 90);
        else if (ceilingZ - pos.z >= 0 && ceilingZ - pos.z < 8)
            pitch = fRandom [shrapnel] (-90, 0);
        else
            pitch = fRandom [shrapnel] (-90, 90);

        double newVel = fRandom [shrapnel] (minVel, maxVel);
        A_ChangeVelocity (Cos (pitch) * newVel, 0.0, Sin (pitch) * newVel, CVF_Relative);
    }

    override void Tick () {
        if (bMissile) {// KE = (mv^2) / 2
            double velMS = (vel.Length () * 35.) / 32.;
            double massKG = mass / 1000.;
            double KE = (massKG * (velMS**2)) / 2.;

            realDamage = KE / keScale;
        }

        Super.Tick ();
    }

    states {
    Spawn:
        TNT1 A 0 {
            int state = random [shrapnel] (1, 4);
            if (state == 2)
                return ResolveState ("SpawnB");
            else if (state == 3)
                return ResolveState ("SpawnC");
            else if (state == 4)
                return ResolveState ("SpawnD");

            return ResolveState ("SpawnA");
        }
    SpawnA:
        FRG2 A 0;
        goto Flight;
    SpawnB:
        FRG2 B 0;
        goto Flight;
    SpawnC:
        FRG2 C 0;
        goto Flight;
    SpawnD:
        FRG2 D 0;
        goto Flight;
    Flight:
        #### #   1 {
            //A_SpawnItemEx ('S7_ShrapnelSmoke');
            A_ChangeVelocity (0, 0, -1);
        }
        #### ### 1 {
            A_ChangeVelocity (vel.X * 0.9, vel.Y * 0.9, vel.Z - 1, CVF_Replace);
            //A_SpawnItemEx ('S7_ShrapnelSmoke');
        }
    FlightActual:
        #### ## 1 {
            A_ChangeVelocity (vel.X * 0.9 + fRandom [shrapnel] (-1, 1), vel.Y * 0.9 + fRandom [shrapnel] (-1, 1), vel.Z - 1, CVF_Replace);
            //A_SpawnItemEx ('S7_ShrapnelSmoke');
        }
        //#### #  0 { realDamage *= 0.9; }
        loop;

    Death:
        #### # 1 {
            A_RearrangePointers (AAPTR_Master, AAPTR_Null, AAPTR_Default);
            A_Explode (int (realDamage), 2, XF_HURTSOURCE, false, 2);
        }
        stop;
    }
}
/*
Properties:
    No direct damage
    +cannotpush flag?

Actions:
    Init {
        mass = 100~400;
        pitch = -90.0~90.0; // Ignore this so we can make the spawner set the pitch range
        velocity = x: Cos (pitch) * mass, y: 0, z: Sin (pitch) * mass;
        damage = sqrt (sqrt (vel.X*vel.X + vel.Y*vel.Y) + (vel.Z*vel.Z)) >> 4;
    }
    FlightStart {
        (1, 1x) velocity = z: -= 1;
        (1, 3x) velocity = xy: *= 0.9, z: -= 1;
    }
    FlightActual {
        (1, 2x) velocity = xy: *= 0.9 + -1.0~1.0, z: -= 1;
        (0, 1x) damage *= 0.9
    }
    Death {
        if damage <= 0:
            (0, 1x) damage = 3~14;
        (0, 1x) RadiusDamage: radius = 4, damage = damage, maxDMGRadius = 4;
    }
*/

class S7_ShrapnelSmoke : S7_ShotSmokeTrail {
    default {
        Scale 0.06;
        Alpha 0.5;
    }

    states {
    Spawn:
        SMOK DEFGHIJKLMNOPQ 1;
        stop;
    }
}

extend class S7_ActorExtensions {
    static void A_S7SpawnShrapnel (
        Actor spawner, int count,
        int minVel = 150, int maxVel = 200, int minMass = 25, int maxMass = 50, double keScale = 100,
        double xOff = 0, double yOff = 0, double zOff = 0,
        int flags = 0
    ) {
        int sieFlags = (flags & (SXF_TransferPointers | SXF_SetMaster | SXF_SetTracer | SXF_SetTarget));
        for (int i = 0; i < count; i++) {
            bool spawned; Actor act;
            [spawned, act] = spawner.A_SpawnItemEx ('S7_Shrapnel', xOff + fRandom [shrapnelSpawn] (-2.0, 2.0), yOff + fRandom [shrapnelSpawn] (-2.0, 2.0), zOff, 0.0, 0.0, 0.0, fRandom [shrapnelSpawn] (0.0, 359.0), SXF_NoCheckPosition | sieFlags);

            if (!spawned || !act)
                continue;

            let shrapnelAct = S7_Shrapnel (act);
            if (!shrapnelAct)
                continue;

            shrapnelAct.mass = random [shrapnelSpawn] (minMass, maxMass);
            shrapnelAct.minVel = minVel;
            shrapnelAct.maxVel = maxVel;
            shrapnelAct.keScale = keScale;
        }
    }
}
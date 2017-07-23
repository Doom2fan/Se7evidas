//-------------------------------------------------------------------------------------------
//
// Shrapnel
//
//-------------------------------------------------------------------------------------------
class S7_Shrapnel : fastProjectile { // By Chronos "phantombeta" Ouroboros. (Heavily) Based on Hideous Destructor's shrapnel actor
    default {
        radius 1;
        height 1;
        speed 1;
        scale .5;
        damageFunction (0);
        damageType "Shrapnel";
        obituary "$OB_SHRAPNEL";

        +cannotPush +noExtremeDeath +bloodSplatter +noDamageThrust
        +forceXYBillboard
    }

    float realDamage;

    states {
    Spawn:
        TNT1 A 0;
        TNT1 A 0 {
            A_RearrangePointers (AAPTR_Null, AAPTR_Target, AAPTR_Default);
            mass = random [shrapnel] (100, 400);
            if (pos.z - floorZ >= 0 && pos.z - floorZ < 8)
                pitch = fRandom [shrapnel] (0, 90);
            else if (ceilingZ - pos.z >= 0 && ceilingZ - pos.z < 8)
                pitch = fRandom [shrapnel] (-90, 0);
            else
                pitch = fRandom [shrapnel] (-90, 90);
        }
        goto Spawn.Rest;
    Spawn.Rest:
        TNT1 A 0 {
            A_ChangeVelocity (Cos (pitch) * mass, 0.0, Sin (pitch) * mass, CVF_Relative);
            realDamage = sqrt (sqrt (vel.X*vel.X + vel.Y*vel.Y) + vel.Z*vel.Z);

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
            A_SpawnItemEx ("S7_ShrapnelSmoke");
            A_ChangeVelocity (0, 0, -1);
        }
        #### ### 1 {
            A_ChangeVelocity (vel.X * 0.9, vel.Y * 0.9, vel.Z - 1, CVF_Replace);
            A_SpawnItemEx ("S7_ShrapnelSmoke");
        }
    FlightActual:
        #### ## 1 {
            A_ChangeVelocity (vel.X * 0.9 + fRandom [shrapnel] (-1, 1), vel.Y * 0.9 + fRandom [shrapnel] (-1, 1), vel.Z - 1, CVF_Replace);
            A_SpawnItemEx ("S7_ShrapnelSmoke");
        }
        #### #  0 { realDamage *= 0.9; }
        loop;

    Death:
        #### # 0 {
            A_RearrangePointers (AAPTR_Master, AAPTR_Null, AAPTR_Default);
            if (realDamage < 0)
                realDamage = random [shrapnel] (3, 14);
        }
        #### # 1 A_Explode (realDamage, 5, XF_HURTSOURCE, false, 5);
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
        scale 0.06;
        alpha 0.5;
    }

    states {
    Spawn:
        SMOK DEFGHIJKLMNOPQ 1;
        stop;
    }
}

extend class S7_ActorExtensions {
    static void A_S7SpawnShrapnel (Actor spawner, int count, double xOff = 0, double yOff = 0, double zOff = 0, int flags = 0) {
        int sieFlags = (flags & (SXF_TransferPointers | SXF_SetMaster | SXF_SetTracer | SXF_SetTarget));
        for (int i = 0; i < count; i++)
            spawner.A_SpawnItemEx ("S7_Shrapnel", xOff + fRandom [shrapnel] (-2.0, 2.0), yOff + fRandom [shrapnel] (-2.0, 2.0), zOff, 0.0, 0.0, 0.0, fRandom [shrapnel] (0.0, 359.0), SXF_NoCheckPosition | sieFlags);
    }
}
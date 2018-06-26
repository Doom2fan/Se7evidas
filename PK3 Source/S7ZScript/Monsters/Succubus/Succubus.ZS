//-------------------------------------------------------------------------------------------
//
// Succubus
//
//-------------------------------------------------------------------------------------------
class S7_Succubus : S7_SuccubusBase {
    default {
        Health 350;
        Speed 8;
        PainChance 90;
        SeeSound "Succubus/Sight";
        ActiveSound "Succubus/Active";
        PainSound "Succubus/Pain";
        DeathSound "Succubus/Death";
        Obituary "$OBSUCCUBUS";
        Species "Succubus";
        Tag "$SUCCUBUSTAG";
    }

    bool isFlying;

    void ChangeFlying (bool set) {
        bNoGravity = set;
        bDropOff = set;
        bFloat = set;
        isFlying = set;
    }

    override void Tick () {
        if (health > 0 && !bKilled) {
            if (target && CheckIfTargetInLOS (90.0, JLOSF_DeadNoJump | JLOSF_CombatantOnly | JLOSF_AllyNoJump, 4800.0) && abs (pos.z - target.pos.z) > 96.0)
                ChangeFlying (true);
            else if (pos.z <= floorZ)
                ChangeFlying (false);
            else
                ChangeFlying (true);
        }

        Super.Tick ();
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            if (pos.z - floorZ > 0)
                ChangeFlying (true);
        }
    Idle:
        SUCC A 10 A_Look;
        loop;

    IdleFlying:
        SUCF ABCB 3 A_Look;
        loop;
    See:
        SUCC AABBCCDD 4 {
            if (isFlying)
                return ResolveState ("StartFlight");

            A_Chase ();

            return ResolveState (null);
        }
        loop;

    SeeFlying:
        SUCF AABBCCBB 2 {
            if (isFlying)
                return ResolveState ("EndFlight");

            A_Chase ();

            return ResolveState (null);
        }
        loop;

    StartFlight:
        SUCF A   3 {
            ChangeFlying (true);
            vel.z += 3.0;
        }
        SUCF BCB 3;
        goto SeeFlying;

    EndFlight:
        SUCF ABCB 3 {
            if (pos.z <= floorZ) {
                ChangeFlying (false);
                return ResolveState ("See");
            }
            vel.z = -3;

            return ResolveState (null);
        }
        loop;

    Missile:
        SUCC AAAEEE 1 A_FaceTarget (60, 30);

        SUCC F 3 {
            A_FaceTarget (0, 0);
            A_SpawnProjectile ("S7_HellionBall", 45.0, 0, 0.0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
        }
        SUCC G 4;
        goto See;

    Pain:
        SUCC H 2;
        SUCC H 2 A_Pain;
        goto See;

    Death:
        SUCC I 3 { monsDeathType = 0; }
        SUCC J 3 A_Scream;
        SUCC K 3;
        SUCC L 3 A_NoBlocking;
    Death_AirLoop:
        SUCC L 1 A_CheckFloor ("Death_HitGround");
        loop;
    Death_HitGround:
        SUCC MNOP 3;
        SUCC Q   -1;
        stop;

    Death.Fire:
        TNT1 A 0 A_JumpIfHealthLower (-15, "RealDeath.Fire");
        goto Death;
    Death.Fire2:
    RealDeath.Fire:
        BURN ABC        5 bright A_Pain;
        BURN D          5 bright A_Pain;
        TNT1 A          0 A_NoBlocking;
        BURN EFGHIJKLMN 5 bright;
        BURN O          5 bright;
        BURN PQRSTU     5 bright;
        BURN V          1;
        wait;

    Raise:
        SUCC Q        6;
        SUCC PONMLKJI 6;
        goto See;
    }
}
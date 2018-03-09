//-------------------------------------------------------------------------------------------
//
// Black Panther
//
//-------------------------------------------------------------------------------------------
class S7_BlackPanther : S7_HellNobleBase {
    default {
        Health 750;
        Speed 8;
        PainChance 50;
        BloodColor "00 67 67";
        SeeSound "BlackPanther/Sight";
        ActiveSound "BlackPanther/Active";
        PainSound "BlackPanther/Pain";
        DeathSound "knight/death";
        HitObituary "$OBBPANTHER_MELEE";
        Species "HellNoble";
        Tag "$BLCKPNTTAG";

        // (Mini-)Boss damage reduction
        DamageFactor "ExplosionSplashDMG", 0.75;
        DamageFactor "Shrapnel", 0.85;
    }

    states {
    Spawn:
        BPNT A 10 A_Look;
        loop;
    See:
        BPNT AABBCCDD 2 A_Chase;
        loop;
    Melee:
    Missile:
        BPNT EEEEEEFFFFFF 1 A_FaceTarget (30, 15);

        BPNT G 6 {
            A_FaceTarget (0, 0);
            A_CustomComboAttack ("S7_BlackPantherBall", 32, fRandom [monsterDMG] (1.0, 4.0) * 8, "baron/melee");
        }
        goto See;
    Pain:
        BPNT H 2;
        BPNT H 2 A_Pain;
        goto See;
    Death:
        BPNT I 5;
        BPNT J 5 {
            A_Scream ();
            A_NoBlocking ();
        }
    Death_AirLoop:
        BPNT J 1 A_CheckFloor ("Death_HitGround");
        loop;
    Death_HitGround:
        BPNT KLMN 5;
        BPNT O   -1;
        stop;
    Raise:
        BPNT O      5;
        BPNT NMLKJI 5;
        goto See;
    }
}

//-------------------------------------------------------------------------------------------
//
// Black Panther ball
//
//-------------------------------------------------------------------------------------------
class S7_BlackPantherBall : S7_FireballBase {
    default {
        DamageFunction (fRandom [monsterDMG] (1.0, 4.0) * 16);
        Speed 18;
        Obituary "$OBBPANTHER";
    }

    states {
    Spawn:
        PNTB AB 2;
        loop;
    Death:
        TNT1 A      0 A_Explode (16, 16, 0);
        PNTB CDEFGH 2;
        stop;
    }
}
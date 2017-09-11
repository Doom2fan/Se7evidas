//-------------------------------------------------------------------------------------------
//
// Empress' invulnerability orbiter
//
//-------------------------------------------------------------------------------------------
const S7_EmpressOrbiterWarpFlags = WARPF_NoCheckPosition | WARPF_Interpolate;
class S7_EmpressInvulnOrbiterCW : Actor {
    double rotAmount;
    property rotAmount: rotAmount;
    bool useCos;
    property useCos: useCos;

    default {
        health 100;
        radius 20;
        height 20;
        renderStyle "add";
        damageFactor "EmpressDeath", 1.0;
        damageFactor "NerveGas", 0.0;
        species "S7EmpressCrap";
        scale 0.1;
        alpha 1.0;

        S7_EmpressInvulnOrbiterCW.rotAmount 10.0;
        S7_EmpressInvulnOrbiterCW.useCos false;

        +shootable +noTeleport +noBlood +noTargetSwitch
        +noGravity +forceXYBillboard +forcePain +foilInvul
        +thruSpecies
    }

    double rotAngle;
    int countdown;
    S7_Empress owner;

    void OrbitMaster () {
        for (int i = 0; i < 4; i++) {
            A_SpawnItemEx ("S7_EmpressShieldSparkle", fRandom (-0.5, 0.5), fRandom (-0.5, 0.5), fRandom (-0.5, 0.5),
                fRandom (-3.0, 3.0), fRandom (-3.0, 3.0), fRandom (-1.0, 1.0), 0, SXF_Clientside | SXF_NoCheckPosition);
        }
        A_SpawnItemEx ("S7_EmpressShieldFlare", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);

        A_Warp (AAPTR_Master, 64.0, 0.0, 50.0 + 40 * (useCos ? cos (40 + rotAngle) : sin (40 + rotAngle)), rotAngle, S7_EmpressOrbiterWarpFlags);
    }

    void WasDestroyed () {
        if (!owner)
            return;

        owner.ballsCount--; // Ouch.
        if (!owner.ballsCount) {
            owner.bNoBlood = false;
            owner.bNoPain = false;
            owner.bInvulnerable = false;
        }
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            A_RearrangePointers (AAPTR_Master, AAPTR_Default, AAPTR_Master);

            if (!master || master.health < 1 || !(master is "S7_Empress"))
                Destroy ();

            owner = S7_Empress (master);

            rotAngle = 270;
            countdown = 35 * 12;

            owner.ballsCount++;
        }
        goto Idle;

    Idle:
        HRSF A 1 bright {
            OrbitMaster ();

            if (!CheckInventory ("S7_Empress_CastingInvuln", 1, AAPTR_Master))
                countdown--;

            rotAngle += rotAmount;

            if (countdown < 1) {
                A_Die ("NonKilledDeath");
                return ResolveState ("Death.NonKilledDeath");
            }

            return ResolveState (null);
        }
        loop;

    Death:
        TNT1 A 1 {
            WasDestroyed ();
            A_DamageMaster (random [miscDamage] (1, 8) * 8, "Empress_BallExploded", DMSS_FoilInvul); // That's gotta hurt.
        }
        // Explosion here
        stop;
    Death.NonKilledDeath:
        HRSF A 1 {
            OrbitMaster ();

            rotAngle += rotAmount;

            A_FadeOut (0.03, 0);

            return (alpha <= 0) ? ResolveState ("KILLKILLKILL") : ResolveState (null);
        }
        loop;
    Death.EmpressDeath:
        HRSF A 1 bright {
            A_Stop ();
            A_FadeOut (0.03, 0);
            return (alpha <= 0) ? ResolveState ("KILLKILLKILL") : ResolveState (null);
        }
        loop;
    KILLKILLKILL:
        TNT1 A 1 WasDestroyed ();
        stop;
    }
}

class S7_EmpressInvulnOrbiterCCW : S7_EmpressInvulnOrbiterCW {
    default {
        S7_EmpressInvulnOrbiterCW.rotAmount -10.0;
        S7_EmpressInvulnOrbiterCW.useCos true;
    }
}
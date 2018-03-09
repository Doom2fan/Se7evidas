class S7_Empress_FXBase : S7_EffectsBase {
    default {
        RenderStyle "add";

        +NOTELEPORT +NOINTERACTION  +NOBLOCKMAP +NOGRAVITY
        +THRUACTORS +CLIENTSIDEONLY
    }
}

//-------------------------------------------------------------------------------------------
//
// Spawner
//
//-------------------------------------------------------------------------------------------
/** Smoke **/
class S7_EmpressSmoke : S7_ShotSmoke_2 {
    default {
        RenderStyle "subtract";
        Alpha 0.6;
        Scale 0.8;

        +NOINTERACTION +FORCEXYBILLBOARD +CLIENTSIDEONLY
    }

    states {
    Spawn:
        ESPS ABCDEFGHIJKLMNOPQRSTUVW 1;
        stop;
    }
}

/** Sparkle **/
class S7_EmpressSparkle : S7_Empress_FXBase {
    default {
        RenderStyle "add";

        +FORCEXYBILLBOARD
    }

    int loopCount;

    states {
    Spawn:
        TNT1 A 0 noDelay {
            A_SetScale (fRandom [sfx] (0.25, 0.4));
            loopCount = random [sfx] (8, 14);
            return A_Jump (256, "SpawnA", "SpawnB", "SpawnC", "SpawnD", "SpawnE", "SpawnF", "SpawnG", "SpawnH");
        }

    SpawnA: HRSS A 0; goto FadeOut;
    SpawnB: HRSS B 0; goto FadeOut;
    SpawnC: HRSS C 0; goto FadeOut;
    SpawnD: HRSS D 0; goto FadeOut;
    SpawnE: HRSS E 0; goto FadeOut;
    SpawnF: HRSS F 0; goto FadeOut;
    SpawnG: HRSS G 0; goto FadeOut;
    SpawnH: HRSS H 0; goto FadeOut;

    FadeOut:
        "----" A 1 bright {
            return (loopCount-- < 1) ? ResolveState ("ReallyFadeOutNow") : ResolveState (null);
        }
        loop;
    ReallyFadeOutNow:
        "----" A 1 bright A_FadeOut (0.1);
        wait;
    }
}

/** Pentagram **/
// Corner
class S7_EmpressPentagramCorner : S7_Empress_FXBase {
    states {
    Spawn:
        TNT1 A 0 noDelay {
            A_SpawnProjectile ("S7_EmpressPentagramLine", 0.0, 0, -198, CMF_AimDirection);
            A_SpawnProjectile ("S7_EmpressPentagramLine", 0.0, 0,  198, CMF_AimDirection);
        }
        stop;
    }
}

// Line
class S7_EmpressPentagramLine : S7_Empress_FXBase {
    default {
        Radius 1;
        Height 1;
        DamageFunction (0);
        Speed 18;

        Projectile;

        +NOTARGET +NOBLOOD +NOCLIP +THRUACTORS
        +PAINLESS +RIPPER  +BLOODLESSIMPACT
    }

    states {
    Spawn:
        TNT1 AAAAAAAAAA 1 A_SpawnItemEx ("S7_EmpressPentagramFire", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
        stop;
    }
}

// Fire
class S7_EmpressPentagramFire : S7_Empress_FXBase {
    default {
        Radius 1;
        Height 1;
        ReactionTime 4;
    }

    states {
    Spawn:
        EPTF ABCDEFGHIJKLM 3 bright;
        TNT1 A             0 A_Countdown;
        loop;

    Death:
        EPTF NOP 3 bright;
        stop;
    }
}



//-------------------------------------------------------------------------------------------
//
// Invuln orbiters
//
//-------------------------------------------------------------------------------------------
class S7_EmpressShieldSparkle : S7_EmpressSparkle {
    default {
        Scale 0.2;
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            loopCount = 2;
            return A_Jump (256, "SpawnA", "SpawnB", "SpawnC", "SpawnD", "SpawnE", "SpawnF", "SpawnG", "SpawnH");
        }
    ReallyFadeOutNow:
        "----" A 1 bright A_FadeOut (0.15);
        wait;
    }
}
class S7_EmpressShieldFlare : S7_Empress_FXBase {
    default {
        Scale 0.1;
        Alpha 0.5;

        +FORCEXYBILLBOARD
    }

    states {
    Spawn:
        HRSF A 3 bright;
        HRSF A 1 bright A_FadeOut (0.03);
        wait;
    }
}
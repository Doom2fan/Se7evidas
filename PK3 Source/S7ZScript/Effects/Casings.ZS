/* Based on Zombie Torrent's casings code (I don't know who made the code for those casings)
** Casing sprites by Captain J. Edited by Chronos "phantombeta" Ouroboros
** Usage:
**  Weapons:  A_FireCustomMissile ("<Casing spawner actor>", 0, 0, <int xPos>, <float yPos>)
**  Monsters: A_SpawnProjectile ("<Casing spawner actor>", <float yPos/zPos>, <int xPos>, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0)
*/

class S7_CasingSmoke : S7_ShotSmokeTrail {
    default {
        scale 0.05;
        alpha 0.35;
    }

    states {
    Spawn:
        SMOK GHIJKLMNOPQ 1;
        stop;
    }
}

class S7_CasingSpawnerBase : actor {
    default {
        speed 20;
        projectile;

        +noClip
    }
}

class S7_CasingBase : actor {
    default {
        height 2;
        radius 2;
        speed 6;
        bounceType "doom";

        +windThrust +clientsideOnly +ghost +canBounceWater
        +moveWithSector +missile +noBlockmap +noTeleport
        +forceXYBillboard
        -dropOff -noGravity
    }

    int user_Timer;
    int user_StayTime;

    states {
    Delaying:
        #### # 0 {
            if (user_Timer % 5 == 0) // Only update user_StayTime every 5 tics. This way it's less performance intensive.
                user_StayTime = callACS ("S7_GetEffectsStayTime");

            if ((user_StayTime == -2 && user_Timer >= 10000) ||
                 (user_StayTime == -1 && user_Timer >=  5000) ||
                 (user_StayTime ==  0 && user_Timer >=  2500) ||
                 (user_StayTime ==  1 && user_Timer >=  1250) ||
                 (user_StayTime ==  2 && user_Timer >=   625) ||
                 (user_StayTime ==  3 && user_Timer >=   313) ||
                 (user_StayTime ==  4 && user_Timer >=   157) ||
                 (user_StayTime ==  5 && user_Timer >=    70) ||
                 (user_StayTime ==  6 && user_Timer >=    35))
                return ResolveState ("Fade");

            return ResolveState (null);
        }
    Delaying.Derp:
        #### # 1 { user_Timer = user_Timer + 1; }
        goto Delaying;

    Fade:
    Fade.Looper:
        #### # 0 {
            int fadeSpeed = callACS ("S7_GetEffectsFadeSpeed");
            switch (fadeSpeed) {
                case 1: return ResolveState ("Fade.Faster"); break;
                case 2: return ResolveState ("Fade.EvenFaster"); break;
                case 3: return ResolveState ("Fade.Fasterer"); break;
                case 4: return ResolveState ("Fade.TheFlash"); break;
                case 5: return ResolveState ("Fade.DearLordGoBuyANewComputerRightMotherfuckingNow"); break;
            }
            return ResolveState (null);
        }
        goto Fade.Normal;

    Fade.Normal:
        #### # 3 A_FadeOut (0.03);
        goto Fade.Looper;
    Fade.Faster:
        #### # 3 A_FadeOut (0.06);
        goto Fade.Looper;
    Fade.EvenFaster:
        #### # 2 A_FadeOut (0.09);
        goto Fade.Looper;
    Fade.Fasterer:
        #### # 1 A_FadeOut (0.12);
        goto Fade.Looper;
    Fade.TheFlash:
        #### # 1 A_FadeOut (0.15);
        goto Fade.Looper;
    Fade.DearLordGoBuyANewComputerRightMotherfuckingNow:
        #### # 1 A_FadeOut (2.0);
        goto Fade.Looper;

    Rest1:
        #### A 0;
        #### # 0 A_Jump (256, "Delaying");
        wait;
    Rest2:
        #### B 0;
        #### # 0 A_Jump (256, "Delaying");
        wait;
    Rest3:
        #### C 0;
        #### # 0 A_Jump (256, "Delaying");
        wait;
    Rest4:
        #### D 0;
        #### # 0 A_Jump (256, "Delaying");
        wait;
    Rest5:
        #### E 0;
        #### # 0 A_Jump (256, "Delaying");
        wait;
    Rest6:
        #### F 0;
        #### # 0 A_Jump (256, "Delaying");
        wait;
    Rest7:
        #### G 0;
        #### # 0 A_Jump (256, "Delaying");
        wait;
    Rest8:
        #### H 0;
        #### # 0 A_Jump (256, "Delaying");
        wait;


    Death:
        #### # 0 A_Jump (256, "Rest1", "Rest3", "Rest5", "Rest7");
        goto Rest1;
    }
}

//-------------------------------------------------------------------------------------------
//
// 20ga Shotgun Shell
//
//-------------------------------------------------------------------------------------------
class S7_ShellCasingSpawn : S7_CasingSpawnerBase {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_ShellCasing", 0, 0, fRandom [sfx] (80, 100), 2, fRandom [sfx] (40, 60));
        stop;
    }
}

class S7_ShellCasing : S7_CasingBase {
    default {
        bounceSound "Weapons/Shell";
        scale .2;
    }

    states {
    Spawn:
        CAS0 ABCDEFGH 2; // A_SpawnItemEx ("S7_CasingSmoke")
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// 12ga Shotgun Shell
//
//-------------------------------------------------------------------------------------------
class S7_12gaShellCasingSpawn : S7_CasingSpawnerBase {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_12gaShellCasing", 0, 0, -110, 2, -50);
        stop;
    }
}

class S7_12gaShellCasing : S7_CasingBase {
    default {
        bounceSound "Weapons/Shell";
        scale .2;
    }

    states {
    Spawn:
        CAS4 FFGGHABCDEFGH 2;
    Idle:
        CAS4 ABCDEFGH 2; // A_SpawnItemEx ("S7_CasingSmoke")
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// 9mm Casing
//
//-------------------------------------------------------------------------------------------
class S7_9mmCasingSpawn : S7_CasingSpawnerBase {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_9mmCasing", -5, 0, fRandom [sfx] (-80, -100), 2, fRandom [sfx] (-45, -80));
        stop;
    }
}

class S7_9mmCasing : S7_CasingBase {
    default {
        bounceSound "Weapons/Brass";
        scale .2;
    }

    states {
    Spawn:
        CAS1 ABCDEFGH 2; // noDelay A_SpawnItemEx ("S7_CasingSmoke")
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// .45 ACP Casing
//
//-------------------------------------------------------------------------------------------
class S7_45ACPCasingSpawn : S7_9mmCasingSpawn {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_45ACPCasing", -5, 0, fRandom [sfx] (-80, -100), 2, fRandom [sfx] (-45, -80));
        stop;
    }
}

class S7_45ACPCasing : S7_9mmCasing { default { scale .3; } }

//-------------------------------------------------------------------------------------------
//
// Revolver Casing
//
//-------------------------------------------------------------------------------------------
class S7_RevolverCasingSpawn : S7_CasingSpawnerBase {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_RevolverCasing", -5, 0, 0, 2, 90);
        stop;
    }
}

class S7_RevolverCasing : S7_CasingBase {
    default {
        bounceSound "Weapons/Brass";
        scale .2;
    }

    states {
    Spawn:
        CAS2 ABCDEFGH 2; // noDelay A_SpawnItemEx ("S7_CasingSmoke")
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Rifle Casing
//
//-------------------------------------------------------------------------------------------
class S7_RifleCasingSpawn : S7_CasingSpawnerBase {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_RifleCasing", -5, 0, fRandom [sfx] (-80, -100), 2, fRandom [sfx] (-45, -80));
        stop;
    }
}
class S7_RifleCasingSpawn2 : S7_CasingSpawnerBase {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_RifleCasing", -5, 0, fRandom [sfx] (80, 100), 2, fRandom [sfx] (-45, -80));
        stop;
    }
}

class S7_RifleCasing : S7_CasingBase {
    default {
        bounceSound "Weapons/Brass";
        scale .2;
    }

    states {
    Spawn:
        CAS3 ABCDEFGH 2; // noDelay A_SpawnItemEx ("S7_CasingSmoke")
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// .45 WW Casing
//
//-------------------------------------------------------------------------------------------
class S7_45WWCasingSpawn : S7_CasingSpawnerBase {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_45WWCasing", -5, 0, fRandom [sfx] (-80, -100), 2, fRandom [sfx] (-45, -80));
        stop;
    }
}
class S7_45WWCasingSpawnRifle : S7_CasingSpawnerBase {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_45WWCasing", -5, 0, fRandom [sfx] (-80, -100), 2, fRandom [sfx] (-45, -55));
        stop;
    }
}

class S7_45WWCasing : S7_CasingBase {
    default {
        bounceSound "Weapons/Brass";
        scale .25;
    }

    states {
    Spawn:
        CAS5 ABCDEFGH 2; // noDelay A_SpawnItemEx ("S7_CasingSmoke")
        loop;
    }
}
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

    int timer;
    CVar stayTime;
    CVar fadeSpeed;

    static const int StayTics [] = { 10000, 5000, 2500, 1250, 625, 313, 157, 70, 35 };
    static const float FadeAmount [] = { 0.03, 0.06, 0.09, 0.12, 0.15, 2.0 };
    static const int FadeTics [] = { 3, 3, 2, 1, 1, 1 };

    override void BeginPlay () {
        super.BeginPlay ();
        stayTime = CVar.GetCVar ("S7_EffectStayTime", players [consolePlayer]);
        fadeSpeed = CVar.GetCVar ("S7_EffectFadeSpeed", players [consolePlayer]);
    }

    states {
    Delaying:
        #### # 1 {
            if (stayTime.GetInt () > -3) {
                if (timer == StayTics [stayTime.GetInt () + 2])
                    return ResolveState ("Fade");

                timer++;
            } else
                timer = 0;

            return ResolveState (null);
        }
        wait;

    Fade:
    Fade.Looper:
        #### # 1 {
            A_FadeOut (FadeAmount [fadeSpeed.GetInt ()]);
            A_SetTics (FadeTics [fadeSpeed.GetInt ()]);
        }
        wait;

    Rest1: #### A 0; goto RestDerp;
    Rest2: #### B 0; goto RestDerp;
    Rest3: #### C 0; goto RestDerp;
    Rest4: #### D 0; goto RestDerp;
    Rest5: #### E 0; goto RestDerp;
    Rest6: #### F 0; goto RestDerp;
    Rest7: #### G 0; goto RestDerp;
    Rest8: #### H 0; goto RestDerp;
    RestDerp:
        #### # 0 { return ResolveState ("Delaying"); }
        wait;


    Death:
        #### # 0 {
            int rnd = random [casingJumps] (0, 3);
            switch (rnd) {
                case 0: return ResolveState ("Rest1"); break;
                case 1: return ResolveState ("Rest3"); break;
                case 2: return ResolveState ("Rest5"); break;
                case 3: return ResolveState ("Rest7"); break;
            }

            return ResolveState (null);
        }
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
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_ShellCasing", 0, 0, fRandom [casingStuff] (80, 100), 2, fRandom [casingStuff] (40, 60));
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
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_9mmCasing", -5, 0, fRandom [casingStuff] (-80, -100), 2, fRandom [casingStuff] (-45, -80));
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
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_45ACPCasing", -5, 0, fRandom [casingStuff] (-80, -100), 2, fRandom [casingStuff] (-45, -80));
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
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_RifleCasing", -5, 0, fRandom [casingStuff] (-80, -100), 2, fRandom [casingStuff] (-45, -80));
        stop;
    }
}
class S7_RifleCasingSpawn2 : S7_CasingSpawnerBase {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_RifleCasing", -5, 0, fRandom [casingStuff] (80, 100), 2, fRandom [casingStuff] (-45, -80));
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
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_45WWCasing", -5, 0, fRandom [casingStuff] (-80, -100), 2, fRandom [casingStuff] (-45, -80));
        stop;
    }
}
class S7_45WWCasingSpawnRifle : S7_CasingSpawnerBase {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnProjectile ("S7_45WWCasing", -5, 0, fRandom [casingStuff] (-80, -100), 2, fRandom [casingStuff] (-45, -55));
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
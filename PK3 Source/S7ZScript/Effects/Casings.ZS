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

/* Casing sprites by Captain J. Edited by Chronos "phantombeta" Ouroboros
** Usage:
**  Weapons:  A_FireCustomMissile ('<Casing spawner actor>', 0, 0, <int xPos>, <float yPos>)
**  Monsters: A_SpawnProjectile ('<Casing spawner actor>', <float yPos/zPos>, <int xPos>, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0)
*/

class S7_CasingSmoke : S7_ShotSmokeTrail {
    default {
        Scale 0.05;
        Alpha 0.35;
        FloatBobPhase 0;
    }

    states {
    Spawn:
        SMOK GHIJKLMNOPQ 1;
        stop;
    }
}

class S7_CasingSpawnerBase : S7_EffectsBase {
    default {
        Speed 20;
        FloatBobPhase 0;

        Projectile;

        +NOCLIP
    }
}

class S7_CasingBase : S7_EffectsBase {
    default {
        Height 2;
        Radius 2;
        Speed 6;
        BounceType "Doom";
        FloatBobPhase 0;

        +CANBOUNCEWATER +NOBLOCKMAP +MISSILE +FORCEXYBILLBOARD
        +WINDTHRUST     +NOTELEPORT +GHOST   +MOVEWITHSECTOR
        +CLIENTSIDEONLY
        -DROPOFF -NOGRAVITY
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        if (!target)
            return;

        vel = target.vel + vel;
    }

    transient CVar stayTimeCVar, fadeSpeedCVar;
    int timer;
    int restFrame;

    override bool CanCollideWith (Actor other, bool passive) {
        if (other == target)
            return false;

        return Super.CanCollideWith (other, passive);
    }

    states {
    Delaying:
        ---- A 1 {
            frame = restFrame;

            if (!stayTimeCVar)
                stayTimeCVar = CVar.GetCVar ("S7_CasingsStayTime", players [consolePlayer]);

            int stayTime = stayTimeCVar.GetInt ();

            if (stayTime > -1) {
                if (timer >= stayTime)
                    return ResolveState ("Fade");

                timer++;
            }

            return ResolveState (null);
        }
        wait;

    Fade:
    Fade.Looper:
        #### # 1 {
            frame = restFrame;

            if (!fadeSpeedCVar)
                fadeSpeedCVar = CVar.GetCVar ("S7_CasingsFadeSpeed", players [consolePlayer]);

            A_FadeOut (fadeSpeedCVar.GetFloat ());
        }
        wait;

    /*//Rest1: #### A 0; goto RestDerp;
    //Rest2: #### B 0; goto RestDerp;
    Rest3: #### C 0; goto RestDerp;
    //Rest4: #### D 0; goto RestDerp;
    //Rest5: #### E 0; goto RestDerp;
    //Rest6: #### F 0; goto RestDerp;
    Rest7: #### G 0; goto RestDerp;
    //Rest8: #### H 0; goto RestDerp;
    RestDerp:
        #### # 0 { return ResolveState ("Delaying"); }
        wait;*/


    Death:
        #### # 0 {
            switch (frame) {
                case 0: // A
                case 4: // E
                    restFrame = ((random [casingJumps] (0, 1)) ? 2 : 6);
                    break;
                case 1: // B
                case 2: // C
                case 3: // D
                    restFrame = 2;
                    break;
                case 5: // F
                case 6: // G
                case 7: // H
                    restFrame = 6;
                    break;
            }
        }
        goto Delaying;
    }
}

//-------------------------------------------------------------------------------------------
//
// 20ga Shotgun Shell
//
//-------------------------------------------------------------------------------------------
class S7_ShellCasing : S7_CasingBase {
    default {
        BounceSound "Weapons/Shell";
        Scale .2;
    }

    states {
    Spawn:
        CAS0 ABCDEFGH 2; // A_SpawnItemEx ('S7_CasingSmoke')
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
        TNT1 A 0 noDelay A_SpawnProjectile ('S7_12gaShellCasing', -5, 0, fRandom [casingStuff] (-80, -100), CMF_AimDirection | CMF_TrackOwner, fRandom [casingStuff] (-45, -80));
        stop;
    }
}

class S7_12gaShellCasing : S7_CasingBase {
    default {
        BounceSound "Weapons/Shell";
        Scale .2;
    }

    states {
    Spawn:
        CAS4 FFGGHABCDEFGH 2;
    Idle:
        CAS4 ABCDEFGH 2; // A_SpawnItemEx ('S7_CasingSmoke')
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
        TNT1 A 0 noDelay A_SpawnProjectile ('S7_9mmCasing', -5, 0, fRandom [casingStuff] (-80, -100), CMF_AimDirection | CMF_TrackOwner, fRandom [casingStuff] (-45, -80));
        stop;
    }
}

class S7_9mmCasing : S7_CasingBase {
    default {
        BounceSound "Weapons/Brass";
        Scale .2;
    }

    states {
    Spawn:
        CAS1 HABCDEFG 2; // noDelay A_SpawnItemEx ('S7_CasingSmoke')
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// .45 ACP Casing
//
//-------------------------------------------------------------------------------------------
class S7_45ACPCasing : S7_9mmCasing { default { Scale .3; } }

//-------------------------------------------------------------------------------------------
//
// Revolver Casing
//
//-------------------------------------------------------------------------------------------
class S7_RevolverCasing : S7_CasingBase {
    default {
        BounceSound "Weapons/Brass";
        Scale .2;
    }

    states {
    Spawn:
        CAS2 ABCDEFGH 2; // noDelay A_SpawnItemEx ('S7_CasingSmoke')
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
        TNT1 A 0 noDelay A_SpawnProjectile ('S7_RifleCasing', -5, 0, fRandom [casingStuff] (-80, -100), CMF_AimDirection | CMF_TrackOwner, fRandom [casingStuff] (-45, -80));
        stop;
    }
}
class S7_RifleCasingSpawn2 : S7_CasingSpawnerBase {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnProjectile ('S7_RifleCasing', -5, 0, fRandom [casingStuff] (80, 100), CMF_AimDirection | CMF_TrackOwner, fRandom [casingStuff] (-45, -80));
        stop;
    }
}

class S7_RifleCasing : S7_CasingBase {
    default {
        BounceSound "Weapons/Brass";
        Scale .2;
    }

    states {
    Spawn:
        CAS3 HABCDEFG 2; // noDelay A_SpawnItemEx ('S7_CasingSmoke')
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// .45 WW Casing
//
//-------------------------------------------------------------------------------------------
class S7_45WWCasing : S7_CasingBase {
    default {
        BounceSound "Weapons/Brass";
        Scale .25;
    }

    states {
    Spawn:
        CAS5 HABCDEFG 2; // noDelay A_SpawnItemEx ('S7_CasingSmoke')
        loop;
    }
}
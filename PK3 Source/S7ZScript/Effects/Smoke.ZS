/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) ????      Jekyll Grim Payne
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

//-------------------------------------------------------------------------------------------
//
// Smoke
//
//-------------------------------------------------------------------------------------------
/** White **/
// By Jekyll Grim Payne/zer0, edited by Chronos "phantombeta" Ouroboros
class S7_WhiteSmoke : S7_EffectsBase {
    default {
        RenderStyle "add";
        Alpha 0.3;
        Scale 0.1;

        +FORCEXYBILLBOARD +NOGRAVITY +NOBLOCKMAP +NOINTERACTION
        +CLIENTSIDEONLY
    }

    states {
    Spawn:
        SMOK ABCDEFGHIJKLMNOPQ 1;
        stop;
    }
}

/** Black **/
// By Jekyll Grim Payne/zer0, edited by Chronos "phantombeta" Ouroboros
class S7_BlackSmoke : S7_WhiteSmoke {
    default {
        RenderStyle "translucent";
        Alpha 0.15;
    }

    states {
    Spawn:
        SMOK ABCDEFGHIJKLMNOPQ 1;
        stop;
    }
}

/** Shot smoke (white) **/
// By Jekyll Grim Payne/zer0, edited by Chronos "phantombeta" Ouroboros
class S7_ShotSmoke : S7_WhiteSmoke {
    default {
        VSpeed 2;
    }

    states {
    Spawn:
        SMOK ABCDEFGHIJKLMNOPQ 1 noDelay A_SpawnItem ('S7_ShotSmokeTrail');
        stop;
    }
}

class S7_ShotSmokeTrail : S7_ShotSmoke {
    default {
        VSpeed 0;
        Alpha 0.15;
    }

    states {
    Spawn:
        SMOK CDEFGHIJKLMNOPQ 1;
        stop;
    }
}

class S7_ShotSmoke_Spawner : S7_WhiteSmoke { // By wildweasel, edited by Chronos "phantombeta" Ouroboros
    default {
        Radius 1;
        Height 1;
        Speed 10;
        DamageFunction (0);

        Projectile;
    }

    states {
    Spawn:
        TNT1 A 1;
        TNT1 A 0 A_Die;
        TNT1 A 1 A_Jump (256, "Death");
        wait;
    Death:
        TNT1 A 0 A_SpawnProjectile ('S7_ShotSmoke', -2, 0, 0);
        stop;
    }
}

/** Shot smoke (Black) **/
// By Jekyll Grim Payne/zer0, edited by Chronos "phantombeta" Ouroboros
class S7_BlackShotSmoke : S7_ShotSmoke {
    default {
        RenderStyle "translucent";
        Alpha 0.15;
    }

    states {
    Spawn:
        SMOK ABCDEFGHIJKLMNOPQ 1 noDelay A_SpawnItem ('S7_BlackShotSmokeTrail');
        stop;
    }
}

class S7_BlackShotSmokeTrail : S7_ShotSmokeTrail {
    default {
        RenderStyle "translucent";
        Alpha 0.08;
    }
}

class S7_BlackShotSmoke_Spawner : S7_ShotSmoke_Spawner {
    states {
    Death:
        TNT1 A 0 A_SpawnProjectile ('S7_BlackShotSmoke', -2, 0, 0);
        stop;
    }
}

/** Smoking piece **/
// By Jekyll Grim Payne/zer0, edited by Chronos "phantombeta" Ouroboros
class S7_SmokingPiece : S7_DebrisGeneral { // Edited by Chronos "phantombeta" Ouroboros
    default {
        Speed 12;
        Gravity 0.7;

        +CLIENTSIDEONLY
        -NOGRAVITY
    }

    states {
    Spawn:
        TNT1 A 1 noDelay A_JumpIf (waterLevel >= 1, "Water");
        TNT1 A 1 A_SpawnItem ('S7_SmokingPieceSmoke');
        loop;
    Water:
        TNT1 A 1;
        stop;
    }
}

class S7_SmokingPieceSmoke : S7_ShotSmokeTrail {
    default {
        Scale 0.06;
        Alpha 0.5;
    }
}

/** Shot smoke 2 **/
// Coding by Chronos "phantombeta" Ouroboros. I dunno who made the sprites.
class S7_ShotSmoke_2_Spawner : S7_ShotSmoke_Spawner {
    states {
    Death:
        TNT1 A 0 A_SpawnProjectile ('S7_ShotSmoke_2', -2, 0, 0);
        stop;
    }
}

class S7_ShotSmoke_2 : S7_WhiteSmoke {
    default {
        Alpha 0.25;
        Scale 0.1;
    }

    states {
    Spawn:
        SMKS ABCDEFGHIJKLMNOPQRSTUVW 1;
        stop;
    }
}

/** Heat smoke/vapour/whatever **/
// By Jekyll Grim Payne/zer0, modified (a lot) by Chronos "phantombeta" Ouroboros
class S7_HeatSmoke : S7_ShotSmoke {
    default {
        Scale 0.08;
        Alpha 0.15;
    }

    states {
    Spawn:
        SMOK EFGHIJKLMNOPQ 1 noDelay A_SpawnItem ('S7_HeatSmokeTrail');
        stop;
    }
}

class S7_HeatSmokeTrail : S7_HeatSmoke {
    default {
        VSpeed 0;
        Alpha 0.075;
    }

    states {
    Spawn:
        SMOK HIJKLMNOPQ 1;
        stop;
    }
}

class S7_HeatSmokeSpawner : S7_DebrisGeneral {
    default {
        Speed 20;

        +NOCLIP
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnItem ('S7_HeatSmoke', 0, 0);
        stop;
    }
}

class S7_HeatSmokeStatic : S7_HeatSmoke {
    default {
        VSpeed 0;
    }

    states {
    Spawn:
        SMOK EFGHIJKLMNOPQ 1;
        stop;
    }
}

class S7_FireballSmoke : S7_HeatSmoke {
    default {
        Scale 0.12;
        Alpha 0.5;
    }

    states {
    Idle:
        TNT1 A 0 A_FadeOut (0.04);
        TNT1 A 0 A_SetScale (scale.X + 0.02);
    Spawn:
        SMK2 A 1;
        TNT1 A 0 A_FadeOut (0.04);
        SMK2 B 1 A_SetScale (scale.X + 0.02);
        TNT1 A 0 A_FadeOut (0.04);
        SMK2 C 1 A_SetScale (scale.X + 0.02);
        TNT1 A 0 A_FadeOut (0.04);
        SMK2 D 1 A_SetScale (scale.X + 0.02);
        goto Idle;
    }
}
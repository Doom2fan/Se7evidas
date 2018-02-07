//-------------------------------------------------------------------------------------------
//
// Smoke
//
//-------------------------------------------------------------------------------------------
/** White **/
// By Jekyll Grim Payne/zer0, edited by Chronos "phantombeta" Ouroboros
class S7_WhiteSmoke : S7_EffectsBase {
    default {
        renderStyle "add";
        alpha 0.3;
        scale 0.1;

        +noInteraction +noGravity +noBlockmap +forceXYBillboard
        +clientsideOnly
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
        renderStyle "translucent";
        alpha 0.15;
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
        vSpeed 2;
    }

    states {
    Spawn:
        SMOK ABCDEFGHIJKLMNOPQ 1 noDelay A_SpawnItem ("S7_ShotSmokeTrail");
        stop;
    }
}

class S7_ShotSmokeTrail : S7_ShotSmoke {
    default {
        vSpeed 0;
        alpha 0.15;
    }

    states {
    Spawn:
        SMOK CDEFGHIJKLMNOPQ 1;
        stop;
    }
}

class S7_ShotSmoke_Spawner : S7_WhiteSmoke { // By wildweasel, edited by Chronos "phantombeta" Ouroboros
    default {
        radius 1;
        height 1;
        speed 10;
        damageFunction (0);
        projectile;
    }

    states {
    Spawn:
        TNT1 A 1;
        TNT1 A 0 A_Die;
        TNT1 A 1 A_Jump (256, "Death");
        wait;
    Death:
        TNT1 A 0 A_SpawnProjectile ("S7_ShotSmoke", -2, 0, 0);
        stop;
    }
}

/** Shot smoke (Black) **/
// By Jekyll Grim Payne/zer0, edited by Chronos "phantombeta" Ouroboros
class S7_BlackShotSmoke : S7_ShotSmoke {
    default {
        renderStyle "translucent";
        alpha 0.15;
    }

    states {
    Spawn:
        SMOK ABCDEFGHIJKLMNOPQ 1 noDelay A_SpawnItem ("S7_BlackShotSmokeTrail");
        stop;
    }
}

class S7_BlackShotSmokeTrail : S7_ShotSmokeTrail {
    default {
        renderStyle "translucent";
        alpha 0.08;
    }
}

class S7_BlackShotSmoke_Spawner : S7_ShotSmoke_Spawner {
    states {
    Death:
        TNT1 A 0 A_SpawnProjectile ("S7_BlackShotSmoke", -2, 0, 0);
        stop;
    }
}

/** Smoking piece **/
// By Jekyll Grim Payne/zer0, edited by Chronos "phantombeta" Ouroboros
class S7_SmokingPiece : S7_DebrisGeneral { // Edited by Chronos "phantombeta" Ouroboros
    default {
        speed 12;
        gravity 0.7;

        +clientsideOnly
        -noGravity
    }

    states {
    Spawn:
        TNT1 A 1 noDelay A_JumpIf (waterLevel >= 1, "Water");
        TNT1 A 1 A_SpawnItem ("S7_SmokingPieceSmoke");
        loop;
    Water:
        TNT1 A 1;
        stop;
    }
}

class S7_SmokingPieceSmoke : S7_ShotSmokeTrail {
    default {
        scale 0.06;
        alpha 0.5;
    }
}

/** Shot smoke 2 **/
// Coding by Chronos "phantombeta" Ouroboros. I dunno who made the sprites.
class S7_ShotSmoke_2_Spawner : S7_ShotSmoke_Spawner {
    states {
    Death:
        TNT1 A 0 A_SpawnProjectile ("S7_ShotSmoke_2", -2, 0, 0);
        stop;
    }
}

class S7_ShotSmoke_2 : S7_WhiteSmoke {
    default {
        alpha 0.25;
        scale 0.1;
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
        scale 0.08;
        alpha 0.15;
    }

    states {
    Spawn:
        SMOK EFGHIJKLMNOPQ 1 noDelay A_SpawnItem ("S7_HeatSmokeTrail");
        stop;
    }
}

class S7_HeatSmokeTrail : S7_HeatSmoke {
    default {
        vSpeed 0;
        alpha 0.075;
    }

    states {
    Spawn:
        SMOK HIJKLMNOPQ 1;
        stop;
    }
}

class S7_HeatSmokeSpawner : S7_DebrisGeneral {
    default {
        speed 20;

        +noClip
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnItem ("S7_HeatSmoke", 0, 0);
        stop;
    }
}

class S7_HeatSmokeStatic : S7_HeatSmoke {
    default {
        vSpeed 0;
    }

    states {
    Spawn:
        SMOK EFGHIJKLMNOPQ 1;
        stop;
    }
}

class S7_FireballSmoke : S7_HeatSmoke {
    default {
        scale 0.12;
        alpha 0.5;
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
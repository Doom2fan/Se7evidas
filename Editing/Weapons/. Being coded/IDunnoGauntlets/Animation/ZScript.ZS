version "4.11.0"

class S7_BulletPuff : S7_TracerEffectsBase { // replaces bulletPuff {
    default {
        Scale 0.05;

        -CLIENTSIDEONLY
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_PlaySound ("Tracers/HitWall", CHAN_Body);
    NoSound:
        SPRK A 2 bright {
            for (int i = 0; i < 4; i++) {
                A_SpawnItemEx ('S7_BulletPuffSparks', 0.0, 0.0, 0.0, fRandom [sfx] (-0.5, -2.0), fRandom [sfx] (-2.0, 2.0), fRandom [sfx] (1.5, 4.0), 0, SXF_Clientside | SXF_NoCheckPosition);
                if (i < 3)
                    A_SpawnItemEx ('S7_BulletPuffSmoke', 0.0, 0.0, 0.0, 0.0, fRandom [sfx] (-1.0, 1.0), fRandom [sfx] (-0.8, 0.8), 0, SXF_Clientside | SXF_NoCheckPosition);
            }
        }
        SPRK A 2 bright A_SetScale (scale.X * 1.5, scale.Y * 1.5);
        stop;
    }
}

#include "S7ZScript/Weapons/Special/Gauntlets/Spells/Fireball.ZS"
#include "S7ZScript/Weapons/Special/Gauntlets/Spells/Flamethrower.ZS"
#include "S7ZScript/Weapons/Special/Gauntlets/Spells/LightningBolt.ZS"
#include "S7ZScript/Weapons/Special/Gauntlets/Gauntlets.ZS"
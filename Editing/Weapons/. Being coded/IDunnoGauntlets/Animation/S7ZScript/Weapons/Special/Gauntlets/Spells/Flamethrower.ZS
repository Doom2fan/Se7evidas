class S7_Gauntlets_Flamethrower : actor {
    default {
        speed 20;
        scale 0.75;
        damageFunction (random (1, 3));
        damageType "Fire2";
        deathType "Fire";
        renderStyle "add";

        projectile;
        +noExtremeDeath +forceXYBillboard
    }

    states {
    Spawn:
        FRFX ABCDEFGHIJKLMNOP 2 bright;
        stop;
    Death:
        TNT1 A 1 {
            for (int i = 0; i < 5; i++) {
                A_SpawnItemEx ("S7_Gauntlets_Flamethrower_HitFlames", 0.0, fRandom (-8.5, 8.5), fRandom (-5.5, 5.5), 0.0, 0.0, fRandom (2.5, 3.0), 0.0, SXF_NoCheckPosition | SXF_Clientside);
                A_SpawnItemEx ("S7_Gauntlets_Flamethrower_HitFlames", 0.0, fRandom (-8.5, 8.5), fRandom (-5.5, 5.5), 0.0, 0.0, fRandom (2.5, 3.0), 0.0, SXF_NoCheckPosition | SXF_Clientside);
            }
            A_Explode (8, 64);
        }
        stop;
    }
}

class S7_Gauntlets_Flamethrower_HitFlames : actor {
    default {
        renderStyle "add";
        alpha 0.99;
        scale 0.25;

        +clientsideOnly +noInteraction +forceXYBillboard
    }

    states {
    Spawn:
        FRFX FGHIJKLMNOP 1 bright;
        stop;
    }
}
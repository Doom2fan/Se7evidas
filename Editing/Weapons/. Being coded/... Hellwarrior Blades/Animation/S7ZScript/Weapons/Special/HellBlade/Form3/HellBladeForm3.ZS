class S7_HellhunterBladeForm3 : S7_BaseWeapon {
    default {
        tag "$HELLBLADE";
        inventory.pickupMessage "$HELLBLADE";
        weapon.ammoUse 0;
        weapon.ammoGive 0;
    }

    bool attacking;
    int lastAttack;

    states {
    Spawn:
        HWBP C -1;
        loop;

    Ready:
        HB31 DCBA 1;
    Ready2:
        HB31 A 1 {
            TakeInventory ("S7_Reloading", 0x7FFFFFFF);
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");

            A_WeaponReady ();
            invoker.attacking = false;
            invoker.lastAttack = 0;

            return ResolveState (null);
        }
        loop;

    Deselect:
        HB31 ABCD 1;
        goto TrueDeselect;

    Fire:
        HB31 A   1 {
            if (invoker.attacking)
                return A_Jump (256, "Fire1", "Fire2");//, "Fire3");

            invoker.attacking = true;

            return ResolveState (null);
        }
        HB31 BCD 1;
        TNT1 A   0 {
            if (random (0, 255) < 96)
                return ResolveState ("Fire1");

            return A_Jump (256, "Fire1", "Fire2");//, "Fire3");
        }

    Fire1:
        HB31 EFG 1;
        HB31 H   1 A_CustomPunch (callACS ("S7_HellBladeDMG", HELLBLADE_FORM3, random [weaponDamage] (1, 3), 15), TRUE, 0, "S7_HBForm3_Puff", 135.0);
        HB31 I   1;
        HB31 J   1 { invoker.lastAttack = 1; }
        goto Fire.ContinueCombo;
    Fire2:
        HB31 KLM 1;
        HB31 N   1 A_CustomPunch (callACS ("S7_HellBladeDMG", HELLBLADE_FORM3, random [weaponDamage] (1, 3), 15), TRUE, 0, "S7_HBForm3_Puff", 135.0);
        HB31 O   1;
        HB31 P   1 { invoker.lastAttack = 2; }
        goto Fire.ContinueCombo;
    Fire3:
        //{ invoker.lastAttack = 3; }
        goto Fire.ContinueCombo;

    Fire.ContinueCombo:
        TNT1 AAAAA 1;
        TNT1 AAAAAAAA 1 A_WeaponReady (WRF_NoBob | WRF_NoSecondary | WRF_NoSwitch);
    Fire.End:
        HB31 D   1 {
            invoker.attacking = false;
            invoker.lastAttack = 0;
        }
        HB31 CBA 1;
        goto Ready2;

    AltFire:
        TNT1 A 0 A_JumpIfInventory ("S7_HellhunterBladeLust", 5, 1);
        goto Ready2;
        TNT1 A 0;
        goto Ready2;
    }
}

class S7_HBForm3_Puff : S7_HBPuff_Base {
    default {
        renderStyle "add";
        scale 0.05;
        //seeSound "Weapons/HHunterBladeF3/Hit";
        //attackSound "Weapons/HHunterBladeF3/HitWall";
    }

    states {
    Crash:
        SPRK A 2 bright {
            for (int i = 0; i < 6; i++) {
                A_SpawnItemEx ("S7_BulletPuffSparks", 0.0, 0.0, 0.0, fRandom [sfx] (0.0, 2.0), fRandom [sfx] (-2.0, 2.0), fRandom [sfx] (1.5, 4.0), 0, SXF_Clientside);
                A_SpawnItemEx ("S7_BulletPuffSmoke", 0.0, 0.0, 0.0, 0.0, fRandom [sfx] (-1.0, 1.0), fRandom [sfx] (-0.8, 0.8), 0, SXF_Clientside);
            }
        }
        stop;
    }
}
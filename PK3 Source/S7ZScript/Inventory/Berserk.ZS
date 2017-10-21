/* Credits:
** DECORATE: Chronos "phantombeta" Ouroboros, Xaser
**
** Sprites:
**   HUD Sprites: Xaser, Chronos "phantombeta" Ouroboros
**   Animation: Xaser, Chronos "phantombeta" Ouroboros
**
** Sounds: Credits in the SNDINFO file (SNDINFO.MiscInventory)
*/

class S7_BerserkPickup : customInventory {
    default {
        tag "$BERSERK";
        inventory.icon "BSRKA0";
        inventory.pickupMessage "$BERSERK";
        inventory.amount 0;
        inventory.maxAmount 0;
        inventory.interHubAmount 0;
    }

    states {
    Pickup:
        TNT1 A 0 A_JumpIfInventory ("S7_Berserk", 0, "Nope");
        TNT1 A 0 GiveInventory ("S7_Berserk", 1);
        TNT1 A 0 A_RailWait;
        stop;
    Nope:
        TNT1 A 0 A_RailWait;
        fail;
    }
}

class S7_Berserk : ammo {
    default {
        tag "$BERSERK";
        inventory.icon "BSRKA0";
        inventory.pickupMessage "$BERSERK";
        inventory.amount 1;
        inventory.maxAmount 5;
        inventory.interHubAmount 5;

        +inventory.invBar
    }
}

class S7_BerserkToken : powerup { default { powerup.duration -60; powerup.color "FF 20 20", 0.25; } }
class S7_BerserkPower : powerWeaponLevel2 { default { powerup.duration -60; powerup.color "00 00 00", 0.0; } }

class S7_BerserkWeap : S7_BaseWeapon {
    default {
        tag "$BERSERKWEAP";
        weapon.ammoType1 "S7_Berserk";
        weapon.ammoUse1 1;

        +inventory.undroppable +inventory.untossable
    }

    states {
    Spawn:
        TNT1 A 0 A_SpawnItemEx ("S7_Berserk", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, SXF_NoCheckPosition);
        stop;

    Ready:
        SYR0 A              1 A_JumpIfNoAmmo ("Ready2");
        SYR0 BCDEFGHIJKLMNO 1;
    Ready2:
        SYR1 A 0 A_JumpIfNoAmmo ("Ready2");
        goto Ready2.DoThings;
    Ready2.NoAmmo:
        TNT1 A 0;
        goto Ready2.DoThings;
    Ready2.DoThings:
        #### # 1 {
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            TakeInventory ("S7_Reloading", 0x7FFFFFFF);
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            A_WeaponReady ();

            return ResolveState (null);
        }
        goto Ready2;

    Deselect:
        TNT1 A 0 A_Lower;
        wait;

    Fire:
        SYR1 A          3 A_JumpIf (!invoker.CheckAmmo (PrimaryFire, false, true) || CheckInventory ("S7_BerserkToken", 1), "Ready2");
        SYR1 CDD        3;
        SYR1 EFGHI      1;
        SYR1 J          5;
        SYR1 KL         1;
        SYR1 M          8 A_PlaySound ("Syringe/In", CHAN_5);
        SYR1 N          2;
        SYR1 O          2 {
            A_PlaySound ("Berserk/Inject", CHAN_Weapon);
            A_PlaySound ("*pain", CHAN_Voice);
        }
        SYR1 P          2;
        SYR1 Q          2 {
            TakeInventory ("S7_Berserk", 1);
            GiveInventory ("S7_BerserkPower", 1);
            GiveInventory ("S7_BerserkToken", 1);
        }
        SYR1 QRSTUVWWWX 2;
        SYR1 Y          8;
        SYR1 Z          2;
        SYR2 A          2 A_PlaySound ("Syringe/Out", CHAN_5);
        SYR2 BCD        2;
        SYR2 E          8;
        SYR2 FG         2;
        SYR2 HIJKL      1;
        TNT1 A          0;
        SYR2 MN         1;
        SYR2 O          1 A_FireProjectile ("S7_SpentSyringe", 0, 0, 0, 0);
        SYR2 PQR        1;
        TNT1 A          8;
        goto Ready;
    }
}

class S7_SpentSyringe : S7_CasingBase {
    default {
        scale 0.1;
        seeSound "Weapons/Shell";
    }

    states {
    Spawn:
        SYTR ABCDEFGHIJKLMNOP 1;
        loop;
    Death:
        #### # 1 A_Jump (256, "Delaying");
        wait;
    }
}
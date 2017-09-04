version "3.1.0"

//-------------------------------------------------------------------------------------------
//
// IWSL-5 (Order standard issue Rocket Launcher)
//
//-------------------------------------------------------------------------------------------
class S7_IWSL5Ammo : ammo { // Ammo pool
    default {
        inventory.amount 1;
        inventory.maxAmount 30;
    }

    states {
    Spawn:
        TNT1 A -1;
        stop;
    }
}

class S7_IWSL5Mag : ammo {
    default {
        inventory.maxAmount 5;
        ammo.backpackMaxAmount 5;

        +inventory.ignoreSkill
    }
}

class S7_IWSL5 : S7_BaseWeapon {
    default {
        tag "$IWSL5";
        inventory.pickupMessage "$IWSL5";
        weapon.ammoType1 "S7_IWSL5Mag";
        weapon.ammoType2 "S7_IWSL5Ammo";
        weapon.ammoUse 1;
        weapon.ammoGive 0;
    }

    bool chambered;

    states {
    Spawn:
        IWRL Z -1;
        stop;

    Ready:
        IWRL VWXYZA 1;
    Ready2:
        IWRL A 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            GiveInventory ("S7_WeapReady", 1);
            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Deselect:
        IWRL AZYXWV 1;
        goto TrueDeselect;

    Fire:
        IWRL A   1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");
            if (!invoker.chambered)
                return ResolveState ("Fire.Rechamber");

            invoker.chambered = false;
            A_AlertMonsters ();
            A_GunFlash ();
            A_PlaySound ("Weapons/IWSL5/Fire", CHAN_Weapon);

            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 4);
            A_FireProjectile ("S7_IWSL5Rocket", 0.0, 1, 0, -3, 0, 0.0);

            A_SetPitch (pitch - 0.5, SPF_Interpolate);

            return ResolveState (null);
        }
        IWRF C   1 A_SetPitch (pitch - 0.5, SPF_Interpolate);
        IWRF BAA 1;
        IWRF BCD 1;
        IWRL A   2;
        goto Ready2;
    Fire.Rechamber:
        IWRL A     1 {
            A_PlaySound ("Weapons/IWSL5/Chamber", CHAN_Weapon);
            invoker.chambered = true;
        }
        IWRL CDEF  1;
        IWRL GHIJ  1;
        IWRL K     4;
        IWRL LMNO  1;
        IWRL P     5;
        IWRL QRSTU 1;
        goto Ready2;

    Flash:
        IWRF WXYZ 1 bright;
        stop;

    DryFire:
        IWRL A 3 A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
        TNT1 A 0 A_JumpIfInventory ("S7_AutoReloading", 1, "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            TakeInventory ("S7_Reloading", 1);

            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1))
                return ResolveState ("Ready2");

            int ammoAmount = min (FindInventory (invoker.ammoType1).maxAmount - CountInv (invoker.ammoType1), CountInv (invoker.ammoType2));
            if (ammoAmount <= 0)
                return ResolveState ("Ready2");

            GiveInventory (invoker.ammoType1, ammoAmount);
            TakeInventory (invoker.ammoType2, ammoAmount);

            return ResolveState ("ReloadFinish");
        }
    ReloadFinish:
        goto Ready2;
    }
}

class S7_IWSL5Rocket : Rocket { }
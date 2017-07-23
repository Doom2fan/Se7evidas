//-------------------------------------------------------------------------------------------
//
// C23 "Manx" Carbine
//
//-------------------------------------------------------------------------------------------
class S7_ManxCarbineClip : ammo {
    default {
        inventory.maxAmount 23;
        ammo.backpackMaxAmount 23;

        +inventory.ignoreSkill
    }
}

class S7_ManxCarbine : S7_BaseWeapon {
    default {
        tag "$MANXCARBINE";
        inventory.pickupMessage "$MANXCARBINE";
        weapon.ammoType1 "S7_ManxCarbineClip";
        weapon.ammoType2 "S7_9mmCartridges";
        weapon.ammoUse 1;
        weapon.ammoGive 0;
    }

    bool semiAuto;

    states {
    Spawn:
        MANX Z -1;
        loop;

    Ready:
    Ready2:
        MANX A 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            if (CheckInventory ("S7_ChangeFireMode", 1))
                return ResolveState ("ChangeMode");

            GiveInventory ("S7_WeapReady", 1);
            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Fire:
        MANX A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/ManxCarbine/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 3, 4.5);
            A_FireProjectile ("S7_9mmCasingSpawn", 0, 0, 13, -3);
            A_FireProjectile ("S7_ManxCarbineTracer", fRandom [weaponSpread] (-0.25, 0.25), 1, 6, 1, 0, fRandom [weaponSpread] (-0.25, 0.25));
            A_SetPitch (pitch - 0.5, SPF_Interpolate);

            return ResolveState (null);
        }
        MANX B 1 A_SetPitch (pitch - 0.5, SPF_Interpolate);
        MANX A 2 A_JumpIf (invoker.semiAuto, "Fire.Semi");
        MANX A 1 A_Refire;
        MANX A 3;
        goto Ready2;
    Fire.Semi:
        MANX AAAA 1 A_WeaponReady (WRF_NoBob | WRF_NoSecondary | WRF_DisableSwitch);
        MANX A    2;
        goto Ready2;

    ChangeMode:
        MANX A 5 {
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            if (invoker.semiAuto)
                invoker.semiAuto = false;
            else
                invoker.semiAuto = true;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);
        }
        goto Ready2;

    DryFire:
        MANX A 3 A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
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
        MANX CDEFG    2;
        MANX HHHHHHIJ 1;
        MANX K        1 A_PlaySound ("Weapons/ManxCarbine/In", CHAN_6);
        MANX L        1;
        MANX MNOPCA   2;
        goto Ready2;

    // Muzzle flashes
    Flash:
        MNXF A 1 bright;
        stop;
    }
}
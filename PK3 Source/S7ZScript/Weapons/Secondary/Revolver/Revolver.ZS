//-------------------------------------------------------------------------------------------
//
// Ω-Σ "Deathbringer" Revolver
//
//-------------------------------------------------------------------------------------------
class S7_RevolverClip : ammo {
    default {
        inventory.maxAmount 6;
        ammo.backpackMaxAmount 6;

        +inventory.ignoreSkill
    }
}

class S7_Revolver : S7_BaseWeapon {
    default {
        tag "$REVOLVER";
        inventory.pickupMessage "$REVOLVER";
        weapon.ammoType1 "S7_RevolverClip";
        weapon.ammoType2 "S7_44MCartridges";
        weapon.ammoUse 1;
        weapon.ammoGive 0;
        S7_BaseWeapon.Icon "RVLVZ0";
    }

    states {
    Spawn:
        RVLV Z -1;
        loop;

    Ready:
    Ready2:
        RVLV A 1 {
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

    Fire:
        RVLV A  1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/Revolver/Fire", CHAN_Weapon);
            A_AlertMonsters ();

            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 4, 5);
            A_FireProjectile ("S7_RevolverTracer", fRandom [weaponSpread] (-0.5, 0.5), 1, 7, 2, 0, fRandom [weaponSpread] (-0.5, 0.5));

            A_SetPitch (pitch - 1.75, SPF_Interpolate);

            return ResolveState (null);
        }
        RVLV B  1 A_SetPitch (pitch - 1.75, SPF_Interpolate);
        RVLV C  1;
        RVLV DE 1;
        RVLV A 15;
        goto Ready2;

    DryFire:
        RVLV A 3 A_PlaySound ("Weapons/Revolver/Dryfire", CHAN_7);
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
        RVLV A 1;
        // Open
        REVR A      1 A_PlaySound ("Weapons/Revolver/Open", CHAN_5);
        REVR BCDEFG 1;
        // Eject
        REVR H     1 {
            A_PlaySound ("Weapons/Revolver/Eject", CHAN_6);
            for (int i = 0; i < 3; i++) {
                A_FireProjectile ("S7_RevolverCasingSpawn", 0, 0, 8 + i, -2);
                A_FireProjectile ("S7_RevolverCasingSpawn", 0, 0, 8 + i, -3);
            }
        }
        REVR IJKLM 1;
        // Insert
        REVR NOPQR 1;
        REVR S     1 A_PlaySound ("Weapons/Revolver/In", CHAN_7);
        REVR TUV   1;
        // Close
        REVR W   1 A_PlaySound ("Weapons/Revolver/Close", CHAN_5);
        REVR XYZ 1;
        RVR2 AB  1;
        // Spin
        RVR2 C    1 A_PlaySound ("Weapons/Revolver/Spin", CHAN_6);
        RVR2 DEF  1;
        RVLV BABA 1;
        RVLV BABA 1;
        RVLV BABA 2;
        RVLV BABA 3;
        RVLV A    1;
        goto Ready2;
    }
}
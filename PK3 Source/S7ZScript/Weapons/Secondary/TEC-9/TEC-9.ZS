//-------------------------------------------------------------------------------------------
//
// S18 "Kronos" SMG
//
//-------------------------------------------------------------------------------------------
class S7_TEC9Clip : ammo {
    default {
        inventory.maxAmount 32;
        ammo.backpackMaxAmount 32;

        +inventory.ignoreSkill
    }
}

class S7_TEC9 : S7_BaseWeapon {
    default {
        tag "$TEC9";
        inventory.pickupMessage "$TEC9";
        weapon.ammoType1 "S7_TEC9Clip";
        weapon.ammoType2 "S7_9mmCartridges";
        weapon.ammoUse 1;
        weapon.ammoGive 0;
        S7_BaseWeapon.Icon "TEC9Z0";
    }

    bool burstFire;
    int burstCount;

    override void DoEffect () {
        super.DoEffect ();

        fireModeIcon = burstFire ? FMI_BurstFire : FMI_FullAuto;
    }

    states {

    Spawn:
        TEC9 Z -1;
        loop;

    Ready:
    Ready2:
        TEC9 A 1 {
            invoker.burstCount = 0;

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
        TEC9 B 1;
    Hold:
        TEC9 C 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/TEC-9/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2.8, 4.5);
            A_FireProjectile ("S7_9mmCasingSpawn", 0, 0, 9, -2);
            A_FireProjectile ("S7_TEC9Tracer", fRandom [weaponSpread] (-0.45, 0.45), 1, 3, 2, 0, fRandom [weaponSpread] (-0.45, 0.45));

            if (invoker.burstFire) {
                A_SetPitch (pitch - 0.5, SPF_Interpolate);

                if ((invoker.burstCount & 1)) // Show frame D on odd shots and frame C on even shots
                    return ResolveState ("Fire.Burst2");
                else
                    return ResolveState ("Fire.Burst1");
            } else
                A_SetPitch (pitch - 0.25, SPF_Interpolate);

            return ResolveState (null);
        }
        TEC9 D 1 A_SetPitch (pitch - 0.25, SPF_Interpolate);
        goto Fire.End;
    Fire.Burst1:
        TEC9 C 1;
        goto Fire.End;
    Fire.Burst2:
        TEC9 D 1;
        goto Fire.End;
    Fire.End:
        TEC9 B 1 {
            if (invoker.burstFire)
                invoker.burstCount++;

            if (invoker.burstFire && invoker.burstCount >= 3)
                invoker.burstCount = 0;
            else
                A_Refire ();

            A_ClearRefire ();
            return ResolveState (null);
        }
        TEC9 A 7;
        goto Ready2;

    ChangeMode:
        TEC9 A 5 {
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);
            invoker.burstCount = 0;

            if (invoker.burstFire)
                invoker.burstFire = false;
            else
                invoker.burstFire = true;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);
        }
        goto Ready2;

    DryFire:
        TEC9 B 1 {
            invoker.burstCount = 0;
            A_PlaySound ("Weapons/DryFirePistol", CHAN_7);
            A_ClearRefire ();
        }
        TEC9 A 3;
        TNT1 A 0 A_JumpIfInventory ("S7_AutoReloading", 1, "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            TakeInventory ("S7_Reloading", 1);
            A_ClearRefire ();

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
        TNT1 A         0 A_PlaySound ("Weapons/TEC-9/Out", CHAN_6);
        TECR ABCDEEEEE 1;
        TECR FGH       2;
        TNT1 A         0 A_PlaySound ("Weapons/TEC-9/In", CHAN_7);
        TECR IJKLMNO   2;
        TNT1 A         0 A_PlaySound ("Weapons/TEC-9/Tap", CHAN_6);
        TECR PQRRRSTU  2;
        goto Ready2;

    // Muzzle flashes
    Flash:
        TNT1 A 0 bright A_Jump (256, "Flash1", "Flash2");
    Flash1:
        TECF A 1 bright;
        stop;
    Flash2:
        TECF B 1 bright;
        stop;
    }
}
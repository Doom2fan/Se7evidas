//-------------------------------------------------------------------------------------------
//
// A28 "Mars" Assault Rifle
//
//-------------------------------------------------------------------------------------------
class S7_AMGMag : ammo {
    default {
        inventory.maxAmount 35;
        ammo.backpackMaxAmount 35;

        +inventory.ignoreSkill
    }
}

class S7_AMG : S7_BaseWeapon {
    default {
        tag "$AMG";
        inventory.pickupMessage "$AMG";
        weapon.ammoType1 "S7_AMGMag";
        weapon.ammoType2 "S7_762x39Cartridges";
        weapon.ammoUse 1;
        weapon.ammoGive 0;
        S7_BaseWeapon.Icon "AMGGZ0";
    }

    bool burstFire;
    int burstCount,
        zoomLevel;

    override void DoEffect () {
        super.DoEffect ();

        fireModeIcon = burstFire ? FMI_BurstFire : FMI_FullAuto;
    }

    states {
    Spawn:
        AMGG Z -1;
        stop;
    Deselect:
        AMGG A 0 {
            A_SetCrosshair (0);
            invoker.burstCount = 0;

            if (invoker.zoomLevel >= 1)
                return ResolveState ("Deselect.Zoom");

            return ResolveState (null);
        }
        goto Super::Deselect;
    Deselect.Zoom:
        AMGG A 8 {
            invoker.zoomLevel = 0;
            A_SetBlend ("00 00 00", 1.0, 8);
            A_ZoomFactor (1.0, ZOOM_Instant);
        }
        goto Deselect;

    Ready:
        TNT1 A 0 {
            invoker.burstCount = 0;
            invoker.zoomLevel = 0;
        }
    Ready2:
        AMGG A 0 A_JumpIf (invoker.zoomLevel >= 1, "Ready2.Zoom");
        goto Ready2.DoStuff;
    Ready2.Zoom:
        SCP1 A 0;
        goto Ready2.DoStuff;
    Ready2.DoStuff:
        #### # 1 {
            invoker.burstCount = 0;
            if (invoker.zoomLevel > 0)
                TakeInventory ("S7_DoMelee", 0x7FFFFFFF);

            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            if (CheckInventory ("S7_ChangeFireMode", 1))
                return ResolveState ("ChangeMode");

            A_WeaponReady (WRF_AllowZoom | ((invoker.zoomLevel >= 1) ? WRF_NoBob : 0));

            return ResolveState (null);
        }
        #### # 0 TakeInventory ("S7_HoldingZoom", 0x7FFFFFFF);
        goto Ready2;
    Ready2.HoldingZoom:
        #### # 1 A_WeaponReady (WRF_NoFire | WRF_NoSwitch | ((invoker.zoomLevel >= 1) ? WRF_NoBob : 0));
        goto Ready2;

    QuickMeleeDerp:
        TNT1 A 0 {
            TakeInventory ("S7_DoMelee", 0x7FFFFFFF);

            if (invoker.zoomLevel >= 1)
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        goto QuickMelee;

    Zoom:
        #### # 1 A_JumpIf (CheckInventory ("S7_HoldingZoom", 1), "Ready2.HoldingZoom");
        SCP1 A 8 {
            GiveInventory ("S7_HoldingZoom", 1);

            if (invoker.zoomLevel > 0 && CheckInventory ("S7_ChangeFireMode", 1)) {
                TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);
                return ResolveState ("ToggleZoomLevel");
            }

            if (invoker.zoomLevel == 0) {
                invoker.zoomLevel = 1;
                A_SetCrosshair (99);
                A_SetBlend ("00 00 00", 1.0, 8);
                A_ZoomFactor (3.5, ZOOM_Instant);
            } else
                return ResolveState ("Unzoom");

            return ResolveState (null);
        }
        TNT1 A 0 TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);
        goto Ready2;
    Unzoom:
        AMGG A 8 {
            invoker.zoomLevel = 0;
            A_SetCrosshair (0);
            A_SetBlend ("00 00 00", 1.0, 8);
            A_ZoomFactor (1.0, ZOOM_Instant);
        }
        TNT1 A 0 TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);
        goto Ready2;

    ChangeMode:
        #### # 1;
        #### # 5 {
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            if (invoker.zoomLevel > 0 && ((player.cmd.buttons & BT_Zoom) || (player.oldbuttons & BT_Zoom)))
                return ResolveState ("ToggleZoomLevel");

            if (invoker.burstFire)
                invoker.burstFire = false;
            else
                invoker.burstFire = true;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);

            return ResolveState (null);
        }
        goto Ready2;
    ToggleZoomLevel:
        SCP1 A 8 {
            A_SetCrosshair (99); // This is just to make sure

            if (invoker.zoomLevel == 1) {
                invoker.zoomLevel = 2;
                A_ZoomFactor (6.0);
            } else {
                invoker.zoomLevel = 1;
                A_ZoomFactor (3.5);
            }
        }
        goto Ready2;

    Fire:
        AMGG B 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/AMG/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();

            if (invoker.zoomLevel >= 1)
                return ResolveState ("Fire.Zoom");

            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 1, 5);
            A_FireProjectile ("S7_RifleCasingSpawn", 0, 0, 8, -5);
            A_FireProjectile ("S7_AMGTracer", fRandom [weaponSpread] (-0.14, 0.14), 1, 2, 2, 0, fRandom [weaponSpread] (-0.14, 0.14));

            A_SetPitch (pitch - 0.8, SPF_Interpolate);

            return ResolveState (null);
        }
        AMGG B 1 A_SetPitch (pitch - 0.8, SPF_Interpolate);
        AMGG C 1 A_JumpIf (invoker.burstFire, "Fire.Burst");
        AMGG C 1 A_Refire ();
        goto Ready2;

    Fire.Burst:
        AMGG C 2 {
            if (++invoker.burstCount >= 3) // If a full burst has been shot, just reset burstCount - since the A_Refire is in the else, it won't be run.
                invoker.burstCount = 0;
            else
                A_Refire ();
        }
        AMGG A 4 {
            invoker.burstCount = 0;
            A_ClearRefire (); // Gotta clear the refire manually.
        }
        goto Ready2;

    Fire.Zoom:
        SCP1 A 1 {
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 0, 0);
            A_FireProjectile ("S7_RifleCasingSpawn", 0, 0, 8, -8);
            A_FireProjectile ("S7_AMGTracer", fRandom [weaponSpread] (-0.13, 0.13), 1, 0, -3, 0, fRandom [weaponSpread] (-0.13, 0.13));

            A_ZoomFactor ((invoker.zoomLevel >= 2) ? 5.9 : 3.4);
            if (invoker.burstFire)
                A_SetPitch (pitch - ((invoker.zoomLevel >= 2) ? 0.8 : 1.0), SPF_Interpolate);
            else
                A_SetPitch (pitch - ((invoker.zoomLevel >= 2) ? 0.4 : 0.5), SPF_Interpolate);
        }
        SCP1 A 1 {
            if (invoker.burstFire)
                A_SetPitch (pitch + ((invoker.zoomLevel >= 2) ? 0.336 : 0.42), SPF_Interpolate);
            else
                A_SetPitch (pitch - ((invoker.zoomLevel >= 2) ? 0.4 : 0.5), SPF_Interpolate);
        }
        SCP1 A 1 {
            A_ZoomFactor ((invoker.zoomLevel >= 2) ? 6.0 : 3.5);

            if (invoker.burstFire)
                return ResolveState ("Fire.Zoom.Burst");

            A_SetPitch (pitch + ((invoker.zoomLevel >= 2) ? 0.336 : 0.42), SPF_Interpolate);
            return ResolveState (null);
        }
        SCP1 A 1 A_Refire ("Fire");
        goto Ready2;

    Fire.Zoom.Burst:
        SCP1 A 2 {
            if (++invoker.burstCount >= 3) { // If a full burst has been shot, just reset burstCount - since the A_Refire is in the else, it won't be run.
                invoker.burstCount = 0;
            } else
                A_Refire ("Fire");
        }
        SCP1 A 4 {
            invoker.burstCount = 0;
            A_ClearRefire (); // Gotta clear the refire manually.
        }
        goto Ready2;

    Flash:
        TNT1 A  0 A_JumpIf (invoker.zoomLevel >= 1, "Flash.Zoom");
        AMGF AB 1 bright;
        stop;
    Flash.Zoom:
        TNT1 A 2 bright;
        stop;

    DryFire.Burst:
        AMGG C 2 {
            invoker.burstCount = 0;

            if (invoker.zoomLevel >= 1)
                return ResolveState ("Dryfire.Burst.Zoom");

            return ResolveState (null);
        }
        goto DryFire;
    DryFire.Burst.Zoom:
        SCP1 A 2;
        goto DryFire;
    DryFire:
        AMGG A 3 {
            A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
            invoker.burstCount = 0;

            if (invoker.zoomLevel >= 1)
                return ResolveState ("DryFire.Zoom");

            return ResolveState (null);
        }
        TNT1 A 0 A_JumpIfInventory ("S7_AutoReloading", 1, "DryReload");
        goto Ready2;
    DryFire.Zoom:
        SCP1 A 3;
        TNT1 A 0 A_JumpIfInventory ("S7_AutoReloading", 1, "DryReload");
        goto Ready2;

    DryReload:
        TNT1 A 0 GiveInventory ("S7_Reloading", 1);
    Reload:
        TNT1 A 0 {
            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1)) {
                TakeInventory ("S7_Reloading", 1);
                return ResolveState ("Ready2");
            }

            if (invoker.zoomLevel >= 1)
                return ResolveState ("Unzoom");

            TakeInventory ("S7_Reloading", 1);

            int ammoAmount = min (FindInventory (invoker.ammoType1).maxAmount - CountInv (invoker.ammoType1), CountInv (invoker.ammoType2));
            if (ammoAmount <= 0)
                return ResolveState ("Ready2");

            GiveInventory (invoker.ammoType1, ammoAmount);
            TakeInventory (invoker.ammoType2, ammoAmount);

            return ResolveState ("ReloadFinish");
        }
    ReloadFinish:
        AMGG A         2;
        AMGR ABCDE     2;
        AMGR F         2 A_PlaySound ("Weapons/AMG/Out", CHAN_6);
        AMGR GHIJKLMNO 2;
        AMGR P         2 A_PlaySound ("Weapons/AMG/In", CHAN_7);
        AMGR QR        4;
        AMGR S         7 A_PlaySound ("Weapons/AMG/Tap", CHAN_6);
        AMGR TUVWXYA   2;
        AMGG A         2;
        goto Ready2;
    }
}
//-------------------------------------------------------------------------------------------
//
// MK17 "Conqueror" Anti-Materiel Sniper Rifle
//
//-------------------------------------------------------------------------------------------
class S7_ConquerorRifleClip : ammo {
    default {
        inventory.maxAmount 15;
        ammo.backpackMaxAmount 15;

        +inventory.ignoreSkill
    }
}

class S7_ConquerorRifle : S7_BaseWeapon {
    default {
        tag "$CONQUERORSRIFLE";
        inventory.pickupMessage "$CONQUERORSRIFLE";
        weapon.ammoType1 "S7_ConquerorRifleClip";
        weapon.ammoType2 "S7_45WWCartridges";
        weapon.ammoUse 1;
        weapon.ammoGive 0;
    }

    bool jammed, loaded, noPump;
    int zoomLevel;

    states {
    Spawn:
        CQRP A -1;
        loop;

    Ready:
        CQR1 VWXYZA 1;
    Ready2:
        CQR1 A 0 A_JumpIf (invoker.zoomLevel > 0, "Ready2.Zoom");
        goto Ready2.DoThings;
    Ready2.Zoom:
        SCP1 B 0;
        goto Ready2.DoThings;
    Ready2.DoThings:
        #### # 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            if (CheckInventory ("S7_ChangeFireMode", 1))
                return ResolveState ("ChangeMode");

            GiveInventory ("S7_WeapReady", 1);
            A_WeaponReady (WRF_AllowZoom);

            return ResolveState (null);
        }
        #### # 0 TakeInventory ("S7_HoldingZoom", 0x7FFFFFFF);
        goto Ready2;
    Ready2.HoldingZoom:
        #### # 1 A_WeaponReady (WRF_NoFire | WRF_NoSwitch);
        goto Ready2;

    Zoom:
        #### # 1 A_JumpIfInventory ("S7_HoldingZoom", 1, "Ready2.HoldingZoom");
        SCP1 B 8 {
            GiveInventory ("S7_HoldingZoom", 1);

            if (invoker.zoomLevel > 0 && CheckInventory ("S7_ChangeFireMode", 1)) {
                TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);
                return ResolveState ("ToggleZoomLevel");
            }

            if (invoker.zoomLevel == 0) {
                invoker.zoomLevel = 1;
                A_SetCrosshair (99);
                A_SetBlend ("00 00 00", 1.0, 8);
                A_ZoomFactor (6.0, ZOOM_Instant);
            } else
                return ResolveState ("Unzoom");

            return ResolveState (null);
        }
        goto Ready2;
    Unzoom:
        CQR1 A 10 {
            invoker.zoomLevel = 0;
            A_SetBlend ("00 00 00", 1.0, 8);
            A_SetCrosshair (0);
            A_ZoomFactor (1.0, ZOOM_Instant);
        }
        goto Ready2;

    ChangeMode:
        #### # 1;
        #### # 5 {
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            if (invoker.zoomLevel > 0 && ((GetPlayerInput (MODINPUT_Buttons) & BT_Zoom) || (GetPlayerInput (MODINPUT_OldButtons) & BT_Zoom)))
                return ResolveState ("ToggleZoomLevel");

            if (invoker.noPump)
                invoker.noPump = 0;
            else
                invoker.noPump = 1;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);

            return ResolveState (null);
        }
        goto Ready2;
    ToggleZoomLevel:
        SCP1 B 8 {
            A_SetCrosshair (99); // This is just to make sure

            if (invoker.zoomLevel == 1) {
                invoker.zoomLevel = 2;
                A_ZoomFactor (12.0);
            } else if (invoker.zoomLevel == 2) {
                invoker.zoomLevel = 3;
                A_ZoomFactor (24.0);
            } else {
                invoker.zoomLevel = 1;
                A_ZoomFactor (6.0);
            }
        }
        goto Ready2;

    Deselect:
        CQR1 A     1 {
            if (invoker.zoomLevel > 0)
                return ResolveState ("Deselect.Zoom");

            A_SetCrosshair (0);
            return ResolveState (null);
        }
        CQR1 ZYXWV 1;
        goto Super::Deselect;
    Deselect.Zoom:
        CQR1 A 8 {
            A_SetBlend ("00 00 00", 1.0, 8);
            A_SetCrosshair (0);
            A_ZoomFactor (1.0, ZOOM_Instant);
            invoker.zoomLevel = 0;
        }
        goto Ready2;

    Fire:
        CQR1 A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");
            if (!invoker.loaded)
                return ResolveState ("Fire.Pump");
            if (invoker.jammed)
                return ResolveState ("Fire.Jammed");

            A_AlertMonsters ();
            A_PlaySound ("Weapons/ConquerorRifle/Fire", CHAN_Weapon);
            invoker.loaded = false;

            if (invoker.zoomLevel > 0)
                return ResolveState ("Fire.Zoomed");

            A_GunFlash ("Flash");
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 4.5);
            A_FireProjectile ("S7_ConquerorRifle_Tracer", fRandom [weaponSpread] (-0.05, 0.05), 1, 6, -2, 0, fRandom [weaponSpread] (-0.06, 0.06));

            if (invoker.noPump)
                A_FireProjectile ("S7_45WWCasingSpawnRifle", 0, 0, 10, -12);

            A_SetPitch (pitch - 1.5);

            return ResolveState (null);
        }
        CQR1 C 1 A_SetPitch (pitch - 1.75);
        CQR1 B 1 A_SetPitch (pitch + 0.15);
        CQR1 C 1 {
            if (invoker.noPump) {
                invoker.loaded = true;
                if (random [weaponSpc] (0, 255) < 2)
                    invoker.jammed = true;
                else
                    invoker.jammed = false;
            }
        }

        CQR1 CDDAA 1 A_WeaponReady (WRF_NoSecondary | WRF_DisableSwitch | WRF_NoBob);
        goto Ready2;
    Fire.Pump:
        CQR1 A   1 {

            invoker.loaded = true;
            if (random [weaponSpc] (0, 255) < 2)
                invoker.jammed = true;
            else
                invoker.jammed = false;

            if (invoker.zoomLevel > 0)
                return ResolveState ("Fire.Zoomed.Pump");

            A_PlaySound ("Weapons/ConquerorRifle/Pump1", CHAN_5);

            return ResolveState (null);
        }
        CQR1 EFG 1;
        CQR1 H   6 A_FireProjectile ("S7_45WWCasingSpawnRifle", 0, 0, 12, -14);
        CQR1 H   1 A_PlaySound ("Weapons/ConquerorRifle/Pump2", CHAN_5);
        CQR1 GFE 1;
        goto Ready2;

    Fire.Zoomed:
        TNT1 A 0 {
            A_GunFlash ("Flash.Zoomed");
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 0, 3.5);
            A_FireProjectile ("S7_ConquerorRifle_Tracer", fRandom [weaponSpread] (-0.005, 0.005), 1, 0, -1, 0, fRandom [weaponSpread] (-0.005, 0.005));

            if (invoker.noPump)
                A_FireProjectile ("S7_45WWCasingSpawnRifle", 0, 0, 8, -8);

            return ResolveState (null);
        }
    Fire.Anim.Zoomed:
        SCP1 B 1 {
            if (invoker.zoomLevel == 1)
                A_ZoomFactor (5.8);
            else if (invoker.zoomLevel == 2)
                A_ZoomFactor (11.7);
            else if (invoker.zoomLevel == 3)
                A_ZoomFactor (23.7);

            A_SetPitch (pitch - 1.5);
        }
        SCP1 B 1 A_SetPitch (pitch - 1.75);
        SCP1 B 1 {
            if (invoker.zoomLevel == 1)
                A_ZoomFactor (5.7);
            else if (invoker.zoomLevel == 2)
                A_ZoomFactor (11.8);
            else if (invoker.zoomLevel == 3)
                A_ZoomFactor (23.8);

            A_SetPitch (pitch + 0.15);
        }
        SCP1 B 1 {
            if (invoker.noPump) {
                invoker.loaded = true;
                if (random [weaponSpc] (0, 255) < 2)
                    invoker.jammed = true;
                else
                    invoker.jammed = false;
            }

            if (invoker.zoomLevel == 1)
                A_ZoomFactor (5.9);
            else if (invoker.zoomLevel == 2)
                A_ZoomFactor (11.9);
            else if (invoker.zoomLevel == 3)
                A_ZoomFactor (23.9);
            A_SetPitch (pitch + 0.15);
        }

        SCP1 BBBBB 1 A_WeaponReady (WRF_NoSecondary | WRF_DisableSwitch | WRF_NoBob);
        goto Ready2;
    Fire.Zoomed.Pump:
        SCP1 B 4 A_PlaySound ("Weapons/ConquerorRifle/Pump1", CHAN_5);
        SCP1 B 6 A_FireProjectile ("S7_45WWCasingSpawnRifle", 0, 0, 8, -8);
        SCP1 B 3 A_PlaySound ("Weapons/ConquerorRifle/Pump2", CHAN_5);
        goto Ready2;

    Fire.Jammed:
        CQR1 A 3 { // add an auto unjamming cvar later
            A_PlaySound ("Weapons/ConquerorRifle/DryFire", CHAN_7);

            if (invoker.zoomLevel > 0)
                return ResolveState ("Fire.Jammed.Zoomed");

            return ResolveState (null);
        }
        goto Ready2;
    Fire.Jammed.Zoomed:
        SCP1 B 3;
        goto Ready2;

    AltFire:
        TNT1 A 0 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire2");
            if (invoker.loaded)
                TakeInventory ("S7_ConquerorRifleClip", 1);

            if (invoker.zoomLevel > 0)
                return ResolveState ("Fire.Zoomed.Pump");
            else
                return ResolveState ("Fire.Pump");
        }

    DryFire:
        CQR1 A 3 {
            A_PlaySound ("Weapons/ConquerorRifle/DryFire", CHAN_7);

            if (invoker.zoomLevel > 0)
                return ResolveState ("DryFire.Zoomed");

            return ResolveState (null);
        }
        goto DryFire2;
    DryFire.Zoomed:
        SCP1 B 3;
        goto DryFire2;
    DryFire2:
        TNT1 A 0 A_JumpIfInventory ("S7_AutoReloading", 1, "Reload");
        goto Ready2;

    Reload.Zoomed:
        CQR1 A 10 {
            invoker.zoomLevel = 0;
            A_SetCrosshair (0);
            A_ZoomFactor (1.0, ZOOM_Instant);
            A_SetBlend ("00 00 00", 1.0, 8);
        }
        goto Reload;
    Reload:
        TNT1 A 0 {
            TakeInventory ("S7_Reloading", 1);

            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1))
                return ResolveState ("Ready2");

            if (invoker.zoomLevel > 0)
                return ResolveState ("Reload.Zoomed");

            int ammoAmount = min (FindInventory (invoker.ammoType1).maxAmount - CountInv (invoker.ammoType1), CountInv (invoker.ammoType2));
            if (ammoAmount <= 0)
                return ResolveState ("Ready2");

            GiveInventory (invoker.ammoType1, ammoAmount);
            TakeInventory (invoker.ammoType2, ammoAmount);

            return ResolveState ("ReloadFinish");
        }
    ReloadFinish:
        CQR1 A      2;
        CQR1 IJKLMN 2;
        TNT1 A      0 A_PlaySound ("Weapons/ConquerorRifle/Out", CHAN_6);
        CQR1 OPN    2;
        CQR1 N     12;
        TNT1 A      0 A_PlaySound ("Weapons/ConquerorRifle/In", CHAN_7);
        CQR1 QRN    2;
        CQR1 NMLKJI 2;
        CQR1 A      2;
        TNT1 A      0 A_JumpIf (!invoker.loaded, "ReloadFinish.Pump");
        goto Ready2;
    ReloadFinish.Pump:
        CQR1 A   1 {
            A_PlaySound ("Weapons/ConquerorRifle/Pump1", CHAN_5);

            invoker.loaded = true;
            if (random [weaponSpc] (0, 255) < 2)
                invoker.jammed = true;
            else
                invoker.jammed = false;
        }
        CQR1 EFG 1;
        CQR1 H   6 A_FireProjectile ("S7_45WWCasingSpawnRifle", 0, 0, 12, -14);
        CQR1 H   1 A_PlaySound ("Weapons/ConquerorRifle/Pump2", CHAN_5);
        CQR1 GFE 1;
        goto Ready2;

    // Muzzle flashes
    Flash:
        CQRF A 1 bright;
        stop;
    Flash.Zoomed:
        TNT1 A 1 bright;
        stop;
    }
}
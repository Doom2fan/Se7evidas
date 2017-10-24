version "3.1.0"

class S7_AntimatterGunClip : ammo {
    default {
        inventory.maxAmount 5;
        ammo.backpackMaxAmount 5;

        +inventory.ignoreSkill
    }
}

class S7_AntimatterGun : S7_BaseWeapon {
    default {
        tag "$ANTIMATTERGUN";
        inventory.pickupMessage "$ANTIMATTERGUN";
        weapon.ammoType1 "S7_AntimatterGunClip";
        weapon.ammoType2 "S7_AntimatterShells";
        weapon.ammoUse 1;
        weapon.ammoGive 0;
    }

    int zoomLevel;

    states {
    Spawn:
        GT5P A -1;
        loop;

    Ready:
        //GTX5 VWXYZA 1;
    Ready2:
        GTX5 A 0 A_JumpIf (invoker.zoomLevel >= 1, "Ready2.Zoom");
        goto Ready2.DoStuff;
    Ready2.Zoom:
        SCP1 C 0;
        goto Ready2.DoStuff;
    Ready2.DoStuff:
        #### # 1 {
            if (invoker.zoomLevel > 0)
                TakeInventory ("S7_DoMelee", 0x7FFFFFFF);

            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            if (CheckInventory ("S7_ChangeFireMode", 1))
                return ResolveState ("ChangeMode");

            A_WeaponReady (WRF_AllowZoom | (invoker.zoomLevel ? WRF_NoBob : 0));

            return ResolveState (null);
        }
        #### # 0 TakeInventory ("S7_HoldingZoom", 0x7FFFFFFF);
        goto Ready2;
    Ready2.HoldingZoom:
        #### # 1 A_WeaponReady (WRF_NoFire | WRF_NoSwitch);
        goto Ready2;

    Deselect:
        GTX5 A     1 {
            A_ZoomFactor (1.0, ZOOM_Instant);
            A_SetCrosshair (0);

            if (invoker.zoomLevel >= 1)
                return ResolveState ("Deselect.Zoom");

            return ResolveState (null);
        }
        GTX5 ZYXWV 1;
        goto Super::Deselect;
    Deselect.Zoom:
        GTX5 A 8 {
            invoker.zoomLevel = 0;
            A_SetBlend ("00 00 00", 1.0, 8);
        }
        goto Ready2;

    Fire:
        GTX5 A  1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_GunFlash ("Flash");
            A_AlertMonsters ();

            if (invoker.zoomLevel >= 1)
                return ResolveState ("Fire.Zoom");

            A_PlaySound ("Weapons/AntimatterGun/Fire", CHAN_Weapon);
            A_FireProjectile ("S7_AntimatterGun_Tracer_Strongest", 0.0, 1, 6, -2, 0, 0.0);

            A_SetPitch (pitch - 1.5, SPF_Interpolate);

            return ResolveState (null);
        }
        GTX5 D  1 A_SetPitch (pitch - 1.5, SPF_Interpolate);
        GTX5 B 12;
        GTX5 C  1;
        GTX5 D  1;
        GTX5 E  1;
        GTX5 A  5;
        goto Ready2;

    Fire.Zoomed:
        goto Ready2.Zoom;

    DryFire:
        GTX5 A 3 {
            A_PlaySound ("Weapons/AntimatterGun/DryFire", CHAN_7);

            if (invoker.zoomLevel >= 1)
                return ResolveState ("DryFire.Zoom");

            return ResolveState (null);
        }
        TNT1 A 0 A_JumpIfInventory ("S7_AutoReloading", 1, "Reload");
        goto Ready2;
    DryFire.Zoom:
        SCP1 C 3;
        TNT1 A 0 A_JumpIfInventory ("S7_AutoReloading", 1, "Reload");
        goto Ready2;

    Zoom:
        #### # 1 A_JumpIfInventory ("S7_HoldingZoom", 1, "Ready2.HoldingZoom");
        SCP1 C 8 {
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
        goto Ready2;
    Unzoom:
        GTX5 A 10 {
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

            return ResolveState (null);
        }
        goto Ready2;
    ToggleZoomLevel:
        SCP1 C 8 {
            A_SetCrosshair (99); // This is just to make sure

            if (invoker.zoomLevel == 1) {
                invoker.zoomLevel = 2;
                A_ZoomFactor (6.0);
            } else if (invoker.zoomLevel == 2) {
                invoker.zoomLevel = 3;
                A_ZoomFactor (8.5);
            } else {
                invoker.zoomLevel = 1;
                A_ZoomFactor (3.5);
            }
        }
        goto Ready2;

    Reload.Zoomed:
        GTX5 A 10 {
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
        goto Ready2;

    // Muzzle flashes
    Flash:
        GT5F A 1 bright;
        stop;
    Flash.Zoomed:
        TNT1 A 1 bright;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Tracer
//
//-------------------------------------------------------------------------------------------
class S7_AntimatterGun_Tracer_Trail : S7_TracerEffectsBase {
    default {
        scale 0.125;
    }

    states {
    Spawn:
        GT5R A 1 bright noDelay A_SetScale (scale.X, scale.X / 2);
    Loople:
        ---- A 1 bright A_FadeOut (0.2);
        wait;
    }
}

class S7_AntimatterGun_Tracer : S7_BaseTracer {
    int dmgMultiplier;
    property dmgMultiplier: dmgMultiplier;

    default {
        S7_BaseTracer.trueSpeed 150;
        S7_AntimatterGun_Tracer.dmgMultiplier 1;
        damageFunction (fRandom [weaponDamage] (1, 5) * 100 * (1 + dmgMultiplier / 4.0));
        damageType "AntimatterTracer";
        deathType "Antimatter";
        scale 0.125;
        missileType "S7_AntimatterGun_Tracer_Trail";
        decal "S7_AntimatterGun_Tracer_Decal";

        -bloodSplatter -noExtremeDeath -noDamageThrust
    }

    int dmg;

    states {
    Spawn:
        TNT1 A 0 noDelay A_SetScale (scale.X, scale.X / 2);
        goto Super::Spawn;
    Idle:
        GT5R A 1 bright;
        wait;

    Death:
    Crash:
    XDeath:
        TNT1 A 3 {
            dmg = ceil (350 * dmgMultiplier + fRandom [weaponDamage] (-1.5, 5.0) * (5 * dmgMultiplier));
            A_Explode (dmg, dmg, XF_HurtSource); // Replace with special explosion
        }
        stop;
    }
}

class S7_AntimatterGun_Tracer_Strongest_Trail : S7_AntimatterGun_Tracer_Trail { default { scale 0.125; } }
class S7_AntimatterGun_Tracer_Strongest : S7_AntimatterGun_Tracer {
    default {
        S7_BaseTracer.trueSpeed 175;
        S7_AntimatterGun_Tracer.dmgMultiplier 12;
        scale 0.125;
        missileType "S7_AntimatterGun_Tracer_Strongest_Trail";
        decal "S7_AntimatterGun_Tracer_Strongest_Decal";
    }
}
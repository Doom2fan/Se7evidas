/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

//-------------------------------------------------------------------------------------------
//
// A28 "Mars" Assault Rifle
//
//-------------------------------------------------------------------------------------------
class S7_AMGMag : Ammo {
    default {
        Inventory.MaxAmount 35;
        Ammo.BackpackMaxAmount 35;

        +INVENTORY.IGNORESKILL
    }
}

class S7_AMG : S7_BaseWeapon {
    default {
        Tag "$AMG";
        Inventory.PickupMessage "$AMG";
        Weapon.AmmoType1 "S7_AMGMag";
        Weapon.AmmoType2 "S7_762x39Cartridges";
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;
        S7_BaseWeapon.Icon "AMGGZ0";
        S7_BaseWeapon.ShortTag "$SHORTAMG";
        S7_BaseWeapon.BindSlot WpSlot_Medium;
    }

    const BASEZOOMFACTOR = 3.5;
    bool burstFire;
    int  burstCount;
    bool   zoomed;
    double zoomLevel;

    override void DoEffect () {
        Super.DoEffect ();

        fireModeIcon = burstFire ? FMI_BurstFire : FMI_FullAuto;
    }

    states {
    Spawn:
        AMGG Z -1;
        stop;

    Ready:
        TNT1 A 0 {
            invoker.burstCount = 0;
            invoker.zoomed = false;
        }
        AMGG TUVWXA 1;
    Ready2:
        AMGG A 0 A_JumpIf (invoker.zoomed, "Ready2.Zoom");
        goto Ready2.DoStuff;
    Ready2.Zoom:
        SCP1 A 0;
        goto Ready2.DoStuff;
    Ready2.DoStuff:
        #### # 1 {
            invoker.burstCount = 0;
            if (invoker.zoomed)
                TakeInventory ("S7_DoMelee", 0x7FFFFFFF);

            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            if (CheckInventory ("S7_ChangeFireMode", 1))
                return ResolveState ("ChangeMode");

            A_WeaponReady (WRF_AllowZoom | (invoker.zoomed ? WRF_NoBob : 0));

            return ResolveState (null);
        }
        #### # 0 TakeInventory ("S7_HoldingZoom", 0x7FFFFFFF);
        goto Ready2;
    Ready2.HoldingZoom:
        #### # 1 A_WeaponReady (WRF_NoFire | WRF_NoSwitch | (invoker.zoomed ? WRF_NoBob : 0));
        goto Ready2;

    Deselect:
        AMGG A 0 {
            A_SetCrosshair (0);
            invoker.burstCount = 0;

            if (invoker.zoomed)
                return ResolveState ("Deselect.Zoom");

            return ResolveState (null);
        }
        AMGG AXWVUT 1;
        goto TrueDeselect;
    Deselect.Zoom:
        AMGG A 8 {
            invoker.zoomed = false;
            A_SetBlend ("00 00 00", 1.0, 8);
            A_ZoomFactor (1.0, ZOOM_Instant);
        }
        goto Deselect;

    QuickMeleeDerp:
        TNT1 A 0 {
            TakeInventory ("S7_DoMelee", 0x7FFFFFFF);

            if (invoker.zoomed)
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        goto QuickMelee;

    Zoom:
        #### ######## 1 {
            if (!invoker.zoomed || !(player.cmd.buttons & BT_ZOOM))
                return ResolveState ("DoZoom");

            if (player.cmd.buttons & BT_ATTACK || player.cmd.buttons & BT_ALTATTACK)
                return ResolveState ("ChangeZoomLevel");

            return ResolveState (null);
        }
        goto ChangeZoomLevel;
    DoZoom:
        #### # 1 A_JumpIf (CheckInventory ("S7_HoldingZoom", 1), "Ready2.HoldingZoom");
        SCP1 A 8 {
            GiveInventory ("S7_HoldingZoom", 1);

            if (!invoker.zoomed) {
                invoker.zoomed = true;
                A_SetCrosshair (99);
                A_SetBlend ("00 00 00", 1.0, 8);
                A_ZoomFactor (BASEZOOMFACTOR + invoker.zoomLevel, ZOOM_Instant);
            } else
                return ResolveState ("Unzoom");

            return ResolveState (null);
        }
        goto Ready2;
    Unzoom:
        AMGG A 8 {
            invoker.zoomed = false;
            A_SetCrosshair (0);
            A_SetBlend ("00 00 00", 1.0, 8);
            A_ZoomFactor (1.0, ZOOM_Instant);
        }
        goto Ready2;
    ChangeZoomLevel:
        #### # 1 {
            if (!(player.cmd.buttons & BT_ZOOM))
                return ResolveState ("Ready2");

            if (player.cmd.buttons & BT_ATTACK) {
                invoker.zoomLevel = clamp (invoker.zoomLevel + 0.25, 0, 2.5);
                A_ZoomFactor (BASEZOOMFACTOR + invoker.zoomLevel);
            } else if (player.cmd.buttons & BT_ALTATTACK) {
                invoker.zoomLevel = clamp (invoker.zoomLevel - 0.25, 0, 2.5);
                A_ZoomFactor (BASEZOOMFACTOR + invoker.zoomLevel);
            }

            return ResolveState (null);
        }
        loop;
    ChangeZoomLevel.Delay:
        #### # 1 A_JumpIf (!(player.cmd.buttons & BT_ZOOM), "Ready2");
        goto ChangeZoomLevel;

    ChangeMode:
        #### # 1;
        #### # 5 {
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            if (invoker.burstFire)
                invoker.burstFire = false;
            else
                invoker.burstFire = true;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);

            return ResolveState (null);
        }
        goto Ready2;

    Fire:
        AMGG B 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/AMG/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();

            if (invoker.zoomed)
                return ResolveState ("Fire.Zoom");

            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 1, 3.5);
            A_FireProjectile ("S7_RifleCasingSpawn", 0, 0, 8, -6);
            A_FireProjectile ("S7_AMGTracer", fRandom [weaponSpread] (-0.14, 0.14), 1, 2, 0, 0, fRandom [weaponSpread] (-0.14, 0.14));

            S7_Recoil (-0.8);

            return ResolveState (null);
        }
        AMGG B 1 S7_Recoil (-0.8);
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

            A_ZoomFactor ((BASEZOOMFACTOR + invoker.zoomLevel) * .95);
            if (invoker.burstFire)
                S7_Recoil (-1);
            else
                S7_Recoil (-0.5);
        }
        SCP1 A 1 {
            if (invoker.burstFire)
                S7_Recoil (+0.42);
            else
                S7_Recoil (-0.5);
        }
        SCP1 A 1 {
            A_ZoomFactor (BASEZOOMFACTOR + invoker.zoomLevel);

            if (invoker.burstFire)
                return ResolveState ("Fire.Zoom.Burst");

            S7_Recoil (+0.42);
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
        TNT1 A  0 A_JumpIf (invoker.zoomed, "Flash.Zoom");
        AMGF AB 1 bright;
        stop;
    Flash.Zoom:
        TNT1 A 2 bright;
        stop;

    DryFire.Burst:
        AMGG C 2 {
            invoker.burstCount = 0;

            if (invoker.zoomed)
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

            if (invoker.zoomed)
                return ResolveState ("DryFire.Zoom");

            return ResolveState (null);
        }
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading"), "DryReload");
        goto Ready2;
    DryFire.Zoom:
        SCP1 A 3;
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading"), "DryReload");
        goto Ready2;

    DryReload:
        TNT1 A 0 GiveInventory ("S7_Reloading", 1);
    Reload:
        TNT1 A 0 {
            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1)) {
                TakeInventory ("S7_Reloading", 1);
                return ResolveState ("Ready2");
            }

            if (invoker.zoomed)
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
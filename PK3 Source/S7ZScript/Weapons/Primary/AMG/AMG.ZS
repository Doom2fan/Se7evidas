/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2019 Chronos "phantombeta" Ouroboros
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
        Inventory.PickupSound "Weapons/Pickup/Medium";

        Weapon.AmmoType1 'S7_AMGMag';
        Weapon.AmmoType2 'S7_762x39Cartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "AMGGZ0";
        S7_BaseWeapon.ShortTag "$SHORTAMG";
        S7_BaseWeapon.AmmoBuyData "A762", 1;
        S7_BaseWeapon.BindSlot WpSlot_Medium;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties true, 0.025;
        S7_BaseWeapon.EnchantmentPrice 750, 0.4, 1.15;
    }

    const BASEZOOMFACTOR = 5.5;
    const BURSTLENGTH = 3;
    bool burstFire;
    int  burstCount;
    bool   zoomed;
    double zoomLevel;

    bool selecting;
    bool whichFlash;

    override Vector2 DoSelectOffset_InitialOffset () { return (8, 6); }

    override void DoEffect () {
        Super.DoEffect ();

        if (Owner.player.ReadyWeapon == self) {
            let psp = Owner.player.FindPSprite (PSP_Weapon);

            if (psp && psp.sprite == GetSpriteIndex ('SCP1')) {
                Owner.A_WeaponOffset (0, 32);
            } else if (!selecting) {
                let offs = DoSelectOffset_InitialOffset ();
                Owner.A_WeaponOffset (offs.X, 32 + offs.Y);
            }
        }

        fireModeIcon = burstFire ? FMI_BurstFire : FMI_FullAuto;
    }

    double GetZoomFactor () {
        if (!zoomed)
            return 1.;

        return BASEZOOMFACTOR + zoomLevel;
    }

    action void HandleBurstRecoil (int burstCount, double mul = 1.) {
        S7_Recoil ((-1.6 / 3.) * burstCount * mul);
        A_ZoomFactor (invoker.GetZoomFactor ());
    }

    states {
    Spawn:
        AMGG Z -1;
        stop;

    Ready:
        TNT1 A 0 {
            invoker.burstCount = 0;
            invoker.zoomed = false;
            invoker.selecting = true;
        }
        AMGG A 1 DoSelectOffset ((72, 72), forceNoInterpolate: true);
        AMGG A 1 DoSelectOffset ((56, 56));
        AMGG A 1 DoSelectOffset ((40, 40));
        AMGG A 1 DoSelectOffset ((24, 24));
        AMGG A 1 DoSelectOffset (( 8,  8));
        AMGG A 1 DoSelectOffset (( 0,  0));
        TNT1 A 0 { invoker.selecting = false; }
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
                TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

            A_ZoomFactor (invoker.GetZoomFactor ());

            S7_WeaponReady ("Reload", "ChangeMode", wrFlags: WRF_AllowZoom | (invoker.zoomed ? WRF_NoBob : 0));;
        }
        #### # 0 TakeInventory ('S7_HoldingZoom', 0x7FFFFFFF);
        goto Ready2;
    Ready2.HoldingZoom:
        #### # 1 S7_WeaponReady ("Reload", "ChangeMode", wrFlags: WRF_NoFire | WRF_NoSwitch | (invoker.zoomed ? WRF_NoBob : 0));
        goto Ready2;

    Deselect:
        AMGG A 0 {
            invoker.selecting = true;
            A_SetCrosshair (0);
            invoker.burstCount = 0;

            if (health <= 0) {
                invoker.zoomed = false;
                return ResolveState ("Deselect.DEAD");
            }

            if (invoker.zoomed)
                return ResolveState ("Deselect.Zoom");

            return ResolveState (null);
        }
        AMGG A 1 DoSelectOffset (( 0,  0));
        AMGG A 1 DoSelectOffset (( 8,  8));
        AMGG A 1 DoSelectOffset ((24, 24));
        AMGG A 1 DoSelectOffset ((40, 40));
        AMGG A 1 DoSelectOffset ((56, 56));
        AMGG A 1 DoSelectOffset ((72, 72));
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
            TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

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
        #### # 1 A_JumpIf (CheckInventory ('S7_HoldingZoom', 1), "Ready2.HoldingZoom");
        SCP1 A 8 {
            GiveInventory ('S7_HoldingZoom', 1);

            if (!invoker.zoomed) {
                invoker.zoomed = true;
                A_SetCrosshair (99);
                A_SetBlend ("00 00 00", 1.0, 8);
                A_ZoomFactor (invoker.GetZoomFactor (), ZOOM_Instant);
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
            A_ZoomFactor (invoker.GetZoomFactor (), ZOOM_Instant);
        }
        goto Ready2;
    ChangeZoomLevel:
        #### # 1 {
            if (!(player.cmd.buttons & BT_ZOOM))
                return ResolveState ("Ready2");

            if (player.cmd.buttons & BT_ATTACK)
                invoker.zoomLevel = clamp (invoker.zoomLevel + 0.25, 0, BASEZOOMFACTOR * 1.5);
            else if (player.cmd.buttons & BT_ALTATTACK)
                invoker.zoomLevel = clamp (invoker.zoomLevel - 0.25, 0, BASEZOOMFACTOR * 1.5);

            A_ZoomFactor (invoker.GetZoomFactor ());

            return ResolveState (null);
        }
        loop;
    ChangeZoomLevel.Delay:
        #### # 1 A_JumpIf (!(player.cmd.buttons & BT_ZOOM), "Ready2");
        goto ChangeZoomLevel;

    ChangeMode:
        #### # 1;
        #### # 5 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            if (invoker.burstFire)
                invoker.burstFire = false;
            else
                invoker.burstFire = true;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);

            return ResolveState (null);
        }
        goto Ready2;

    Fire:
        AMGG B 1 bright {
            if (!invoker.CheckAmmo (PrimaryFire, false, true)) {
                if (!invoker.burstCount)
                    return ResolveState ("DryFire");
                else
                    return ResolveState ("DryFire.Burst");
            }

            A_PlaySound ("Weapons/AMG/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();

            if (invoker.zoomed)
                return ResolveState ("Fire.Zoom");

            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2, 3));
            S7_A_SpawnCasing ('S7_RifleCasing', (30, 10.5, 12), pitchOffs: -45, spread: (10, 15));
            S7_A_FireBullets ('S7_AMGTracer', spread: (.14, .14), offs: (10, 5, 8), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);

            if (!invoker.burstFire) {
                S7_Recoil (-.9);
                A_ZoomFactor (invoker.GetZoomFactor () * .98, ZOOM_Instant);
            } else if (invoker.burstCount >= BURSTLENGTH)
                HandleBurstRecoil (invoker.burstCount);
            else {
                S7_Recoil (-.05);
                double zoomFac = invoker.GetZoomFactor () * (1. - (.01 * (BURSTLENGTH - invoker.burstCount)));
                A_ZoomFactor (zoomFac, (invoker.burstCount < 1) ? ZOOM_Instant : 0);
            }

            return ResolveState (null);
        }
        AMGG B 1 {
            if (invoker.burstFire)
                return ResolveState ("Fire.Burst");

            S7_Recoil (-.9);
            A_ZoomFactor (.99);

            return ResolveState (null);
        }
        AMGG C 1 {
            S7_Recoil (+.3);
            A_ZoomFactor (1.);
        }
        AMGG C 1 A_Refire ();
        goto Ready2;

    Fire.Burst:
        AMGG C 1 {
            if (++invoker.burstCount < BURSTLENGTH)
                return ResolveState ("Fire");

            HandleBurstRecoil (invoker.burstCount);

            return ResolveState (null);
        }
        AMGG A 1 HandleBurstRecoil (invoker.burstCount);
        AMGG A 4 {
            invoker.burstCount = 0;
            A_ClearRefire (); // Gotta clear the refire manually.
        }
        goto Ready2;

    Fire.Zoom:
        SCP1 A 1 {
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 0, 4));
            S7_A_SpawnCasing ('S7_RifleCasing', (30, 8, 10), pitchOffs: -45, spread: (10, 15));
            S7_A_FireBullets ('S7_AMGTracer', spread: (.13, .13), offs: (10, 0, 5.5), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);

            if (!invoker.burstFire) {
                S7_Recoil (-0.5);
                A_ZoomFactor (invoker.GetZoomFactor () * .95);
            } else if (invoker.burstCount >= BURSTLENGTH)
                HandleBurstRecoil (invoker.burstCount, .625);
            else {
                S7_Recoil (-0.05);
                double zoomFac = invoker.GetZoomFactor () * (1. - (.025 * (BURSTLENGTH - invoker.burstCount)));
                A_ZoomFactor (zoomFac, (invoker.burstCount < 1) ? ZOOM_Instant : 0);
            }
        }
        SCP1 A 1 {
            if (invoker.burstFire)
                return ResolveState ("Fire.Zoom.Burst");

            S7_Recoil (-0.5);

            return ResolveState (null);
        }
        SCP1 A 1 A_ZoomFactor (invoker.GetZoomFactor ());
        SCP1 A 1 A_Refire ("Fire");
        goto Ready2;

    Fire.Zoom.Burst:
        SCP1 A 1 {
            if (++invoker.burstCount < BURSTLENGTH)
                return ResolveState ("Fire");

            HandleBurstRecoil (invoker.burstCount);

            return ResolveState (null);
        }
        SCP1 A 1 HandleBurstRecoil (invoker.burstCount);
        SCP1 A 4 {
            A_ZoomFactor (invoker.GetZoomFactor ());
            invoker.burstCount = 0;
            A_ClearRefire (); // Gotta clear the refire manually.
        }
        goto Ready2;

    Flash:
        TNT1 A 0 {
            if (invoker.zoomed)
                return ResolveState ("Flash.Zoom");
            else if (invoker.burstFire)
                return ResolveState ("Flash.Burst");

            return ResolveState (null);
        }
        AMGF A 1 bright {
            let psp = player.FindPSprite (PSP_Flash);

            if (psp)
                psp.frame = (invoker.whichFlash ? 1 : 0);

            invoker.whichFlash = !invoker.whichFlash;
        }
        stop;
    Flash.Burst:
        AMGF A 1 bright {
            let psp = player.FindPSprite (PSP_Flash);

            if (psp)
                psp.frame = ((invoker.burstCount & 1) ? 1 : 0);
        }
        stop;
    Flash.Zoom:
        TNT1 A 1 bright;
        stop;

    DryFire.Burst:
        AMGG C  1 {
            A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
            HandleBurstRecoil (invoker.burstCount);

            if (invoker.zoomed)
                return ResolveState ("DryFire.Burst.Zoom");

            return ResolveState (null);
        }
        AMGG AA 1 HandleBurstRecoil (invoker.burstCount);
        goto DryFire.Check;
    DryFire.Burst.Zoom:
        SCP1 AAA 1 HandleBurstRecoil (invoker.burstCount);
        goto DryFire.Check;
    DryFire:
        AMGG A 3 {
            A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
            invoker.burstCount = 0;

            if (invoker.zoomed)
                return ResolveState ("DryFire.Zoom");

            return ResolveState (null);
        }
        goto DryFire.Check;
    DryFire.Zoom:
        SCP1 A 3;
        goto DryFire.Check;
    DryFire.Check:
        TNT1 A 0 {
            invoker.burstCount = 0;

            return A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "DryReload");
        }
        goto Ready2;

    DryReload:
        TNT1 A 0 GiveInventory ('S7_Reloading', 1);
    Reload:
        TNT1 A 0 {
            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1)) {
                TakeInventory ('S7_Reloading', 1);
                return ResolveState ("Ready2");
            }

            if (invoker.zoomed)
                return ResolveState ("Unzoom");

            TakeInventory ('S7_Reloading', 1);

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
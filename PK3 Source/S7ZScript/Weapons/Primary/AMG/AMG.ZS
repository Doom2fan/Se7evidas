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
        //$Category "Se7evidas/Weapons"
        //$Color 14
        //$Title ""Mars" 7.62x39mm Assault Rifle"
        //$NotAngled

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
        S7_BaseWeapon.BindSlot S7_WpSlot_Medium;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties true, 0.025;
        S7_BaseWeapon.EnchantmentPrice 750, 0.4, 1.15;
    }

    const AnimLayer_ID = 2;
    const BaseZoomFactor = 5.5;
    const BurstLength = 3;
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
            let psp = Owner.player.FindPSprite (AnimLayer_ID);

            if (psp && psp.sprite == GetSpriteIndex ('SCP1')) {
                Owner.A_WeaponOffset (0, 32);
            } else if (!selecting) {
                let offs = DoSelectOffset_InitialOffset ();
                Owner.A_WeaponOffset (offs.X, 32 + offs.Y);
            }
        }

        fireModeIcon = burstFire ? S7_FMI_BurstFire : S7_FMI_FullAuto;
    }

    double GetZoomFactor () {
        if (!zoomed)
            return 1.;

        return BaseZoomFactor + zoomLevel;
    }

    action void S7_SetAnim (StateLabel animState) {
        S7_Internal_SetAnim (AnimLayer_ID, animState, 0, 0);
    }

    /** Pickup **/
    states {
    Spawn:
        AMGG Z -1;
        stop;
    }

    /** Animations **/
    states {
    Anim.Select:
        AMGG A 6;
        AMGG A 1;
        wait;
    Anim.Idle:
        AMGG A 1 {
            if (invoker.zoomed)
                S7_SetSprite ('SCP1', 0, AnimLayer_ID);
        }
        wait;
    Anim.Fire:
        AMGG B 1 bright A_JumpIf (invoker.zoomed, "Anim.FireZoom");
        AMGG B 1 A_JumpIf (invoker.burstFire, "Anim.Fire.Burst");
        AMGG C 2;
        goto Anim.Idle;
    Anim.Fire.Burst:
        AMGG C 1;
        AMGG A 5;
        goto Anim.Idle;
    Anim.FireZoom:
        SCP1 A 1 bright;
        SCP1 A 1 A_JumpIf (invoker.burstFire, "Anim.FireZoom.Burst");
        SCP1 A 2;
        goto Anim.Idle;
    Anim.FireZoom.Burst:
        SCP1 A 6;
        goto Anim.Idle;
    Anim.DryfireIdle:
        AMGG C 1 A_JumpIf (invoker.zoomed, "Anim.Idle");
        goto Anim.Idle;
    Anim.Reload:
        AMGG A         2;
        AMGR ABCDE     2;
        AMGR F         2 A_PlaySound ("Weapons/AMG/Out", CHAN_6);
        AMGR GHIJKLMNO 2;
        AMGR P         2 A_PlaySound ("Weapons/AMG/In", CHAN_7);
        AMGR QR        4;
        AMGR S         7 A_PlaySound ("Weapons/AMG/Tap", CHAN_6);
        AMGR TUVWXYA   2;
        AMGG A         2;
        goto Anim.Idle;
    }

    /** Actions **/
    states {
    Ready:
        TNT1 A 0 {
            invoker.burstCount = 0;
            invoker.zoomed = false;
            invoker.selecting = true;

            S7_SetAnim ("Anim.Select");
        }
        TNT1 A 1 DoSelectOffset ((72, 72), forceNoInterpolate: true);
        TNT1 A 1 DoSelectOffset ((56, 56));
        TNT1 A 1 DoSelectOffset ((40, 40));
        TNT1 A 1 DoSelectOffset ((24, 24));
        TNT1 A 1 DoSelectOffset (( 8,  8));
        TNT1 A 1 DoSelectOffset (( 0,  0));
        TNT1 A 0 { invoker.selecting = false; }
    Ready2:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");

            invoker.burstCount = 0;
            if (invoker.zoomed)
                TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

            A_ZoomFactor (invoker.GetZoomFactor ());

            S7_WeaponReady ("Reload", "ChangeMode", "QuickMeleeDerp", wrFlags: WRF_AllowZoom | (invoker.zoomed ? WRF_NoBob : 0));
        }
        goto Ready2;

    Deselect:
        AMGG A 0 {
            invoker.selecting = true;
            A_SetCrosshair (0);
            invoker.burstCount = 0;

            if (health <= 0) {
                invoker.zoomed = false;
                S7_SetAnim ("Null");
                return ResolveState ("Deselect.DEAD");
            }

            if (invoker.zoomed)
                return ResolveState ("Deselect.Zoom");

            S7_SetAnim ("Anim.Select");

            return ResolveState (null);
        }
        TNT1 A 1 DoSelectOffset (( 0,  0));
        TNT1 A 1 DoSelectOffset (( 8,  8));
        TNT1 A 1 DoSelectOffset ((24, 24));
        TNT1 A 1 DoSelectOffset ((40, 40));
        TNT1 A 1 DoSelectOffset ((56, 56));
        TNT1 A 1 DoSelectOffset ((72, 72));
        goto TrueDeselect;
    Deselect.Zoom:
        TNT1 A 8 {
            invoker.zoomed = false;

            S7_SetAnim ("Anim.Idle");

            A_SetBlend ("00 00 00", 1.0, 8);
            A_ZoomFactor (1.0, ZOOM_Instant);
        }
        goto Deselect;

    QuickMeleeDerp:
        TNT1 A 0 {
            TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

            if (invoker.zoomed)
                return ResolveState ("Ready2");

            S7_SetAnim ("Null");

            return ResolveState (null);
        }
        goto QuickMelee;
    }

    /** Zooming **/
    states {
    Zoom:
        TNT1 AAAAAAAA 1 {
            S7_SetAnim ("Anim.Idle");

            if (!invoker.zoomed || !(player.cmd.buttons & BT_Zoom))
                return ResolveState ("DoZoom");

            if (player.cmd.buttons & BT_Attack || player.cmd.buttons & BT_AltAttack)
                return ResolveState ("ChangeZoomLevel");

            return ResolveState (null);
        }
        goto ChangeZoomLevel;
    DoZoom:
        TNT1 A 8 {
            S7_SetAnim ("Anim.Idle");

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
        TNT1 A 8 {
            invoker.zoomed = false;

            S7_SetAnim ("Anim.Idle");

            A_SetCrosshair (0);
            A_SetBlend ("00 00 00", 1.0, 8);
            A_ZoomFactor (invoker.GetZoomFactor (), ZOOM_Instant);
        }
        goto Ready2;
    ChangeZoomLevel:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");

            if (!(player.cmd.buttons & BT_Zoom))
                return ResolveState ("Ready2");

            if (player.cmd.buttons & BT_Attack)
                invoker.zoomLevel = clamp (invoker.zoomLevel + 0.25, 0, BaseZoomFactor * 1.5);
            else if (player.cmd.buttons & BT_AltAttack)
                invoker.zoomLevel = clamp (invoker.zoomLevel - 0.25, 0, BaseZoomFactor * 1.5);

            A_ZoomFactor (invoker.GetZoomFactor ());

            return ResolveState (null);
        }
        loop;
    ChangeZoomLevel.Delay:
        TNT1 A 1 A_JumpIf (!(player.cmd.buttons & BT_Zoom), "Ready2");
        goto ChangeZoomLevel;
    }

    /** Fire mode change **/
    states {
    ChangeMode:
        TNT1 A 1 S7_SetAnim ("Anim.Idle");
        TNT1 A 5 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            if (invoker.burstFire)
                invoker.burstFire = false;
            else
                invoker.burstFire = true;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);

            return ResolveState (null);
        }
        goto Ready2;
    }

    /** Firing **/
    action void HandleBurstRecoil (int burstCount) {
        S7_Recoil ((-1.6 / 3.) * burstCount);
        A_ZoomFactor (invoker.GetZoomFactor ());
    }

    override void V_S7_Recoil (double amount) {
        Super.V_S7_Recoil (amount * (zoomed ? .5555 : 1.));
    }

    action state S7_DoFire () {
        if (!invoker.CheckAmmo (PrimaryFire, false, true)) {
            if (!invoker.burstCount)
                return ResolveState ("DryFire");
            else
                return ResolveState ("DryFire.Burst");
        }

        A_PlaySound ("Weapons/AMG/Fire", CHAN_Weapon);
        A_AlertMonsters ();
        A_GunFlash ();

        if (!invoker.zoomed) {
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2, 3));
            S7_A_SpawnCasing ('S7_RifleCasing', (30, 10.5, 12), pitchOffs: -45, spread: (10, 15));
            S7_A_FireBullets ('S7_AMGTracer', spread: (.14, .14), offs: (10, 5, 8), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);
        } else {
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 0, 4));
            S7_A_SpawnCasing ('S7_RifleCasing', (30, 8, 10), pitchOffs: -45, spread: (10, 15));
            S7_A_FireBullets ('S7_AMGTracer', spread: (.13, .13), offs: (10, 0, 5.5), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);
        }

        if (!invoker.burstFire) {
            S7_Recoil (-.9);
            A_ZoomFactor (invoker.GetZoomFactor () * .98, ZOOM_Instant);
        } else if (invoker.burstCount >= BurstLength)
            HandleBurstRecoil (invoker.burstCount);
        else {
            S7_Recoil (-.05);
            double mulFac = invoker.zoomed ? .025 : .01;
            double zoomFac = invoker.GetZoomFactor () * (1. - (mulFac * (BurstLength - invoker.burstCount)));
            A_ZoomFactor (zoomFac, (invoker.burstCount < 1) ? ZOOM_Instant : 0);
        }

        return ResolveState (null);
    }

    states {
    Fire:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Fire");
            return S7_DoFire ();
        }
        TNT1 A 1 {
            if (invoker.burstFire)
                return ResolveState ("Fire.Burst");

            S7_Recoil (-.9);
            A_ZoomFactor (invoker.GetZoomFactor () * .99);

            return ResolveState (null);
        }
        TNT1 A 1 {
            S7_Recoil (+.3);
            A_ZoomFactor (invoker.GetZoomFactor ());
        }
        TNT1 A 1 A_Refire ();
        goto Ready2;

    Fire.Burst:
        TNT1 A 1 {
            if (++invoker.burstCount < BurstLength)
                return ResolveState ("Fire");

            HandleBurstRecoil (invoker.burstCount);

            return ResolveState (null);
        }
        TNT1 A 1 HandleBurstRecoil (invoker.burstCount);
        TNT1 A 4 {
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
        TNT1 A  1 {
            S7_SetAnim ("Anim.DryfireIdle");

            A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
            HandleBurstRecoil (invoker.burstCount);
        }
        TNT1 AA 1 HandleBurstRecoil (invoker.burstCount);
        goto DryFire.Check;
    DryFire:
        TNT1 A 3 {
            S7_SetAnim ("Anim.Idle");

            A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
            invoker.burstCount = 0;
        }
        goto DryFire.Check;
    DryFire.Check:
        TNT1 A 0 {
            invoker.burstCount = 0;
            return A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "DryReload");
        }
        goto Ready2;
    }

    /** Reloading **/
    states {
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

            S7_SetAnim ("Anim.Reload");

            return ResolveState (null);
        }
        TNT1 A 1 {
            let psp = player.FindPSprite (AnimLayer_ID);
            if (psp && InStateSequence (psp.CurState, ResolveState ("Anim.Idle")))
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        wait;
    }
}
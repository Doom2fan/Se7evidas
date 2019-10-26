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
// MK17 "Conqueror" Anti-Materiel Sniper Rifle
//
//-------------------------------------------------------------------------------------------
class S7_ConquerorRifleClip : Ammo {
    default {
        Inventory.MaxAmount 15;
        Ammo.BackpackMaxAmount 15;

        +INVENTORY.IGNORESKILL
    }
}

class S7_ConquerorRifle : S7_BaseWeapon {
    default {
        //$Category "Se7evidas/Weapons"
        //$Color 14
        //$Title ""Conqueror" .45WW Sniper Rifle"
        //$NotAngled

        Tag "$CONQUERORSRIFLE";
        Inventory.PickupMessage "$CONQUERORSRIFLE";
        Inventory.PickupSound "Weapons/Pickup/Medium";

        Weapon.AmmoType1 'S7_ConquerorRifleClip';
        Weapon.AmmoType2 'S7_45WWCartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "CQRPA0";
        S7_BaseWeapon.ShortTag "$SHORTCONQUERORSRIFLE";
        S7_BaseWeapon.AmmoBuyData "A45W", 1;
        S7_BaseWeapon.BindSlot S7_WpSlot_Heavy;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties true, 0.015;
        S7_BaseWeapon.EnchantmentPrice 1350, 0.25, 1.209;
    }

    const BaseZoomFactor = 6.5;
    bool jammed, loaded, lastLoaded, semiAuto, noEject; // noEject is just for telling the reloading anim not to spawn casings
    bool zoomed;
    double zoomLevel;
    State pumpEndState;

    override void DoEffect () {
        Super.DoEffect ();

        fireModeIcon = semiAuto ? S7_FMI_SemiAuto : S7_FMI_None;
    }

    double GetZoomFactor () {
        if (!zoomed)
            return 1.;

        return BaseZoomFactor + zoomLevel;
    }

    action void S7_DoLoad () {
        invoker.lastLoaded = invoker.loaded;
        invoker.loaded = true;

        if (random [weaponSpc] () < 2)
            invoker.jammed = true;
        else
            invoker.jammed = false;
    }

    const AnimLayer_ID = 2;

    action void S7_SetAnim (StateLabel animState) {
        S7_Internal_SetAnim (AnimLayer_ID, animState, 0, 0);
    }

    /** Pickup **/
    states {
    Spawn:
        CQRP A -1;
        loop;
    }

    /** Animations **/
    states {
    Anim.Idle:
        CQR1 A 1 {
            if (invoker.zoomed)
                S7_SetSprite ('SCP1', 1, AnimLayer_ID);
        }
        wait;
    Anim.Handless:
        CQR1 N 1;
        wait;
    Anim.Pump:
        CQR1 A   1 A_JumpIf (invoker.zoomed, "Anim.Idle");
        CQR1 EFG 1;
        CQR1 H   7;
        CQR1 GFE 1;
        goto Anim.Idle;
    Anim.Fire:
        CQR1 A   1 bright A_JumpIf (invoker.zoomed, "Anim.FireZoom");
        CQR1 CB  1;
        CQR1 CDA 2;
        goto Anim.Idle;
    Anim.FireZoom:
        SCP1 B 1 bright;
        goto Anim.Idle;
    Anim.Reload:
        CQR1 A      2;
        CQR1 IJKLMN 2;
        TNT1 A      0 A_PlaySound ("Weapons/ConquerorRifle/Out", CHAN_6);
        CQR1 OPN    2;
        CQR1 N     12;
        TNT1 A      0 A_PlaySound ("Weapons/ConquerorRifle/In", CHAN_7);
        CQR1 QRN    2;
        CQR1 NMLKJI 2;
        CQR1 A      2;
        goto Anim.Idle;

    Anim.SelectHand:
        TNT1 A 1;
        HAN0 A 1 DoSelectOffset (( 61, 162), -5, true);
        HAN0 A 1 DoSelectOffset (( 91, 135), -5);
        HAN0 F 1 DoSelectOffset ((116, 122), -5);
        HAN0 F 1 DoSelectOffset ((132, 105), -5);
        stop;
    Anim.DeselectHand:
        HAN0 F 1 DoSelectOffset ((132, 105), -5, true);
        HAN0 F 1 DoSelectOffset ((116, 122), -5);
        HAN0 A 1 DoSelectOffset (( 91, 135), -5);
        HAN0 A 1 DoSelectOffset (( 61, 162), -5);
        TNT1 A 1;
        stop;
    }

    /** Actions **/
    states {
    Ready:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Handless");

            DoSelectOffset ((109, 77), forceNoInterpolate: true);
            A_Overlay (-5, "Anim.SelectHand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        TNT1 A 1 DoSelectOffset (( 82, 60));
        TNT1 A 1 DoSelectOffset (( 57, 43));
        TNT1 A 1 DoSelectOffset (( 34, 27));
        TNT1 A 1 DoSelectOffset (( 12, 15));
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");
            DoSelectOffset ((0, 0));
        }
    Ready2:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");

            if (invoker.zoomed)
                TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

            S7_WeaponReady ("Reload", "ChangeMode", "QuickMeleeDerp", wrFlags: WRF_AllowZoom | (invoker.zoomed ? WRF_NoBob : 0));
        }
        goto Ready2;

    Deselect:
        CQR1 A 0 {
            if (health <= 0) {
                invoker.zoomed = false;
                A_ZoomFactor (invoker.GetZoomFactor ());
                S7_SetAnim ("Null");
                return ResolveState ("Deselect.DEAD");
            }

            if (invoker.zoomed)
                return ResolveState ("Deselect.Zoom");

            return ResolveState (null);
        }
        TNT1 A 1 S7_SetAnim ("Anim.Idle");
        TNT1 A 1 {
            S7_SetAnim ("Anim.Handless");
            DoSelectOffset (( 12, 15), forceNoInterpolate: true);

            A_Overlay (-5, "Anim.DeselectHand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        TNT1 A 1 DoSelectOffset (( 34, 27));
        TNT1 A 1 DoSelectOffset (( 57, 43));
        TNT1 A 1 DoSelectOffset (( 82, 60));
        TNT1 A 1 DoSelectOffset ((109, 77));
        goto TrueDeselect;
    Deselect.Zoom:
        TNT1 A 8 {
            invoker.zoomed = false;

            S7_SetAnim ("Anim.Idle");

            A_SetBlend ("00 00 00", 1.0, 8);
            A_SetCrosshair (0);
            A_ZoomFactor (invoker.GetZoomFactor (), ZOOM_Instant);
        }
        goto Ready2;

    Zoom:
        TNT1 AAAAAAAA 1 {
            if (!invoker.zoomed || !(player.cmd.buttons & BT_Zoom))
                return ResolveState ("DoZoom");

            if (player.cmd.buttons & BT_Attack || player.cmd.buttons & BT_AltAttack)
                return ResolveState ("ChangeZoomLevel");

            S7_SetAnim ("Anim.Idle");

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
        TNT1 A 10 {
            S7_SetAnim ("Anim.Idle");

            invoker.zoomed = false;
            A_SetCrosshair (0);
            A_SetBlend ("00 00 00", 1.0, 8);
            A_ZoomFactor (invoker.GetZoomFactor (), ZOOM_Instant);
        }
        goto Ready2;
    ChangeZoomLevel:
        TNT1 A 1 {
            if (!(player.cmd.buttons & BT_Zoom))
                return ResolveState ("Ready2");

            S7_SetAnim ("Anim.Idle");

            if (player.cmd.buttons & BT_Attack) {
                invoker.zoomLevel = clamp (invoker.zoomLevel + 0.75, 0, 15);
                A_ZoomFactor (invoker.GetZoomFactor ());
            } else if (player.cmd.buttons & BT_AltAttack) {
                invoker.zoomLevel = clamp (invoker.zoomLevel - 0.75, 0, 15);
                A_ZoomFactor (invoker.GetZoomFactor ());
            }

            return ResolveState (null);
        }
        loop;
    ChangeZoomLevel.Delay:
        TNT1 A 1 A_JumpIf (!(player.cmd.buttons & BT_Zoom), "Ready2");
        goto ChangeZoomLevel;

    ChangeMode:
        TNT1 A 1 S7_SetAnim ("Anim.Idle");
        TNT1 A 5 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            if (invoker.semiAuto)
                invoker.semiAuto = false;
            else
                invoker.semiAuto = true;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);

            return ResolveState (null);
        }
        goto Ready2;

    Fire:
        TNT1 A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");
            if (!invoker.loaded) {
                if (invoker.Ammo1.Amount > 0)
                    S7_DoLoad ();

                invoker.pumpEndState = ResolveState ("Fire.PumpEnd");
                return ResolveState ("DoPump");
            }
            if (invoker.jammed)
                return ResolveState ("Fire.Jammed");

            S7_SetAnim ("Anim.Fire");

            A_AlertMonsters ();
            A_PlaySound ("Weapons/ConquerorRifle/Fire", CHAN_Weapon);
            invoker.loaded = false;

            Vector2 spread = (!invoker.zoomed ? (.05, .06) : (.005, .005));

            if (invoker.semiAuto)
                spread *= (!invoker.zoomed ? 1.75 : 2);

            if (!invoker.zoomed) {
                A_GunFlash ("Flash");
                S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2, 2.5));
                S7_A_FireBullets ('S7_ConquerorRifle_Tracer', spread: spread, offs: (10, 4.5, 4.5), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);

                if (invoker.semiAuto)
                    S7_A_SpawnCasing ('S7_45WWCasing', (30, 12, 17), pitchOffs: -45, spread: (10, 15));

                A_ZoomFactor (invoker.GetZoomFactor () * .975, ZOOM_Instant);
            } else {
                A_GunFlash ("Flash.Zoomed");
                S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 0, 3));
                S7_A_FireBullets ('S7_ConquerorRifle_Tracer', spread: spread, offs: (10, 0, 4.5), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);

                if (invoker.semiAuto)
                    S7_A_SpawnCasing ('S7_45WWCasing', (30, 8, 10), pitchOffs: -45, spread: (10, 15));

                A_ZoomFactor (invoker.GetZoomFactor () * .9, ZOOM_Instant);
            }

            S7_Recoil (-1.75);

            return ResolveState (null);
        }
        TNT1 A 1 {
            S7_Recoil (-1.5);
            if (!invoker.zoomed)
                A_ZoomFactor (invoker.GetZoomFactor () * .9833);
            else
                A_ZoomFactor (invoker.GetZoomFactor () * .95);
        }
        TNT1 A 1 {
            S7_Recoil (+.15);
            if (!invoker.zoomed)
                A_ZoomFactor (invoker.GetZoomFactor () * .991667);
            else
                A_ZoomFactor (invoker.GetZoomFactor () * .95);
        }
        TNT1 A 1 {
            if (invoker.semiAuto) {
                if (invoker.CheckAmmo (PrimaryFire, false, true))
                    S7_DoLoad ();
                else
                    invoker.noEject = true;
            } else
                invoker.noEject = false; // Reset noEject

            A_ZoomFactor (invoker.GetZoomFactor ());
        }
        TNT1 A 4;
        TNT1 A 1 { player.WeaponState |= WF_WeaponReady; }
        goto Ready2;
    Fire.PumpEnd:
        TNT1 A 0 { invoker.noEject = false; }
        goto Ready2;

    DoPump:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Pump");
            A_PlaySound ("Weapons/ConquerorRifle/Pump1", CHAN_5);
        }
        TNT1 A 3;
        TNT1 A 6 {
            if (invoker.noEject)
                return;

            Class<S7_CasingBase> casingType = 'S7_45WWCasing';
            if (invoker.lastLoaded)
                casingType = 'S7_45WWCasingUnfired';

            if (!invoker.zoomed)
                S7_A_SpawnCasing (casingType, (30, 14, 20), pitchOffs: -45, spread: (10, 15));
            else
                S7_A_SpawnCasing (casingType, (30,  8, 10), pitchOffs: -45, spread: (10, 15));
        }
        TNT1 A 1 A_PlaySound ("Weapons/ConquerorRifle/Pump2", CHAN_5);
        TNT1 A 3;
        TNT1 A 1 { return invoker.pumpEndState; }
        wait;

    Fire.Jammed:
        TNT1 A 3 { // Add an auto unjamming cvar later
            S7_SetAnim ("Anim.Idle");
            A_PlaySound ("Weapons/ConquerorRifle/DryFire", CHAN_7);
        }
        goto Ready2;

    AltFire:
        TNT1 A 0 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("Ready2");
            if (invoker.loaded) {
                TakeInventory ('S7_ConquerorRifleClip', 1);

                if (invoker.Ammo1.Amount < 1)
                    invoker.loaded = false;
                else if (invoker.Ammo1.Amount > 0)
                    S7_DoLoad ();
            }

            invoker.pumpEndState = ResolveState ("AltFire.PumpEnd");

            return ResolveState ("DoPump");
        }
    AltFire.PumpEnd:
        TNT1 A 0 { invoker.noEject = !invoker.loaded; }
        goto Ready2;

    DryFire:
        TNT1 A 3 {
            S7_SetAnim ("Anim.Idle");
            A_PlaySound ("Weapons/ConquerorRifle/DryFire", CHAN_7);
        }
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
        goto Ready2;

    Reload.Zoomed:
        TNT1 A 10 {
            S7_SetAnim ("Anim.Idle");

            invoker.zoomed = false;
            A_SetCrosshair (0);
            A_SetBlend ("00 00 00", 1.0, 8);
            A_ZoomFactor (invoker.GetZoomFactor (), ZOOM_Instant);
        }
        goto Reload;
    Reload:
        TNT1 A 0 {
            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1)) {
                TakeInventory ('S7_Reloading', 1);
                return ResolveState ("Ready2");
            }

            if (invoker.zoomed)
                return ResolveState ("Reload.Zoomed");

            int ammoAmount = min (FindInventory (invoker.ammoType1).maxAmount - CountInv (invoker.ammoType1), CountInv (invoker.ammoType2));
            if (ammoAmount <= 0) {
                TakeInventory ('S7_Reloading', 1);
                return ResolveState ("Ready2");
            }

            GiveInventory (invoker.ammoType1, ammoAmount);
            TakeInventory (invoker.ammoType2, ammoAmount);

            S7_SetAnim ("Anim.Reload");

            return ResolveState (null);
        }
        TNT1 A 1 {
            let psp = player.FindPSprite (AnimLayer_ID);
            if (psp && InStateSequence (psp.CurState, ResolveState ("Anim.Idle"))) {
                TakeInventory ('S7_Reloading', 1);
                if (invoker.loaded && !invoker.jammed)
                    return ResolveState ("Ready2");
                else {
                    S7_DoLoad ();
                    invoker.pumpEndState = ResolveState ("Reload.PumpEnd");
                    return ResolveState ("DoPump");
                }
            }

            return ResolveState (null);
        }
        wait;
    Reload.PumpEnd:
        TNT1 A 0 { invoker.noEject = false; }
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
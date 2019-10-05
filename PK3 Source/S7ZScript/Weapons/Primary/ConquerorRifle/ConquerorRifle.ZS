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
    bool jammed, loaded, noPump, noEject; // noEject is just for telling the reloading anim not to spawn casings
    bool zoomed;
    double zoomLevel;

    override void DoEffect () {
        Super.DoEffect ();

        fireModeIcon = noPump ? S7_FMI_SemiAuto : S7_FMI_None;
    }

    states {
    Spawn:
        CQRP A -1;
        loop;

    Select.Hand:
        TNT1 A 1;
        HAN0 A 1 DoSelectOffset (( 61, 162), -5, true);
        HAN0 A 1 DoSelectOffset (( 91, 135), -5);
        HAN0 F 1 DoSelectOffset ((116, 122), -5);
        HAN0 F 1 DoSelectOffset ((132, 105), -5);
        stop;
    Ready:
        CQR1 N 1 {
            DoSelectOffset ((109, 77), forceNoInterpolate: true);
            A_Overlay (-5, "Select.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        CQR1 N 1 DoSelectOffset (( 82, 60));
        CQR1 N 1 DoSelectOffset (( 57, 43));
        CQR1 N 1 DoSelectOffset (( 34, 27));
        CQR1 N 1 DoSelectOffset (( 12, 15));
        CQR1 A 1 DoSelectOffset ((  0,  0));
    Ready2:
        CQR1 A 0 A_JumpIf (invoker.zoomed, "Ready2.Zoom");
        goto Ready2.DoThings;
    Ready2.Zoom:
        SCP1 B 0;
        goto Ready2.DoThings;
    Ready2.DoThings:
        #### # 1 {
            if (invoker.zoomed)
                TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

            S7_WeaponReady ("Reload", "ChangeMode", wrFlags: WRF_AllowZoom | (invoker.zoomed ? WRF_NoBob : 0));
        }
        #### # 0 TakeInventory ('S7_HoldingZoom', 0x7FFFFFFF);
        goto Ready2;
    Ready2.HoldingZoom:
        #### # 1 S7_WeaponReady ("Reload", "ChangeMode", wrFlags: WRF_NoFire | WRF_NoSwitch | (invoker.zoomed ? WRF_NoBob : 0));
        goto Ready2;

    Zoom:
        #### ######## 1 {
            if (!invoker.zoomed || !(player.cmd.buttons & BT_Zoom))
                return ResolveState ("DoZoom");

            if (player.cmd.buttons & BT_Attack || player.cmd.buttons & BT_AltAttack)
                return ResolveState ("ChangeZoomLevel");

            return ResolveState (null);
        }
        goto ChangeZoomLevel;
    DoZoom:
        #### # 1 A_JumpIf (CheckInventory ('S7_HoldingZoom', 1), "Ready2.HoldingZoom");
        SCP1 B 8 {
            GiveInventory ('S7_HoldingZoom', 1);

            if (!invoker.zoomed) {
                invoker.zoomed = true;
                A_SetCrosshair (99);
                A_SetBlend ("00 00 00", 1.0, 8);
                A_ZoomFactor (BaseZoomFactor + invoker.zoomLevel, ZOOM_Instant);
            } else
                return ResolveState ("Unzoom");

            return ResolveState (null);
        }
        goto Ready2;
    Unzoom:
        CQR1 A 10 {
            invoker.zoomed = false;
            A_SetCrosshair (0);
            A_SetBlend ("00 00 00", 1.0, 8);
            A_ZoomFactor (1.0, ZOOM_Instant);
        }
        goto Ready2;
    ChangeZoomLevel:
        #### # 1 {
            if (!(player.cmd.buttons & BT_Zoom))
                return ResolveState ("Ready2");

            if (player.cmd.buttons & BT_Attack) {
                invoker.zoomLevel = clamp (invoker.zoomLevel + 0.75, 0, 15);
                A_ZoomFactor (BaseZoomFactor + invoker.zoomLevel);
            } else if (player.cmd.buttons & BT_AltAttack) {
                invoker.zoomLevel = clamp (invoker.zoomLevel - 0.75, 0, 15);
                A_ZoomFactor (BaseZoomFactor + invoker.zoomLevel);
            }

            return ResolveState (null);
        }
        loop;
    ChangeZoomLevel.Delay:
        #### # 1 A_JumpIf (!(player.cmd.buttons & BT_Zoom), "Ready2");
        goto ChangeZoomLevel;

    ChangeMode:
        #### # 1;
        #### # 5 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            if (invoker.noPump)
                invoker.noPump = 0;
            else
                invoker.noPump = 1;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);

            return ResolveState (null);
        }
        goto Ready2;

    Deselect.Hand:
        HAN0 F 1 DoSelectOffset ((132, 105), -5, true);
        HAN0 F 1 DoSelectOffset ((116, 122), -5);
        HAN0 A 1 DoSelectOffset (( 91, 135), -5);
        HAN0 A 1 DoSelectOffset (( 61, 162), -5);
        TNT1 A 1;
        stop;
    Deselect:
        CQR1 A 1 {
            if (health <= 0) {
                invoker.zoomed = false;
                return ResolveState ("Deselect.DEAD");
            }

            if (invoker.zoomed)
                return ResolveState ("Deselect.Zoom");

            A_SetCrosshair (0);

            return ResolveState (null);
        }
        CQR1 N 1 {
            DoSelectOffset (( 12, 15), forceNoInterpolate: true);
            A_Overlay (-5, "Deselect.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        CQR1 N 1 DoSelectOffset (( 34, 27));
        CQR1 N 1 DoSelectOffset (( 57, 43));
        CQR1 N 1 DoSelectOffset (( 82, 60));
        CQR1 N 1 DoSelectOffset ((109, 77));
        goto TrueDeselect;
    Deselect.Zoom:
        CQR1 A 8 {
            A_SetBlend ("00 00 00", 1.0, 8);
            A_SetCrosshair (0);
            A_ZoomFactor (1.0, ZOOM_Instant);
            invoker.zoomed = false;
        }
        goto Ready2;

    Fire:
        CQR1 A 1 bright {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");
            if (!invoker.loaded)
                return ResolveState ("Fire.Pump");
            if (invoker.jammed)
                return ResolveState ("Fire.Jammed");

            A_AlertMonsters ();
            A_PlaySound ("Weapons/ConquerorRifle/Fire", CHAN_Weapon);
            invoker.loaded = false;

            if (invoker.zoomed)
                return ResolveState ("Fire.Zoomed");

            A_GunFlash ("Flash");

            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2, 2.5));

            Vector2 spread = (.05, .06);

            if (invoker.noPump)
                spread *= 1.75;

            S7_A_FireBullets ('S7_ConquerorRifle_Tracer', spread: spread, offs: (10, 4.5, 4.5), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);

            if (invoker.noPump)
                S7_A_SpawnCasing ('S7_45WWCasing', (30, 12, 17), pitchOffs: -45, spread: (10, 15));

            S7_Recoil (-1.5);

            return ResolveState (null);
        }
        CQR1 C 1 S7_Recoil (-1.75);
        CQR1 B 1 S7_Recoil (0.15);
        CQR1 C 1 {
            if (invoker.noPump) {
                if (invoker.CheckAmmo (PrimaryFire, false, true)) {
                    invoker.loaded = true;

                    if (random [weaponSpc] () < 2)
                        invoker.jammed = true;
                    else
                        invoker.jammed = false;
                } else
                    invoker.noEject = true;
            } else
                invoker.noEject = false; // Reset noEject
        }

        CQR1 CDDAA 1 { player.WeaponState |= WF_WeaponReady; }
        goto Ready2;
    Fire.Pump:
        CQR1 A   1 {
            if (invoker.Ammo1.Amount > 0) {
                invoker.loaded = true;
                invoker.noEject = false; // Reset noEject

                if (random [weaponSpc] () < 2)
                    invoker.jammed = true;
                else
                    invoker.jammed = false;
            }

            if (invoker.zoomed)
                return ResolveState ("Fire.Zoomed.Pump");

            A_PlaySound ("Weapons/ConquerorRifle/Pump1", CHAN_5);

            return ResolveState (null);
        }
        CQR1 EFG 1;
        CQR1 H   6 S7_A_SpawnCasing ('S7_45WWCasing', (30, 14, 20), pitchOffs: -45, spread: (10, 15));
        CQR1 H   1 A_PlaySound ("Weapons/ConquerorRifle/Pump2", CHAN_5);
        CQR1 GFE 1;
        goto Ready2;

    Fire.Zoomed:
        TNT1 A 0 {
            A_GunFlash ("Flash.Zoomed");
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 0, 3));

            Vector2 spread = (.005, .005);

            if (invoker.noPump)
                spread *= 2;

            S7_A_FireBullets ('S7_ConquerorRifle_Tracer', spread: spread, offs: (10, 0, 4.5), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);

            if (invoker.noPump)
                S7_A_SpawnCasing ('S7_45WWCasing', (30, 8, 10), pitchOffs: -45, spread: (10, 15));

            return ResolveState (null);
        }
    Fire.Anim.Zoomed:
        SCP1 B 1 {
            A_ZoomFactor ((BaseZoomFactor + invoker.zoomLevel) * .9);
            S7_Recoil (-1.5);
        }
        SCP1 B 1 S7_Recoil (-1.75);
        SCP1 B 1 {
            A_ZoomFactor ((BaseZoomFactor + invoker.zoomLevel) * .95);

            S7_Recoil (0.15);
        }
        SCP1 B 1 {
            if (invoker.noPump) {
                if (invoker.CheckAmmo (PrimaryFire, false, true)) {
                    invoker.loaded = true;

                    if (random [weaponSpc] () < 2)
                        invoker.jammed = true;
                    else
                        invoker.jammed = false;
                } else
                    invoker.noEject = true;
            } else
                invoker.noEject = false; // Reset noEject

            A_ZoomFactor (BaseZoomFactor + invoker.zoomLevel);
            S7_Recoil (0.15);
        }

        SCP1 BBBBB 1 { player.WeaponState |= WF_WeaponReady; }
        goto Ready2;
    Fire.Zoomed.Pump:
        SCP1 B 4 A_PlaySound ("Weapons/ConquerorRifle/Pump1", CHAN_5);
        SCP1 B 6 S7_A_SpawnCasing ('S7_45WWCasing', (30, 8, 10), pitchOffs: -45, spread: (10, 15));
        SCP1 B 3 A_PlaySound ("Weapons/ConquerorRifle/Pump2", CHAN_5);
        goto Ready2;

    Fire.Jammed:
        CQR1 A 3 { // Add an auto unjamming cvar later
            A_PlaySound ("Weapons/ConquerorRifle/DryFire", CHAN_7);

            if (invoker.zoomed)
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
                return ResolveState ("Ready2");
            if (invoker.loaded) {
                TakeInventory ('S7_ConquerorRifleClip', 1);

                if (invoker.Ammo1.Amount < 1) {
                    invoker.loaded = false;
                    invoker.noEject = true;
                }
            }

            return ResolveState ("Fire.Pump");
        }

    DryFire:
        CQR1 A 3 {
            A_PlaySound ("Weapons/ConquerorRifle/DryFire", CHAN_7);

            if (invoker.zoomed)
                return ResolveState ("DryFire.Zoomed");

            return ResolveState (null);
        }
        goto DryFire2;
    DryFire.Zoomed:
        SCP1 B 3;
        goto DryFire2;
    DryFire2:
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
        goto Ready2;

    Reload.Zoomed:
        CQR1 A 10 {
            invoker.zoomed = false;
            A_SetCrosshair (0);
            A_ZoomFactor (1.0, ZOOM_Instant);
            A_SetBlend ("00 00 00", 1.0, 8);
        }
        goto Reload;
    Reload:
        TNT1 A 0 {
            TakeInventory ('S7_Reloading', 1);

            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1))
                return ResolveState ("Ready2");

            if (invoker.zoomed)
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

            if (random [weaponSpc] () < 2)
                invoker.jammed = true;
            else
                invoker.jammed = false;
        }
        CQR1 EFG 1;
        CQR1 H   6 {
            if (!invoker.noEject)
                S7_A_SpawnCasing ('S7_45WWCasing', (30, 14, 20), pitchOffs: -45, spread: (10, 15));

            invoker.noEject = false; // Reset noEject
        }
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
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

        Weapon.AmmoType1 'S7_ConquerorRifleClip';
        Weapon.AmmoType2 'S7_45WWCartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "CQRPA0";
        S7_BaseWeapon.ShortTag "$SHORTCONQUERORSRIFLE";
        S7_BaseWeapon.BindSlot WpSlot_Heavy;
        S7_BaseWeapon.UsesMag true;
    }

    const BASEZOOMFACTOR = 4.5;
    bool jammed, loaded, noPump, noEject; // noEject is just for telling the reloading anim not to spawn casings
    bool zoomed;
    double zoomLevel;

    override void DoEffect () {
        Super.DoEffect ();

        fireModeIcon = noPump ? FMI_SemiAuto : FMI_None;
    }

    states {
    Spawn:
        CQRP A -1;
        loop;

    Ready:
        CQR1 VWXYZA 1;
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

            if (CheckInventory ('S7_Reloading', 1))
                return ResolveState ("Reload");
            if (CheckInventory ('S7_DoMelee', 1))
                return ResolveState ("QuickMelee");
            if (CheckInventory ('S7_ChangeFireMode', 1))
                return ResolveState ("ChangeMode");

            A_WeaponReady (WRF_AllowZoom | (invoker.zoomed ? WRF_NoBob : 0));

            return ResolveState (null);
        }
        #### # 0 TakeInventory ('S7_HoldingZoom', 0x7FFFFFFF);
        goto Ready2;
    Ready2.HoldingZoom:
        #### # 1 A_WeaponReady (WRF_NoFire | WRF_NoSwitch | (invoker.zoomed ? WRF_NoBob : 0));
        goto Ready2;

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
        SCP1 B 8 {
            GiveInventory ('S7_HoldingZoom', 1);

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
        CQR1 A 10 {
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
                invoker.zoomLevel = clamp (invoker.zoomLevel + 0.75, 0, 16);
                A_ZoomFactor (BASEZOOMFACTOR + invoker.zoomLevel);
            } else if (player.cmd.buttons & BT_ALTATTACK) {
                invoker.zoomLevel = clamp (invoker.zoomLevel - 0.75, 0, 16);
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
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            if (invoker.noPump)
                invoker.noPump = 0;
            else
                invoker.noPump = 1;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);

            return ResolveState (null);
        }
        goto Ready2;

    Deselect:
        CQR1 A     1 {
            if (invoker.zoomed)
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
            invoker.zoomed = false;
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

            if (invoker.zoomed)
                return ResolveState ("Fire.Zoomed");

            A_GunFlash ("Flash");
            A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 2, 4);
            A_FireProjectile ('S7_ConquerorRifle_Tracer', fRandom [weaponSpread] (-0.05, 0.05), true, 6, -2, 0, fRandom [weaponSpread] (-0.06, 0.06));

            if (invoker.noPump)
                A_FireProjectile ('S7_45WWCasingSpawnRifle', 0, false, 10, -12);

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
            invoker.loaded = true;
            invoker.noEject = false; // Reset noEject

            if (random [weaponSpc] () < 2)
                invoker.jammed = true;
            else
                invoker.jammed = false;

            if (invoker.zoomed)
                return ResolveState ("Fire.Zoomed.Pump");

            A_PlaySound ("Weapons/ConquerorRifle/Pump1", CHAN_5);

            return ResolveState (null);
        }
        CQR1 EFG 1;
        CQR1 H   6 A_FireProjectile ('S7_45WWCasingSpawnRifle', 0, false, 12, -14);
        CQR1 H   1 A_PlaySound ("Weapons/ConquerorRifle/Pump2", CHAN_5);
        CQR1 GFE 1;
        goto Ready2;

    Fire.Zoomed:
        TNT1 A 0 {
            A_GunFlash ("Flash.Zoomed");
            A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 0, 3.5);
            A_FireProjectile ('S7_ConquerorRifle_Tracer', fRandom [weaponSpread] (-0.005, 0.005), true, 0, -1, 0, fRandom [weaponSpread] (-0.005, 0.005));

            if (invoker.noPump)
                A_FireProjectile ('S7_45WWCasingSpawnRifle', 0, false, 8, -8);

            return ResolveState (null);
        }
    Fire.Anim.Zoomed:
        SCP1 B 1 {
            A_ZoomFactor ((BASEZOOMFACTOR + invoker.zoomLevel) * .9);
            S7_Recoil (-1.5);
        }
        SCP1 B 1 S7_Recoil (-1.75);
        SCP1 B 1 {
            A_ZoomFactor ((BASEZOOMFACTOR + invoker.zoomLevel) * .95);

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

            A_ZoomFactor (BASEZOOMFACTOR + invoker.zoomLevel);
            S7_Recoil (0.15);
        }

        SCP1 BBBBB 1 { player.WeaponState |= WF_WeaponReady; }
        goto Ready2;
    Fire.Zoomed.Pump:
        SCP1 B 4 A_PlaySound ("Weapons/ConquerorRifle/Pump1", CHAN_5);
        SCP1 B 6 A_FireProjectile ('S7_45WWCasingSpawnRifle', 0, false, 8, -8);
        SCP1 B 3 A_PlaySound ("Weapons/ConquerorRifle/Pump2", CHAN_5);
        goto Ready2;

    Fire.Jammed:
        CQR1 A 3 { // add an auto unjamming cvar later
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
                return ResolveState ("DryFire2");
            if (invoker.loaded)
                TakeInventory ('S7_ConquerorRifleClip', 1);

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
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading"), "Reload");
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
                A_FireProjectile ('S7_45WWCasingSpawnRifle', 0, false, 12, -14);

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
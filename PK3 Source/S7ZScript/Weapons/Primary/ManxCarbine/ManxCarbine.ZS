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
// C23 "Manx" Carbine
//
//-------------------------------------------------------------------------------------------
class S7_ManxCarbineClip : Ammo {
    default {
        Inventory.MaxAmount 23;
        Ammo.BackpackMaxAmount 23;

        +INVENTORY.IGNORESKILL
    }
}

class S7_ManxCarbine : S7_BaseWeapon {
    default {
        Tag "$MANXCARBINE";
        Inventory.PickupMessage "$MANXCARBINE";

        Weapon.AmmoType1 'S7_ManxCarbineClip';
        Weapon.AmmoType2 'S7_9mmCartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "MNXPA0";
        S7_BaseWeapon.ShortTag "$SHORTMANXCARBINE";
        S7_BaseWeapon.BindSlot WpSlot_Medium;
        S7_BaseWeapon.UsesMag true;
    }

    const MANX_SCOPEOVERLAY_ID      = 20;
    const MANX_SUPPRESSOROVERLAY_ID = 21;
    bool hasScope;
    bool hasSuppressor;

    bool semiAuto;

    const BASEZOOMFACTOR = 2.0;
    bool   zoomed;
    double zoomLevel;

    override void Tick () {
        Super.Tick ();
        
        if (!self)
            return;

        if (hasScope && hasSuppressor)
            weapIcon = "MNXPD0";
        else if (hasSuppressor)
            weapIcon = "MNXPC0";
        else if (hasScope)
            weapIcon = "MNXPB0";
        else
            weapIcon = "MNXPA0";
    }

    override void DoEffect () {
        Super.DoEffect ();

        fireModeIcon = semiAuto ? FMI_SemiAuto : FMI_FullAuto;
    }

    override bool SS_PreSell (int amount) {
        if (hasScope) {
            if (!Owner.CheckInventory ('S7_ManxScope', 0))
                Owner.GiveInventory ('S7_ManxScope', 1);
            else
                DropAmmo ('S7_ManxScope', Owner, 1);

            hasScope = false;
        }

        if (hasSuppressor) {
            if (!Owner.CheckInventory ('S7_ManxSuppressor', 0))
                Owner.GiveInventory ('S7_ManxSuppressor', 1);
            else
                DropAmmo ('S7_ManxSuppressor', Owner, 1);

            hasSuppressor = false;
        }

        return true;
    }

    action void Manx_RunOverlay (int id, name sprite, bool showOverlay) {
        let pspWeap = player.FindPSprite (PSP_Weapon);
        let pspOverlay = player.FindPSprite (id);

        if (!pspWeap || !pspOverlay)
            return;

        if (showOverlay && pspWeap.sprite == GetSpriteIndex ('MANX')) {
            pspOverlay.sprite = GetSpriteIndex (sprite);
            pspOverlay.frame = pspWeap.frame;
        } else {
            pspOverlay.sprite = GetSpriteIndex ('TNT1');
            pspOverlay.frame = 0;
        }
    }

    states {
    Spawn:
        MNXP A 1 {
            if (invoker.hasScope && invoker.hasSuppressor)
                frame = 3;
            else if (invoker.hasSuppressor)
                frame = 2;
            else if (invoker.hasScope)
                frame = 1;
            else
                frame = 0;
        }
        loop;

    Ready:
        TNT1 A 0 {
            A_Overlay (MANX_SCOPEOVERLAY_ID     , "Overlay.Scope"     );
            A_Overlay (MANX_SUPPRESSOROVERLAY_ID, "Overlay.Suppressor");
        }
        MANX TUVWXA 1;
    Ready2:
        MANX A 1 {
            int flagsWR = 0;
            if (invoker.hasScope)
                flagsWR |= WRF_AllowZoom;

            S7_WeaponReady ("Reload", "ChangeMode", wrFlags: flagsWR);

            return ResolveState (null);
        }
        loop;
    Ready2:
        MANX A 0 A_JumpIf (invoker.zoomed, "Ready2.Zoom");
        goto Ready2.DoStuff;
    Ready2.Zoom:
        SCP1 D 0;
        goto Ready2.DoStuff;
    Ready2.DoStuff:
        #### # 1 {
            if (invoker.zoomed)
                TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

            int flagsWR = 0;
            if (invoker.hasScope)
                flagsWR |= WRF_AllowZoom;
            if (invoker.zoomed)
                flagsWR |= WRF_NoBob;

            S7_WeaponReady ("Reload", "ChangeMode", wrFlags: flagsWR);

            return ResolveState (null);
        }
        #### # 0 TakeInventory ('S7_HoldingZoom', 0x7FFFFFFF);
        goto Ready2;
    Ready2.HoldingZoom:
        #### # 1 S7_WeaponReady ("Reload", "ChangeMode", wrFlags: WRF_NoFire | WRF_NoSwitch | (invoker.zoomed ? WRF_NoBob : 0));
        goto Ready2;

    Overlay.Scope:
        MNX2 A 1 Manx_RunOverlay (MANX_SCOPEOVERLAY_ID, 'MNX2', invoker.hasScope);
        loop;
    Overlay.Suppressor:
        MNX3 A 1 Manx_RunOverlay (MANX_SUPPRESSOROVERLAY_ID, 'MNX3', invoker.hasSuppressor);
        loop;

    Deselect:
        TNT1 A 0 {
            A_SetCrosshair (0);

            if (invoker.zoomed)
                return ResolveState ("Deselect.Zoom");

            return ResolveState (null);
        }
        MANX AXWVUT 1;
        TNT1 A 0 {
            A_Overlay (MANX_SCOPEOVERLAY_ID     , "Null");
            A_Overlay (MANX_SUPPRESSOROVERLAY_ID, "Null");
        }
        goto TrueDeselect;
    Deselect.Zoom:
        MANX A 8 {
            invoker.zoomed = false;
            A_SetBlend ("00 00 00", 1.0, 8);
            A_ZoomFactor (1.0, ZOOM_Instant);
        }
        goto Deselect;

    Fire:
        MANX A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            if (!invoker.hasSuppressor) {
                A_PlaySound ("Weapons/ManxCarbine/Fire", CHAN_Weapon);
                A_AlertMonsters ();
                A_GunFlash ();
            } else {
                A_PlaySound ("Weapons/ManxCarbine/Fire", CHAN_Weapon, volume: 0.4);
                A_AlertMonsters (512.0);
            }

            if (invoker.zoomed)
                return ResolveState ("Fire.Zoom");

            if (!invoker.hasSuppressor)
                A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 3.75, 1.75);
            else
                A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 2.25, 3.15);

            A_FireProjectile ('S7_9mmCasingSpawn', 0, false, 15, -9);
            A_FireProjectile ('S7_ManxCarbineTracer', fRandom [weaponSpread] (-0.25, 0.25), true, 6, -3, 0, fRandom [weaponSpread] (-0.25, 0.25));

            S7_Recoil (-0.3);

            return ResolveState (null);
        }
        MANX B 1 S7_Recoil (-0.3);
        MANX C 1 A_JumpIf (invoker.semiAuto, "Fire.Semi");
        MANX A 1;
        MANX A 1 A_Refire;
        MANX A 3;
        goto Ready2;
    Fire.Semi:
        MANX C    1;
        MANX AAAA 1 { player.WeaponState |= WF_WeaponReady; }
        MANX A    2;
        goto Ready2;

    Fire.Zoom:
        SCP1 D 1 {
            A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 0, 0);
            A_FireProjectile ('S7_9mmCasingSpawn', 0, false, 8, -8);
            A_FireProjectile ('S7_ManxCarbineTracer', fRandom [weaponSpread] (-0.24, 0.24), true, 0, -3, 0, fRandom [weaponSpread] (-0.24, 0.24));

            A_ZoomFactor ((BASEZOOMFACTOR + invoker.zoomLevel) * .95);
            S7_Recoil (-0.3);
        }
        SCP1 D 1 {
            A_ZoomFactor ((BASEZOOMFACTOR + invoker.zoomLevel) * .975);
            S7_Recoil (-0.3);
        }
        SCP1 D 1 {
            A_ZoomFactor (BASEZOOMFACTOR + invoker.zoomLevel);
            return A_JumpIf (invoker.semiAuto, "Fire.Zoom.Semi");
        }
        SCP1 D 1;
        SCP1 D 1 A_Refire;
        SCP1 D 3;
        goto Ready2;
    Fire.Zoom.Semi:
        SCP1 D    1;
        SCP1 DDDD 1 { player.WeaponState |= WF_WeaponReady; }
        SCP1 D    2;
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
        SCP1 D 8 {
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
        MANX A 8 {
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
                invoker.zoomLevel = clamp (invoker.zoomLevel + 0.2, 0, 2.0);
                A_ZoomFactor (BASEZOOMFACTOR + invoker.zoomLevel);
            } else if (player.cmd.buttons & BT_ALTATTACK) {
                invoker.zoomLevel = clamp (invoker.zoomLevel - 0.2, 0, 2.0);
                A_ZoomFactor (BASEZOOMFACTOR + invoker.zoomLevel);
            }

            return ResolveState (null);
        }
        loop;
    ChangeZoomLevel.Delay:
        #### # 1 A_JumpIf (!(player.cmd.buttons & BT_ZOOM), "Ready2");
        goto ChangeZoomLevel;

    ChangeMode:
        #### # 5 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            if (invoker.semiAuto)
                invoker.semiAuto = false;
            else
                invoker.semiAuto = true;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);
        }
        goto Ready2;

    DryFire:
        MANX A 3 {
            A_PlaySound ("Weapons/DryFireSMG", CHAN_7);

            if (invoker.zoomed)
                return ResolveState ("DryFire.Zoom");

            return ResolveState (null);
        }
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "DryReload");
        goto Ready2;
    DryFire.Zoom:
        SCP1 D 3;
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "DryReload");
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
        MANX ADEFG 2;
        MANX H     6;
        MANX IJ    1;
        MANX KL    2;
        MANX M     2 A_PlaySound ("Weapons/ManxCarbine/In", CHAN_6);
        MANX NO    2;
        MANX PQEDA 2;
        goto Ready2;

    // Muzzle flashes
    Flash:
        MNXF A 1 bright A_JumpIf (invoker.zoomed, "Flash.Zoom");
        stop;
    Flash.Zoom:
        TNT1 A 1 bright;
        stop;
    }
}
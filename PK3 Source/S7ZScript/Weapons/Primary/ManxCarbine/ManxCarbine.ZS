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
// C23 "Manx" Carbine
//
//-------------------------------------------------------------------------------------------
class S7_ManxCarbineClip : Ammo {
    default {
        Inventory.MaxAmount 32;
        Ammo.BackpackMaxAmount 32;

        +INVENTORY.IGNORESKILL
    }
}

class S7_ManxCarbine : S7_BaseWeapon {
    default {
        Tag "$MANXCARBINE";
        Inventory.PickupMessage "$MANXCARBINE";
        Inventory.PickupSound "Weapons/Pickup/Small";

        Weapon.AmmoType1 'S7_ManxCarbineClip';
        Weapon.AmmoType2 'S7_9mmCartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "MNXPA0";
        S7_BaseWeapon.ShortTag "$SHORTMANXCARBINE";
        S7_BaseWeapon.AmmoBuyData "A9MM", 1;
        S7_BaseWeapon.BindSlot S7_WpSlot_Medium;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties true, 0.025;
        S7_BaseWeapon.EnchantmentPrice 600, 0.4, 1.16;
    }

    const AnimLayer_ID              =  2;
    const Manx_ScopeOverlay_ID      = 20;
    const Manx_SuppressorOverlay_ID = 21;
    bool hasScope;
    bool hasSuppressor;

    bool semiAuto;
    bool fireSoundChannel;

    const BaseZoomFactor = 3.0;
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

        fireModeIcon = semiAuto ? S7_FMI_SemiAuto : S7_FMI_FullAuto;
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

    action state Manx_RunOverlay (int id, name sprite, bool showOverlay) {
        let pspWeap = player.FindPSprite (AnimLayer_ID);
        let pspOverlay = player.FindPSprite (id);

        if (!pspOverlay)
            return ResolveState ("Null");

        if (!pspWeap) {
            pspOverlay.sprite = GetSpriteIndex ('TNT1');
            pspOverlay.frame = 0;
            return ResolveState (null);
        }

        if (showOverlay && pspWeap.sprite == GetSpriteIndex ('MANX')) {
            pspOverlay.sprite = GetSpriteIndex (sprite);
            pspOverlay.frame = pspWeap.frame;
        } else {
            pspOverlay.sprite = GetSpriteIndex ('TNT1');
            pspOverlay.frame = 0;
        }

        if (health <= 0)
            return ResolveState ("Overlay.DeselectDEAD");

        return ResolveState (null);
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
    }

    /** Animations **/
    states {
    Anim.Idle:
        MANX A 1 {
            if (invoker.zoomed)
                S7_SetSprite ('SCP1', 3, AnimLayer_ID);
        }
        wait;
    Anim.Fire:
        MANX A  1 bright;
        MANX BC 1;
        goto Anim.Idle;
    Anim.FireZoom:
        SCP1 D 1 bright;
        goto Anim.Idle;
    Anim.Reload:
        MANX ADEFG 2;
        MANX H     6;
        MANX IJ    1;
        MANX KL    2;
        MANX M     2 A_PlaySound ("Weapons/ManxCarbine/In", CHAN_6);
        MANX NO    2;
        MANX PQEDA 2;
        goto Anim.Idle;

    Overlay.Scope:
        MNX2 A 1 Manx_RunOverlay (Manx_ScopeOverlay_ID, 'MNX2', invoker.hasScope);
        loop;
    Overlay.Suppressor:
        MNX3 A 1 Manx_RunOverlay (Manx_SuppressorOverlay_ID, 'MNX3', invoker.hasSuppressor);
        loop;
    }

    /** Actions **/
    states {
    Ready:
        TNT1 A 0 {
            A_Overlay (Manx_ScopeOverlay_ID     , "Overlay.Scope"     );
            A_Overlay (Manx_SuppressorOverlay_ID, "Overlay.Suppressor");
            S7_SetAnim ("Anim.Idle");
        }
        TNT1 A 1 DoSelectOffset ((56, 56), forceNoInterpolate: true);
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((32, 32));
        TNT1 A 1 DoSelectOffset ((16, 16));
        TNT1 A 1 DoSelectOffset (( 8,  8));
        TNT1 A 1 DoSelectOffset (( 0,  0));
    Ready2:
        TNT1 A 1 {
            if (invoker.zoomed)
                TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

            int flagsWR = 0;
            if (invoker.hasScope)
                flagsWR |= WRF_AllowZoom;
            if (invoker.zoomed)
                flagsWR |= WRF_NoBob;

            S7_SetAnim ("Anim.Idle");

            S7_WeaponReady ("Reload", "ChangeMode", "QuickMeleeDerp", wrFlags: flagsWR);

            return ResolveState (null);
        }
        loop;

    QuickMeleeDerp:
        TNT1 A 0 {
            TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

            if (invoker.zoomed)
                return ResolveState ("Ready2");

            S7_SetAnim ("Null");

            return ResolveState (null);
        }
        goto QuickMelee;

    Deselect:
        MANX A 0 {
            A_SetCrosshair (0);

            if (health <= 0) {
                invoker.zoomed = false;
                S7_SetAnim ("Null");
                return ResolveState ("Deselect.DEAD");
            }

            if (invoker.zoomed)
                return ResolveState ("Deselect.Zoom");

            S7_SetAnim ("Anim.Idle");

            return ResolveState (null);
        }
        TNT1 A 1 DoSelectOffset (( 0,  0));
        TNT1 A 1 DoSelectOffset (( 8,  8));
        TNT1 A 1 DoSelectOffset ((16, 16));
        TNT1 A 1 DoSelectOffset ((32, 32));
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((56, 56));
        TNT1 A 0 {
            A_Overlay (Manx_ScopeOverlay_ID     , "Null");
            A_Overlay (Manx_SuppressorOverlay_ID, "Null");
        }
        goto TrueDeselect;
    Deselect.Zoom:
        TNT1 A 8 {
            invoker.zoomed = false;
            A_SetBlend ("00 00 00", 1.0, 8);
            A_ZoomFactor (1.0, ZOOM_Instant);
            S7_SetAnim ("Anim.Idle");
        }
        goto Deselect;

    Fire:
        TNT1 A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            if (!invoker.hasSuppressor) {
                A_PlaySound ("Weapons/ManxCarbine/Fire", invoker.fireSoundChannel ? CHAN_5 : CHAN_Weapon);
                A_AlertMonsters ();
                A_GunFlash ();
            } else {
                A_PlaySound ("Weapons/ManxCarbine/Fire", invoker.fireSoundChannel ? CHAN_5 : CHAN_Weapon, volume: 0.4);
                A_AlertMonsters (512.0);
            }

            invoker.fireSoundChannel = !invoker.fireSoundChannel;

            if (!invoker.zoomed) {
                S7_SetAnim ("Anim.Fire");

                if (!invoker.hasSuppressor) S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 4, 4.25));
                else                        S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2.5, 2.75));
                S7_A_SpawnCasing ('S7_9mmCasing', (30, 15, 15), pitchOffs: -45, spread: (10, 15));
                S7_A_FireBullets ('S7_ManxCarbineTracer', spread: (.25, .25), offs: (10, 10, 10), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);


                A_ZoomFactor (invoker.GetZoomFactor () * .9875);
            } else {
                S7_SetAnim ("Anim.FireZoom");

                S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 0, 4));
                S7_A_SpawnCasing ('S7_9mmCasing', (30, 8, 10), pitchOffs: -45, spread: (10, 15));
                S7_A_FireBullets ('S7_ManxCarbineTracer', spread: (.24, .24), offs: (10, 0, 10), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);

                A_ZoomFactor (invoker.GetZoomFactor () * .95);
            }

            S7_Recoil (-0.3);

            return ResolveState (null);
        }
        TNT1 A 1 {
            if (!invoker.zoomed)
                A_ZoomFactor (invoker.GetZoomFactor () * .99375);
            else
                A_ZoomFactor (invoker.GetZoomFactor () * .975);

            S7_Recoil (-0.3);
        }
        TNT1 A 1 A_ZoomFactor (invoker.GetZoomFactor ());
        TNT1 A 1 {
            if (invoker.semiAuto)
                return ResolveState ("Fire.Semi");

            A_Refire ();

            return ResolveState (null);
        }
        TNT1 A 3;
        goto Ready2;
    Fire.Semi:
        TNT1 AAAA 1 { player.WeaponState |= WF_WeaponReady; }
        TNT1 A    2;
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
                A_ZoomFactor (BaseZoomFactor + invoker.zoomLevel, ZOOM_Instant);
            } else
                return ResolveState ("Unzoom");

            return ResolveState (null);
        }
        goto Ready2;
    Unzoom:
        TNT1 A 8 {
            S7_SetAnim ("Anim.Idle");

            invoker.zoomed = false;
            A_SetCrosshair (0);
            A_SetBlend ("00 00 00", 1.0, 8);
            A_ZoomFactor (1.0, ZOOM_Instant);
        }
        goto Ready2;
    ChangeZoomLevel:
        TNT1 A 1 {
            if (!(player.cmd.buttons & BT_Zoom))
                return ResolveState ("Ready2");

            if (player.cmd.buttons & BT_Attack) {
                invoker.zoomLevel = clamp (invoker.zoomLevel + 0.2, 0, BaseZoomFactor);
                A_ZoomFactor (BaseZoomFactor + invoker.zoomLevel);
            } else if (player.cmd.buttons & BT_AltAttack) {
                invoker.zoomLevel = clamp (invoker.zoomLevel - 0.2, 0, BaseZoomFactor);
                A_ZoomFactor (BaseZoomFactor + invoker.zoomLevel);
            }

            return ResolveState (null);
        }
        loop;
    ChangeZoomLevel.Delay:
        TNT1 A 1 A_JumpIf (!(player.cmd.buttons & BT_Zoom), "Ready2");
        goto ChangeZoomLevel;

    ChangeMode:
        TNT1 A 5 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            S7_SetAnim ("Anim.Idle");

            invoker.semiAuto = !invoker.semiAuto;
            A_PlaySound ("Weapons/ModeChange", CHAN_7);
        }
        goto Ready2;

    DryFire:
        TNT1 A 3 {
            S7_SetAnim ("Anim.Idle");

            A_PlaySound ("Weapons/DryFireSMG", CHAN_7);

            return ResolveState (null);
        }
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

    // Muzzle flashes
    Flash:
        MNXF A 1 bright A_JumpIf (invoker.zoomed, "Flash.Zoom");
        stop;
    Flash.Zoom:
        TNT1 A 1 bright;
        stop;
    }
}
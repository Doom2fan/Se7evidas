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
// S18 "Kronos" SMG
//
//-------------------------------------------------------------------------------------------
class S7_TEC9Clip : Ammo {
    default {
        Inventory.MaxAmount 32;
        Ammo.BackpackMaxAmount 32;

        +INVENTORY.IGNORESKILL
    }
}

class S7_TEC9 : S7_BaseWeapon {
    default {
        Tag "$TEC9";
        Inventory.PickupMessage "$TEC9";
        Inventory.PickupSound "Weapons/Pickup/Small";

        Weapon.AmmoType1 'S7_TEC9Clip';
        Weapon.AmmoType2 'S7_9mmCartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "TEC9Z0";
        S7_BaseWeapon.ShortTag "$SHORTTEC9";
        S7_BaseWeapon.AmmoBuyData "A9MM", 1;
        S7_BaseWeapon.BindSlot WpSlot_Light;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties true, 0.025;
        S7_BaseWeapon.EnchantmentPrice 450, 0.375, 1.1885;
    }

    const ANIM_LAYER = 2;
    const TEC9_SUPPRESSOROVERLAY_ID = 3;
    bool hasSuppressor;

    bool fireFrame2;

    override void Tick () {
        Super.Tick ();

        if (!self)
            return;

        if (hasSuppressor)
            weapIcon = "TECSZ0";
        else
            weapIcon = "TEC9Z0";
    }

    override bool SS_PreSell (int amount) {
        if (hasSuppressor) {
            if (!Owner.CheckInventory ('S7_TEC9Suppressor', 0))
                Owner.GiveInventory ('S7_TEC9Suppressor', 1);
            else
                DropAmmo ('S7_TEC9Suppressor', Owner, 1);

            hasSuppressor = false;
        }

        return true;
    }

    override void DoEffect () {
        Super.DoEffect ();

        if (hasSuppressor)
            Owner.A_OverlayOffset (ANIM_LAYER, 12, 12);
        else
            Owner.A_OverlayOffset (ANIM_LAYER,  0,  0);
    }

    action void S7_SetAnim (StateLabel animState) {
        A_Overlay (ANIM_LAYER, animState);
        A_OverlayFlags (ANIM_LAYER, PSPF_AddWeapon | PSPF_PowDouble | PSPF_CvarFast | PSPF_RenderStyle | PSPF_Alpha, true);
        A_OverlayFlags (ANIM_LAYER, PSPF_Flip | PSPF_Mirror | PSPF_ForceAlpha | PSPF_ForceStyle, false);
    }

    states {
    Spawn:
        TEC9 Z 1 {
            if (invoker.hasSuppressor)
                sprite = GetSpriteIndex ('TECS');
            else
                sprite = GetSpriteIndex ('TEC9');
        }
        goto Spawn;
    }

    /** Animations **/
    states {
    Anim.Idle:
        TEC9 A 1;
        wait;
    Anim.FireStart:
        TEC9 B 1;
        wait;
    Anim.Fire:
        TEC9 D 1 bright {
            let psp = player.FindPSprite (ANIM_LAYER);
            if (!psp)
                return;

            if (invoker.fireFrame2)
                psp.frame = 2; // C
            else
                psp.frame = 3; // D
        }
        TEC9 B 1;
        wait;
    Anim.Reload:
        TECR A   1 A_PlaySound ("Weapons/TEC-9/Out", CHAN_6);
        TECR BCD 1;
        TECR D   5;
        TECR DEF 2;
        TNT1 A   0 A_PlaySound ("Weapons/TEC-9/In", CHAN_7);
        TECR G   2 A_WeaponOffset (0, 32 + -6);
        TECR H   2;
        TECR I   2 A_WeaponOffset (0, 32 + -3);
        TECR J   2 A_WeaponOffset (0, 32 +  0);
        TECR KLM 2;
        TECR N   2 A_PlaySound ("Weapons/TEC-9/Tap", CHAN_6);
        TECR O   2 A_WeaponOffset (0, 32 + -8);
        TECR P   2 A_WeaponOffset (0, 32 + -6);
        TECR P   4 A_WeaponOffset (0, 32 + -3);
        TECR Q   2 A_WeaponOffset (0, 32 + -6);
        TECR R   2 A_WeaponOffset (0, 32 + -3);
        TECR S   2 A_WeaponOffset (0, 32 +  0);
        goto Anim.Idle;

    Overlay.Suppressor:
        TECS A 1 {
            {
                name sprite = 'TECS';
                bool showOverlay = invoker.hasSuppressor;

                let pspWeap = player.FindPSprite (ANIM_LAYER);
                let pspOverlay = player.FindPSprite (TEC9_SUPPRESSOROVERLAY_ID);

                if (!pspWeap || !pspOverlay)
                    return ResolveState (null);

                A_OverlayOffset (TEC9_SUPPRESSOROVERLAY_ID, 12, 12);

                if (showOverlay && (pspWeap.sprite == GetSpriteIndex ('TEC9') || pspWeap.sprite == GetSpriteIndex ('TECR'))) {
                    pspOverlay.sprite = GetSpriteIndex (sprite);
                    pspOverlay.frame = 0;
                } else {
                    pspOverlay.sprite = GetSpriteIndex ('TNT1');
                    pspOverlay.frame = 0;
                }
            }

            if (health <= 0)
                return ResolveState ("Overlay.DeselectDEAD");

            return ResolveState (null);
        }
        wait;
    }

    states {
    Ready:
        TNT1 A 0 {
            S7_SetAnim ("Anim.Idle");
            A_Overlay (TEC9_SUPPRESSOROVERLAY_ID, "Overlay.Suppressor");
        }
        TNT1 A 1 DoSelectOffset ((80, 80), forceNoInterpolate: true);
        TNT1 A 1 DoSelectOffset ((64, 64));
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((32, 32));
        TNT1 A 1 DoSelectOffset ((16, 16));
        TNT1 A 1 DoSelectOffset (( 0,  0));
    Ready2:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");
            S7_WeaponReady ("Reload", null);
        }
        loop;

    Deselect:
        TEC9 A 0 {
            if (health <= 0)
                return ResolveState ("Deselect.DEAD");

            return ResolveState (null);
        }
        TNT1 A 1 DoSelectOffset (( 0,  0));
        TNT1 A 1 DoSelectOffset ((16, 16));
        TNT1 A 1 DoSelectOffset ((32, 32));
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((64, 64));
        TNT1 A 1 DoSelectOffset ((80, 80));
        TNT1 A 0 A_Overlay (TEC9_SUPPRESSOROVERLAY_ID, "Null");
        goto TrueDeselect;

    Fire:
        TNT1 A 1 {
            S7_SetAnim ("Anim.FireStart");
            invoker.fireFrame2 = false;
        }
    Hold:
        TNT1 A 1 bright {
            if (!invoker.CheckAmmo (PrimaryFire, false, true)) {
                A_ClearRefire ();
                return ResolveState ("DryFire");
            }

            S7_SetAnim ("Anim.Fire");

            if (!invoker.hasSuppressor) {
                A_PlaySound ("Weapons/TEC-9/Fire", CHAN_Weapon);
                A_AlertMonsters ();
                A_GunFlash ();
            } else {
                A_PlaySound ("Weapons/TEC-9/Fire", CHAN_Weapon, volume: 0.35);
                A_AlertMonsters (384.0);
            }

            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2.5, 2.25));

            if (!invoker.hasSuppressor) {
                S7_A_SpawnCasing ('S7_9mmCasing', (30, 11, 9.5), pitchOffs: -45, spread: (10, 15));
                S7_A_FireBullets ('S7_TEC9Tracer', spread: (.45, .45), offs: (10, 4.25, 4), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);
            } else {
                S7_A_SpawnCasing ('S7_9mmCasing', (30, 12, 12), pitchOffs: -45, spread: (10, 15));
                S7_A_FireBullets ('S7_TEC9Tracer', spread: (.45, .45), offs: (10, 5.25, 5), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);
            }

            S7_Recoil (-.75);
            A_ZoomFactor (.99, ZOOM_Instant);
            A_SetAngle (angle + fRandom [weaponSpread] (-.5, .5));

            A_WeaponOffset (4, 32 + 4);

            invoker.fireFrame2 = !invoker.fireFrame2;

            return ResolveState (null);
        }
        TNT1 A 1 {
            S7_Recoil (+.25);
            A_ZoomFactor (1.);

            A_WeaponOffset (0, 32, WOF_Interpolate);
        }
        TNT1 A 1 A_Refire ();
        TNT1 A 1 { player.WeaponState |= WF_WeaponReady; }
        goto Ready2;

    DryFire:
        TNT1 A 1 {
            S7_SetAnim ("Anim.FireStart");
            A_PlaySound ("Weapons/DryFireSMG", CHAN_7);
            A_ClearRefire ();
        }
        TNT1 A 3 S7_SetAnim ("Anim.Idle");
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            TakeInventory ('S7_Reloading', 1);
            A_ClearRefire ();

            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1))
                return ResolveState ("Ready2");

            int ammoAmount = min (FindInventory (invoker.ammoType1).maxAmount - CountInv (invoker.ammoType1), CountInv (invoker.ammoType2));
            if (ammoAmount <= 0)
                return ResolveState ("Ready2");

            GiveInventory (invoker.ammoType1, ammoAmount);
            TakeInventory (invoker.ammoType2, ammoAmount);

            S7_SetAnim ("Anim.Reload");

            return ResolveState (null);
        }
        TNT1 A 1 {
            let psp = player.FindPSprite (ANIM_LAYER);
            if (psp && InStateSequence (psp.CurState, ResolveState ("Anim.Idle")))
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        wait;

    // Muzzle flashes
    Flash:
        TNT1 A 0 bright A_Jump (256, "Flash1", "Flash2");
    Flash1:
        TECF A 1 bright;
        stop;
    Flash2:
        TECF B 1 bright;
        stop;
    }
}
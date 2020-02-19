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
// Ω-Σ "Deathbringer" Revolver
//
//-------------------------------------------------------------------------------------------
class S7_RevolverClip : Ammo {
    default {
        Inventory.MaxAmount 6;
        Ammo.BackpackMaxAmount 6;

        +INVENTORY.IGNORESKILL
    }
}

class S7_Revolver : S7_BaseWeapon {
    default {
        Tag "$REVOLVER";
        Inventory.PickupMessage "$REVOLVER";
        Inventory.PickupSound "Weapons/Pickup/Small";

        Weapon.AmmoType1 'S7_RevolverClip';
        Weapon.AmmoType2 'S7_44MCartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "RVLPA0";
        S7_BaseWeapon.ShortTag "$SHORTREVOLVER";
        S7_BaseWeapon.AmmoBuyData "A44M", 1;
        S7_BaseWeapon.BindSlot S7_WpSlot_Light;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties true, 0.02;
        S7_BaseWeapon.EnchantmentPrice 650, 0.425, 1.1885;
    }

    const AnimLayer_ID = 2;

    action void S7_SetAnim (StateLabel animState) {
        S7_Internal_SetAnim (AnimLayer_ID, animState, 0, 0);
    }

    /** Pickup **/
    states {
    Spawn:
        RVLP A -1;
        loop;
    }

    /** Animations **/
    states {
    Anim.Idle:
        RVLV A 1;
        wait;
    Anim.Fire:
        RVLV AB 1;
        RVLV C  1 bright;
        RVLV D  1;
        RVLV E  1;
        RVLV E  1;
        RVLV FG 1;
        RVLV A  1;
        goto Anim.Idle;
    Anim.DryFire:
        RVLV BC 1;
        goto Anim.Idle;
    Anim.Reload:
        // Open
        RVLV AHIJ 1;
        RVLV KL   1;
        RVLV M    2 A_StartSound ("Weapons/Revolver/Open", slot: CHAN_5);
        RVLV NOP  1;
        RVLV QRR  1;
        RVLV S    3;
        // Eject
        RVLV T     1 {
            A_StartSound ("Weapons/Revolver/Eject", slot: CHAN_6);
            for (int i = 0; i < 3; i++) {
                S7_A_SpawnCasing ('S7_RevolverCasing', (30, -1.5 + i, 5), pitchOffs: 90, spread: (0, 1), horzMul: 0);
                S7_A_SpawnCasing ('S7_RevolverCasing', (30, -1.5 + i, 6), pitchOffs: 90, spread: (0, 1), horzMul: 0);
            }
        }
        RVLV U     5;
        RVLV VWXYZ 1;
        // Insert
        RVL2 ABCD 1;
        RVL2 E    3 A_StartSound ("Weapons/Revolver/In", slot: CHAN_7);
        RVL2 F    3;
        // Close
        RVL2 G   1;
        RVL2 H   1 A_StartSound ("Weapons/Revolver/Close", slot: CHAN_Weapon);
        RVL2 IJK 1;
        RVL2 LM  1;
        RVLV A   3;
        goto Anim.Idle;
    }

    /** Actions **/
    states {
    Ready:
        TNT1 A 0 S7_SetAnim ("Anim.Idle");
        TNT1 A 1 DoSelectOffset ((96, 96), forceNoInterpolate: true);
        TNT1 A 1 DoSelectOffset ((72, 72));
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((24, 24));
        TNT1 A 1 DoSelectOffset (( 8,  8));
        TNT1 A 1 DoSelectOffset (( 0,  0));
    Ready2:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");
            S7_WeaponReady ("Reload", null, "QuickMeleeDerp");
        }
        loop;
    QuickMeleeDerp:
        TNT1 A 0 S7_SetAnim ("Null");
        goto QuickMelee;

    Deselect:
        RVLV A 0 {
            if (health <= 0) {
                S7_SetAnim ("Null");
                return ResolveState ("Deselect.DEAD");
            }

            S7_SetAnim ("Anim.Idle");

            return ResolveState (null);
        }
        TNT1 A 1 DoSelectOffset (( 0,  0));
        TNT1 A 1 DoSelectOffset (( 8,  8));
        TNT1 A 1 DoSelectOffset ((24, 24));
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((72, 72));
        TNT1 A 1 DoSelectOffset ((96, 96));
        goto TrueDeselect;

    Fire:
        TNT1 A 2 S7_SetAnim ("Anim.Fire");
        TNT1 A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_StartSound ("Weapons/Revolver/Fire", slot: CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();

            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 1.8, 1));
            S7_A_FireBullets ('S7_RevolverTracer', spread: (.5, .5), offs: (12, 4, 2), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);

            S7_Recoil (-1.75);
            A_ZoomFactor (.965, ZOOM_Instant);

            return ResolveState (null);
        }
        TNT1 A 1 {
            S7_Recoil (-1.75);
            A_ZoomFactor (.9825);
        }
        TNT1 A 1 {
            S7_Recoil (+.25);
            A_ZoomFactor (1.);
        }
        TNT1 A 1 S7_Recoil (+.25);
        TNT1 A 2;
        TNT1 A 1;
        goto Ready2;

    Flash:
        RVLF A 1 bright;
        stop;

    DryFire:
        TNT1 A 3 {
            A_StartSound ("Weapons/Revolver/Dryfire", slot: CHAN_7);
            S7_SetAnim ("Anim.DryFire");
        }
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            TakeInventory ('S7_Reloading', 1);

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
            let psp = player.FindPSprite (AnimLayer_ID);
            if (psp && InStateSequence (psp.CurState, ResolveState ("Anim.Idle")))
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        wait;
    }
}
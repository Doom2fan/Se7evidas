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
// R16 "Raptor" Pistol
//
//-------------------------------------------------------------------------------------------
class S7_RaptorClip : Ammo {
    default {
        Inventory.MaxAmount 24;
        Ammo.BackpackMaxAmount 24;

        +INVENTORY.IGNORESKILL
    }
}

class S7_Raptor : S7_BaseWeapon {
    default {
        Tag "$RAPTOR";
        Inventory.PickupMessage "$RAPTOR";
        Inventory.PickupSound "Weapons/Pickup/Small";

        Weapon.AmmoType1 'S7_RaptorClip';
        Weapon.AmmoType2 'S7_9mmCartridges';
        Weapon.AmmoUse 2;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "RPTPA0";
        S7_BaseWeapon.ShortTag "$SHORTRAPTOR";
        S7_BaseWeapon.AmmoBuyData "A9MM", 1;
        S7_BaseWeapon.BindSlot S7_WpSlot_Light;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties true, 0.025;
        S7_BaseWeapon.EnchantmentPrice 450, 0.375, 1.1885;
    }

    const AnimLayer_ID = 2;

    action void S7_SetAnim (StateLabel animState) {
        S7_Internal_SetAnim (AnimLayer_ID, animState, 0, 0);
    }

    states {
    Spawn:
        RPTP A -1;
        loop;
    }

    /** Animations **/
    states {
    Anim.Idle:
        RPTN A 1;
        wait;
    Anim.Fire:
        RPTN B 1 bright;
        RPTN C 1;
        goto Anim.Idle;
    Anim.Altfire:
        RPTM A    1;
        RPTM BC   1;
        RPTM D    1;
        RPTM EFGH 1;
        TNT1 A    4;
        RPTN A    1;
    Anim.Reload:
        RPTR FGGH  1;
        RPTR I     4;
        RPTR I    23 A_StartSound ("Weapons/Raptor/Out", slot: CHAN_6);
        RPTR I     1 A_StartSound ("Weapons/Raptor/In", slot: CHAN_7);
        RPTR JDD   1;
        RPTR BA    1;
        RPTN A     1;
        goto Anim.Idle;
    }

    /** Actions **/
    states {
    Ready:
        TNT1 A 0 S7_SetAnim ("Anim.Idle");
        TNT1 A 1 DoSelectOffset ((80, 80), forceNoInterpolate: true);
        TNT1 A 1 DoSelectOffset ((64, 64));
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((32, 32));
        TNT1 A 1 DoSelectOffset ((14, 14));
        TNT1 A 1 DoSelectOffset (( 0,  0));
        goto Ready2;

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
        RPTN A 0 {
            if (health <= 0) {
                S7_SetAnim ("Null");
                return ResolveState ("Deselect.DEAD");
            }

            S7_SetAnim ("Anim.Idle");

            return ResolveState (null);
        }
        TNT1 A 1 DoSelectOffset (( 0,  0));
        TNT1 A 1 DoSelectOffset ((14, 14));
        TNT1 A 1 DoSelectOffset ((32, 32));
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((64, 64));
        TNT1 A 1 DoSelectOffset ((80, 80));
        goto TrueDeselect;

    Fire:
        TNT1 A 1 bright {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            S7_SetAnim ("Anim.Fire");

            A_StartSound ("Weapons/Raptor/Fire", slot: CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();

            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2.75, 2.95));
            for (int i = 0; i < 2; i++)
                S7_A_SpawnCasing ('S7_9mmCasing', (30, 11, 8), pitchOffs: -45, spread: (10, 15));
            S7_A_FireBullets ('S7_RaptorTracer', spread: (.4, .4), offs: (12, 6.5, 5.5), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);
            S7_A_FireBullets ('S7_RaptorTracer', spread: (.4, .4), offs: (12, 6.5, 7.5), bonusDMGFactor: invoker.Enchantments_GetDamageBonus ());

            S7_Recoil (-.95);
            A_ZoomFactor (.9875, ZOOM_Instant);

            return ResolveState (null);
        }
        TNT1 A 1 {
            S7_Recoil (-.95);
            A_ZoomFactor (.99375);
        }
        TNT1 A 1 {
            S7_Recoil (+.5);
            A_ZoomFactor (1.);
        }
        TNT1 AAAA 1 { player.WeaponState |= WF_WeaponReady; }
        goto Ready2;

    AltFire:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Altfire");
            A_StartSound ("Weapons/Raptor/Melee", slot: CHAN_5);
        }
        TNT1 A 2;
        TNT1 A 1 A_CustomPunch (30 + random [weaponDamage] (-2, 2), true, 0, 'S7_RaptorMPuff', 85);
        TNT1 A 4;
        TNT1 A 4;
        TNT1 A 1;
        goto Ready2;

    Flash:
        RPTF A 1 bright;
        stop;

    DryFire:
        TNT1 A 3 {
            S7_SetAnim ("Anim.Idle");
            A_StartSound ("Weapons/DryFirePistol", slot: CHAN_7);
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

class S7_RaptorMPuff : Actor {
    default {
        RenderStyle "translucent";
        Alpha 0.5;
        SeeSound "Weapons/Raptor/Melee/Hit";
        AttackSound "Weapons/Raptor/Melee/Wall";

        +NOBLOCKMAP       +NOGRAVITY +NOEXTREMEDEATH +PUFFONACTORS
        +FORCEXYBILLBOARD
    }

    states {
    Crash:
        RMPF AB 2 bright;
        RMPF C  1 bright;
        stop;
    Spawn:
    Melee:
        TNT1 A 1;
        stop;
    }
}
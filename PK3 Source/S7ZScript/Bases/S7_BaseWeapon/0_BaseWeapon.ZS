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
// Base weapon
//
//-------------------------------------------------------------------------------------------
class S7_BaseWeapon : Weapon {
    String weapIcon;
    String shortTag;
    String ammoBuyShopItem;
    int ammoBuyAmount;
    S7_WeaponSlots bindSlot;
    bool usesMag;
    bool reloadWhileSprinting;
    bool enchantment_canEnchant;
    double enchantment_BasePower;
    int enchantment_Price_Base;
    double enchantment_Price_AmountD, enchantment_Price_PowerMul;

    property Icon: weapIcon;
    property ShortTag: shortTag;
    property AmmoBuyData: ammoBuyShopItem, ammoBuyAmount;
    property BindSlot: bindSlot;
    property UsesMag: usesMag;
    property CanReloadWhileSprinting: reloadWhileSprinting;
    property EnchantmentProperties: enchantment_canEnchant, enchantment_BasePower;
    property EnchantmentPrice: enchantment_Price_Base, enchantment_Price_PowerMul, enchantment_Price_AmountD;

    default {
        Inventory.PickupSound "misc/gunpickup";
        Weapon.BobRangeX 0.3;
        Weapon.BobRangeY 0.5;
        Weapon.BobSpeed 2.0;
        Weapon.BobStyle "inverseSmooth";
        Weapon.Kickback 100;

        S7_BaseWeapon.Icon "";
        S7_BaseWeapon.AmmoBuyData "", 1;
        S7_BaseWeapon.BindSlot -1;
        S7_BaseWeapon.UsesMag false;
        S7_BaseWeapon.CanReloadWhileSprinting false;
        S7_BaseWeapon.EnchantmentProperties false, 0.0;
        S7_BaseWeapon.EnchantmentPrice 0, 0.0, 0.0;

        +WEAPON.AMMO_OPTIONAL +WEAPON.NOAUTOFIRE +WEAPON.NOALERT +INVENTORY.RESTRICTABSOLUTELY
        +INVENTORY.TRANSFER
    }

    int fireModeIcon; // 0: none, 1: semi-auto, 2: burst-fire, 3: full-auto.

    virtual double S7_WeightSpeedModifier (double strengthStat, double berserkCount) {
        return 1.;
    }

    states {
    DummyState:
        TNT1 A 1;
        wait;

    DryFire:
        TNT1 A 0 {
            A_PlaySound ("Weapons/DryFire", CHAN_Weapon);

            if (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload ())
                return ResolveState ("Reload");

            return ResolveState (null);
        }
        TNT1 A 0 A_Jump (256, "Ready2");
        wait;

    Ready:
        TNT1 A 0 A_Jump (256, "Ready2");
        wait;
    Fire:
        TNT1 A 1;
        goto Ready;

    Select:
    TrueSelect:
        TNT1 A 0 A_Raise ();
        loop;
    Deselect:
    TrueDeselect:
        ---- A 0 {
            TakeInventory ('S7_Weap_ReadyFrame', 0x7FFFFFFF);
            A_ZoomFactor (1.0);
            A_WeaponOffset (0, 32);

            if (!health)
                return ResolveState ("Deselect.DEAD");

            return ResolveState (null);
        }
        ---- A 0 A_Lower ();
        wait;
    Deselect.DEAD:
        ---- A 0 {
            A_ZoomFactor (1.0, ZOOM_Instant);
            A_WeaponOffset (0, 32);
        }
        ---- A 1 A_Lower;
        wait;
    Overlay.DeselectDEAD:
        #### # 1 {
            let psp = player.FindPSprite (PSP_Weapon);

            if (!psp)
                return ResolveState ("Null");

            return ResolveState (null);
        }
        wait;
    }
}

//-------------------------------------------------------------------------------------------
//
// Misc crap
//
//-------------------------------------------------------------------------------------------
class S7_Unarmed : S7_BaseWeapon { default { Tag "$UNARMED"; } }
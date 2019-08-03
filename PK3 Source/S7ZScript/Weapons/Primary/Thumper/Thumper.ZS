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

enum S7_ThprGrenType { // An enum containing the grenade types. Pretty straightforward.
    S7_TH_None      = 0,
    S7_TH_Exp       = 1,
    S7_TH_Frag      = 2,
    S7_TH_Therm     = 3,
    S7_TH_Flare     = 4,
    S7_TH_Cluster   = 5,
    S7_TH_Nail      = 6,
    S7_TH_NGas      = 7,
    S7_TH_EndToken  = 8,
};

//-------------------------------------------------------------------------------------------
//
// XPL-50 "Thumper" Grenade Launcher
//
//-------------------------------------------------------------------------------------------
// These will stay so HUDs can show what kind of grenades are loaded.
class S7_ThumperMag1 : S7_Counter { default { Inventory.MaxAmount 7; } }
class S7_ThumperMag2 : S7_Counter { default { Inventory.MaxAmount 7; } }
class S7_ThumperMag3 : S7_Counter { default { Inventory.MaxAmount 7; } }
class S7_ThumperMag4 : S7_Counter { default { Inventory.MaxAmount 7; } }
class S7_ThumperMag5 : S7_Counter { default { Inventory.MaxAmount 7; } }
class S7_ThumperSelectedPool : S7_Counter { default { Inventory.MaxAmount 7; } }

class S7_ThumperMag : Ammo { // This isn't actually used by the weapon. It's just here so HUDs can use it.
    default {
        Inventory.MaxAmount 5;
        Ammo.BackpackMaxAmount 5;

        +INVENTORY.IGNORESKILL
    }
}

// No more GROSS HACKS! Yay!
class S7_Thumper : S7_BaseWeapon {
    default {
        Tag "$THUMPER";
        Inventory.PickupMessage "$THUMPER";
        Inventory.PickupSound "Weapons/Pickup/Medium";

        Weapon.AmmoType1 'S7_ThumperMag';
        Weapon.AmmoUse 0;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "THMPU0";
        S7_BaseWeapon.ShortTag "$SHORTTHUMPER";
        S7_BaseWeapon.AmmoBuyData "", 1;
        S7_BaseWeapon.BindSlot WpSlot_AreaDMG;
        S7_BaseWeapon.UsesMag false;
        S7_BaseWeapon.EnchantmentProperties true, 0.025;
        S7_BaseWeapon.EnchantmentPrice 850, 0.65, 1.1612;

        +WEAPON.NOAUTOAIM
    }

    bool chambered;
    int selectedPool;
    class<S7_50mmCasing> casingType;
    Array<int> magazine;

    static const Class<Inventory> PoolNames [] = {
        "",
        "S7_Thumper_PExp",
        "S7_Thumper_PFrag",
        "S7_Thumper_PTherm",
        "S7_Thumper_PFlare",
        "S7_Thumper_PCluster",
        "S7_Thumper_PNail",
        "S7_Thumper_PNGas"
    };

    static const string Pool_ShopNames [] = {
        "",
        "THP1",
        "THP2",
        "THP3",
        "THP4",
        "THP5",
        "THP6",
        "THP7"
    };

    static const Class<Inventory> MagTokens [] = {
        "S7_ThumperMag1",
        "S7_ThumperMag2",
        "S7_ThumperMag3",
        "S7_ThumperMag4",
        "S7_ThumperMag5"
    };

    int CountCurPoolAmmo () {
        if (selectedPool <= S7_TH_None || selectedPool >= S7_TH_EndToken)
            return -1;

        return Owner.CountInv (PoolNames [selectedPool]);
    }

    override void AttachToOwner (Actor other) {
        Super.AttachToOwner (other);

        selectedPool = S7_TH_Exp;
    }

    void UpdateAmmoQuickBuyData () {
        if (selectedPool <= S7_TH_None || selectedPool >= S7_TH_EndToken) {
            ammoBuyShopItem = "";
            ammoBuyAmount = 0;
        } else {
            ammoBuyShopItem = Pool_ShopNames [selectedPool];
            ammoBuyAmount = 1;
        }
    }

    override void DoEffect () {
        Super.DoEffect ();

        int i = 0;
        for (; i < magazine.Size (); i++)
            Owner.SetInventory (MagTokens [i], magazine [i]);
        for (; i < 5; i++)
            Owner.SetInventory (MagTokens [i], 0);

        Owner.SetInventory ('S7_ThumperMag', magazine.Size ());
        Owner.SetInventory ('S7_ThumperSelectedPool', selectedPool - 1);

        UpdateAmmoQuickBuyData ();
    }

    override bool SS_PreSell (int amount) {
        int unifiedMax;

        let unifiedPool = Owner.FindInventory ('S7_Thumper_PUnified');
        if (unifiedPool)
            unifiedMax = unifiedPool.MaxAmount;
        else
            unifiedMax = GetDefaultByType ('S7_Thumper_PUnified').MaxAmount;

        int unifiedCount;
        while (magazine.Size () > 0) {
            unifiedCount = S7_Thumper_PUnified.CalculateUnifiedAmount (Owner);

            int type = magazine [magazine.Size ()-1];
            magazine.Pop ();

            class<Inventory> typeClass = PoolNames [type];
            if (unifiedCount < unifiedMax)
                Owner.GiveInventory (typeClass, 1);
            else
                DropAmmo (typeClass, Owner, 1);
        }

        return true;
    }

    action void S7_SpawnCasing () {
        S7_A_SpawnCasing (invoker.casingType, (30, 18, 16), pitchOffs: -45, spread: (10, 15));
    }

    states {
    Spawn:
        THMP U -1;
        stop;

    Select.Hand:
        HAN0 F 1 DoSelectOffset (( 67, 168), -5, forceNoInterpolate: true);
        HAN0 F 1 DoSelectOffset (( 95, 158), -5);
        HAN0 F 1 DoSelectOffset ((123, 148), -5);
        HAN0 F 1 DoSelectOffset ((151, 137), -5);
        HAN0 F 1 DoSelectOffset ((167, 130), -5);
        stop;
    Ready:
        THMP H 1 {
            A_Overlay (-5, "Select.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
            DoSelectOffset ((8 + (30 * 4), 4 + (15 * 4)), forceNoInterpolate: true);
        }
        THMP H 1 DoSelectOffset ((8 + (30 * 3), 4 + (15 * 3)));
        THMP H 1 DoSelectOffset ((8 + (30 * 2), 4 + (15 * 2)));
        THMP H 1 DoSelectOffset ((8 + (30 * 1), 4 + (15 * 1)));
        THMP H 1 DoSelectOffset ((8           , 4           ));
        THMP A 1 {
            DoSelectOffset ((10, 3), forceNoInterpolate: true);
            DoSelectOffset (( 0, 0));
        }
    Ready2:
        THMP A 1 S7_WeaponReady ("Reload", "ChangeMode");
        loop;

    Deselect.Hand:
        HAN0 F 1 DoSelectOffset ((167, 130), -5, forceNoInterpolate: true);
        HAN0 F 1 DoSelectOffset ((151, 137), -5);
        HAN0 F 1 DoSelectOffset ((123, 148), -5);
        HAN0 F 1 DoSelectOffset (( 95, 158), -5);
        HAN0 F 1 DoSelectOffset (( 67, 168), -5);
        stop;
    Deselect:
        THMP A 1 {
            if (health <= 0)
                return ResolveState ("Deselect.DEAD");

            DoSelectOffset ((0, 0));
            return ResolveState (null);
        }
        THMP H 1 {
            DoSelectOffset ((8, 4));
            A_Overlay (-5, "Deselect.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        THMP H 1 DoSelectOffset ((8 + (30 * 1), 4 + (15 * 1)));
        THMP H 1 DoSelectOffset ((8 + (30 * 2), 4 + (15 * 2)));
        THMP H 1 DoSelectOffset ((8 + (30 * 3), 4 + (15 * 3)));
        THMP H 1 DoSelectOffset ((8 + (30 * 4), 4 + (15 * 4)));
        goto TrueDeselect;

    Fire:
        THMP A 1 {
            if (!invoker.chambered)
                return ResolveState ("Pump");

            class<Actor> projType;
            int grenType = invoker.magazine [invoker.magazine.Size () - 1];
            invoker.magazine.Pop ();
            switch (grenType) {
                default:
                case S7_TH_None:
                    return ResolveState ("Ready2"); // Shouldn't happen, but better safe than sorry.
                    break;
                case S7_TH_Exp:
                    invoker.casingType = 'S7_50mmCasing';
                    projType = 'S7_ThumperGrenade';
                    break;
                case S7_TH_Frag:
                    invoker.casingType = 'S7_50mmCasingFrag';
                    projType = 'S7_ThumperGrenadeFrag';
                    break;
                case S7_TH_Therm:
                    invoker.casingType = 'S7_50mmCasingTherm';
                    projType = 'S7_ThumperGrenadeTherm';
                    break;
                case S7_TH_Flare:
                    invoker.casingType = 'S7_50mmCasingFlare';
                    projType = 'S7_ThumperGrenadeFlare';
                    break;
                case S7_TH_Cluster:
                    invoker.casingType = 'S7_50mmCasingCluster';
                    projType = 'S7_ThumperGrenadeCluster';
                    break;
                case S7_TH_Nail:
                    invoker.casingType = 'S7_50mmCasingNail';
                    projType = 'S7_ThumperGrenadeNail';
                    break;
                case S7_TH_NGas:
                    invoker.casingType = 'S7_50mmCasingNGas';
                    projType = 'S7_ThumperGrenadeNGas';
                    break;
            }

            A_PlaySound ("Weapons/Thumper/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();

            S7_A_FireBullets (projType, offs: (10, 9, 6), pitchOffs: -1.5, bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 4.5, 3));
            invoker.chambered = false;

            S7_Recoil (-1.65);

            return ResolveState (null);
        }
        THMP A 1 {
            S7_Recoil (-1.65);
            A_WeaponOffset (11, 32 + 5);
        }
        THMP A 1 A_WeaponOffset (17, 32 + 9);
        THMP A 1 A_WeaponOffset (14, 32 + 7, WOF_Interpolate);
        THMP A 1 A_WeaponOffset ( 7, 32 + 3, WOF_Interpolate);
        THMP A 2 A_WeaponOffset ( 0, 32, WOF_Interpolate);
        goto Ready2;

    ChangeMode:
        THMP A 5 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            int i = invoker.selectedPool + 1;

            while (TRUE) {
                if (i == invoker.selectedPool)
                    return ResolveState (null);
                else if (i >= S7_TH_EndToken)
                    i = S7_TH_None;
                else if (CheckInventory (S7_Thumper.PoolNames [i], 1) || (player.cmd.buttons & BT_AltAttack))
                    break;

                i++;
            }

            if (i > S7_TH_None && i < S7_TH_EndToken && i != invoker.selectedPool) {
                A_PlaySound ("Weapons/ModeChange", CHAN_6);
                invoker.selectedPool = i;
            }

            invoker.UpdateAmmoQuickBuyData ();

            return ResolveState (null);
        }
        goto Ready2;

    Pump:
        TNT1 A 0 {
            if (invoker.magazine.Size () <= 0)
                return ResolveState ("DryFire");

            invoker.chambered = true;

            A_Overlay (2, "Pump.Anim");

            return ResolveState (null);
        }
        TNT1 A 16;
        goto Ready2;
    Pump.Anim: // 16 tics
        THMP A 2 A_OverlayFlags (2, PSPF_AddWeapon, true);
        THMP B 1 A_WeaponOffset ( 5, 32 +  3, WOF_Interpolate);
        THMP C 1 {
            A_WeaponOffset (16, 32 +  7, WOF_Interpolate);
            A_PlaySound ("Weapons/Thumper/Pump", CHAN_7);

            if (invoker.casingType)
                S7_SpawnCasing ();

            invoker.casingType = NULL;
        }
        THMP E 1 A_WeaponOffset (20, 32 +  9, WOF_Interpolate);
        THMP F 6 A_WeaponOffset (35, 32 + 16, WOF_Interpolate);
        THMP E 1 A_WeaponOffset (26, 32 + 12, WOF_Interpolate);
        THMP C 1 A_WeaponOffset (18, 32 +  9, WOF_Interpolate);
        THMP B 1 A_WeaponOffset ( 3, 32 +  1, WOF_Interpolate);
        THMP A 2 A_WeaponOffset ( 0, 32     , WOF_Interpolate);
        stop;

    Flash:
        THPF AB 1 bright;
        stop;

    DryFire:
        THMP A 1 A_PlaySound ("Weapons/Thumper/Dryfire", CHAN_7);
        TNT1 A 0 {
            if (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload ()) {
                GiveInventory ('S7_Reloading', 1);
                return ResolveState ("Reload");
            }

            return ResolveState (null);
        }
        goto Ready2;

    Reload:
        THMP A 2 {
            if (
                !CheckInventory ('S7_Reloading', 1) ||
                invoker.magazine.Size () >= 5 || invoker.CountCurPoolAmmo () < 1 ||
                invoker.selectedPool <= S7_TH_None || invoker.selectedPool >= S7_TH_EndToken
            )
                return ResolveState ("EndReload");

            if (!invoker.chambered && invoker.magazine.Size () > 0)
                return ResolveState ("InsertShells.Pump2");

            return ResolveState (null);
        }

        TNT1 A 5 A_Overlay (2, "Reload.LowerAnim");
        goto InsertShells;
    Reload.LowerAnim:
        THMP H 1 {
            A_OverlayFlags (2, PSPF_AddWeapon, true);
            A_Overlay (-5, "Deselect.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);

            A_WeaponOffset ((5.2 * 1), 32 + (3.2 * 1));
        }
        THMP H 1 A_WeaponOffset ((5.2 * 2), 32 + (3.2 * 2));
        THMP H 1 A_WeaponOffset ((5.2 * 3), 32 + (3.2 * 3));
        THMP H 1 A_WeaponOffset ((5.2 * 4), 32 + (3.2 * 4));
        THMP H 1 A_WeaponOffset ((5.2 * 5), 32 + (3.2 * 5));
        stop;
    Reload.RaiseAnim:
        THMP H 1 {
            A_OverlayFlags (2, PSPF_AddWeapon, true);
            A_Overlay (-5, "Select.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);

            A_WeaponOffset ((5.2 * 5), 32 + (3.2 * 5));
        }
        THMP H 1 A_WeaponOffset ((5.2 * 4), 32 + (3.2 * 4));
        THMP H 1 A_WeaponOffset ((5.2 * 3), 32 + (3.2 * 3));
        THMP H 1 A_WeaponOffset ((5.2 * 2), 32 + (3.2 * 2));
        THMP H 1 A_WeaponOffset ((5.2 * 1), 32 + (3.2 * 1));
        stop;

    InsertShells:
        THMP H 13 {
            A_WeaponOffset ((5.2 * 5), 32 + (3.2 * 5), WOF_Interpolate);

            if (!CheckInventory ('S7_Reloading', 1) || invoker.magazine.Size () >= 5 || invoker.CountCurPoolAmmo () < 1 || invoker.selectedPool <= S7_TH_None || invoker.selectedPool >= S7_TH_EndToken)
                return ResolveState ("Reloaded");

            return ResolveState (null);
        }
        THMP H 1 {
            A_PlaySound ("Weapons/Thumper/ShellIn", CHAN_6);
            invoker.magazine.Insert (0, invoker.selectedPool);
            TakeInventory (S7_Thumper.PoolNames [invoker.selectedPool], 1);
            A_WeaponOffset ((5.2 * 5) - 6.5, 32 + (3.2 * 5) - 3);
        }
        THMP H 2 A_WeaponOffset ((5.2 * 5) - 10, 32 + (3.2 * 5) - 5);
        THMP H 2 A_WeaponOffset ((5.2 * 5) -  4, 32 + (3.2 * 5) - 3, WOF_Interpolate);
        THMP H 3 A_WeaponOffset ((5.2 * 5)     , 32 + (3.2 * 5)    , WOF_Interpolate);
        TNT1 A 0 A_JumpIf (!invoker.chambered, "InsertShells.Pump");
        loop;

    InsertShells.Pump:
        TNT1 A 5 A_Overlay (2, "Reload.RaiseAnim");
    InsertShells.Pump2:
        TNT1 A 16 {
            if (invoker.magazine.Size () <= 0)
                return ResolveState ("InsertShells");

            invoker.chambered = true;

            A_Overlay (2, "Pump.Anim");

            return ResolveState (null);
        }
        TNT1 A 5 {
            if (invoker.CountCurPoolAmmo () < 1 || !CheckInventory ('S7_Reloading', 1))
                return ResolveState ("EndReload");

            A_Overlay (2, "Reload.LowerAnim");

            return ResolveState (null);
        }
        goto InsertShells;

    Reloaded:
        TNT1 A 5 A_Overlay (2, "Reload.RaiseAnim");
    EndReload:
        TNT1 A 0 TakeInventory ('S7_Reloading', 0x7FFFFFFF);
        goto Ready2;
    }
}
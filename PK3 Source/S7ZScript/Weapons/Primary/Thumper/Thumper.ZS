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
        S7_BaseWeapon.BindSlot WpSlot_AreaDMG;
        S7_BaseWeapon.UsesMag false;

        +WEAPON.NOAUTOAIM
    }

    bool chambered;
    int selectedPool;
    class<Actor> casingType;
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

    override void DoEffect () {
        Super.DoEffect ();

        int i = 0;
        for (; i < magazine.Size (); i++)
            Owner.SetInventory (MagTokens [i], magazine [i]);
        for (; i < 5; i++)
            Owner.SetInventory (MagTokens [i], 0);

        Owner.SetInventory ('S7_ThumperMag', magazine.Size ());
        Owner.SetInventory ('S7_ThumperSelectedPool', selectedPool - 1);
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

    states {
    Spawn:
        THMP U -1;
        stop;

    Select.Hand:
        HAN0 A 1 DoSelectOffset ((132, 151), -5, forceNoInterpolate: true);
        HAN0 A 1 DoSelectOffset ((149, 140), -5);
        HAN0 A 1 DoSelectOffset ((161, 127), -5);
        HAN0 A 1 DoSelectOffset ((168, 122), -5);
        stop;
    Ready:
        THPR E 1 DoSelectOffset ((77, 55), forceNoInterpolate: true);
        THPR E 1 {
            DoSelectOffset ((45, 32));
            A_Overlay (-5, "Select.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        THPR E 1 DoSelectOffset (( 14,  10));
        THPR E 1 DoSelectOffset ((  1,   1));
        THPR E 1 DoSelectOffset ((-16, -13));
        THMP A 1 {
            DoSelectOffset ((10, 3), forceNoInterpolate: true);
            DoSelectOffset (( 0, 0));
        }
    Ready2:
        THMP A 1 {
            S7_WeaponReady ("Reload", "ChangeMode");

            return ResolveState (null);
        }
        loop;

    Deselect.Hand:
        HAN0 A 1 DoSelectOffset ((168, 122), -5, forceNoInterpolate: true);
        HAN0 A 1 DoSelectOffset ((161, 127), -5);
        HAN0 A 1 DoSelectOffset ((149, 140), -5);
        HAN0 A 1 DoSelectOffset ((132, 151), -5);
        stop;
    Deselect:
        THMP A 1 {
            if (health <= 0)
                return ResolveState ("Deselect.DEAD");

            DoSelectOffset ((0, 0));
            return ResolveState (null);
        }
        THPR E 1 {
            DoSelectOffset ((-16, -13));
            A_Overlay (-5, "Deselect.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        THPR E 1 DoSelectOffset (( 1,  1));
        THPR E 1 DoSelectOffset ((14, 10));
        THPR E 1 DoSelectOffset ((45, 32));
        THPR E 1 DoSelectOffset ((77, 55));
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
                    invoker.casingType = 'S7_50mmCasingSpawn';
                    projType = 'S7_ThumperGrenade';
                    break;
                case S7_TH_Frag:
                    invoker.casingType = 'S7_50mmCasingSpawnFrag';
                    projType = 'S7_ThumperGrenadeFrag';
                    break;
                case S7_TH_Therm:
                    invoker.casingType = 'S7_50mmCasingSpawnTherm';
                    projType = 'S7_ThumperGrenadeTherm';
                    break;
                case S7_TH_Flare:
                    invoker.casingType = 'S7_50mmCasingSpawnFlare';
                    projType = 'S7_ThumperGrenadeFlare';
                    break;
                case S7_TH_Cluster:
                    invoker.casingType = 'S7_50mmCasingSpawnCluster';
                    projType = 'S7_ThumperGrenadeCluster';
                    break;
                case S7_TH_Nail:
                    invoker.casingType = 'S7_50mmCasingSpawnNail';
                    projType = 'S7_ThumperGrenadeNail';
                    break;
                case S7_TH_NGas:
                    invoker.casingType = 'S7_50mmCasingSpawnNGas';
                    projType = 'S7_ThumperGrenadeNGas';
                    break;
            }

            A_PlaySound ("Weapons/Thumper/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();

            S7_A_FireBullets (projType, offs: (10, 9, 6), bonusDMGFactor: invoker.enchantment_DamageBonus, flags: S7_FB_UseAmmo);
            S7_A_SpawnSFX ('S7_ShotSmoke_2_Spawner', offs: (0, 4.5, 1));
            invoker.chambered = false;

            S7_Recoil (-1.65);

            return ResolveState (null);
        }
        THMP A      1 S7_Recoil (-1.65);
        THMP DBCDEA 1;
        goto Ready2;

    ChangeMode:
        THMP A 5 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);
            A_PlaySound ("Weapons/ModeChange", CHAN_6);

            bool looped = false;
            int i = invoker.selectedPool + 1;

            while (TRUE) {
                if (i == invoker.selectedPool)
                    return ResolveState (null);
                else if (i >= S7_TH_EndToken)
                    i = 0;
                else if (CheckInventory (S7_Thumper.PoolNames [i], 1))
                    break;

                i++;
            }

            if (i > S7_TH_None && i < S7_TH_EndToken && i != invoker.selectedPool)
                invoker.selectedPool = i;

            return ResolveState (null);
        }
        goto Ready2;

    Pump:
        THMP A   1 {
            if (invoker.magazine.Size () <= 0)
                return ResolveState ("DryFire");

            invoker.chambered = true;

            return ResolveState (null);
        }
        THPP A   2;
        THPP B   1 {
            A_PlaySound ("Weapons/Thumper/Pump", CHAN_7);

            if (invoker.casingType)
                S7_A_SpawnSFX (invoker.casingType, offs: (0, 18, 14));

            invoker.casingType = NULL;
        }
        THPP C   1;
        THPP D   6;
        THPP CBA 1;
        THMP A   2;
        goto Ready2;

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
        THMP A    2 {
            if (!CheckInventory ('S7_Reloading', 1) || invoker.magazine.Size () >= 5 || invoker.CountCurPoolAmmo () < 1 || invoker.selectedPool <= S7_TH_None || invoker.selectedPool >= S7_TH_EndToken)
                return ResolveState ("EndReload");

            return ResolveState (null);
        }
        THPR A    2 A_JumpIf (!invoker.chambered && invoker.magazine.Size () > 0, "InsertShells.Pump2");
        THPR BCDE 2;
        goto InsertShells;
    InsertShells:
        THPR E 13 {
            if (!CheckInventory ('S7_Reloading', 1) || invoker.magazine.Size () >= 5 || invoker.CountCurPoolAmmo () < 1 || invoker.selectedPool <= S7_TH_None || invoker.selectedPool >= S7_TH_EndToken)
                return ResolveState ("Reloaded");

            return ResolveState (null);
        }
        THPR E 8 {
            A_PlaySound ("Weapons/Thumper/ShellIn", CHAN_6);
            invoker.magazine.Insert (0, invoker.selectedPool);
            TakeInventory (S7_Thumper.PoolNames [invoker.selectedPool], 1);
        }
        TNT1 A 0 A_JumpIf (!invoker.chambered, "InsertShells.Pump");
        loop;
    InsertShells.Pump:
        THPR EDCBA 2;
    InsertShells.Pump2:
        THMP A     1 {
            if (invoker.magazine.Size () <= 0)
                return ResolveState ("InsertShells");

            invoker.chambered = true;

            return ResolveState (null);
        }
        THPP A     2;
        THPP B     1 {
            A_PlaySound ("Weapons/Thumper/Pump", CHAN_7);

            if (invoker.casingType)
                S7_A_SpawnSFX (invoker.casingType, offs: (0, 18, 14));

            invoker.casingType = NULL;
        }
        THPP C     1;
        THPP D     6;
        THPP CBA   1;
        THMP A     2 A_JumpIf (invoker.CountCurPoolAmmo () < 1 || !CheckInventory ('S7_Reloading', 1), "EndReload");
        THPR ABCDE 2;
        goto InsertShells;

    Reloaded:
        THPR EDCBA 2;
    EndReload:
        TNT1 A 0 TakeInventory ('S7_Reloading', 0x7FFFFFFF);
        goto Ready2;
    }
}
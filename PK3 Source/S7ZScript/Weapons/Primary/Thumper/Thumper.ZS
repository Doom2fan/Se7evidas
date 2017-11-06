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
class S7_ThumperMag1 : S7_Counter { default { inventory.maxAmount 7; } }
class S7_ThumperMag2 : S7_Counter { default { inventory.maxAmount 7; } }
class S7_ThumperMag3 : S7_Counter { default { inventory.maxAmount 7; } }
class S7_ThumperMag4 : S7_Counter { default { inventory.maxAmount 7; } }
class S7_ThumperMag5 : S7_Counter { default { inventory.maxAmount 7; } }
class S7_ThumperSelectedPool : S7_Counter { default { inventory.maxAmount 7; } }

class S7_ThumperMag : ammo { // This isn't actually used by the weapon. It's just here so HUDs can use it.
    default {
        inventory.maxAmount 5;
        ammo.backpackMaxAmount 5;

        +inventory.ignoreSkill
    }
}

// No more GROSS HACKS! Yay!
class S7_Thumper : S7_BaseWeapon {
    default {
        tag "$THUMPER";
        inventory.pickupMessage "$THUMPER";
        weapon.ammoType1 "S7_ThumperMag";
        weapon.ammoUse 0;
        weapon.ammoGive 0;
        S7_BaseWeapon.Icon "THMPU0";

        +weapon.noAutoAim
    }

    bool chambered;
    int selectedPool;
    string casingType;
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

        return CountInv (PoolNames [selectedPool]);
    }

    override void AttachToOwner (Actor other) {
        super.AttachToOwner (other);

        selectedPool = S7_TH_Exp;
    }

    override void DoEffect () {
        super.DoEffect ();

        int i = 0;
        for (; i < magazine.Size (); i++)
            SetInventory (MagTokens [i], magazine [i]);
        for (; i < 5; i++)
            SetInventory (MagTokens [i], 0);

        SetInventory ("S7_ThumperMag", magazine.Size ());
        SetInventory ("S7_ThumperSelectedPool", selectedPool - 1);
    }

    states {
    Spawn:
        THMP U -1;
        stop;

    Ready:
        THMP VWXYZA 1;
    Ready2:
        THMP A 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            if (CheckInventory ("S7_ChangeFireMode", 1))
                return ResolveState ("ChangeMode");

            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Deselect:
        THMP AZYXWV 1;
        goto TrueDeselect;

    Fire:
        THMP A 1 {
            if (!invoker.chambered)
                return ResolveState ("Pump");

            string projType;
            int grenType = invoker.magazine [invoker.magazine.Size () - 1];
            invoker.magazine.Pop ();
            switch (grenType) {
                default:
                case S7_TH_None:
                    return ResolveState ("Ready2"); // Shouldn't happen, but better safe than sorry.
                    break;
                case S7_TH_Exp:
                    invoker.casingType = "S7_50mmCasingSpawn";
                    projType = "S7_ThumperGrenade";
                    break;
                case S7_TH_Frag:
                    invoker.casingType = "S7_50mmCasingSpawnFrag";
                    projType = "S7_ThumperGrenadeFrag";
                    break;
                case S7_TH_Therm:
                    invoker.casingType = "S7_50mmCasingSpawnTherm";
                    projType = "S7_ThumperGrenadeTherm";
                    break;
                case S7_TH_Flare:
                    invoker.casingType = "S7_50mmCasingSpawnFlare";
                    projType = "S7_ThumperGrenadeFlare";
                    break;
                case S7_TH_Cluster:
                    invoker.casingType = "S7_50mmCasingSpawnCluster";
                    projType = "S7_ThumperGrenadeCluster";
                    break;
                case S7_TH_Nail:
                    invoker.casingType = "S7_50mmCasingSpawnNail";
                    projType = "S7_ThumperGrenadeNail";
                    break;
                case S7_TH_NGas:
                    invoker.casingType = "S7_50mmCasingSpawnNGas";
                    projType = "S7_ThumperGrenadeNGas";
                    break;
            }

            A_PlaySound ("Weapons/Thumper/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();

            A_FireProjectile (projType, 0, 0, 8, -5, 0, -3.0);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 4, 4);
            invoker.chambered = false;

            A_SetPitch (pitch - 1.65, SPF_Interpolate);

            return ResolveState (null);
        }
        THMP A      1 A_SetPitch (pitch - 1.65, SPF_Interpolate);
        THMP DBCDEA 1;
        goto Ready2;

    ChangeMode:
        THMP A 5 {
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);
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

            if (invoker.casingType != "")
                A_FireProjectile (invoker.casingType, 0, 0, 10, -9);

            invoker.casingType = "";
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
        THMP A 1;
        TNT1 A 0 {
            if (CheckInventory ("S7_AutoReloading", 1)) {
                GiveInventory ("S7_Reloading", 1);
                return ResolveState ("Reload");
            }

            return ResolveState (null);
        }
        goto Ready2;

    Reload:
        THMP A    2 {
            if (!CheckInventory ("S7_Reloading", 1) || invoker.magazine.Size () >= 5 || invoker.CountCurPoolAmmo () < 1 || invoker.selectedPool <= S7_TH_None || invoker.selectedPool >= S7_TH_EndToken)
                return ResolveState ("EndReload");

            return ResolveState (null);
        }
        THPR A    2 A_JumpIf (!invoker.chambered && invoker.magazine.Size () > 0, "InsertShells.Pump2");
        THPR BCDE 2;
        goto InsertShells;
    InsertShells:
        THPR E 13 {
            if (!CheckInventory ("S7_Reloading", 1) || invoker.magazine.Size () >= 5 || invoker.CountCurPoolAmmo () < 1 || invoker.selectedPool <= S7_TH_None || invoker.selectedPool >= S7_TH_EndToken)
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

            if (invoker.casingType != "")
                A_FireProjectile (invoker.casingType, 0, 0, 10, -9);

            invoker.casingType = "";
        }
        THPP C     1;
        THPP D     6;
        THPP CBA   1;
        THMP A     2 A_JumpIf (invoker.CountCurPoolAmmo () < 1 || !CheckInventory ("S7_Reloading", 1), "EndReload");
        THPR ABCDE 2;
        goto InsertShells;

    Reloaded:
        THPR EDCBA 2;
    EndReload:
        TNT1 A 0 TakeInventory ("S7_Reloading", 0x7FFFFFFF);
        goto Ready2;
    }
}
//-------------------------------------------------------------------------------------------
//
// R16 "Raptor" Pistol
//
//-------------------------------------------------------------------------------------------
class S7_RaptorClip : Ammo {
    default {
        Inventory.MaxAmount 16;
        Ammo.BackpackMaxAmount 16;

        +INVENTORY.IGNORESKILL
    }
}

class S7_Raptor : S7_BaseWeapon {
    default {
        Tag "$RAPTOR";
        Inventory.PickupMessage "$RAPTOR";
        Weapon.AmmoType1 "S7_RaptorClip";
        Weapon.AmmoType2 "S7_9mmCartridges";
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;
        S7_BaseWeapon.Icon "RPTPA0";
        S7_BaseWeapon.ShortTag "$SHORTRAPTOR";
        S7_BaseWeapon.BindSlot WpSlot_Light;
    }

    bool doubleTap;

    states {
    Spawn:
        RPTP A -1;
        loop;

    Ready:
        RPTN VWXYZA 1;
    Ready2:
        RPTN A 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            invoker.doubleTap = false;
            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Deselect:
        RPTN AZYXWV 1;
        goto TrueDeselect;

    Fire:
        RPTN B 1 bright {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/Raptor/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 3, 3.75);

            for (int i = 0; i < 2; i++) {
                A_FireProjectile ("S7_9mmCasingSpawn", 0, 0, 7, -2);
                A_FireProjectile ("S7_RaptorTracer", fRandom [weaponSpread] (-0.4, 0.4), 1, 5, 0, 0, fRandom [weaponSpread] (-0.4, 0.4));
            }

            S7_Recoil (-0.8);

            return ResolveState (null);
        }
        RPTN C 1 S7_Recoil (-0.8);
        RPTN A 3;
        RPTN A 1 {
            if (invoker.doubleTap)
                return;

            invoker.doubleTap = true;
            A_Refire ();
        }
        RPTN A 6 A_ClearRefire;
        goto Ready2;

    AltFire:
        RPTM A    1 A_PlaySound ("Weapons/Raptor/Melee", CHAN_5);
        RPTM BC   1;
        RPTM D    1 A_CustomPunch (15 * fRandom [weaponSpc] (1.0, 3.0), true, 0, "S7_RaptorMPuff", 85);
        RPTM EFGH 1;
        TNT1 A    4;
        RPTN A    1;
        goto Ready2;

    DryFire:
        RPTN A 3 {
            A_PlaySound ("Weapons/DryFirePistol", CHAN_7);
            A_ClearRefire ();
            invoker.doubleTap = false;
        }
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading"), "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            TakeInventory ("S7_Reloading", 1);

            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1))
                return ResolveState ("Ready2");

            int ammoAmount = min (FindInventory (invoker.ammoType1).maxAmount - CountInv (invoker.ammoType1), CountInv (invoker.ammoType2));
            if (ammoAmount <= 0)
                return ResolveState ("Ready2");

            GiveInventory (invoker.ammoType1, ammoAmount);
            TakeInventory (invoker.ammoType2, ammoAmount);

            return ResolveState ("ReloadFinish");
        }
    ReloadFinish:
        RPTR FGGH  1;
        RPTR I     4;
        RPTR I    23 A_PlaySound ("Weapons/Raptor/Out", CHAN_6);
        RPTR I     1 A_PlaySound ("Weapons/Raptor/In", CHAN_7);
        RPTR JDD   1;
        RPTR BA    1;
        RPTN A     1;
        goto Ready2;
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
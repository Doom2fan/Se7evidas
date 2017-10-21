//-------------------------------------------------------------------------------------------
//
// R16 "Raptor" Pistol
//
//-------------------------------------------------------------------------------------------
class S7_RaptorClip : ammo {
    default {
        inventory.maxAmount 16;
        ammo.backpackMaxAmount 16;

        +inventory.ignoreSkill
    }
}

class S7_Raptor : S7_BaseWeapon {
    default {
        tag "$RAPTOR";
        inventory.pickupMessage "$RAPTOR";
        weapon.ammoType1 "S7_RaptorClip";
        weapon.ammoType2 "S7_9mmCartridges";
        weapon.ammoUse 1;
        weapon.ammoGive 0;
        S7_BaseWeapon.Icon "RPTP0";
    }

    bool doubleTap;

    states {
    Spawn:
        RPTP A -1;
        loop;

    Ready:
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

    Fire:
        RPTN B 1 bright {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/Raptor/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 3, 4);

            for (int i = 0; i < 2; i++) {
                A_FireProjectile ("S7_9mmCasingSpawn", 0, 0, 7, -2);
                A_FireProjectile ("S7_RaptorTracer", fRandom [weaponSpread] (-0.4, 0.4), 1, 5, 0, 0, fRandom [weaponSpread] (-0.4, 0.4));
            }

            A_SetPitch (pitch - 0.8, SPF_Interpolate);

            return ResolveState (null);
        }
        RPTN C 1 A_SetPitch (pitch - 0.8, SPF_Interpolate);
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
        TNT1 A 0 A_JumpIfInventory ("S7_AutoReloading", 1, "Reload");
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

class S7_RaptorMPuff : actor {
    default {
        renderStyle "translucent";
        alpha 0.5;
        seeSound "Weapons/Raptor/Melee/Hit";
        attackSound "Weapons/Raptor/Melee/Wall";

        +noBlockmap +noGravity +noExtremeDeath +puffOnActors
        +forceXYBillboard
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
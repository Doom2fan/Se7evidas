//-------------------------------------------------------------------------------------------
//
// SR20 "Hitter" .45 ACP SMG
//
//-------------------------------------------------------------------------------------------
class S7_HitterSMGClip : ammo {
    default {
        inventory.maxAmount 62;
        ammo.backpackMaxAmount 62;

        +inventory.ignoreSkill
    }
}

class S7_HitterSMG : S7_BaseWeapon {
    default {
        tag "$HITTERSMG";
        inventory.pickupMessage "HITTERSMG";
        weapon.ammoType1 "S7_HitterSMGClip";
        weapon.ammoType2 "S7_45ACPCartridges";
        weapon.ammoUse 1;
        weapon.ammoGive 0;
    }

    bool upperJammed, lowerJammed;

    states {
    Spawn:
        SR20 Z -1;
        loop;

    Ready:
    Ready2:
        SR20 A 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            TakeInventory ("S7_WeapReady", 0x7FFFFFFF);

            GiveInventory ("S7_WeapReady", 1);
            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Fire:
        SR20 A 1 A_JumpIf (!CheckInventory (invoker.ammoType1, 2), "DryFire");
    Hold:
        SR20 A  1 {
            if (!CheckInventory (invoker.ammoType1, 2))
                return ResolveState ("DryFire.Firing");

            if (invoker.upperJammed && invoker.lowerJammed)
                return ResolveState ("DoubleJammed");

            if (!invoker.upperJammed) {
                A_FireProjectile ("S7_45ACPCasingSpawn", 0, 0, 9, -2);
                A_FireProjectile ("S7_HitterSMGTracer", fRandom [weaponSpread] (-0.5, 0.5), 1, 3, 2, 0, fRandom [weaponSpread] (-0.5, 0.5));
            } else
                A_PlaySound ("Weapons/DryFirePistol", CHAN_6);

            if (!invoker.lowerJammed) {
                A_FireProjectile ("S7_45ACPCasingSpawn", 0, 0, 9, -2);
                A_FireProjectile ("S7_HitterSMGTracer", fRandom [weaponSpread] (-0.5, 0.5), 1, 2, 2, 0, fRandom [weaponSpread] (-0.5, 0.5));
            } else
                A_PlaySound ("Weapons/DryFirePistol", CHAN_7);

            if (invoker.upperJammed)
                A_GunFlash ("Flash.UpperJammed");
            else if (invoker.lowerJammed)
                A_GunFlash ("Flash.LowerJammed");
            else
                A_GunFlash ("Flash");

            A_PlaySound ("Weapons/HitterSMG/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 4.5);

            if (random [weaponSpc] (0, 255) < 3) {
                int jamType = randomPick [weaponSpc] (0, 0, 1, 1, 2); // More likely to jam only one barrel

                if (jamType == 0 || jamType == 3)
                    invoker.upperJammed = true;
                if (jamType == 1 || jamType == 3)
                    invoker.lowerJammed = true;
            }

            A_SetPitch (pitch - 0.6, SPF_Interpolate);

            return ResolveState (null);
        }
        SR20 E  1 A_SetPitch (pitch - 0.6, SPF_Interpolate);
        SR20 D  1;
        SR20 C  1 A_Refire ("Hold");
        SR20 BA 1 A_ClearRefire;
        SR20 A  9;
        goto Ready2;

    DryFire:
        SR20 A 3 A_PlaySound ("Weapons/DryFirePistol", CHAN_7);
        TNT1 A 0 A_JumpIfInventory ("S7_AutoReloading", 1, "Reload");
        goto Ready2;
    DryFire.Firing:
        SR20 A    1 {
            A_ClearRefire ();
            A_PlaySound ("Weapons/DryFirePistol", CHAN_7);
        }
        SR20 EDCB 1;
        TNT1 A    0 A_JumpIfInventory ("S7_AutoReloading", 1, "Reload");
        goto Ready2;

    DoubleJammed:
        SR20 A     1 {
            A_ClearRefire ();
            A_PlaySound ("Weapons/DryFirePistol", CHAN_7);
        }
        SR20 CEDCB 1;
        SR20 A     1;
        goto Ready2;

    AltFire:
        SR20 A      1 A_ClearRefire;
        SR20 KLMNOP 1;
        SR20 Q      1 {
            if (invoker.upperJammed || CheckInventory (invoker.ammoType1, 1)) {
                A_FireProjectile ("S7_45ACPCasingSpawn", 0, 0, 9, -2);
                if (!invoker.upperJammed)
                    TakeInventory (invoker.ammoType1, 1);
            }
            if (invoker.lowerJammed || CheckInventory (invoker.ammoType1, 1)) {
                A_FireProjectile ("S7_45ACPCasingSpawn", 0, 0, 9, -2);
                if (!invoker.lowerJammed)
                    TakeInventory (invoker.ammoType1, 1);
            }

            invoker.upperJammed = false;
            invoker.lowerJammed = false;
            A_PlaySound ("Weapons/HitterSMG/Slide", CHAN_6);
        }
        SR20 RSTUVW 1;
        SR20 A 1 A_JumpIf (CheckInventory ("S7_Reloading", 1), "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            A_ClearRefire ();

            if (invoker.upperJammed || invoker.lowerJammed)
                return ResolveState ("AltFire");

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
        // Reloading anim here
        SR20 AF  1;
        SR20 G   1 A_PlaySound ("Weapons/HitterSMG/Out", CHAN_6);
        SR20 H   1;
        SR20 I  18;
        SR20 I  28 A_PlaySound ("Weapons/HitterSMG/In", CHAN_7);
        SR20 JA  1;
        goto Ready2;

    Flash:
        SR2F A 1 bright;
        stop;
    Flash.UpperJammed:
        SR2F C 1 bright;
        stop;
    Flash.LowerJammed:
        SR2F B 1 bright;
        stop;
    }
}
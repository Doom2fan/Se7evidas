//-------------------------------------------------------------------------------------------
//
// Avtomat Kalashnikova 47
//
//-------------------------------------------------------------------------------------------
class S7_AK47Clip : ammo {
    default {
        inventory.maxAmount 30;
        ammo.backpackMaxAmount 30;

        +inventory.ignoreSkill
    }
}

class S7_AK47 : S7_BaseWeapon {
    default {
        tag "$AK47";
        inventory.pickupMessage "$AK47";
        weapon.ammoType1 "S7_AK47Clip";
        weapon.ammoType2 "S7_762x39Cartridges";
        weapon.ammoUse 1;
        weapon.ammoGive 0;
        S7_BaseWeapon.Icon "AK4PA0";
    }

    bool halfTic, reloadChamber; // Temporary stuff
    bool semiAuto, semiOnly; // Persistent stuff

    override void DoEffect () {
        super.DoEffect ();

        if (semiOnly)
            fireModeIcon = FMI_None;
        else
            fireModeIcon = semiAuto ? FMI_SemiAuto : FMI_FullAuto;
    }

    states {
    Spawn:
        AK4P A -1;
        loop;

    Ready:
        //AK47 VWXYZA 1;
    Ready2:
        AK47 A 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            if (CheckInventory ("S7_ChangeFireMode", 1))
                return ResolveState ("ChangeMode");

            GiveInventory ("S7_WeapReady", 1);
            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    ChangeMode:
        AK47 A 5 {
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            if (invoker.semiOnly)
                invoker.semiAuto = true;
            else {
                if (invoker.semiAuto)
                    invoker.semiAuto = false;
                else
                    invoker.semiAuto = true;

                A_PlaySound ("Weapons/ModeChange", CHAN_7);
            }
        }
        goto Ready2;

    Deselect:
        //AK47 A     1;
        //AK47 ZYXWV 1;
        goto Super::Deselect;

    Fire:
        AK47 A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_AlertMonsters ();
            A_GunFlash ("Flash");
            A_FireProjectile ("S7_AK47_Tracer", fRandom [weaponSpread] (-0.16, 0.16), 1, 5, -0.5, 0, fRandom [weaponSpread] (-0.16, 0.16));
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 4);
            A_FireProjectile ("S7_RifleCasingSpawn", 0, 0, 11, -12);

            A_PlaySound ("Weapons/AK47/Fire", (invoker.halfTic ? CHAN_5 : CHAN_Weapon));
            A_SetPitch (pitch - 0.7, SPF_Interpolate);

            return ResolveState (null);
        }
        AK47 C 1 A_SetPitch (pitch - 0.7, SPF_Interpolate);
        AK47 B 1;
        AK47 C 1;
        AK47 A 1 {
            if (invoker.halfTic) {
                invoker.halfTic = false;
                return ResolveState ("Fire.End");
            }

            invoker.halfTic = true;
            return ResolveState (null);
        }
    Fire.End:
        AK47 A 1 {
            if (invoker.semiOnly || invoker.semiAuto)
                return ResolveState ("Fire.Semi");

            A_Refire ("Fire");
            return ResolveState (null);
        }
        goto Ready2;
    Fire.Semi:
        TNT1 A   0 { invoker.halfTic = false; }
        AK47 AAA 1 A_WeaponReady (WRF_NoSecondary | WRF_DisableSwitch | WRF_NoBob);
        goto Ready2;

    DryFire:
        AK47 A 3 A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
        TNT1 A 0 A_JumpIfInventory ("S7_AutoReloading", 1, "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            TakeInventory ("S7_Reloading", 1);

            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1))
                return ResolveState ("Ready2");

            if (CheckInventory (invoker.ammoType1, 1)) // If there's still a bullet chambered, set reloadChamber to false
                invoker.reloadChamber = false;
            else // If not, (i.e. the mag is empty) set reloadChamber to false
                invoker.reloadChamber = true;

            int ammoAmount = min (FindInventory (invoker.ammoType1).maxAmount - CountInv (invoker.ammoType1), CountInv (invoker.ammoType2));
            if (ammoAmount <= 0)
                return ResolveState ("Ready2");

            GiveInventory (invoker.ammoType1, ammoAmount);
            TakeInventory (invoker.ammoType2, ammoAmount);

            return ResolveState ("ReloadFinish");
        }
    ReloadFinish:
        AK47 ADEF  2;
        AK47 GHI   1;
        AK47 J     3;
        AK47 K     1 A_PlaySound ("Weapons/AK47/Out", CHAN_6);
        AK47 LM    1;
        AK47 N    15;
        AK47 O     1 A_PlaySound ("Weapons/AK47/In", CHAN_7);
        AK47 PQRS  1;
        AK47 J     4;
        AK47 TUVWA 1;

        TNT1 A 0 A_JumpIf (invoker.reloadChamber, "ReloadFinish.Chamber");
        goto Reload.End;
    ReloadFinish.Chamber:
        AK47 A     2;
        AK42 ABCDE 2;
        AK42 F     2 A_PlaySound ("Weapons/AK47/Bolt", CHAN_6);
        AK42 GH    2;
        AK42 IJKLM 1;
        AK47 A     2;
        goto Reload.End;
    Reload.End:
        AK47 A 2 { invoker.reloadChamber = false; }
        goto Ready2;

    // Muzzle flashes
    Flash:
        AK4F AB 1 bright;
        stop;
    }
}
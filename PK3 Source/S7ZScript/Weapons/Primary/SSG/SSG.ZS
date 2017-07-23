//-------------------------------------------------------------------------------------------
//
// Super Shotgun
//
//-------------------------------------------------------------------------------------------
class S7_SSGLeftLoadedToken  : S7_Boolean { } // These are for HUDs and stuff
class S7_SSGRightLoadedToken : S7_Boolean { }
class S7_SSGFauxClip : ammo {
    default {
        inventory.maxAmount 2;
        ammo.backpackMaxAmount 2;

        +inventory.ignoreSkill
    }
}

class S7_SSG : S7_BaseWeapon {
    default {
        tag "$SSG";
        inventory.pickupMessage "$SSG";
        weapon.ammoType1 "S7_SSGFauxClip";
        weapon.ammoType2 "S7_12gaShells";
        weapon.ammoUse 0;
        weapon.ammoGive 0;
    }

    bool leftLoaded, rightLoaded, firingBoth;

    override void DoEffect () {
        super.DoEffect ();

        Owner.SetInventory ("S7_SSGLeftLoadedToken",  (leftLoaded  ? 1 : 0));
        Owner.SetInventory ("S7_SSGRightLoadedToken", (rightLoaded ? 1 : 0));
        Owner.SetInventory ("S7_SSGFauxClip", Owner.CountInv ("S7_SSGLeftLoadedToken") + Owner.CountInv ("S7_SSGRightLoadedToken"));
    }

    override void DetachFromOwner () {
        Owner.SetInventory ("S7_SSGLeftLoadedToken",  0);
        Owner.SetInventory ("S7_SSGRightLoadedToken", 0);
        Owner.SetInventory ("S7_SSGFauxClip", 0);
    }

    states {
    Spawn:
        SSGP A -1;
        loop;

    Ready:
        SSGS ABCDE 1;
        SSG0 A     1;
    Ready2:
        SSG0 A 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            bool attack = S7_ActorExtensions.KeyPressed (invoker.Owner, BT_ATTACK), altAttack = S7_ActorExtensions.KeyPressed (invoker.Owner, BT_ALTATTACK);
            if (attack && altAttack)
                return ResolveState ("Fire.Both2");
            if (attack)
                return ResolveState ("Fire.Left");
            if (altAttack)
                return ResolveState ("Fire.Right");

            GiveInventory ("S7_WeapReady", 1);
            A_WeaponReady (WRF_NoFire);

            return ResolveState (null);
        }
        loop;

    Deselect:
        SSG0 A     1;
        SSGS EDCBA 1;
        goto TrueDeselect;

    Fire.Left:
        SSG0 A 1;
        SSG5 A 1 {
            if (S7_ActorExtensions.KeyPressed (invoker.Owner, BT_ALTATTACK))
                return ResolveState ("Fire.Both");

            if (!invoker.leftLoaded)
                return ResolveState ("DryFireLeft");

            A_AlertMonsters ();
            A_PlaySound ("Weapons/SSG/Fire", CHAN_Weapon);
            A_GunFlash ("Flash.Left");

            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 1, 2);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 1, 2);
            for (int i = 0; i < 9; i++)
                A_FireProjectile ("S7_12gaTracer", fRandom [weaponSpread] (-0.35, 0.35), 1, 2, -1, 0, fRandom [weaponSpread] (-0.35, 0.35));
            invoker.leftLoaded = false;

            A_SetPitch (pitch - 2.175, SPF_Interpolate);

            return ResolveState (null);
        }
        SSG5 B 1 A_SetPitch (pitch - 2.175, SPF_Interpolate);
        goto Ready2;
    Fire.Right:
        SSG0 A 1;
        SSG5 A 1 {
            if (S7_ActorExtensions.KeyPressed (invoker, BT_ATTACK))
                return ResolveState ("Fire.Both");

            if (!invoker.rightLoaded)
                return ResolveState ("DryFireRight");

            A_AlertMonsters ();
            A_PlaySound ("Weapons/SSG/Fire", CHAN_5);
            A_GunFlash ("Flash.Right");

            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 2);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 2);
            for (int i = 0; i < 9; i++)
                A_FireProjectile ("S7_12gaTracer", fRandom [weaponSpread] (-0.35, 0.35), 1, 3, -1, 0, fRandom [weaponSpread] (-0.35, 0.35));
            invoker.rightLoaded = false;

            A_SetPitch (pitch - 2.175, SPF_Interpolate);

            return ResolveState (null);
        }
        SSG5 B 1 A_SetPitch (pitch - 2.175, SPF_Interpolate);
        goto Ready2;

    Fire.Both2:
        SSG0 A 1;
    Fire.Both:
        SSG5 A 1 {
            if (!invoker.leftLoaded && !invoker.rightLoaded)
                return ResolveState ("DryFireBoth");
            else if (!invoker.leftLoaded)
                return ResolveState ("Fire.Both.DryLeft");
            else if (!invoker.rightLoaded)
                return ResolveState ("Fire.Both.DryRight");

            A_AlertMonsters ();
            A_PlaySound ("Weapons/SSG/Fire", CHAN_Weapon);
            A_GunFlash ("Flash.Both");

            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 1, 2);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 1, 2);
            for (int i = 0; i < 9; i++)
                A_FireProjectile ("S7_12gaTracer", fRandom [weaponSpread] (-0.35, 0.35), 1, 2, -1, 0, fRandom [weaponSpread] (-0.35, 0.35));
            invoker.leftLoaded = false;

            A_SetPitch (pitch - 1.0875, SPF_Interpolate);

            return ResolveState (null);
        }
        SSG5 A 1 {
            A_AlertMonsters ();
            A_PlaySound ("Weapons/SSG/Fire", CHAN_5);

            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 2);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 2);
            for (int i = 0; i < 9; i++)
                A_FireProjectile ("S7_12gaTracer", fRandom [weaponSpread] (-0.35, 0.35), 1, 3, -1, 0, fRandom [weaponSpread] (-0.35, 0.35));
            invoker.rightLoaded = false;

            A_SetPitch (pitch - 5.4375, SPF_Interpolate); // 2.175 * 2.5
        }
        SSG5 B 1 A_SetPitch (pitch - 2.175, SPF_Interpolate);
        SSG0 A 4;
        goto Ready2;
    Fire.Both.DryLeft:
        SSG5 A 1 A_PlaySound ("Weapons/DryFireShotgun", CHAN_Weapon);
        SSG5 A 1 {
            A_AlertMonsters ();
            A_PlaySound ("Weapons/SSG/Fire", CHAN_5);
            A_GunFlash ("Flash.Right");

            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 2);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 2);
            for (int i = 0; i < 9; i++)
                A_FireProjectile ("S7_12gaTracer", fRandom [weaponSpread] (-0.35, 0.35), 1, 3, -1, 0, fRandom [weaponSpread] (-0.35, 0.35));
            invoker.rightLoaded = false;

            A_SetPitch (pitch - 2.175, SPF_Interpolate);
        }
        SSG5 B 1 A_SetPitch (pitch - 2.175, SPF_Interpolate);
        SSG0 A 4;
        goto Ready2;
    Fire.Both.DryRight:
        SSG5 A 1 {
            A_AlertMonsters ();
            A_PlaySound ("Weapons/SSG/Fire", CHAN_Weapon);
            A_GunFlash ("Flash.Left");

            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 1, 2);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 1, 2);
            for (int i = 0; i < 9; i++)
                A_FireProjectile ("S7_12gaTracer", fRandom [weaponSpread] (-0.35, 0.35), 1, 2, -1, 0, fRandom [weaponSpread] (-0.35, 0.35));
            invoker.leftLoaded = false;

            A_SetPitch (pitch - 2.175, SPF_Interpolate);

            return ResolveState (null);
        }
        SSG5 B 1 {
            A_PlaySound ("Weapons/DryFireShotgun", CHAN_6);
            A_SetPitch (pitch - 2.175, SPF_Interpolate);
        }
        SSG0 A 5;
        goto Ready2;

    Flash.Left:
        SSG5 CD 1 bright;
        stop;
    Flash.Right:
        SSG5 EF 1 bright;
        stop;
    Flash.Both:
        SSG5 CGF 1 bright;
        stop;

    DryFireLeft:  SSG0 A 3 A_PlaySound ("Weapons/DryFireShotgun", CHAN_6); goto DryFireEnd;
    DryFireRight: SSG0 A 3 A_PlaySound ("Weapons/DryFireShotgun", CHAN_7); goto DryFireEnd;
    DryFireBoth:  SSG0 A 1 A_PlaySound ("Weapons/DryFireShotgun", CHAN_6);
                  SSG0 A 2 A_PlaySound ("Weapons/DryFireShotgun", CHAN_7); goto DryFireEnd;

    DryFireEnd:
        TNT1 A 0 A_JumpIf (!invoker.leftLoaded && !invoker.rightLoaded && CheckInventory ("S7_AutoReloading", 1), "Reload");
        goto Ready2;

    Reload:
        TNT1 A     0 {
            TakeInventory ("S7_Reloading", 1);

            if ((invoker.leftLoaded && invoker.rightLoaded) ||
                (!invoker.leftLoaded && !invoker.rightLoaded && !CheckInventory (invoker.ammoType2, 2)) ||
                (!invoker.leftLoaded && !CheckInventory (invoker.ammoType2, 1)) ||
                (!invoker.rightLoaded && !CheckInventory (invoker.ammoType2, 1)))
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        SSG0 AAABC 1;
        SSG0 D     1 A_PlaySound ("Weapons/SSG/Open", CHAN_7);
        SSG0 E     1;
        TNT1 A     0 {
            if (!invoker.leftLoaded && !invoker.rightLoaded)
                return ResolveState ("LoadBoth");
            else if (!invoker.leftLoaded && invoker.rightLoaded)
                return ResolveState ("LoadLeft");
            else if (invoker.leftLoaded && !invoker.rightLoaded)
                return ResolveState ("LoadRight");

            return ResolveState ("ReloadEnd"); // Shouldn't EVER get here. If it still somehow did, uh... Just close the shotgun without reloading.
        }

    LoadBoth:
        SSG0 F         1 {
            A_FireProjectile ("S7_12gaShellCasingSpawn", 0, 0, 4, -16);
            A_FireProjectile ("S7_12gaShellCasingSpawn", 0, 0, 7, -18);
        }
        SSG0 GHIJKLMNO 1;
        SSG0 P         1 {
            A_PlaySound ("Weapons/SSG/In", CHAN_6);
            invoker.leftLoaded = true;
            TakeInventory (invoker.ammoType2, 1);
        }
        SSG0 Q         4;
        SSG0 RSTUVWXYZ 1;
        SSG1 A         1;
        SSG1 B         1 {
            A_PlaySound ("Weapons/SSG/In", CHAN_7);
            invoker.rightLoaded = true;
            TakeInventory (invoker.ammoType2, 1);
        }
        SSG1 C         4;
        SSG1 DEFGHI    1;
        goto ReloadEnd;

    LoadLeft:
        SSG3 A         1 A_FireProjectile ("S7_12gaShellCasingSpawn", 0, 0, 4, -16);
        SSG3 BCDEFHIJK 1;
        SSG0 Q         4 {
            A_PlaySound ("Weapons/SSG/In", CHAN_6);
            invoker.leftLoaded = true;
            TakeInventory (invoker.ammoType2, 1);
        }
        SSG3 LM        1;
        SSG1 DEFGHI    1;
        goto ReloadEnd;

    LoadRight:
        SSG2 A      1 A_FireProjectile ("S7_12gaShellCasingSpawn", 0, 0, 7, -18);
        SSG2 BCDE   1;
        SSG0 WXYZ   1;
        SSG1 A      1;
        SSG1 B      1 {
            A_PlaySound ("Weapons/SSG/In", CHAN_6);
            invoker.rightLoaded = true;
            TakeInventory (invoker.ammoType2, 1);
        }
        SSG1 C      4;
        SSG1 DEFGHI 1;
        goto ReloadEnd;

    ReloadEnd:
        SSG0 E     1;
        SSG0 D     1 A_PlaySound ("Weapons/SSG/Close", CHAN_Weapon);
        SSG0 CBAAA 1;
        goto Ready2;
    }
}
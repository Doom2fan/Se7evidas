//-------------------------------------------------------------------------------------------
//
// AM-10 "Lucifer" Combat Shotgun
//
//-------------------------------------------------------------------------------------------
class S7_ShotgunMag : Ammo {
    default {
        Inventory.MaxAmount 10;
        Ammo.BackpackMaxAmount 10;

        +INVENTORY.IGNORESKILL
    }
}

class S7_Shotgun : S7_BaseWeapon {
    default {
        Tag "$SHOTGUN";
        Inventory.PickupMessage "$SHOTGUN";
        Weapon.AmmoType1 "S7_ShotgunMag";
        Weapon.AmmoType2 "S7_20gaShells";
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;
        S7_BaseWeapon.Icon "DTUPA0";
        S7_BaseWeapon.ShortTag "$SHORTSHOTGUN";
        S7_BaseWeapon.BindSlot WpSlot_Medium;
    }

    int loaded;

    states {
    Spawn:
        DTUP A -1;
        stop;

    Ready:
    Ready2:
        SSGR A 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            TakeInventory ("S7_ChangeFireMode", 1);

            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Fire:
        SSGF E 1 {
            int ammoCount = CountInv (invoker.ammoType1);

            if (ammoCount >= 10 && invoker.loaded != 2) // If the mag ammo is completely full, (i.e. two in chamber and 8 in mag) then this makes no sense.
                invoker.loaded = 2;                     // Probably cheating or a bug. Just silently fix it and fire anyway.
            else if (ammoCount <= 0)
                return ResolveState ("DryFire");
            else if (invoker.loaded == 1 || (invoker.loaded > 0 && ammoCount == 1))
                return ResolveState ("FireRight");
            else if (invoker.loaded <= 0)
                return ResolveState ("Pump");

            A_PlaySound ("Weapons/Shotgun/Fire", CHAN_5);
            A_AlertMonsters ();
            A_GunFlash ("FlashLeft");

            invoker.loaded = 1;
            invoker.DepleteAmmo (false, true, 1);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 1, 3);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 1, 3);
            for (int i = 0; i < 18; i++)
                A_FireProjectile ("S7_SSGTracer", fRandom [weaponSpread] (-0.25, 0.25), 0, 2, -1, 0, fRandom [weaponSpread] (-0.25, 0.25));
            A_SetPitch (pitch - 1.45, SPF_Interpolate);

            return ResolveState (null);
        }
        SSGF E 1 A_SetPitch (pitch - 1.45, SPF_Interpolate);
        SSGF E 1;
        SSGF F 1 A_SetPitch (pitch + 0.725, SPF_Interpolate);
        SSGR A 2 A_SetPitch (pitch + 0.725, SPF_Interpolate);
        goto Ready2;

    FireRight:
        SSGF E 1 {
            A_PlaySound ("Weapons/Shotgun/Fire", CHAN_6);
            A_AlertMonsters ();
            A_GunFlash ("FlashRight");

            invoker.loaded = 0;
            invoker.DepleteAmmo (false, true, 1);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 3, 2);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 3, 2);
            for (int i = 0; i < 18; i++)
                A_FireProjectile ("S7_SSGTracer", fRandom [weaponSpread] (-0.25, 0.25), 0, 4, -1, 0, fRandom [weaponSpread] (-0.25, 0.25));

            A_SetPitch (pitch - 1.45, SPF_Interpolate);
        }
        SSGF E 1 A_SetPitch (pitch - 1.45, SPF_Interpolate);
        SSGF E 1;
        SSGF F 1 A_SetPitch (pitch + 0.725, SPF_Interpolate);
        SSGR A 2 A_SetPitch (pitch + 0.725, SPF_Interpolate);
        goto Ready2;

    AltFire:
        TNT1 A 0 {
            int ammoCount = CountInv (invoker.ammoType1);

            if (ammoCount >= 10 && invoker.loaded != 2) // If the mag ammo is completely full, (i.e. two in chamber and 8 in mag) then this makes no sense.
                invoker.loaded = 2;                     // Probably cheating or a bug. Just silently fix it and fire anyway.
            else if (ammoCount == 0)
                return ResolveState ("DryFire");
            else if (invoker.loaded == 0)
                return ResolveState ("Pump");
            else if (invoker.loaded == 1 || ammoCount == 1)
                return ResolveState ("Fire");

            A_AlertMonsters ();
            A_GunFlash ("AltFlash");

            return ResolveState (null);
        }

        SSGF E 1 {
            A_PlaySound ("Weapons/Shotgun/Fire", CHAN_5);

            invoker.loaded = 1;
            invoker.DepleteAmmo (false, true, 1);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 1, 3);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 1, 3);
            for (int i = 0; i < 18; i++)
                A_FireProjectile ("S7_SSGTracer", fRandom [weaponSpread] (-0.25, 0.25), 0, 2, -1, 0, fRandom [weaponSpread] (-0.25, 0.25));

            A_SetPitch (pitch - 0.725, SPF_Interpolate);
        }

        SSGF D 1 {
            A_PlaySound ("Weapons/Shotgun/Fire", CHAN_6);

            invoker.loaded = 0;
            invoker.DepleteAmmo (false, true, 1);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 3, 2);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 3, 2);
            for (int i = 0; i < 18; i++)
                A_FireProjectile ("S7_SSGTracer", fRandom [weaponSpread] (-0.25, 0.25), 0, 4, -1, 0, fRandom [weaponSpread] (-0.25, 0.25));

            A_SetPitch (pitch - 2.175, SPF_Interpolate);
        }

        SSGF DD 1 A_SetPitch (pitch - 1.45, SPF_Interpolate);
        SSGF E  1;
        SSGF F  1 A_SetPitch (pitch + 1.45, SPF_Interpolate);
        SSGR A  2 A_SetPitch (pitch + 1.45, SPF_Interpolate);
        goto Ready2;

    FlashLeft:
        SSGF A 2 bright;
        stop;
    FlashRight:
        SSGF B 2 bright;
        stop;
    AltFlash:
        SSGF AC 1 bright;
        stop;

    Pump:
        SSGF G    2 {
            int ammoCount = CountInv (invoker.ammoType1);

            if (ammoCount >= 10) {  // If the mag ammo is completely full, (i.e. two in chamber and 8 in mag) then this makes no sense.
                invoker.loaded = 2; // Probably cheating or a bug. Just silently fix it and fire anyway.
                return ResolveState ("Fire");
            } else if (ammoCount == 1 && invoker.loaded >= 1)
                return ResolveState ("Ready2");
            else if (ammoCount <= 0)
                return ResolveState ("DryFire");

            invoker.loaded = 2;

            return ResolveState (null);
        }
        SSGF H    2 {
            A_FireProjectile ("S7_ShellCasingSpawn", 0, 0, 6, -3);
            A_FireProjectile ("S7_ShellCasingSpawn", 0, 0, 6, -3);
            A_PlaySound ("Weapons/Shotgun/Pump", CHAN_7);
        }
        SSGF IK   2;
        SSGF JIHG 2;
        SSGR A    2;
        goto Ready2;

    DryFire:
        SSGR A 3 A_PlaySound ("Weapons/Misc/DryFire", CHAN_7);
        TNT1 A 0 {
            if (S7_PlayerCVar.GetInt (player, "S7_AutoReloading")) {
                GiveInventory ("S7_Reloading", 1);
                return ResolveState ("Reload");
            }

            return ResolveState (null);
        }
        goto Ready2;

    Reload:
        SSGR A 5 A_JumpIf (!CheckInventory ("S7_Reloading", 1) || CheckInventory (invoker.ammoType1, 0) || CountInv (invoker.ammoType2) < 2, "ReloadFinish");
        TNT1 A 0 A_JumpIf (invoker.loaded != 2, "InsertShells.Pump");
        goto InsertShells;

    InsertShells:
        DSGR A       1 {
            if (!CheckInventory ("S7_Reloading", 1) || CheckInventory (invoker.ammoType1, 0) || CountInv (invoker.ammoType2) < 2)
                return ResolveState ("ReloadFinish");

            GiveInventory ("S7_ShotgunMag", 2);
            TakeInventory ("S7_20gaShells", 2);
            A_PlaySound ("Weapons/Shotgun/ShellIn", CHAN_5);

            return ResolveState (null);
        }
        DSGR BCCCCBA 1;
        DSGR A       1 A_PlaySound ("Weapons/Shotgun/ShellIn", CHAN_6);
        DSGR BCCCCB  1;
        DSGR A      13;
        TNT1 A       0 A_JumpIf (invoker.loaded != 2, "InsertShells.Pump");
        goto InsertShells;

    InsertShells.Pump:
        SSGF G    2 {
            if (invoker.loaded >= 2) {
                invoker.loaded = 2;
                return ResolveState ("InsertShells");
            } else if (invoker.loaded == 1) {
                TakeInventory (invoker.ammoType1, 1); // Remove the extra shell
                GiveInventory (invoker.ammoType2, 1);
                A_FireProjectile ("S7_ShellCasingSpawn", 0, 0, 6, -3);
                if (CheckInventory (invoker.ammoType1, 2))
                    invoker.loaded = 2; // Load 2 shells into the chamber
                else
                    invoker.loaded = 0;
            } else if (invoker.loaded <= 0 && CheckInventory (invoker.ammoType1, 2)) {
                A_FireProjectile ("S7_ShellCasingSpawn", 0, 0, 6, -3);
                A_FireProjectile ("S7_ShellCasingSpawn", 0, 0, 6, -3);
                invoker.loaded = 2;
            } else
                return ResolveState ("InsertShells");

            return ResolveState (null);
        }
        SSGF H    2 A_PlaySound ("Weapons/Shotgun/Pump", CHAN_7);
        SSGF IK   2;
        SSGF JIHG 2;
        SSGR A    2;
        goto InsertShells;

    ReloadFinish:
        TNT1 A 0 TakeInventory ("S7_Reloading", 1);
        goto Ready2;
    }
}
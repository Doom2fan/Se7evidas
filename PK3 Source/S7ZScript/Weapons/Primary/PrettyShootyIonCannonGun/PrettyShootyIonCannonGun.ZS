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

//-------------------------------------------------------------------------------------------
//
// GTX-2 "Mjolnir" Ion Cannon Mk V
//
//-------------------------------------------------------------------------------------------
class S7_PSICG_CantFire           : S7_Counter { default { Inventory.MaxAmount 5; } }
class S7_PSICG_AltFireType2       : S7_Boolean { }
class S7_PrettyShootyIonCannonGun : S7_BaseWeapon {
    default {
        Tag "$IONCANNON";
        Inventory.PickupMessage "$IONCANNON";
        //Weapon.AmmoType1 "S7_PrettyShootyIonCannonGunMag";
        //Weapon.AmmoType2 "S7_Cells";
        Weapon.AmmoUse 0;
        Weapon.AmmoGive 0;
        S7_BaseWeapon.Icon "PIC1Z0";
        S7_BaseWeapon.ShortTag "$SHORTIONCANNON";
        S7_BaseWeapon.BindSlot WpSlot_AreaDMG;
    }

    int readyFrame;

    states {
    Spawn:
        PIC1 Z -1;
        stop;

    Ready:
        TNT1 A      0 TakeInventory ("S7_PSICG_CantFire", 0x7FFFFFFF);
        PIC1 TUVWXA 1;
    Ready2:
        PIC1 AAAAAAAAAAAABBCCDDEEFFGGGGGFFEEDDCCBB 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            /*if (CheckInventory ("S7_ChangeFireMode", 1))
                return ResolveState ("ChangeMode");*/
            TakeInventory ("S7_ChangeFireMode", 1);

            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Deselect:
        PIC1 AXWVUT 1;
        goto TrueDeselect;

    Reload:
        PIC1 A 5 TakeInventory ("S7_Reloading", 1);
        goto Ready2;

    Fire:
        // Distance check
        TNT1 A        0 A_FireBullets (0.0, 0.0, 1, 0, "S7_PSICG_FireTesterPuff", FBF_NoRandom | FBF_NoFlash | FBF_NoRandomPuffZ, 192);
        TNT1 A        0 A_JumpIfInventory ("S7_PSICG_CantFire", 1, "CantFire");
        TNT1 A        0 TakeInventory ("S7_PSICG_CantFire", 0x7FFFFFFF);
        // Space check
        PIC1 A        3 A_FireProjectile ("S7_PSICG_FireTester", 0.0, 0, 6, -3.3);
        TNT1 A        0 A_JumpIfInventory ("S7_PSICG_CantFire", 1, "CantFire");
        TNT1 A        0 TakeInventory ("S7_PSICG_CantFire", 0x7FFFFFFF);
        // Fire
        TNT1 A        0 A_FireProjectile ("S7_IonCannonProjectile", 0.0, 1, 6, -3.3);
        TNT1 AAA      0 A_FireProjectile ("S7_IonCannonRail", fRandom [weaponSpread] (-1.5, 1.5), 0, 6, -3.3, 0, fRandom [weaponSpread] (-1.5, 1.5));
        TNT1 A        0 A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 4, 0);
    Fire.Anim:
        PIC1 A        1 offset (8, 40);
        PIC1 B        1 offset (6, 38);
        PIC1 C        1 offset (4, 36);
        PIC1 D        1 offset (2, 34);
        TNT1 A        0 A_WeaponReady (WRF_DisableSwitch | WRF_DisableSwitch | WRF_NoFire);
        PIC1 EFG      1;
        PIC1 GGGGGGGG 2 A_FireProjectile ("S7_HeatSmokeSpawner", 0, 0, random [sfx] (4, 10), fRandom [sfx] (-8.0, -9.2));
        PIC1 GGGGGGGG 2 A_FireProjectile ("S7_HeatSmokeSpawner", 0, 0, random [sfx] (4, 10), fRandom [sfx] (-8.0, -9.2));
        PIC1 G        4;
        PIC1 FEDCBA   2;
        PIC1 A        5;
        goto Ready2;

    AltFire:
        TNT1 A       0 A_JumpIfInventory ("S7_PSICG_AltFireType2", 1, "AltFire.MainOnly");
        TNT1 AAAAAAA 0 A_FireProjectile ("S7_IonCannonRailAlt", fRandom [weaponSpread] (-1.5, 1.5), 0, 6, -3.3, 0, fRandom [weaponSpread] (-1.5, 1.5));
        TNT1 A       0 A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 4, 0);
        goto Fire.Anim;
    AltFire.MainOnly:
        // Distance check
        TNT1 A 0 A_FireBullets (0.0, 0.0, 1, 0, "S7_PSICG_FireTesterPuff", FBF_NoRandom | FBF_NoFlash | FBF_NoRandomPuffZ, 192);
        TNT1 A 0 A_JumpIfInventory ("S7_PSICG_CantFire", 1, "CantFire");
        TNT1 A 0 TakeInventory ("S7_PSICG_CantFire", 0x7FFFFFFF);
        // Space check
        PIC1 A 3 A_FireProjectile ("S7_PSICG_FireTester", 0.0, 0, 6, -3.3);
        TNT1 A 0 A_JumpIfInventory ("S7_PSICG_CantFire", 1, "CantFire");
        TNT1 A 0 TakeInventory ("S7_PSICG_CantFire", 0x7FFFFFFF);
        // Fire
        TNT1 A 0 A_FireProjectile ("S7_IonCannonProjectileAlt", 0.0, 1, 6, -3.3);
        TNT1 A 0 A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 4, 0);
        goto Fire.Anim;

    CantFire:
        TNT1 A 0 TakeInventory ("S7_PSICG_CantFire", 0x7FFFFFFF);
        PIC1 A 1 A_PlaySound ("Weapons/PSICG/Error", CHAN_6);
        goto Ready2;
    }
}

//-------------------------------------------------------------------------------------------
//
// Firing checks
//
//-------------------------------------------------------------------------------------------
class S7_PSICG_FireTesterPuff : S7_DistanceTestPuff {
    states {
    RunStuff:
        TNT1 A 2 A_GiveToTarget ("S7_PSICG_CantFire", 1);
        stop;
    }
}

class S7_PSICG_FireTester : S7_DistanceTestProjectile {
    default {
        Speed 20;
    }

    states {
    Spawn:
        TNT1 A 2 noDelay {
            A_ScaleVelocity (1.0 / 20);
            A_ScaleVelocity (35.0);
        }
        TNT1 A 2 A_TakeFromTarget ("S7_PSICG_CantFire", 0x7FFFFFFF);
        stop;

    Death:
        TNT1 A 2 A_GiveToTarget ("S7_PSICG_CantFire", 1);
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Main projectile
//
//-------------------------------------------------------------------------------------------
class S7_IonCannonProjectile : S7_BaseTracer {
    double realDamage;

    default {
        S7_Projectile.fastProjCollision ColMode_Center | ColMode_Corners | ColMode_EdgeCenters;
        S7_BaseTracer.TrueSpeed 35;

        Radius 20;
        Height 16;
        Speed 20;
        Scale 0.235;
        DamageFunction int (realDamage);
        DamageType "IonCannonMain";
        MissileType "S7_IonCannonProjectileTrail";
        Decal "S7_IonCannon";

        +FORCERADIUSDMG +BLOODLESSIMPACT
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        realDamage = 280 + (fRandom [weaponDamage] (2.0, 5.0) * 80) + (fRandom [weaponDamage] (-3.0, 3.0) * 40);
    }

    states {
    Idle:
        TNT1 A   0 A_JumpIf (realDamage < 75, "DieOut");
        PICF AAA 1 bright A_Explode (int (fRandom [weaponDamage] (1.0, 3.0) * 7), 96, 0, false, 96);
        TNT1 A   0 { realDamage -= 5; }
        loop;

    DieOut:
        TNT1 A 0 A_Explode (64, 64, 0);
    DieOut.Loople:
        PICF A 1 bright A_FadeOut (0.8);
        loop;

    Death:
        TNT1 A 3 A_Explode (256, 128);
        stop;
    }
}

class S7_IonCannonProjectileTrail : S7_TracerEffectsBase {
    default {
        RenderStyle "add";
        Scale 0.235;
    }

    states {
    Spawn:
        PICF A 1 bright;
        TNT1 A 0 A_ChangeVelocity (fRandom [sfx] (-3.0, 3.0), fRandom [sfx] (-3.0, 3.0), fRandom [sfx] (-3.0, 3.0), CVF_Replace | CVF_Relative);
    Loople:
        PICF A 1 bright A_FadeOut (0.1);
        loop;

    Death:
        TNT1 A 0;
        stop;
    }
}

class S7_IonCannonProjectileAlt : S7_IonCannonProjectile {
    states {
    Spawn:
        PICF A 0 noDelay {
            A_ScaleVelocity (1.0 / 20);
            A_ScaleVelocity (35);
            realDamage = 350 + (fRandom [weaponDamage] (3.0, 6.0) * 95) + (fRandom [weaponDamage] (-2.0, 5.0) * 53);
        }
        goto Idle;
    Death:
        TNT1 A 3 A_Explode (300, 128);
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Rails
//
//-------------------------------------------------------------------------------------------
class S7_IonCannonRail : S7_BaseTracer {
    double realDamage;
    int realDistTrav;

    default {
        S7_BaseTracer.TrueSpeed 125;

        Radius 4;
        Height 4;
        Alpha 1.0;
        Scale 0.08;
        Decal "S7_IonCannonRail";
        DamageFunction (realDamage);
        DamageType "IonCannonRail";
        MissileType "S7_IonCannonRailEffectSpawner";

        +RIPPER +FORCERADIUSDMG +BLOODLESSIMPACT
        -BLOODSPLATTER
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        realDistTrav = 0;
    }

    states {
    Idle:
        TNT1 A 0 A_JumpIf (realDistTrav > 4000, "DieOut");
        PICF A 1 bright {
            realDamage = fRandom [weaponDamage] (4.0, 12.0);
            realDistTrav += 125;
        }
        loop;

    DieOut:
        TNT1 A 0 A_Explode (24, 24, 0);
    DieOut.Loople:
        PICF A 1 bright A_FadeOut (0.15);
        loop;

    Death:
        TNT1 A 3;
        stop;
    }
}

class S7_IonCannonRailEffectSpawner : S7_TracerEffectsBase {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnItemEx ("S7_IonCannonRailEffect", 0.0 + fRandom [sfx] (-2.5, 2.5), 0.0 + fRandom [sfx] (-2.5, 2.5), 8.0 + fRandom [sfx] (-2.5, 2.5), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
        stop;
    }
}

class S7_IonCannonRailEffect : S7_TracerEffectsBase {
    default {
        RenderStyle "add";
        Scale 0.1;
    }

    states {
    Spawn:
        PICF A 1 bright;
        TNT1 A 0 A_ChangeVelocity (fRandom [sfx] (-3.0, 3.0), fRandom [sfx] (-3.0, 3.0), fRandom [sfx] (-3.0, 3.0), CVF_Replace | CVF_Relative);
        PICF A 1 bright A_FadeOut (0.1);
        wait;
    }
}

class S7_IonCannonRailAlt : S7_IonCannonRail {
    default {
        S7_BaseTracer.TrueSpeed 138;
    }

    states {
    Idle:
        TNT1 A 0 A_JumpIf (realDistTrav > 4500, "DieOut");
        PICF A 1 bright {
            realDamage = fRandom [weaponDamage] (8.0, 16.0);
            realDistTrav += 138;
        }
        loop;
    }
}
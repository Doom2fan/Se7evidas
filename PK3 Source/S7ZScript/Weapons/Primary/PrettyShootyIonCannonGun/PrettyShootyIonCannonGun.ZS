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

//-------------------------------------------------------------------------------------------
//
// GTX-2 "Mjolnir" Ion Cannon Mk V
//
//-------------------------------------------------------------------------------------------
class S7_PrettyShootyIonCannonGunMag : Ammo {
    default {
        Inventory.MaxAmount 36;
        Ammo.BackpackMaxAmount 36;

        +INVENTORY.IGNORESKILL
    }
}

class S7_PrettyShootyIonCannonGun : S7_BaseWeapon {
    default {
        //$Category "Se7evidas/Weapons"
        //$Color 14
        //$Title ""Mjolnir" Ion Cannon"
        //$NotAngled

        Tag "$IONCANNON";
        Inventory.PickupMessage "$IONCANNON";
        Inventory.PickupSound "Weapons/Pickup/Medium";

        Weapon.AmmoType1 'S7_PrettyShootyIonCannonGunMag';
        Weapon.AmmoType2 'S7_Cells';
        Weapon.AmmoUse 9;
        Weapon.AmmoUse2 0;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "PIC1Z0";
        S7_BaseWeapon.ShortTag "$SHORTIONCANNON";
        S7_BaseWeapon.AmmoBuyData "ACEL", 1;
        S7_BaseWeapon.BindSlot S7_WpSlot_AreaDMG;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties false, 0.;
    }

    int readyFrame;
    bool altFireType2;

    override double S7_WeightSpeedModifier (double strengthStat, double berserkCount) {
        return clamp (.65 + clamp (.15 * log (strengthStat / 4.), 0., 1.) + (.05 * berserkCount), 0., 1.);
    }

    action bool FireMainProjectile (Class<S7_IonCannonProjectile> proj, bool useAmmo = true) {
        bool canFire = true;

        let act = S7_A_FireBullets ('S7_IonCannonSpaceTester', offs: (10, 8, 8));
        if (act) {
            Vector3 startPos = act.pos;
            Vector3 stepSize = act.vel;
            int stepCount = int (ceil (265. / stepSize.Length ()));

            for (int i = 0; i <= stepCount; i++) {
                if (!act) {
                    canFire = false;
                    break;
                }

                Vector3 curPos = startPos + (stepSize * i);

                act.SetOrigin ((curPos.X, curPos.Y, act.pos.Z), false);
                if (curPos.Z <= act.floorZ || (curPos.Z + act.height) >= act.ceilingZ) {
                    canFire = false;
                    break;
                }
                act.SetOrigin (curPos, false);

                if (act.pos.Z <= act.floorZ || (act.pos.Z + act.height) >= act.ceilingZ ||
                    !act.TryMove (act.pos.XY, true, false) ||
                    act.bKilled || !act.bMissile || act.InStateSequence (act.CurState, act.FindState ("Death"))
                ) {
                    canFire = false;
                    break;
                }
            }
        } else
            canFire = false;

        if (act)
            act.Destroy ();

        if (canFire)
            S7_A_FireBullets (proj, offs: (10, 8, 8), bonusDMGFactor: invoker.GetDamageBonus (), flags: useAmmo ? S7_FB_UseAmmo : 0);

        return canFire;
    }

    double GetDamageBonus () {
        if (!Owner)
            return 0.;

        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.xpSys)
            return 0.;

        return pPawn.xpSys.GetStat (S7Stat_Tech, false) * 0.005;
    }

    const AnimLayer_ID = 2;

    action void S7_SetAnim (StateLabel animState) {
        S7_Internal_SetAnim (AnimLayer_ID, animState, 0, 0);
    }

    /** Pickup **/
    states {
    Spawn:
        PIC1 Z -1;
        stop;
    }

    /** Animations **/
    states {
    Anim.Idle:
        PIC1 A 1;
        wait;
    Anim.Ready:
        PIC1 A    12;
        PIC1 BCDEF 1;
        PIC1 G     5;
        PIC1 FEDCB 1;
        loop;
    Anim.Fire: // 60 tics
        PIC1 A        1 bright A_WeaponOffset (8, 40);
        PIC1 B        1 A_WeaponOffset (6, 38, WOF_Interpolate);
        PIC1 C        1 A_WeaponOffset (4, 36, WOF_Interpolate);
        PIC1 D        1 A_WeaponOffset (2, 34, WOF_Interpolate);
        PIC1 E        1 A_WeaponOffset (0, 32, WOF_Interpolate);
        PIC1 FG       1;
        PIC1 GGGGGGGG 2 S7_A_SpawnSFX ('S7_HeatSmokeSpawner', offs: (0, random [S7_SmokeRNG] (4, 10), fRandom [S7_SmokeRNG] (9., 10.)));
        PIC1 GGGGGGGG 2 S7_A_SpawnSFX ('S7_HeatSmokeSpawner', offs: (0, random [S7_SmokeRNG] (4, 10), fRandom [S7_SmokeRNG] (9., 10.)));
        PIC1 G        4;
        PIC1 FEDCBA   2;
        PIC1 A        5;
        goto Anim.Ready;
    Anim.Reload:
        PIC1 A   1 DoSelectOffset (( 0,  0), forceNoInterpolate: true);
        PIC1 A   1 DoSelectOffset (( 8,  8));
        PIC1 A   1 DoSelectOffset ((24, 24));
        PIC1 A   1 DoSelectOffset ((40, 40));
        PIC1 A   1 DoSelectOffset ((64, 64));
        PIC1 A   1 DoSelectOffset ((88, 88));
        TNT1 A   5;
        TNT1 A 105 A_StartSound ("Weapons/PrettyShootyIonCannonGun/Reload", slot: CHAN_Weapon);
        TNT1 A   5;
        PIC1 A   1 DoSelectOffset ((88, 88), forceNoInterpolate: true);
        PIC1 A   1 DoSelectOffset ((64, 64));
        PIC1 A   1 DoSelectOffset ((40, 40));
        PIC1 A   1 DoSelectOffset ((24, 24));
        PIC1 A   1 DoSelectOffset (( 8,  8));
        PIC1 A   1 DoSelectOffset (( 0,  0));
        goto Anim.Ready;
    }

    /** Actions **/
    states {
    Ready:
        TNT1 A 0 S7_SetAnim ("Anim.Ready");
        TNT1 A 1 DoSelectOffset ((88, 88), forceNoInterpolate: true);
        TNT1 A 1 DoSelectOffset ((64, 64));
        TNT1 A 1 DoSelectOffset ((40, 40));
        TNT1 A 1 DoSelectOffset ((24, 24));
        TNT1 A 1 DoSelectOffset (( 8,  8));
        TNT1 A 1 DoSelectOffset (( 0,  0));
        goto Ready2.SkipAnimSet;
    Ready2:
        TNT1 A 0 S7_SetAnim ("Anim.Ready");
    Ready2.SkipAnimSet:
        TNT1 A 1 S7_WeaponReady ("Reload", null, "QuickMeleeDerp");
        wait;
    QuickMeleeDerp:
        TNT1 A 0 S7_SetAnim ("Null");
        goto QuickMelee;

    Deselect:
        PIC1 A 0 {
            if (health <= 0) {
                S7_SetAnim ("Null");
                return ResolveState ("Deselect.DEAD");
            }

            return ResolveState (null);
        }
        TNT1 A 1 DoSelectOffset (( 0,  0));
        TNT1 A 1 DoSelectOffset (( 8,  8));
        TNT1 A 1 DoSelectOffset ((24, 24));
        TNT1 A 1 DoSelectOffset ((40, 40));
        TNT1 A 1 DoSelectOffset ((64, 64));
        TNT1 A 1 DoSelectOffset ((88, 88));
        goto TrueDeselect;

    Fire:
        TNT1 A 60 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            if (!FireMainProjectile ('S7_IonCannonProjectile', true))
                return ResolveState ("CantFire");

            S7_SetAnim ("Anim.Fire");

            for (int i = 0; i < 5; i++)
                S7_A_FireBullets ('S7_IonCannonRail', spread: (1.5, 1.5), offs: (10, 8, 8), bonusDMGFactor: invoker.GetDamageBonus ());

            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 3, 5));
            A_StartSound ("Weapons/PrettyShootyIonCannonGun/Fire", slot: CHAN_Weapon);
            A_AlertMonsters ();

            GiveInventory ('S7_IonCannonInverse', 2);

            return ResolveState (null);
        }
        goto Ready2;

    AltFire:
        TNT1 A 60 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            S7_SetAnim ("Anim.Fire");

            invoker.DepleteAmmo (false, true);

            if (!invoker.altFireType2) {
                for (int i = 0; i < 7; i++)
                    S7_A_FireBullets ('S7_IonCannonRailAlt', spread: (1.5, 1.5), offs: (10, 8, 8), bonusDMGFactor: invoker.GetDamageBonus ());
            } else {
                if (!FireMainProjectile ('S7_IonCannonProjectileAlt', false))
                    return ResolveState ("CantFire");
            }

            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 3, 5));
            A_StartSound ("Weapons/PrettyShootyIonCannonGun/Fire", slot: CHAN_Weapon);
            A_AlertMonsters ();

            GiveInventory ('S7_IonCannonInverse', 3);

            return ResolveState (null);
        }
        goto Ready2;

    CantFire:
        TNT1 A 1 A_StartSound ("Weapons/PrettyShootyIonCannonGun/Error", slot: CHAN_6);
        goto Ready2.SkipAnimSet;

    DryFire:
        TNT1 A 3 A_StartSound ("Weapons/DryFirePlasma", slot: CHAN_7);
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
        goto Ready2.SkipAnimSet;

    Reload:
        TNT1 A 0 {
            TakeInventory ('S7_Reloading', 1);

            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1))
                return ResolveState ("Ready2.SkipAnimSet");

            int ammoAmount = min (FindInventory (invoker.ammoType1).maxAmount - CountInv (invoker.ammoType1), CountInv (invoker.ammoType2));
            if (ammoAmount <= 0)
                return ResolveState ("Ready2.SkipAnimSet");

            GiveInventory (invoker.ammoType1, ammoAmount);
            TakeInventory (invoker.ammoType2, ammoAmount);

            S7_SetAnim ("Anim.Reload");

            return ResolveState (null);
        }
        TNT1 A 1 {
            let psp = player.FindPSprite (AnimLayer_ID);
            if (psp && InStateSequence (psp.CurState, ResolveState ("Anim.Ready")))
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        wait;
    }
}

class S7_IonCannonSpaceTester : S7_BaseTracer {
    default {
        S7_Projectile.fastProjCollision 0;

        Damage 0;
        Radius 20;
        Height 16;
        Speed 35;

        +PAINLESS   +NOPAIN +NOTRIGGER +BLOODLESSIMPACT
        +CANNOTPUSH
        -ACTIVATEIMPACT -ACTIVATEMCROSS -ACTIVATEPCROSS -CANPUSHWALLS
        -BLOODSPLATTER
    }

    states {
    Spawn:
        TNT1 A 1;
        loop;
    Death:
        TNT1 A 1;
        stop;
    }
}

class S7_IonCannonInverse : Inventory {
    default {
        Inventory.MaxAmount 0x7FFFFFFF;
    }

    override void DoEffect () {
        if (!Owner || !Owner.player)
            return;

        Owner.player.extralight = 0x80000000;

        if ((amount--) == 0)
            Owner.TakeInventory (GetClass (), 0x7FFFFFFF);
    }

    override void DetachFromOwner () {
        if (!Owner || !Owner.player)
            return;

        Owner.player.extralight = 0;
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

        Radius 20;
        Height 16;
        Speed 35;
        Scale 0.235;
        DamageFunction int (ceil (realDamage * (1. + bonusDMGFactor)));
        DamageType 'IonCannonMain';
        MissileType 'S7_IonCannonProjectileTrail';
        Decal 'S7_IonCannon';

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
        TNT1 A 3 A_Explode (256, 256);
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
        TNT1 A 0 A_ChangeVelocity (fRandom [S7_ProjSFXRNG] (-3.0, 3.0), fRandom [S7_ProjSFXRNG] (-3.0, 3.0), fRandom [S7_ProjSFXRNG] (-3.0, 3.0), CVF_Replace | CVF_Relative);
    Loople:
        PICF A 1 bright A_FadeOut (0.1);
        loop;

    Death:
        TNT1 A 0;
        stop;
    }
}

class S7_IonCannonProjectileAlt : S7_IonCannonProjectile {
    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        realDamage = 350 + (fRandom [weaponDamage] (3.0, 6.0) * 95) + (fRandom [weaponDamage] (-2.0, 5.0) * 53);
    }

    states {
    Death:
        TNT1 A 3 A_Explode (300, 256);
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
    double realDistTrav;

    default {
        Radius 4;
        Height 4;
        Speed 125;
        Alpha 1.0;
        Scale 0.08;
        Decal 'S7_IonCannonRail';
        DamageFunction int (ceil (realDamage * (1. + bonusDMGFactor)));
        DamageType 'IonCannonRail';
        MissileType 'S7_IonCannonRailEffectSpawner';

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
            realDamage = 8. + fRandom [weaponDamage] (-1.0, 1.0);
            realDistTrav += vel.Length ();
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
        TNT1 A 0 noDelay {
            A_SpawnItemEx ('S7_IonCannonRailEffect',
                      fRandom [S7_ProjSFXRNG] (-2.5, 2.5),
                      fRandom [S7_ProjSFXRNG] (-2.5, 2.5),
                8.0 + fRandom [S7_ProjSFXRNG] (-2.5, 2.5),
                flags: SXF_Clientside | SXF_NoCheckPosition
            );
        }
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
        TNT1 A 0 A_ChangeVelocity (fRandom [S7_ProjSFXRNG] (-3.0, 3.0), fRandom [S7_ProjSFXRNG] (-3.0, 3.0), fRandom [S7_ProjSFXRNG] (-3.0, 3.0), CVF_Replace | CVF_Relative);
        PICF A 1 bright A_FadeOut (0.1);
        wait;
    }
}

class S7_IonCannonRailAlt : S7_IonCannonRail {
    default {
        Speed 138;
    }

    states {
    Idle:
        TNT1 A 0 A_JumpIf (realDistTrav > 4500, "DieOut");
        PICF A 1 bright {
            realDamage = 12. + fRandom [weaponDamage] (-1.0, 1.0);
            realDistTrav += vel.Length ();
        }
        loop;
    }
}
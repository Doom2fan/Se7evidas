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
// FS/002A Mod 4 "Fauchard" Automatic Rifle
//
//-------------------------------------------------------------------------------------------
class S7_FauchardMag : Ammo {
    default {
        Inventory.MaxAmount 23;
        Ammo.BackpackMaxAmount 23;

        +INVENTORY.IGNORESKILL
    }
}

class S7_Fauchard : S7_BaseWeapon {
    default {
        Tag "$FAUCHARD";
        Inventory.PickupMessage "$FAUCHARD";

        Weapon.AmmoType1 'S7_FauchardMag';
        Weapon.AmmoType2 'S7_FBSysCells';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "LRFPA0";
        S7_BaseWeapon.ShortTag "$SHORTFAUCHARD";
        S7_BaseWeapon.BindSlot WpSlot_Medium;
        S7_BaseWeapon.UsesMag true;
    }

    double GetDamageBonus () {
        if (!Owner)
            return 0.;

        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.xpSys)
            return 0.;

        return pPawn.xpSys.GetStat (S7Stat_Tech, false) * 0.025;
    }

    bool halfTic;

    states {
    Spawn:
        LRFP A -1;
        stop;

    Ready:
        LSRF VWXYZA 1;
    Ready2:
        LSRF A 1 {
            if (CheckInventory ('S7_Reloading', 1))
                return ResolveState ("Reload");
            if (CheckInventory ('S7_DoMelee', 1))
                return ResolveState ("QuickMelee");
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Deselect:
        LSRF AZYXWV 1;
        goto TrueDeselect;

    Fire:
        LSRF A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/Fauchard/Fire", (invoker.halfTic ? CHAN_5 : CHAN_Weapon));
            A_AlertMonsters ();
            A_GunFlash ();
            A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 2, 4);
            let proj = S7_FauchardTracer (A_FireProjectile ('S7_FauchardTracer', fRandom [weaponSpread] (-0.14, 0.14), true, 6, -3, 0, fRandom [weaponSpread] (-0.14, 0.14)));

            if (proj)
                proj.bonusDamage = invoker.GetDamageBonus ();

            S7_Recoil (-0.3);

            return ResolveState (null);
        }
        LSRF B 1 S7_Recoil (-0.3);
        LSRF A 1;
        LSRF A 1 {
            if (invoker.halfTic) {
                invoker.halfTic = false;
                return ResolveState ("Fire.End");
            }

            invoker.halfTic = true;
            return ResolveState (null);
        }
    Fire.End:
        LSRF A 1 {
            A_Refire ();
            A_ClearRefire ();
        }
        goto Ready2;

    Flash:
        LSRF LM 1 bright;
        stop;

    DryFire:
        LSRF A 3 A_PlaySound ("Weapons/DryFireLaser", CHAN_7);
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading"), "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            TakeInventory ('S7_Reloading', 1);

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
        LSRF ACDEFGH   2;
        LSRF I         2 A_PlaySound ("Weapons/Fauchard/Out", CHAN_6);
        LSRF J        30;
        LSRF J        12 A_PlaySound ("Weapons/Fauchard/In", CHAN_7);
        LSRF KHGFEDCA  2;
        goto Ready2;
    }
}

//-------------------------------------------------------------------------------------------
//
// Fauchard Tracer
//
//-------------------------------------------------------------------------------------------
class S7_FauchardTracer : S7_BaseTracer {
    double bonusDamage;

    default {
        DamageFunction (fRandom [weaponDamage] (1.0, 4.0) * 12 * (1+bonusDamage));
        S7_BaseTracer.TrueSpeed 300;
        DamageType 'LaserTracer';
        Scale 0.015;
        MissileType 'S7_LaserTracerTrail';
        Decal 'S7_LaserDecal';

        -BLOODSPLATTER
    }

    states {
    Idle:
        LSFL A 1 bright;
        wait;

    Death:
    Crash:
        TNT1 A 3; //A_SpawnItemEx ('S7_LaserPuff')
        stop;
    XDeath:
        TNT1 A 3;
        stop;
    }
}

class S7_LaserTracerTrail : S7_TracerEffectsBase {
    default {
        Scale 0.015;
    }

    states {
    Spawn:
        LSFL A 1 bright;
    Loople:
        #### # 1 bright A_FadeOut (0.2);
        wait;
    }
}
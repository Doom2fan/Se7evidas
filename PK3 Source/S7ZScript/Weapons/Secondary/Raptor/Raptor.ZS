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

        Weapon.AmmoType1 'S7_RaptorClip';
        Weapon.AmmoType2 'S7_9mmCartridges';
        Weapon.AmmoUse 2;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "RPTPA0";
        S7_BaseWeapon.ShortTag "$SHORTRAPTOR";
        S7_BaseWeapon.BindSlot WpSlot_Light;
        S7_BaseWeapon.UsesMag true;
    }

    states {
    Spawn:
        RPTP A -1;
        loop;

    Ready:
        RPTN A 1 DoSelectOffset ((80, 80), forceNoInterpolate: true);
        RPTN A 1 DoSelectOffset ((64, 64));
        RPTN A 1 DoSelectOffset ((48, 48));
        RPTN A 1 DoSelectOffset ((32, 32));
        RPTN A 1 DoSelectOffset ((14, 14));
        RPTN A 1 DoSelectOffset (( 0,  0));
    Ready2:
        RPTN A 1 S7_WeaponReady ("Reload", null);
        loop;

    Deselect:
        RPTN A 1 DoSelectOffset (( 0,  0));
        RPTN A 1 DoSelectOffset ((14, 14));
        RPTN A 1 DoSelectOffset ((32, 32));
        RPTN A 1 DoSelectOffset ((48, 48));
        RPTN A 1 DoSelectOffset ((64, 64));
        RPTN A 1 DoSelectOffset ((80, 80));
        goto TrueDeselect;

    Fire:
        RPTN B 1 bright {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/Raptor/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();

            A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 3, 3.75);
            for (int i = 0; i < 2; i++) {
                A_FireProjectile ('S7_9mmCasingSpawn', 0, false, 7, -2);
                A_FireProjectile ('S7_RaptorTracer', fRandom [weaponSpread] (-0.4, 0.4), (i == 0), 5, 0, 0, fRandom [weaponSpread] (-0.4, 0.4));
            }

            S7_Recoil (-0.8);

            return ResolveState (null);
        }
        RPTN C    1 S7_Recoil (-0.8);
        RPTN A    1;
        RPTN AAAA 1 { player.WeaponState |= WF_WeaponReady; }
        goto Ready2;

    AltFire:
        RPTM A    1 A_PlaySound ("Weapons/Raptor/Melee", CHAN_5);
        RPTM BC   1;
        RPTM D    1 A_CustomPunch (int (15 * fRandom [weaponSpc] (1.0, 3.0)), true, 0, 'S7_RaptorMPuff', 85);
        RPTM EFGH 1;
        TNT1 A    4;
        RPTN A    1;
        goto Ready2;

    Flash:
        RPTF A 1 bright;
        stop;

    DryFire:
        RPTN A 3 {
            A_PlaySound ("Weapons/DryFirePistol", CHAN_7);
        }
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
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
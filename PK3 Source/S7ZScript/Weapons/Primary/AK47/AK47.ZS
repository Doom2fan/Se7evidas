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
// Avtomat Kalashnikova 47
//
//-------------------------------------------------------------------------------------------
class S7_AK47Clip : Ammo {
    default {
        Inventory.MaxAmount 30;
        Ammo.BackpackMaxAmount 30;

        +INVENTORY.IGNORESKILL
    }
}

class S7_AK47 : S7_BaseWeapon {
    default {
        Tag "$AK47";
        Inventory.PickupMessage "$AK47";
        Inventory.PickupSound "Weapons/Pickup/Medium";

        Weapon.AmmoType1 'S7_AK47Clip';
        Weapon.AmmoType2 'S7_762x39Cartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "AK4PA0";
        S7_BaseWeapon.ShortTag "$SHORTAK47";
        S7_BaseWeapon.AmmoBuyData "A762", 1;
        S7_BaseWeapon.BindSlot WpSlot_Medium;
        S7_BaseWeapon.UsesMag true;
    }

    bool halfTic, reloadChamber; // Temporary stuff
    bool semiAuto, semiOnly; // Persistent stuff

    override void DoEffect () {
        Super.DoEffect ();

        if (semiOnly)
            fireModeIcon = FMI_None;
        else
            fireModeIcon = semiAuto ? FMI_SemiAuto : FMI_FullAuto;
    }

    states {
    Spawn:
        AK4P A -1;
        loop;

    Select.Hand:
        HAN0 F 1 DoSelectOffset ((142, 159), -5, true);
        HAN0 F 1 DoSelectOffset ((151, 146), -5);
        HAN0 F 1 DoSelectOffset ((157, 129), -5);
        HAN0 F 1 DoSelectOffset ((160, 111), -5);
        HAN0 F 1 DoSelectOffset ((162,  96), -5);
        stop;
    Ready:
        AK47 S 1 {
            DoSelectOffset ((69, 72), forceNoInterpolate: true);
            A_Overlay (-5, "Select.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        AK47 S 1 DoSelectOffset ((48, 48));
        AK47 S 1 DoSelectOffset ((24, 24));
        AK47 S 1 DoSelectOffset (( 8,  8));
        AK47 S 1 DoSelectOffset (( 0,  0));
        AK47 A 1 DoSelectOffset (( 0,  0));
    Ready2:
        AK47 A 1 S7_WeaponReady ("Reload", "ChangeMode");
        loop;

    ChangeMode:
        AK47 A 5 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

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

    Deselect.Hand:
        HAN0 F 1 DoSelectOffset ((162,  96), -5, true);
        HAN0 F 1 DoSelectOffset ((160, 111), -5);
        HAN0 F 1 DoSelectOffset ((157, 129), -5);
        HAN0 F 1 DoSelectOffset ((151, 146), -5);
        HAN0 F 1 DoSelectOffset ((142, 159), -5);
        stop;
    Deselect:
        AK47 A 1;
        AK47 S 1 {
            DoSelectOffset (( 0,  0));
            A_Overlay (-5, "Deselect.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        AK47 S 1 DoSelectOffset (( 8,  8));
        AK47 S 1 DoSelectOffset ((24, 24));
        AK47 S 1 DoSelectOffset ((48, 48));
        AK47 S 1 DoSelectOffset ((69, 72));
        goto TrueDeselect;

    Fire:
        AK47 A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_AlertMonsters ();
            A_GunFlash ("Flash");
            A_FireProjectile ('S7_AK47_Tracer', fRandom [weaponSpread] (-0.16, 0.16), true, 7, -0.5, 0, fRandom [weaponSpread] (-0.16, 0.16));
            A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 3.5, 4);
            A_FireProjectile ('S7_RifleCasingSpawn', 0, false, 13, -12);

            A_PlaySound ("Weapons/AK47/Fire", (invoker.halfTic ? CHAN_5 : CHAN_Weapon));
            S7_Recoil (-0.7);

            return ResolveState (null);
        }
        AK47 C 1 S7_Recoil (-0.7);
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
        AK47 AAA 1 { player.WeaponState |= WF_WeaponReady; }
        goto Ready2;

    DryFire:
        AK47 A 3 A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            TakeInventory ('S7_Reloading', 1);

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
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
        //$Category "Se7evidas/Weapons"
        //$Color 14
        //$Title "AK-47 (7.62x39mm)"
        //$NotAngled

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
        S7_BaseWeapon.BindSlot S7_WpSlot_Medium;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties true, 0.025;
        S7_BaseWeapon.EnchantmentPrice 750, 0.4, 1.15;
    }

    bool halfTic, reloadChamber, whichFlash; // Temporary stuff
    bool semiAuto, semiOnly; // Persistent stuff

    override void DoEffect () {
        Super.DoEffect ();

        if (semiOnly)
            fireModeIcon = S7_FMI_None;
        else
            fireModeIcon = semiAuto ? S7_FMI_SemiAuto : S7_FMI_FullAuto;
    }

    const AnimLayer_ID = 2;

    action void S7_SetAnim (StateLabel animState) {
        S7_Internal_SetAnim (AnimLayer_ID, animState, 0, 0);
    }

    /** Pickup **/
    states {
    Spawn:
        AK4P A -1;
        loop;
    }

    /** Animations **/
    states {
    Anim.Idle:
        AK47 A 1;
        wait;
    Anim.Fire:
        AK47 A 1 bright;
        AK47 CBC 1;
        AK47 A 1;
        goto Anim.Idle;
    Anim.Select:
        AK47 S 5;
        AK47 A 1;
        wait;
    Anim.SelectHand:
        HAN0 F 1 DoSelectOffset ((142, 159), -5, true);
        HAN0 F 1 DoSelectOffset ((151, 146), -5);
        HAN0 F 1 DoSelectOffset ((157, 129), -5);
        HAN0 F 1 DoSelectOffset ((160, 111), -5);
        HAN0 F 1 DoSelectOffset ((162,  96), -5);
        stop;
    Anim.Deselect:
        AK47 A 1;
        AK47 S 5;
        wait;
    Anim.DeselectHand:
        HAN0 F 1 DoSelectOffset ((162,  96), -5, true);
        HAN0 F 1 DoSelectOffset ((160, 111), -5);
        HAN0 F 1 DoSelectOffset ((157, 129), -5);
        HAN0 F 1 DoSelectOffset ((151, 146), -5);
        HAN0 F 1 DoSelectOffset ((142, 159), -5);
        stop;
    Anim.Reload:
        AK47 A   1 A_WeaponOffset (0  , 32);
        AK47 A   1 A_WeaponOffset (1.5, 33);
        AK47 D   1 A_WeaponOffset (3  , 34);
        AK47 D   1 A_WeaponOffset (4.5, 35);
        AK47 E   1 A_WeaponOffset (6  , 36);
        AK47 EFF 1;
        AK47 GHI 1;
        AK47 J   2;
        AK47 J   1 A_WeaponOffset (6 + -2, 36 + 2);
        AK47 K   1 {
            A_WeaponOffset (6 + -3, 36 + 4);
            A_StartSound ("Weapons/AK47/Out", slot: CHAN_6);
        }
        AK47 L   1 A_WeaponOffset (6 + -1, 36 + 1);
        AK47 M   1 A_WeaponOffset (6     , 36    );
        AK47 N  15;
        AK47 O   1 A_StartSound ("Weapons/AK47/In", slot: CHAN_7);
        AK47 PQ  1;
        AK47 R   1 A_WeaponOffset (6 + 1, 36 + -2);
        AK47 S   1 A_WeaponOffset (6 + 3, 36 + -4);
        AK47 J   1 A_WeaponOffset (6 + 2, 36 + -1);
        AK47 J   3 A_WeaponOffset (6    , 36     );
        AK47 T   1 A_WeaponOffset (6  , 36);
        AK47 U   1 A_WeaponOffset (4.5, 35);
        AK47 V   1 A_WeaponOffset (3  , 34);
        AK47 W   1 A_WeaponOffset (1.5, 33);
        AK47 A   1 A_WeaponOffset (0  , 32);

        TNT1 A 0 A_JumpIf (invoker.reloadChamber, "Anim.Reload.Chamber");
        goto Anim.Reload.End;
    Anim.Reload.Chamber:
        AK47 A     2;
        AK42 ABCDE 2;
        AK42 F     2 A_StartSound ("Weapons/AK47/Bolt", slot: CHAN_6);
        AK42 GH    2;
        AK42 IJKLM 1;
        AK47 A     2;
        goto Anim.Reload.End;
    Anim.Reload.End:
        AK47 A 2 { invoker.reloadChamber = false; }
        goto Anim.Idle;
    }

    /** Actions **/
    states {
    Ready:
        TNT1 A 0 {
            S7_SetAnim ("Anim.Select");
            A_Overlay (-5, "Anim.SelectHand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        TNT1 A 1 DoSelectOffset ((69, 72), forceNoInterpolate: true);
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((24, 24));
        TNT1 A 1 DoSelectOffset (( 8,  8));
        TNT1 A 1 DoSelectOffset (( 0,  0));
        TNT1 A 1 DoSelectOffset (( 0,  0));
    Ready2:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");
            S7_WeaponReady ("Reload", "ChangeMode", "QuickMeleeDerp");
        }
        loop;
    QuickMeleeDerp:
        TNT1 A 0 S7_SetAnim ("Null");
        goto QuickMelee;

    ChangeMode:
        TNT1 A 5 {
            S7_SetAnim ("Anim.Idle");

            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            if (invoker.semiOnly)
                invoker.semiAuto = true;
            else {
                if (invoker.semiAuto)
                    invoker.semiAuto = false;
                else
                    invoker.semiAuto = true;

                A_StartSound ("Weapons/ModeChange", slot: CHAN_7);
            }
        }
        goto Ready2;
    Deselect:
        AK47 A 0 {
            if (health <= 0) {
                S7_SetAnim ("Null");
                return ResolveState ("Deselect.DEAD");
            }

            S7_SetAnim ("Anim.Deselect");
            return ResolveState (null);
        }
        TNT1 A 1;
        TNT1 A 1 {
            DoSelectOffset (( 0,  0));
            A_Overlay (-5, "Anim.DeselectHand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        TNT1 A 1 DoSelectOffset (( 8,  8));
        TNT1 A 1 DoSelectOffset ((24, 24));
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((69, 72));
        goto TrueDeselect;

    Fire:
        TNT1 A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            S7_SetAnim ("Anim.Fire");

            A_AlertMonsters ();
            A_GunFlash ("Flash");
            A_StartSound ("Weapons/AK47/Fire", slot: (invoker.halfTic ? CHAN_5 : CHAN_Weapon));

            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 3.5, 2.5));
            S7_A_SpawnCasing ('S7_RifleCasing', (30, 18, 10.5), pitchOffs: -45, spread: (10, 15));
            S7_A_FireBullets ('S7_AK47_Tracer', spread: (.16, .16), offs: (10, 7, 5), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);

            S7_Recoil (-.9);
            A_ZoomFactor (.99, ZOOM_Instant);

            return ResolveState (null);
        }
        TNT1 A 1 {
            S7_Recoil (-.9);
            A_ZoomFactor (.995);
        }
        TNT1 A 1 {
            S7_Recoil (+.6);
            A_ZoomFactor (1.);
        }
        TNT1 A 1;
        TNT1 A 1 {
            if (invoker.halfTic) {
                invoker.halfTic = false;
                return ResolveState ("Fire.End");
            }

            invoker.halfTic = true;
            return ResolveState (null);
        }
    Fire.End:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");

            if (invoker.semiOnly || invoker.semiAuto)
                return ResolveState ("Fire.Semi");

            A_Refire ("Fire");
            return ResolveState (null);
        }
        goto Ready2;
    Fire.Semi:
        TNT1 A   0 {
            S7_SetAnim ("Anim.Idle");
            invoker.halfTic = false;
        }
        TNT1 AAA 1 { player.WeaponState |= WF_WeaponReady; }
        goto Ready2;

    DryFire:
        TNT1 A 3 {
            S7_SetAnim ("Anim.Idle");
            A_StartSound ("Weapons/DryFireRifle", slot: CHAN_7);
        }
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

            S7_SetAnim ("Anim.Reload");

            return ResolveState (null);
        }
        TNT1 A 1 {
            let psp = player.FindPSprite (AnimLayer_ID);
            if (psp && InStateSequence (psp.CurState, ResolveState ("Anim.Idle")))
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        wait;

    // Muzzle flashes
    Flash:
        AK4F A 1 bright {
            let psp = player.FindPSprite (PSP_Flash);

            if (psp)
                psp.frame = (invoker.whichFlash ? 1 : 0);

            invoker.whichFlash = !invoker.whichFlash;
        }
        stop;
    }
}
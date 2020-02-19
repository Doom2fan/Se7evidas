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
// FS/909G "Butterfly" SMG
//
//-------------------------------------------------------------------------------------------
class S7_LaserPewPewClip : Ammo {
    default {
        Inventory.MaxAmount S7_LaserPewPew.MagSize;
        Ammo.BackpackMaxAmount S7_LaserPewPew.MagSize;

        +INVENTORY.IGNORESKILL
    }
}
class S7_LaserPewPewClipSecond : Ammo {
    default {
        Inventory.MaxAmount S7_LaserPewPew.MagSize;
        Ammo.BackpackMaxAmount S7_LaserPewPew.MagSize;

        +INVENTORY.IGNORESKILL
    }
}

class S7_LaserPewPew : S7_BaseWeapon {
    default {
        //$Category "Se7evidas/Weapons"
        //$Color 14
        //$Title ""Butterfly" Laser SMG"
        //$NotAngled

        Tag "$BUTTFLY";

        Inventory.PickupMessage "$BUTTFLY";
        Inventory.PickupSound "Weapons/Pickup/Small";
        Inventory.MaxAmount 2;

        Weapon.AmmoType1 FirstMagClass;
        Weapon.AmmoType2 'S7_FBSysCells';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "BLSPA0";
        S7_BaseWeapon.ShortTag "$SHORTBUTTFLY";
        S7_BaseWeapon.AmmoBuyData "AFBC", 1;
        S7_BaseWeapon.BindSlot S7_WpSlot_Light;
        S7_BaseWeapon.EnchantmentProperties false, 0.;
    }

    const MagSize = 32;
    const FirstMagClass = "S7_LaserPewPewClip";
    const SecondMagClass = "S7_LaserPewPewClipSecond";

    const RightAnimLayer_ID = 2;
    const BaseZoomFactor = 1.275;
    bool akimbo, sights;
    int magAmmo;

    double GetDamageBonus () {
        if (!Owner)
            return 0.;

        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.xpSys)
            return 0.;

        return pPawn.xpSys.GetStat (S7Stat_Tech, false) * 0.025;
    }

    void LPP_DoDropAmmo (Ammo mag, Ammo pool) {
        if (mag && pool) {
            int count = mag.Amount;
            int excess = max ((pool.Amount + count) - pool.MaxAmount, 0);

            if ((count - excess) > 0)
                Owner.GiveInventory (pool.GetClass (), count - excess);

            if (excess > 0)
                DropAmmo (pool.GetClass (), Owner, excess);

            Owner.TakeInventory (mag.GetClass (), count);
        }
    }

    override bool SS_PreSell (int amount) {
        let secondMag = Ammo (Owner.FindInventory (SecondMagClass));

        if (self.amount < 2)
            LPP_DoDropAmmo (Ammo1, Ammo2);
        else if (amount > 1) {
            LPP_DoDropAmmo (Ammo1, Ammo2);
            LPP_DoDropAmmo (secondMag, Ammo2);
        } else if (amount == 1 && self.amount > 1)
            LPP_DoDropAmmo (secondMag, Ammo2);

        return true;
    }

    override Inventory CreateTossable (int amt) {
        // If self actor lacks a SpawnState, don't drop it. (e.g. A base weapon
        // like the fist can't be dropped because you'll never see it.)
        if (SpawnState == GetDefaultByType ('Actor').SpawnState || SpawnState == null)
            return null;
        if (bUndroppable || bUntossable || Owner == null || Amount <= 0)
            return null;
        if (amount > 2)
            ThrowAbortException ("What the fuck, you have more than two S7_LaserPewPew, this should never happen.");

        // Will pretty much always be true, but ehhh...
        if (Owner && Owner.player && Owner.player.ReadyWeapon == self) {
            int weapState = Owner.player.WeaponState;

            if (!(weapState & WF_WeaponSwitchOK))
                return null;
            if (weapState & WF_DisableSwitch)
                return null;
        }

        amt = 1; // Never drop more than one instance of a weapon

        if (Amount == 1) {
            let ammo1Act = Ammo1;

            BecomePickup ();
            DropTime = 30;
            bSpecial = bSolid = false;

            if (ammo1Act) {
                ammo1Act.BecomePickup ();
                magAmmo = ammo1Act.Amount;
                ammo1Act.Destroy ();
            }

            akimbo = false;
            sights = false;

            return self;
        }

        let copy = S7_LaserPewPew (Spawn (GetClass (), Owner.Pos, NO_REPLACE));
        if (copy != null) {
            copy.MaxAmount = MaxAmount;
            copy.Amount = amt;
            copy.DropTime = 30;
            copy.bSpecial = copy.bSolid = false;
            Amount -= amt;

            copy.sights = false;
            copy.akimbo = false;

            let ammoSecond = Owner.FindInventory (SecondMagClass);
            if (ammoSecond) {
                ammoSecond.BecomePickup ();
                copy.magAmmo = ammoSecond.amount;
                ammoSecond.Destroy ();
            }

            if (Owner && Owner.player && Owner.player.ReadyWeapon == self) {
                if (akimbo)
                    Owner.player.SetPSprite (PSP_Weapon, ResolveState ("ChangeMode.ToSingleDropped"));
            }

            copy.akimbo = akimbo = false;
            copy.sights = sights = false;
        }

        return copy;
    }

    override void AttachToOwner (Actor other) {
        Super.AttachToOwner (other);

        other.SetInventory (FirstMagClass, magAmmo);
        magAmmo = 0;
    }

    override bool HandlePickup (Inventory item) {
        if (item.GetClass () == GetClass ()) {
            let weap = S7_LaserPewPew (item);

            if (MaxAmount > 1) {
                let magAmount = weap.magAmmo;
                bool ret = Inventory.HandlePickup (item);

                if (ret && item.bPickupGood) {
                    if (weap)
                        weap.magAmmo = 0;

                    Owner.SetInventory (SecondMagClass, magAmount);
                    return true;
                }

                return ret;
            }
            return true;
        }
        return false;
    }

    double GetZoomFactor () {
        if (!sights)
            return 1.;

        return BaseZoomFactor;
    }

    action void S7_SetRightAnim (StateLabel animState) {
        S7_Internal_SetAnim (RightAnimLayer_ID, animState, 0, PSPF_AddBob);
    }

    /** Pickup **/
    states {
    Spawn:
        BLSP A -1;
        loop;
    }

    /** Animations (Single) **/
    states {
    AnimSingle.Idle:
        BLSG A 1 A_JumpIf (invoker.sights, "AnimSingle.Sights");
        wait;
    AnimSingle.Sights:
        BLSG K 1;
        wait;
    AnimSingle.Handless:
        BLSG F 1;
        wait;
    AnimSingle.Fire:
        BLSG A  1 bright A_JumpIf (invoker.sights, "AnimSingle.FireSights");
        BLSG CB 1 S7_Recoil (-0.07);
        goto AnimSingle.Idle;
    AnimSingle.FireSights:
        BLSG K  1 bright;
        BLSG OP 1;
        goto AnimSingle.Idle;
    AnimSingle.Zoom:
        BLSG ALMNK 1;
        goto AnimSingle.Idle;
    AnimSingle.Unzoom:
        BLSG KNMLA 1;
        goto AnimSingle.Idle;

    AnimSingle.Reload:
        BLSG ADEFF   2;
        BLSG F      15 A_StartSound ("Weapons/LaserPewPew/Out", slot: CHAN_6);
        BLSG GHI     2;
        BLSG I       2 A_StartSound ("Weapons/LaserPewPew/In", slot: CHAN_7);
        BLSG IIJEDAA 2;
        goto AnimSingle.Idle;

    AnimSingle.Select:
        BLSG F 1 DoSelectOffset ((103, 67), forceNoInterpolate: true);
        BLSG F 1 {
            DoSelectOffset ((84,52));
            A_Overlay (-5, "AnimSingle.SelectHand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        BLSG F 1 DoSelectOffset ((64, 35));
        BLSG F 1 DoSelectOffset ((39, 20));
        BLSG A 1 DoSelectOffset ((20, 10));
        BLSG A 1 DoSelectOffset (( 0,  0));
        goto AnimSingle.Idle;
    AnimSingle.SelectHand:
        HAN0 A 1 DoSelectOffset ((128, 165), -5, true);
        HAN0 A 1 DoSelectOffset ((139, 157), -5);
        HAN0 A 1 DoSelectOffset ((153, 147), -5);
        stop;
    AnimSingle.Deselect:
        BLSG A 1 DoSelectOffset ((  0,  0));
        BLSG A 1 DoSelectOffset (( 20, 10));
        BLSG F 1 {
            DoSelectOffset ((39, 20));
            A_Overlay (-5, "AnimSingle.DeselectHand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        BLSG F 1 DoSelectOffset (( 64, 35));
        BLSG F 1 DoSelectOffset (( 84, 52));
        BLSG F 1 DoSelectOffset ((103, 67));
        TNT1 A 1;
        wait;
    AnimSingle.DeselectHand:
        HAN0 A 1 DoSelectOffset ((153, 147), -5, true);
        HAN0 A 1 DoSelectOffset ((139, 157), -5);
        HAN0 A 1 DoSelectOffset ((128, 165), -5);
        stop;
    }

    /** Actions (Single) **/
    states {
    Ready:
        TNT1 A 6 {
            if (invoker.akimbo)
                return ResolveState ("Akimbo.Select");

            S7_SetRightAnim ("AnimSingle.Select");

            return ResolveState (null);
        }
    Ready2:
        TNT1 A 1 {
            if (invoker.sights) {
                TakeInventory ('S7_DoMelee', 0x7FFFFFFF);
                TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);
            }

            S7_SetRightAnim ("AnimSingle.Idle");
            A_OverlayFlags (RightAnimLayer_ID, PSPF_AddBob, true);
            S7_WeaponReady ("Reload", "ChangeMode", "QuickMeleeDerp", flags: S7WRF_ChangeModeWhileSprinting, wrFlags: WRF_AllowZoom | WRF_NoSecondary);

            return ResolveState (null);
        }
        goto Ready2;
    QuickMeleeDerp:
        TNT1 A 0 {
            TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

            if (invoker.sights)
                return ResolveState ("Ready2");

            S7_SetRightAnim ("Null");

            return ResolveState (null);
        }
        goto QuickMelee;

    Deselect:
        BLSG A 0 {
            if (invoker.akimbo)
                return ResolveState ("Akimbo.Deselect");

            if (health <= 0){
                S7_SetRightAnim ("Null");
                return ResolveState ("Deselect.DEAD");
            }

            if (invoker.sights)
                return ResolveState ("Deselect.Sights");

            return ResolveState (null);
        }
        TNT1 A 6 S7_SetRightAnim ("AnimSingle.Deselect");
        goto TrueDeselect;
    Deselect.Sights:
        TNT1 A 5 {
            S7_SetRightAnim ("AnimSingle.Unzoom");

            invoker.sights = false;
            A_SetCrosshair (0);
            A_ZoomFactor (invoker.GetZoomFactor ());
        }
        goto Deselect;

    Fire:
        TNT1 A 1 bright {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            S7_SetRightAnim ("AnimSingle.Fire");

            A_AlertMonsters ();
            A_StartSound ("Weapons/LaserPewPew/Fire", slot: CHAN_Weapon);

            if (!invoker.sights) {
                A_GunFlash ("Flash");
                S7_A_FireBullets ('S7_LaserPewPew_Tracer', spread: (.2, .2), offs: (10, 4.5, 4.5), bonusDMGFactor: invoker.GetDamageBonus (), flags: S7_FB_UseAmmo);
                S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2.75, 2.75));
            } else {
                A_GunFlash ("Flash.Sights");
                S7_A_FireBullets ('S7_LaserPewPew_Tracer', spread: (.2, .2), offs: (10, 0, 3), bonusDMGFactor: invoker.GetDamageBonus (), flags: S7_FB_UseAmmo);
                S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 0, 2));
            }

            A_ZoomFactor (invoker.GetZoomFactor () * .996);
            S7_Recoil (-0.38);

            return ResolveState (null);
        }
        TNT1 A 1 {
            A_ZoomFactor (invoker.GetZoomFactor () * .998);
            S7_Recoil (-0.07);
        }
        TNT1 A 1 {
            A_ZoomFactor (invoker.GetZoomFactor ());
            S7_Recoil (-0.07);
        }
        TNT1 A 1;
        TNT1 A 1 A_Refire ("Fire");
        goto Ready2;

    DryFire:
        TNT1 A 3 {
            S7_SetRightAnim ("AnimSingle.Idle");
            A_StartSound ("Weapons/LaserPewPew/DryFire", slot: CHAN_7);
        }
        TNT1 A 0 {
            if (invoker.amount > 1 && CheckInventory (SecondMagClass, 1))
                return ResolveState ("Reload.SwapGuns");
            if (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload ())
                return ResolveState ("Reload");

            return ResolveState (null);
        }
        goto Ready2;

    Zoom:
        TNT1 A 5 {
            if (!invoker.sights) {
                S7_SetRightAnim ("AnimSingle.Zoom");

                invoker.sights = true;
                A_SetCrosshair (99);
            } else {
                S7_SetRightAnim ("AnimSingle.Unzoom");

                invoker.sights = false;
                A_SetCrosshair (0);
            }
            A_ZoomFactor (invoker.GetZoomFactor ());

            return ResolveState (null);
        }
        goto Ready2;

    Reload.Sights:
        TNT1 A 5 {
            invoker.sights = false;
            A_SetCrosshair (0);
            A_ZoomFactor (invoker.GetZoomFactor ());

            S7_SetRightAnim ("AnimSingle.Unzoom");
        }
        goto Reload;
    Reload:
        TNT1 A 0 {
            TakeInventory ('S7_Reloading', 1);

            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1))
                return ResolveState ("Ready2");

            if (invoker.sights)
                return ResolveState ("Reload.Sights");

            int ammoAmount = min (FindInventory (invoker.ammoType1).maxAmount - CountInv (invoker.ammoType1), CountInv (invoker.ammoType2));
            if (ammoAmount <= 0)
                return ResolveState ("Ready2");

            GiveInventory (invoker.ammoType1, ammoAmount);
            TakeInventory (invoker.ammoType2, ammoAmount);

            S7_SetRightAnim ("AnimSingle.Reload");

            return ResolveState (null);
        }
        TNT1 A 1 {
            let psp = player.FindPSprite (RightAnimLayer_ID);
            if (psp && InStateSequence (psp.CurState, ResolveState ("AnimSingle.Idle")))
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        wait;

    Reload.SwapGunsUnzoom:
        TNT1 A 5 {
            S7_SetRightAnim ("AnimSingle.Unzoom");

            invoker.sights = false;
            A_SetCrosshair (0);
            A_ZoomFactor (invoker.GetZoomFactor ());
        }
        goto Reload.SwapGuns;
    Reload.SwapGuns: // Gun swapping
        TNT1 A 6 {
            if (invoker.sights)
                return ResolveState ("Reload.SwapGunsUnzoom");

            S7_SetRightAnim ("AnimSingle.Deselect");

            return ResolveState (null);
        }
        TNT1 A 10 {
            int mag1 = CountInv (FirstMagClass), mag2 = CountInv (SecondMagClass);
            SetInventory (FirstMagClass, mag2);
            SetInventory (SecondMagClass, mag1);
        }
        goto Ready;

    // Muzzle flashes
    Flash:
        BLSG U 1 bright;
        stop;
    Flash.Sights:
        BLSG T 1 bright;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Tracer
//
//-------------------------------------------------------------------------------------------
class S7_LaserPewPew_Tracer : S7_LaserTracer {
    default {
        DamageFunction ((21. + fRandom [weaponDamage] (-2.5, 2.5)) * (1. + bonusDMGFactor));
        DamageType 'LaserTracer';
        Scale 0.0125;
        MissileType 'S7_LaserPewPew_Tracer_Trail';
        Decal 'S7_LaserPewPewDecal';

        -BLOODSPLATTER
    }

    states {
    Idle:
        BLSF A 1 bright;
        wait;

    Death:
    Crash:
        TNT1 A 0 A_FaceTarget;
        TNT1 A 3; //A_SpawnItemEx ('S7_LaserPewPew_Puff')
        stop;
    XDeath:
        TNT1 A 3;
        stop;
    }
}

class S7_LaserPewPew_Tracer_Trail : S7_TracerEffectsBase {
    default {
        Scale 0.0125;
    }

    states {
    Spawn:
        BLSF A 1 bright;
    Loople:
        #### # 1 bright A_FadeOut (0.2);
        wait;
    }
}
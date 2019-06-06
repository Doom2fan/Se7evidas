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
    const MagSize = 32;

    default {
        Tag "$BUTTFLY";

        Inventory.PickupMessage "$BUTTFLY";
        Inventory.PickupSound "Weapons/Pickup/Small";
        Inventory.MaxAmount 2;

        Weapon.AmmoType1 'S7_LaserPewPewClip';
        Weapon.AmmoType2 'S7_FBSysCells';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "BLSPA0";
        S7_BaseWeapon.ShortTag "$SHORTBUTTFLY";
        S7_BaseWeapon.AmmoBuyData "AFBC", 1;
        S7_BaseWeapon.BindSlot WpSlot_Light;
        S7_BaseWeapon.EnchantmentProperties false, 0.;
    }

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
        let secondMag = Ammo (Owner.FindInventory ('S7_LaserPewPewClipSecond'));

        if (self.amount < 2)
            LPP_DoDropAmmo (Ammo1, Ammo2);
        else if (amount > 1) {
            LPP_DoDropAmmo (Ammo1, Ammo2);
            LPP_DoDropAmmo (secondMag, Ammo2);
        } else if (amount == 1 && self.amount > 1)
            LPP_DoDropAmmo (secondMag, Ammo2);

        return true;
    }

    bool akimbo, sights;

    states {
    Spawn:
        BLSP A -1;
        loop;

    /** Normal mode **/
    Select.Hand:
        HAN0 A 1 DoSelectOffset ((128, 165), -5, true);
        HAN0 A 1 DoSelectOffset ((139, 157), -5);
        HAN0 A 1 DoSelectOffset ((153, 147), -5);
        stop;
    Ready:
        BLSG F 1 {
            DoSelectOffset ((103, 67), forceNoInterpolate: true);
            invoker.akimbo = false;
        }
        BLSG F 1 {
            DoSelectOffset (( 84, 52));
            A_Overlay (-5, "Select.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        BLSG F 1 DoSelectOffset (( 64, 35));
        BLSG F 1 DoSelectOffset (( 39, 20));
        BLSG A 1 DoSelectOffset (( 20, 10));
        BLSG A 1 DoSelectOffset ((  0,  0));
    Ready2:
        BLSG A 0 A_JumpIf (invoker.sights, "Ready2.Sights");
        goto Ready2.DoThings;
    Ready2.Sights:
        BLSG K 0;
        goto Ready2.DoThings;
    Ready2.DoThings:
        #### # 1 {
            if (invoker.akimbo)
                return ResolveState ("AkimboRight.Ready");

            if (invoker.sights) {
                TakeInventory ('S7_DoMelee', 0x7FFFFFFF);
                TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);
            }

            S7_WeaponReady ("Reload", "ChangeMode", flags: S7WRF_ChangeModeWhileSprinting, wrFlags: WRF_AllowZoom | WRF_NoSecondary);

            return ResolveState (null);
        }
        #### # 0 TakeInventory ('S7_HoldingZoom', 0x7FFFFFFF);
        goto Ready2;
    Ready2.HoldingZoom:
        #### # 1 S7_WeaponReady (null, null, null, wrFlags: WRF_NoFire | WRF_NoSwitch | WRF_AllowZoom);
        goto Ready2;

    ChangeMode:
        BLSG A   2 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            if (invoker.amount <= 1)
                return ResolveState ("Ready2");
            if (invoker.akimbo)
                return ResolveState ("ChangeMode.ToSingle");

            return ResolveState (null);
        }
        BLSG DEF 2;
        BLS2 A   7 {
            invoker.akimbo = true;
            A_Overlay (2, "AkimboLeft.Select");
        }
        goto AkimboRight.Ready;
    ChangeMode.ToSingle:
        BLS2 A    7 {
            invoker.akimbo = false;
            A_Overlay (2, "AkimboLeft.Deselect");
        }
        BLSG FEDA 2;
        goto Ready2;

    Deselect.Hand:
        HAN0 A 1 DoSelectOffset ((153, 147), -5, true);
        HAN0 A 1 DoSelectOffset ((139, 157), -5);
        HAN0 A 1 DoSelectOffset ((128, 165), -5);
        stop;
    Deselect:
        BLSG A 0 {
            if (health <= 0)
                return ResolveState ("Deselect.DEAD");

            if (invoker.sights)
                return ResolveState ("Deselect.Sights");

            return ResolveState (null);
        }
        BLSG A 1;
        BLSG A 1 DoSelectOffset (( 20, 10));
        BLSG F 1 {
            DoSelectOffset (( 39, 20));
            A_Overlay (-5, "Deselect.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        BLSG F 1 DoSelectOffset (( 64, 35));
        BLSG F 1 DoSelectOffset (( 84, 52));
        BLSG F 1 DoSelectOffset ((103, 67));
        goto TrueDeselect;
    Deselect.Sights:
        BLSG K   1 { invoker.sights = false; }
        BLSG N   1 {
            A_ZoomFactor (1.0);
            A_SetCrosshair (0);
        }
        BLSG MLA 1;
        goto Deselect;

    Fire:
        BLSG A 1 {
            if (invoker.akimbo)
                return ResolveState ("AkimboRight.Fire");
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_AlertMonsters ();
            A_PlaySound ("Weapons/LaserPewPew/Fire", CHAN_Weapon);

            if (invoker.sights)
                return ResolveState ("Fire.Sights");

            A_GunFlash ("Flash");
            S7_A_FireBullets ('S7_LaserPewPew_Tracer', spread: (.2, .2), offs: (10, 4.5, 4.5), bonusDMGFactor: invoker.GetDamageBonus (), flags: S7_FB_UseAmmo);
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2.75, 2.75));

            S7_Recoil (-0.38);

            return ResolveState (null);
        }
        BLSG C 1 S7_Recoil (-0.07);
        BLSG B 1 S7_Recoil (-0.07);
        BLSG A 1;   
        BLSG A 1 A_Refire ("Fire");
        goto Ready2;
    Fire.Sights:
        BLSG K 1 {
            A_GunFlash ("Flash.Sights");
            S7_A_FireBullets ('S7_LaserPewPew_Tracer', spread: (.2, .2), offs: (10, 0, 3), bonusDMGFactor: invoker.GetDamageBonus (), flags: S7_FB_UseAmmo);
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 0, 2));

            A_ZoomFactor (1.270);
            S7_Recoil (-0.38);
            //A_SetAngle (angle - 0.5 * random [weaponSpc] (-1, 1), SPF_Interpolate);

            return ResolveState (null);
        }
        BLSG O 1 {
            A_ZoomFactor (1.2725);
            S7_Recoil (-0.07);
        }
        BLSG P 1 {
            A_ZoomFactor (1.275);
            S7_Recoil (-0.07);
        }
        BlSG K 1;
        BLSG K 1 A_Refire ("Fire");
        goto Ready2;

    DryFire:
        BLSG A 0 A_JumpIf (invoker.sights, "DryFire.Sights");
        goto DryFire.End;
    DryFire.Sights:
        BLSG K 0;
        goto DryFire.End;
    DryFire.End:
        #### # 3 A_PlaySound ("Weapons/LaserPewPew/DryFire", CHAN_7);
        #### # 0 {
            if (invoker.amount > 1 && CheckInventory ('S7_LaserPewPewClipSecond', 1))
                return ResolveState ("Reload.SwapGuns");

            if (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload ())
                return ResolveState ("Reload");

            return ResolveState (null);
        }
        goto Ready2;

    Zoom:
        #### # 1 {
            if (invoker.akimbo) {
                invoker.sights = false;
                A_ZoomFactor (1.0);
                A_SetCrosshair (0);
                return ResolveState ("AkimboRight.Ready");
            }

            if (CheckInventory ('S7_HoldingZoom', 1))
                return ResolveState ("Ready2.HoldingZoom");

            GiveInventory ('S7_HoldingZoom', 1);

            if (invoker.sights)
                return ResolveState ("Unzoom");

            invoker.sights = true;
            A_SetCrosshair (99);
            A_ZoomFactor (1.275);

            return ResolveState (null);
        }

        BLSG ALMNK 1;
        goto Ready2.HoldingZoom;
    Unzoom:
        BLSG K    1 {
            invoker.sights = false;
            A_ZoomFactor (1.0);
            A_SetCrosshair (0);
        }
        BLSG NMLA 1;
        goto Ready2.HoldingZoom;

    Reload.Sights:
        BLSG K    1 {
            invoker.sights = false;
            A_SetCrosshair (0);
            A_ZoomFactor (1.0);

            return ResolveState (null);
        }
        BLSG NM 1;
        BLSG L 1 { return (!CheckInventory ('S7_Reloading', 1) ? ResolveState ("Reload.SwapGuns") : null); }
        BLSG A 1;
        goto Reload;
    Reload:
        TNT1 A 0 {
            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1)) {
                TakeInventory ('S7_Reloading', 1);
                return ResolveState ("Ready2");
            }

            if (invoker.sights)
                return ResolveState ("Reload.Sights");

            TakeInventory ('S7_Reloading', 1);

            int ammoAmount = min (FindInventory (invoker.ammoType1).maxAmount - CountInv (invoker.ammoType1), CountInv (invoker.ammoType2));
            if (ammoAmount <= 0)
                return ResolveState ("Ready2");

            GiveInventory (invoker.ammoType1, ammoAmount);
            TakeInventory (invoker.ammoType2, ammoAmount);

            return ResolveState ("ReloadFinish");
        }
    ReloadFinish:
        BLSG ADEFF   2;
        BLSG F      15 A_PlaySound ("Weapons/LaserPewPew/Out", CHAN_6);
        BLSG GHI     2;
        BLSG I       2 A_PlaySound ("Weapons/LaserPewPew/In", CHAN_7);
        BLSG IIJEDAA 2;
        goto Ready2;

    
    Reload.SwapGuns: // Gun swapping
        BLSG A 1 { return (invoker.sights ? ResolveState ("Reload.Sights") : null); }
        BLSG A 1 DoSelectOffset (( 20, 10));
        BLSG F 1 {
            DoSelectOffset (( 39, 20));
            A_Overlay (-5, "Deselect.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        BLSG F 1 DoSelectOffset (( 64, 35));
        BLSG F 1 DoSelectOffset (( 84, 52));
        BLSG F 1 DoSelectOffset ((103, 67));

        TNT1 A 10 {
            int mag1 = CountInv ('S7_LaserPewPewClip'), mag2 = CountInv ('S7_LaserPewPewClipSecond');
            SetInventory ('S7_LaserPewPewClip', mag2);
            SetInventory ('S7_LaserPewPewClipSecond', mag1);
        }


        BLSG F 1 DoSelectOffset ((103, 67));
        BLSG F 1 {
            DoSelectOffset (( 84, 52));
            A_Overlay (-5, "Select.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        BLSG F 1 DoSelectOffset (( 64, 35));
        BLSG F 1 DoSelectOffset (( 39, 20));
        BLSG A 1 DoSelectOffset (( 20, 10));
        BLSG A 1 DoSelectOffset ((  0,  0));
        goto Ready2;

    // Muzzle flashes
    Flash:
        BLSG U 1 bright;
        stop;
    Flash.Sights:
        BLSG T 1 bright;
        stop;

    /** Akimbo mode **/
    AkimboRight.Ready:
        BLS2 A 1 {
            if (invoker.amount <= 1)
                return ResolveState ("AkimboRight.NoSecLPP");
            if (!invoker.akimbo)
                return ResolveState ("AkimboRight.Derped");

            S7_WeaponReady ("AkimboRight.Reload", "ChangeMode", null, wrFlags: WRF_NoSecondary | WRF_DisableSwitch);

            return ResolveState (null);
        }
        goto AkimboRight.Ready;
    AkimboLeft.Ready:
        BLS2 A 1 {
            if (health <= 0)
                return ResolveState ("AkimboLeft.DeselectDEAD");

            if (invoker.amount <= 1)
                return ResolveState ("AkimboLeft.NoSecLPP");
            if (!invoker.akimbo)
                return ResolveState ("AkimboLeft.Derped");
            if ((player.cmd.buttons & BT_ALTATTACK))
                return ResolveState ("AkimboLeft.Fire");

            return ResolveState (null);
        }
        goto AkimboLeft.Ready;

    AkimboLeft.Select:
        TNT1 A 0 {
            A_OverlayFlags (2, PSPF_PowDouble | PSPF_CVarFast | PSPF_Flip | PSPF_Mirror, true);
            A_OverlayFlags (2, PSPF_AddWeapon | PSPF_AddBob, false);
        }
        BLSG F 1 DoSelectOffset ((103, 67), 2, forceNoInterpolate: true);
        BLSG F 1 DoSelectOffset (( 84, 52), 2);
        BLSG F 1 DoSelectOffset (( 64, 35), 2);
        BLSG F 1 DoSelectOffset (( 39, 20), 2);
        BLSG F 1 DoSelectOffset (( 20, 10), 2);
        BLSG F 1 DoSelectOffset ((  0,  0), 2);
        TNT1 A 0 {
            A_OverlayFlags (2, PSPF_AddWeapon | PSPF_AddBob, true);
            A_OverlayOffset (2, 0, 0);
        }
        goto AkimboLeft.Ready;
    AkimboLeft.Deselect:
        TNT1 A 0 {
            A_OverlayFlags (2, PSPF_PowDouble | PSPF_CVarFast | PSPF_Flip | PSPF_Mirror, true);
            A_OverlayFlags (2, PSPF_AddWeapon | PSPF_AddBob, false);
        }
        BLSG F 1 DoSelectOffset ((  0,  0), 2, forceNoInterpolate: true);
        BLSG F 1 DoSelectOffset (( 20, 10), 2);
        BLSG F 1 DoSelectOffset (( 39, 20), 2);
        BLSG F 1 DoSelectOffset (( 64, 35), 2);
        BLSG F 1 DoSelectOffset (( 84, 52), 2);
        BLSG F 1 DoSelectOffset ((103, 67), 2);
        stop;

    AkimboLeft.DeselectDEAD:
        BLSG F 1;
        goto Overlay.DeselectDEAD;

    AkimboRight.Fire:
        BLS2 A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("AkimboRight.DryFire");

            A_GunFlash ("Flash");
            A_AlertMonsters ();
            A_PlaySound ("Weapons/LaserPewPew/Fire", CHAN_Weapon);

            S7_A_FireBullets ('S7_LaserPewPew_Tracer', spread: (.2, .2), offs: (10, 4.5, 4.5), bonusDMGFactor: invoker.GetDamageBonus (), flags: S7_FB_UseAmmo);
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2.75, 2.75));

            S7_Recoil (-0.38);

            return ResolveState (null);
        }
        BLS2 C 1 S7_Recoil (-0.07);
        BLS2 B 1 S7_Recoil (-0.07);
        BLS2 A 1;
        BLS2 A 1 A_Refire ("AkimboRight.Fire");
        goto AkimboRight.Ready;
    AltFire:
    AkimboLeft.Fire:
        BLS2 A 1 {
            if (!CheckInventory ('S7_LaserPewPewClipSecond', 1))
                return ResolveState ("AkimboLeft.Dryfire");

            A_Overlay (1001, "Flash");
            A_OverlayFlags (1001, PSPF_AddWeapon | PSPF_AddBob | PSPF_PowDouble | PSPF_CVarFast | PSPF_Flip | PSPF_Mirror, true);
            A_AlertMonsters ();
            A_PlaySound ("Weapons/LaserPewPew/Fire", CHAN_Weapon);

            S7_A_FireBullets ('S7_LaserPewPew_Tracer', spread: (.2, .2), offs: (10, -4.5, 4.5), bonusDMGFactor: invoker.GetDamageBonus ());
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, -2.75, 2.75));

            TakeInventory ('S7_LaserPewPewClipSecond', 1);

            S7_Recoil (-0.38);

            return ResolveState (null);
        }
        BLS2 C 1 S7_Recoil (-0.07);
        BLS2 B 1 S7_Recoil (-0.07);
        BLS2 A 1;
        BLS2 A 1 A_JumpIf (player.cmd.buttons & BT_ALTATTACK, "AkimboLeft.Fire");
        goto AkimboLeft.Ready;

    AkimboRight.Dryfire:
        BLS2 A 7 A_PlaySound ("Weapons/LaserPewPew/DryFire", CHAN_7);
        TNT1 A 0 {
            if (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload () && !CheckInventory ('S7_LaserPewPewClipSecond', 1)) // Check the opposite ammo, if there's none, we can go ahead and reload
                return ResolveState ("AkimboRight.Reload");
            return ResolveState (null);
        }
        goto AkimboRight.Ready;
    AkimboLeft.Dryfire:
        BLS2 A 7 A_PlaySound ("Weapons/LaserPewPew/DryFire", CHAN_6);
        TNT1 A 0 {
            if (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload () && !CheckInventory ('S7_LaserPewPewClip', 1))
                return ResolveState ("AkimboLeft.Reload");
            return ResolveState (null);
        }
        goto AkimboLeft.Ready;

    AkimboLeft.Reload:
        TNT1 A 0 GiveInventory ('S7_Reloading', 1);
        goto AkimboLeft.Ready;
    AkimboRight.Reload:
        TNT1 A 0 {
            TakeInventory ('S7_Reloading', 0x7FFFFFFF);

            int mag1 = CountInv ('S7_LaserPewPewClip'), mag2 = CountInv ('S7_LaserPewPewClipSecond'),
                mag1Req = S7_LaserPewPew.MagSize - mag1, mag2Req = S7_LaserPewPew.MagSize - mag2,
                ammoPool = CountInv ('S7_FBSysCells');

            if (mag1Req + mag2Req <= 0 || ammoPool <= 0)
                return ResolveState (null);

            if (mag1Req + mag2Req > ammoPool) { // If not enough ammo to top both off
                int ammoGiven = 0, ammoToGive = 0;

                if (mag1Req == mag2Req && ammoPool < 2) // If they require the same amount and there's less than 2 ammo.
                    return ResolveState (null);

                // Equalize the mags
                if (mag1Req != mag2Req) {
                    int ammoDiff = abs (mag1Req - mag2Req); // Get the difference
                    ammoToGive = ((ammoDiff > ammoPool) ? ammoPool : AmmoDiff); // Make sure the given amount isn't greater than the available amount
                    GiveInventory ((mag1Req - mag2Req > 0) ? 'S7_LaserPewPewClip' : 'S7_LaserPewPewClipSecond', ammoToGive); // Give the ammo
                    ammoGiven += ammoToGive;
                }

                // If there's enough ammo, split it between the mags
                if (ammoPool - ammoGiven > 1) {
                    ammoToGive = ammoPool - ammoGiven;
                    ammoToGive = ((ammoToGive & 1) ? ammoToGive - 1 : AmmoToGive) / 2;  // Calculate the amount to give
                    GiveInventory ('S7_LaserPewPewClip', ammoToGive); // Give the ammo
                    GiveInventory ('S7_LaserPewPewClipSecond', ammoToGive);
                    ammoGiven += ammoToGive * 2;
                }

                TakeInventory ('S7_FBSysCells', ammoGiven); // Take the ammo from the ammo pool
            } else {
                GiveInventory ('S7_LaserPewPewClip', mag1Req);
                GiveInventory ('S7_LaserPewPewClipSecond', mag2Req);
                TakeInventory ('S7_FBSysCells', mag1Req + mag2Req);
            }

            return ResolveState ("AkimboRight.ReloadAnim");
        }
        goto AkimboRight.Ready;
    AkimboRight.ReloadAnim:
        BLS2 A 3 {
            A_Overlay (2, "AkimboLeft.ReloadAnim");
            A_OverlayFlags (2, PSPF_PowDouble | PSPF_CVarFast | PSPF_Flip | PSPF_Mirror, true);
            A_OverlayFlags (2, PSPF_AddWeapon, false);
            A_OverlayOffset (2, 0, 32);
            A_PlaySound ("Weapons/LaserPewPew/Out", CHAN_6);
        }
        // Left buttfly lower
        BLS2 AAAAA 1;
        // Start right clip insert
        BLS2 A     2;
        BLSG G     2 A_PlaySound ("Weapons/LaserPewPew/In", CHAN_7);
        BLSG HIIJJ 2;
        BLSG IHG   2; // Finish right clip insert
        BLS2 A     2;
        // Right buttfly lower, left buttfly raise
        BLS2 A 1 DoSelectOffset ((  0,  0), forceNoInterpolate: true);
        BLS2 A 1 DoSelectOffset (( 20, 10));
        BLS2 A 1 DoSelectOffset (( 39, 20));
        BLS2 A 1 DoSelectOffset (( 64, 35));
        BLS2 A 1 DoSelectOffset (( 84, 52));
        BLS2 A 1 DoSelectOffset ((103, 67));
        // Start left clip insert
        TNT1 A     2;
        TNT1 A     2;
        TNT1 AAAAA 2;
        TNT1 AAA   2; // Finish left clip insert
        // Right buttfly raise
        BLS2 A 1 DoSelectOffset ((103, 67), forceNoInterpolate: true);
        BLS2 A 1 DoSelectOffset (( 84, 52));
        BLS2 A 1 DoSelectOffset (( 64, 35));
        BLS2 A 1 DoSelectOffset (( 39, 20));
        BLS2 A 1 DoSelectOffset (( 20, 10));
        BLS2 A 3 DoSelectOffset ((  0,  0));
        goto AkimboRight.Ready;

    AkimboLeft.ReloadAnim:
        BLS2 A 3 A_PlaySound ("Weapons/LaserPewPew/Out", CHAN_5);
        // Left buttfly lower
        BLS2 A 1 DoSelectOffset ((  0,  0), 2, forceNoInterpolate: true);
        BLS2 A 1 DoSelectOffset (( 20, 10), 2);
        BLS2 A 1 DoSelectOffset (( 39, 20), 2);
        BLS2 A 1 DoSelectOffset (( 64, 35), 2);
        BLS2 A 1 DoSelectOffset (( 84, 52), 2);
        BLS2 A 1 DoSelectOffset ((103, 67), 2);
        // Start right clip insert
        TNT1 A     2;
        TNT1 A     2;
        TNT1 AAAAA 2;
        TNT1 AAA   2; // Finish right clip insert
        TNT1 A     2;
        // Left buttfly raise, right buttfly lower
        BLS2 A 1 DoSelectOffset ((103, 67), 2, forceNoInterpolate: true);
        BLS2 A 1 DoSelectOffset (( 84, 52), 2);
        BLS2 A 1 DoSelectOffset (( 64, 35), 2);
        BLS2 A 1 DoSelectOffset (( 39, 20), 2);
        BLS2 A 1 DoSelectOffset (( 20, 10), 2);
        BLS2 A 1 DoSelectOffset ((  0,  0), 2);
        // Start left clip insert
        BLS2 A     2;
        BLSG G     2 A_PlaySound ("Weapons/LaserPewPew/In", CHAN_7);
        BLSG HIIJJ 2;
        BLSG IHG   2; // Finish right clip insert
        // Right buttfly raise
        BLS2 A 5;
        BLS2 A 3;
        TNT1 A 0 {
            A_OverlayFlags (2, PSPF_AddWeapon | PSPF_AddBob | PSPF_PowDouble | PSPF_CVarFast | PSPF_Flip | PSPF_Mirror, true);
            A_OverlayOffset (2, 0, 0);
        }
        goto AkimboLeft.Ready;

    AkimboRight.Derped:
        BLS2 A    8;
        BLSG FEDA 2;
        goto Ready2;
    AkimboRight.NoSecLPP:
        TNT1 A 0 { invoker.akimbo = false; }
        goto Ready2;

    AkimboLeft.Derped:
        BLS2 GHIJK 1;
        TNT1 A     1;
        stop;
    AkimboLeft.NoSecLPP:
        TNT1 A 0 { invoker.akimbo = false; }
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Tracer
//
//-------------------------------------------------------------------------------------------
class S7_LaserPewPew_Tracer : S7_BaseTracer {
    default {
        DamageFunction ((21. + fRandom [weaponDamage] (-2.5, 2.5)) * (1. + bonusDMGFactor));
        Speed 310;
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
        "----" A 1 bright A_FadeOut (0.2);
        wait;
    }
}
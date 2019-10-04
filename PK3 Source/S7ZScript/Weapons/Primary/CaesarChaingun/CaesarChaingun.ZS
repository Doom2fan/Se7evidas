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
class S7_CaesarChaingunMag : Ammo {
    default {
        Inventory.MaxAmount 100;
        Ammo.BackpackMaxAmount 100;

        +INVENTORY.IGNORESKILL
    }
}

class S7_CaesarChaingun : S7_BaseWeapon {
    default {
        Tag "$CAESARCHAINGUN";
        Inventory.PickupMessage "$CAESARCHAINGUN";
        Inventory.PickupSound "Weapons/Pickup/Medium";

        Weapon.AmmoType1 'S7_CaesarChaingunMag';
        Weapon.AmmoType2 'S7_45WWCartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "CESRZ0";
        S7_BaseWeapon.ShortTag "$SHORTCAESARCHAINGUN";
        S7_BaseWeapon.AmmoBuyData "A45W", 6;
        S7_BaseWeapon.BindSlot WpSlot_Heavy;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties true, 0.015;
        S7_BaseWeapon.EnchantmentPrice 1250, 0.25, 1.178;
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        fireMode = 1;
    }

    override double S7_WeightSpeedModifier (double strengthStat, double berserkCount) {
        return clamp (0.65 + clamp (0.15 * log (strengthStat / 2.), 0., 1.) + (0.05 * berserkCount), 0., 1.);
    }

    override void V_S7_Recoil (double amount) {
        if (S7_Debug_NoRecoil)
            return;

        let xpSys = GetOwnerXPSystem ();
        double strengthStat = (xpSys ? xpSys.GetStat (S7Stat_Strength) / 8. : 0);

        double berserkMod = clamp (Owner.CountInv ("S7_BerserkToken") * .1, 0., 1.);

        let pPawn = S7_BasePlayer (Owner);
        if (pPawn && pPawn.playerData && !Owner.CheckInventory ("S7_BerserkToken", 1))
            berserkMod = clamp (-(.2 * pPawn.playerData.bsrkAddiction), -1., 0.);

        amount = ConvWeapRecoil (amount, strengthStat, berserkMod);

        Owner.A_SetPitch (Owner.pitch + amount, SPF_Interpolate);
    }

    const ANIM_LAYER = 2;

    action void S7_SetAnim (StateLabel animState) {
        A_Overlay (ANIM_LAYER, animState);
        A_OverlayFlags (ANIM_LAYER, PSPF_AddWeapon | PSPF_AddBob | PSPF_PowDouble | PSPF_CvarFast | PSPF_RenderStyle | PSPF_Alpha, true);
        A_OverlayFlags (ANIM_LAYER, PSPF_Flip | PSPF_Mirror | PSPF_ForceAlpha | PSPF_ForceStyle, false);
    }

    int fireMode;
    bool firedDud;

    /** Pickup **/
    states {
    Spawn:
        CESR Z -1;
        loop;
    }

    /** Animations **/
    states {
    Anim.Idle:
        CESR A 1;
        wait;
    Anim.Fire:
        CESR A 1 bright;
        goto Anim.Idle;
    Anim.Reload:
        CESR ABCD 1;
        CESR E    6;
        CESR FGH  1;
        CESR I    1 A_PlaySound ("Weapons/CaesarChaingun/Out", CHAN_5);
        CESR I    2 A_WeaponOffset (-2, 32 - 2);
        CESR J    2 A_WeaponOffset (-1, 32 - 1);
        CESR K    1 A_WeaponOffset ( 0, 32    );
        CESR LMN  1;
        CESR OPPQ 1;
        CESR R   20;
        CESR QPPO 1;
        CESR NMLK 1;
        CESR J    1 A_PlaySound ("Weapons/CaesarChaingun/In", CHAN_6);
        CESR I    2 A_WeaponOffset (2, 32 + 2);
        CESR I    2 A_WeaponOffset (1, 32 + 1);
        CESR H    1 A_WeaponOffset (0, 32    );
        CESR GF   1;
        CESR E    6;
        CESR DCBA 1;
        goto Anim.Idle;
    }

    /** Actions **/
    states {
    Ready:
        TNT1 A 0 S7_SetAnim ("Anim.Idle");
        TNT1 A 1 DoSelectOffset ((14.4 * 5, 14.4 * 5), forceNoInterpolate: true);
        TNT1 A 1 DoSelectOffset ((14.4 * 4, 14.4 * 4));
        TNT1 A 1 DoSelectOffset ((14.4 * 3, 14.4 * 3));
        TNT1 A 1 DoSelectOffset ((14.4 * 2, 14.4 * 2));
        TNT1 A 1 DoSelectOffset ((14.4 * 1, 14.4 * 1));
        TNT1 A 1 DoSelectOffset ((0, 0));
    Ready2:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");
            S7_WeaponReady ("Reload", "ChangeMode");
        }
        loop;

    ChangeMode:
        TNT1 A 5 {
            S7_SetAnim ("Anim.Idle");
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            if (++invoker.fireMode > 2)
                invoker.fireMode = 0;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);
        }
        goto Ready2;

    Deselect:
        CESR A 0 {
            if (health <= 0) {
                S7_SetAnim ("Null");
                return ResolveState ("Deselect.DEAD");
            }

            S7_SetAnim ("Anim.Idle");
            return ResolveState (null);
        }
        TNT1 A 1 DoSelectOffset ((0, 0));
        TNT1 A 1 DoSelectOffset ((14.4 * 1, 14.4 * 1));
        TNT1 A 1 DoSelectOffset ((14.4 * 2, 14.4 * 2));
        TNT1 A 1 DoSelectOffset ((14.4 * 3, 14.4 * 3));
        TNT1 A 1 DoSelectOffset ((14.4 * 4, 14.4 * 4));
        TNT1 A 1 DoSelectOffset ((14.4 * 5, 14.4 * 5));
        goto TrueDeselect;

    Fire:
        TNT1 A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            S7_SetAnim ("Anim.Fire");

            invoker.firedDud = (random [weaponSpc] (0, 255) < 2);

            if (!invoker.firedDud) {
                A_AlertMonsters ();
                A_GunFlash ("Flash");

                S7_A_FireBullets ('S7_CaesarChaingun_Tracer', spread: (.16, .16), offs: (10, 9, 6), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);
                S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 4.5, 3));

                A_PlaySound ("Weapons/CaesarChaingun/Fire", CHAN_Weapon);

                S7_Recoil ((invoker.fireMode >= 1) ? -1.35 : -0.9);
                A_WeaponOffset (6, 32 + 6);
            } else
                invoker.DepleteAmmo (false);

            S7_A_SpawnCasing ('S7_45WWCasing', (30, 15, 13), pitchOffs: -45, spread: (10, 15));

            return ResolveState (null);
        }
        TNT1 A 1 {
            if (!invoker.firedDud) {
                S7_Recoil ((invoker.fireMode >= 2) ? -1.35 : -0.9);
                A_WeaponOffset (3, 32 + 3);
            }
        }
        TNT1 A 2 {
            switch (invoker.fireMode) {
                default: A_SetTics (2); break;
                case  1: A_SetTics (1); break;
                case  2: A_SetTics (0); break;
            }
            if (!invoker.firedDud)
                S7_Recoil (-0.9);

            A_WeaponOffset (0, 32);
        }
    Fire.End:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");
            A_Refire ("Fire");
        }
        goto Ready2;

    DryFire:
        TNT1 A 3 {
            S7_SetAnim ("Anim.Idle");
            A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
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

            S7_SetAnim ("Anim.Reload");

            return ResolveState (null);
        }
        TNT1 A 1 {
            let psp = player.FindPSprite (ANIM_LAYER);
            if (psp && InStateSequence (psp.CurState, ResolveState ("Anim.Idle")))
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        wait;

    // Muzzle flashes
    Flash:
        CSRF A 1 bright;
        stop;
    }
}
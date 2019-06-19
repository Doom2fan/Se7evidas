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
// S18 "Kronos" SMG
//
//-------------------------------------------------------------------------------------------
class S7_TEC9Clip : Ammo {
    default {
        Inventory.MaxAmount 32;
        Ammo.BackpackMaxAmount 32;

        +INVENTORY.IGNORESKILL
    }
}

class S7_TEC9 : S7_BaseWeapon {
    default {
        Tag "$TEC9";
        Inventory.PickupMessage "$TEC9";
        Inventory.PickupSound "Weapons/Pickup/Small";

        Weapon.AmmoType1 'S7_TEC9Clip';
        Weapon.AmmoType2 'S7_9mmCartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "TEC9Z0";
        S7_BaseWeapon.ShortTag "$SHORTTEC9";
        S7_BaseWeapon.AmmoBuyData "A9MM", 1;
        S7_BaseWeapon.BindSlot WpSlot_Light;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties true, 0.025;
        S7_BaseWeapon.EnchantmentPrice 450, 0.375, 1.1885;
    }

    bool selecting;

    const TEC9_SUPPRESSOROVERLAY_ID = 20;
    bool hasSuppressor;

    bool fireFrame2;
    Vector3 spriteOffsets;

    override void Tick () {
        Super.Tick ();

        if (!self)
            return;

        if (hasSuppressor)
            weapIcon = "TECSZ0";
        else
            weapIcon = "TEC9Z0";
    }

    override bool SS_PreSell (int amount) {
        if (hasSuppressor) {
            if (!Owner.CheckInventory ('S7_TEC9Suppressor', 0))
                Owner.GiveInventory ('S7_TEC9Suppressor', 1);
            else
                DropAmmo ('S7_TEC9Suppressor', Owner, 1);

            hasSuppressor = false;
        }

        return true;
    }

    override Vector2 DoSelectOffset_InitialOffset () {
        return hasSuppressor ? (12, 12) : (0, 0);
    }

    states {
    Spawn:
        TEC9 Z 1 {
            if (invoker.hasSuppressor)
                sprite = GetSpriteIndex ('TECS');
            else
                sprite = GetSpriteIndex ('TEC9');
        }
        goto Spawn;

    Ready:
        TNT1 A 0 {
            invoker.selecting = true;
            A_Overlay (TEC9_SUPPRESSOROVERLAY_ID, "Overlay.Suppressor");
        }
        TEC9 A 1 DoSelectOffset ((80, 80), forceNoInterpolate: true);
        TEC9 A 1 DoSelectOffset ((64, 64));
        TEC9 A 1 DoSelectOffset ((48, 48));
        TEC9 A 1 DoSelectOffset ((32, 32));
        TEC9 A 1 DoSelectOffset ((16, 16));
        TEC9 A 1 DoSelectOffset (( 0,  0));
        TNT1 A 0 { invoker.selecting = false; }
    Ready2:
        TEC9 A 1 S7_WeaponReady ("Reload", null);
        loop;

    Overlay.Suppressor:
        TECS A 1 {
            {
                name sprite = 'TECS';
                int id = TEC9_SUPPRESSOROVERLAY_ID;
                bool showOverlay = invoker.hasSuppressor;

                let pspWeap = player.FindPSprite (PSP_Weapon);
                let pspOverlay = player.FindPSprite (id);

                if (!pspWeap || !pspOverlay)
                    return ResolveState (null);

                if (showOverlay && pspWeap.sprite == GetSpriteIndex ('TEC9')) {
                    pspOverlay.sprite = GetSpriteIndex (sprite);
                    pspOverlay.frame = pspWeap.frame;
                } else if (showOverlay && pspWeap.sprite == GetSpriteIndex ('TECR')) {
                    pspOverlay.sprite = GetSpriteIndex (sprite);
                    pspOverlay.frame = 0;
                } else {
                    pspOverlay.sprite = GetSpriteIndex ('TNT1');
                    pspOverlay.frame = 0;
                }
            }

            if (health <= 0)
                return ResolveState ("Overlay.DeselectDEAD");

            if (!invoker.selecting) {
                if (invoker.hasSuppressor)
                    A_WeaponOffset (12 + invoker.spriteOffsets.X, 32 + 12 + invoker.spriteOffsets.Y, int (invoker.spriteOffsets.Z));
                else
                    A_WeaponOffset (0 + invoker.spriteOffsets.X, 32 + invoker.spriteOffsets.Y, int (invoker.spriteOffsets.Z));
            }

            return ResolveState (null);
        }
        wait;

    Deselect:
        TEC9 A 0 {
            if (health <= 0)
                return ResolveState ("Deselect.DEAD");

            invoker.selecting = true;
            return ResolveState (null);
        }
        TEC9 A 1 DoSelectOffset (( 0,  0));
        TEC9 A 1 DoSelectOffset ((16, 16));
        TEC9 A 1 DoSelectOffset ((32, 32));
        TEC9 A 1 DoSelectOffset ((48, 48));
        TEC9 A 1 DoSelectOffset ((64, 64));
        TEC9 A 1 DoSelectOffset ((80, 80));
        TNT1 A 0 {
            invoker.selecting = false;
            A_Overlay (TEC9_SUPPRESSOROVERLAY_ID, "Null");
        }
        goto TrueDeselect;

    Fire:
        TEC9 B 1 { invoker.fireFrame2 = false; }
    Hold:
        TEC9 D 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true)) {
                A_ClearRefire ();
                return ResolveState ("DryFire");
            }

            if (!invoker.hasSuppressor) {
                A_PlaySound ("Weapons/TEC-9/Fire", CHAN_Weapon);
                A_AlertMonsters ();
                A_GunFlash ();
            } else {
                A_PlaySound ("Weapons/TEC-9/Fire", CHAN_Weapon, volume: 0.35);
                A_AlertMonsters (384.0);
            }

            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2.5, 2.25));

            if (!invoker.hasSuppressor) {
                S7_A_SpawnCasing ('S7_9mmCasing', (30, 11, 9.5), pitchOffs: -45, spread: (10, 15));
                S7_A_FireBullets ('S7_TEC9Tracer', spread: (.45, .45), offs: (10, 4.25, 4), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);
            } else {
                S7_A_SpawnCasing ('S7_9mmCasing', (30, 14, 9.5), pitchOffs: -45, spread: (10, 15));
                S7_A_FireBullets ('S7_TEC9Tracer', spread: (.45, .45), offs: (10, 5.25, 5), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);
            }

            S7_Recoil (-0.25);

            let psp = player.FindPSprite (PSP_Weapon);
            if (psp && invoker.fireFrame2)
                psp.frame = 2; // C
            else if (psp)
                psp.frame = 3; // D

            invoker.spriteOffsets = (4, 4, 0);

            invoker.fireFrame2 = !invoker.fireFrame2;

            return ResolveState (null);
        }
        TEC9 B 1 {
            S7_Recoil (-0.25);
            invoker.spriteOffsets = (0, 0, WOF_Interpolate);
        }
        TEC9 B 1 A_Refire ();
        TEC9 B 1 { player.WeaponState |= WF_WeaponReady; }
        goto Ready2;

    DryFire:
        TEC9 B 1 {
            A_PlaySound ("Weapons/DryFireSMG", CHAN_7);
            A_ClearRefire ();
        }
        TEC9 A 3;
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            TakeInventory ('S7_Reloading', 1);
            A_ClearRefire ();

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
        TNT1 A    0 A_PlaySound ("Weapons/TEC-9/Out", CHAN_6);
        TECR ABCD 1;
        TECR D    5;
        TECR DEF  2;
        TNT1 A    0 A_PlaySound ("Weapons/TEC-9/In", CHAN_7);
        TECR G    2 { invoker.spriteOffsets = (0, -6, 0); }
        TECR H    2;
        TECR I    2 { invoker.spriteOffsets = (0, -3, 0); }
        TECR J    2 { invoker.spriteOffsets = (0,  0, 0); }
        TECR KLM  2;
        TECR N    2 A_PlaySound ("Weapons/TEC-9/Tap", CHAN_6);
        TECR O    2 { invoker.spriteOffsets = (0, -8, 0); }
        TECR P    2 { invoker.spriteOffsets = (0, -6, 0); }
        TECR P    4 { invoker.spriteOffsets = (0, -3, 0); }
        TECR Q    2 { invoker.spriteOffsets = (0, -6, 0); }
        TECR R    2 { invoker.spriteOffsets = (0, -3, 0); }
        TECR S    2 { invoker.spriteOffsets = (0,  0, 0); }
        goto Ready2;

    // Muzzle flashes
    Flash:
        TNT1 A 0 bright A_Jump (256, "Flash1", "Flash2");
    Flash1:
        TECF A 1 bright;
        stop;
    Flash2:
        TECF B 1 bright;
        stop;
    }
}
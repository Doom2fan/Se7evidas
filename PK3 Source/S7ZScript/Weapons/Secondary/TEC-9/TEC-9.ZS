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

        Weapon.AmmoType1 'S7_TEC9Clip';
        Weapon.AmmoType2 'S7_9mmCartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "TEC9Z0";
        S7_BaseWeapon.ShortTag "$SHORTTEC9";
        S7_BaseWeapon.BindSlot WpSlot_Light;
        S7_BaseWeapon.UsesMag true;
    }

    bool selecting;

    const TEC9_SUPPRESSOROVERLAY_ID = 20;
    bool hasSuppressor;

    const BURSTLENGTH = 3;
    bool burstFire;
    int burstCount;

    override void Tick () {
        Super.Tick ();

        if (!self)
            return;

        if (hasSuppressor)
            weapIcon = "TECSZ0";
        else
            weapIcon = "TEC9Z0";
    }

    override void DoEffect () {
        Super.DoEffect ();

        fireModeIcon = burstFire ? FMI_BurstFire : FMI_FullAuto;
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
        TEC9 A 1 {
            invoker.burstCount = 0;
            S7_WeaponReady ("Reload", "ChangeMode");
        }
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
                    return;

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

            if (!invoker.selecting) {
                if (invoker.hasSuppressor)
                    A_WeaponOffset (12, 32 + 12);
                else
                    A_WeaponOffset (0, 32);
            }
        }
        loop;

    Deselect:
        TNT1 A 0 { invoker.selecting = true; }
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
        TEC9 B 1;
    Hold:
        TEC9 C 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            if (!invoker.hasSuppressor) {
                A_PlaySound ("Weapons/TEC-9/Fire", CHAN_Weapon);
                A_AlertMonsters ();
                A_GunFlash ();
            } else {
                A_PlaySound ("Weapons/TEC-9/Fire", CHAN_Weapon, volume: 0.35);
                A_AlertMonsters (384.0);
            }

            A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 1.8, 4.5);

            if (!invoker.hasSuppressor) {
                A_FireProjectile ('S7_9mmCasingSpawn', 0, false, 9, -2);
                A_FireProjectile ('S7_TEC9Tracer', fRandom [weaponSpread] (-0.45, 0.45), true, 2, 2, 0, fRandom [weaponSpread] (-0.45, 0.45));
            } else {
                A_FireProjectile ('S7_9mmCasingSpawn', 0, false, 11, -4);
                A_FireProjectile ('S7_TEC9Tracer', fRandom [weaponSpread] (-0.45, 0.45), true, 3, 1, 0, fRandom [weaponSpread] (-0.45, 0.45));
            }

            if (invoker.burstFire) {
                S7_Recoil (-0.5);

                if ((invoker.burstCount & 1)) // Show frame D on odd shots and frame C on even shots
                    return ResolveState ("Fire.Burst2");
                else
                    return ResolveState ("Fire.Burst1");
            } else
                S7_Recoil (-0.25);

            return ResolveState (null);
        }
        TEC9 D 1 S7_Recoil (-0.25);
        goto Fire.End;
    Fire.Burst1:
        TEC9 C 1;
        goto Fire.End;
    Fire.Burst2:
        TEC9 D 1;
        goto Fire.End;
    Fire.End:
        TEC9 B 1 {
            if (invoker.burstFire)
                invoker.burstCount++;

            if (invoker.burstFire && invoker.burstCount >= BURSTLENGTH)
                invoker.burstCount = 0;
            else
                A_Refire ();

            A_ClearRefire ();
            return ResolveState (null);
        }
        TEC9 A 7;
        goto Ready2;

    ChangeMode:
        TEC9 A 5 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);
            invoker.burstCount = 0;

            if (invoker.burstFire)
                invoker.burstFire = false;
            else
                invoker.burstFire = true;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);
        }
        goto Ready2;

    DryFire:
        TEC9 B 1 {
            invoker.burstCount = 0;
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
        TNT1 A         0 A_PlaySound ("Weapons/TEC-9/Out", CHAN_6);
        TECR ABCDEEEEE 1;
        TECR FGH       2;
        TNT1 A         0 A_PlaySound ("Weapons/TEC-9/In", CHAN_7);
        TECR IJKLMNO   2;
        TNT1 A         0 A_PlaySound ("Weapons/TEC-9/Tap", CHAN_6);
        TECR PQRRRSTU  2;
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
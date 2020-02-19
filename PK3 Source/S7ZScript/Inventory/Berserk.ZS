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

/* Credits:
** Coding: Chronos "phantombeta" Ouroboros, Xaser
**
** Sprites:
**   HUD Sprites: Xaser, Chronos "phantombeta" Ouroboros
**   Animation: Xaser, Chronos "phantombeta" Ouroboros
**
** Sounds: Credits in the SNDINFO file (SNDINFO.MiscInventory)
*/

class S7_Berserk : Inventory {
    default {
        //$Category "Se7evidas/Inventory"
        //$Color 13
        //$Title "XS-22 Emergency Stimulant Cocktail"
        //$NotAngled

        Tag "$XS22ESC";
        Inventory.Icon "BSRKA0";
        Inventory.PickupMessage "$XS22ESC";
        Inventory.Amount 1;
        Inventory.MaxAmount 5;
        Inventory.InterHubAmount 5;

        +INVENTORY.INVBAR
    }

    override bool Use (bool pickup) {
        let bsrkWeap = Owner.FindInventory ('S7_BerserkWeap');

        if (bsrkWeap)
            bsrkWeap.Use (false);
        else {
            bsrkWeap = owner.GiveInventoryType ('S7_BerserkWeap');

            if (bsrkWeap)
                bsrkWeap.Use (false);
        }

        return false;
    }

    states {
    Spawn:
        BSRK A -1;
        stop;
    }
}

class S7_BerserkToken : Powerup {
    default {
        Inventory.MaxAmount 3;

        Powerup.Duration -120;
        Powerup.Color "FF 20 20", 0.25;

        +INVENTORY.PERSISTENTPOWER
    }

    override void AttachToOwner (Actor other) {
        Super.AttachToOwner (other);

        let pPawn = S7_BasePlayer (other);
        if (pPawn && pPawn.playerData)
            pPawn.playerData.bsrkAddiction++;
    }

    override bool HandlePickup (Inventory item) {
        if (item.GetClass () == GetClass ()) {
            let power = Powerup (item);
            if (power.EffectTics == 0) {
                power.bPickupGood = true;
                return true;
            }

            let pPawn = S7_BasePlayer (Owner);

            // Handle addiction
            if (pPawn && pPawn.playerData) {
                if (pPawn.playerData.bsrkAddiction) {
                    int maxAddiction = max (pPawn.playerData.bsrkMaxAddiction, pPawn.playerData.bsrkAddiction);
                    pPawn.playerData.bsrkMaxAddiction = maxAddiction + 1;
                }

                pPawn.playerData.bsrkAddiction++;
            }

            // Increase the effect's duration.
            if ((Amount + power.Amount) > 1)
                power.EffectTics = 60;

            EffectTics += power.EffectTics / max (Amount, 1);
            Amount += power.Amount;

            power.bPickupGood = true;
            return true;
        }
        return false;
    }

    override void DoEffect () {
        Super.DoEffect ();

        // Shouldn't happen, but hey!
        if (!self || bDestroyed || !Owner || Owner.health <= 0 || owner.bKilled)
            return;

        double timeMod = 1. - (.25 * (Amount / 3.));
        double regenTime = clamp (15 * timeMod, 1, 15);

        if (Amount > 3 && (random [berserkEffects] (0, 255) < 26 || (EffectTics % regenTime) ~== floor (regenTime / 2.)))
            Owner.DamageMobj (Owner, Owner, 1, 'S7_BerserkDamage', DMG_No_Armor | DMG_Thrustless);

        // Can actually happen now if the owner dies
        if (!self || bDestroyed || !Owner || Owner.health <= 0 || owner.bKilled)
            return;

        double regenRateAmount = 0, regenRateTime = 1;
        let xpSys = S7_XPSystem (Owner.FindInventory ("S7_XPSystem"));
        if (xpSys)
            [regenRateTime, regenRateAmount] = xpSys.GetStatMod (S7Stat_Special, specialName: "regenRate");

        if (EffectTics % max (regenTime * regenRateTime, 2) == 0) {
            double regenAmount = 5 * clamp (regenTime / 15., 0., 1.);
            Owner.GiveBody (int (clamp (regenAmount, 1, 5) + regenRateAmount));
        }
    }
}

class S7_BerserkWeap : S7_BaseWeapon {
    default {
        Tag "$XS22ESCWEAP";

        +INVENTORY.UNDROPPABLE +INVENTORY.UNTOSSABLE +WEAPON.CHEATNOTWEAPON
    }

    override bool Use (bool pickup) {
        return !pickup ? Weapon.Use (false) : false;
    }

    action void S7_A_InjectBerserk () {
        TakeInventory ('S7_Berserk', 1);
        GiveInventory ('S7_BerserkToken', 1);

        let pPawn = S7_BasePlayer (self);
        if (pPawn) {
            double maxMul = .25;

            for (int i = 0; i < (CountInv ('S7_BerserkToken') - 1); i++)
                maxMul *= .8;

            pPawn.GiveBody (int (ceil (pPawn.GetMaxHealth () * maxMul)));
        }
    }

    states {
    Spawn:
        TNT1 A 0 A_SpawnItemEx ('S7_Berserk', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, SXF_NoCheckPosition);
        stop;

    Ready:
        SYR1 A 1 {
            if (CountInv ('S7_Berserk') <= 0)
                return ResolveState ("Ready2.NoBerserk");

            DoSelectOffset ((-12.8 * 5, 12.8 * 5), forceNoInterpolate: true);

            return ResolveState (null);
        }
        SYR1 A 1 DoSelectOffset ((-12.8 * 4, 12.8 * 4));
        SYR1 A 1 DoSelectOffset ((-12.8 * 3, 12.8 * 3));
        SYR1 A 1 DoSelectOffset ((-12.8 * 2, 12.8 * 2));
        SYR1 A 1 DoSelectOffset ((-12.8 * 1, 12.8 * 1));
        TNT1 A 0 DoSelectOffset ((0, 0));
        goto Ready2;
    Ready2:
        SYR1 A 0 A_JumpIf (CountInv ('S7_Berserk') <= 0, "Ready2.NoBerserk");
        goto Ready2.DoThings;
    Ready2.NoBerserk:
        TNT1 A 0;
        goto Ready2.DoThings;
    Ready2.DoThings:
        #### # 1 S7_WeaponReady (null, null);
        goto Ready2;

    Deselect:
        SYR1 A 1 A_JumpIf (CountInv ('S7_Berserk') <= 0, "TrueDeselect");
        SYR1 A 1 DoSelectOffset ((-12.8 * 1, 12.8 * 1));
        SYR1 A 1 DoSelectOffset ((-12.8 * 2, 12.8 * 2));
        SYR1 A 1 DoSelectOffset ((-12.8 * 3, 12.8 * 3));
        SYR1 A 1 DoSelectOffset ((-12.8 * 4, 12.8 * 4));
        SYR1 A 1 DoSelectOffset ((-12.8 * 5, 12.8 * 5));
        TNT1 A 0 DoSelectOffset ((0, 0));
        goto TrueDeselect;

    Fire:
        SYR1 A          3 A_JumpIf (!CheckInventory ('S7_Berserk', 1), "Ready2");
        SYR1 CDD        3;
        SYR1 EFGHI      1;
        SYR1 J          5;
        SYR1 KL         1;
        SYR1 M          8 A_StartSound ("Syringe/In", slot: CHAN_5);
        SYR1 N          2;
        SYR1 O          2 {
            A_StartSound ("Berserk/Inject", slot: CHAN_Weapon);
            A_StartSound ("*pain", slot: CHAN_Voice);
        }
        SYR1 P          2;
        SYR1 Q          2 S7_A_InjectBerserk ();
        SYR1 QRSTUVWWWX 2;
        SYR1 Y          8;
        SYR1 Z          2;
        SYR2 A          2 A_StartSound ("Syringe/Out", slot: CHAN_5);
        SYR2 BCD        2;
        SYR2 E          8;
        SYR2 FG         2;
        SYR2 HIJKL      1;
        TNT1 A          0;
        SYR2 MN         1;
        SYR2 O          1 A_FireProjectile ('S7_SpentSyringe', 0, false, 0, 0);
        SYR2 PQR        1;
        TNT1 A          8;
        goto Ready;
    }
}

class S7_SpentSyringe : S7_CasingBase {
    default {
        Scale 0.1;
        SeeSound "Weapons/Shell";
    }

    states {
    Spawn:
        SYTR ABCDEFGHIJKLMNOP 1;
        loop;
    Death:
        #### # 1 A_Jump (256, "Delaying");
        wait;
    }
}
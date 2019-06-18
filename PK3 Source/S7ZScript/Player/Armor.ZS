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

class S7_ArmorData play {
    int armorBonuses;

    virtual void Init (S7_BasicArmor armor) { }
    virtual void Tick (S7_BasicArmor armor) { }

    virtual void FixArmor (S7_BasicArmor armor, int amount) { }
    virtual void GotBonus (S7_BasicArmor armor, int amount) { }

    virtual double GetSpeedFactor () { return 1; }

    virtual int HandleDamage (S7_BasicArmor armor, Actor inflictor, Actor source, int damage, Name damageType) {
        int saved;
        int full = max (0, armor.MaxFullAbsorb - armor.AbsorbCount);

        if (damage < full)
            saved = damage;
        else {
            saved = full + int ((damage - full) * armor.SavePercent);

            if (armor.MaxAbsorb > 0 && saved + armor.AbsorbCount > armor.MaxAbsorb)
                saved = max (0,  armor.MaxAbsorb - armor.AbsorbCount);
        }

        if (armor.Amount < saved)
            saved = armor.Amount;

        armor.Amount -= saved;
        armor.AbsorbCount += saved;

        return damage - saved;
    }
}

class S7_BasicArmor : BasicArmor {
    S7_ArmorData armorData;
    double bonusFactor; // The factor for the armor bonuses is saved as an optimization.
    int    bonusFactorAmount;

    override void DoEffect () {
        Inventory basicArmor;
        if (basicArmor = Owner.FindInventory ('BasicArmor'))
            Owner.RemoveInventory (basicArmor);

        if (armorData)
            armorData.Tick (self);
    }

    override bool HandlePickup (Inventory item) {
        if (item.GetClass () == 'S7_BasicArmor')
            return true; // You shouldn't be picking up S7_BasicArmor anyway.

        if (!item.bIgnoreSkill) {
            /*if (item is 'S7_BasicArmorBonus') {
                let armor = S7_BasicArmorBonus (item);
                armor.SaveAmount = int (armor.SaveAmount * G_SkillPropertyFloat (SKILLP_ArmorFactor));
            } else*/ if (item is 'S7_BasicArmorPickup') {
                let armor = S7_BasicArmorPickup (item);
                armor.SaveAmount = int (armor.SaveAmount * G_SkillPropertyFloat (SKILLP_ArmorFactor));
            }
        }

        return false;
    }

    static bool IsBulletDamageType (name damageType) {
        switch (damageType) {
            case 'PistolTracer':
            case 'RevolverTracer':
            case 'ShotgunTracer':
            case 'RifleTracer':
            case 'SniperRifleTracer':
                return true;

            default:
                return false;
        }
    }

    override void AbsorbDamage (int damage, Name damageType, out int newdamage) {
        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn) { // Uhhhh... Shouldn't happen...
            newdamage = damage;
            return;
        }

        int saved;

        if (!DamageTypeDefinition.IgnoreArmor (damageType)) {
            if (armorData)
                newDamage = armorData.HandleDamage (self, pPawn.damageInflictor, pPawn.damageSource, damage, damageType);

            if (Amount <= 0) {
                // The armor has become useless
                SavePercent = 0;
                ArmorType = 'None';

                if (armorData) {
                    armorData.Destroy ();
                    armorData = null;
                }
            }
        }

        if (armorData && (newDamage != damage || ArmorType != 'None') && !IsBulletDamageType (damageType) && !(pPawn.damageInflictor is 'S7_BulletTracer')) {
            if (armorData.armorBonuses == 0)
                bonusFactor = 1.;

            if (bonusFactorAmount != armorData.armorBonuses) {
                double bonuses = clamp (armorData.armorBonuses, 0, 300); // This is clamped to [0-300] because at >~350 the result starts to increase

                bonusFactor = clamp (S7_Math.Lerp (1. / ((bonuses + 28) / 30.) * 1.15,  1.7 * log10 ((bonuses + 1) / 50.), .1) + .15, .5, 1.);
                bonusFactorAmount = armorData.armorBonuses;
            }

            double curBonusFactor = bonusFactor;

            // Hurtfloors don't get affected by armor bonuses as much as enemy attacks.
            if (!pPawn.damageInflictor && !pPawn.damageSource)
                curBonusFactor = clamp (curBonusFactor * 1.5, .5, 1.);

            newDamage = int (max (newDamage * curBonusFactor, newDamage * 0.25));
        }

        // Once the armor has absorbed its part of the damage, then apply its damage factor, if any, to the player
        if ((newDamage > 0) && (ArmorType != 'None')) // S7_BasicArmor is not going to have any damage factor, so skip it.
            newdamage = ApplyDamageFactors (ArmorType, damageType, newDamage, newDamage);
    }
}

class S7_BasicArmorPickup : BasicArmorPickup {
    class<S7_ArmorData> dataClass;

    property DataClass: dataClass;

    default {
        S7_BasicArmorPickup.dataClass 'S7_ArmorData';
    }

    override Inventory CreateCopy (Actor other) {
        let copy = S7_BasicArmorPickup (Super.CreateCopy (other));

        copy.dataClass = dataClass;

        return copy;
    }

    override bool Use (bool pickup) {
        let armor = S7_BasicArmor (Owner.FindInventory ('S7_BasicArmor'));

        // This should really never happen but let's be prepared for a broken inventory.
        if (armor == null) {
            armor = S7_BasicArmor (Spawn ('S7_BasicArmor'));
            armor.BecomeItem ();
            Owner.AddInventory (armor);
        } else {
            // If you already have more armor than this item gives you, you can't
            // use it.
            if (armor.Amount >= SaveAmount + armor.BonusCount)
                return false;
            // Don't use it if you're picking it up and already have some.
            if (pickup && armor.Amount > 0 && MaxAmount > 0)
                return false;
        }

        if (armor.armorData)
            armor.armorData.Destroy ();

        armor.SavePercent = clamp (SavePercent, 0, 100) / 100;
        armor.Amount = SaveAmount + armor.BonusCount;
        armor.MaxAmount = SaveAmount;
        armor.Icon = Icon;
        armor.MaxAbsorb = MaxAbsorb;
        armor.MaxFullAbsorb = MaxFullAbsorb;
        armor.ArmorType = GetClassName ();
        armor.ActualSaveAmount = SaveAmount;
        armor.armorData = S7_ArmorData (new (dataClass));
        armor.armorData.Init (armor);

        return true;
    }
}
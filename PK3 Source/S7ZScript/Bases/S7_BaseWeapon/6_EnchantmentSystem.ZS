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

extend class S7_BaseWeapon {
    // Price, power
    int, double Enchantments_GetNewEnchantmentData (int powerLevel, int amount) const {
        double finalPower = (enchantment_BasePower * powerLevel);

        double finalPrice = enchantment_Price_Base;
        finalPrice *= (1. + (enchantment_Price_PowerMul * (powerLevel - 1)));
        finalPrice = finalPrice * (enchantment_Price_AmountD ** amount);

        int finalPriceInt = int (finalPrice);
        finalPriceInt = (
            ((finalPriceInt % 10) == 5) ?
            finalPriceInt :
            (finalPriceInt + (finalPriceInt % 2))
        );

        return finalPriceInt, finalPower;
    }
    int Enchantments_GetSellPrice () const {
        int ret = 0;

        for (int i = 0; i < enchantments_List.Size (); i++) {
            double finalPrice = enchantment_Price_Base;
            finalPrice *= (1. + (enchantment_Price_PowerMul * (enchantments_List [i])));
            finalPrice = finalPrice * (enchantment_Price_AmountD ** i);

            int finalPriceInt = int (finalPrice);
            finalPriceInt = (
                ((finalPriceInt % 10) == 5) ?
                finalPriceInt :
                (finalPriceInt + (finalPriceInt % 2))
            );

            ret += finalPriceInt;
        }

        return ret;
    }

    Array<int> enchantments_List;
    double Enchantments_GetDamageBonus () {
        int totalPowerLevel = 0;

        int enchantmentsCount = enchantments_List.Size ();
        for (int i = 0; i < enchantmentsCount; i++)
            totalPowerLevel += enchantments_List [i];

        return totalPowerLevel * enchantment_BasePower;
    }
}
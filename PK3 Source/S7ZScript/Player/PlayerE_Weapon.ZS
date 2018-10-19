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

extend class S7_BasePlayer {
    static const string PermanentWeapons [] = {
        "S7_GrenadeWeap:S7_GrenadeCount",
        "S7_BerserkWeap:S7_Berserk"
    };

    void Weapon_PermanentWeapons () {
        for (int i = 0; i < PermanentWeapons.Size (); i++) {
            Array<String> parts;
            PermanentWeapons [i].Split (parts, ":");

            // If this happens someone's a fucking idiot.
            if (parts.Size () < 1 || parts.Size () > 2)
                continue;

            if ((parts.Size () == 1 || CheckInventory (parts [1], 1)) && !CheckInventory (parts [0], 1))
                GiveInventory (parts [0], 1);
        }
    }

    const BaseAmmoMax = 6.0;
    void Weapon_SetAmmoMax () {
        double ammoMax = BaseAmmoMax;

        if (CheckInventory ("S7_BackpackToken", 1))
            ammoMax += 2.0;

        if (ammoMax != playerData.ammoMaxMult) { // Only update if it changed...
            for (int i = 0; i < S7_WeapData.AmmoTypesData.Size (); i++) {
                Array<String> res;
                S7_WeapData.AmmoTypesData [i].Split (res, ":");
                if (res.Size () != 2) // Uhhh... Should always equal two exactly...
                    continue;

                Ammo ammoInv = Ammo (FindInventory (res [0]));
                int maxAmount = int (floor (res [1].ToInt () * ammoMax));

                if (ammoInv)
                    ammoInv.maxAmount = maxAmount;
                else {
                    ammoInv = Ammo (GiveInventoryType (res [0]));
                    if (ammoInv) {
                        ammoInv.maxAmount = maxAmount;
                        ammoInv.amount = 0;
                    }
                }
            }
        }

        playerData.ammoMaxMult = ammoMax;
    }

    S7_BaseWeapon GiveBasics_GiveStartingWeapon (class<S7_BaseWeapon> weapon) {
        if (!CheckInventory (weapon, 1))
            GiveInventory (weapon, 1);

        let weap = S7_BaseWeapon (FindInventory (weapon));

        if (weap)
            weapBinds.Binds [int (weap.bindSlot)].Push (weap);

        return weap;
    }
}
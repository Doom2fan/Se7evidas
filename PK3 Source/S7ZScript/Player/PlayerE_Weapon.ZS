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

extend class S7_BasePlayer {
    /** Weapon selection **/
    bool selectedWeapon;
    override Weapon PickWeapon (int slot, bool checkammo) {
        selectedWeapon = true;

        bool isDraco = (player.mo is 'S7_DracoPlayer');
        let selWeap = weapBinds.PickWeapon (slot, false, isDraco);
        weapBinds.LastWeapon = selWeap;
        return selWeap;
    }

    override Weapon PickNextWeapon () {
        selectedWeapon = true;

        bool isDraco = (player.mo is 'S7_DracoPlayer');
        let selWeap = weapBinds.CycleWeapons (false, false, isDraco);
        weapBinds.LastWeapon = selWeap;
        return selWeap;
    }

    override Weapon PickPrevWeapon () {
        selectedWeapon = true;

        bool isDraco = (player.mo is 'S7_DracoPlayer');
        let selWeap = weapBinds.CycleWeapons (true, false, isDraco);
        weapBinds.LastWeapon = selWeap;
        return selWeap;
    }

    /** Ammo max **/
    const BaseAmmoMax = 6.0;
    void Weapon_SetAmmoMax () {
        if (player.cheats & CF_Predicting)
            return;

        for (int i = 0; i < S7_WeapData.AmmoTypesData.Size (); i++) {
            Array<String> res;
            res.Clear ();

            S7_WeapData.AmmoTypesData [i].Split (res, ":");
            int resSize = res.Size ();
            if (resSize != 2 && resSize != 3) // Uhhh... Should always equal two or three exactly...
                continue;

            double ammoMax = BaseAmmoMax;

            /** Calculate the maximum amount for the pool **/
            if (resSize == 3)
                ammoMax = res [2].ToDouble ();

            if (CheckInventory ('S7_BackpackToken', 1))
                ammoMax *= 1.33334;

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

    /** Misc **/
    S7_BaseWeapon GiveBasics_GiveStartingWeapon (Class<S7_BaseWeapon> weapon) {
        if (!CheckInventory (weapon, 1))
            GiveInventory (weapon, 1);

        let weap = S7_BaseWeapon (FindInventory (weapon));

        if (weap)
            weapBinds.Binds [int (weap.bindSlot)].Push (weap);

        return weap;
    }
}
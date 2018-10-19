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
    static const string StatNames [] = {
        "strength",
        "agility",
        "vitality",
        "defense",
        "will",
        "magic",
        "tech"
    };

    override void CheatGive (String name, int amount) {
        let player = self.player;

        if (player.mo == NULL || player.health <= 0)
            return;

        int giveall = ALL_NO;
        if (name ~== "all")
            giveall = ALL_YES;
        else if (name ~== "everything")
            giveall = ALL_YESYES;

        if (giveall == ALL_YESYES || name ~== "levels") {
            xpSys.GiveXP (int.max);

            if (!giveall)
                return;
        }

        if (giveall == ALL_YESYES || name ~== "attrPoints") {
            xpSys.attrPoints += amount;

            if (!giveall)
                return;
        }

        for (int i = 0; i < StatNames.Size (); i++) {
            if (name ~== StatNames [i]) {
                xpSys.SetStat (i + 1, amount, true);

                return;
            }
        }

        if (giveall || name ~== "weapons") {
            let savedpending = player.PendingWeapon;
            for (int i = 0; i < AllActorClasses.Size (); ++i) {
                let type = (class<S7_BaseWeapon>) (AllActorClasses [i]);
                if (type != null && type != "S7_BaseWeapon") {
                    // Don't give replaced weapons unless the replacement was done by Dehacked.
                    let rep = GetReplacement (type);
                    if (rep == type || rep is "DehackedPickup") {
                        readonly<S7_BaseWeapon> def = GetDefaultByType (type);
                        if (giveall == ALL_YESYES || !def.bCheatNotWeapon)
                            GiveInventory (type, 1, true);
                    }
                }
            }
            player.PendingWeapon = savedpending;

            if (!giveall)
                return;
        }

        Super.CheatGive (name, amount);
    }
}
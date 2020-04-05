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
    /* Summary:
    **  Called before an item is sold. Return value indicates whether to continue the transaction.
    **
    ** Returns:
    **  Returns a bool indicating whether or not to continue selling the weapon.
    */
    virtual bool SS_PreSell (int amount) {
        if (usesMag && Ammo1 && Ammo2) {
            int count = Ammo1.Amount;
            int excess = max ((Ammo2.Amount + count) - Ammo2.MaxAmount, 0);

            if ((count - excess) > 0)
                Owner.GiveInventory (Ammo2.GetClass (), count - excess);

            if (excess > 0) {
                let drop = Ammo (Spawn (Ammo2.GetClass (), Owner.Vec3Offset (0, 0, 10.), NO_REPLACE));

                if (drop) {
                    drop.amount = excess;

                    drop.angle = Owner.angle;
                    drop.VelFromAngle (5.);
                    drop.vel.Z = 1.;
                    drop.vel += Owner.vel;
                }
            }

            Owner.TakeInventory (Ammo1.GetClass (), count);
        }

        return true;
    }

    /* Summary:
    **  Called after the weapon has been successfully sold.
    */
    virtual void SS_OnSell (int amount) { }
}
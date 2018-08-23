/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

class S7_FScreenSBarAmmoBar {
    Class<Weapon> weap;
    Class<Inventory> magType;
    Class<Inventory> poolType;
    string sprite;
    Array<double> xPositions;
    Array<double> yPositions;

    static S7_FScreenSBarAmmoBar GenerateBar (Class<Weapon> weap, Class<Inventory> magType, Class<Inventory> poolType, int ammoMax, string sprite, double initialX, double xIncrAmount, double yPos1, double yPos2 = double.Infinity, double yPos3 = double.Infinity) {
        let bar = new ("S7_FScreenSBarAmmoBar");
        bar.weap     = weap;
        bar.magType  = magType;
        bar.poolType = poolType;
        bar.sprite   = sprite;

        double curX = initialX;
        int curY = 0;
        Array<double> yPos; // This is dumb, but whatever.

        yPos.Push (yPos1);

        if (yPos2 != double.Infinity)
            yPos.Push (yPos2);
        if (yPos3 != double.Infinity)
            yPos.Push (yPos3);

        for (int i = 0; i < ammoMax; i++) {
            bar.xPositions.Push (curX);
            bar.yPositions.Push (yPos [curY]);
            curX += xIncrAmount;
            curY++;
            if (curY >= yPos.Size ())
                curY = 0;
        }

        return bar;
    }
}
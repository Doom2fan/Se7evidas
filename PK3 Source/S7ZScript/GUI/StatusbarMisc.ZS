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

class S7_FScreenSBarAmmoBar {
    Class<Weapon> weap;
    Class<Inventory> magType;
    Class<Inventory> poolType;
    string sprite;
    Array<double> xPositions;
    Array<double> yPositions;
    Vector2 scale;
    int rowsCount;

    static S7_FScreenSBarAmmoBar GenerateBar (Class<Weapon> weap, Class<Inventory> magType, Class<Inventory> poolType, int ammoMax, string sprite, double initialX, double xIncrAmount, double yPos1, double yPos2 = double.Infinity, double yPos3 = double.Infinity, Vector2 scale = (1, 1)) {
        let bar = new ('S7_FScreenSBarAmmoBar');
        bar.weap     = weap;
        bar.magType  = magType;
        bar.poolType = poolType;
        bar.sprite   = sprite;
        bar.scale    = scale;

        double curX = initialX;
        int curY = 0;
        Array<double> yPos; // This is dumb, but whatever.
        yPos.Clear ();

        yPos.Push (yPos1);

        if (yPos2 != double.Infinity)
            yPos.Push (yPos2);
        if (yPos3 != double.Infinity)
            yPos.Push (yPos3);

        bar.rowsCount = yPos.Size ();

        Array<double> xPositions; xPositions.Clear ();
        Array<double> yPositions; yPositions.Clear ();

        for (int i = 0; i < ammoMax; i++) {
            xPositions.Push (initialX + (xIncrAmount * i));
            yPositions.Push (yPos [curY]);
            curY++;
            if (curY >= bar.rowsCount)
                curY = 0;
        }
        bar.xPositions.Clear (); bar.xPositions.Reserve (ammoMax);
        bar.yPositions.Clear (); bar.yPositions.Reserve (ammoMax);

        for (int x = ammoMax; x >= 0;) {
            int startY = (x % bar.rowsCount);
            if (startY == 0) startY = bar.rowsCount;

            for (int y = startY; y >= 0; y--) {
                if ((x - y) >= ammoMax || (x - y) < 0)
                    continue;

                bar.xPositions [x - y] = xPositions [x - y];
                bar.yPositions [x - y] = yPositions [x - y];
            }

            x -= startY;
        }

        return bar;
    }
}
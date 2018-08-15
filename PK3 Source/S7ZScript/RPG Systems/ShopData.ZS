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

class S7_ShopData {
    Array<S7_SSItem> allItems;
}

class S7_ShopDataEventHandler : EventHandler {
    override void WorldLoaded (WorldEvent e) {
        let serverData = S7_ServerData.Get ();
        
        Populate (serverData);
    }

    override void WorldTick () {
        let serverData = S7_ServerData.Get ();
        
        Populate (serverData);
    }

    void Populate (S7_ServerData serverData) {
        if (!serverData.shopData) {
            serverData.shopData = new ("S7_ShopData");
            mainShop_Populate (serverData);
        }
    }
}
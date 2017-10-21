/*
**  Se7evidas - A GZDoom mod
**  Copyright (C) 2015-???  Chronos Ouroboros
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License along
**  with this program; if not, write to the Free Software Foundation, Inc.,
**  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#include "includes.h"
#include "shop/shop.h"
#include "shop/shop_process.h"
#include "shop/shop_items/externs.h"
#include "gui/pmCallbacks.h"

enum {
    PMMU_ShopUse = 1,
};

bool PlayerMenu_MainEnabled (PlayerData_t *player, PM_Item *item) {
    switch (item->callbackID) {
        case PMMU_ShopUse:
            return !player->shopDef.disableOpen;
            break;

        default:
            return TRUE;
            break;
    }
}

void PlayerMenu_MainUse (PlayerData_t *player, PM_Item *item) {
    switch (item->callbackID) {
        case PMMU_ShopUse: { // Open the shop
                PM_ChangePage (player, NULL); // Close the menu
                SS_OpenPage (player, &mainSP, OXF_ForceAll); // Change the page to main
                player->shopDef.open = TRUE; // Set open to TRUE
                SetPlayerProperty (FALSE, ON, PROP_TOTALLYFROZEN); // Freeze the player
                player->shopDef.moveDelay = (SS_ONMOVEDELAY / 2); // Set the movement delay
            }
            break;

        default:
            break;
    }
}
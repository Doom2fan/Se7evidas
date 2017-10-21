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
#include "shop/shop_items.h"
#include "shop/shop_process.h"
#include "shop/shop_render.h"

#ifndef SHOP_C
#define SHOP_C

void ShopSystem_Script (PlayerData_t *player) {
    if (!player)
        return;

    SS_ProcessToggle (player); // Process the menu toggling

    if (player->health.health <= 0 && (player->shopDef.open || player->shopDef.shop != NULL || player->shopDef.page != NULL)) { // Close the shop if the player died with it open
        SS_OpenPage (player, NULL, OXF_ForceAll); // Change the page to NULL
        player->shopDef.sellMode = FALSE; // Set sellMode to FALSE
        SetPlayerProperty (FALSE, OFF, PROP_TOTALLYFROZEN); // Unfreeze the player
        player->shopDef.moveDelay = SS_ONMOVEDELAY; // Set the movement delay
    }

    // Processing
    SS_Movement (player); // Process the movement

    // Rendering
    if (player->shopDef.page != NULL) {
        if (player->shopDef.page->renderer)
            player->shopDef.page->renderer (player);
        else if (player->shopDef.shop && player->shopDef.shop->renderer)
            player->shopDef.shop->renderer (player);
        else
            SS_Render (player);
    }
}

#endif
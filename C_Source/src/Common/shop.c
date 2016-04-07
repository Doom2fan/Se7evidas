/*
**  Se7evidas - A GZDoom mod
**  Copyright (C) 2015  Chronos Ouroboros
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
#include "shop.h"
#include "shop_items.h"
#include "shop_process.h"
#include "shop_render.h"

#ifndef SHOP_C
#define SHOP_C
        
void ShopSystem_Script (PlayerData_t *player) {
    if (!player)
        return;
    
    SS_ProcessToggle (player); // Process the menu toggling
    if (player->shopDef.open) {
        // Processing
        SS_Movement (player); // Process the movement

        // Rendering
        if (player->shopDef.page && player->shopDef.page->renderer)
            player->shopDef.page->renderer (player);
        else if (player->shopDef.shop && player->shopDef.shop->renderer)
            player->shopDef.shop->renderer (player);
        else
            SS_Render (player);
    }
}

#endif
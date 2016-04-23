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
#include "shop/shop.h"
#include "shop/shop_items.h"
#include "shop/shop_render.h"

#define SS_PrintHudMessage(id, color, x, y, ...) \
( \
HudMessage (HUDMSG_PLAIN | HUDMSG_LAYER_OVERHUD, id, color, (x) + 0.1k, (y) + 0.1k, 0.1, 0.0k, 0.0k, 0.0k, __VA_ARGS__) \
)
#define SS_PrintSprite(id, x, y, spr) \
( \
SetFont (spr), \
HudMessage (HUDMSG_PLAIN | HUDMSG_LAYER_OVERHUD, id, CR_UNTRANSLATED, (x) + 0.1k, (y) + 0.2k, 0.1, 0.0k, 0.0k, 0.0k, "A") \
)
#define SHOPBASEID 9000
#define VITEMOFF 2

// This probably breaks for pages that reach the limit of 100 but I'm never gonna have pages that big so bleh. You can increase it by something
// like 5 or 10 if you do have pages with 100 items for some reason
void SS_Render (PlayerData_t *player) {
    int id = SHOPBASEID; // Define id and initialize it to SHOPBASEID

    SetHudSize (320, 200, FALSE); // Set the hud size to 320x200
    SetFont (s"SMALLFNT"); // Set the font to SMALLFNT
    if (!player->shopDef.sellMode) // If sellMode is not TRUE...
        SS_PrintHudMessage (id, CR_WHITE, 117.0k, 6.0k, "%LS", s"SS_BUYMODE"); // Print the message
    else // If not...
        SS_PrintHudMessage (id, CR_WHITE, 117.0k, 6.0k, "%LS", s"SS_SELLMODE");  // Print the message
    id++; // Increment the id

    if (!player->shopDef.page)
        goto Finish;

    SetFont (s"SMALLFNT"); // Set the font to SMALLFNT
    SS_PrintHudMessage (id, CR_WHITE, 6.0k, 6.0k, "%LS", player->shopDef.page->name); // Print the message
    id++; // Increment the id

    SetFont (s"FSHUDFNT"); // Set the font to FSHUDFONT

    SS_Item_t *vItems [5]; // Define *vItems []
    int vItemsStart = 0, vItemsLength = 0, // Define vItemsStart, vItemsLength,
        firstVItem  = 0, lastVItem    = 0; // firstVItem and lastVItem and initialize them to 0.

    if (player->shopDef.position.y + 1 > VITEMOFF) { // If y + 1 is greater than VITEMOFF...
        firstVItem = player->shopDef.position.y - VITEMOFF;
        lastVItem  = player->shopDef.position.y < SS_ITEMSMAX - VITEMOFF ? player->shopDef.position.y + VITEMOFF : player->shopDef.position.y;
        vItemsStart = vItemsLength = 0; // Set vItemsStart and vItemsLength to 0
    } else if (player->shopDef.position.y < VITEMOFF) { // If y is lesser than VITEMOFF...
        firstVItem = player->shopDef.position.y - (VITEMOFF - (player->shopDef.position.y > 0 ? player->shopDef.position.y : VITEMOFF));
        lastVItem  = player->shopDef.position.y < SS_ITEMSMAX - VITEMOFF ? player->shopDef.position.y + VITEMOFF : player->shopDef.position.y;
        vItemsStart = vItemsLength = VITEMOFF - player->shopDef.position.y; // Set vItemsStart and vItemsLength to VITEMOFF - player->shopDef.position.y
    }

    for (int i = firstVItem; i < lastVItem + 1; i++) { // Define i and initialize it to firstVItem; Loop while i is lesser than lastVItem + 1; Increment i
        if (i < 0 || i + 1 >= player->shopDef.itemsLength || vItemsLength + 1 > 5) // If i is lesser than 0, i + 1 is greater than itemsLength or vItemsLength + 1 is greater than 5...
            break; // Break
        vItems [vItemsLength] = player->shopDef.items [i]; // Set vItems [vItemsLength] to items [i]
        vItemsLength++; // Increment vItemsLength
    }

    for (int i = vItemsStart; i < vItemsLength; i++) {// Define i and initialize it to vItemsStart; Loop while i is lesser than vItemsLength; Increment i
        SS_Item_t *item = vItems [i]; // Define *item and initialize it to vItems [i]

        int color = item == player->shopDef.items [player->shopDef.position.y] ? CR_RED : CR_WHITE; // Define color and initialize it to CR_RED if item is equal to items [y], if not, initialize it to CR_WHITE
        accum yOff = 30.0k + (35.0k * i); // Define yOff and initialize it to 30.0 + (35.0 * i)

        if (item->icon != s"") // If the item has an icon...
            SS_PrintSprite (id + 2, 4.0k, yOff, item->icon); // Print it
        SetFont (s"FSHUDFNT"); // Set the font to FSHUDFONT
        if (item->name != s"") // If the item has a name...
            SS_PrintHudMessage (id + 0, color, 4.0k, yOff, "%LS", item->name); // Print it
        id += 3; // Increment id by 3
    }
    for (int i = vItemsLength; i < 5; i++) { // Define i and set it to vItemsLength; Loop while i is lesser than 5; Increment i
        ClearMessage (id + 2); // Clear id + 2
        ClearMessage (id + 1); // Clear id + 1
        ClearMessage (id); // Clear id
        id += 3; // Increment id by 3
    }

Finish:
    SS_PrintSprite (id, -91.0k, 200.0k, s"SSTBACKG"); // Print the background
    id++; // Increment the id

    SetHudSize (0, 0, FALSE); // Set the hud size to 0x0 (Reset SetHudSize)
}
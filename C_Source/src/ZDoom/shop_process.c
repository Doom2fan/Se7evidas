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

// Ammo max amount callback
int SS_AmmoMaxAmount (PlayerData_t *player, SS_Item_t *item) {
    int magSize = item->maxAmount;
    if (CheckInventory (s"Backpack"))
        return magSize * 8;
    else
        return magSize * 6;
}

// Default buy callback
int SS_BuyItem (PlayerData_t *player, SS_Item_t *item) {
    if (!player) {
        Log ("\\cgFunction SS_BuyItem: Fatal error: Invalid or NULL player struct");
        return BC_InvalidPlayer;
    } else if (!item) {
        Log ("\\cgFunction SS_BuyItem: Fatal error: Invalid or NULL item struct");
        return BC_InvalidItem;
    }

    int maxAmount = 0;
    if (item->maxAmountCallback)
        maxAmount = item->maxAmountCallback (player, item);
    else
        maxAmount = item->maxAmount;
    
    if (CheckInventory (item->inventoryName) + (item->buyAmount > 1 ? (item->buyAmount / 2) : item->buyAmount) >= maxAmount) // If the current amount of the item plus half the buyAmount is greater than or equal to the max amount...
        return BC_InventoryFull; // Report the inventory is full
    if (player->cash - item->buyPrice < 0) // If the amount of cash minus the price of the item is less than zero...
        return BC_NotEnoughMoney; // Report there's not enough money

    TakeCash (player, item->buyPrice); // Take the cash
    GiveInventory (item->inventoryName, item->buyAmount); // Give the item

    return BC_Success; // Report success
}
// Default sell callback
int SS_SellItem (PlayerData_t *player, SS_Item_t *item) {
    if (!player) {
        Log ("\\cgFunction SS_SellItem: Fatal error: Invalid or NULL player struct");
        return SC_InvalidPlayer;
    } else if (!item) {
        Log ("\\cgFunction SS_SellItem: Fatal error: Invalid or NULL item struct");
        return SC_InvalidItem;
    }
    
    if (CheckInventory (item->inventoryName) < item->sellAmount) // If the current amount of the item is lesser than sellAmount...
        return SC_NotEnoughOfItem; // Report there's not enough of the item
    if (player->cash + item->sellPrice > 0x7FFFFFFF) // If the cash plus the price of the item is greater than 0x7FFFFFFF...
        return SC_TooMuchMoney; // Report there's too much money

    TakeInventory (item->inventoryName, item->sellAmount); // Take the item
    GiveCash (player, item->sellPrice); // Give the cash

    return SC_Success; // Report success
}

void SS_ChangePage (PlayerData_t *player, SS_Page_t *page) {
    if (!player) {
        Log ("\\cgFunction SS_ChangePage: Fatal error: Invalid or NULL player struct");
        return;
    }
    
    player->shopDef.page = page; // Set the stored page pointer to page
    player->shopDef.position.y = 0;
    if (page) { // If page is not null...
        int i = 0; // Define i and initialize it to 0
        SS_Item_t *currentItem = player->shopDef.page->items; // Define currentItem and set it to the first item in the current page's item list
        for (; i < SS_ITEMSMAX; i++) { // ; Loop while i is lesser than SS_ITEMSMAX; Increment i
            if (!currentItem) // If currentItem is null...
                break; // Break

            player->shopDef.items [i] = currentItem; // Set item [i] to currentItem
            if (currentItem->next == currentItem) // If the next item is the same as the current...
                break; // Break
            else // If not...
                currentItem = currentItem->next; // Set the current item to the next item
        }
        player->shopDef.itemsLength = i + 1; // Set itemsLength to i + 1
        for (; i < SS_ITEMSMAX; i++) // ; Loop while i is lesser than SS_ITEMSMAX; Increment i
            player->shopDef.items [i] = NULL; // Set item [i] to NULL
    } else { // If not...
        player->shopDef.itemsLength = 0; // Set itemsLength to 0
        for (int i = 0; i < SS_ITEMSMAX; i++) // Define i and initialize it to 0; Loop while i is lesser than SS_ITEMSMAX; Increment i
            player->shopDef.items [i] = NULL; // Set item [i] to NULL
    }
}

int SS_OpenPage (PlayerData_t *player, SS_Page_t *page, int flags) {
    if (!player) {
        Log ("\\cgFunction SS_OpenPage: Fatal error: Invalid or NULL player struct");
        return FALSE;
    }

    if (!(flags & OXF_ForceShop) && player->shopDef.open) // If the OXF_ForceShop flag is not set and the shop is open...
        return OXC_ShopOpen; // Return OXC_ShopOpen

    if (!(flags & OXF_ForceOther) && !player->shopDef.open && player->shopDef.page) // If the OXF_ForceOther flag is not set, the shop is not open and shopDef.page is not NULL...
        return OXC_OtherOpen; // Return OXC_OtherOpen

    if (page && player->shopDef.page && player->shopDef.page == page) // if page is not NULL, shopdef.page is not NULL and shopDef.page is equal to page...
        return OXC_AlreadyOpen; // Return OXC_AlreadyOpen

    SS_ChangePage (player, page);

    if (flags & OXF_DisableShop)
        player->shopDef.disableOpen = TRUE;

    return OXC_Success;
}

int SS_OpenShop (PlayerData_t *player, SS_Shop_t *shop, int flags) {
    if (!player) {
        Log ("\\cgFunction SS_OpenShop: Fatal error: Invalid or NULL player struct");
        return FALSE;
    }

    if (!(flags & OXF_ForceShop) && player->shopDef.open) // If the OXF_ForceShop flag is not set and the shop is open...
        return OXC_ShopOpen; // Return OXC_ShopOpen

    if (!(flags & OXF_ForceOther) && !player->shopDef.open && player->shopDef.shop) // If the OXF_ForceOther flag is not set, the shop is not open and shopDef.shop is not NULL...
        return OXC_OtherOpen; // Return OXC_OtherOpen

    if (shop && player->shopDef.shop && player->shopDef.shop == shop) // if shop is not NULL, shopdef.shop is not NULL and shopDef.shop is equal to shop...
        return OXC_AlreadyOpen; // Return OXC_AlreadyOpen

    if (!(flags & OSF_NoPage) && shop && shop->mainPage)
        SS_ChangePage (player, shop->mainPage);
    else if (!(flags & OSF_NoPage))
        SS_ChangePage (player, NULL);


    if (flags & OXF_DisableShop)
        player->shopDef.disableOpen = TRUE;

    return OXC_Success;
}

void SS_ProcessToggle (PlayerData_t *player) {
    if (!player)
        return;

    if (!player->shopDef.disableOpen && !player->shopDef.open && KeyPressed (BT_USER3) && player->shopDef.page) { // If disableOpen is false, the shop menu is closed, the BT_USER3 key was hit and there is a page set/open...
        SS_ChangePage (player, NULL); // Change the page to NULL
        player->shopDef.sellMode = FALSE; // Set sellMode to FALSE
        SetPlayerProperty (FALSE, OFF, PROP_TOTALLYFROZEN); // Unfreeze the player
    } else if (!player->shopDef.disableOpen && !player->shopDef.open && KeyPressed (BT_USER3)) { // If disableOpen is false, the shop menu is closed and the BT_USER3 key was hit...
        SS_ChangePage (player, &main); // Change the page to main
        player->shopDef.open = TRUE; // Set open to TRUE
        SetPlayerProperty (FALSE, ON, PROP_TOTALLYFROZEN); // Freeze the player
    } else if (player->shopDef.open && KeyPressed (BT_USER3)) {
        SS_ChangePage (player, NULL); // Change the page to NULL
        player->shopDef.open = FALSE; // Set open to FALSE
        player->shopDef.sellMode = FALSE; // Set sellMode to FALSE
        SetPlayerProperty (FALSE, OFF, PROP_TOTALLYFROZEN); // Unfreeze the player
    }
}

void SS_ProcessUse (PlayerData_t *player, bool sellMode) {
    if (!player)
        return;

    int index = player->shopDef.position.y; // Define index and set it to x multiplied by y
    SS_Item_t *item = player->shopDef.items [index]; // Define item and point it to the SS_Item_t in the items array at index
    int returnCode; // Define returnCode

    if (!item)
        return;

    if (sellMode && (item->itemType & IT_SellItem)) // If sellMode is TRUE and the SellItem flag is set...
        returnCode = item->sellCallback (player, item); // Set returnCode to the return value from sellCallback
    else if (!sellMode && (item->itemType & IT_BuyItem)) // If sellMode is FALSE and the BuyItem flag is set...
        returnCode = item->buyCallback (player, item); // Set returnCode to the return value from buyCallback

    if ((item->itemType & IT_PageLink) && item->link) { // If the PageLink flag is set...
        if ((item->linkType & LT_Always)) // If the LT_Always flag is set...
            SS_ChangePage (player, item->link); // Change page to item->link
        else if (sellMode && (item->itemType & IT_SellItem)) { // If sellMode is TRUE and the IT_SellItem flag is set...
            if (returnCode == SC_Success && (item->linkType & LT_OnSuccess)) // If the return code is SC_Success and the LT_OnSuccess flag is set...
                SS_ChangePage (player, item->link); // Change page to item->link
            else if (returnCode != SC_Success && (item->linkType & LT_OnFailure)) // If the return code is not SC_Success and the LT_OnFailure flag is set...
                SS_ChangePage (player, item->link); // Change page to item->link
        } else if (!sellMode && (item->itemType & IT_BuyItem)) { // If sellMode is FALSE and the IT_BuyItem flag is set...
            if (returnCode == BC_Success && (item->linkType & LT_OnSuccess)) // If the return code is BC_Success and the LT_OnSuccess flag is set...
                SS_ChangePage (player, item->link); // Change page to item->link
            else if (returnCode != BC_Success && (item->linkType & LT_OnFailure)) // If the return code is not BC_Success and the LT_OnFailure flag is set...
                SS_ChangePage (player, item->link); // Change page to item->link
        }
    }
}
#define ONMOVEDELAY 5
void SS_Movement (PlayerData_t *player) {
    if (!player)
        return;
    
    if (player->shopDef.moveDelay <= 0) { // If the movement delay/cooldown is equal to or lesser than 0...
        if (GetPlayerInput (-1, INPUT_SIDEMOVE) > 0) { // If the player has positive > 0 movement on the left/right axis...
            player->shopDef.position.x--; // Decrement x
            player->shopDef.moveDelay = ONMOVEDELAY; // Set the movement delay/cooldown to ONMOVEDELAY
        } else if (GetPlayerInput (-1, INPUT_SIDEMOVE) < 0) { // If the player has negative < 0 movement on the left/right axis...
            player->shopDef.position.x++; // Increment x
            player->shopDef.moveDelay = ONMOVEDELAY; // Set the movement delay/cooldown to ONMOVEDELAY
        }

        if (GetPlayerInput (-1, INPUT_FORWARDMOVE) > 0 && (player->shopDef.items [player->shopDef.position.y - 1]) != NULL && player->shopDef.position.y - 1 >= 0) { // If the player has positive > 0 movement on the forward/backwards axis and the item isn't NULL...
            player->shopDef.position.y--; // Increment y
            player->shopDef.moveDelay = ONMOVEDELAY; // Set the movement delay/cooldown to ONMOVEDELAY
        } else if (GetPlayerInput (-1, INPUT_FORWARDMOVE) < 0 && (player->shopDef.items [player->shopDef.position.y + 1]) != NULL && player->shopDef.position.y + 1 < SS_ITEMSMAX) { // If the player has negative < 0 movement on the forward/backwards axis and the item isn't NULL...
            player->shopDef.position.y++; // Decrement y
            player->shopDef.moveDelay = ONMOVEDELAY; // Set the movement delay/cooldown to ONMOVEDELAY
        }
        
        if (KeyPressed (SS_SELLMODEKEY)) { // If the player hit SS_SELLMODEKEY...
            if (!player->shopDef.sellMode) // If sellMode is not TRUE...
                player->shopDef.sellMode = TRUE; // Set sellMode to TRUE
            else // If not...
                player->shopDef.sellMode = FALSE; // Set sellMode to FALSE
        }

        if (KeyPressed (BT_USE)) { // If the player hit the use key...
            SS_ProcessUse (player, player->shopDef.sellMode); // Process it
            player->shopDef.moveDelay = ONMOVEDELAY; // Set the movement delay/cooldown to ONMOVEDELAY
        }
    }

    if (player->shopDef.moveDelay > 0) // If the movement delay/cooldown counter is greater than 0...
        player->shopDef.moveDelay--; // Decrement the counter
}
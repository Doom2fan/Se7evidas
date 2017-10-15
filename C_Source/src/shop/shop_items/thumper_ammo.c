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
#include "shop/shop_items/externs.h"
#include "shop/shop_process.h"

// Functions
// Thumper grenades buy callback
/*int SS_TH_BuyItem (PlayerData_t *player, SS_Item_t *item) {
    if (!player) {
        Log ("\CFunction SS_TH_BuyItem: Fatal error: Invalid or NULL player struct");
        return BC_InvalidPlayer;
    } else if (!item) {
        Log ("\CFunction SS_TH_BuyItem: Fatal error: Invalid or NULL item struct");
        return BC_InvalidItem;
    }

    if (Thumper_GetUnifiedPool () + (item->buyAmount > 1 ? (item->buyAmount / 2) : item->buyAmount) >= Thumper_GetUnifiedPoolMax ()) // If the current amount of the unified pool is greater than or equal to the unified max amount...
        return BC_InventoryFull; // Report the inventory is full
    if (player->cash - item->buyPrice < 0) // If the amount of cash minus the price of the item is less than zero...
        return BC_NotEnoughMoney; // Report there's not enough money

    TakeCash (player, item->buyPrice); // Take the cash
    GiveInventory (Thumper_PoolNames [item->maxAmount], item->buyAmount); // Give the item

    return BC_Success; // Report success
}
// Thumper grenades sell callback
int SS_TH_SellItem (PlayerData_t *player, SS_Item_t *item) {
    if (!player) {
        Log ("\CFunction SS_TH_SellItem: Fatal error: Invalid or NULL player struct");
        return SC_InvalidPlayer;
    } else if (!item) {
        Log ("\CFunction SS_TH_SellItem: Fatal error: Invalid or NULL item struct");
        return SC_InvalidItem;
    }

    if (CheckInventory (Thumper_PoolNames [item->maxAmount]) < item->sellAmount) // If the current amount of the item is lesser than sellAmount...
        return SC_NotEnoughOfItem; // Report there's not enough of the item
    if (player->cash + item->sellPrice > 0x7FFFFFFF) // If the cash plus the price of the item is greater than 0x7FFFFFFF...
        return SC_TooMuchMoney; // Report there's too much money

    TakeInventory (Thumper_PoolNames [item->maxAmount], item->sellAmount); // Take the item
    GiveCash (player, item->sellPrice); // Give the cash

    return SC_Success; // Report success
}

// Items
SS_Item_t thumperAmmoItems [] = {
    {
        .name               = s"SS_BACK",
        .icon               = SS_BACKICON,
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &ammoSP,
        .next               = &thumperAmmoItems [1],
    },
    {
        .name               = s"SS_TH_EXP",
        .description        = s"SS_TH_EXPDESC",
        .icon               = s"SSTTHG1",

        .itemType           = IT_BuySellItem,
        .next               = &thumperAmmoItems [2],

        .maxAmount          = 1,
        .buyPrice           = 300,
        .buyAmount          = 1,
        .sellPrice          = 150,
        .sellAmount         = 1,
        .buyCallback        = &SS_TH_BuyItem,
        .sellCallback       = &SS_TH_SellItem,
    },
    {
        .name               = s"SS_TH_FRAG",
        .description        = s"SS_TH_FRAGDESC",
        .icon               = s"SSTTHG2",

        .itemType           = IT_BuySellItem,
        .next               = &thumperAmmoItems [3],

        .maxAmount          = 2,
        .buyPrice           = 330,
        .buyAmount          = 1,
        .sellPrice          = 165,
        .sellAmount         = 1,
        .buyCallback        = &SS_TH_BuyItem,
        .sellCallback       = &SS_TH_SellItem,
    },
    {
        .name               = s"SS_TH_THRM",
        .description        = s"SS_TH_THERMDESC",
        .icon               = s"SSTTHG3",

        .itemType           = IT_BuySellItem,
        .next               = &thumperAmmoItems [4],

        .maxAmount          = 3,
        .buyPrice           = 380,
        .buyAmount          = 1,
        .sellPrice          = 190,
        .sellAmount         = 1,
        .buyCallback        = &SS_TH_BuyItem,
        .sellCallback       = &SS_TH_SellItem,
    },
    {
        .name               = s"SS_TH_FLRE",
        .description        = s"SS_TH_FLREDESC",
        .icon               = s"SSTTHG4",

        .itemType           = IT_BuySellItem,
        .next               = &thumperAmmoItems [5],

        .maxAmount          = 4,
        .buyPrice           = 250,
        .buyAmount          = 1,
        .sellPrice          = 125,
        .sellAmount         = 1,
        .buyCallback        = &SS_TH_BuyItem,
        .sellCallback       = &SS_TH_SellItem,
    },
    {
        .name               = s"SS_TH_CLST",
        .description        = s"SS_TH_CLUSTERDESC",
        .icon               = s"SSTTHG5",

        .itemType           = IT_BuySellItem,
        .next               = &thumperAmmoItems [6],

        .maxAmount          = 5,
        .buyPrice           = 415,
        .buyAmount          = 1,
        .sellPrice          = 208,
        .sellAmount         = 1,
        .buyCallback        = &SS_TH_BuyItem,
        .sellCallback       = &SS_TH_SellItem,
    },
    {
        .name               = s"SS_TH_NAIL",
        .description        = s"SS_TH_NAILDESC",
        .icon               = s"SSTTHG6",

        .itemType           = IT_BuySellItem,
        .next               = &thumperAmmoItems [7],

        .maxAmount          = 6,
        .buyPrice           = 450,
        .buyAmount          = 1,
        .sellPrice          = 225,
        .sellAmount         = 1,
        .buyCallback        = &SS_TH_BuyItem,
        .sellCallback       = &SS_TH_SellItem,
    },
    {
        .name               = s"SS_TH_NGAS",
        .description        = s"SS_TH_NGASDESC",
        .icon               = s"SSTTHG7",

        .itemType           = IT_BuySellItem,
        .next               = NULL,

        .maxAmount          = 7,
        .buyPrice           = 625,
        .buyAmount          = 1,
        .sellPrice          = 313,
        .sellAmount         = 1,
        .buyCallback        = &SS_TH_BuyItem,
        .sellCallback       = &SS_TH_SellItem,
    },
};

SS_Page_t thumperAmmoSP = {
    .name       = s"SS_THGRENADES",
    .items      = &thumperAmmoItems [0],
};*/
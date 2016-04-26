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
#include "shop/shop_process.h"
#include "shop/shop_items/externs.h"

SS_Item_t batteriesAmmoItems [] = {
    {
        .name               = s"SS_BACK",
        .icon               = SS_BACKICON,
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &ammoSP,
        .next               = &batteriesAmmoItems [1],
    },
    {
        .name               = s"CELLS",
        .description        = s"SS_CELLSDESC",
        .icon               = s"SSTCELTA",
        .inventoryName      = s"S7_Cells",

        .itemType           = IT_BuySellItem,
        .next               = &batteriesAmmoItems [2],

        .maxAmount          = 36,
        .buyPrice           = 240,
        .buyAmount          = 36,
        .sellPrice          = 120,
        .sellAmount         = 36,
        .buyCallback        = &SS_BuyItem,
        .sellCallback       = &SS_SellItem,
        .maxAmountCallback  = &SS_AmmoMaxAmount,
    },
    {
        .name               = s"FBSYSCELLS",
        .description        = s"SS_FBSYSCELLSDESC",
        .icon               = s"SSTCELFB",
        .inventoryName      = s"S7_FBSysCells",

        .itemType           = IT_BuySellItem,
        .next               = NULL,

        .maxAmount          = 23,
        .buyPrice           = 300,
        .buyAmount          = 23,
        .sellPrice          = 150,
        .sellAmount         = 23,
        .buyCallback        = &SS_BuyItem,
        .sellCallback       = &SS_SellItem,
        .maxAmountCallback  = &SS_AmmoMaxAmount,
    },
};

SS_Page_t batteriesAmmoSP = {
    .name       = s"SS_BATTERIES",
    .items      = &batteriesAmmoItems [0],
};
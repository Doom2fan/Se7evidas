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

#ifndef SSI_BULLET_AMMO_H
#define SSI_BULLET_AMMO_H

#include <ACS_ZDoom.h>
#include "../shop_process.h"
#include "ammo.h"

static SS_Item_t bulletAmmoItems [] = {
    {
        .name               = s"SS_BACK",
        .icon               = SS_BACKICON,
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &ammo,
        .next               = &bulletAmmoItems [1],
    },
    {
        .name               = s"9MM",
        .description        = s"SS_9MMDESC",
        .icon               = s"graphics/Menu/Shop/9mmBox.png",
        .inventoryName      = s"S7_9mmCartridges",

        .itemType           = IT_BuySellItem,
        .next               = &bulletAmmoItems [2],

        .maxAmount          = 15,
        .buyPrice           = 240,
        .buyAmount          = 30,
        .sellPrice          = 120,
        .sellAmount         = 30,
        .buyCallback        = &SS_BuyItem,
        .sellCallback       = &SS_SellItem,
        .maxAmountCallback  = &SS_AmmoMaxAmount,
    },
    {
        .name               = s"45ACP",
        .description        = s"SS_45ACPDESC",
        .icon               = s"graphics/Menu/Shop/45ACPBox.png",
        .inventoryName      = s"S7_45ACPCartridges",

        .itemType           = IT_BuySellItem,
        .next               = &bulletAmmoItems [3],

        .maxAmount          = 62,
        .buyPrice           = 386,
        .buyAmount          = 62,
        .sellPrice          = 193,
        .sellAmount         = 62,
        .buyCallback        = &SS_BuyItem,
        .sellCallback       = &SS_SellItem,
        .maxAmountCallback  = &SS_AmmoMaxAmount,
    },
    {
        .name               = s"44M",
        .description        = s"SS_44MDESC",
        .icon               = s"graphics/Menu/Shop/44MSLoader.png",
        .inventoryName      = s"S7_44MCartridges",

        .itemType           = IT_BuySellItem,
        .next               = &bulletAmmoItems [4],

        .maxAmount          = 6,
        .buyPrice           = 150,
        .buyAmount          = 6,
        .sellPrice          = 75,
        .sellAmount         = 6,
        .buyCallback        = &SS_BuyItem,
        .sellCallback       = &SS_SellItem,
        .maxAmountCallback  = &SS_AmmoMaxAmount,
    },
    {
        .name               = s"762X39",
        .description        = s"SS_762X39DESC",
        .icon               = s"graphics/Menu/Shop/762Mag.png",
        .inventoryName      = s"S7_762x39Cartridges",

        .itemType           = IT_BuySellItem,
        .next               = &bulletAmmoItems [5],

        .maxAmount          = 35,
        .buyPrice           = 613,
        .buyAmount          = 35,
        .sellPrice          = 307,
        .sellAmount         = 35,
        .buyCallback        = &SS_BuyItem,
        .sellCallback       = &SS_SellItem,
        .maxAmountCallback  = &SS_AmmoMaxAmount,
    },
    {
        .name               = s"20GA",
        .description        = s"SS_20GADESC",
        .icon               = s"graphics/Menu/Shop/20gaBox.png",
        .inventoryName      = s"S7_20gaShells",

        .itemType           = IT_BuySellItem,
        .next               = NULL,

        .maxAmount          = 10,
        .buyPrice           = 200,
        .buyAmount          = 10,
        .sellPrice          = 100,
        .sellAmount         = 10,
        .buyCallback        = &SS_BuyItem,
        .sellCallback       = &SS_SellItem,
        .maxAmountCallback  = &SS_AmmoMaxAmount,
    },
};

static SS_Page_t bulletAmmo = {
    .name       = s"SS_BULLETS",
    .items      = &bulletAmmoItems [0],
};

#endif
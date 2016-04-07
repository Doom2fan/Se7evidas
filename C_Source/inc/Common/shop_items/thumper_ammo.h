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

#ifndef SSI_THUMPER_AMMO_H
#define SSI_THUMPER_AMMO_H

#include <ACS_ZDoom.h>
#include "shop.h"
#include "../shop_process.h"
#include "externs.h"
#include "ammo.h"
#include "thumper.h"

// Prototypes
int SS_TH_BuyItem  (PlayerData_t *player, SS_Item_t *item);
int SS_TH_SellItem (PlayerData_t *player, SS_Item_t *item);

// Items
SS_Item_t thumperAmmoItems [] = {
    {
        .name               = s"SS_BACK",
        .icon               = SS_BACKICON,
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &ammo,
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

SS_Page_t thumperAmmo = {
    .name       = s"SS_THGRENADES",
    .items      = &thumperAmmoItems [0],
};

#endif
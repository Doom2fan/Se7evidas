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

SS_Item_t ammoItems [] = {
    {
        .name               = s"SS_BACK",
        .icon               = SS_BACKICON,
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &mainSP,
        .next               = &ammoItems [1],
    },
    {
        .name               = s"SS_BULLETS",
        .icon               = s"SSTBULAM",
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &bulletAmmoSP,
        .next               = &ammoItems [2],
    },
    {
        .name               = s"SS_BATTERIESLINK",
        .icon               = s"SSTBATAM",
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &batteriesAmmoSP,
        .next               = &ammoItems [3],
    },
    {
        .name               = s"SS_THGRENADES",
        .icon               = s"SSTTHGAM",
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &thumperAmmoSP,
        .next               = NULL,
    },

};

SS_Page_t ammoSP = {
    .name       = s"SS_AMMO",
    .items      = &ammoItems [0],
};
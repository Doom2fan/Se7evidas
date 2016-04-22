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
#include "shop_process.h"
#include "shop_items/externs.h"

/*SS_Item_t weaponsItems [] = {
    {
        .name               = s"SS_BACK",
        .icon               = SS_BACKICON,
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &mainSP,
        .next               = &weaponsItems [1],
    },
    {
        .name               = s"",
        .icon               = s"",
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &,
        .next               = &weaponsItems [2],
    },
};*/

SS_Page_t weaponsSP = {
    .name       = s"SS_WEAPONS",
    //.items      = &weaponsItems [0],
};
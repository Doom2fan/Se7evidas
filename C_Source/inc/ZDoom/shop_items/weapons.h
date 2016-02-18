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

#ifndef SSI_WEAPONS_H
#define SSI_WEAPONS_H

#include <ACS_ZDoom.h>
#include "../shop_process.h"
#include "externs.h"

/*SS_Item_t weaponsItems [] = {
    {
        .name               = s"SS_BACK",
        .icon               = SS_BACKICON,
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &main,
        .next               = &weaponsItems [1],
    },
    {
        .name               = s"",
        .icon               = s"graphics/Menu/Shop/Weapons/.png",
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &,
        .next               = &weaponsItems [2],
    },
};*/

SS_Page_t weapons = {
    .name       = s"SS_WEAPONS",
    //.items      = &weaponsItems [0],
};

#endif
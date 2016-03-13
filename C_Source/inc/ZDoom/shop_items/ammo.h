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

#ifndef SSI_AMMO_H
#define SSI_AMMO_H

#include <ACS_ZDoom.h>
#include "../shop_process.h"
#include "externs.h"
#include "main.h"
#include "bullet_ammo.h"
#include "batteries_ammo.h"
#include "thumper_ammo.h"

SS_Item_t ammoItems [] = {
    {
        .name               = s"SS_BACK",
        .icon               = SS_BACKICON,
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &main,
        .next               = &ammoItems [1],
    },
    {
        .name               = s"SS_BULLETS",
        .icon               = s"graphics/Menu/Shop/CartShells.png",
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &bulletAmmo,
        .next               = &ammoItems [2],
    },
    {
        .name               = s"SS_BATTERIESLINK",
        .icon               = s"graphics/Menu/Shop/Batteries.png",
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &batteriesAmmo,
        .next               = &ammoItems [3],
    },
    {
        .name               = s"SS_THGRENADES",
        .icon               = s"graphics/Menu/Shop/ThumperAmmo.png",
        .itemType           = IT_PageLink,
        .linkType           = LT_Always,
        .link               = &thumperAmmo,
        .next               = NULL,
    },
    
};

SS_Page_t ammo = {
    .name       = s"SS_AMMO",
    .items      = &ammoItems [0],
};

#endif
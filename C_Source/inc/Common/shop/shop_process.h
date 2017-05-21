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

#ifndef SHOP_PROCESS_H
#define SHOP_PROCESS_H

#include <ACS_ZDoom.h>

// Defines
#define SS_ONMOVEDELAY 7

// Prototypes
int  SS_AmmoMaxAmount (PlayerData_t *player, SS_Item_t *item);
int  SS_BuyItem       (PlayerData_t *player, SS_Item_t *item);
int  SS_SellItem      (PlayerData_t *player, SS_Item_t *item);
int  SS_OpenPage      (PlayerData_t *player, SS_Page_t *page, int flags);
int  SS_OpenShop      (PlayerData_t *player, SS_Shop_t *shop, int flags);
void SS_ProcessToggle (PlayerData_t *player);
void SS_Movement      (PlayerData_t *player);

#endif
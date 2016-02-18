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

#ifndef SHOP_H
#define SHOP_H

#include <ACS_ZDoom.h>

// Defines
#define SS_SELLMODEKEY BT_CROUCH
#define SS_BACKICON s"M_BACK_D"

// Typedefs
typedef enum SS_ItemType {
    IT_PageLink             = 1,
    IT_BuyItem              = 1 <<  1,
    IT_SellItem             = 1 <<  2,
    IT_BuySellItem          = IT_BuyItem | IT_SellItem,
} SS_ItemType;

typedef enum SS_LinkType {
    LT_Always               = 1,
    LT_OnFailure            = 1 <<  1,
    LT_OnSuccess            = 1 <<  2,
} SS_LinkType;

enum SS_BuyCode {
    BC_Success              =   0,
    BC_NotEnoughMoney       =   1,
    BC_InventoryFull        =   2,
    BC_InvalidItem          = 253,
    BC_InvalidPlayer        = 254,
    BC_Unknown              = 255,
};

enum SS_SellCode {
    SC_Success              =   0,
    SC_NotEnoughOfItem      =   1,
    SC_TooMuchMoney         =   2, // Should be very, VERY hard to get, since the maximum amount of cash is 0x7FFFFFFF...
    SC_InvalidItem          = 253,
    SC_InvalidPlayer        = 254,
    SC_Unknown              = 255,
};

enum SS_OpenXFlags {
    OXF_ForceShop           = 1,
    OXF_ForceOther          = 1 << 1,
    OXF_ForceAll            = OXF_ForceShop | OXF_ForceOther,
    OXF_DisableShop         = 1 << 2,
    OSF_NoPage              = 1 << 3,
};

enum SS_OpenXCode {
    OXC_Success             =   0,
    OXC_AlreadyOpen         =   1,
    OXC_ShopOpen            =   2,
    OXC_OtherOpen           =   3,
    OXC_Invalid             =   4,
    OXC_Unknown             = 255,
};

// Structs
struct SS_Item_t {
    string name;
    string description;
    string icon;
    string inventoryName;
    SS_ItemType itemType;
    SS_LinkType linkType;
    SS_Page_t *link;
    SS_Item_t *next;
    int maxAmount;
    int (*maxAmountCallback) (PlayerData_t *player, SS_Item_t *item);
    int buyPrice;
    int buyAmount;
    int (*buyCallback)  (PlayerData_t *player, SS_Item_t *item);
    int sellPrice;
    int sellAmount;
    int (*sellCallback) (PlayerData_t *player, SS_Item_t *item);
};

struct SS_Page_t {
    string name;
    SS_Item_t *items;
    void (*renderer) (PlayerData_t *player);
};

struct SS_Shop_t {
    string name;
    SS_Page_t *mainPage;
    void (*renderer) (PlayerData_t *player);
};

// Prototypes
void ShopSystem_Script (PlayerData_t *player);

#endif
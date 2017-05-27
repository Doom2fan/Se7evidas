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

#ifndef PLAYERMENU_H
#define PLAYERMENU_H

#include <ACS_ZDoom.h>
#include "includes.h"

// Macros
#define PM_TOGGLEMENUTOKEN s"S7_ToggleMenuToken"
#define PM_MenuDisabled(p) (p->shopDef.open || p->playerMenu.disable)

// Typedefs
typedef enum PM_ItemType_t PM_ItemType;
typedef enum PM_ItemState_t PM_ItemState;
typedef struct PM_Icon_t PM_Icon;
typedef struct PM_Item_t PM_Item;
typedef struct PM_Page_t PM_Page;

// Enums
enum PM_ItemType_t {
    PM_ListEnd = -1,
    PM_Label = 0,
    PM_Link,
    PM_Use,
};

enum PM_ItemState_t {
    PMS_Disabled = 1,
    PMS_Selected = 1 << 1,
    PMS_Clicked  = 1 << 2,
};

enum {
    PM_OnMoveDelay = 7,
    PM_MoveSpeedTol = 4,
    PM_MoveSpeedMax = 6,
    PM_MoveSpeedTotal = PM_MoveSpeedTol + PM_MoveSpeedMax,
};

// Structs
struct PM_Icon_t {
    vec2_k offsets; // XY offsets
    string image;
};

struct PM_Item_t {
    PM_ItemType type;
    // Shared stuff
    int id;
    vec2_k pos;
    PM_Icon icon;
    PM_Icon (*iconCallback) (PlayerData_t *player, PM_Item *item, PM_ItemState state); // If set, overrides the icon variable
    string font;
    string text;
    string (*textCallback) (PlayerData_t *player, PM_Item *item, PM_ItemState state); // If set, overrides the text variable
    bool (*visibleCallback) (PlayerData_t *player, PM_Item *item); // If NULL, defaults to TRUE
    bool (*enabledCallback) (PlayerData_t *player, PM_Item *item); // If NULL, defaults to TRUE
    int nextId, prevId;
    // Link
    PM_Page *dest;
    // Use
    void (*useCallback) (PlayerData_t *player, PM_Item *item);
    int callbackID;
};

struct PM_Page_t {
    vec2_i hudSize;
    int initialId;
    PM_Item *items;
};

// Menu externs
extern PM_Page PM_MainMenu;
extern PM_Page PM_DerpSubmenu;

// Prototypes
void PlayerMenuScript (PlayerData_t *player);

#endif
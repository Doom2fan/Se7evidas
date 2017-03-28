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

/*
struct PlayerMenu_t {
    bool open, disable;
    int moveDelay, moveSpeed;
    int id, curIdx;

    struct PM_Page_t *page;
};
*/
#include "includes.h"
#include "systems/playerMenu.h"

int PM_FindControlId (PM_Page *page, int id) {
    int i = 0;

    while (page->items [i].id != id) {
        if (page->items [i].type != PM_ListEnd)
            return -1;
        i++;
    }

    return i;
}

void PM_ChangePage (PlayerData_t *player, PM_Page *dest) {
    player->playerMenu.page = dest;
    if (dest != null) {
        player->playerMenu.open = TRUE;
        player->playerMenu.id = dest->initialId;
        player->playerMenu.curIdx = PM_FindControlId (player->playerMenu.page, player->playerMenu.id);
        player->playerMenu.moveDelay = player->playerMenu.moveSpeed = 0;
    } else {
        player->playerMenu.open = FALSE;
        player->playerMenu.id = player->playerMenu.curIdx = player->playerMenu.moveDelay = player->playerMenu.moveSpeed = 0;
    }
}

void PM_ProcessToggle (PlayerData_t *player) {
    if (!PM_MenuDisabled (player) && !player->playerMenu.open && KeyPressed (BT_USER4)) {
        PM_ChangePage (player, &PM_MainMenu);
        player->playerMenu.open = TRUE;
        player->SprintDef.disable = TRUE;
        SetPlayerProperty (FALSE, ON, PROP_TOTALLYFROZEN);
    } else if (player->playerMenu.open && KeyPressed (BT_USER4)) {
        PM_ChangePage (player, NULL);
        player->playerMenu.open = FALSE;
        player->SprintDef.disable = FALSE;
        SetPlayerProperty (FALSE, OFF, PROP_TOTALLYFROZEN);
    }
}

enum {
    PM_OnMoveDelay = 7,
    PM_MoveSpeedTol = 6,
    PM_MoveSpeedMax = 4,
    PM_MoveSpeedTotal = PM_MoveSpeedTol + PM_MoveSpeedMax,
};
void PM_ProcessMovement (PlayerData_t *player) {
    accum move = GetPlayerInput (-1, INPUT_FORWARDMOVE);
    PM_Page page = player->playerMenu.page;
    if (move != 0 && page != NULL) {
        bool dir = (move > 0) ? TRUE : FALSE; // TRUE = up

        if (dir) {
            if (player->playerMenu.curIdx >= 0) {

            } else {
                player->playerMenu.curIdx = PM_FindControlId (player->playerMenu.page, player->playerMenu.id);
            }
        }
    }
        } if (GetPlayerInput (-1, INPUT_FORWARDMOVE) > 0 && (player->shopDef.items [player->shopDef.position.y - 1]) != NULL && player->shopDef.position.y - 1 >= 0) { // If the player has positive > 0 movement on the forward/backwards axis and the item isn't NULL...
            player->shopDef.position.y--; // Increment y
            player->shopDef.moveDelay = ONMOVEDELAY; // Set the movement delay/cooldown to ONMOVEDELAY
        } else if (GetPlayerInput (-1, INPUT_FORWARDMOVE) < 0 && (player->shopDef.items [player->shopDef.position.y + 1]) != NULL && player->shopDef.position.y + 1 < SS_ITEMSMAX) { // If the player has negative < 0 movement on the forward/backwards axis and the item isn't NULL...
            player->shopDef.position.y++; // Decrement y
            player->shopDef.moveDelay = ONMOVEDELAY; // Set the movement delay/cooldown to ONMOVEDELAY
        }
}

void PM_ProcessUse (PlayerData_t *player) {

}

void PM_Render (PlayerData_t *player) {

}

void PlayerMenuScript (PlayerData_t *player) {
    PM_ProcessToggle (player);
    if (player->playerMenu.open) {
        PM_ProcessMovement (player);
        PM_ProcessUse (player);
        PM_Render (player);
    }
}
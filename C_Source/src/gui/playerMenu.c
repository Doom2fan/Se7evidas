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
    bool open, disable, pause;
    int moveDelay, moveSpeed;
    int id, curIdx;

    struct PM_Page_t *page;
};
*/
#include "includes.h"
#include "shop/shop.h"
#include "gui/playerMenu.h"

#define PMENUBASEID 15000

int PM_FindControlId (PM_Page *page, int id) {
    if (id < 0) // Control ids lower than 0 are not allowed, so skip the search.
        return -1;

    int i = 0;

    while (page->items [i].id != id) {
        if (page->items [i].type == PM_ListEnd)
            return -1;
        i++;
    }

    return i;
}

bool PM_ChangePage (PlayerData_t *player, PM_Page *dest) {
    PM_Page *oldPage = player->playerMenu.page;
    player->playerMenu.page = dest;
    if (dest != NULL) {
        int curIdx = PM_FindControlId (dest, dest->initialId);
        if (curIdx < 0) {
            player->playerMenu.page = oldPage;
            return FALSE;
        }
        player->playerMenu.open = TRUE;
        player->playerMenu.id = dest->initialId;
        player->playerMenu.curIdx = curIdx;
        player->playerMenu.moveDelay = player->playerMenu.moveSpeed = 0;

        for (int i = 0; i < 1000; i++)
            ClearMessage (PMENUBASEID + i);

        return TRUE;
    } else {
        player->playerMenu.open = FALSE;
        player->playerMenu.id = player->playerMenu.curIdx = player->playerMenu.moveDelay = player->playerMenu.moveSpeed = 0;
        
        for (int i = 0; i < 1000; i++)
            ClearMessage (PMENUBASEID + i);

        return TRUE;
    }
}

void PM_ProcessToggle (PlayerData_t *player) {
    if (player->health.health > 0 && player->playerMenu.moveDelay <= 0) {
        if (!PM_MenuDisabled (player) && !player->playerMenu.open && KeyPressed (BT_USER4)) {
            if (player->shopDef.open) {
                SS_OpenPage (player, NULL, OXF_ForceAll); // Change the page to NULL
                player->shopDef.sellMode = FALSE; // Set sellMode to FALSE
            }

            if (PM_ChangePage (player, &PM_MainMenu)) {
                player->SprintDef.disable = TRUE;
                SetPlayerProperty (FALSE, ON, PROP_TOTALLYFROZEN);
                player->playerMenu.moveDelay = PM_OnMoveDelay;
            } else {
                DebugLog ("\CgFunction PM_ProcessToggle: Fatal error: Main menu is invalid");
                return;
            }
        } else if (player->playerMenu.open && !player->playerMenu.pause && KeyPressed (BT_USER4)) {
            PM_ChangePage (player, NULL);
            player->SprintDef.disable = FALSE;
            SetPlayerProperty (FALSE, OFF, PROP_TOTALLYFROZEN);
            player->playerMenu.moveDelay = PM_OnMoveDelay;
        }
    }
}

void PM_ProcessMovement (PlayerData_t *player) {
    if (player->playerMenu.pause)
        return;

    accum move = GetPlayerInput (-1, INPUT_FORWARDMOVE);
    PM_Page *page = player->playerMenu.page;
    if (page != NULL && move != 0 && player->playerMenu.moveDelay <= 0) {
        bool dir = (move > 0) ? TRUE : FALSE; // TRUE = up
        int newId, newIdx;

        if (player->playerMenu.id >= 0 && player->playerMenu.curIdx < 0) {
            player->playerMenu.curIdx = PM_FindControlId (player->playerMenu.page, player->playerMenu.id);
            if (player->playerMenu.curIdx < 0)
                return;
        }

        int curIdx = player->playerMenu.curIdx;
        newId = dir ? (page->items [curIdx].prevId) : (page->items [curIdx].nextId);
        newIdx = PM_FindControlId (page, newId);

        if (newIdx < 0)
            return;

        player->playerMenu.id = newId;
        player->playerMenu.curIdx = newIdx;
        if (player->playerMenu.moveDelay == -1 || (player->playerMenu.moveSpeed > 0 && dir) || (player->playerMenu.moveSpeed < 0 && !dir)) {
            player->playerMenu.moveDelay = PM_OnMoveDelay;
            player->playerMenu.moveSpeed = 0;
        } else {
            player->playerMenu.moveDelay = (abs (player->playerMenu.moveSpeed) > PM_MoveSpeedTol) ? (PM_OnMoveDelay - (abs (player->playerMenu.moveSpeed) - PM_MoveSpeedTol)) : PM_OnMoveDelay;
            player->playerMenu.moveSpeed += dir ? -1 : 1;

            if (abs (player->playerMenu.moveSpeed) > PM_MoveSpeedTotal)
                player->playerMenu.moveSpeed = (player->playerMenu.moveSpeed > 0) ? PM_MoveSpeedTotal : -PM_MoveSpeedTotal;
        }
    }

    if (player->playerMenu.moveDelay > -1)
        player->playerMenu.moveDelay--;
    else if (player->playerMenu.moveDelay < -1)
        player->playerMenu.moveDelay = -1;
}

void PM_ProcessUse (PlayerData_t *player) {
    if (player->playerMenu.pause)
        return;

    PM_Page *page = player->playerMenu.page;
    if (page != NULL && KeyPressed (BT_USE) && player->playerMenu.moveDelay <= 0) {
        if (player->playerMenu.id >= 0 && player->playerMenu.curIdx < 0) {
            player->playerMenu.curIdx = PM_FindControlId (player->playerMenu.page, player->playerMenu.id);
            if (player->playerMenu.curIdx < 0)
                return;
        }

        int curIdx = player->playerMenu.curIdx;
        PM_Item *control = &(page->items [curIdx]);
        if (control->enabledCallback != NULL && !control->enabledCallback (player, control))
            return;

        if (control->type == PM_Link) {
            if (!PM_ChangePage (player, control->dest))
                DebugLog ("\CgFunction PM_ProcessUse: Error: Control links to invalid page");
        } else if (control->type == PM_Use) {
            if (control->useCallback != NULL)
                control->useCallback (player, control);
        }

        player->playerMenu.moveDelay = PM_OnMoveDelay;
        player->playerMenu.moveSpeed = 0;
    }
}

void PM_Render (PlayerData_t *player) {
    if (player == NULL || player->playerMenu.page == NULL || player->playerMenu.page->items == NULL)
        return;

    PM_Page *page = player->playerMenu.page;
    PM_Item *control;
    SetHudSize (page->hudSize.x, page->hudSize.y, FALSE);
    int hudmsgID = PMENUBASEID;
    for (int i = 0; page->items [i].type != PM_ListEnd; i++) {
        PM_ItemState state = 0;
        control = &(page->items [i]);

        if (control->visibleCallback != NULL && !control->visibleCallback (player, control))
            continue;

        if (control->enabledCallback != NULL && !control->enabledCallback (player, control))
            state |= PMS_Disabled;

        if (player->playerMenu.id == control->id)
            state |= PMS_Selected;

        // Display text, if set
        if (control->text != NULL || control->textCallback != NULL) {
            string text;
            if (control->textCallback != NULL)
                text = control->textCallback (player, control, 0);
            else if (control->text != NULL)
                text = control->text;

            if (control->font == NULL)
                SetFont (s"FSHUDFNT");
            else
                SetFont (control->font);

            HudMessage (HUDMSG_PLAIN | HUDMSG_LAYER_OVERHUD, hudmsgID++, (state & PMS_Selected ? CR_RED : CR_UNTRANSLATED), control->pos.x, control->pos.y, 0.1k, 0.0k, 0.0k, 0.0k, "%S", text);
        }

        // Display icon, if set
        if (control->icon.image != NULL || control->iconCallback != NULL) {
            vec2_k iconPos;
            iconPos.x = (control->pos.x >> 16) << 16; iconPos.y = (control->pos.y >> 16) << 16;
            PM_Icon icon;

            if (control->iconCallback != NULL)
                icon = control->iconCallback (player, control, 0);
            else if (control->icon.image != NULL)
                icon = control->icon;

            if (icon.image != NULL && StrCmp (icon.image, s"TNT1A0") != 0 && StrCmp (icon.image, s"") != 0) {
                SetFont (icon.image);
                HudMessage (HUDMSG_PLAIN | HUDMSG_LAYER_OVERHUD, hudmsgID++, CR_UNTRANSLATED, iconPos.x + icon.offsets.x, iconPos.y + icon.offsets.y, 0.1k, 0.0k, 0.0k, 0.0k, "A");
            }
        }
    }
    SetHudSize (0, 0, FALSE);
}

void PlayerMenuScript (PlayerData_t *player) {
    PM_ProcessToggle (player);
    
    if (player->health.health <= 0 && (player->playerMenu.open || player->playerMenu.page != NULL)) { // Close the menu if the player died
        PM_ChangePage (player, NULL);
        player->SprintDef.disable = FALSE;
        SetPlayerProperty (FALSE, OFF, PROP_TOTALLYFROZEN);
        player->playerMenu.moveDelay = PM_OnMoveDelay;
    }

    PM_ProcessMovement (player);
    PM_ProcessUse (player);
    PM_Render (player);
}
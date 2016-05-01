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

#ifndef HUD_H
#define HUD_H

#include <ACS_ZDoom.h>

// Structs
typedef struct EIS_Data_t {
    bool forceClear;

    int  prevScreenblocks;
    bool prevOn;
    bool prevDisableHUD;
} EIS_Data_t;

typedef struct SP_Data_t {
    int  prevPopupNum;
    int  prevPageNum;
} SP_Data_t;

// Prototypes
void HudWeapons      (PlayerData_t *player);
void ShowPop         (PlayerData_t *player, SP_Data_t *data);
void EnemyInfoScript (PlayerData_t *player, EIS_Data_t *data);
void ScreenOverlays  (PlayerData_t *player);
void DrawRadar       (PlayerData_t *player);

#endif
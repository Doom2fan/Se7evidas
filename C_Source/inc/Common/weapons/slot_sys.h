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

#ifndef W_SLOT_SYS_H
#define W_SLOT_SYS_H

#include <ACS_ZDoom.h>

void CWeapSlots_BindSlot   (PlayerData_t *player, int slot, int pos, int weap);
void CWeapSlots_Slot       (PlayerData_t *player, int slot, int pos);
void CWeapSlots_WeapCycle  (PlayerData_t *player, bool next);
void CustomWeapSlotsScript (PlayerData_t *player);
Script_C void S7_CWB_Slot NET (int slot, int pos);
Script_C void S7_CWB_SetBind NET (int slot, int pos, int weap);
Script_C void S7_CWB_WeapCycle (bool next);

#endif
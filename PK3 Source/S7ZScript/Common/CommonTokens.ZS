/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

class S7_EvadeNow        : S7_Boolean { } // Usage: A_RadiusGive ("S7_EvadeNow", <distance>, RGF_Monsters, 1)
class S7_IsDead          : S7_Boolean { }
class S7_NotRealMonster  : S7_Boolean { }
class S7_MFireMode       : S7_Counter { default { Inventory.MaxAmount 3; } }
class S7_Weap_ReadyFrame : S7_Counter { }
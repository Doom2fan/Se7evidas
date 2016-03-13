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

#include "includes.h"
#include "monster_stuff.h"

Script_C void S7_EmpressScript () {
    if (!CheckInventory (EMPIDENT))
        return;

    int invulnDelay,
        ballsCount,
        newHealth, health;

    newHealth = GetActorProperty (0, APROP_Health);
    health = EMPMHEALTH;
    while (TRUE) {
        ballsCount = CheckInventory (s"S7_EmpressBalls");
        health += -(0x7FFFFFFF - newHealth);

        if (health > EMPINVLIMIT || ballsCount > 0) {
            SetInventory (EMPINVTOKEN, FALSE);
            if (ballsCount > 0)
                invulnDelay = EMPINVDELAY;
        } else if (invulnDelay) {
            SetInventory (EMPINVTOKEN, FALSE);
            invulnDelay--;
        } else if (health <= EMPINVLIMIT && ballsCount < 1 && invulnDelay < 1)
            SetInventory (EMPINVTOKEN, TRUE);

        SetUserVariable (0, EMPHPVAR, health);

        Delay (1);

        if (!CheckInventory (ISDEADTOKEN)) {
            newHealth = GetActorProperty (0, APROP_Health);
            SetActorProperty (0, APROP_Health, 0x7FFFFFFF);
        } else {
            newHealth = 0x7FFFFFFF;

            if (GetActorProperty (0, APROP_Health) > 0) {
                SetActorProperty (0, APROP_Health, 0x7FFFFFFF);
            }
        }
    }
}
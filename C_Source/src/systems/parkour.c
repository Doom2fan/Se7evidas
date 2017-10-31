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

#include "includes.h"
#include "weapons/weapon_stuff.h"
#include "systems/stamina.h"
#include "systems/parkour.h"

int sign (int x) {
    if (x < 0) { return -1; }
    return 1;
}

// Some code taken from Parkmore by Ijon Tichy
#define WJUMPDELAY 5
void WallJumpScript (PlayerData_t *player) {
    if (!player)
        return;

    if (player->parkourDef.wjumpJustJumped)
        player->parkourDef.wjumpJustJumped--;

    if (player->health.health > 0 && !player->scriptData.beamGrab && !player->parkourDef.wjumpJustJumped && GetPlayerInputFixed (-1, MODINPUT_FORWARDMOVE) < 0 && KeyPressedMOD (BT_JUMP) && player->physics.relativeZ > 24.0k) {
        bool canBounce;
        int j;
        accum x = 20 * CosA (player->physics.angle), y = 20 * SinA (player->physics.angle);
        accum x2 = 8 * CosA (player->physics.angle), y2 = 8 * SinA (player->physics.angle);
        accum x3, y3, z;

        /*if (AbsA (x) > AbsA (y)) {
            y = y * (20.0k / AbsA (x));
            x = 20.0k * sign (x);
        } else {
            x = x * (20.0k / AbsA (y));
            y = 20.0k * sign (y);
        }*/

        for (int i = 0; i < 10; i++) {
            x3 = player->physics.x + x + (x2 * i);
            y3 = player->physics.y + y + (y2 * i);
            z  = player->physics.z + 16.0k;

            j = Spawn (s"S7_WallChecker", x3, y3, z, 0); // -500);
            if (!j) {
                int byteAngle = (player->physics.angle << 16) >> 8;
                player->parkourDef.wjumpJustJumped = WJUMPDELAY;
                ThrustThing (byteAngle + 128, 18, 1, 0);
                ThrustThingZ (0, 40.0k, 0, 0);
                ChangeActorAngle (0, player->physics.angle + 0.5k, TRUE);
                break;
            }
        }
    }
}

void CancelWallHold (PlayerData_t *player) {
    if (!player)
        return;

    Log ("FUCK");
    SetActorPropertyFixed (0, APROP_Gravity, 1.0k);
    SetPlayerProperty (FALSE, PROP_FROZEN, FALSE);
    player->parkourDef.wGrabHolding = FALSE;
}
void WallHoldScript (PlayerData_t *player) {
    if (!player)
        return;

    if (player->health.health > 0 && !player->scriptData.beamGrab && !player->parkourDef.wGrabHolding && KeyPressedMOD (BT_CROUCH) && player->physics.relativeZ > 4k) {
        int j;
        accum x = 20 * CosA (player->physics.angle), y = 20 * SinA (player->physics.angle);
        accum x2 = 8 * CosA (player->physics.angle), y2 = 8 * SinA (player->physics.angle);
        accum x3, y3, z;

        for (int i = 0; i < 10; i++) {
            x3 = player->physics.x + x + (x2 * i);
            y3 = player->physics.y + y + (y2 * i);
            z  = player->physics.z + 16.0k;

            j = Spawn (s"S7_WallChecker", x3, y3, z, 0); // -500);
            if (!j) {
                // Set values
                player->parkourDef.wGrabHolding = TRUE;
                player->parkourDef.wGrabHoldi = i;
                player->parkourDef.wGrabOldGravity = GetActorPropertyFixed (0, APROP_Gravity);
                player->parkourDef.wGrabHoldAngle = player->physics.angle;
                player->parkourDef.wGrabOldCoords.x = player->physics.x;
                player->parkourDef.wGrabOldCoords.y = player->physics.y;

                SetPlayerProperty (FALSE, PROP_FROZEN, TRUE);
                SetActorPropertyFixed (0, APROP_Gravity, 0.0k);
                SetActorVelocity (0, 0.0k, 0.0k, 0.0k, FALSE, FALSE);
                break;
            }
        }
    }

    if (player->parkourDef.wGrabHolding) {
        accum maxLeft  = player->parkourDef.wGrabHoldAngle - 0.25k, maxRight = player->parkourDef.wGrabHoldAngle + 0.25k,
              x = player->physics.x + 20 * CosA (player->physics.angle) + (8 * CosA (player->physics.angle) * player->parkourDef.wGrabHoldi),
              y = player->physics.y + 20 * SinA (player->physics.angle) + (8 * SinA (player->physics.angle) * player->parkourDef.wGrabHoldi),
              z  = player->physics.z + 16.0k;
        bool  facingWall = (player->physics.angle > maxLeft && player->physics.angle < maxRight);

        SetActorPosition (0, player->parkourDef.wGrabOldCoords.x, player->parkourDef.wGrabOldCoords.y, player->physics.z, FALSE);
        SetActorVelocity (0, 0.0k, 0.0k, -0.2k, FALSE, FALSE);

        if (!player->parkourDef.wjumpJustJumped) {
            if (KeyPressedMOD (BT_JUMP)) {
                CancelWallHold (player);
                int byteAngle = (player->parkourDef.wGrabHoldAngle << 16) >> 8;
                player->parkourDef.wjumpJustJumped = WJUMPDELAY;
                ThrustThing (byteAngle + 128, 18, 1, 0);
                ThrustThingZ (0, 40.0k, 0, 0);
                ChangeActorAngle (0, player->parkourDef.wGrabHoldAngle + 0.5k, TRUE);
            } else if ((facingWall && GetPlayerInputFixed (-1, MODINPUT_FORWARDMOVE) < 0) || (!facingWall && GetPlayerInputFixed (-1, MODINPUT_FORWARDMOVE) > 0)) {
                bool dirFW = (facingWall && GetPlayerInputFixed (-1, MODINPUT_FORWARDMOVE) < 0);
                CancelWallHold (player);
                int byteAngle = (player->physics.angle << 16) >> 8;
                player->parkourDef.wjumpJustJumped = WJUMPDELAY;
                ThrustThing (dirFW ? byteAngle + 128 : byteAngle, 18, 1, 0);
            }
        }

        if (Spawn (s"S7_WallChecker", x, y, z, 0) || player->health.health <= 0 || player->scriptData.beamGrab || player->physics.relativeZ < 4k || (facingWall && GetPlayerInputFixed (-1, MODINPUT_FORWARDMOVE) > 0) || (!facingWall && GetPlayerInputFixed (-1, MODINPUT_FORWARDMOVE) < 0))
            CancelWallHold (player);
    }
}
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
#include "weapon_stuff.h"
#include "stamina.h"
#include "parkour.h"

#define DODGESTAMINA 30
void DodgeScriptP1 (PlayerData_t *player) { // player->staminaEmpty = 1;
    if (player->parkourDef.dodgeCooldown <= 0) { // If dodgeCooldown is less than or equal to 0...
        if (player->parkourDef.dodgeCooldown < 0) // If dodgeCooldown is less than 0...
            player->parkourDef.dodgeCooldown = 0; // Set dodgeCooldown to 0

        // If the player is trying to move backwards, tapped user4, isn't sprinting and has at least DODGESTAMINA stamina...
        if ((GetPlayerInput (-1, INPUT_FORWARDMOVE) < 0) && (KeyPressed (BT_USER4)) && !(player->SprintDef.Sprinting) && (player->stamina >= DODGESTAMINA)) {
            TakeInventory (s"S7_Stamina", DODGESTAMINA); // Take DODGESTAMINA stamina
            player->stamina = CheckInventory (s"S7_Stamina"); // Update player data
            ActivatorSound (s"Player/Dodge", 127); // Play the dodge sound
            int byteAngle = (player->angle << 16) >> 8; // For some reason I have to do this weird shit. I have no idea why. Go ask DavidPH.
            ThrustThing (byteAngle + 128, 18, 1, 0); // Thrust the player backwards
            ThrustThingZ (0, 32, 0, TRUE); // Thrust the player up
            player->parkourDef.dodgeCooldown = ServerData.dodgeCooldown; // Set the dodgeCooldown to 1 second
        }
    }
}

void DodgeScriptP2 (PlayerData_t *player) {
    if (player->parkourDef.dodgeCooldown > 0) { // If dodgeCooldown is greater than 0...
        player->parkourDef.dodgeCooldown--; // Decrement dodgeCooldown by 1
    }
}

void MultiJumpScript (PlayerData_t *player) {
    accum force = 40.0k * ServerData.mjumpZMul;
    if (player->relativeZ == 0) { // If the player is on the ground...
        player->parkourDef.mjumpOnGround = TRUE; // Set mjumpOnGround to TRUE
        if (player->parkourDef.mjumpCount > 0) // If the player has multijumped at least once...
            player->parkourDef.mjumpCount = 0; // Reset the counter to 0
    } else { // If not...
        player->parkourDef.mjumpOnGround = FALSE; // Set mjumpOnGround to FALSE
    }

    // If the player's Z velocity is lower than or equal to 32, the player is not on the ground, the player's multijump counter isn't equal to their multijump max, the player pressed
    // jump and the sv_nojump CVAR isn't TRUE...
    if (player->velZ <= 32 && !player->parkourDef.mjumpOnGround && player->parkourDef.mjumpCount < player->parkourDef.mjumpMax && KeyPressed (BT_JUMP) && !GetCVar (s"sv_nojump")) {
        SpawnForced (s"S7_MultiJump_Marker", player->x, player->y, player->z, 0, player->angle); // Spawn a multijump marker
        ThrustThingZ (0, force, 0, FALSE); // Thrust the player up
        player->parkourDef.mjumpCount++; // Increment the jump counter by 1
    }
}
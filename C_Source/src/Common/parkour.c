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
void DodgeScriptP1 (PlayerData_t *player) {
    if (!player)
        return;

    if (player->parkourDef.dodgeInvulnTics > 0) {
        (player->parkourDef.dodgeInvulnTics)--;
        SetInventory (DODGEINVULITEM, 1);
        SetInventory (DODGETRAILITEM, 1);
    } else {
        SetInventory (DODGEINVULITEM, 0);
        SetInventory (DODGETRAILITEM, 0);
    }

    if (player->parkourDef.dodgeCooldown <= 0) { // If dodgeCooldown is less than or equal to 0...
        if (player->parkourDef.dodgeCooldown < 0) // If dodgeCooldown is less than 0...
            player->parkourDef.dodgeCooldown = 0; // Set dodgeCooldown to 0

        // If the player tapped user2, isn't sprinting, didn't have his Soul Lance beam grabbed and has at least DODGESTAMINA stamina...
        if (KeyPressed (BT_USER2) && !player->SprintDef.Sprinting && !player->scriptData.beamGrab && player->health.stamina >= DODGESTAMINA) {
            if ((GetPlayerInput (-1, INPUT_FORWARDMOVE) < 0) || (GetPlayerInput (-1, INPUT_SIDEMOVE) != 0)) { // If the player is trying to move backwards or sideways...
                TakeInventory (STAMINATOKEN, DODGESTAMINA); // Take DODGESTAMINA stamina
                player->health.stamina = CheckInventory (STAMINATOKEN); // Update player data

                ActivatorSound (s"Player/Dodge", 127); // Play the dodge sound

                int byteAngle = (player->physics.angle << 16) >> 8; // For some reason I have to do this weird shit. I have no idea why. Go ask DavidPH.
                if (GetPlayerInput (-1, INPUT_FORWARDMOVE) < 0) // If the player is trying to move backwards...
                    ThrustThing (byteAngle + 128, 18, 1, 0); // Thrust the player backwards
                else if (GetPlayerInput (-1, INPUT_SIDEMOVE) < 0) // If the player is trying to move left...
                    ThrustThing (byteAngle + 64, 18, 1, 0); // Thrust the player left
                else if (GetPlayerInput (-1, INPUT_SIDEMOVE) > 0) // If the player is trying to move right...
                    ThrustThing (byteAngle + 192, 18, 1, 0); // Thrust the player right

                ThrustThingZ (0, 32, 0, TRUE); // Thrust the player up

                player->parkourDef.dodgeCooldown = ServerData.dodgeCooldown; // Set the dodgeCooldown to 1 second
                player->parkourDef.dodgeInvulnTics = 24; // Set the invuln tics to 16
            }
        }
    }
}

void DodgeScriptP2 (PlayerData_t *player) {
    if (!player)
        return;

    if (player->parkourDef.dodgeCooldown > 0) { // If dodgeCooldown is greater than 0...
        player->parkourDef.dodgeCooldown--; // Decrement dodgeCooldown by 1
    }
}

#define MJUMPMINDIFF 15
void MultiJumpScript (PlayerData_t *player) {
    if (!player)
        return;

    int mJumpMax = player->scriptData.beamGrab ? player->parkourDef.mjumpMax / 2 : player->parkourDef.mjumpMax;
    if (mJumpMax < 1)
        mJumpMax = 1;

    accum force = 40.0k * ServerData.mjumpZMul;
    if (player->physics.relativeZ == 0) { // If the player is on the ground...
        player->parkourDef.mjumpOnGround = TRUE; // Set mjumpOnGround to TRUE
        if (player->parkourDef.mjumpCount > 0) // If the player has multijumped at least once...
            player->parkourDef.mjumpCount = 0; // Reset the counter to 0
    } else { // If not...
        player->parkourDef.mjumpOnGround = FALSE; // Set mjumpOnGround to FALSE
    }

    // If the player's floor-relative Z is greater than MJUMPMINDIFF, the player's Z velocity is lower than or equal to 32, the player is not on the ground, the player's multijump
    // counter isn't equal to mJumpMax, the player pressed jump and the sv_nojump CVAR isn't TRUE...
    if (abs (player->physics.relativeZ) >= MJUMPMINDIFF && player->physics.velZ <= 32 && !player->parkourDef.mjumpOnGround && player->parkourDef.mjumpCount < mJumpMax && KeyPressed (BT_JUMP) && !GetCVar (s"sv_nojump")) {
        SpawnForced (s"S7_MultiJump_Marker", player->physics.x, player->physics.y, player->physics.z, 0, player->physics.angle); // Spawn a multijump marker
        ThrustThingZ (0, force, 0, FALSE); // Thrust the player up
        player->parkourDef.mjumpCount++; // Increment the jump counter by 1
    }
}
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
#include "health.h"
#include "HUD.h"
#include "misc.h"
#include "sprint_system.h"

Script_C void S7_Enter ENTER (void) {
    ACS_SetActorPropertyFixed (0, APROP_Speed, 1.0k);
    //S7_SR_StaminaEmpty [PLN] = 0;
}

Script_C void S7_Respawn RESPAWN (void) {
    ACS_SetActorPropertyFixed (0, APROP_Speed, 6.0k);
    //S7_SR_StaminaEmpty [PLN] = 0;
}

Script_C int S7_RunningInZDoom (void) {
    return 1;
}

/*static bool dead = false;

* this can also be written like any of the following:
 * script_c void mainLoop ENTER (void)
 * void mainLoop script_c ENTER (void)
 * ENTER void mainLoop script_c (void)
 *
Script_C ENTER void mainLoop (void) {
    int renderStyle = 5;
    unsigned int renderColor = 0xFF;

    ACS_ChangeSky (s"SKY3", s"SKY3");  ACS uses s-prefixed strings 

    for (accum i = 0; ; i += 0.1k) {
            accum sin = SinA (i / 60.0k);

            ++renderStyle > 6 ? (renderStyle = 5) : (renderStyle = 6);
            renderColor = (int) (sin * 255.0k);
            ACS_SetSkyScrollSpeed (1, ACS_Random (0, 1) == 1 ? sin : -sin);
            ACS_SetSkyScrollSpeed (2, ACS_Random (0, 1) == 1 ? sin : -sin);

            if (!dead) {
                    ACS_SetActorRoll (0, sin);
                }

            ACS_SetActorProperty (0, APROP_RenderStyle, renderStyle);

            ACS_SetActorProperty (0, APROP_StencilColor, renderColor);

            int rngod = ACS_Random (-0xFFFF, 0xFFFF);

            if (rngod <= 0xF && rngod > 0) {
                    ACS_DamageThing (0);

                } else

                if (rngod <= -0xFF) {
                        int rand = ACS_Random (-10, 10);

                        if (ACS_GetActorProperty (0, APROP_Health) > 10 || rand < 0) {
                                ACS_DamageThing (rand == 0 ? 1 : rand);
                            }

                    } else

                    if (rngod >= 0xF7FF) {
                            ACS_LineAttack (0, ACS_GetActorAngle (0), ACS_GetActorPitch (0), 1000);
                        }

            if (rngod <= 0x1800 && rngod > 0x800 && !dead) {
                    ACS_PlaySound (0, s"misc/chat");

                    if (rngod == 0x1800) {
                            // PrintLog (COL_DEFCHAT "%S: This is a great mod.", PlayerName (ACS_PlayerNumber()));
                        }
                }

            ACS_Delay (1);
        }
}

Script_C DEATH void ded (void) {
    accum x = ACS_GetActorX (0), y = ACS_GetActorY (0), z = ACS_GetActorZ (0);
    dead = true;

    for (int i = 0; i < ACS_Random (40, 128); i++) {
            ACS_Spawn (s"Rocket", x, y, z + 16.0k, 100, (accum) ACS_Random (-128, 128));
            ACS_SetActorVelocity (100, ACS_Random (-128, 128), ACS_Random (-128, 128), 0, false, false);
            ACS_Delay (2);
        }

    for (;;) {
            ACS_Spawn (s"MBFHelperDog", x + 10.0k, y + 10.0k, z + 10.0k, 101);
            ACS_SetActorVelocity (101, ACS_Random (-128, 128), ACS_Random (-128, 128), 0, false, false);
            ACS_Thing_Hate (101, 0, 6);
            ACS_PlaySound (0, s"misc/chat2");
            // PrintLog ("REPENT");
            ACS_Delay (1);
        }

}*/
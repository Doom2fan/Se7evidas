#include "util.h"
#include "util_math.h"
#include "sprint_system.h"
#undef ACS_SHORT_NAMES

accum S7_SS_OldSpeed [MAXPLAYERS];
bool S7_SS_Sprinting [MAXPLAYERS];

Script_C void S7_SprintSystem ENTER (void) {
    Start:
    // Not needed or desired in TitleMaps.
    if (ACS_GameType () == GAME_TITLE_MAP)
        return;
    
    int tics = 0;
    while (TRUE) {
        if (ACS_CheckWeapon (s"S7_SprintWeapon") && S7_SS_Sprinting [PLN] == 0) {
            ACS_SetActorPropertyFixed (0, APROP_Speed, S7_SS_OldSpeed [PLN]);
            S7_SS_Sprinting [PLN] = 0;
            tics = 0;
            DisableWeapon (s"S7_SprintWeapon", s"S7_Sprinting");
        }
        if (KeyDown (BT_USER1) &&
            S7_SS_Sprinting [PLN] == 0 &&
            ACS_CheckInventory (s"S7_Stamina") >= 5 && !ACS_CheckInventory (s"S7_Dying") &&
            !S7_SR_StaminaEmpty [PLN]) {
            S7_SS_Sprinting [PLN] = 1;
            S7_SS_OldSpeed [PLN] = ACS_GetActorProperty (0, APROP_Speed);
            DisableWeapon (s"S7_SprintWeapon", s"S7_Sprinting");
        }
        if (keyUp (BT_USER1) && S7_SS_Sprinting [PLN] && !S7_SR_StaminaEmpty [PLN]) {
            ACS_SetActorPropertyFixed (0, APROP_Speed, S7_SS_OldSpeed [PLN]);
            S7_SS_Sprinting [PLN] = 0;
            tics = 0;
            DisableWeapon (s"S7_SprintWeapon", s"S7_Sprinting");
        }
        if (ACS_CheckInventory (s"S7_Sprinting") && S7_SS_Sprinting [PLN]) {
            if (ACS_CheckInventory (s"S7_Stamina") >= 5) {
                if (ACS_CheckInventory (s"S7_Sprinting") && tics >= 5) {
                    tics = 0;
                    if (GetVelocity () > 0)
                        ACS_TakeInventory (s"S7_Stamina", 5);
                }
                if (ACS_CheckInventory (s"S7_Stamina") < 5 || ACS_CheckInventory (s"S7_Dying")) {
                    ACS_SetActorPropertyFixed (0, APROP_Speed, S7_SS_OldSpeed [PLN]);
                    S7_SS_Sprinting [PLN] = 0;
                    S7_SR_StaminaEmpty [PLN] = 1;
                    DisableWeapon (s"S7_SprintWeapon", s"S7_Sprinting");
                    goto Start;
                }
                if (ACS_CheckInventory (s"S7_Sprinting") && ((abs (ACS_GetPlayerInput (-1, INPUT_FORWARDMOVE)) > 6400) || (abs (ACS_GetPlayerInput (-1, INPUT_SIDEMOVE)) > 6400)))
                    ACS_SetActorPropertyFixed (0, APROP_Speed, 3.0k);
                else if (ACS_CheckInventory (s"S7_Sprinting") && !((abs (ACS_GetPlayerInput (-1, INPUT_FORWARDMOVE)) > 6400) || (abs (ACS_GetPlayerInput (-1, INPUT_SIDEMOVE)) > 6400)))
                    ACS_SetActorPropertyFixed (0, APROP_Speed, 6.0k);
                else if (!checkInventory (s"S7_Sprinting"))
                    ACS_SetActorPropertyFixed (0, APROP_Speed, S7_SS_OldSpeed [PLN]);
            }
        }
        
        ACS_Delay (1);
        
        if (S7_SS_Sprinting [PLN])
            tics++;
    }
}
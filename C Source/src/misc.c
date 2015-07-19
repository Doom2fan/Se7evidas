#include "util.h"
#include "util_math.h"
#include "commonFuncs.h"
#include "misc.h"
#undef ACS_SHORT_NAMES

Script_C void S7_SpeedScript ENTER (void) {
    // Not needed or desired in TitleMaps.
    if (ACS_GameType () == GAME_TITLE_MAP)
        return;
    
    int health;
    
    while (true) {
        health = ACS_GetActorProperty (0, APROP_Health);
        
        if (health <= 20)
            ACS_GiveInventory (s"S7_Dying", 9999999);
        else
            ACS_TakeInventory (s"S7_Dying", 9999999);
        
        ACS_Delay(1);
    }
}

Script_C void S7_WaterScript ENTER (void) {
    // Not needed or desired in TitleMaps.
    if (ACS_GameType () == GAME_TITLE_MAP)
        return;
    
    while (true) {
        if (ACS_GetActorProperty(0, APROP_Waterlevel) > 2) // if underwater...
            ACS_GiveInventory (s"S7_IsUnderwater", 1); // give S7_IsUnderwater

        else if (ACS_GetActorProperty(0, APROP_Waterlevel) <= 2) // if not underwater
            ACS_TakeInventory (s"S7_IsUnderwater", 1); // take S7_IsUnderwater
            
        SetInventory (s"S7_AirTime", ACS_GetAirSupply (PLN));
        ACS_Delay (1);
    }
}

Script_C void S7_Keys ENTER (void) {
    // Not needed or desired in TitleMaps.
    if (ACS_GameType () == GAME_TITLE_MAP)
        return;
    
    while (true) {
        if (KeyPressed (BT_RELOAD))
            ACS_UseInventory (s"S7_ReloadKey");
        
        ACS_Delay (1);
    }
}

Script_C void S7_BrutalDoomCompatibility OPEN (void) {
    // Not needed or desired in Titlemaps.
    if (ACS_GameType () == GAME_TITLE_MAP)
        return;
    
    bool ACTIVATE = 0;
    bool tid = UnusedTID (-37000, -47000);
    int delayer = 0;
    
    while (true) {
        if (ACS_Spawn (s"Brutal_Blood", 0.0k, 0.0k, 0.0k, tid) ||
            ACS_Spawn (s"BrutalPistol", 0.0k, 0.0k, 0.0k, tid)) {
            ACS_Thing_Remove (tid);
            ACTIVATE = 1;
        }
        
        if (ACTIVATE) {
            int randomizer = ACS_Random (0, 2);
            int randomizer2 = 0;
            int i = 0;
            int actionCount = 0;
            
            if (delayer == 0) {
                if (randomizer == 0) { // AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
                    delayer = 35 * ACS_Random (10, 20);
                    for (i = 0; i < ACS_Random (5, 30); i++) {
                        ACS_Spawn (s"GETTHATSHITOUTTAHERE", ACS_GetActorX (0) + ACS_RandomFixed (-200.0k, 200.0k), ACS_GetActorY (0) + ACS_RandomFixed (-200.0k, 200.0k), ACS_GetActorZ (0), tid);
                        ACS_Thing_Hate (tid, 0, 2);
                        ACS_Thing_ChangeTID (tid, 0);
                        ACS_NoiseAlert (0, 0);
                    }
                } else if (randomizer == 1) { // Fuck sector colours up
                    delayer = 35 * ACS_Random (10, 20);
                    for (i = 0; i < 32767; i++) {
                        ACS_Sector_SetColor (i, ACS_Random (0, 255), ACS_Random (0, 255), ACS_Random (0, 255), 0);
                        actionCount++;
                        if (actionCount >= 10000) {
                            ACS_Delay (1);
                            actionCount = 0;
                        }
                    }
                } else if (randomizer == 2) { // Fuck flat rotations up
                    delayer = 35 * ACS_Random (10, 20);
                    for (i = 0; i < 32767; i++) {
                        ACS_Sector_SetRotation (i, ACS_Random (0, 356), ACS_Random (0, 356));
                        actionCount++;
                        if (actionCount >= 10000) {
                            ACS_Delay (1);
                            actionCount = 0;
                        }
                    }
                }
                
                if (ACS_GetLevelInfo (LEVELINFO_KILLED_MONSTERS) >= ACS_GetLevelInfo (LEVELINFO_TOTAL_MONSTERS) ||
                    ACS_GetLevelInfo (LEVELINFO_FOUND_SECRETS)   >= ACS_GetLevelInfo (LEVELINFO_TOTAL_SECRETS)  ||
                    ACS_GetLevelInfo (LEVELINFO_FOUND_ITEMS)     >= ACS_GetLevelInfo (LEVELINFO_TOTAL_ITEMS)) {
                    for (i = 0; i < 10; i++) {
                        ACS_Spawn (s"GETTHATSHITOUTTAHERE", ACS_GetActorX (0) + ACS_RandomFixed (-200.0k, 200.0k), ACS_GetActorY (0) + ACS_RandomFixed (-200.0k, 200.0k), ACS_GetActorZ (0), tid);
                        ACS_Thing_Hate (tid, 0, 2);
                        ACS_Thing_ChangeTID(tid, 0);
                        ACS_NoiseAlert (0, 0);
                    }
                }
            }
            
            i = 0;
            randomizer = 0;
            randomizer2 = 0;
        }
        
        ACS_Delay (1);
        if (delayer > 0)
            delayer--;
        if (delayer < 0)
            delayer = 0;
    }
}
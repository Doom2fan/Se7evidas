#include "util.h"
#include "util_math.h"
#include "health.h"
#undef ACS_SHORT_NAMES

#define MEDIKITHEALTH 40
#define STIMPACKHEALTH MEDIKITHEALTH / 2

Script_C void S7_MedikitScript (void) {
    Print ("Applying Medikit");
    ACS_Thing_Stop (0);
    ACS_SetPlayerProperty (0, 1, PROP_TOTALLYFROZEN);
    ACS_Delay (35 * 2);
    ACS_SetPlayerProperty (0, 0, PROP_TOTALLYFROZEN);
    
    if (MEDIKITHEALTH - (100 - GetActorProperty (0, APROP_Health)) >= STIMPACKHEALTH)
        if (ACS_CheckInventory (s"S7_Stimpack") < 8)
            ACS_GiveInventory (s"S7_Stimpack", 1);
        else
            ACS_Spawn (s"S7_Stimpack", ACS_GetActorX (0), ACS_GetActorY (0), ACS_GetActorZ (0));
    
    ACS_HealThing (MEDIKITHEALTH);
}

Script_C void S7_StimpackScript (void) {
    Print ("Applying Stimpack");
    ACS_Thing_Stop (0);
    ACS_SetPlayerProperty (0, 1, PROP_TOTALLYFROZEN);
    ACS_Delay (35 * 1);
    ACS_HealThing (STIMPACKHEALTH);
    ACS_SetPlayerProperty (0, 0, PROP_TOTALLYFROZEN);
}

Script_C void S7_HeartbeatScript ENTER CLIENTSIDE (void) {
    // Not needed or desired in TitleMaps.
    if (ACS_GameType () == GAME_TITLE_MAP)
        return;
    
    int health;
    int heartbeatTics = 0;
    
    while (TRUE) {
        health = ACS_GetActorProperty (0, APROP_Health);
        
        if ((health <= 25 && health > 15 && heartbeatTics >= 89) ||
            (health <= 15 && health > 10 && heartbeatTics >= 71) ||
            (health <= 10 && health > 5  && heartbeatTics >= 53) ||
            (health <= 5  && health > 2  && heartbeatTics >= 35) ||
            (health <= 2  && health > 0  && heartbeatTics >= 18)) {
            heartbeatTics = 0;
            ACS_LocalAmbientSound (s"Player/Heartbeat", 127);
        } else if (health > 25)
            heartbeatTics = 0;
        else
            heartbeatTics++;
            
        ACS_Delay (1);
    }
}

Script_C int S7_GetMaxHealth (void) {
    return ACS_GetActorProperty (0, APROP_SpawnHealth);
}
#LIBDEFINE MEDIKITHEALTH 40
#LIBDEFINE STIMPACKHEALTH MEDIKITHEALTH / 2

#LIBDEFINE S7_MedikitScript 900
script S7_MedikitScript (void) {
    print (s:"Applying Medikit");
    thing_Stop (0);
    setPlayerProperty (0, 1, PROP_TotallyFrozen);
    delay (35 * 2);
    setPlayerProperty (0, 0, PROP_TotallyFrozen);
    if (MEDIKITHEALTH - (100 - GetActorProperty (0, APROP_Health)) >= STIMPACKHEALTH)
        if (!CheckInventory ("S7_Stimpack"))
            giveInventory ("S7_Stimpack", 1);
        else
            spawn ("S7_Stimpack", GetActorX (0), GetActorY (0), GetActorZ (0));
    healThing (MEDIKITHEALTH);
}

#LIBDEFINE S7_StimpackScript 901
script S7_StimpackScript (void) {
    print (s:"Applying Stimpack");
    thing_Stop (0);
    setPlayerProperty (0, 1, PROP_TotallyFrozen);
    delay (35 * 1);
    healThing (STIMPACKHEALTH);
    setPlayerProperty (0, 0, PROP_TotallyFrozen);
}

#LIBDEFINE S7_HeartbeatScript 903
script S7_HeartbeatScript ENTER CLIENTSIDE {
    if (gameType () == game_Title_Map)
        terminate;
    
    int health;
    int heartbeatTics = 0;
    
    while (TRUE) {
        health = getActorProperty (0, APROP_HEALTH);
        
        if (health < 2 && health > 0) {
            if (heartbeatTics >= 35) {
                heartbeatTics = 0;
                localAmbientSound ("Player/Heartbeat", 127);
            }
            heartbeatTics++;
        } else if (health <= 5 && health > 0) {
            if (heartbeatTics >= 70) {
                heartbeatTics = 0;
                localAmbientSound ("Player/Heartbeat", 127);
            }
            heartbeatTics++;
        } else if (health <= 10 && health > 0) {
            if (heartbeatTics >= 105) {
                heartbeatTics = 0;
                localAmbientSound ("Player/Heartbeat", 127);
            }
            heartbeatTics++;
        } else if (health <= 15 && health > 0) {
            if (heartbeatTics >= 140) {
                heartbeatTics = 0;
                localAmbientSound ("Player/Heartbeat", 127);
            }
            heartbeatTics++;
        } else if (health <= 25 && health > 0) {
            if (heartbeatTics >= 175) {
                heartbeatTics = 0;
                localAmbientSound ("Player/Heartbeat", 127);
            }
            heartbeatTics++;
        } else if (health > 20 && heartbeatTics > 0)
            heartbeatTics = 0;
            
        delay (1);
    }
}
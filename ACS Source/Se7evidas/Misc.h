script "S7_SpeedScript" ENTER {
    if (gameType () == game_Title_Map)
        terminate;
    
    int health;
    
    while (TRUE) {
        health = getActorProperty (0, APROP_HEALTH);
        
        if (health <= 20)
            giveInventory ("S7_Dying", 9999999);
        else
            takeInventory ("S7_Dying", 9999999);
        
        delay(1);
    }
}

script "S7_WaterScript" ENTER {
    // Not needed or desired in TitleMaps.
    if (gameType () == game_Title_Map)
        terminate;
    
    while (TRUE) {
        if (getActorProperty(0, APROP_WATERLEVEL) > 2) // if underwater...
            giveInventory ("S7_IsUnderwater", 1); // give S7_IsUnderwater

        else if (getActorProperty(0, APROP_WATERLEVEL) <= 2) // if not underwater
            takeInventory ("S7_IsUnderwater", 1); // take S7_IsUnderwater
            
        setInventory ("S7_AirTime", getAirSupply (PLN));
        delay (1);
    }
}

script "S7_Keys" ENTER {
    // Not needed or desired in TitleMaps.
    if (gameType () == Game_Title_Map)
        terminate;
    
    while (TRUE) {
        if (keyPressed (BT_RELOAD))
            useInventory ("S7_ReloadKey");
        
        delay (1);
    }
}

script "S7_BrutalDoomCompatibility" OPEN {
    // Not needed or desired in TitleMaps.
    if (gameType () == game_Title_Map)
        terminate;
    
    bool ACTIVATE = 0;
    bool tid = unusedTID (-37000, -47000);
    int delayer = 0;
    
    while (TRUE) {
        if (Spawn ("Brutal_Blood", 0.0, 0.0, 0.0, tid) || Spawn ("BrutalPistol", 0.0, 0.0, 0.0, tid)) {
            thing_Remove (tid);
            ACTIVATE = 1;
        }
        
        if (ACTIVATE) {
            int randomizer = random (0, 2);
            int randomizer2 = 0;
            int i = 0;
            int actionCount = 0;
            
            if (delayer == 0) {
                if (randomizer == 0) { // AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
                    delayer = 35 * random (10, 20);
                    for (i = 0; i < random (5, 30); i++) {
                        spawn ("GETTHATSHITOUTTAHERE", getActorX (0) + random (-200.0, 200.0), getActorY (0) + random (-200.0, 200.0), getActorZ (0), tid);
                        thing_Hate (tid, 0, 2);
                        thing_ChangeTID(tid, 0);
                        NoiseAlert (0, 0);
                    }
                } else if (randomizer == 1) { // Fuck sector colours up
                    delayer = 35 * random (10, 20);
                    for (i = 0; i < 32767; i++) {
                        sector_SetColor (i, random (0, 255), random (0, 255), random (0, 255), 0);
                        actionCount++;
                        if (actionCount >= 10000) {
                            delay (1);
                            actionCount = 0;
                        }
                    }
                } else if (randomizer == 2) { // Fuck flat rotations up
                    delayer = 35 * random (10, 20);
                    for (i = 0; i < 32767; i++) {
                        sector_SetRotation (i, random (0, 356), random (0, 356));
                        actionCount++;
                        if (actionCount >= 10000) {
                            delay (1);
                            actionCount = 0;
                        }
                    }
                }
                
                if (getLevelInfo (LEVELINFO_KILLED_MONSTERS) >= getLevelInfo (LEVELINFO_TOTAL_MONSTERS) ||
                    getLevelInfo (LEVELINFO_FOUND_SECRETS)>= getLevelInfo (LEVELINFO_TOTAL_SECRETS) ||
                    getLevelInfo (LEVELINFO_FOUND_ITEMS) >= getLevelInfo (LEVELINFO_TOTAL_ITEMS)) {
                    for (i = 0; i < 10; i++) {
                        spawn ("GETTHATSHITOUTTAHERE", getActorX (0) + random (-200.0, 200.0), getActorY (0) + random (-200.0, 200.0), getActorZ (0), tid);
                        thing_Hate (tid, 0, 2);
                        thing_ChangeTID(tid, 0);
                        NoiseAlert (0, 0);
                    }
                }
            }
            
            i = 0;
            randomizer = 0;
            randomizer2 = 0;
        }
        
        delay (1);
        if (delayer > 0)
            delayer--;
        if (delayer < 0)
            delayer = 0;
    }
}

/*#LIBDEFINE S7_CVars_Count 1
str S7_CVars [S7_CVars_Count] = {
};
#LIBDEFINE S7_GetCVar 916
script S7_GetCVar (int CVar) {
    int CVarValue = GetCVar (S7_CVars [CVar]);
    if (CVar > S7_CVars_Count - 1 || CVar < 0)
        setResultValue (-1);
    setResultValue (CVarValue);
}
#LIBDEFINE S7_GetUserCVar 917
script S7_GetUserCVar (int CVar) {
    int CVarValue = GetUserCVar (PLN, S7_CVars [CVar]);
    if (CVar > S7_CVars_Count - 1 || CVar < 0)
        setResultValue (-1);
    setResultValue (CVarValue);
}

#LIBDEFINE S7_GetCVarClientside 918
script S7_GetCVarClientside (int CVar) CLIENTSIDE {
    int CVarValue = GetUserCVar (PLN, S7_CVars [CVar]);
    if (CVar > S7_CVars_Count - 1 || CVar < 0)
        setResultValue (-1);
    setResultValue (CVarValue);
}*/
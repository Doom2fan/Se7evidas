global int 0:S7_SS_OldSpeed [];
global int 1:S7_SS_Sprinting [];

#DEFINE S7_SprintSystem 904
script S7_SprintSystem ENTER {
    if (gameType () == game_Title_Map)
        terminate;
    
    int tics = 0;
    while (TRUE) {
        if (checkWeapon ("S7_SprintWeapon") && S7_SS_Sprinting [playerNumber ()] == 0) {
            setActorProperty (0, APROP_SPEED, S7_SS_OldSpeed [playerNumber ()]);
            S7_SS_Sprinting [playerNumber ()] = 0;
            tics = 0;
            disableWeapon ("S7_SprintWeapon", "S7_Sprinting");
        }
        if (keyDown (BT_USER1) &&
            S7_SS_Sprinting [playerNumber ()] == 0 &&
            checkInventory ("S7_Stamina") >= 5 && !CheckInventory ("S7_Dying") &&
            !S7_SR_StaminaEmpty [playerNumber ()]
            ) {
            S7_SS_Sprinting [playerNumber ()] = 1;
            S7_SS_OldSpeed [playerNumber ()] = getActorProperty (0, APROP_SPEED);
            disableWeapon ("S7_SprintWeapon", "S7_Sprinting");
        }
        if (keyUp (BT_USER1) && S7_SS_Sprinting [playerNumber ()] && !S7_SR_StaminaEmpty [playerNumber ()]) {
            setActorProperty (0, APROP_SPEED, S7_SS_OldSpeed [playerNumber ()]);
            S7_SS_Sprinting [playerNumber ()] = 0;
            tics = 0;
            disableWeapon ("S7_SprintWeapon", "S7_Sprinting");
        }
        if (checkInventory ("S7_Sprinting") && S7_SS_Sprinting [playerNumber ()]) {
            if (checkInventory ("S7_Stamina") >= 5) {
                if (checkInventory ("S7_Sprinting") && tics >= 5) {
                    tics = 0;
                    if (getVelocity () > 0)
                        takeInventory ("S7_Stamina", 5);
                }
                if (checkInventory ("S7_Stamina") < 5 || CheckInventory ("S7_Dying")) {
                    setActorProperty (0, APROP_SPEED, S7_SS_OldSpeed [playerNumber ()]);
                    S7_SS_Sprinting [playerNumber ()] = 0;
                    S7_SR_StaminaEmpty [playerNumber ()] = 1;
                    disableWeapon ("S7_SprintWeapon", "S7_Sprinting");
                    restart;
                }
                if (checkInventory ("S7_Sprinting") && ((abs (getPlayerInput (-1, INPUT_FORWARDMOVE)) > 6400) || (abs (getPlayerInput (-1, INPUT_SIDEMOVE)) > 6400)))
                    setActorProperty (0, APROP_SPEED, 3.0);
                else if (checkInventory ("S7_Sprinting") && !((abs (getPlayerInput (-1, INPUT_FORWARDMOVE)) > 6400) || (abs (getPlayerInput (-1, INPUT_SIDEMOVE)) > 6400)))
                    setActorProperty (0, APROP_SPEED, 6.0);
                else if (!checkInventory ("S7_Sprinting"))
                    setActorProperty (0, APROP_SPEED, S7_SS_OldSpeed [playerNumber ()]);
            }
        }
        
        delay (1);
        
        if (S7_SS_Sprinting [playerNumber ()])
            tics++;
    }
}
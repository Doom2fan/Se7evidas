script "S7_HudWeapons" ENTER CLIENTSIDE { // HUD icons and stuff...
    // Not needed or desired in TitleMaps.
    if (gameType () == Game_Title_Map)
        terminate;
    
    while (TRUE) {
        if (getUserCVar (PLN,  "screenblocks") <= 11) { // if HUD shown...
            /* Firing modes */
            if (checkWeapon ("S7_TEC9")) { // if using the TEC-9...
                if (checkInventory ("S7_TEC9_Burst")) { // if in Burst mode...
                    SetFont ("BrstFire"); // Display Burst icon
                } else { // if in full auto mode
                    SetFont ("FullAuto"); // Display Full Auto icon
                }
                hudMessage (s:"A"; HUDMSG_PLAIN | HUDMSG_NOTWITHFULLMAP | HUDMSG_LAYER_UNDERHUD, 10001, 0, 0.0, 0.0, 0);
            } else if (checkWeapon ("S7_AMG")) { // if using the AMG...
                if (checkInventory ("S7_AMG_Burst")) { // if in Burst mode...
                    SetFont ("BrstFire"); // Display Burst icon
                } else { // if in full auto mode
                    SetFont ("FullAuto"); // Display Full Auto icon
                }
                hudMessage (s:"A"; HUDMSG_PLAIN | HUDMSG_NOTWITHFULLMAP | HUDMSG_LAYER_UNDERHUD, 10001, 0, 0.0, 0.0, 0);
            } else
                hudMessage (s:""; HUDMSG_PLAIN | HUDMSG_NOTWITHFULLMAP | HUDMSG_LAYER_UNDERHUD, 10001, 0, 0.0, 0.0, 0);
        } else
            hudMessage (s:""; HUDMSG_PLAIN | HUDMSG_NOTWITHFULLMAP | HUDMSG_LAYER_UNDERHUD, 10001, 0, 0.0, 0.0, 0);
        delay (1);
    }
}
//-------------------------------------------------------------------------------------------
//
// XP System
//
//-------------------------------------------------------------------------------------------

function void levelUp (int level) {
	setFont ("DBIGFONT");
	
	if (getCVAR ("S7_MsgsOn"))
		hudMessage (s:"You reached level ", d:level, s:"."; HUDMSG_FADEINOUT|getCVAR ("S7_LogLVLUpMsgs") * HUDMSG_LOG, 10000, CR_UNTRANSLATED, 0.5, 0.5, 3.0, 0.3, 0.3);
	
	playSound (0, "Player/LevelUp", CHAN_UI);
	giveInventory ("S7_XP_System_Level", 1);
	giveInventory ("S7_XP_System_Experience", random (4, 6));
}

#DEFINE S7_XP_System 918
script S7_XP_System ENTER {
	if (gameType () == Game_Title_Map)
		terminate;
	
	int currentLVL, currentXP, currentHP;
	int logMessages = getCVAR ("S7_LogLVLUpMsgs");
	
	while (TRUE) {
		currentLVL = checkInventory ("S7_XP_System_Level");
		currentXP = checkInventory ("S7_XP_System_Experience");
		logMessages = getCVAR ("S7_LogLVLUpMsgs");
		
		if (currentXP >= 1000 && currentLVL == 0) {
			levelUp (1);
            giveInventory ("BerettaUpgrade", 1);
            setFont ("SMALLFONT");
            if (getCVAR ("S7_MsgsOn"))
                hudMessage (s:"Beretta upgraded.\nBurstfire(press ", k:"+altattack", s:" to change firing modes)";
                    HUDMSG_FADEINOUT|logMessages * HUDMSG_LOG, 9999, CR_UNTRANSLATED, 0.5, 0.6, 3.0, 0.3, 0.3);
		}
		
		delay (1);
	}
}

//-------------------------------------------------------------------------------------------
//
// Stat System
//
//-------------------------------------------------------------------------------------------

// strength
function int S7_StrengthStat (int baseDamage, int multiplier) {
	int strengthStat = checkInventory ("S7_Stats_System_Strength");
	int result = baseDamage * (1.0 + (multiplier * strengthStat));
	
	return result >> 16;

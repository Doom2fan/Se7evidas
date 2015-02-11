#INCLUDE "zcommon.acs"
#LIBRARY "Se7evidas"

// Defines
#DEFINE MAXPLAYERS 64

// Includes
#INCLUDE "commonFuncs.h"
#INCLUDE "Weapon Stuff.h"
#INCLUDE "Health.h"
#INCLUDE "Stamina.h"
#INCLUDE "Sprint System.h"
#INCLUDE "Misc.h"
#INCLUDE "HUD.h"

// Defines

// Highest script num ID: 915
// Highest global var ID: 4

#DEFINE S7_Enter 906
script S7_Enter ENTER {
    setActorProperty (0, APROP_SPEED, 1.0);
    S7_SR_StaminaEmpty [playerNumber ()] = 0;
}

#DEFINE S7_Respawn 907
script S7_Respawn RESPAWN {
    setActorProperty (0, APROP_SPEED, 1.0);
    S7_SR_StaminaEmpty [playerNumber ()] = 0;
}
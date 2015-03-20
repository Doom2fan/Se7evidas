#INCLUDE "zcommon.acs"
#LIBRARY "Se7evidas"

// Defines
#LIBDEFINE MAXPLAYERS 64

// Includes
#INCLUDE "commonFuncs.h"
#INCLUDE "Se7evidas/Weapon Stuff.h"
#INCLUDE "Se7evidas/Health.h"
#INCLUDE "Se7evidas/Stamina.h"
#INCLUDE "Se7evidas/Sprint System.h"
#INCLUDE "Se7evidas/Misc.h"
#INCLUDE "Se7evidas/HUD.h"
#INCLUDE "Se7evidas/Bank System.h"

// Defines

// Highest script num ID: 920
// Highest global var ID: 5

#LIBDEFINE S7_Enter 906
script S7_Enter ENTER {
    setActorProperty (0, APROP_SPEED, 1.0);
    S7_SR_StaminaEmpty [playerNumber ()] = 0;
}

#LIBDEFINE S7_Respawn 907
script S7_Respawn RESPAWN {
    setActorProperty (0, APROP_SPEED, 1.0);
    S7_SR_StaminaEmpty [playerNumber ()] = 0;
}
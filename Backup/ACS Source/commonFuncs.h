#DEFINE TICUNITS         35.725

// A bunch of functions that I've built up
// They come in handy :>
// by Ijon
function int abs (int x) {
    if (x < 0)
		return -x;
	
    return x;
}

function int mod (int x, int y) {
    int ret = x - ((x / y) * y);
	
    if (ret < 0)
		ret = y + ret;
	
    return ret;
}

function int pow (int x, int y) {
    int n = 1;
	
    while (y-- > 0)
		n *= x;
	
    return n;
}

function int powFixed (int x, int y) {
    int n = 1.0;
    while (y-- > 0)
		n = fixedMul (n, x);
	
    return n;
}

function int keyUp (int key) {
    int buttons = getPlayerInput (-1, INPUT_BUTTONS);

    if (~buttons & key)
        return 1;
    
    return 0;
}

function int keyDown (int key) {
    int buttons = getPlayerInput (-1, INPUT_BUTTONS);

    if (buttons & key)
        return 1;
    
    return 0;
}

function int keyPressed (int key) {
    int buttons     = getPlayerInput (-1, INPUT_BUTTONS);
    int oldbuttons  = getPlayerInput (-1, INPUT_OLDBUTTONS);
    int newbuttons  = (buttons ^ oldbuttons) & buttons;

    if (newbuttons & key)
        return 1;
    
    return 0;
}

function int unusedTID(int start, int end) {
    int ret = start - 1;
    int tidNum;
    if (start > end) {
        start ^= end;
        end ^= start;
        start ^= end;
    } // good ol' XOR swap
    while (ret++ != end) {
        if (ThingCount(0, ret) == 0)
            return ret;
    }
    
    return -1;
}

// I dunno who made this...
function int getVelocity (void) {
    int vel;
    int x = getActorVelX (0);
    int y = getActorVelY (0);
    int angle = vectorAngle (x, y);
    
    if (((angle + 0.125) % 0.5) > 0.25)
        vel = fixedDiv (y, sin (angle));
    else
        vel = fixedDiv (x, cos (angle));
    return vel >> 16;
}

// by Alex_mercer
// Health Boost
function void healthBoost (int HP) {
    int currentHP = getActorProperty (0, APROP_SPAWNHEALTH);
    setActorProperty (0, APROP_SPAWNHEALTH, currentHP + HP);
}

// Health Unboost
function void healthUnboost (int HP) {
    int currentHP = getActorProperty (0, APROP_SPAWNHEALTH);
    setActorProperty (0, APROP_SPAWNHEALTH, currentHP - HP);
}

// Set inventory
function void setInventory (str actorName, int amount) {
    takeInventory (actorName, 0x7FFFFFFF);
    giveInventory (actorName, amount);
}

// Player move speed script made by DoomRater
// turned into a function by Alex_Mercer
function void playerSpeed (int movespeed) {
    setActorProperty (0, APROP_SPEED, movespeed * 65535 / 100);
}

function int clamp (int x, int min, int max) {
    int realMin = min;
    int realMax = max;
    
    if (min > max) {
        realMax = min;
        realMin = max;
    }
    
    if (x > realMax)
        return realMax;
    else if (x < realMin)
        return realMin;
    else
        return x;
}

function int scaleValue (int x, int fromMin, int fromMax, int toMin, int toMax) {
    return (x - fromMin) * (toMax - toMin) / (fromMax - fromMin) + toMin;
}

function fixed scaleValueFixed (fixed x, fixed fromMin, fixed fromMax, fixed toMin, fixed toMax) {
    return fixedDiv (fixedMul (x - fromMin, toMax - toMin), fromMax - fromMin) + toMin;
}
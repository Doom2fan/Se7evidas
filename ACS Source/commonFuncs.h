#LIBDEFINE TICUNITS         35.725

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

function int powFloat (int x, int y) {
    int n = 1.0;
    while (y-- > 0)
        n = fixedMul (n, x);
    
    return n;
}

function int min (int x, int y) {
    if (x < y)
        return x;
    
    return y;
}

function int max (int x, int y) {
    if (x > y)
        return x;
    
    return y;
}

function int middle (int x, int y, int z) {
    if ((x < z) && (y < z))
        return min (max (x, y), z);
    
    return max (min (x, y), z);
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

function int adjustBottom (int tmin, int tmax, int i) {
    if (i < tmin)
        tmin = i;
    if (i > tmax)
        tmin += (i - tmax);

    return tmin;
}

function int adjustTop (int tmin, int tmax, int i) {
    if (i < tmin)
        tmax -= (tmin - i);
    if (i > tmax)
        tmax = i;

    return tmax;
}


function int quadPos (int a, int b, int c) {
    int s1 = sqrt (fixedMul (b, b) - (4 * fixedMul (a, c)));
    int s2 = (2 * a);
    int b1 = fixedDiv (-b + s1, s2);

    return b1;
}

function int quadNeg (int a, int b, int c) {
    int s1 = sqrt (fixedMul (b, b) - (4 * fixedMul (a, c)));
    int s2 = (2 * a);
    int b1 = fixedDiv (-b - s1, s2);

    return b1;
}

function int quadHigh (int a, int b, int c, int x) {
    c -= x;
    
    return quadPos (a, b, c);
}

function int quadLow (int a, int b, int c, int x) {
    c -= x;
    
    return quadNeg (a, b, c);
}

function int quad (int a, int b, int c, int y) {
    return fixedMul (a, fixedMul (y, y)) + fixedMul (b, y) + y;
}

// Note: high is not inclusive because it's more useful that way
function int inRange (int low, int high, int x) {
    return ((x >= low) && (x < high));
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

// by Alex_mercer

// Summoning
function void summon (str actor, int spottid, int tid, int angle) {
    spawnSpot (actor, spottid, tid, angle);
    spawnSpot ("TeleportFog", spottid, 0, 0);
}

// Infighting
function void infight (int hate1, int hate2, int type) {
    thing_Hate (hate1, hate2, type);
    thing_Hate (hate2, hate1, type);
}

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
// transformed into a function by Alex_Mercer
function void playerSpeed (int movespeed) {
    setActorProperty (0, APROP_SPEED, movespeed * 65535 / 100);
}

// I dunno who made this...
// I got it from ww-terror's Titlemap
function int hudMessageTime (int type, int length, int typetime, int staytime, int fadetime) {
    switch (type) {
    case HUDMSG_PLAIN:
        return fixedMul (staytime, TICUNITS) >> 16;
    
    case HUDMSG_FADEOUT:
        return fixedMul (staytime + fadetime, TICUNITS) >> 16;
    
    case HUDMSG_TYPEON:
        return fixedMul (fixedMul (typetime, length << 16) + staytime + fadetime, TICUNITS) >> 16;
    
    case HUDMSG_FADEINOUT:
        return fixedMul (typetime + staytime + fadetime, TICUNITS) >> 16;
    }
    
    return 0;
}

// From the ZDoom Wiki
// Hud Message on actor

/*function void hudMessageonactor (int tid, int range, str sprite, str text) {
    int dist, ang, vang, pitch, x, y;
    int HUDX = 640;
    int HUDY = 400;
    int offset = 0;

    if (sprite != -1) {
        SetFont (sprite);
        text = "A";
        offset = 0.1;
    }

    setHudSize (HUDX, HUDY, 1);
    x = getActorX (tid) - getActorX (0);
    y = getActorY (tid) - getActorY (0); 

    vang = vectorAngle (x, y);
    ang = (vang - getActorAngle (0) + 1.0) % 1.0;

    if (((vang + 0.125) % 0.5) > 0.25)
        dist = fixedDiv (y, sin (vang));
    else
        dist = fixedDiv (x, cos (vang));

    if ((ang < 0.2 || ang > 0.8) && dist >> 16 < range) {
        pitch = vectorAngle (dist, getActorZ (tid) - (getActorZ (0) + 41.0));
        pitch = (pitch + getActorPitch (0) + 1.0) % 1.0;

        x = HUDX / 2 - ((HUDX / 2) * sin (ang) / cos (ang));
        y = HUDY / 2 - ((HUDX / 2) * sin (pitch) / cos (pitch));

        hudMessage (s:text; HUDMSG_PLAIN, 1, CR_UNTRANSLATED, (x << 16) + offset, (y << 16) + offset, 0);
    }
    else
        hudMessage (s:""; HUDMSG_PLAIN, 1, CR_UNTRANSLATED, 0, 0, 0);
}*/

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
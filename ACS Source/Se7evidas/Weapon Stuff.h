#LIBDEFINE S7_WEAPONMAX 4
str S7_WeaponName [S7_WEAPONMAX] = { "S7_Raptor", "S7_Shotgun", "S7_TEC9", "S7_Revolver" };
#LIBDEFINE S7_DUMMYWEAPON_COUNT 3
str S7_DummyWeapons [S7_DUMMYWEAPON_COUNT] = { "S7_NullWeapon", "S7_SprintWeapon", "S7_QuickMelee" };
global int 2:S7_LastWeapon [];

function int getWeaponName (void) {
    for (int x = 0; x < S7_DUMMYWEAPON_COUNT; x++)
        if (checkWeapon (S7_DummyWeapons [x])) 
            return -1;
    
    for (int y = 0; y < S7_WEAPONMAX; y++)
        if (checkWeapon (S7_WeaponName [y]))
            return y;
    
    return -1;
}

function void lastWeapon (int mode) {
    int weaponNumber = 0;
    if (mode != 0) {
        weaponNumber = S7_LastWeapon [playerNumber ()];
        if (weaponNumber < 0 || weaponNumber > S7_WEAPONMAX - 1)
            return;
        setWeapon (S7_WeaponName [weaponNumber]);
    } else {
        weaponNumber = getWeaponName ();
        if (weaponNumber < 0 || weaponNumber > S7_WEAPONMAX - 1)
            return;
        else
            S7_LastWeapon [playerNumber ()] = weaponNumber;
    }
}

function void disableWeapon (str meh, str blah) {
    if (checkWeapon (meh)) {
        takeInventory (blah, 99999);
        lastWeapon (1);
        return;
    }
    print (s:meh);
    giveInventory (meh, 1);
    //setWeapon (meh);
    lastWeapon (0);
}

// Scripts
// SynthFire stuff
#LIBDEFINE S7_SynthFire 910
script S7_SynthFire (void) {
    while (TRUE) {
        if (!checkInventory ("S7_SynthFireActive"))
            terminate;
        
        if (keyDown (BT_ATTACK) && !checkInventory ("S7_SynthFireLeft"))
            giveInventory ("S7_SynthFireLeft", 1);
        
        if (keyDown (BT_ALTATTACK) && !checkInventory ("S7_SynthFireRight"))
            giveInventory ("S7_SynthFireRight", 1);
        
        delay (1);
        
        if (!keyDown (BT_ATTACK) && checkInventory ("S7_SynthFireLeft"))
            takeInventory ("S7_SynthFireLeft", 1);
        
        if (!keyDown (BT_ALTATTACK) && checkInventory ("S7_SynthFireRight"))
            takeInventory ("S7_SynthFireRight", 1);
    }
}

#LIBDEFINE S7_SynthFireAllowChange 911
script S7_SynthFireAllowChange (void) {
    if (!checkInventory ("S7_SynthFireRightReloading") || checkInventory ("S7_SynthFireLeftReloading"))
        setResultValue (1);
    else
        setResultValue (0);
}

#LIBDEFINE S7_QuickMelee 919
script S7_QuickMelee (void) {
    disableWeapon ("S7_QuickMelee", "None");
}
/* AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACCCCCCCCCCCCCCCCCCCCCCKKKKKKKKKK
** I have to rewrite some of this shit for Zandro and GZDoom now...
*/
/*// Credits to TheMisterCat for the code

// Default button width and height = 50;
// Default button positions {
// 1/Top = X 401, Y 60
// 2/Top-Right = X 567, Y 120
// 3/Right = X 661, Y 232
// 4/Bottom-Right = X 567, Y 361
// 5/Bottom = X 401, Y 427
// 6/Bottom-Left = X 233, Y 361
// 7/Left = X 139, Y 232
// 8/Top-Left = X 233, Y 120
// }

#LIBDEFINE SCREEN_WIDTH                800
#LIBDEFINE SCREEN_HEIGHT               600

#LIBDEFINE SENSITIVITY_X               20
#LIBDEFINE SENSITIVITY_Y               20

#LIBDEFINE SHOPBACKGROUNDID            9000000
#LIBDEFINE SHOPCURSORID                8000000
#LIBDEFINE SHOPTEXTID                  8000001
#LIBDEFINE SHOPCOSTID                  8000002
#LIBDEFINE BACKBUTTON                  8000003
#LIBDEFINE SHOPBUTTONS                 8000004

int mouseX [MAXPLAYERS] = { SCREEN_WIDTH / 2 };
int mouseY [MAXPLAYERS] = { SCREEN_HEIGHT / 2 };
int shopGUIOPEN [MAXPLAYERS];
int shopGUIDisplayingError [MAXPLAYERS];

function void shopSystem_PrintTextTimed (str text, str font, int time) {
    // shopSystem_PrintText (Text, Font, Time);
    setHudSize (SCREEN_WIDTH, SCREEN_HEIGHT, 0);
    
    if (font == 0) 
        setFont ("SmallFont");
    else
        setFont (font);
    
    if (!shopGUIDisplayingError [playerNumber ()])
        hudMessage (s:text; HUDMSG_FADEOUT, SHOPTEXTID, 0, 11.1, 492.1, time, 0.3);
}

function void shopSystem_PrintText (str text, str font) {
    // shopSystem_PrintText (Text, Font);
    shopSystem_PrintTextTimed (text, font, 0.1);
}

function void shopSystem_PrintError (str text, str font, int time) {
    // shopSystem_PrintError (Text, Font, Time);
    setHudSize (SCREEN_WIDTH, SCREEN_HEIGHT, 0);
    
    if (font == 0) 
        setFont ("SmallFont");
    else
        setFont (font);
    
    hudMessage (s:text; HUDMSG_FADEOUT, SHOPTEXTID, 0, 11.1, 492.1, time, 0.3);
}

function void shopSystem_PrintCost (int cost) {
    // shopSystem_PrintCost (cost);
    setHudSize (SCREEN_WIDTH, SCREEN_HEIGHT, 0);

    setFont ("SmallFont");
    hudMessage (s:"$", d:cost; HUDMSG_PLAIN, SHOPCOSTID, 0, 780*1.0, 492*1.0, 0.1);
}

#LIBDEFINE S7_ShopSystem_NoCash 915
script S7_ShopSystem_NoCash (void) {
    shopGUIDisplayingError [playerNumber ()] = 1;
    shopSystem_PrintError ("You don't have enough money for that.", "SMALLFONT", 1.0);
    
    delay (35 * 1);
    
    shopGUIDisplayingError [playerNumber ()] = 0;
}

#LIBDEFINE S7_ShopSystem_NoSpace 916
script S7_ShopSystem_NoSpace (void) {
    shopGUIDisplayingError[playerNumber ()] = 1;
    shopSystem_PrintError ("Your inventory is full.", "SMALLFONT", 1.0);
    
    delay (35 * 1);
    
    shopGUIDisplayingError[playerNumber ()] = 0;
}

function int shopSystem_BuyStuff (str inventory, int price, int amount) {
    // shopSystem_BuyStuff (str inventory, int amount, int price);
    // returns 1 if successful, -1 if inventory is full and -2 if not enough cash
    int cash = checkInventory ("Energy");
    
    if (checkInventory (inventory) >= checkInventoryMax (inventory)) {
        ACS_Execute (S7_ShopSystem_NoSpace, 0);
        
        return -1;
    } else {
        if (cash < price) {
            ACS_Execute (S7_ShopSystem_NoCash, 0);
            
            return -2;
        } else {
            giveInventory (inventory, amount);
            takeInventory ("Energy", price);
            
            return 1;
        }
    }
    
    return 0;
}

function int shopSystem_BasicButton (str image, str image2, int bx, int by, int bwidth, int bheight, int bid) {
    // shopSystem_BasicButton (Normal image, Clicked image, Button X, Button Y, Button width, Button height, Button ID);
    // returns 1 when clicked with left button, 2 when clicked with right button and 3 when hovered.
    setHudSize (SCREEN_WIDTH, SCREEN_HEIGHT, 0);

    setFont (image);
    hudMessage (s:"A";
        HUDMSG_PLAIN, bid, 0, bx*1.0, by*1.0, 0.1);

    if (mouseX [PlayerNumber ()] > bx - bwidth && mouseX [PlayerNumber ()] < bx + bwidth && mouseY [PlayerNumber ()] > by - bheight && mouseY [PlayerNumber ()] < by + bheight) {
        if (keyPressed (BT_ATTACK) == 1) {
            setFont (image2);
            hudMessage (s:"A";
                HUDMSG_PLAIN, bid, 0, bx*1.0, by*1.0, 0.1);
            return 1;
        } else if (keyPressed (BT_ALTATTACK) == 1) {
            setFont (image2);
            hudMessage (s:"A"; HUDMSG_PLAIN, bid, 0, bx*1.0, by*1.0, 0.1);
            return 2;
        }
        
        return 3;
    }

    return false;
}

function int shopSystem_BasicTextButton (str text, int bx, int by, int bwidth, int bheight, int bid) {
    // shopSystem_BasicTextButton (Text, Button X, Button Y, Button width, Button height, Button ID);
    // returns 1 when clicked with left button, 2 when clicked with right button and 3 when hovered.
    setHudSize (SCREEN_WIDTH, SCREEN_HEIGHT, 0);

    setFont ("SMALLFONT");
    if (mouseX [PlayerNumber ()] > bx - bwidth && mouseX [PlayerNumber ()] < bx + bwidth && mouseY [PlayerNumber ()] > by - bheight && mouseY [PlayerNumber ()] < by + bheight)
        hudMessage (s:text; HUDMSG_PLAIN, bid, CR_RED, bx * 1.0, by * 1.0, 0.1);
    else
        hudMessage (s:text; HUDMSG_PLAIN, bid, CR_WHITE, bx * 1.0, by * 1.0, 0.1);

    if (mouseX [PlayerNumber ()] > bx - bwidth && mouseX [PlayerNumber ()] < bx + bwidth && mouseY [PlayerNumber ()] > by - bheight && mouseY [PlayerNumber ()] < by + bheight) {
        if (keyPressed (BT_ATTACK) == 1)
            return 1;
        else if (keyPressed (BT_ALTATTACK) == 1)
            return 2;
        return 3;
    }

    return false;
}

#LIBDEFINE S7_ShopSystem_ToggleShopSystem 917
#LIBDEFINE S7_ShopSystem 918
script S7_ShopSystem (void) {
    int mouseXAdd = getPlayerInput (-1, INPUT_YAW);
    int mouseYAdd = getPlayerInput (-1, INPUT_PITCH);
    int CurrentPage = 0; // Current page. 0 == Main, 1 == Runes, 2 == Spheres, 3 == Health Items
    int Cash = checkInventory ("Energy"); // The player's current amount of cash
    int Counter = 0; // This is used to fix a bug that happens when changing the page.
    
    while (TRUE) {
        Cash = checkInventory ("Energy");
        // move the cursor
        mouseXAdd = getPlayerInput (-1, INPUT_YAW);
        mouseYAdd = getPlayerInput (-1, INPUT_PITCH);

        mouseX [PlayerNumber ()] -= mouseXAdd / SENSITIVITY_X;
        mouseY [PlayerNumber ()] -= mouseYAdd / SENSITIVITY_Y;
        // prevent the cursor from going offscreen
        if (mouseX [PlayerNumber ()] < 0)
            mouseX [PlayerNumber ()] = 0;
        if (mouseX [PlayerNumber ()] > SCREEN_WIDTH)
            mouseX [PlayerNumber ()] = SCREEN_WIDTH;
        
        if (mouseY [PlayerNumber ()] < 0)
            mouseY [PlayerNumber ()] = 0;
        if (mouseY [PlayerNumber ()] > SCREEN_HEIGHT)
            mouseY [PlayerNumber ()] = SCREEN_HEIGHT;
        
        setFont ("CURSOR");
        hudMessage (s:"A"; HUDMSG_FADEOUT, SHOPCURSORID, CR_UNTRANSLATED, mouseX [PlayerNumber ()] * 1.0 + 0.1, mouseY [PlayerNumber ()] * 1.0 + 0.1, 0.04, 0.3);

        if (CurrentPage == 0) { // Main
            if (shopSystem_BasicButton ("M_BACK_D", "M_BACK_D", 8, 6, 8, 6, BACKBUTTON) == 1)
                ACS_Execute (S7_ShopSystem_ToggleShopSystem, 0);
            
            if (Counter < 1) {
                if (shopSystem_BasicButton ("Graphics/ShopSystem/Runes.png", "Graphics/ShopSystem/RunesClicked.png", 394, 60, 50, 50, SHOPBUTTONS) == 1) {
                    CurrentPage = 1;
                    Counter = 1;
                }
                if (shopSystem_BasicButton ("Graphics/ShopSystem/Runes.png", "Graphics/ShopSystem/RunesClicked.png", 394, 60, 50, 50, SHOPBUTTONS) == 3)
                    shopSystem_PrintText ("Enter the Magical Runes menu.", "SmallFont");

                if (shopSystem_BasicButton ("Graphics/ShopSystem/Spheres.png", "Graphics/ShopSystem/SpheresClicked.png", 567, 120, 50, 50, SHOPBUTTONS + 1) == 1) {
                    CurrentPage = 2;
                    Counter = 1;
                }
                if (shopSystem_BasicButton ("Graphics/ShopSystem/Spheres.png", "Graphics/ShopSystem/SpheresClicked.png", 567, 120, 50, 50, SHOPBUTTONS + 1) == 3)
                    shopSystem_PrintText ("Enter the Spheres menu.", "SmallFont");

                if (shopSystem_BasicButton ("Graphics/ShopSystem/Health.png", "Graphics/ShopSystem/HealthClicked.png", 661, 232, 50, 50, SHOPBUTTONS + 2) == 1) {
                    CurrentPage = 3;
                    Counter = 1;
                }
                if (shopSystem_BasicButton ("Graphics/ShopSystem/Health.png", "Graphics/ShopSystem/HealthClicked.png", 661, 232, 50, 50, SHOPBUTTONS + 2) == 3)
                    shopSystem_PrintText ("Enter the Health items menu.", "SmallFont");
            }
            else {
                if (shopSystem_BasicButton ("Graphics/ShopSystem/Runes.png", "Graphics/ShopSystem/Runes.png", 394, 60, 50, 50, SHOPBUTTONS) == 3)
                    shopSystem_PrintText ("Enter the Magical Runes menu.", "SmallFont");
                
                if (shopSystem_BasicButton ("Graphics/ShopSystem/Spheres.png", "Graphics/ShopSystem/Spheres.png", 567, 120, 50, 50, SHOPBUTTONS + 1) == 3)
                    shopSystem_PrintText ("Enter the Spheres menu.", "SmallFont");

                if (shopSystem_BasicButton ("Graphics/ShopSystem/Health.png", "Graphics/ShopSystem/Health.png", 661, 232, 50, 50, SHOPBUTTONS + 2) == 3)
                    shopSystem_PrintText ("Enter the Health items menu.", "SmallFont");
            }
        }
        
        if (Counter > 0) // If the timer is greater than 0,
            Counter++; // Add 1
        delay (1);
        if (Counter >= 9) // If the timer is 9,
            Counter = 0; // Reset it
    }
}

script S7_ShopSystem_ToggleShopSystem (void) NET {
    setHudSize (SCREEN_WIDTH, SCREEN_HEIGHT, 0);
    
    if (shopGUIOPEN [playerNumber ()] == 0) {
        shopGUIOPEN [playerNumber ()] = 1;
        mouseX [PlayerNumber ()] = SCREEN_WIDTH / 2;
        mouseY [PlayerNumber ()] = SCREEN_HEIGHT / 2;
        setFont ("Graphics/ShopSystem/Background.png");
        hudMessage (s:"A"; HUDMSG_PLAIN, SHOPBACKGROUNDID, CR_UNTRANSLATED, 0.1, 0.1, 0.0);
        ACS_Execute (S7_ShopSystem, 0);
        delay (1);
        setPlayerProperty (0, 1, PROP_TOTALLYFROZEN);
        terminate;
    } else if (shopGUIOPEN [playerNumber ()] == 1) {
        shopGUIOPEN [playerNumber ()] = 0;
        mouseX [PlayerNumber ()] = SCREEN_WIDTH / 2;
        mouseY [PlayerNumber ()] = SCREEN_HEIGHT / 2;
        setFont ("Graphics/ShopSystem/Background.png");
        hudMessage (s:"A";
            HUDMSG_FADEOUT, SHOPBACKGROUNDID, CR_UNTRANSLATED, 0.1, 0.1, 0.0001, 0.3);
        ACS_Terminate (S7_ShopSystem, 0);
        delay (1);
        setPlayerProperty (0, 0, PROP_TOTALLYFROZEN);
        terminate;
    }
}*/
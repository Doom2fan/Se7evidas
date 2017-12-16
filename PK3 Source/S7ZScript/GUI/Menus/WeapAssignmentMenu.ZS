class S7_WeapAssignMenuHandler : S7_ZF_Handler {
    S7_WeapAssignMenu link;

    override void buttonCommand (S7_ZF_Button button, string command) {
    }
}

class S7_WeapAssignMenu : S7_ZF_GenericMenu {
    S7_WeapAssignMenuHandler handler;

    PlayerInfo CPlayer;

    Font bigFont;
    Font smallFont;
    S7_ZF_Frame slotsFrame;
    S7_ZF_Button slotButtons [3] [5];
    S7_ZF_Image  slotImages  [3] [5];

    static const String weapLabelsText [] = {
        "Medium", "Light", "Heavy", "Area-damage", "Special"
    };
    override void Init (Menu parent) {
        Super.Init (parent);
        SetBaseResolution ((640, 480));

        CPlayer = players [consolePlayer];

        handler = new ("S7_WeapAssignMenuHandler");
        handler.link = self;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('SmallFont');

        slotsFrame = new ("S7_ZF_Frame").Init ((0, 0), (640, 240));
        slotsFrame.Pack (mainFrame);

        string labelText = "WEAPON SLOT ASSIGNMENT";
        S7_ZF_Label label = new ("S7_ZF_Label").Init ((0, 12), (0, bigFont.GetHeight ()), labelText, bigFont, false, true, 1, Font.CR_WHITE);
        label.box.pos.X = 320.0 - (bigFont.stringWidth (labelText) / 2.0);
        label.Pack (slotsFrame);

        for (int x = 0; x < 5; x++) {
            double xCoords = 19.0 + ((105.0 + 19.0) * x);
            labelText = weapLabelsText [x];
            label = new ("S7_ZF_Label").Init ((xCoords, 48), (0, smallFont.GetHeight ()), labelText, smallFont, false, true, 1, Font.CR_WHITE);
            label.box.pos.X += (105.0 / 2) - (smallFont.stringWidth (labelText) / 2.0);
            label.Pack (slotsFrame);

            for (int y = 0; y < 3; y++) {
                double yCoords = 72.0 + ((40.0 + 8.0) * y);
                // Button
                slotButtons [x] [y] = new ("S7_ZF_Button").Init ((xCoords, yCoords), (107, 42), "", handler, "SetSlot", null, null, null, null);
                slotButtons [x] [y].SetTexture ("graphics/Menu/WeapAssignment/WeapSlot.png", "graphics/Menu/WeapAssignment/WeapSlotHover.png", "graphics/Menu/WeapAssignment/WeapSlotPressed.png", "");
                slotButtons [x] [y].Pack (slotsFrame);
                // Image
                slotImages [x] [y] = new ("S7_ZF_Image").Init ((xCoords + 1, yCoords + 1), (105, 40), "", S7_ZF_Image.AlignCenter, noOffsets: true);
                slotImages [x] [y].Pack (slotsFrame);
            }
        }

        //dontDim = true;
    }

    override void Ticker () { // GetClassName
        super.Ticker ();

        if (!CPlayer || !CPlayer.mo)
            return;

        let weapBinds = S7_WeapBindsSystem (CPlayer.mo.FindInventory ("S7_WeapBindsSystem"));

        Array<S7_BaseWeapon> weapons;
        S7_BaseWeapon weap;
        for (int x = 0; x < 5; x++) {
            weapons.Clear ();
            weapons.Copy (weapBinds.Binds [x + 1]);

            for (int y = 0; y < 3; y++) {
                if (y < weapBinds.Binds [x + 1].Size () && (weap = weapons [y]))
                    slotImages [x] [y].image = weap.weapIcon;
                else
                    slotImages [x] [y].image = "";
            }
        }
    }
}

class S7_WeapAssignMenu_EventHandler : EventHandler {
    override void NetworkProcess (ConsoleEvent e) {
        if (e.IsManual || e.Player < 0) // Don't execute this if it was called manually or the player isn't given/valid
            return;
        if (!playeringame [e.Player] || !players [e.Player].mo) // Don't execute if the player isn't ingame, the player is null or the player's PlayerPawn is null
            return;

        Array<String> strings;
        e.Name.Split (strings, ":");
        if (strings.Size () != 2 || strings [0] != "S7_WeapBindsSystem") // Return if the array doesn't contain exactly two strings or the first string isn't "S7_WeapBindsSystem"
            return;

    }
}
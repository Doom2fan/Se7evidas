class S7_PlayerMenuHandler : S7_ZF_Handler {
    S7_PlayerMenu link;

    override void buttonCommand (S7_ZF_Button caller, string command) {
        if (command == "openXPSysMenu")
            Menu.SetMenu ("S7_XPSystemMenu");
        else if (command == "openLuciusShop")
            Menu.SetMenu ("S7_LuciusShopMenu");
        else if (command == "openWeapAssignMenu")
            Menu.SetMenu ("S7_WeapAssignMenu");
        else if (command == "openDracoWeapMenu")
            Menu.SetMenu ("S7_DracoWeapAssignMenu");
        else if (command == "openAutogunMenu")
            Menu.SetMenu ("S7_AutogunMenu");
    }
}

class S7_PlayerMenu : S7_ZF_GenericMenu {
    S7_PlayerMenuHandler handler;

    PlayerInfo CPlayer;

    Font bigFont;
    Font smallFont;
    S7_ZF_Frame menusFrame;
    S7_ZF_Button xpSysButton, luciusShopButton, weapAssignButton, dracoWeapAssignButton, m400AutogunButton;

    override void Init (Menu parent) {
        Super.Init (parent);
        SetBaseResolution ((640, 480));
        menuactive = Menu.OnNoPause;

        CPlayer = players [consolePlayer];

        if (!CPlayer || !CPlayer.mo)
            return;

        handler = new ("S7_PlayerMenuHandler");
        handler.link = self;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        menusFrame = new ("S7_ZF_Frame").Init ((0, 0), (640, 480));
        menusFrame.Pack (mainFrame);

        string labelText = StringTable.Localize ("$PLAYERMENUHEADER", true);
        S7_ZF_Label label = new ("S7_ZF_Label").Init ((0, 12), (0, bigFont.GetHeight ()), labelText, bigFont, false, true, 1, Font.CR_WHITE);
        label.box.pos.X = 320.0 - (bigFont.stringWidth (labelText) / 2.0);
        label.Pack (menusFrame);

        double fontHeight = smallFont.GetHeight ();

        int buttonCount = 0;
        AddButton (xpSysButton, "$PLAYERMENU_XPMENU", 15 + ((fontHeight+4) * buttonCount++), handler, "openXPSysMenu");
        AddButton (luciusShopButton, "$PLAYERMENU_LUCIUSSHOP", 15 + ((fontHeight+4) * buttonCount++), handler, "openLuciusShop");
        AddButton (weapAssignButton, "$PLAYERMENU_WEAPASSIGN", 15 + ((fontHeight+4) * buttonCount++), handler, "openWeapAssignMenu");
        if (true) //CheckInventory ("S7_DracoStored"))
            AddButton (dracoWeapAssignButton, "$PLAYERMENU_DRACOWEAPASSIGN", 15 + ((fontHeight+4) * buttonCount++), handler, "openDracoWeapMenu");
        if (CheckInventory ("S7_M400AutogunStored"))
            AddButton (m400AutogunButton, "$PLAYERMENU_M400AUTOGUN", 15 + ((fontHeight+4) * buttonCount++), handler, "openAutogunMenu");

        //dontDim = true;
    }

    bool CheckInventory (class<Inventory> item, int amount = 1) {
        if (CPlayer == null)
            return false;

        let it = CPlayer.mo.FindInventory (item);
        return it != null && it.Amount >= amount;
    }

    void AddButton (out S7_ZF_Button button, string label, double yOffs, S7_ZF_Handler cmdHandler = NULL, string command = "") {
        string btnText = StringTable.Localize (label, true);
        int btnTextWidth = smallFont.StringWidth (btnText), btnTextHeight = smallFont.GetHeight ();

        button = new ("S7_ZF_Button").Init (((640 - btnTextWidth) / 2, ((480 - btnTextHeight) / 2) + yOffs), (btnTextWidth, btnTextHeight),
            btnText, cmdHandler, command, fnt: smallFont);
        button.SetTexture ("", "", "", "");
        button.Pack (menusFrame);
    }

    override void Ticker () {
        Super.Ticker ();
        menuactive = Menu.OnNoPause;

        if (!CPlayer || !CPlayer.mo || CPlayer.mo.health < 1) {
            self.Close ();
            return;
        }

        xpSysButton.textColor           = (     xpSysButton.isHovered ? Font.CR_RED : Font.CR_WHITE);
        luciusShopButton.textColor      = (luciusShopButton.isHovered ? Font.CR_RED : Font.CR_WHITE);
        weapAssignButton.textColor      = (weapAssignButton.isHovered ? Font.CR_RED : Font.CR_WHITE);
        if (dracoWeapAssignButton)
            dracoWeapAssignButton.textColor = (dracoWeapAssignButton.isHovered ? Font.CR_RED : Font.CR_WHITE);
        if (m400AutogunButton)
            m400AutogunButton.textColor     = (m400AutogunButton.isHovered ? Font.CR_RED : Font.CR_WHITE);
    }
}
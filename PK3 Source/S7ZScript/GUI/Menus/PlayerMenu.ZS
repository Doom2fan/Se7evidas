class S7_PlayerMenuHandler : S7_ZF_Handler {
    S7_PlayerMenu link;

    override void buttonCommand (S7_ZF_Button caller, string command) {
        if (command == "openXPSysMenu")
            Menu.SetMenu ("S7_XPSystemMenu");
        else if (command == "openLuciusShop")
            Menu.SetMenu ("S7_LuciusShopMenu");
        else if (command == "openWeapAssignMenu")
            Menu.SetMenu ("S7_WeapAssignMenu");
    }
}

class S7_PlayerMenu : S7_ZF_GenericMenu {
    S7_PlayerMenuHandler handler;

    PlayerInfo CPlayer;

    Font bigFont;
    Font smallFont;
    S7_ZF_Frame menusFrame;
    S7_ZF_Button xpSysButton, luciusShopButton, weapAssignButton;

    override void Init (Menu parent) {
        Super.Init (parent);
        SetBaseResolution ((640, 480));
        menuactive = Menu.OnNoPause;

        CPlayer = players [consolePlayer];

        handler = new ("S7_PlayerMenuHandler");
        handler.link = self;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('SmallFont');

        menusFrame = new ("S7_ZF_Frame").Init ((0, 0), (640, 480));
        menusFrame.Pack (mainFrame);

        string labelText = StringTable.Localize ("$PLAYERMENUHEADER", true);
        S7_ZF_Label label = new ("S7_ZF_Label").Init ((0, 12), (0, bigFont.GetHeight ()), labelText, bigFont, false, true, 1, Font.CR_WHITE);
        label.box.pos.X = 320.0 - (bigFont.stringWidth (labelText) / 2.0);
        label.Pack (menusFrame);

        string btnText = StringTable.Localize ("$PLAYERMENU_XPMENU", true);
        int btnTextWidth = smallFont.StringWidth (btnText), btnTextHeight = smallFont.GetHeight ();
        xpSysButton = new ("S7_ZF_Button").Init (((640 - btnTextWidth) / 2, ((480 - btnTextHeight) / 2) + 15), (btnTextWidth, btnTextHeight),
            btnText, handler, "openXPSysMenu", null, null, null, null);
        xpSysButton.SetTexture ("", "", "", "");
        xpSysButton.Pack (menusFrame);

        btnText = StringTable.Localize ("$PLAYERMENU_LUCIUSSHOP", true);
        btnTextWidth = smallFont.StringWidth (btnText); btnTextHeight = smallFont.GetHeight ();
        luciusShopButton = new ("S7_ZF_Button").Init (((640 - btnTextWidth) / 2, xpSysButton.box.pos.Y + ((btnTextHeight / 2) + 8)), (btnTextWidth, btnTextHeight),
            btnText, handler, "openLuciusShop", null, null, null, null);
        luciusShopButton.SetTexture ("", "", "", "");
        luciusShopButton.Pack (menusFrame);

        btnText = StringTable.Localize ("$PLAYERMENU_WEAPASSIGN", true);
        btnTextWidth = smallFont.StringWidth (btnText); btnTextHeight = smallFont.GetHeight ();
        weapAssignButton = new ("S7_ZF_Button").Init (((640 - btnTextWidth) / 2, luciusShopButton.box.pos.Y + ((btnTextHeight / 2) + 8)), (btnTextWidth, btnTextHeight),
            btnText, handler, "openWeapAssignMenu", null, null, null, null);
        weapAssignButton.SetTexture ("", "", "", "");
        weapAssignButton.Pack (menusFrame);

        //dontDim = true;
    }

    override void Ticker () {
        Super.Ticker ();
        menuactive = Menu.OnNoPause;

        if (!CPlayer || !CPlayer.mo || CPlayer.mo.health < 1) {
            self.Close ();
            return;
        }

        xpSysButton.textColor      = (     xpSysButton.isHovered ? Font.CR_RED : Font.CR_WHITE);
        luciusShopButton.textColor = (luciusShopButton.isHovered ? Font.CR_RED : Font.CR_WHITE);
        weapAssignButton.textColor = (weapAssignButton.isHovered ? Font.CR_RED : Font.CR_WHITE);
    }
}
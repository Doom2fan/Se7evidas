class S7_XPSystemMenu : GenericMenu {
    S7_XPSystemMenuElement e;

    override void Init (Menu parent) {
        Super.Init (parent);
        dontDim = true;
        e = S7_XPSystemMenuElement (new ('S7_XPSystemMenuElement').Init ());
        e.CPlayer = players [consoleplayer];
    }

    override void Ticker () {
        super.Ticker ();
        if (e) e.OnTick();
    }

    override void Drawer () {
        if (e) e.OnDraw ();
    }

    override bool OnUIEvent (UIEvent ev) {
        if (e) return e.OnProcessUi (ev);
        return false;
    }

    override bool OnInputEvent (InputEvent ev) {
        if (e) return e.OnProcessInput (ev);
        return false;
    }

    override bool MenuEvent (int mkey, bool fromcontroller) {
        if (e && e.MenuEvent (mkey, fromcontroller))
            return true;
        return Menu.MenuEvent (mkey, fromcontroller);
    }
}

class S7_XPSystemMenuElement : S7_BaseMenu {
    Font SmallFont;

    PlayerInfo CPlayer;
    int strengthAdd, agilityAdd, vitalityAdd, defenseAdd, willAdd, magicAdd, techAdd;

    // Labels
    S7_Menu_Label lStrength; S7_Menu_Label lStrengthBase; S7_Menu_Label lStrengthAdded;
    S7_Menu_Label lAgility;  S7_Menu_Label lAgilityBase;  S7_Menu_Label lAgilityAdded;
    S7_Menu_Label lVitality; S7_Menu_Label lVitalityBase; S7_Menu_Label lVitalityAdded;
    S7_Menu_Label lDefense;  S7_Menu_Label lDefenseBase;  S7_Menu_Label lDefenseAdded;
    S7_Menu_Label lWill;     S7_Menu_Label lWillBase;     S7_Menu_Label lWillAdded;
    S7_Menu_Label lMagic;    S7_Menu_Label lMagicBase;    S7_Menu_Label lMagicAdded;
    S7_Menu_Label lTech;     S7_Menu_Label lTechBase;     S7_Menu_Label lTechAdded;
    // Buttons
    S7_Menu_Button bStrengthAdd; S7_Menu_Button bStrengthSub;
    S7_Menu_Button bAgilityAdd;  S7_Menu_Button bAgilitySub;
    S7_Menu_Button bVitalityAdd; S7_Menu_Button bVitalitySub;
    S7_Menu_Button bDefenseAdd;  S7_Menu_Button bDefenseSub;
    S7_Menu_Button bWillAdd;     S7_Menu_Button bWillSub;
    S7_Menu_Button bMagicAdd;    S7_Menu_Button bMagicSub;
    S7_Menu_Button bTechAdd;     S7_Menu_Button bTechSub;
    S7_Menu_Button bReset;
    S7_Menu_Button bAccept;

    private int selectedButton;
    private Array<S7_Menu_Button> mButtons;
    private S7_Menu_Label AddLabel (string text, Vector2 coords) {
        S7_Menu_Label label = new ('S7_Menu_Label');
        label.Init ();
        AddChild (label);
        label.mRect = Rect.FromXYWH (coords.x, coords.y, SmallFont.StringWidth (text), SmallFont.GetHeight ());
        label.Text = text;

        return label;
    }
    private S7_Menu_Button AddButton (string text, Vector2 coords) {
        S7_Menu_Button button = new ('S7_Menu_Button');
        button.Init ();
        AddChild (button);
        button.mRect = Rect.FromXYWH (coords.x, coords.y, SmallFont.StringWidth (text), SmallFont.GetHeight ());
        button.Text = text;
        mButtons.Push (button);

        return button;
    }

    override void OnCreate () {
        mRect = Rect.FromXYWH (0, 0, Screen.GetWidth (), Screen.GetHeight ());
        mScale = max (1.0, Screen.GetWidth () / 800.0);

        selectedButton = 0;
        SmallFont = Font.GetFont ('SmallFont');

        // Labels
        lStrength = AddLabel ("Strength:", (140,  80)); lStrengthBase = AddLabel ("0", (220,  80)); lStrengthAdded = AddLabel ("+0", (250,  80));
        lAgility  = AddLabel ("Agility:",  (140,  90)); lAgilityBase  = AddLabel ("0", (220,  90)); lAgilityAdded  = AddLabel ("+0", (250,  90));
        lVitality = AddLabel ("Vitality:", (140, 100)); lVitalityBase = AddLabel ("0", (220, 100)); lVitalityAdded = AddLabel ("+0", (250, 100));
        lDefense  = AddLabel ("Defense:",  (140, 110)); lDefenseBase  = AddLabel ("0", (220, 110)); lDefenseAdded  = AddLabel ("+0", (250, 110));
        lWill     = AddLabel ("Will:",     (140, 120)); lWillBase     = AddLabel ("0", (220, 120)); lWillAdded     = AddLabel ("+0", (250, 120));
        lMagic    = AddLabel ("Magic:",    (140, 130)); lMagicBase    = AddLabel ("0", (220, 130)); lMagicAdded    = AddLabel ("+0", (250, 130));
        lTech     = AddLabel ("Tech:",     (140, 140)); lTechBase     = AddLabel ("0", (220, 140)); lTechAdded     = AddLabel ("+0", (250, 140));
        // Buttons
        bStrengthAdd = AddButton ("+", (280,  80)); bStrengthSub = AddButton ("-", (285,  80));
        bAgilityAdd  = AddButton ("+", (280,  90)); bAgilitySub  = AddButton ("-", (285,  90));
        bVitalityAdd = AddButton ("+", (280, 100)); bVitalitySub = AddButton ("-", (285, 100));
        bDefenseAdd  = AddButton ("+", (280, 110)); bDefenseSub  = AddButton ("-", (285, 110));
        bWillAdd     = AddButton ("+", (280, 120)); bWillSub     = AddButton ("-", (285, 120));
        bMagicAdd    = AddButton ("+", (280, 130)); bMagicSub    = AddButton ("-", (285, 130));
        bTechAdd     = AddButton ("+", (280, 140)); bTechSub     = AddButton ("-", (285, 140));
        bAccept = AddButton ("Back", (150, 160));
        bReset = AddButton ("Reset", (220, 160));
    }

    override void Draw () {
        Rect r = GetClientRect ();
        Drawer d = GetDrawer ();

        d.Dim (0x000000, 0.5, 0, 0, r.Width, r.Height);
    }

    void SetStatLabel (out S7_Menu_Label label, string text, int fontHeight) {
        label.Text = text;
        label.mRect.Width = SmallFont.StringWidth (text);
        label.mRect.Height = fontHeight;
    }
    override void Tick () {
        if (!CPlayer || !CPlayer.mo)
            return;

        int fontHeight = SmallFont.GetHeight ();
        int totalStatsAdded = strengthAdd + agilityAdd + vitalityAdd + defenseAdd + willAdd + magicAdd + techAdd;
        let xpSys = S7_XPSystemWorker (CPlayer.mo.FindInventory ("S7_XPSystemWorker"));

        bReset.IsEnabled = !(totalStatsAdded < 1);
        bAccept.Text = ((totalStatsAdded < 1) ? "Back" : "Confirm");
        bAccept.mRect = Rect.FromXYWH (bAccept.mRect.x, bAccept.mRect.y, SmallFont.StringWidth (bAccept.Text), fontHeight);

        SetStatLabel (lStrengthBase, String.Format ("%d", xpSys.strengthStat), fontHeight); SetStatLabel (lStrengthAdded, String.Format ("+%d", strengthAdd), fontHeight);
        SetStatLabel (lAgilityBase,  String.Format ("%d", xpSys.agilityStat),  fontHeight); SetStatLabel (lAgilityAdded,  String.Format ("+%d", agilityAdd),  fontHeight);
        SetStatLabel (lVitalityBase, String.Format ("%d", xpSys.vitalityStat), fontHeight); SetStatLabel (lVitalityAdded, String.Format ("+%d", vitalityAdd), fontHeight);
        SetStatLabel (lDefenseBase,  String.Format ("%d", xpSys.defenseStat),  fontHeight); SetStatLabel (lDefenseAdded,  String.Format ("+%d", defenseAdd),  fontHeight);
        SetStatLabel (lWillBase,     String.Format ("%d", xpSys.willStat),     fontHeight); SetStatLabel (lWillAdded,     String.Format ("+%d", willAdd),     fontHeight);
        SetStatLabel (lMagicBase,    String.Format ("%d", xpSys.magicStat),    fontHeight); SetStatLabel (lMagicAdded,    String.Format ("+%d", magicAdd),    fontHeight);
        SetStatLabel (lTechBase,     String.Format ("%d", xpSys.techStat),     fontHeight); SetStatLabel (lTechAdded,     String.Format ("+%d", techAdd),     fontHeight);

        if (bStrengthAdd.CheckClicked () && totalStatsAdded < xpSys.attrPoints) strengthAdd++;
        else if (bStrengthSub.CheckClicked () && strengthAdd > 0) strengthAdd--;

        if (bAgilityAdd.CheckClicked () && totalStatsAdded < xpSys.attrPoints) agilityAdd++;
        else if (bAgilitySub.CheckClicked () && agilityAdd > 0) agilityAdd--;

        if (bVitalityAdd.CheckClicked () && totalStatsAdded < xpSys.attrPoints) vitalityAdd++;
        else if (bVitalitySub.CheckClicked () && vitalityAdd > 0) vitalityAdd--;

        if (bDefenseAdd.CheckClicked () && totalStatsAdded < xpSys.attrPoints) defenseAdd++;
        else if (bDefenseSub.CheckClicked () && defenseAdd > 0) defenseAdd--;

        if (bWillAdd.CheckClicked () && totalStatsAdded < xpSys.attrPoints) willAdd++;
        else if (bWillSub.CheckClicked () && willAdd > 0) willAdd--;

        if (bMagicAdd.CheckClicked () && totalStatsAdded < xpSys.attrPoints) magicAdd++;
        else if (bMagicSub.CheckClicked () && magicAdd > 0) magicAdd--;

        if (bTechAdd.CheckClicked () && totalStatsAdded < xpSys.attrPoints) techAdd++;
        else if (bTechSub.CheckClicked () && techAdd > 0) techAdd--;


        if (bReset.CheckClicked ())
            strengthAdd = agilityAdd = vitalityAdd = defenseAdd = willAdd = magicAdd = techAdd = 0;
        if (bAccept.CheckClicked ()) {
            if (totalStatsAdded > 0) {
                if (totalStatsAdded <= xpSys.attrPoints) {
                    EventHandler.SendNetworkEvent (String.Format ("S7_XPSysMenuConfirm:%d,%d,%d,%d,%d,%d,%d", strengthAdd, agilityAdd, vitalityAdd, defenseAdd, willAdd, magicAdd, techAdd));
                    strengthAdd = agilityAdd = vitalityAdd = defenseAdd = willAdd = magicAdd = techAdd = 0;
                }
            } else
                Menu.GetCurrentMenu().Close();
        }
    }

    override void SetFocus (Element control) {
        if (control == null) { // Probably just a very small increase in performance, but whatever
            selectedButton = 0;
            for (int i = 0; i < mButtons.Size (); i++)
                mButtons [i].IsFocused = false;
        } else {
            for (int i = 0; i < mButtons.Size (); i++) {
                bool theButton = (mButtons [i] == control);
                mButtons [i].IsFocused = theButton;
                if (theButton)
                    selectedButton = i;
            }
        }
    }

    bool MenuEvent (int mkey, bool fromcontroller) {
        switch (mkey) {
            case Menu.MKEY_Up:
                if (selectedButton > 0) {
                    do {
                        selectedButton--;
                    } while (selectedButton > 0 && !mButtons [selectedButton].IsEnabled);
                }

                SetFocus (mButtons [selectedButton]);
                return true;

            case Menu.MKEY_Down:
                if (selectedButton < mButtons.Size () - 1) {
                    do {
                        selectedButton++;
                    } while (selectedButton < mButtons.Size () && !mButtons [selectedButton].IsEnabled);
                }

                SetFocus (mButtons [selectedButton]);
                return true;

            case Menu.MKEY_Enter:
                mButtons [selectedButton].Click ();
                return true;
        }

        return false;
    }
}

class S7_XPSysMenuEventHandler : EventHandler {
    override void NetworkProcess (ConsoleEvent e) {
        if (e.IsManual || e.Player < 0) // Don't execute this if it was called manually or the player isn't given/valid
            return;
        if (!playeringame [e.Player] || !players [e.Player].mo) // Don't execute if the player isn't ingame, the player is null or the player's PlayerPawn is null
            return;

        let xpSys = S7_XPSystemWorker (players [e.Player].mo.FindInventory ("S7_XPSystemWorker"));
        SplitResult strings;
        strings = S7_Extensions.Split (e.Name, ":");
        if (strings.Result.Size () != 2 || strings.Result [0] != "S7_XPSysMenuConfirm") // Return if the array doesn't contain exactly two strings or the first string isn't "S7_XPSysMenuConfirm"
            return;

        strings = S7_Extensions.Split (strings.Result [1], ",");
        if (strings.Result.Size () != 7) // Return if the array doesn't contain exactly seven strings
            return;

        int strengthAdd = strings.Result [0].ToInt (),
            agilityAdd  = strings.Result [1].ToInt (),
            vitalityAdd = strings.Result [2].ToInt (),
            defenseAdd  = strings.Result [3].ToInt (),
            willAdd     = strings.Result [4].ToInt (),
            magicAdd    = strings.Result [5].ToInt (),
            techAdd     = strings.Result [6].ToInt ();
        int totalStatsAdded = strengthAdd + agilityAdd + vitalityAdd + defenseAdd + willAdd + magicAdd + techAdd;

        if (totalStatsAdded > xpSys.attrPoints) // Return if we're trying to spend more attribute points than we have
            return;

        xpSys.strengthStat += strengthAdd; // Add the attribute points to the stats
        xpSys.agilityStat  += agilityAdd;
        xpSys.vitalityStat += vitalityAdd;
        xpSys.defenseStat  += defenseAdd;
        xpSys.willStat     += willAdd;
        xpSys.magicStat    += magicAdd;
        xpSys.techStat     += techAdd;
        xpSys.attrPoints -= totalStatsAdded; // Remove attribute points used up
    }
}
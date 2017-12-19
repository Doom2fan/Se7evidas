class S7_XPSystemMenuHandler : S7_ZF_Handler {
    S7_XPSystemMenu link;

    override void buttonCommand (S7_ZF_Button button, string command) {
        if (command.IndexOf (":") < 0) {
            if (command == "AcceptButton")
                AcceptStats ();
            else if (command == "ResetButton")
                ResetStatAdds ();
        } else {
            Array<String> commandStrings;
            command.Split (commandStrings, ":");

            if (commandStrings.Size () == 2) {
                if (commandStrings [0] == "StatAdd")
                    GiveStat (commandStrings [1], false);
                else if (commandStrings [0] == "StatDec")
                    GiveStat (commandStrings [1], true);
            }
        }
    }

    void ResetStatAdds () {
        link.strengthAdd = link.agilityAdd = link.vitalityAdd = link.defenseAdd = link.willAdd = link.magicAdd = link.techAdd = 0;
    }

    void AcceptStats () {
        int statsTotal = link.strengthAdd + link.agilityAdd + link.vitalityAdd + link.defenseAdd + link.willAdd + link.magicAdd + link.techAdd;
        if (statsTotal > 0) {
            string xpData = String.Format ("S7_XPSysMenuConfirm:%d,%d,%d,%d,%d,%d,%d", link.strengthAdd, link.agilityAdd, link.vitalityAdd, link.defenseAdd, link.willAdd, link.magicAdd, link.techAdd);
            EventHandler.SendNetworkEvent (xpData);
            ResetStatAdds ();
        } else
            link.Close ();
    }

    void GiveStat (string stat, bool take) {
        if (!link.CPlayer || !link.CPlayer.mo)
            return;

        let xpSys = S7_XPSystemWorker (link.CPlayer.mo.FindInventory ("S7_XPSystemWorker"));
        int amount = take ? -1 : 1;

        if (!xpSys)
            return;

        if (!take) {
            int statsTotal = link.strengthAdd + link.agilityAdd + link.vitalityAdd + link.defenseAdd + link.willAdd + link.magicAdd + link.techAdd;
            if (statsTotal >= xpSys.attrPoints)
                return;
        }

        if (stat == "Strength" && (!take || link.strengthAdd > 0))
            link.strengthAdd += amount;
        if (stat == "Agility" && (!take || link.agilityAdd > 0))
            link.agilityAdd += amount;
        if (stat == "Vitality" && (!take || link.vitalityAdd > 0))
            link.vitalityAdd += amount;
        if (stat == "Defense" && (!take || link.defenseAdd > 0))
            link.defenseAdd += amount;
        if (stat == "Will" && (!take || link.willAdd > 0))
            link.willAdd += amount;
        if (stat == "Magic" && (!take || link.magicAdd > 0))
            link.magicAdd += amount;
        if (stat == "Tech" && (!take || link.techAdd > 0))
            link.techAdd += amount;
    }
}

class S7_XPSystemMenu : S7_ZF_GenericMenu {
    S7_XPSystemMenuHandler handler;

    PlayerInfo CPlayer;
    int strengthAdd, agilityAdd, vitalityAdd, defenseAdd, willAdd, magicAdd, techAdd;

    Font bigFont;
    Font smallFont;
    S7_ZF_Frame statsFrame;
    S7_ZF_Label statLabels [7];
    S7_ZF_Label statBaseLabels [7];
    S7_ZF_Label statAddLabels [7];
    S7_ZF_Button statButtons [2] [7];
    S7_ZF_Button resetButton, acceptButton;
    static const String statNames [] = {
        "Strength", "Agility", "Vitality", "Defense", "Will", "Magic", "Tech"
    };
    override void Init (Menu parent) {
        Super.Init (parent);
        SetBaseResolution ((640, 480));

        CPlayer = players [consolePlayer];

        handler = new ("S7_XPSystemMenuHandler");
        handler.link = self;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('SmallFont');

        statsFrame = new ("S7_ZF_Frame").Init ((0, 0), (640, 240));
        statsFrame.Pack (mainFrame);

        for (int i = 0; i < 7; i++) {
            double yCoords = 80 + (13 * i);
            string statName = statNames [i];

            statLabels [i] = new ("S7_ZF_Label").Init ((140, yCoords + 1), (0, SmallFont.GetHeight ()), String.Format ("%s:", statName), smallFont, false, true, 1, Font.CR_WHITE);
            statLabels [i].Pack (statsFrame);
            statBaseLabels [i] = new ("S7_ZF_Label").Init ((220, yCoords + 1), (0, SmallFont.GetHeight ()), "0", smallFont, false, true, 1, Font.CR_WHITE);
            statBaseLabels [i].Pack (statsFrame);
            statAddLabels [i] = new ("S7_ZF_Label").Init ((250, yCoords + 1), (0, SmallFont.GetHeight ()), "+0", smallFont, false, true, 1, Font.CR_WHITE);
            statAddLabels [i].Pack (statsFrame);

            statButtons [i] [0] = new ("S7_ZF_Button").Init ((280, yCoords), (13, 11), "+", handler, String.Format ("StatAdd:%s", statName), null, null, null, null);
            statButtons [i] [0].SetTexture ("graphics/Menu/Generic/SmallButton.png", "graphics/Menu/Generic/SmallButtonHover.png", "graphics/Menu/Generic/SmallButtonPressed.png", "");
            statButtons [i] [0].Pack (statsFrame);
            statButtons [i] [1] = new ("S7_ZF_Button").Init ((300, yCoords), (13, 11), "-", handler, String.Format ("StatDec:%s", statName), null, null, null, null);
            statButtons [i] [1].SetTexture ("graphics/Menu/Generic/SmallButton.png", "graphics/Menu/Generic/SmallButtonHover.png", "graphics/Menu/Generic/SmallButtonPressed.png", "");
            statButtons [i] [1].Pack (statsFrame);
        }
        acceptButton = new ("S7_ZF_Button").Init ((180, 175), (62, 15), "Back", handler, "AcceptButton", null, null, null, null);
        acceptButton.SetTexture ("graphics/Menu/XPSys/StatButton.png", "graphics/Menu/XPSys/StatButtonHover.png", "graphics/Menu/XPSys/StatButtonPressed.png", "");
        acceptButton.Pack (statsFrame);
        resetButton = new ("S7_ZF_Button").Init ((245, 175), (62, 15), "Reset", handler, "ResetButton", null, null, null, null);
        resetButton.SetTexture ("graphics/Menu/XPSys/StatButton.png", "graphics/Menu/XPSys/StatButtonHover.png", "graphics/Menu/XPSys/StatButtonPressed.png", "");
        resetButton.Pack (statsFrame);

        //dontDim = true;
    }

    override void Ticker () {
        Super.Ticker ();

        if (!CPlayer || !CPlayer.mo)
            return;

        let xpSys = S7_XPSystemWorker (CPlayer.mo.FindInventory ("S7_XPSystemWorker"));

        if (!xpSys)
            return;

        int statsTotal = strengthAdd + agilityAdd + vitalityAdd + defenseAdd + willAdd + magicAdd + techAdd;
        if (statsTotal > 0)
            acceptButton.text = "Accept";
        else
            acceptButton.text = "Back";

        statBaseLabels [0].text = String.Format ("%d", xpSys.strengthStat); statAddLabels [0].text = String.Format ("+%d", strengthAdd);
        statBaseLabels [1].text = String.Format ("%d", xpSys.agilityStat);  statAddLabels [1].text = String.Format ("+%d", agilityAdd);
        statBaseLabels [2].text = String.Format ("%d", xpSys.vitalityStat); statAddLabels [2].text = String.Format ("+%d", vitalityAdd);
        statBaseLabels [3].text = String.Format ("%d", xpSys.defenseStat);  statAddLabels [3].text = String.Format ("+%d", defenseAdd);
        statBaseLabels [4].text = String.Format ("%d", xpSys.willStat);     statAddLabels [4].text = String.Format ("+%d", willAdd);
        statBaseLabels [5].text = String.Format ("%d", xpSys.magicStat);    statAddLabels [5].text = String.Format ("+%d", magicAdd);
        statBaseLabels [6].text = String.Format ("%d", xpSys.techStat);     statAddLabels [6].text = String.Format ("+%d", techAdd);
    }
}

class S7_XPSysMenuEventHandler : EventHandler {
    override void NetworkProcess (ConsoleEvent e) {
        if (e.IsManual || e.Player < 0) // Don't execute this if it was called manually or the player isn't given/valid
            return;
        if (!playeringame [e.Player] || !players [e.Player].mo) // Don't execute if the player isn't ingame, the player is null or the player's PlayerPawn is null
            return;

        let xpSys = S7_XPSystemWorker (players [e.Player].mo.FindInventory ("S7_XPSystemWorker"));
        Array<String> strings;
        e.Name.Split (strings, ":");
        if (strings.Size () != 2 || strings [0] != "S7_XPSysMenuConfirm") // Return if the array doesn't contain exactly two strings or the first string isn't "S7_XPSysMenuConfirm"
            return;

        string values = strings [1];
        strings.Clear ();
        values.Split (strings, ",");
        if (strings.Size () != 7) // Return if the array doesn't contain exactly seven strings
            return;

        int strengthAdd = strings [0].ToInt (),
            agilityAdd  = strings [1].ToInt (),
            vitalityAdd = strings [2].ToInt (),
            defenseAdd  = strings [3].ToInt (),
            willAdd     = strings [4].ToInt (),
            magicAdd    = strings [5].ToInt (),
            techAdd     = strings [6].ToInt ();
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
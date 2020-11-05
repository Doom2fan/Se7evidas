/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2019 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

class S7_XPSystemMenuHandler : S7_ZF_Handler {
    S7_XPSystemMenu link;

    override void buttonClickCommand (S7_ZF_Button caller, string command) {
        if (command.IndexOf (":") < 0) {
            if (command == "AcceptButton")
                AcceptStats ();
            else if (command == "ResetButton") {
                ResetStatAdds ();
                Menu.MenuSound ("S7Menu/Choose");
            }
        } else {
            Array<String> commandStrings; commandStrings.Clear ();
            command.Split (commandStrings, ":");

            if (commandStrings.Size () == 2) {
                if (commandStrings [0] == "StatAdd")
                    GiveStat (commandStrings [1], false);
                else if (commandStrings [0] == "StatDec")
                    GiveStat (commandStrings [1], true);
            }
        }
    }

    override void buttonHeldCommand (S7_ZF_Button caller, string command) {
        if (command.IndexOf (":") < 0)
            return;

        Array<String> commandStrings; commandStrings.Clear ();
        command.Split (commandStrings, ":");

        if (commandStrings.Size () == 2 && link.buttonHeldTics++ > 8) {
            if (commandStrings [0] == "StatAdd")
                GiveStat (commandStrings [1], false);
            else if (commandStrings [0] == "StatDec")
                GiveStat (commandStrings [1], true);
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
            Menu.MenuSound ("S7Menu/Close");
        } else {
            link.Close ();
            Menu.MenuSound ("S7Menu/PrevMenu");
        }
    }

    void GiveStat (string stat, bool take) {
        if (!link.CPlayer || !link.CPlayer.mo)
            return;

        let xpSys = S7_PlayerXPSystem (link.CPlayer.mo.FindInventory ('S7_PlayerXPSystem'));
        int amount = take ? -1 : 1;

        if (!xpSys)
            return;

        if (!take) {
            int statsTotal = link.strengthAdd + link.agilityAdd + link.vitalityAdd + link.defenseAdd + link.willAdd + link.magicAdd + link.techAdd;
            if (statsTotal >= xpSys.attrPoints)
                return;
        }

        Menu.MenuSound ("S7Menu/SliderMove");

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
    S7_ZF_Image background;
    S7_ZF_Label tooltipLabel;

    S7_ZF_Label statLabels [7];
    S7_ZF_Label statBaseLabels [7];
    S7_ZF_Label statAddLabels [7];
    S7_ZF_Button statButtons [7] [2];

    S7_ZF_Button resetButton, acceptButton;

    int buttonHeldTics;

    static const String statNames [] = {
        "Strength", "Agility", "Vitality", "Defense", "Will", "Magic", "Tech"
    };

    override void Init (Menu parent) {
        Super.Init (parent);
        SetBaseResolution ((640, 480));

        CPlayer = players [consolePlayer];

        handler = new ('S7_XPSystemMenuHandler');
        handler.link = self;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        string labelText = StringTable.Localize ("$STATSMENUHEADER", true);
        S7_ZF_Label label = new ('S7_ZF_Label').Init ((0, 12), (0, bigFont.GetHeight ()), text: labelText, fnt: bigFont, wrap: false, autoSize: true, textColor: Font.CR_White);
        label.box.pos.X = 320.0 - (bigFont.stringWidth (labelText) / 2.0);
        label.Pack (mainFrame);

        background = new ('S7_ZF_Image').Init ((25, 50), (590, 400), "graphics/Menu/Generic/Background.png", S7_ZF_Image.AlignType_TopLeft);
        background.Pack (mainFrame);

        statsFrame = new ('S7_ZF_Frame').Init ((35, 60), (200, 200));
        statsFrame.Pack (mainFrame);

        for (int i = 0; i < statNames.Size (); i++) {
            double yCoords = (13 * i);
            string statName = statNames [i];
            string statText = statNames [i];
            statText = statText.MakeUpper ();
            statText = StringTable.Localize ("$STATSMENU_" .. statText, true);

            statLabels [i] = new ('S7_ZF_Label').Init (
                (0, yCoords + 1), (0, SmallFont.GetHeight ()),
                text: String.Format ("%s:", statText),
                fnt: smallFont,
                wrap: false, autoSize: true,
                textColor: Font.CR_White
            );
            statLabels [i].cmdHandler = handler;
            statLabels [i].command = statNames [i];
            statLabels [i].Pack (statsFrame);

            statBaseLabels [i] = new ('S7_ZF_Label').Init (
                (80, yCoords + 1), (0, SmallFont.GetHeight ()),
                text: "0",
                fnt: smallFont,
                wrap: false, autoSize: true,
                textColor: Font.CR_White
            );
            statBaseLabels [i].Pack (statsFrame);

            statAddLabels [i] = new ('S7_ZF_Label').Init ((
                110, yCoords + 1), (0, SmallFont.GetHeight ()),
            text: "+0",
                fnt: smallFont,
                wrap: false, autoSize: true,
                textColor: Font.CR_White
            );
            statAddLabels [i].Pack (statsFrame);

            S7_ZF_BoxTextures smallButtonIdle, smallButtonHover, smallButtonClick;
            [smallButtonIdle, smallButtonHover, smallButtonClick] = S7_ZFMenuUtils.GetSmallButtonTexes ();

            statButtons [i] [0] = new ('S7_ZF_Button').Init (
                (140, yCoords), (13, 11),
                text: "+",
                cmdHandler: handler, command: String.Format ("StatAdd:%s", statName),
                fnt: smallFont,
                holdInterval: 1
            );
            statButtons [i] [0].SetTextures (smallButtonIdle, smallButtonHover, smallButtonClick, smallButtonIdle);
            statButtons [i] [0].Pack (statsFrame);

            statButtons [i] [1] = new ('S7_ZF_Button').Init (
                (160, yCoords), (13, 11),
                text: "-",
                cmdHandler: handler, command: String.Format ("StatDec:%s", statName),
                fnt: smallFont,
                holdInterval: 1
            );
            statButtons [i] [1].SetTextures (smallButtonIdle, smallButtonHover, smallButtonClick, smallButtonIdle);
            statButtons [i] [1].Pack (statsFrame);
        }

        let statButtonIdle = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/XPSys/StatButton.png", true);
        let statButtonHover = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/XPSys/StatButtonHover.png", true);
        let statButtonClick = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/XPSys/StatButtonPressed.png", true);

        acceptButton = new ('S7_ZF_Button').Init ((25, 95), (62, 15), text: "Back", cmdHandler: handler, command: "AcceptButton", fnt: smallFont);
        acceptButton.SetTextures (statButtonIdle, statButtonHover, statButtonClick, null);
        acceptButton.Pack (statsFrame);
        resetButton = new ('S7_ZF_Button').Init ((25 + 65, 95), (62, 15), text: "Reset", cmdHandler: handler, command: "ResetButton", fnt: smallFont);
        resetButton.SetTextures (statButtonIdle, statButtonHover, statButtonClick, null);
        resetButton.Pack (statsFrame);

        tooltipLabel = new ('S7_ZF_Label').Init ((0, 455), (640, 20), text: "", fnt: smallFont, alignment: S7_ZF_Label.AlignType_Center, wrap: true, autoSize: false, textColor: Font.CR_White);
        tooltipLabel.Pack (mainFrame);
    }

    override void Ticker () {
        Super.Ticker ();

        if (!CPlayer || !CPlayer.mo)
            return;

        let xpSys = S7_PlayerXPSystem (CPlayer.mo.FindInventory ('S7_PlayerXPSystem'));

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

        for (int i = 0; i < statButtons.Size (); i++)
            statButtons [i] [0].disabled = (statsTotal >= xpSys.attrPoints);

        statButtons [0] [1].disabled = (strengthAdd <= 0);
        statButtons [1] [1].disabled = (agilityAdd  <= 0);
        statButtons [2] [1].disabled = (vitalityAdd <= 0);
        statButtons [3] [1].disabled = (defenseAdd  <= 0);
        statButtons [4] [1].disabled = (willAdd     <= 0);
        statButtons [5] [1].disabled = (magicAdd    <= 0);
        statButtons [6] [1].disabled = (techAdd     <= 0);

        bool statButtonHeld = false;
        for (int i = 0; i < statButtons.Size (); i++) {
            for (int j = 0; j < 2; j++) {
                let statButton = statButtons [i] [j];

                statButton.textColor = (statButton.disabled ? Font.CR_DarkGray : Font.CR_White);
                statButtonHeld |= (statButton.curButtonState == S7_ZF_Button.ButtonState_Click);
            }
        }

        if (!statButtonHeld)
            buttonHeldTics = 0;

        for (int i = 0; i < statLabels.Size () + 1; i++) {
            if (i == statLabels.Size ()) {
                SetTooltip ("");
                break;
            }

            if (statLabels [i].isHovered) {
                SetTooltip (StringTable.Localize ("$STATSMENU_TOOLTIP_" .. statLabels [i].command));
                break;
            }
        }
    }

    void SetTooltip (string text) {
        if (tooltipLabel)
            tooltipLabel.text = text;
    }
}

class S7_XPSysMenuEventHandler : EventHandler {
    override void NetworkProcess (ConsoleEvent e) {
        if (e.IsManual || e.Player < 0) // Don't execute this if it was called manually or the player isn't given/valid
            return;
        if (!playeringame [e.Player] || !players [e.Player].mo) // Don't execute if the player isn't ingame, the player is null or the player's PlayerPawn is null
            return;

        let xpSys = S7_PlayerXPSystem (players [e.Player].mo.FindInventory ('S7_PlayerXPSystem'));
        Array<String> strings; strings.Clear ();
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
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

class S7_AutogunMenuHandler : S7_ZF_Handler {
    S7_AutogunMenu link;

    void ChangeScanAngle (int amount) {
        EventHandler.SendNetworkEvent ("S7_AutogunMenu:ScanAngleChange", amount);
        Menu.MenuSound ("S7Menu/SliderMove");
    }

    override void ButtonClickCommand (S7_ZF_Button caller, string command) {
        if (!link || !link.CPlayer || !link.CPlayer.mo)
            return;

        if (command == "scanAngleIncButton") {
            ChangeScanAngle (1);

            if (caller)
                caller.SetHoldTicInterval (15);
        } else if (command == "scanAngleDecButton") {
            ChangeScanAngle (-1);

            if (caller)
                caller.SetHoldTicInterval (15);
        } else if (command == "repairHealthButton")
            link.popup.Activate (link.GetRepairHealthText (), "RepairHealth");
        else if (command == "buyAmmoButton")
            link.popup.Activate (link.GetAmmoReplenishText (), "ReplenishAmmo");
        else if (command == "repairCorruptionButton")
            link.popup.Activate (link.GetRepairCorruptionText (), "RepairCorruption");

        if (command == "PopupAccept")
            link.PopupAccept (link.popup.popupCommand);
        else if (command == "PopupCancel")
            link.popup.Close ();
    }

    override void ButtonHeldCommand (S7_ZF_Button caller, string command) {
        if (!link || !link.CPlayer || !link.CPlayer.mo)
            return;

        if (command == "scanAngleIncButton") {
            ChangeScanAngle (1);

            if (caller)
                caller.SetHoldTicInterval (3);
        } else if (command == "scanAngleDecButton") {
            ChangeScanAngle (-1);

            if (caller)
                caller.SetHoldTicInterval (3);
        }
    }
}

class S7_AutogunMenu_EventHandler : EventHandler {
    override void NetworkProcess (ConsoleEvent e) {
        if (e.IsManual || e.Player < 0) // Don't execute this if it was called manually or the player isn't given/valid
            return;
        if (!playeringame [e.Player] || !players [e.Player].mo) // Don't execute if the player isn't ingame, the player is null or the player's PlayerPawn is null
            return;

        let pPawn = S7_BasePlayer (players [e.Player].mo);
        let inv = S7_M400AutogunStored (players [e.Player].mo.FindInventory ('S7_M400AutogunStored'));

        if (!pPawn || !inv)
            return;

        Array<String> strings; strings.Clear ();
        e.Name.Split (strings, ":");
        if (strings.Size () < 2 || strings [0] != "S7_AutogunMenu") // Return if the array has less than two strings or the first string isn't "S7_AutogunMenu"
            return;

        if (strings [1] == "ScanAngleChange") {
            inv.scanAngle = clamp (inv.scanAngle + e.Args [0], 10, 180);
        } else if (strings [1] == "RepairHealth") {
            int price, healAmount;

            [price, healAmount] = S7_AutogunMenu.GetHealthRepairInfo (pPawn);

            if (price < 1 || healAmount < 1)
                return;

            pPawn.TakeInventory ('S7_Cash', price);
            inv.integrity += healAmount;
        } else if (strings [1] == "ReplenishAmmo") {
            int price, ammoAmount;

            [price, ammoAmount] = S7_AutogunMenu.GetAmmoReplenishInfo (pPawn);

            if (price < 1 || ammoAmount < 1)
                return;

            pPawn.TakeInventory ('S7_Cash', price);
            inv.ammo += ammoAmount;
        } else if (strings [1] == "RepairCorruption") {
            int price, corruptionAmount;

            [price, corruptionAmount] = S7_AutogunMenu.GetRepairCorruptionInfo (pPawn);

            if (price < 1 || corruptionAmount < 1)
                return;

            pPawn.TakeInventory ('S7_Cash', price);
            inv.corruption -= corruptionAmount;
        }
    }
}

class S7_AutogunMenu : S7_ZF_GenericMenu {
    S7_AutogunMenuHandler handler;

    PlayerInfo CPlayer;

    Font bigFont;
    Font smallFont;

    S7_ZF_Frame menuFrame;
    S7_AutogunMenu_Popup popup;

    S7_ZF_Label healthLabel, ammoLabel, corruptionLabel;
    S7_ZF_Label healthCountLabel, ammoCountLabel, corruptionCountLabel;
    S7_ZF_Button repairHealthButton, buyAmmoButton, repairCorruptionButton;

    S7_ZF_Label scanAngleLabel;
    S7_ZF_Label scanAngleAmountLabel;
    S7_ZF_Button scanAngleInc, scanAngleDec;

    void ReportError (string error) {
        let errorLabel = S7_ZF_Label.Create ((0, 12), (0, bigFont.GetHeight ()), text: error, fnt: bigFont, wrap: false, autoSize: true, textColor: Font.CR_White);
        errorLabel.SetPos ((320.0 - (bigFont.StringWidth (error) / 2.0), (480.0 / 2.0) - bigFont.GetHeight ()));
        errorLabel.Pack (mainFrame);
        string labelText = "You shouldn't be seeing this";
        let label = S7_ZF_Label.Create ((0, 12), (0, smallFont.GetHeight ()), text: labelText, fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_White);
        label.SetPos ((320.0 - (smallFont.StringWidth (labelText) / 2.0), errorLabel.GetPosY () + bigFont.GetHeight () + 5));
        label.Pack (mainFrame);
    }

    override void Init (Menu parent) {
        Super.Init (parent);
        SetBaseResolution ((640, 480));
        menuactive = Menu.OnNoPause;

        CPlayer = players [consolePlayer];

        if (!CPlayer || !CPlayer.mo) {
            ReportError ("Invalid player");
            return;
        } else if (CPlayer.mo.health <= 0) {
            ReportError ("Dead player");
            return;
        }

        handler = new ('S7_AutogunMenuHandler');
        handler.link = self;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        string labelText = StringTable.Localize ("$AUTOGUNMENUHEADER", true);
        let header = S7_ZF_Label.Create ((0, 12), (0, bigFont.GetHeight ()), text: labelText, fnt: bigFont, wrap: false, autoSize: true, textColor: Font.CR_White);
        header.SetPosX (320.0 - (bigFont.stringWidth (labelText) / 2.0));
        header.Pack (mainFrame);

        menuFrame = S7_ZF_Frame.Create ((25, 50), (590, 400));
        menuFrame.Pack (mainFrame);

        popup = S7_AutogunMenu_Popup.CreatePopup (self, mainFrame, handler);

        let bgBox = S7_ZFMenuUtils.GetCommonMenuBG ();
        let background = S7_ZF_BoxImage.Create ((0, 0), (590, 400), textures: bgBox);
        background.Pack (menuFrame);

        double offs = (smallFont.GetHeight () + 10);
        int controlCount = 0;
        int bigButtonYOffs = -(int ((17. - smallFont.GetHeight ()) / 2.));
        int smallButtonYOffs = -(int ((11. - smallFont.GetHeight ()) / 2.));

        /** Button textures **/
        S7_ZF_BoxTextures smallButtonIdle, smallButtonHover, smallButtonClick;
        [smallButtonIdle, smallButtonHover, smallButtonClick] = S7_ZFMenuUtils.GetSmallButtonTexes ();
        let buyButtonIdle = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/Shop/BuyButton.png", true);
        let buyButtonHover = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/Shop/BuyButtonHover.png", true);
        let buyButtonClick = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/Shop/BuyButtonPressed.png", true);

        /** Integrity **/
        labelText = StringTable.Localize ("$AUTOGUNMENU_INTEGRITY", true);
        healthLabel = S7_ZF_Label.Create ((10, 10 + (offs * controlCount++)), (0, 0),
            text: String.Format ("%s: ", labelText),
            fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_White
        );
        healthLabel.Pack (menuFrame);

        healthCountLabel = S7_ZF_Label.Create (healthLabel.GetPos (), (0, 0), text: "", fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_White);
        healthCountLabel.Pack (menuFrame);

        labelText = StringTable.Localize ("$AUTOGUNMENU_REPAIR", true);
        repairHealthButton = S7_ZF_Button.Create (healthLabel.GetPos () + (0, bigButtonYOffs), (50, 17),
            labelText, cmdHandler: handler, command: "repairHealthButton", fnt: smallFont
        );
        repairHealthButton.SetTextures (buyButtonIdle, buyButtonHover, buyButtonClick, buyButtonIdle);
        repairHealthButton.Pack (menuFrame);

        /** Ammunition **/
        labelText = StringTable.Localize ("$AUTOGUNMENU_AMMO", true);
        ammoLabel = S7_ZF_Label.Create ((10, 10 + (offs * controlCount++)), (0, 0),
            text: String.Format ("%s: ", labelText),
            fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_White
        );
        ammoLabel.Pack (menuFrame);

        ammoCountLabel = S7_ZF_Label.Create (ammoLabel.GetPos (), (0, 0), text: "", fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_White);
        ammoCountLabel.Pack (menuFrame);

        labelText = StringTable.Localize ("$AUTOGUNMENU_BUY", true);
        buyAmmoButton = S7_ZF_Button.Create (ammoCountLabel.GetPos () + (0, bigButtonYOffs), (50, 17),
            labelText, cmdHandler: handler, command: "buyAmmoButton", fnt: smallFont
        );
        buyAmmoButton.SetTextures (buyButtonIdle, buyButtonHover, buyButtonClick, buyButtonIdle);
        buyAmmoButton.Pack (menuFrame);

        /** Corruption **/
        labelText = StringTable.Localize ("$AUTOGUNMENU_CORRUPTION", true);
        corruptionLabel = S7_ZF_Label.Create ((10, 10 + (offs * controlCount++)), (0, 0),
            text: String.Format ("%s: ", labelText),
            fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_White
        );
        corruptionLabel.Pack (menuFrame);

        corruptionCountLabel = S7_ZF_Label.Create (corruptionLabel.GetPos (), (0, 0), text: "", fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_White);
        corruptionCountLabel.Pack (menuFrame);

        labelText = StringTable.Localize ("$AUTOGUNMENU_REPAIR", true);
        repairCorruptionButton = S7_ZF_Button.Create (corruptionCountLabel.GetPos () + (0, bigButtonYOffs), (50, 17),
            labelText, cmdHandler: handler, command: "repairCorruptionButton", fnt: smallFont
        );
        repairCorruptionButton.SetTextures (buyButtonIdle, buyButtonHover, buyButtonClick, buyButtonIdle);
        repairCorruptionButton.Pack (menuFrame);

        /** Scan angle **/
        labelText = StringTable.Localize ("$AUTOGUNMENU_SCANANGLE", true);
        scanAngleLabel = S7_ZF_Label.Create ((10, 10 + (offs * controlCount++)), (0, 0),
            text: String.Format ("%s: ", labelText),
            fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_White
        );
        scanAngleLabel.Pack (menuFrame);

        scanAngleAmountLabel = S7_ZF_Label.Create (scanAngleLabel.GetPos (), (0, 0), text: "", fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_White);
        scanAngleAmountLabel.Pack (menuFrame);

        scanAngleInc = S7_ZF_Button.Create (scanAngleAmountLabel.GetPos () + (0, smallButtonYOffs), (13, 11),
            text: "+", cmdHandler: handler, command: "scanAngleIncButton", fnt: smallFont, holdInterval: 3);
        scanAngleInc.SetTextures (smallButtonIdle, smallButtonHover, smallButtonClick, smallButtonIdle);
        scanAngleInc.Pack (menuFrame);

        scanAngleDec = S7_ZF_Button.Create (scanAngleAmountLabel.GetPos () + (0, smallButtonYOffs), (13, 11),
            text: "-", cmdHandler: handler, command: "scanAngleDecButton", fnt: smallFont, holdInterval: 3);
        scanAngleDec.SetTextures (smallButtonIdle, smallButtonHover, smallButtonClick, smallButtonIdle);
        scanAngleDec.Pack (menuFrame);

        //dontDim = true;
    }

    static clearscope int, int GetHealthRepairInfo (PlayerPawn player) {
        let inv = S7_M400AutogunStored (player.FindInventory ('S7_M400AutogunStored'));

        if (!inv)
            return -1, -1;

        int healAmount = 500 - inv.integrity;
        int price = 5 * healAmount;

        if (price > player.CountInv ('S7_Cash')) {
            healAmount = player.CountInv ('S7_Cash') / 5;
            price = 5 * healAmount;
        }

        return price, healAmount;
    }

    string GetRepairHealthText () {
        return String.Format ("Repair turret for %d credits?", GetHealthRepairInfo (CPlayer.mo));
    }

    static clearscope int, int GetAmmoReplenishInfo (PlayerPawn player) {
        let inv = S7_M400AutogunStored (player.FindInventory ('S7_M400AutogunStored'));

        if (!inv)
            return -1, -1;

        int ammoAmount = 1000 - inv.ammo;
        int price = 2 * ammoAmount;

        if (price > player.CountInv ('S7_Cash')) {
            ammoAmount = player.CountInv ('S7_Cash') / 2;
            price = 2 * ammoAmount;
        }

        return price, ammoAmount;
    }

    string GetAmmoReplenishText () {
        return String.Format ("Replenish ammo for %d credits?", GetAmmoReplenishInfo (CPlayer.mo));
    }

    static clearscope int, int GetRepairCorruptionInfo (PlayerPawn player) {
        let inv = S7_M400AutogunStored (player.FindInventory ('S7_M400AutogunStored'));

        if (!inv)
            return -1, -1;

        int corruptionAmount = int (ceil (inv.corruption / 20.) * 20);
        int price = 50 * (corruptionAmount / 20);

        if (price > player.CountInv ('S7_Cash')) {
            corruptionAmount = (player.CountInv ('S7_Cash') / 50) * 20;
            price = 50 * (corruptionAmount / 20);
        }

        return price, corruptionAmount;
    }

    string GetRepairCorruptionText () {
        return String.Format ("Remove corruption for %d credits?", GetRepairCorruptionInfo (CPlayer.mo));
    }

    void PopupAccept (string command) {
        if (command == "RepairHealth") {
            EventHandler.SendNetworkEvent ("S7_AutogunMenu:RepairHealth");
            popup.Close ();
        } else if (command == "ReplenishAmmo") {
            EventHandler.SendNetworkEvent ("S7_AutogunMenu:ReplenishAmmo");
            popup.Close ();
        } else if (command == "RepairCorruption") {
            EventHandler.SendNetworkEvent ("S7_AutogunMenu:RepairCorruption");
            popup.Close ();
        }
    }

    void PopupUpdate (string command) {
        if (command == "RepairHealth")
            popup.SetText (GetRepairHealthText ());
        else if (command == "ReplenishAmmo") {
            popup.SetText (GetAmmoReplenishText ());
        } else if (command == "RepairCorruption")
            popup.SetText (GetRepairCorruptionText ());
    }

    override void Ticker () {
        menuactive = Menu.OnNoPause;

        if (!CPlayer || !CPlayer.mo) {
            Super.Ticker ();
            return;
        }

        let inv = S7_M400AutogunStored (CPlayer.mo.FindInventory ('S7_M400AutogunStored'));

        if (inv) {
            healthCountLabel.SetText (String.Format ("%d%", int ((inv.integrity / 500.) * 100.)));
            ammoCountLabel.SetText (String.Format ("%d", inv.ammo));
            corruptionCountLabel.SetText (String.Format ("%d", inv.corruption));
            scanAngleAmountLabel.SetText (String.Format ("%d", inv.scanAngle));

            repairHealthButton.SetTextColor (Font.CR_White);
            buyAmmoButton.SetTextColor (Font.CR_White);
            repairCorruptionButton.SetTextColor (Font.CR_White);

            if (inv.integrity >= 500) {
                repairHealthButton.Disable ();
                repairHealthButton.Hide ();
            } else {
                repairHealthButton.Enable ();
                repairHealthButton.Show ();
            }

            if (inv.ammo >= 1000) {
                buyAmmoButton.Disable ();
                buyAmmoButton.Hide ();
            } else {
                buyAmmoButton.Enable ();
                buyAmmoButton.Show ();
            }

            if (inv.corruption <= 0) {
                repairCorruptionButton.Disable ();
                repairCorruptionButton.Hide ();
            } else {
                repairCorruptionButton.Enable ();
                repairCorruptionButton.Show ();
            }

            if (inv.scanAngle >= 180.)
                scanAngleInc.Disable ();
            else
                scanAngleInc.Enable ();

            if (inv.scanAngle <= 10.)
                scanAngleDec.Disable ();
            else
                scanAngleDec.Enable ();
        }

        int cash = CPlayer.mo.CountInv ('S7_Cash');

        if (cash < 5) {
            repairHealthButton.SetTextColor (Font.CR_Red);
            repairHealthButton.Disable ();
        }
        if (cash < 2) {
            buyAmmoButton.SetTextColor (Font.CR_Red);
            buyAmmoButton.Disable ();
        }
        if (cash < 50) {
            repairCorruptionButton.SetTextColor (Font.CR_Red);
            repairCorruptionButton.Disable ();
        }

        Super.Ticker ();

        healthCountLabel.SetPosX (healthLabel.GetPosX () + healthLabel.GetWidth () + 5);
        ammoCountLabel.SetPosX (ammoLabel.GetPosX () + ammoLabel.GetWidth () + 5);
        corruptionCountLabel.SetPosX (corruptionLabel.GetPosX () + corruptionLabel.GetWidth () + 5);
        scanAngleAmountLabel.SetPosX (scanAngleLabel.GetPosX () + scanAngleLabel.GetWidth () + 5);

        repairHealthButton.SetPosX (healthLabel.GetPosX () + healthLabel.GetWidth () + 35);
        buyAmmoButton.SetPosX (ammoLabel.GetPosX () + ammoLabel.GetWidth () + 35);
        repairCorruptionButton.SetPosX (corruptionLabel.GetPosX () + corruptionLabel.GetWidth () + 35);
        scanAngleInc.SetPosX (scanAngleLabel.GetPosX () + scanAngleLabel.GetWidth () + 35);
        scanAngleDec.SetPosX (scanAngleInc.GetPosX () + scanAngleInc.GetWidth () + 2.5);
    }
}

class S7_AutogunMenu_Popup : S7_ZF_Frame {
    S7_AutogunMenuHandler handler;
    S7_AutogunMenu link;

    Font bigFont, smallFont;

    string popupCommand;

    S7_ZF_BoxImage background;
    S7_ZF_Label textLabel;
    S7_ZF_Button acceptButton, cancelButton;

    void Config (S7_AutogunMenu menuLink, S7_ZF_Frame frame, S7_AutogunMenuHandler handler) {
        alpha = 1;

        link = menuLink;
        self.handler = handler;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        let bgBox = S7_ZFMenuUtils.GetCommonMenuBG ();
        let background = S7_ZF_BoxImage.Create ((0, 0), (320, 80), textures: bgBox);
        background.Pack (self);

        textLabel = S7_ZF_Label.Create (
            (5, 5), (320 - 10, 80 - 10),
            text: "", fnt: smallFont,
            wrap: true, autoSize: true,
            textColor: Font.CR_White
        );
        textLabel.Pack (self);

        let popupButtonIdle = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/Shop/PopupButton.png", true);
        let popupButtonHover = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/Shop/PopupButtonHover.png", true);
        let popupButtonClick = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/Shop/PopupButtonPressed.png", true);

        acceptButton = S7_ZF_Button.Create (
            (196, 57), (55, 17),
            text: "Accept",
            cmdHandler: handler, command: "PopupAccept",
            fnt: smallFont
        );
        acceptButton.SetTextures (popupButtonIdle, popupButtonHover, popupButtonClick, popupButtonIdle);
        acceptButton.Pack (self);
        cancelButton = S7_ZF_Button.Create (
            (259, 57), (55, 17),
            text: StringTable.Localize ("$SS_CANCELBUTTON", true),
            cmdHandler: handler, command: "PopupCancel",
            fnt: smallFont
        );
        cancelButton.SetTextures (popupButtonIdle, popupButtonHover, popupButtonClick, popupButtonIdle);
        cancelButton.Pack (self);

        Hide ();
        Disable ();
        SetDontBlockMouse (true);
    }

    static S7_AutogunMenu_Popup CreatePopup (S7_AutogunMenu menuLink, S7_ZF_Frame frame, S7_AutogunMenuHandler handler) {
        let ret = new ('S7_AutogunMenu_Popup');

        ret.SetBox ((160, 200), (320, 80));
        ret.Pack (frame);
        ret.Config (menuLink, frame, handler);

        return ret;
    }

    override void Ticker () {
        Super.Ticker ();

        if (isEnabled ())
            link.PopupUpdate (popupCommand);
    }

    void Activate (string text, string command) {
        if (!link)
            return;

        link.menuFrame.Disable ();
        Show ();
        Enable ();
        SetDontBlockMouse (false);

        textLabel.SetText (text);
        popupCommand = command;

        Menu.MenuSound ("S7Menu/Open");
    }

    void SetText (string text) {
        textLabel.SetText (text);
    }

    void Close () {
        link.menuFrame.Enable ();
        Hide ();
        Disable ();
        SetDontBlockMouse (true);

        textLabel.SetText ("");
        popupCommand = "";
        Menu.MenuSound ("S7Menu/Close");
    }
}
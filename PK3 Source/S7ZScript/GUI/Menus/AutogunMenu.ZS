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

    override void buttonClickCommand (S7_ZF_Button caller, string command) {
        if (!link || !link.CPlayer || !link.CPlayer.mo)
            return;

        if (command == "scanAngleIncButton")
            ChangeScanAngle (1);
        else if (command == "scanAngleDecButton")
            ChangeScanAngle (-1);
        else if (command == "repairHealthButton")
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

    override void buttonHeldCommand (S7_ZF_Button caller, string command) {
        if (!link || !link.CPlayer || !link.CPlayer.mo)
            return;

        if (command == "scanAngleIncButton")
            ChangeScanAngle (1);
        else if (command == "scanAngleDecButton")
            ChangeScanAngle (-1);
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
        let errorLabel = new ('S7_ZF_Label').Init ((0, 12), (0, bigFont.GetHeight ()), text: error, fnt: bigFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE);
        errorLabel.box.pos = (320.0 - (bigFont.StringWidth (error) / 2.0), (480.0 / 2.0) - bigFont.GetHeight ());
        errorLabel.Pack (mainFrame);
        string labelText = "You shouldn't be seeing this";
        let label = new ('S7_ZF_Label').Init ((0, 12), (0, smallFont.GetHeight ()), text: labelText, fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE);
        label.box.pos = (320.0 - (smallFont.StringWidth (labelText) / 2.0), errorLabel.box.pos.y + bigFont.GetHeight () + 5);
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
        let header = new ('S7_ZF_Label').Init ((0, 12), (0, bigFont.GetHeight ()), text: labelText, fnt: bigFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE);
        header.box.pos.X = 320.0 - (bigFont.stringWidth (labelText) / 2.0);
        header.Pack (mainFrame);

        menuFrame = new ('S7_ZF_Frame').Init ((25, 50), (590, 400));
        menuFrame.Pack (mainFrame);

        popup = new ('S7_AutogunMenu_Popup').InitPopup (self, mainFrame, handler);

        let background = new ('S7_ZF_Image').Init ((0, 0), (590, 400), "graphics/Menu/Generic/Background.png", S7_ZF_Image.AlignType_TopLeft);
        background.Pack (menuFrame);

        double offs = (smallFont.GetHeight () + 10);
        int controlCount = 0;
        int bigButtonYOffs = -(int ((17. - smallFont.GetHeight ()) / 2.));
        int smallButtonYOffs = -(int ((11. - smallFont.GetHeight ()) / 2.));

        /** Integrity **/
        labelText = StringTable.Localize ("$AUTOGUNMENU_INTEGRITY", true);
        healthLabel = new ('S7_ZF_Label').Init ((10, 10 + (offs * controlCount++)), (0, 0),
            text: String.Format ("%s: ", labelText),
            fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE
        );
        healthLabel.Pack (menuFrame);

        healthCountLabel = new ('S7_ZF_Label').Init ((healthLabel.box.pos.x, healthLabel.box.pos.y), (0, 0), text: "", fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE);
        healthCountLabel.Pack (menuFrame);

        labelText = StringTable.Localize ("$AUTOGUNMENU_REPAIR", true);
        repairHealthButton = new ('S7_ZF_Button').Init ((healthLabel.box.pos.x, healthLabel.box.pos.y + bigButtonYOffs), (50, 17),
            labelText, cmdHandler: handler, command: "repairHealthButton", fnt: smallFont
        );
        repairHealthButton.SetTexture ("graphics/Menu/Shop/BuyButton.png", "graphics/Menu/Shop/BuyButtonHover.png", "graphics/Menu/Shop/BuyButtonPressed.png", "graphics/Menu/Shop/BuyButton.png");
        repairHealthButton.Pack (menuFrame);

        /** Ammunition **/
        labelText = StringTable.Localize ("$AUTOGUNMENU_AMMO", true);
        ammoLabel = new ('S7_ZF_Label').Init ((10, 10 + (offs * controlCount++)), (0, 0),
            text: String.Format ("%s: ", labelText),
            fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE
        );
        ammoLabel.Pack (menuFrame);

        ammoCountLabel = new ('S7_ZF_Label').Init ((ammoLabel.box.pos.x, ammoLabel.box.pos.y), (0, 0), text: "", fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE);
        ammoCountLabel.Pack (menuFrame);

        labelText = StringTable.Localize ("$AUTOGUNMENU_BUY", true);
        buyAmmoButton = new ('S7_ZF_Button').Init ((ammoCountLabel.box.pos.x, ammoCountLabel.box.pos.y + bigButtonYOffs), (50, 17),
            labelText, cmdHandler: handler, command: "buyAmmoButton", fnt: smallFont
        );
        buyAmmoButton.SetTexture ("graphics/Menu/Shop/BuyButton.png", "graphics/Menu/Shop/BuyButtonHover.png", "graphics/Menu/Shop/BuyButtonPressed.png", "graphics/Menu/Shop/BuyButton.png");
        buyAmmoButton.Pack (menuFrame);

        /** Corruption **/
        labelText = StringTable.Localize ("$AUTOGUNMENU_CORRUPTION", true);
        corruptionLabel = new ('S7_ZF_Label').Init ((10, 10 + (offs * controlCount++)), (0, 0),
            text: String.Format ("%s: ", labelText),
            fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE
        );
        corruptionLabel.Pack (menuFrame);

        corruptionCountLabel = new ('S7_ZF_Label').Init ((corruptionLabel.box.pos.x, corruptionLabel.box.pos.y), (0, 0), text: "", fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE);
        corruptionCountLabel.Pack (menuFrame);

        labelText = StringTable.Localize ("$AUTOGUNMENU_REPAIR", true);
        repairCorruptionButton = new ('S7_ZF_Button').Init ((corruptionCountLabel.box.pos.x, corruptionCountLabel.box.pos.y + bigButtonYOffs), (50, 17),
            labelText, cmdHandler: handler, command: "repairCorruptionButton", fnt: smallFont
        );
        repairCorruptionButton.SetTexture ("graphics/Menu/Shop/BuyButton.png", "graphics/Menu/Shop/BuyButtonHover.png", "graphics/Menu/Shop/BuyButtonPressed.png", "graphics/Menu/Shop/BuyButton.png");
        repairCorruptionButton.Pack (menuFrame);

        /** Scan angle **/
        labelText = StringTable.Localize ("$AUTOGUNMENU_SCANANGLE", true);
        scanAngleLabel = new ('S7_ZF_Label').Init ((10, 10 + (offs * controlCount++)), (0, 0),
            text: String.Format ("%s: ", labelText),
            fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE
        );
        scanAngleLabel.Pack (menuFrame);//scanAngleInc scanAngleDec

        scanAngleAmountLabel = new ('S7_ZF_Label').Init ((scanAngleLabel.box.pos.x, scanAngleLabel.box.pos.y), (0, 0), text: "", fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE);
        scanAngleAmountLabel.Pack (menuFrame);

        scanAngleInc = new ('S7_ZF_Button').Init ((scanAngleAmountLabel.box.pos.x, scanAngleAmountLabel.box.pos.y + smallButtonYOffs), (13, 11),
            text: "+", cmdHandler: handler, command: "scanAngleIncButton", fnt: smallFont, holdInterval: 3);
        scanAngleInc.SetTexture (
            "graphics/Menu/Generic/SmallButton.png",
            "graphics/Menu/Generic/SmallButtonHover.png",
            "graphics/Menu/Generic/SmallButtonPressed.png",
            "graphics/Menu/Generic/SmallButton.png"
        );
        scanAngleInc.Pack (menuFrame);

        scanAngleDec = new ('S7_ZF_Button').Init ((scanAngleAmountLabel.box.pos.x, scanAngleAmountLabel.box.pos.y + smallButtonYOffs), (13, 11),
            text: "-", cmdHandler: handler, command: "scanAngleDecButton", fnt: smallFont, holdInterval: 3);
        scanAngleDec.SetTexture (
            "graphics/Menu/Generic/SmallButton.png",
            "graphics/Menu/Generic/SmallButtonHover.png",
            "graphics/Menu/Generic/SmallButtonPressed.png",
            "graphics/Menu/Generic/SmallButton.png"
        );
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
        if (!CPlayer || !CPlayer.mo) {
            Super.Ticker ();
            return;
        }

        let inv = S7_M400AutogunStored (CPlayer.mo.FindInventory ('S7_M400AutogunStored'));

        if (inv) {
            healthCountLabel.text = String.Format ("%d%", int ((inv.integrity / 500.) * 100.));
            ammoCountLabel.text = String.Format ("%d", inv.ammo);
            corruptionCountLabel.text = String.Format ("%d", inv.corruption);
            scanAngleAmountLabel.text = String.Format ("%d", inv.scanAngle);

            repairHealthButton.disabled = (repairHealthButton.hidden = (inv.integrity >= 500));
            buyAmmoButton.disabled = (buyAmmoButton.hidden = (inv.ammo >= 1000));
            repairCorruptionButton.disabled = (repairCorruptionButton.hidden = (inv.corruption <= 0));
            scanAngleInc.disabled = (inv.scanAngle >= 180.);
            scanAngleDec.disabled = (inv.scanAngle <= 10.);
        }

        int cash = CPlayer.mo.CountInv ('S7_Cash');

        if (cash < 5) {
            repairHealthButton.textColor = Font.CR_RED;
            repairHealthButton.disabled = true;
        }
        if (cash < 2) {
            buyAmmoButton.textColor = Font.CR_RED;
            buyAmmoButton.disabled = true;
        }
        if (cash < 50) {
            repairCorruptionButton.textColor = Font.CR_RED;
            repairCorruptionButton.disabled = true;
        }

        Super.Ticker ();

        healthCountLabel.box.pos.X = (healthLabel.box.pos.x + healthLabel.box.size.x + 5);
        ammoCountLabel.box.pos.X = (ammoLabel.box.pos.x + ammoLabel.box.size.x + 5);
        corruptionCountLabel.box.pos.X = (corruptionLabel.box.pos.x + corruptionLabel.box.size.x + 5);
        scanAngleAmountLabel.box.pos.X = (scanAngleLabel.box.pos.x + scanAngleLabel.box.size.x + 5);

        repairHealthButton.box.pos.X = (healthLabel.box.pos.x + healthLabel.box.size.x + 35);
        buyAmmoButton.box.pos.X = (ammoLabel.box.pos.x + ammoLabel.box.size.x + 35);
        repairCorruptionButton.box.pos.X = (corruptionLabel.box.pos.x + corruptionLabel.box.size.x + 35);
        scanAngleInc.box.pos.X = (scanAngleLabel.box.pos.x + scanAngleLabel.box.size.x + 35);
        scanAngleDec.box.pos.X = (scanAngleInc.box.pos.x + scanAngleInc.box.size.x + 2.5);
    }
}

class S7_AutogunMenu_Popup : S7_ZF_Frame {
    S7_AutogunMenuHandler handler;
    S7_AutogunMenu link;

    Font bigFont, smallFont;

    string popupCommand;

    S7_ZF_Image background;
    S7_ZF_Label textLabel;
    S7_ZF_Button acceptButton, cancelButton;

    S7_AutogunMenu_Popup InitPopup (S7_AutogunMenu menuLink, S7_ZF_Frame frame, S7_AutogunMenuHandler handler) {
        self.Init ((160, 200), (320, 80));
        self.Pack (frame);
        link = menuLink;
        self.handler = handler;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        background = new ('S7_ZF_Image').Init ((0, 0), (320, 80), "graphics/Menu/Shop/BuySellPopup.png", S7_ZF_Image.AlignType_TopLeft);
        background.Pack (self);

        textLabel = new ('S7_ZF_Label').Init ((5, 5), (320 - 10, 80 - 10),
            text: "", fnt: smallFont, wrap: true, autoSize: true, textColor: Font.CR_WHITE);
        textLabel.Pack (self);

        acceptButton = new ('S7_ZF_Button').Init ((196, 57), (55, 17), text: "Accept", cmdHandler: handler, command: "PopupAccept", fnt: smallFont);
        acceptButton.SetTexture ("graphics/Menu/Shop/PopupButton.png", "graphics/Menu/Shop/PopupButtonHover.png", "graphics/Menu/Shop/PopupButtonPressed.png", "graphics/Menu/Shop/PopupButton.png");
        acceptButton.Pack (self);
        cancelButton = new ('S7_ZF_Button').Init ((259, 57), (55, 17), text: StringTable.Localize ("$SS_CANCELBUTTON", true), cmdHandler: handler, command: "PopupCancel", fnt: smallFont);
        cancelButton.SetTexture ("graphics/Menu/Shop/PopupButton.png", "graphics/Menu/Shop/PopupButtonHover.png", "graphics/Menu/Shop/PopupButtonPressed.png", "graphics/Menu/Shop/PopupButton.png");
        cancelButton.Pack (self);

        self.hidden = true;
        self.disabled = true;

        return self;
    }

    override void Ticker () {
        Super.Ticker ();

        if (isEnabled ())
            link.PopupUpdate (popupCommand);
    }

    void Activate (string text, string command) {
        if (!link)
            return;

        link.menuFrame.disabled = true;
        self.hidden = false;
        self.disabled = false;

        textLabel.text = text;
        popupCommand = command;

        Menu.MenuSound ("S7Menu/Open");
    }

    void SetText (string text) {
        textLabel.text = text;
    }

    void Close () {
        link.menuFrame.disabled = false;
        self.hidden = true;
        self.disabled = true;

        textLabel.text = "";
        popupCommand = "";
        Menu.MenuSound ("S7Menu/Close");
    }
}
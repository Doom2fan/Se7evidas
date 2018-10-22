/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
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

class S7_ShopMenuHandler : S7_ZF_Handler {
    S7_ShopMenu link;

    override void buttonClickCommand (S7_ZF_Button caller, string command) {
        if (command.IndexOf (":") < 0) {
            if (command == "BuySellButton") {
                link.ShowBuySellPopup ();
            }
        } /*else {
            Array<String> commandStrings;
            command.Split (commandStrings, ":");

            if (commandStrings.Size () >= 2) {
            }
        }*/
    }
}

class S7_ShopMenu_ListItem {
    int id;
    S7_ZF_Button clickableArea;
    Array<S7_ZF_Label> labels;
    S7_ZF_Image icon;
    S7_SSItem itemData; // This was originally right after id, but for some crazy reason having this as the second item makes GZDoom crash when accessing it.
}

class S7_ShopMenu : S7_ZF_GenericMenu {
    S7_ShopMenuHandler handler;

    PlayerInfo CPlayer;
    S7_SSShop shopData;

    int backKeyCountdown;

    Font bigFont, smallFont;

    S7_ZF_Image mainWindowBG;
    S7_ZF_Label nameLabel, playerDataLabel, descLabel, infoLabel, tooltipLabel;
    S7_ZF_Button buyButton;

    S7_ZF_Frame shopFrame;
    S7_ZF_Frame popupFrame;

    S7_ShopMenu_List itemsList;
    S7_ShopMenu_BuySellPopup bsPopup;

    S7_ShopMenu_ListItem selectedItem, hoveredItem;
    bool sellMode;

    virtual S7_SSShop GetShop () { return null; }

    void ReportError (string error) {
        let errorLabel = new ("S7_ZF_Label").Init ((0, 12), (0, bigFont.GetHeight ()), text: error,
            fnt: bigFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE
        );
        errorLabel.box.pos = (320.0 - (bigFont.StringWidth (error) / 2.0), (480.0 / 2.0) - bigFont.GetHeight ());
        errorLabel.Pack (mainFrame);
        string labelText = "You shouldn't be seeing this";
        let label = new ("S7_ZF_Label").Init ((0, 12), (0, smallFont.GetHeight ()), text: labelText,
            fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE
        );
        label.box.pos = (320.0 - (smallFont.StringWidth (labelText) / 2.0), errorLabel.box.pos.y + bigFont.GetHeight () + 5);
        label.Pack (mainFrame);
    }

    override void Init (Menu parent) {
        Super.Init (parent);
        SetBaseResolution ((640, 480));
        menuactive = Menu.OnNoPause;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        CPlayer = players [consolePlayer];

        if (!CPlayer || !CPlayer.mo) {
            ReportError ("Invalid player");
            return;
        } else if (CPlayer.mo.health <= 0) {
            ReportError ("Dead player");
            return;
        }

        shopData = GetShop ();
        if (!shopData) {
            ReportError ("Invalid shop descriptor");
            return;
        }

        handler = new ("S7_ShopMenuHandler");
        handler.link = self;

        shopFrame = new ("S7_ZF_Frame").Init ((0, 0), (640, 480));
        shopFrame.Pack (mainFrame);

        popupFrame = new ("S7_ZF_Frame").Init ((0, 0), (640, 480));
        popupFrame.Pack (mainFrame);

        nameLabel = new ("S7_ZF_Label").Init ((0, 12), (0, bigFont.GetHeight ()), text: "", fnt: bigFont, wrap: false, textColor: Font.CR_WHITE);
        nameLabel.Pack (shopFrame);

        itemsList = S7_ShopMenu_List (new ("S7_ShopMenu_List").InitList (self, shopFrame, shopData));
        bsPopup = S7_ShopMenu_BuySellPopup (new ("S7_ShopMenu_BuySellPopup").InitPopup (self, popupFrame));

        mainWindowBG = new ("S7_ZF_Image").Init ((250, 50), (365, 400), "graphics/Menu/Shop/MainWindow.png", S7_ZF_Image.AlignType_TopLeft);
        mainWindowBG.Pack (shopFrame);

        playerDataLabel = new ("S7_ZF_Label").Init ((255, 345-smallFont.GetHeight ()), (355, smallFont.GetHeight ()), text: "", fnt: smallFont, wrap: true, textColor: Font.CR_WHITE);
        playerDataLabel.Pack (shopFrame);
        descLabel = new ("S7_ZF_Label").Init ((255, 55), (355, playerDataLabel.box.pos.X - 5), text: "", fnt: smallFont, wrap: true, textColor: Font.CR_WHITE);
        descLabel.Pack (shopFrame);
        infoLabel = new ("S7_ZF_Label").Init ((255, 355), (355, 80), text: "", fnt: smallFont, wrap: true, textColor: Font.CR_WHITE);
        infoLabel.Pack (shopFrame);

        tooltipLabel = new ("S7_ZF_Label").Init ((0, 455), (640, 20), text: "", fnt: smallFont, alignment: S7_ZF_Label.AlignType_Center, wrap: true, autoSize: false, textColor: Font.CR_WHITE);
        tooltipLabel.Pack (mainFrame);

        buyButton = new ("S7_ZF_Button").Init ((555, 423), (50, 17), text: StringTable.Localize ("$SS_BUYBUTTON", true), cmdHandler: handler, command: "BuySellButton", fnt: smallFont);
        buyButton.SetTexture ("graphics/Menu/Shop/BuyButton.png", "graphics/Menu/Shop/BuyButtonHover.png", "graphics/Menu/Shop/BuyButtonPressed.png", "graphics/Menu/Shop/BuyButton.png");
        buyButton.Pack (shopFrame);
        sellMode = false;

        SetPage (shopData.mainPage);

        //dontDim = true;
    }

    void SetPage (S7_SSPage page) {
        string labelText;
        string shopName = shopData ? StringTable.Localize (shopData.name, true) : "";
        string pageName = page ? StringTable.Localize (page.name, true) : "";
        int shopNameLength = shopName.Length ();
        int pageNameLength = pageName.Length ();

        if (shopNameLength && pageNameLength)
            labelText = String.Format ("%s - %s", shopName, pageName);
        else if (shopNameLength && !pageNameLength)
            labelText = shopName;
        else if (!shopNameLength && pageNameLength)
            labelText = pageName;
        else
            labelText = "";

        int width = bigFont.StringWidth (labelText);
        if (nameLabel) {
            nameLabel.text = labelText;
            nameLabel.box.size.X = width;
            nameLabel.box.pos.X = (640.0 - width) / 2.0;
        }
    }

    void SetTooltip (string text) {
        if (tooltipLabel)
            tooltipLabel.text = text;
    }

    void ShowBuySellPopup () {
        bsPopup.Activate (sellMode);
    }

    override bool OnUIEvent (UIEvent ev) {
        if (!shopData)
            return Super.OnUIEvent (ev);

        if (shopFrame.isEnabled () && ev.type == UIEvent.Type_KeyDown && ev.KeyChar == UIEvent.Key_Tab) {
            sellMode = !sellMode;
            return true;
        }

        return Super.OnUIEvent (ev);
    }

    override bool MenuEvent (int mkey, bool fromcontroller) {
        if (!shopData)
            return Super.MenuEvent (mkey, fromcontroller);

        if (shopFrame.isEnabled ()) {
            S7_SSPage  curPage = null;
            S7_SSPage backPage = null;

            if (itemsList) {
                curPage = itemsList.curPage;

                if (curPage)
                    backPage = curPage.backPage;
            }

            switch (mkey) {
            case MKEY_Back:
                if (backKeyCountdown <= 0 && (backPage || shopData.mainPage != curPage)) {
                    backKeyCountdown = 10;

                    if (backPage) {
                        itemsList.Select (NULL);
                        itemsList.SetPage (backPage);
                        SetPage (backPage);

                        selectedItem = NULL;
                        return true;
                    } else
                        return false;
                }
            }
        } else if (bsPopup && bsPopup.isEnabled ()) {
            bsPopup.Close ();
            return true;
        }

        return Super.MenuEvent (mkey, fromcontroller);
    }

    override void Ticker () {
        if (!CPlayer || !CPlayer.mo || CPlayer.mo.health < 1) {
            self.Close ();
            return;
        }

        Super.Ticker ();
        menuactive = Menu.OnNoPause;
        if (backKeyCountdown > 0)
            backKeyCountdown--;

        if (!shopData)
            return;

        if (bsPopup.hidden)
            SetTooltip (StringTable.Localize ("$SS_SELLTTIP", true));
        else
            SetTooltip (StringTable.Localize ("$SS_BUYSELLPOPUPTTIP", true));

        if (buyButton) {
            int bbColor = Font.CR_WHITE;
            bool bbDisable = false;

            if (!selectedItem) {
                bbColor = Font.CR_DARKGRAY;
                bbDisable = true;
            } else {
                let selItemData = selectedItem.itemData;

                if ((!sellMode && !(selItemData.itemType & IT_BuyItem)) ||
                    ( sellMode && !(selItemData.itemType & IT_SellItem))) {
                    bbColor = Font.CR_DARKGRAY;
                    bbDisable = true;
                } else {
                    let pPawn = S7_BasePlayer (CPlayer.mo);
                    let info = selItemData.GetInfo (pPawn, 1);

                    let cashItem = pPawn.FindInventory (selItemData.cashItem);
                    int cashAmount, cashMax;

                    if (cashItem) {
                        cashAmount = cashItem.Amount;
                        cashMax = cashItem.MaxAmount;
                    } else {
                        cashAmount = 0;
                        cashMax = 0;
                    }

                    if ((!sellMode && selItemData.GetAmount (pPawn) >= info.maxAmount && info.maxAmount > 0) ||
                        ( sellMode && selItemData.GetAmount (pPawn) <  info.sellAmount)) {
                        bbColor = Font.CR_RED;
                        bbDisable = true;
                    } else if ((!sellMode && cashAmount < info.buyPrice) ||
                                (sellMode && double (cashAmount) + info.sellPrice > cashMax)) {
                        bbColor = Font.CR_RED;
                        bbDisable = true;
                    } else if ((!sellMode && !selItemData.CanBuy  (pPawn, 1)) ||
                                (sellMode && !selItemData.CanSell (pPawn, 1))) {
                        bbColor = Font.CR_RED;
                        bbDisable = true;
                    }
                }
            }

            buyButton.text = StringTable.Localize ((sellMode ? "$SS_SELLBUTTON" : "$SS_BUYBUTTON"), true);
            buyButton.textColor = bbColor;
            buyButton.disabled = bbDisable;
        }

        if (playerDataLabel) {
            string formatStr = "";
            string cashInv = "";

            if (itemsList && itemsList.curPage) {
                if (itemsList.curPage.cashLabelFormat != "")
                    formatStr = StringTable.Localize (itemsList.curPage.cashLabelFormat, true);
                if (itemsList.curPage.cashTypeShown != "")
                    cashInv = itemsList.curPage.cashTypeShown;
            }

            if (shopData) {
                if (shopData.cashLabelFormat != "" && formatStr == "")
                    formatStr = StringTable.Localize (shopData.cashLabelFormat, true);
                if (shopData.cashTypeShown != "" && cashInv == "")
                    cashInv = shopData.cashTypeShown;
            }

            if (formatStr != "" && cashInv != "")
                playerDataLabel.Text = String.Format (formatStr, CPlayer.mo.CountInv (cashInv));
            else
                playerDataLabel.Text = "";
        }

        if (hoveredItem && hoveredItem.itemData)
            Hover (hoveredItem.itemData);
        else if (selectedItem && selectedItem.itemData)
            Select (selectedItem.itemData);
        else
            Select (NULL);
    }

    void Select (S7_SSItem item) {
        string desc = "";
        string info = "";

        if (item && (item.descShowType & DS_Select)) {
            desc = StringTable.Localize (item.description, true);
            info = StringTable.Localize (item.infoText, true);
        }

        if (descLabel)
            descLabel.text = desc;
        if (infoLabel)
            infoLabel.text = info;
    }

    void Hover (S7_SSItem item) {
        string desc = "";
        string info = "";

        if (item && (item.descShowType & DS_Hover)) {
            desc = StringTable.Localize (item.description, true);
            info = StringTable.Localize (item.infoText, true);
        }

        if (!desc.Length () && !info.Length ())
            return;

        if (descLabel)
            descLabel.text = desc;
        if (infoLabel)
            infoLabel.text = info;
    }
}

class S7_ShopMenu_EventHandler : EventHandler {
    override void NetworkProcess (ConsoleEvent e) {
        if (e.IsManual || e.Player < 0) // Don't execute this if it was called manually or the player isn't given/valid
            return;
        if (!playeringame [e.Player] || !players [e.Player].mo) // Don't execute if the player isn't ingame, the player is null or the player's PlayerPawn is null
            return;

        let player = S7_BasePlayer (players [e.Player].mo);
        if (!player)
            return;

        Array<String> strings;
        e.Name.Split (strings, ":");
        if (strings.Size () < 2 || strings [0] != "S7_ShopMenu") // Return if the array has less than two strings or the first string isn't "S7_ShopMenu"
            return;

        if ((strings [1] == "Buy" || strings [1] == "Sell")) {
            let serverData = S7_ServerData.Get ();
            if (!serverData || !serverData.S7Data.shopData)
                return;

            let shopData = serverData.S7Data.shopData;

            int amount = e.Args [1];
            double mod = 0.0;
            S7_SSItem item = NULL;

            for (int i = 0; i < shopData.allItems.Size (); i++) {
                if (shopData.allItems [i].id == e.Args [0]) {
                    item = shopData.allItems [i];
                    break;
                }
            }
            if (!item)
                return;

            if (strings [1] == "Buy" && (item.itemType & IT_BuyItem)) {
                player.playerData.transactResult = item.BuyItem (player, amount, mod);
                player.playerData.transactSell = false;
                player.playerData.transactDone = true;
            } else if (strings [1] == "Sell" && (item.itemType & IT_SellItem)) {
                player.playerData.transactResult = item.SellItem (player, amount, mod);
                player.playerData.transactSell = true;
                player.playerData.transactDone = true;
            }
        } else if (strings [1] == "TransactStateHandled") {
            player.playerData.transactResult = 0;
            player.playerData.transactSell = false;
            player.playerData.transactDone = false;
        }
    }
}

class S7_LuciusShopMenu : S7_ShopMenu {
    override S7_SSShop GetShop () {
        let serverData = S7_ServerData.GetSpecial ();

        if (!serverData || !serverData.S7Data || !serverData.S7Data.shopData)
            return NULL;

        return S7_SSShop (serverData.S7Data.shopData.shops.Get ("mainShop"));
    }
}
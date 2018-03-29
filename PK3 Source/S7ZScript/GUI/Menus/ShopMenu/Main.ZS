class S7_ShopMenuHandler : S7_ZF_Handler {
    S7_ShopMenu link;

    override void buttonCommand (S7_ZF_Button caller, string command) {
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

    Font bigFont, smallFont;

    S7_ZF_Image mainWindowBG;
    S7_ZF_Label nameLabel, descLabel, infoLabel, tooltipLabel;
    S7_ZF_Button buyButton;

    S7_ZF_Frame shopFrame;
    S7_ZF_Frame popupFrame;

    S7_ShopMenu_List itemsList;
    S7_ShopMenu_BuySellPopup bsPopup;

    S7_ShopMenu_ListItem selectedItem, hoveredItem;
    bool sellMode;

    virtual S7_SSShop GetShop () { return null; }

    void ReportError (string error) {
        let errorLabel = new ("S7_ZF_Label").Init ((0, 12), (0, bigFont.GetHeight ()), error, bigFont, false, true, 1, Font.CR_WHITE);
        errorLabel.box.pos = (320.0 - (bigFont.StringWidth (error) / 2.0), (480.0 / 2.0) - bigFont.GetHeight ());
        errorLabel.Pack (mainFrame);
        string labelText = "You shouldn't be seeing this";
        let label = new ("S7_ZF_Label").Init ((0, 12), (0, smallFont.GetHeight ()), labelText, smallFont, false, true, 1, Font.CR_WHITE);
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

        nameLabel = new ("S7_ZF_Label").Init ((0, 12), (0, bigFont.GetHeight ()), "", bigFont, false, false, 1, Font.CR_WHITE);
        nameLabel.Pack (shopFrame);

        itemsList = S7_ShopMenu_List (new ("S7_ShopMenu_List").InitList (self, shopFrame, shopData));
        bsPopup = S7_ShopMenu_BuySellPopup (new ("S7_ShopMenu_BuySellPopup").InitPopup (self, popupFrame));

        mainWindowBG = new ("S7_ZF_Image").Init ((245, 50), (365, 400), "graphics/Menu/Shop/MainWindow.png", S7_ZF_Image.AlignTopLeft);
        mainWindowBG.Pack (shopFrame);
        descLabel = new ("S7_ZF_Label").Init ((250, 55), (345, 279), "", smallFont, true, false, 1, Font.CR_WHITE);
        descLabel.Pack (shopFrame);
        infoLabel = new ("S7_ZF_Label").Init ((250, 355), (345, 80), "", smallFont, true, false, 1, Font.CR_WHITE);
        infoLabel.Pack (shopFrame);

        tooltipLabel = new ("S7_ZF_Label").Init ((0, 0), (0, 0), "", smallFont, false, false, 1, Font.CR_WHITE);
        tooltipLabel.Pack (popupFrame);
        SetTooltip (StringTable.Localize ("$SS_SELLTTIP", true));

        buyButton = new ("S7_ZF_Button").Init ((550, 423), (50, 17), StringTable.Localize ("$SS_BUYBUTTON", true), handler, "BuySellButton", fnt: smallFont);
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
        if (tooltipLabel) {
            tooltipLabel.text = text;
            tooltipLabel.box.size = (smallFont.StringWidth (text), smallFont.GetHeight ());
            tooltipLabel.box.pos = ((640 - smallFont.StringWidth (text)) / 2,  450 + (30 - smallFont.GetHeight ()) / 2);
        }
    }

    void ShowBuySellPopup () {
        bsPopup.Activate (sellMode);
    }

    override bool OnUIEvent (UIEvent ev) {
        if (!shopFrame.disabled && ev.type == UIEvent.Type_KeyDown && ev.KeyChar == UIEvent.Key_Tab) {
            sellMode = !sellMode;
            return true;
        }

        return Super.OnUIEvent (ev);
    }

    override void Ticker () {
        if (!CPlayer || !CPlayer.mo || CPlayer.mo.health < 1) {
            self.Close ();
            return;
        }

        Super.Ticker ();
        menuactive = Menu.OnNoPause;

        if (buyButton) {
            int bbColor = Font.CR_WHITE;
            bool bbDisable = false;

            if (!selectedItem) {
                bbColor = Font.CR_DARKGRAY;
                bbDisable = true;
            } else {
                let selItemData = selectedItem.itemData;

                let info = selItemData.GetInfo (S7_BasePlayer (CPlayer.mo), 1);

                if ((!sellMode && (CPlayer.mo.CountInv (selItemData.inventoryName) >= info.maxAmount)) ||
                    ( sellMode && (CPlayer.mo.CountInv (selItemData.inventoryName) <  info.sellAmount))) {
                    bbColor = Font.CR_RED;
                    bbDisable = true;
                }
            }

            buyButton.text = StringTable.Localize ((sellMode ? "$SS_SELLBUTTON" : "$SS_BUYBUTTON"), true);
            buyButton.textColor = bbColor;
            buyButton.disabled = bbDisable;
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
            if (!serverData || !serverData.shopData || !serverData.shopData.mainShop)
                return;

            int amount = e.Args [1];
            double mod = 0.0;
            S7_SSItem item = NULL;

            for (int i = 0; i < serverData.shopData.allItems.Size (); i++) {
                if (serverData.shopData.allItems [i].id == e.Args [0]) {
                    item = serverData.shopData.allItems [i];
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

        if (!serverData || !serverData.shopData || !serverData.shopData.mainShop)
            return NULL;

        return serverData.shopData.mainShop;
    }
}
class S7_ShopMenuHandler : S7_ZF_Handler {
    S7_ShopMenu link;

    override void buttonCommand (S7_ZF_Button button, string command) {
        if (command.IndexOf (":") < 0) { // Currently empty
        } else {
            Array<String> commandStrings;
            command.Split (commandStrings, ":");

            if (commandStrings.Size () >= 2) {
                if (commandStrings [0] == "List") {
                    if (commandStrings [1] == "Entry" && commandStrings.Size () == 3)
                        ListSelect (commandStrings [2]);
                } else if (commandStrings [0] == "Buy" && commandStrings.Size () == 4)
                    BuyOrSellItem (commandStrings [1], commandStrings [2], commandStrings [3], false);
                else if (commandStrings [0] == "Sell" && commandStrings.Size () == 4)
                    BuyOrSellItem (commandStrings [1], commandStrings [2], commandStrings [3], true);
            }
        }
    }

    void BuyOrSellItem (string itemId, string amount, string mod, bool sell) {
        S7_SSItem item;
        let list = link.itemsList;
        for (int i = 0; i < list.items.Size (); i++) {
            if (list.items [i].id == itemId.ToInt ()) {
                item = list.items [i].itemData;
                break;
            }
        }
        if (!item)
            return;

        if ((!sell && (item.itemType & IT_BuyItem)) || (sell && (item.itemType & IT_SellItem)))
            EventHandler.SendNetworkEvent (String.Format ("S7_ShopMenu:%s:%s", !sell ? "Buy" : "Sell", mod), itemId.ToInt (), amount.ToInt ());
    }

    void ListSelect (string itemId) {
        S7_ShopMenu_ListItem item;
        let list = link.itemsList;
        for (int i = 0; i < list.items.Size (); i++) {
            if (list.items [i].id == itemId.ToInt ()) {
                item = list.items [i];
                break;
            }
        }

        if (!item)
            return;

        if (item.itemData && item.itemData.itemType == IT_PageLink && item.itemData.link) {
            list.Select (NULL);
            let page = item.itemData.link;
            list.SetPage (page);
            link.SetPage (page);

            link.selectedItem = NULL;
        } else if (link.selectedItem != item) { // If the item isn't already selected
            list.Select (item);
            link.selectedItem = item;
        } else {
            list.Select (NULL);
            link.selectedItem = NULL;
        }
    }

    override void buttonFocusChanged (S7_ZF_Button button, string command, bool lostFocus) {
        if (command.IndexOf (":") < 0) { // Currently empty
        } else {
            Array<String> commandStrings;
            command.Split (commandStrings, ":");

            if (commandStrings.Size () >= 2) {
                if (commandStrings [0] == "List") {
                    if (button && button.isEnabled () && commandStrings [1] == "Entry" && commandStrings.Size () == 3)
                        ListHover (commandStrings [2], lostFocus);
                }
            }
        }
    }

    void ListHover (string itemId, bool lostFocus) {
        S7_ShopMenu_ListItem item;
        let list = link.itemsList;
        for (int i = 0; i < list.items.Size (); i++) {
            if (list.items [i].id == itemId.ToInt ()) {
                item = list.items [i];
                break;
            }
        }

        if (!lostFocus)
            link.hoveredItem = item;
        else if (link.hoveredItem == item)
            link.hoveredItem = NULL;
    }
}

class S7_ShopMenu_ListItem {
    int id;
    S7_ZF_Button clickableArea;
    Array<S7_ZF_Label> labels;
    S7_ZF_Image icon;
    S7_SSItem itemData; // This was originally right after id, but for some crazy reason having this as the second item makes GZDoom crash when accessing it.
}

class S7_ShopMenu_List : S7_ZF_Frame {
    S7_ShopMenu link;
    S7_SSShop shopData;
    S7_SSPage curPage;

    Font bigFont;
    Font smallFont;
    S7_ZF_Image background;
    S7_ZF_Frame itemsFrame;
    Array<S7_ShopMenu_ListItem> items;

    void InitList (S7_SSShop shopData) {
        background = new ("S7_ZF_Image").Init ((0, 0), (200, 400), "graphics/Menu/Shop/ItemList.png", S7_ZF_Image.AlignTopLeft, noOffsets: true);
        background.Pack (self);
        bigFont = Font.GetFont ("BigFont");
        smallFont = Font.GetFont ("SmallFont");

        SetShop (shopData);
    }

    bool SetShop (S7_SSShop newShopData, bool setPage = true) {
        if (!newShopData)
            return false;

        shopData = newShopData;
        if (setPage)
            SetPage (shopData.mainPage);

        return true;
    }

    bool SetPage (S7_SSPage page) {
        if (!page)
            return false;
        if (itemsFrame && elements.Find (itemsFrame) != elements.Size ()) {
            elements.Delete (elements.Find (itemsFrame));
            itemsFrame.master = NULL;
            itemsFrame.Destroy ();
            itemsFrame = NULL;
        }
        if (items.Size () > 0) {
            for (int i = items.Size () - 1; i > 0; i--) {
                items [i].itemData = NULL;
                items [i].clickableArea.Destroy ();
                items [i].clickableArea = NULL;
                items [i].labels.Clear ();
                items [i].icon.Destroy ();
                items [i].icon = NULL;
                items [i].Destroy ();
            }
            items.Clear ();
        }
        itemsFrame = new ("S7_ZF_Frame").Init ((0, 3), (200, 400 - 3));
        itemsFrame.Pack (self);

        curPage = page;

        double yCoords = 0.0; // We have to do it like this because entries have variable lengths based on contents
        for (int i = 0; i < curPage.items.Size (); i++) {
            let item = curPage.items [i];
            if (!item)
                continue;
            let itemControls = new ("S7_ShopMenu_ListItem");
            itemControls.id = item.id;
            itemControls.itemData = item;

            if (i > 0) {
                let sep = new ("S7_ZF_Image").Init ((0, yCoords), (200, 2), "graphics/Menu/Shop/ListSep.png", noOffsets: true);
                sep.Pack (itemsFrame);
                yCoords += 2;
            }

            let tex = TexMan.CheckForTexture (item.icon, TexMan.Type_Any);
            Vector2 texSize = (0, 0);
            if (tex)
                texSize = TexMan.GetScaledSize (tex);

            // Clickable area
            let button = new ("S7_ZF_Button").Init ((0, yCoords), (200, 40), "", link.handler, String.Format ("List:Entry:0x%.8X", item.id), null, null, null, null, null);
            button.SetTexture ("", "", "", "");
            button.Pack (itemsFrame);
            itemControls.clickableArea = button;

            // Text
            double textX = 8;
            double textY = yCoords + 4;
            if (texSize.X > 0)
                textX = texSize.X + 8 * 2;
            BrokenLines textLines = smallFont.BreakLines (StringTable.Localize (item.name, true), 200 - (texSize.X + 8 * 3));

            double clickHeight = (smallFont.GetHeight () * textLines.Count ());
            if (texSize.Y > clickHeight) {
                textY = yCoords + 4 + (texSize.Y - clickHeight) / 2;
                clickHeight = texSize.Y;
            }

            for (int i = 0; i < textLines.Count (); i++) {
                double fHeight = smallFont.GetHeight ();
                let label = new ("S7_ZF_Label").Init ((textX, textY + (fHeight * i)), (textLines.stringWidth (i), fHeight), textLines.StringAt (i), smallFont, false, false, 1, Font.CR_WHITE);
                label.Pack (itemsFrame);
                itemControls.labels.Push (label);
            }

            button.box.size.Y = clickHeight + 4 * 2;
            // Icon
            let icon = new ("S7_ZF_Image").Init ((8, yCoords + 4 + (clickHeight - texSize.Y) / 2), texSize, item.icon, noOffsets: true);
            icon.Pack (itemsFrame);
            itemControls.icon = icon;

            items.Push (itemControls);
            yCoords += button.box.size.Y;
        }

        return true;
    }

    void Select (S7_ShopMenu_ListItem item) {
        Array<S7_ZF_Label> labels;
        for (int i = 0; i < items.Size (); i++) {
            labels.Copy (items [i].labels);
            for (int j = 0; j < labels.Size (); j++)
                labels [j].textColor = (items [i] == item ? Font.CR_RED : Font.CR_WHITE);
            labels.Clear ();
        }
    }
}

class S7_ShopMenu : S7_ZF_GenericMenu {
    S7_ShopMenuHandler handler;

    PlayerInfo CPlayer;
    S7_SSShop shopData;

    Font bigFont;
    Font smallFont;

    S7_ZF_Label nameLabel;
    S7_ZF_Image mainWindowBG;
    S7_ZF_Label descLabel;
    S7_ZF_Label infoLabel;
    S7_ZF_Button buyButton;

    S7_ZF_Frame shopFrame;
    S7_ShopMenu_List itemsList;
    S7_ShopMenu_ListItem selectedItem;
    S7_ShopMenu_ListItem hoveredItem;

    virtual S7_SSShop GetShop () { return null; }

    void ReportError (string error) {
        let errorLabel = new ("S7_ZF_Label").Init ((0, 12), (0, bigFont.GetHeight ()), error, bigFont, false, true, 1, Font.CR_WHITE);
        errorLabel.box.pos = (320.0 - (bigFont.stringWidth (error) / 2.0), (480.0 / 2.0) - bigFont.GetHeight ());
        errorLabel.Pack (mainFrame);
        string labelText = "You shouldn't be seeing this";
        let label = new ("S7_ZF_Label").Init ((0, 12), (0, smallFont.GetHeight ()), labelText, smallFont, false, true, 1, Font.CR_WHITE);
        label.box.pos = (320.0 - (smallFont.stringWidth (labelText) / 2.0), errorLabel.box.pos.y + bigFont.GetHeight () + 5);
        label.Pack (mainFrame);
    }

    override void Init (Menu parent) {
        Super.Init (parent);
        SetBaseResolution ((640, 480));

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('SmallFont');

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

        nameLabel = new ("S7_ZF_Label").Init ((0, 12), (0, bigFont.GetHeight ()), "", bigFont, false, false, 1, Font.CR_WHITE);
        nameLabel.Pack (shopFrame);

        itemsList = S7_ShopMenu_List (new ("S7_ShopMenu_List").Init ((25, 50), (200, 400)));
        itemsList.link = self;
        itemsList.Pack (shopFrame);
        itemsList.InitList (shopData);

        mainWindowBG = new ("S7_ZF_Image").Init ((245, 50), (365, 400), "graphics/Menu/Shop/MainWindow.png", S7_ZF_Image.AlignTopLeft, noOffsets: true);
        mainWindowBG.Pack (shopFrame);
        descLabel = new ("S7_ZF_Label").Init ((250, 55), (345, 279), "", smallFont, true, false, 1, Font.CR_WHITE);
        descLabel.Pack (shopFrame);
        infoLabel = new ("S7_ZF_Label").Init ((250, 355), (345, 80), "", smallFont, true, false, 1, Font.CR_WHITE);
        infoLabel.Pack (shopFrame);

        buyButton = new ("S7_ZF_Button").Init ((550, 423), (50, 17), "Buy", handler, "BuyButton", null, null, null, null, null);
        buyButton.SetTexture ("graphics/Menu/Shop/BuyButton.png", "graphics/Menu/Shop/BuyButtonHover.png", "graphics/Menu/Shop/BuyButtonPressed.png", "graphics/Menu/Shop/BuyButton.png");
        buyButton.Pack (shopFrame);

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

        int width = bigFont.stringWidth (labelText);
        nameLabel.text = labelText;
        nameLabel.box.size.X = width;
        nameLabel.box.pos.X = (640.0 - width) / 2.0;
    }

    override void Ticker () {
        Super.Ticker ();

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

        descLabel.text = desc;
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

        descLabel.text = desc;
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

        if ((strings [1] == "Buy" || strings [1] == "Sell") && strings.Size () == 3) {
            let serverData = S7_ServerData.Get ();
            if (!serverData || !serverData.shopData || !serverData.shopData.mainShop)
                return;

            int amount = e.Args [1];
            double mod = strings [2].ToDouble ();
            S7_SSItem item = NULL;

            for (int i = 0; i < serverData.shopData.allItems.Size (); i++) {
                if (serverData.shopData.allItems [i].id == e.Args [0]) {
                    let item = serverData.shopData.allItems [i];
                    break;
                }
            }
            if (!item)
                return;

            if (strings [1] == "Buy" && (item.itemType & IT_BuyItem))
                item.BuyItem (player, amount, mod);
            else if (strings [1] == "Sell" && (item.itemType & IT_SellItem))
                item.SellItem (player, amount, mod);
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
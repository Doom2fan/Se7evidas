class S7_ShopMenu_BuySellPopupHandler : S7_ZF_Handler {
    S7_ShopMenu_BuySellPopup link;
    S7_ShopMenu menuLink;

    override void buttonCommand (S7_ZF_Button button, string command) {
        if (command == "Accept" && link.amount > 0 && link.amount <= 9999) {
            if (!link.sellMode)
                BuyItem ();
            else
                SellItem ();
        } else if (command == "Cancel")
            link.Close ();
        else if (command == "Add")
            link.SetAmount (1);
        else if (command == "Dec")
            link.SetAmount (-1);
    }

    void BuyItem () {
        S7_SSItem item = link.selectedItem;

        if (!item || !(item.itemType & IT_BuyItem))
            return;

        EventHandler.SendNetworkEvent ("S7_ShopMenu:Buy", item.id, link.amount);
    }

    void SellItem () {
        S7_SSItem item = link.selectedItem;

        if (!item || !(item.itemType & IT_SellItem))
            return;

        EventHandler.SendNetworkEvent ("S7_ShopMenu:Sell", item.id, link.amount);
    }
}

class S7_ShopMenu_BuySellPopup : S7_ZF_Frame {
    S7_ShopMenu_BuySellPopupHandler handler;
    S7_ShopMenu link;

    Font bigFont, smallFont;

    S7_ZF_Image background;
    S7_ZF_Label modeLabel;

    S7_ZF_Image itemIcon;
    S7_ZF_Label itemName, totalAmount, selAmount, priceLabel;

    S7_ZF_Button addButton, decButton;
    S7_ZF_Button acceptButton, cancelButton;

    S7_SSItem selectedItem;
    bool sellMode;
    int amount;
    S7_SSItemInfo info;

    S7_ZF_Frame InitPopup (S7_ShopMenu menuLink, S7_ZF_Frame frame) {
        self.Init ((160, 200), (320, 80));
        self.Pack (frame);
        link = menuLink;

        bigFont = Font.GetFont ("BigFont");
        smallFont = Font.GetFont ("SmallFont");

        handler = new ("S7_ShopMenu_BuySellPopupHandler");
        handler.link = self;
        handler.menuLink = link;

        background = new ("S7_ZF_Image").Init ((0, 0), (320, 80), "graphics/Menu/Shop/BuySellPopup.png", S7_ZF_Image.AlignTopLeft);
        background.Pack (self);
        modeLabel = new ("S7_ZF_Label").Init ((4, 4), (40, 10), "", bigFont, false, true, 1, Font.CR_WHITE);
        modeLabel.Pack (self);

        itemIcon = new ("S7_ZF_Image").Init ((0, 0), (0, 0), "", S7_ZF_Image.AlignTopLeft, noOffsets: true);
        itemIcon.Pack (self);
        itemName = new ("S7_ZF_Label").Init ((0, 0), (0, 0), "", smallFont, false, true, 1, Font.CR_WHITE);
        itemName.Pack (self);

        totalAmount = new ("S7_ZF_Label").Init ((0, 0), (smallFont.StringWidth (String.Format ("%s: 00000", StringTable.Localize ("$SS_TOTAL", true))), smallFont.GetHeight ()),
            "", smallFont, false, false, 1, Font.CR_WHITE);
        totalAmount.Pack (self);
        selAmount = new ("S7_ZF_Label").Init ((0, 0), (smallFont.StringWidth (String.Format ("%s: 00000", StringTable.Localize ("$SS_COUNT", true))), smallFont.GetHeight ()),
            "", smallFont, false, false, 1, Font.CR_WHITE);
        selAmount.Pack (self);
        priceLabel = new ("S7_ZF_Label").Init ((0, 0), (smallFont.StringWidth (String.Format ("%s: 00000000", StringTable.Localize ("$SS_PRICE", true))), smallFont.GetHeight ()),
            "", smallFont, false, false, 1, Font.CR_WHITE);
        priceLabel.Pack (self);

        addButton = new ("S7_ZF_Button").Init ((0, 0), (13, 11), "+", handler, "Add", null, null, null, null, null);
        addButton.SetTexture ("graphics/Menu/Generic/SmallButton.png", "graphics/Menu/Generic/SmallButtonHover.png", "graphics/Menu/Generic/SmallButtonPressed.png", "graphics/Menu/Generic/SmallButton.png");
        addButton.Pack (self);
        decButton = new ("S7_ZF_Button").Init ((0, 0), (13, 11), "-", handler, "Dec", null, null, null, null, null);
        decButton.SetTexture ("graphics/Menu/Generic/SmallButton.png", "graphics/Menu/Generic/SmallButtonHover.png", "graphics/Menu/Generic/SmallButtonPressed.png", "graphics/Menu/Generic/SmallButton.png");
        decButton.Pack (self);

        acceptButton = new ("S7_ZF_Button").Init ((196, 57), (55, 17), "", handler, "Accept", null, null, null, null, null);
        acceptButton.SetTexture ("graphics/Menu/Shop/PopupButton.png", "graphics/Menu/Shop/PopupButtonHover.png", "graphics/Menu/Shop/PopupButtonPressed.png", "graphics/Menu/Shop/PopupButton.png");
        acceptButton.Pack (self);
        cancelButton = new ("S7_ZF_Button").Init ((259, 57), (55, 17), StringTable.Localize ("$SS_CANCELBUTTON", true), handler, "Cancel", null, null, null, null, null);
        cancelButton.SetTexture ("graphics/Menu/Shop/PopupButton.png", "graphics/Menu/Shop/PopupButtonHover.png", "graphics/Menu/Shop/PopupButtonPressed.png", "graphics/Menu/Shop/PopupButton.png");
        cancelButton.Pack (self);

        self.hidden = true;
        self.disabled = true;

        return self;
    }

    void Activate (bool sellMode) {
        if (!link || !link.selectedItem || !link.selectedItem.itemData)
            return;

        selectedItem = link.selectedItem.itemData;
        if ((!sellMode && !(selectedItem.itemType & IT_BuyItem)) ||
            ( sellMode && !(selectedItem.itemType & IT_SellItem))
        ) {
            selectedItem = null;
            return;
        }

        link.shopFrame.disabled = true;
        self.hidden = false;
        self.disabled = false;

        modeLabel.text = StringTable.Localize ((sellMode ? "$SS_SELLMODE" : "$SS_BUYMODE"), true);
        acceptButton.text = StringTable.Localize ((sellMode ? "$SS_SELLBUTTON" : "$SS_BUYBUTTON"), true);

        let tex = TexMan.CheckForTexture (selectedItem.icon, TexMan.Type_Any);
        Vector2 texSize = (0, 0);
        if (tex)
            texSize = TexMan.GetScaledSize (tex);

        itemIcon.image = selectedItem.icon;
        itemIcon.box.size = texSize;
        itemIcon.box.pos = (8, (modeLabel.box.pos.Y + modeLabel.box.size.Y) + 4);

        itemName.text = StringTable.Localize (selectedItem.name, true);
        itemName.box.size = (smallFont.StringWidth (itemName.text), smallFont.GetHeight ());
        itemName.box.pos = 
            (8 + texSize.X + ((texSize.X > 0) ? 4 : 0),
             itemIcon.box.pos.Y + (texSize.Y - smallFont.GetHeight ()) / 2
        );

        let actualBox = ((texSize != (0, 0)) ? itemIcon.box : itemName.box);
        selAmount.box.pos = (8, (actualBox.pos.Y + actualBox.size.Y) + 4);
        totalAmount.box.pos = (8, (selAmount.box.pos.Y + selAmount.box.size.Y) + 4);
        priceLabel.box.pos = (8, (totalAmount.box.pos.Y + totalAmount.box.size.Y) + 4);

        addButton.box.pos = ((selAmount.box.pos.X + selAmount.box.size.X) + 4, selAmount.box.pos.Y - 1);
        decButton.box.pos = ((addButton.box.pos.X + addButton.box.size.X) + 4, addButton.box.pos.Y);

        self.sellMode = sellMode;
        amount = 1;
        UpdateData ();
    }

    void SetAmount (int addAmount) {
        amount += addAmount;
        if (amount > 9999)
            amount = 9999;
        if (amount < 1)
            amount = 1;

        UpdateData ();
    }

    override void Ticker () {
        UpdateData ();

        Super.Ticker ();
    }

    void UpdateData () {
        if (!selectedItem)
            return;

        let pPawn = S7_BasePlayer (link.CPlayer.mo);

        if (!pPawn)
            return;

        if (pPawn.playerData && pPawn.playerData.transactDone) {
            if (pPawn.playerData.transactResult == 0) {
                EventHandler.SendNetworkEvent ("S7_ShopMenu:TransactStateHandled");
                Close ();
                return;
            }
        }

        if (info)
            info.Destroy ();
        info = selectedItem.GetInfo (pPawn, amount);

        uint total = (sellMode ? info.sellAmount : info.buyAmount);
        uint price = (sellMode ? info.sellPrice  : info.buyPrice);
        totalAmount.text = String.Format ("%s: %d", StringTable.Localize ("$SS_TOTAL", true), total);
        selAmount.text = String.Format ("%s: %d", StringTable.Localize ("$SS_COUNT", true), amount);
        priceLabel.text = String.Format ("%s: %d", StringTable.Localize ("$SS_PRICE", true), price);

        totalAmount.textColor = Font.CR_WHITE;
        selAmount.textColor = Font.CR_WHITE;
        priceLabel.textColor = Font.CR_WHITE;
        acceptButton.textColor = Font.CR_WHITE;

        addButton.disabled = false;
        decButton.disabled = false;
        acceptButton.disabled = false;

        class<Inventory> cashInvType = (class<Inventory>) (selectedItem.cashItem);
        uint cash = uint (pPawn.CountInv (cashInvType)), maxCash;
        
        let cashInv = pPawn.FindInventory (cashInvType);
        if (cashInv)
            maxCash = cashInv.maxAmount;
        else {
            let defaults = GetDefaultByType (cashInvType);
            if (defaults) maxCash = defaults.maxAmount;
        }

        if ((!sellMode && cash < price) || // If buying, check if there's not enough money
            (sellMode && (cash + price) >= maxCash) // If selling, check if there's too much money
        ) {
            priceLabel.textColor = Font.CR_DARKRED;
            acceptButton.textColor = Font.CR_DARKGRAY;

            acceptButton.disabled = true;
        } else if (
            (!sellMode && (pPawn.CountInv (selectedItem.inventoryName) + total) > info.maxAmount) || // If buying, check if there's too much of the item
            (sellMode && total > pPawn.CountInv (selectedItem.inventoryName)) // If selling, check if there's not enough of the item
        ) {
            selAmount.textColor = Font.CR_DARKRED;
            totalAmount.textColor = Font.CR_DARKRED;
            acceptButton.textColor = Font.CR_DARKGRAY;

            acceptButton.disabled = true;
        }

        if (amount >= 9999)
            addButton.disabled = true;
        if (amount <= 1)
            decButton.disabled = true;
    }

    void Close () {
        link.shopFrame.disabled = false;
        self.hidden = true;
        self.disabled = true;

        selectedItem = null;
        if (info)
            info.Destroy ();
        info = null;
        modeLabel.text = "";
        itemName.text = "";
        itemIcon.image = "";
    }
}
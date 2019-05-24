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

class S7_ShopMenu_BuySellPopupHandler : S7_ZF_Handler {
    S7_ShopMenu_BuySellPopup link;
    S7_ShopMenu menuLink;

    void DoAddDec (string command) {
        if (command != "Add" && command != "Dec")
            return;

        int mul = (command == "Add") ? 1 : -1;

        if (link.ctrlHeld)
            mul *= 5;
        if (link.shiftHeld)
            mul *= 10;

        Menu.MenuSound ("S7Menu/SliderMove");

        link.SetAmount (1 * mul);
    }

    override void buttonClickCommand (S7_ZF_Button caller, string command) {
        if (command == "Accept" && link.amount > 0 && link.amount <= 9999) {
            if (!link.sellMode)
                BuyItem ();
            else
                SellItem ();
        } else if (command == "Cancel")
            link.Close ();
        else if (command == "Add" || command == "Dec")
            DoAddDec (command);
    }

    override void buttonHeldCommand (S7_ZF_Button caller, string command) {
        if ((command == "Add" || command == "Dec") && link.buttonHeldTics++ > 8)
            DoAddDec (command);
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

    int buttonHeldTics;
    bool shiftHeld, ctrlHeld;

    S7_ZF_Frame InitPopup (S7_ShopMenu menuLink, S7_ZF_Frame frame) {
        self.Init ((160, 200), (320, 80));
        self.Pack (frame);
        link = menuLink;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        handler = new ('S7_ShopMenu_BuySellPopupHandler');
        handler.link = self;
        handler.menuLink = link;

        background = new ('S7_ZF_Image').Init ((0, 0), (320, 80), "graphics/Menu/Shop/BuySellPopup.png", S7_ZF_Image.AlignType_TopLeft);
        background.Pack (self);
        modeLabel = new ('S7_ZF_Label').Init ((4, 4), (40, 10), text: "", fnt: bigFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE);
        modeLabel.Pack (self);

        itemIcon = new ('S7_ZF_Image').Init ((0, 0), (0, 0), "", S7_ZF_Image.AlignType_TopLeft, noOffsets: true);
        itemIcon.Pack (self);
        itemName = new ('S7_ZF_Label').Init ((0, 0), (0, 0), text: "", fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_WHITE);
        itemName.Pack (self);

        totalAmount = new ('S7_ZF_Label').Init ((0, 0), (smallFont.StringWidth (String.Format ("%s: 00000", StringTable.Localize ("$SS_TOTAL", true))), smallFont.GetHeight ()),
            text: "", fnt: smallFont, wrap: false, autoSize: false, textColor: Font.CR_WHITE
        );
        totalAmount.Pack (self);
        selAmount = new ('S7_ZF_Label').Init ((0, 0), (smallFont.StringWidth (String.Format ("%s: 00000", StringTable.Localize ("$SS_COUNT", true))), smallFont.GetHeight ()),
            text: "", fnt: smallFont, wrap: false, autoSize: false, textColor: Font.CR_WHITE
        );
        selAmount.Pack (self);
        priceLabel = new ('S7_ZF_Label').Init ((0, 0), (smallFont.StringWidth (String.Format ("%s: 00000000", StringTable.Localize ("$SS_PRICE", true))), smallFont.GetHeight ()),
            text: "", fnt: smallFont, wrap: false, autoSize: false, textColor: Font.CR_WHITE
        );
        priceLabel.Pack (self);

        addButton = new ('S7_ZF_Button').Init ((0, 0), (13, 11), text: "+", cmdHandler: handler, command: "Add", fnt: smallFont, holdInterval: 1);
        addButton.SetTexture ("graphics/Menu/Generic/SmallButton.png", "graphics/Menu/Generic/SmallButtonHover.png", "graphics/Menu/Generic/SmallButtonPressed.png", "graphics/Menu/Generic/SmallButton.png");
        addButton.Pack (self);
        decButton = new ('S7_ZF_Button').Init ((0, 0), (13, 11), text: "-", cmdHandler: handler, command: "Dec", fnt: smallFont, holdInterval: 1);
        decButton.SetTexture ("graphics/Menu/Generic/SmallButton.png", "graphics/Menu/Generic/SmallButtonHover.png", "graphics/Menu/Generic/SmallButtonPressed.png", "graphics/Menu/Generic/SmallButton.png");
        decButton.Pack (self);

        acceptButton = new ('S7_ZF_Button').Init ((196, 57), (55, 17), text: "", cmdHandler: handler, command: "Accept", fnt: smallFont);
        acceptButton.SetTexture ("graphics/Menu/Shop/PopupButton.png", "graphics/Menu/Shop/PopupButtonHover.png", "graphics/Menu/Shop/PopupButtonPressed.png", "graphics/Menu/Shop/PopupButton.png");
        acceptButton.Pack (self);
        cancelButton = new ('S7_ZF_Button').Init ((259, 57), (55, 17), text: StringTable.Localize ("$SS_CANCELBUTTON", true), cmdHandler: handler, command: "Cancel", fnt: smallFont);
        cancelButton.SetTexture ("graphics/Menu/Shop/PopupButton.png", "graphics/Menu/Shop/PopupButtonHover.png", "graphics/Menu/Shop/PopupButtonPressed.png", "graphics/Menu/Shop/PopupButton.png");
        cancelButton.Pack (self);

        self.hidden = true;
        self.disabled = true;

        return self;
    }

    override void OnUIEvent (UIEvent ev) {
        if (addButton.curButtonState != S7_ZF_Button.ButtonState_Click && decButton.curButtonState != S7_ZF_Button.ButtonState_Click &&
            (ev.Type == UIEvent.Type_LButtonClick || ev.Type == UIEvent.Type_LButtonDown)) {
            shiftHeld = ev.IsShift;
             ctrlHeld = ev.IsCtrl;
        }

        Super.OnUIEvent (ev);
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

        let pPawn = S7_BasePlayer (link.CPlayer.mo);
        if (pPawn)
            info = selectedItem.GetInfo (pPawn, 1);

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
             itemIcon.box.pos.Y //+ (texSize.Y > 0 ? (texSize.Y - smallFont.GetHeight ()) / 2 : 0)
        );

        let actualBox = itemName.box; //((texSize.X > 0 && texSize.Y > 0) ? itemIcon.box : itemName.box);
        double xCoords = actualBox.pos.X; //8;
        if (info && info.maxAmount != 1) {
            selAmount.box.pos = (xCoords, (actualBox.pos.Y + actualBox.size.Y) + 2);
            totalAmount.box.pos = (xCoords, (selAmount.box.pos.Y + selAmount.box.size.Y) + 2);
            priceLabel.box.pos = (xCoords, (totalAmount.box.pos.Y + totalAmount.box.size.Y) + 2);
            selAmount.hidden = totalAmount.hidden = false;
        } else {
            selAmount.hidden = totalAmount.hidden = true;
            priceLabel.box.pos = (xCoords, (actualBox.pos.Y + actualBox.size.Y) + 4);
        }

        addButton.box.pos = ((selAmount.box.pos.X + selAmount.box.size.X) + 4, selAmount.box.pos.Y - 1);
        decButton.box.pos = ((addButton.box.pos.X + addButton.box.size.X) + 4, addButton.box.pos.Y);

        self.sellMode = sellMode;
        amount = 1;
        UpdateData ();

        Menu.MenuSound ("S7Menu/Open");
    }

    void SetAmount (int addAmount) {
        amount += addAmount;

        let pPawn = S7_BasePlayer (link.CPlayer.mo);
        if (info && amount > info.maxAmount)
            amount = info.maxAmount;
        if (selectedItem) {
            let itemInfo = selectedItem.GetInfo (pPawn, 1);

            int totalAmt = !sellMode ? (amount * itemInfo.buyAmount) : (amount * itemInfo.sellAmount);
            int heldAmt = selectedItem.GetAmount (pPawn, sellMode);

            if (!sellMode && (info.maxAmount - (totalAmt + heldAmt)) <= 0)
                amount = int (floor (double (info.maxAmount - heldAmt) / itemInfo.buyAmount));
            else if (sellMode && totalAmt > heldAmt)
                amount = int (floor (double (heldAmt) / itemInfo.sellAmount));
        }
        if (amount < 1)
            amount = 1;

        UpdateData ();
    }

    override void Ticker () {
        UpdateData ();

        if (addButton.curButtonState != S7_ZF_Button.ButtonState_Click && decButton.curButtonState != S7_ZF_Button.ButtonState_Click)
            buttonHeldTics = 0;

        Super.Ticker ();
    }

    void UpdateData () {
        if (!selectedItem)
            return;

        let pPawn = S7_BasePlayer (link.CPlayer.mo);

        if (!pPawn)
            return;

        if (pPawn.playerData && pPawn.playerData.transactData.done) {
            if (pPawn.playerData.transactData.result == 0) {
                pPawn.playerData.transactData.done = false;
                pPawn.playerData.transactData.result = 0;
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
            ( sellMode && (cash + price) >= maxCash) // If selling, check if there's too much money
        ) {
            priceLabel.textColor = Font.CR_DARKRED;
            acceptButton.textColor = Font.CR_DARKGRAY;

            acceptButton.disabled = true;
        }
        if (
            (!sellMode && (selectedItem.GetAmount (pPawn, sellMode) + total) > info.maxAmount) || // If buying, check if there's too much of the item
            ( sellMode && total > selectedItem.GetAmount (pPawn, sellMode)) // If selling, check if there's not enough of the item
        ) {
            selAmount.textColor = Font.CR_DARKRED;
            totalAmount.textColor = Font.CR_DARKRED;
            acceptButton.textColor = Font.CR_DARKGRAY;

            acceptButton.disabled = true;
        }
        if ((!sellMode && !selectedItem.CanBuy  (pPawn, amount)) ||
            ( sellMode && !selectedItem.CanSell (pPawn, amount)))
            acceptButton.disabled = true;

        bool noShowQuant = info.maxAmount == 1;
        addButton.disabled = decButton.disabled = noShowQuant;
        addButton.hidden = decButton.hidden = noShowQuant;
        totalAmount.hidden = selAmount.hidden = noShowQuant;

        int heldAmt = selectedItem.GetAmount (pPawn, sellMode);
        let baseItemInfo = selectedItem.GetInfo (pPawn, 1);
        uint baseAmount = (sellMode ? baseItemInfo.sellAmount : baseItemInfo.buyAmount);

        if ((!sellMode && (info.maxAmount - (total + heldAmt)) < baseAmount) ||
            ( sellMode && total >= heldAmt))
            addButton.disabled = true;
        if (amount >= info.maxAmount)
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

        Menu.MenuSound ("S7Menu/Close");
    }
}
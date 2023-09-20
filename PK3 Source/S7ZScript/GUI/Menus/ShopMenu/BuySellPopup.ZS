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

    override void ButtonClickCommand (S7_ZF_Button caller, string command) {
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

    override void ButtonHeldCommand (S7_ZF_Button caller, string command) {
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

    S7_ZF_BoxImage background;
    S7_ZF_Label modeLabel;

    S7_ZF_Image itemIcon;
    S7_ZF_Label itemName, totalAmount, selAmount, priceLabel;

    S7_ZF_Button addButton, decButton;
    S7_ZF_Button acceptButton, cancelButton;

    S7_SSItem selectedItem;
    bool sellMode;
    uint amount;
    S7_SSItemInfo info;

    int buttonHeldTics;
    bool shiftHeld, ctrlHeld;

    void Config (S7_ShopMenu menuLink) {
        alpha = 1;

        link = menuLink;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        handler = new ('S7_ShopMenu_BuySellPopupHandler');
        handler.link = self;
        handler.menuLink = link;

        let bgBox = S7_ZFMenuUtils.GetCommonMenuBG ();
        background = S7_ZF_BoxImage.Create ((0, 0), GetSize (), textures: bgBox);
        background.Pack (self);

        modeLabel = S7_ZF_Label.Create ((4, 4), (40, 10), text: "", fnt: bigFont, wrap: false, autoSize: true, textColor: Font.CR_White);
        modeLabel.Pack (self);

        itemIcon = S7_ZF_Image.Create ((0, 0), (0, 0), "", S7_ZF_Image.AlignType_TopLeft);
        itemIcon.Pack (self);
        itemName = S7_ZF_Label.Create ((0, 0), (0, 0), text: "", fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_White);
        itemName.Pack (self);

        totalAmount = S7_ZF_Label.Create ((0, 0), (smallFont.StringWidth (String.Format ("%s: 00000", StringTable.Localize ("$SS_TOTAL", true))), smallFont.GetHeight ()),
            text: "", fnt: smallFont, wrap: false, autoSize: false, textColor: Font.CR_White
        );
        totalAmount.Pack (self);
        selAmount = S7_ZF_Label.Create ((0, 0), (smallFont.StringWidth (String.Format ("%s: 00000", StringTable.Localize ("$SS_COUNT", true))), smallFont.GetHeight ()),
            text: "", fnt: smallFont, wrap: false, autoSize: false, textColor: Font.CR_White
        );
        selAmount.Pack (self);
        priceLabel = S7_ZF_Label.Create ((0, 0), (smallFont.StringWidth (String.Format ("%s: 00000000", StringTable.Localize ("$SS_PRICE", true))), smallFont.GetHeight ()),
            text: "", fnt: smallFont, wrap: false, autoSize: false, textColor: Font.CR_White
        );
        priceLabel.Pack (self);

        S7_ZF_BoxTextures smallButtonIdle, smallButtonHover, smallButtonClick;
        [smallButtonIdle, smallButtonHover, smallButtonClick] = S7_ZFMenuUtils.GetSmallButtonTexes ();

        addButton = S7_ZF_Button.Create ((0, 0), (13, 11), text: "+", cmdHandler: handler, command: "Add", fnt: smallFont, holdInterval: 1);
        addButton.SetTextures (smallButtonIdle, smallButtonHover, smallButtonClick, smallButtonIdle);
        addButton.Pack (self);
        decButton = S7_ZF_Button.Create ((0, 0), (13, 11), text: "-", cmdHandler: handler, command: "Dec", fnt: smallFont, holdInterval: 1);
        decButton.SetTextures (smallButtonIdle, smallButtonHover, smallButtonClick, smallButtonIdle);
        decButton.Pack (self);

        let popupButtonIdle = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/Shop/PopupButton.png", true);
        let popupButtonHover = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/Shop/PopupButtonHover.png", true);
        let popupButtonClick = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/Shop/PopupButtonPressed.png", true);

        acceptButton = S7_ZF_Button.Create ((196, 57), (55, 17), text: "", cmdHandler: handler, command: "Accept", fnt: smallFont);
        acceptButton.SetTextures (popupButtonIdle, popupButtonHover, popupButtonClick, popupButtonIdle);
        acceptButton.Pack (self);
        cancelButton = S7_ZF_Button.Create ((259, 57), (55, 17), text: StringTable.Localize ("$SS_CANCELBUTTON", true), cmdHandler: handler, command: "Cancel", fnt: smallFont);
        cancelButton.SetTextures (popupButtonIdle, popupButtonHover, popupButtonClick, popupButtonIdle);
        cancelButton.Pack (self);

        Hide ();
        Disable ();
        SetDontBlockMouse (true);
    }

    static S7_ShopMenu_BuySellPopup CreatePopup (S7_ShopMenu menuLink, S7_ZF_Frame frame) {
        let ret = new ('S7_ShopMenu_BuySellPopup');

        ret.SetBox ((160, 200), (336, 84));
        ret.Pack (frame);
        ret.Config (menuLink);

        return ret;
    }

    override bool OnUIEvent (S7_ZF_UiEvent ev) {
        if (addButton.GetCurButtonState () != S7_ZF_Button.ButtonState_Click && decButton.GetCurButtonState () != S7_ZF_Button.ButtonState_Click &&
            (ev.Type == UIEvent.Type_LButtonClick || ev.Type == UIEvent.Type_LButtonDown)) {
            shiftHeld = ev.IsShift;
            ctrlHeld = ev.IsCtrl;
        }

        return Super.OnUIEvent (ev);
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

        link.shopFrame.Disable ();
        Show ();
        Enable ();
        SetDontBlockMouse (false);

        modeLabel.SetText (StringTable.Localize ((sellMode ? "$SS_SELLMODE" : "$SS_BUYMODE"), true));
        acceptButton.SetText (StringTable.Localize ((sellMode ? "$SS_SELLBUTTON" : "$SS_BUYBUTTON"), true));

        let tex = TexMan.CheckForTexture (selectedItem.icon, TexMan.Type_Any);
        Vector2 texSize = (0, 0);
        if (tex)
            texSize = TexMan.GetScaledSize (tex);

        itemIcon.SetImage (selectedItem.icon);
        itemIcon.SetBox (
            (8, (modeLabel.GetPosY () + bigFont.GetHeight ()) + 4),
            texSize
        );

        itemName.SetText (StringTable.Localize (selectedItem.name, true));
        itemName.SetBox (
            (8 + texSize.X + ((texSize.X > 0) ? 4 : 0), itemIcon.GetPosY ()),
            (smallFont.StringWidth (itemName.GetText ()), smallFont.GetHeight ())
        );

        S7_ZF_AABB actualBox;
        actualBox.pos = itemName.GetPos ();
        actualBox.size = itemName.GetSize ();

        double xCoords = actualBox.pos.X;
        if (info && info.maxAmount != 1) {
            selAmount.SetPos ((xCoords, (actualBox.pos.Y + actualBox.size.Y) + 2));
            totalAmount.SetPos ((xCoords, (selAmount.GetPosY () + selAmount.GetHeight ()) + 2));
            priceLabel.SetPos ((xCoords, (totalAmount.GetPosY () + totalAmount.GetHeight ()) + 2));
            selAmount.Show ();
            totalAmount.Show ();
        } else {
            selAmount.Hide ();
            totalAmount.Hide ();
            priceLabel.SetPos ((xCoords, (actualBox.pos.Y + actualBox.size.Y) + 4));
        }

        addButton.SetPos (((selAmount.GetPosX () + selAmount.GetWidth ()) + 4, selAmount.GetPosY () - 1));
        decButton.SetPos (((addButton.GetPosX () + addButton.GetWidth ()) + 4, addButton.GetPosY ()));

        self.sellMode = sellMode;
        amount = 1;
        UpdateData ();

        Menu.MenuSound ("S7Menu/Open");
    }

    void SetAmount (int addAmount) {
        amount += addAmount;

        let pPawn = S7_BasePlayer (link.CPlayer.mo);
        if (info && amount > uint (info.maxAmount))
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

        if (addButton.GetCurButtonState () != S7_ZF_Button.ButtonState_Click && decButton.GetCurButtonState () != S7_ZF_Button.ButtonState_Click)
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
        totalAmount.SetText (String.Format ("%s: %d", StringTable.Localize ("$SS_TOTAL", true), total));
        selAmount.SetText (String.Format ("%s: %d", StringTable.Localize ("$SS_COUNT", true), amount));
        priceLabel.SetText (String.Format ("%s: %d", StringTable.Localize ("$SS_PRICE", true), price));

        totalAmount.SetTextColor (Font.CR_White);
        selAmount.SetTextColor (Font.CR_White);
        priceLabel.SetTextColor (Font.CR_White);
        acceptButton.SetTextColor (Font.CR_White);

        acceptButton.Enable ();

        Class<Inventory> cashInvType = (Class<Inventory>) (selectedItem.cashItem);
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
            priceLabel.SetTextColor (Font.CR_DarkRed);
            acceptButton.SetTextColor (Font.CR_DarkGray);

            acceptButton.Disable ();
        }
        if (
            (!sellMode && int (selectedItem.GetAmount (pPawn, sellMode) + total) > info.maxAmount) || // If buying, check if there's too much of the item
            ( sellMode && total > selectedItem.GetAmount (pPawn, sellMode)) // If selling, check if there's not enough of the item
        ) {
            selAmount.SetTextColor (Font.CR_DarkRed);
            totalAmount.SetTextColor (Font.CR_DarkRed);
            acceptButton.SetTextColor (Font.CR_DarkGray);

            acceptButton.Disable ();
        }
        if ((!sellMode && !selectedItem.CanBuy  (pPawn, amount)) ||
            ( sellMode && !selectedItem.CanSell (pPawn, amount)))
            acceptButton.Disable ();

        bool noShowQuant = info.maxAmount == 1;
        addButton.SetDisabled (noShowQuant);
        decButton.SetDisabled (noShowQuant);
        addButton.SetHidden (noShowQuant);
        decButton.SetHidden (noShowQuant);
        totalAmount.SetHidden (noShowQuant);
        selAmount.SetHidden (noShowQuant);

        uint heldAmt = uint (selectedItem.GetAmount (pPawn, sellMode));
        let baseItemInfo = selectedItem.GetInfo (pPawn, 1);
        uint baseAmount = (sellMode ? baseItemInfo.sellAmount : baseItemInfo.buyAmount);

        if ((!sellMode && (info.maxAmount - (total + heldAmt)) < baseAmount) ||
            ( sellMode && total >= heldAmt))
            addButton.Disable ();
        if (int (amount) >= info.maxAmount)
            addButton.Disable ();
        if (amount <= 1)
            decButton.Disable ();

        addButton.SetTextColor ((addButton.IsDisabled () ? Font.CR_DarkGray : Font.CR_White));
        decButton.SetTextColor ((decButton.IsDisabled () ? Font.CR_DarkGray : Font.CR_White));
    }

    void Close () {
        link.shopFrame.Enable ();
        Hide ();
        Disable ();
        SetDontBlockMouse (true);

        selectedItem = null;
        if (info)
            info.Destroy ();
        info = null;
        modeLabel.SetText ("");
        itemName.SetText ("");
        itemIcon.SetImage ("");

        Menu.MenuSound ("S7Menu/Close");
    }
}
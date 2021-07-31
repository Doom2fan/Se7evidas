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

class S7_ShopMenu_ListHandler : S7_ZF_Handler {
    S7_ShopMenu link;

    override void ButtonClickCommand (S7_ZF_Button caller, string command) {
        if (command.IndexOf (":") < 0) { // Currently empty
        } else {
            Array<String> commandStrings; commandStrings.Clear ();
            command.Split (commandStrings, ":");

            if (commandStrings.Size () >= 2) {
                if (commandStrings [0] == "Entry")
                    ListSelect (commandStrings [1]);
            }
        }
    }

    void ListSelect (string itemId) {
        if (!link)
            return;

        S7_ShopMenu_ListItem item;
        let list = link.itemsList;
        if (!list)
            return;

        for (int i = 0; i < list.items.Size (); i++) {
            if (list.items [i] && list.items [i].id == itemId.ToInt ()) {
                item = list.items [i];
                break;
            }
        }

        if (!item)
            return;

        if (item.itemData && item.itemData.itemType == IT_PageLink && item.itemData.link) {
            link.selectedItem = null;
            link.hoveredItem = null;
            list.UpdateList ();

            let page = item.itemData.link;
            list.SetPage (page);
            link.SetPage (page);

            Menu.MenuSound ("S7Menu/Choose");
        } else if (link.selectedItem != item) { // If the item isn't already selected
            link.selectedItem = item;
            list.UpdateList ();

            Menu.MenuSound ("S7Menu/SelectionMove");
        } else {
            link.selectedItem = null;
            list.UpdateList ();

            Menu.MenuSound ("S7Menu/SelectionMove");
        }
    }

    override void ElementHoverChanged (S7_ZF_Element caller, string command, bool lostFocus) {
        if (command.IndexOf (":") < 0) { // Currently empty
        } else {
            Array<String> commandStrings; commandStrings.Clear ();
            command.Split (commandStrings, ":");

            if (commandStrings.Size () >= 2) {
                if (commandStrings [0] == "Entry")
                    ListHover (commandStrings [1], lostFocus, (caller && caller.isEnabled ()));
            }
        }
    }

    void ListHover (string itemId, bool lostFocus, bool buttonEnabled) {
        if (!link)
            return;

        S7_ShopMenu_ListItem item;
        let list = link.itemsList;

        if (!list)
            return;

        for (int i = 0; i < list.items.Size (); i++) {
            if (list.items [i] && list.items [i].id == itemId.ToInt ()) {
                item = list.items [i];
                break;
            }
        }

        if (!lostFocus && buttonEnabled)
            link.hoveredItem = item;
        else if (link.hoveredItem == item)
            link.hoveredItem = null;
    }
}

class S7_ShopMenu_List : S7_ZF_Frame {
    S7_ShopMenu_ListHandler handler;

    S7_ShopMenu link;
    S7_SSShop shopData;
    S7_SSPage curPage;

    Font bigFont, smallFont;
    S7_ZF_Image background;
    S7_ZF_Frame clippingFrame, itemsFrame;
    Array<S7_ShopMenu_ListItem> items;
    double lowestCoord;

    void Config (S7_ShopMenu menuLink, S7_SSShop shopData) {
        alpha = 1;

        link = menuLink;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        background = S7_ZF_Image.Create ((0, 0), (200, 400), "graphics/Menu/Shop/ItemList.png", S7_ZF_Image.AlignType_TopLeft);
        background.Pack (self);

        clippingFrame = S7_ZF_Frame.Create ((0, 3), (200, 400 - 3));
        clippingFrame.Pack (self);

        handler = new ('S7_ShopMenu_ListHandler');
        handler.link = link;

        SetShop (shopData);
    }

    static S7_ShopMenu_List CreateList (S7_ShopMenu menuLink, S7_ZF_Frame frame, S7_SSShop shopData) {
        let ret = new ('S7_ShopMenu_List');

        ret.SetBox ((25, 50), (200, 400));
        ret.Pack (frame);
        ret.Config (menuLink, shopData);

        return ret;
    }

    override void Ticker () {
        Super.Ticker ();

        UpdateList ();
    }

    override bool OnUIEvent (S7_ZF_UiEvent ev) {
        if (itemsFrame && itemsFrame.isEnabled ()) {
            if (ev.type == UIEvent.Type_WheelDown) {
                UpdateScroll (-1);
                return true;
            } else if (ev.type == UIEvent.Type_WheelUp) {
                UpdateScroll (+1);
                return true;
            }
        }

        return Super.OnUIEvent (ev);
    }

    void UpdateScroll (double direction) {
        itemsFrame.SetPosY (itemsFrame.GetPosY () + 15 * direction);

        if (itemsFrame && clippingFrame) {
            if (clippingFrame.GetHeight () > itemsFrame.GetHeight ())
                itemsFrame.SetPosY (0);
            else if (itemsFrame.GetPosY () <= -lowestCoord)
                itemsFrame.SetPosY (-lowestCoord);
            else if (itemsFrame.GetPosY () > 0)
                itemsFrame.SetPosY (0);
        }
    }

    void UpdateList () {
        UpdateScroll (0);

        bool sellMode = link.sellMode;
        let pPawn = S7_BasePlayer (link.CPlayer.mo);

        for (int i = items.Size () - 1; i >= 0; i--) {
            let item = items [i];

            if (!item || !item.itemData)
                continue;

            int colour = Font.CR_White;

            if (item == link.selectedItem)
                colour = Font.CR_LightBlue;
            else if (item.itemData.itemType != IT_PageLink) {
                if (
                    (!sellMode && !item.itemData.CanBuy (pPawn, 1)) ||
                    (sellMode && !item.itemData.CanSell (pPawn, 1))
                ) {
                    colour = Font.CR_DarkGray;
                }
            }

            for (int j = item.labels.Size () - 1; j >= 0; j--)
                item.labels [j].SetTextColor (colour);
        }
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

        if (items.Size () > 0) {
            for (int i = items.Size () - 1; i >= 0; i--) {
                if (!items [i])
                    continue;

                items [i].itemData = null;
                if (items [i].clickableArea)
                    items [i].clickableArea = null;
                items [i].labels.Clear ();
                if (items [i].icon)
                    items [i].icon = null;
            }
            items.Clear ();
        }

        if (itemsFrame) {
            itemsFrame.Unpack ();
            itemsFrame = null;
        }

        itemsFrame = S7_ZF_Frame.Create ((0, 3), (200, 0));
        itemsFrame.SetPosY (0);
        itemsFrame.Pack (clippingFrame);

        curPage = page;

        double yCoords = 0.0; // We have to do it like this because entries have variable lengths based on contents
        int loopLimit = curPage.items.Size ();
        for (int i = 0; i < loopLimit; i++) {
            let item = curPage.items [i];
            if (!item)
                continue;
            let itemControls = new ('S7_ShopMenu_ListItem');
            itemControls.id = item.id;
            itemControls.itemData = item;

            let tex = TexMan.CheckForTexture (item.icon, TexMan.Type_Any);
            Vector2 texSize = (0, 0);
            if (tex)
                texSize = TexMan.GetScaledSize (tex);

            // Clickable area
            let button = S7_ZF_Button.Create ((0, yCoords), (200, 40), "", cmdHandler: handler, command: String.Format ("Entry:0x%.8X", item.id), fnt: smallFont);
            button.Pack (itemsFrame);
            itemControls.clickableArea = button;

            // Text
            double textX = 8;
            double textY = yCoords + 4;
            if (texSize.X > 0)
                textX = texSize.X + 8 * 2;
            BrokenLines textLines = smallFont.BreakLines (StringTable.Localize (item.name, true), int (200 - (texSize.X + 8 * 3)));

            double clickHeight = (smallFont.GetHeight () * textLines.Count ());
            if (texSize.Y > clickHeight) {
                textY = yCoords + 4 + (texSize.Y - clickHeight) / 2;
                clickHeight = texSize.Y;
            }

            for (int i = 0; i < textLines.Count (); i++) {
                double fHeight = smallFont.GetHeight ();
                let label = S7_ZF_Label.Create ((textX, textY + (fHeight * i)), (textLines.stringWidth (i), fHeight), text: textLines.StringAt (i),
                    fnt: smallFont, wrap: false, textColor: Font.CR_White
                );
                label.SetDontBlockMouse (true);
                label.Pack (itemsFrame);
                itemControls.labels.Push (label);
            }

            button.SetHeight (clickHeight + 4 * 2);
            // Icon
            let icon = S7_ZF_Image.Create ((8, yCoords + 4 + (clickHeight - texSize.Y) / 2), texSize, item.icon);
            icon.SetDontBlockMouse (true);
            icon.Pack (itemsFrame);
            itemControls.icon = icon;

            items.Push (itemControls);
            lowestCoord = yCoords;
            yCoords += button.GetHeight ();

            let sep = S7_ZF_Image.Create ((0, yCoords), (200, 2), "graphics/Menu/Shop/ListSep.png");
            sep.SetDontBlockMouse (true);
            sep.Pack (itemsFrame);
            yCoords += 2;
        }

        itemsFrame.SetHeight (yCoords);

        return true;
    }
}
class S7_ShopMenu_ListHandler : S7_ZF_Handler {
    S7_ShopMenu link;

    override void buttonCommand (S7_ZF_Button caller, string command) {
        if (command.IndexOf (":") < 0) { // Currently empty
        } else {
            Array<String> commandStrings;
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

    override void elementHoverChanged (S7_ZF_Element caller, string command, bool lostFocus) {
        if (command.IndexOf (":") < 0) { // Currently empty
        } else {
            Array<String> commandStrings;
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
            link.hoveredItem = NULL;
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

    S7_ShopMenu_List InitList (S7_ShopMenu menuLink, S7_ZF_Frame frame, S7_SSShop shopData) {
        self.Init ((25, 50), (200, 400));
        self.Pack (frame);
        link = menuLink;

        bigFont = Font.GetFont ("BigFont");
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        background = new ("S7_ZF_Image").Init ((0, 0), (200, 400), "graphics/Menu/Shop/ItemList.png", S7_ZF_Image.AlignTopLeft);
        background.Pack (self);

        clippingFrame = new ("S7_ZF_Frame").Init ((0, 3), (200, 400 - 3));
        clippingFrame.Pack (self);

        handler = new ("S7_ShopMenu_ListHandler");
        handler.link = link;

        SetShop (shopData);

        return self;
    }

    override void Ticker () {
        Super.Ticker ();
        UpdateScroll ();
    }

    override void OnUIEvent (UIEvent ev) { // Type_WheelUp
        Super.OnUIEvent (ev);

        if (itemsFrame && !itemsFrame.disabled) {
            if (ev.type == UIEvent.Type_WheelDown) {
                itemsFrame.box.pos.Y -= 15;
                UpdateScroll ();
            } else if (ev.type == UIEvent.Type_WheelUp) {
                itemsFrame.box.pos.Y += 15;
                UpdateScroll ();
            }
        }
    }

    void UpdateScroll () {
        if (itemsFrame && clippingFrame) {
            if (clippingFrame.box.size.Y > itemsFrame.box.size.Y)
                itemsFrame.box.pos.Y = 0;
            else if (itemsFrame.box.pos.Y <= -lowestCoord)
                itemsFrame.box.pos.Y = -lowestCoord;
            else if (itemsFrame.box.pos.Y > 0)
                itemsFrame.box.pos.Y = 0;
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

        if (items.Size () >= 0) {
            for (int i = items.Size () - 1; i > 0; i--) {
                if (!items [i])
                    continue;

                items [i].itemData = NULL;
                if (items [i].clickableArea) {
                    items [i].clickableArea.master = NULL;
                    items [i].clickableArea.Destroy ();
                    items [i].clickableArea = NULL;
                }
                items [i].labels.Clear ();
                if (items [i].icon) {
                    items [i].icon.master = NULL;
                    items [i].icon.Destroy ();
                    items [i].icon = NULL;
                }
            }
            items.Clear ();
        }

        if (itemsFrame && clippingFrame) {
            if (clippingFrame.elements.Find (itemsFrame) != clippingFrame.elements.Size ())
                clippingFrame.elements.Delete (clippingFrame.elements.Find (itemsFrame));

            itemsFrame.master = NULL;
            itemsFrame.Destroy ();
            itemsFrame = NULL;
        }

        itemsFrame = new ("S7_ZF_Frame").Init ((0, 3), (200, 0));
        itemsFrame.Pack (clippingFrame);

        curPage = page;

        double yCoords = 0.0; // We have to do it like this because entries have variable lengths based on contents
        int loopLimit = curPage.items.Size ();
        for (int i = 0; i < loopLimit; i++) {
            let item = curPage.items [i];
            if (!item)
                continue;
            let itemControls = new ("S7_ShopMenu_ListItem");
            itemControls.id = item.id;
            itemControls.itemData = item;

            if (i > 0) {
                let sep = new ("S7_ZF_Image").Init ((0, yCoords), (200, 2), "graphics/Menu/Shop/ListSep.png");
                sep.Pack (itemsFrame);
                yCoords += 2;
            }

            let tex = TexMan.CheckForTexture (item.icon, TexMan.Type_Any);
            Vector2 texSize = (0, 0);
            if (tex)
                texSize = TexMan.GetScaledSize (tex);

            // Clickable area
            let button = new ("S7_ZF_Button").Init ((0, yCoords), (200, 40), "", handler, String.Format ("Entry:0x%.8X", item.id), null, null, null, null, null);
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
            lowestCoord = yCoords;
            yCoords += button.box.size.Y;
        }

        itemsFrame.box.size.Y = yCoords;
        itemsFrame.box.pos.Y = 0;

        return true;
    }

    void Select (S7_ShopMenu_ListItem item) {
        Array<S7_ZF_Label> labels;
        for (int i = 0; i < items.Size (); i++) {
            if (!items [i])
                return;

            labels.Copy (items [i].labels);
            for (int j = 0; j < labels.Size (); j++)
                labels [j].textColor = (items [i] == item ? Font.CR_RED : Font.CR_WHITE);
            labels.Clear ();
        }
    }
}
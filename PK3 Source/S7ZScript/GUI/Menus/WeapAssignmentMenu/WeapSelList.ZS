class S7_WeapAssignMenu_ListHandler : S7_ZF_Handler {
    S7_WeapAssignMenu link;

    override void buttonCommand (S7_ZF_Button caller, string command) {
        if (command.IndexOf (":") < 0) { // Currently empty
        } else {
            Array<String> commandStrings;
            command.Split (commandStrings, ":");

            if (commandStrings.Size () >= 2) {
                if (commandStrings [0] == "Weapon")
                    link.SetWeapon (commandStrings [1]);
            }
        }
    }

    override void elementHoverChanged (S7_ZF_Element caller, string command, bool lostFocus) {
        Array<String> commandStrings;
        command.Split (commandStrings, ":");

        if (commandStrings.Size () >= 2) {
            if (commandStrings [0] == "Weapon")
                ListHover (commandStrings [1], lostFocus);
        }
    }

    void ListHover (string weaponName, bool lostFocus) {
        S7_WeapAssignMenu_ListWeap item;
        let list = link.itemsList;
        for (int i = 0; i < list.items.Size (); i++) {
            if (list.items [i].weaponName ~== weaponName) {
                item = list.items [i];
                break;
            }
        }

        if (!item)
            return;

        if (!lostFocus)
            link.hoveredWeap = item.weaponInst;
        else if (link.hoveredWeap == item.weaponInst)
            link.hoveredWeap = NULL;
    }
}

class S7_WeapAssignMenu_List : S7_ZF_Frame {
    S7_WeapAssignMenu_ListHandler handler;

    S7_WeapAssignMenu link;
    S7_BasePlayer CPlayer;

    Font bigFont, smallFont;
    S7_ZF_Image background;
    S7_ZF_Frame clippingFrame, itemsFrame;
    Array<S7_WeapAssignMenu_ListWeap> items;
    double lowestCoord;
    Vector2 mousePos;

    S7_WeapAssignMenu_List InitList (S7_WeapAssignMenu menuLink, S7_ZF_Frame frame, S7_BasePlayer pPawn) {
        self.Init ((19, 12), (200, 246));
        self.Pack (frame);
        link = menuLink;

        bigFont = Font.GetFont ("BigFont");
        smallFont = Font.GetFont ("SmallFont");

        background = new ("S7_ZF_Image").Init ((0, 0), (200, 246), "graphics/Menu/WeapAssignment/ListBG.png", S7_ZF_Image.AlignTopLeft);
        background.Pack (self);

        clippingFrame = new ("S7_ZF_Frame").Init ((0, 3), (200, 246 - 3 - 5));
        clippingFrame.Pack (self);

        handler = new ("S7_WeapAssignMenu_ListHandler");
        handler.link = link;

        CPlayer = pPawn;

        return self;
    }

    override void Ticker () {
        Super.Ticker ();
        UpdateScroll ();
    }

    override void OnUIEvent (UIEvent ev) {
        Super.OnUIEvent (ev);

        if (ev.type == UIEvent.Type_MouseMove)
            mousePos = (ev.mouseX, ev.mouseY);

        if (itemsFrame && !itemsFrame.disabled && boxToScreen ().pointCollides (mousePos)) {
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
        if (itemsFrame) {
            if (clippingFrame.box.size.Y > itemsFrame.box.size.Y)
                itemsFrame.box.pos.Y = 0;
            else if (itemsFrame.box.pos.Y <= -lowestCoord)
                itemsFrame.box.pos.Y = -lowestCoord;
            else if (itemsFrame.box.pos.Y > 0)
                itemsFrame.box.pos.Y = 0;
        }
    }

    void Activate (S7_WeaponSlots slot) {
        PopulateList (slot);
    }

    void Deactivate () {
        if (items.Size () > 0) {
            for (int i = items.Size () - 1; i > 0; i--) {
                if (!items [i])
                    continue;

                items [i].weaponInst = NULL;
                if (items [i].clickableArea) {
                    items [i].clickableArea.Destroy ();
                    items [i].clickableArea = NULL;
                }
                items [i].labels.Clear ();
                if (items [i].icon) {
                    items [i].icon.Destroy ();
                    items [i].icon = NULL;
                }
                items [i].Destroy ();
            }
            items.Clear ();
        }
        if (itemsFrame && clippingFrame.elements.Find (itemsFrame) != clippingFrame.elements.Size ()) {
            clippingFrame.elements.Delete (clippingFrame.elements.Find (itemsFrame));
            itemsFrame.master = NULL;
            itemsFrame.Destroy ();
            itemsFrame = NULL;
        }
    }

    bool PopulateList (S7_WeaponSlots slot) {
        if (!CPlayer || slot < 0)
            return false;

        if (items.Size () > 0) {
            for (int i = items.Size () - 1; i > 0; i--) {
                if (!items [i])
                    continue;

                items [i].weaponInst = NULL;
                if (items [i].clickableArea) {
                    items [i].clickableArea.Destroy ();
                    items [i].clickableArea = NULL;
                }
                items [i].labels.Clear ();
                if (items [i].icon) {
                    items [i].icon.Destroy ();
                    items [i].icon = NULL;
                }
                items [i].Destroy ();
            }
            items.Clear ();
        }
        if (itemsFrame && clippingFrame.elements.Find (itemsFrame) != clippingFrame.elements.Size ()) {
            clippingFrame.elements.Delete (clippingFrame.elements.Find (itemsFrame));
            itemsFrame.master = NULL;
            itemsFrame.Destroy ();
            itemsFrame = NULL;
        }

        itemsFrame = new ("S7_ZF_Frame").Init ((0, 3), (200, 0));
        itemsFrame.Pack (clippingFrame);

        double yCoords = 0.0; // We have to do it like this because entries have variable lengths based on contents

        if (link.selectedX >= 0 && link.selectedY >= 0 && link.weapBinds.BindUsed (link.selectedX + 1, link.selectedY)) {
            let weapControls = new ("S7_WeapAssignMenu_ListWeap");
            weapControls.weaponName = "@__NoWeapon__";
            weapControls.weaponInst = NULL;

            Vector2 texSize = (0, 0);

            // Clickable area
            let button = new ("S7_ZF_Button").Init ((0, yCoords), (200, 40), "", handler, "Weapon:@__NoWeapon__", null, null, null, null, null);
            button.SetTexture ("", "", "", "");
            button.Pack (itemsFrame);
            weapControls.clickableArea = button;

            // Text
            double textX = 8;
            double textY = yCoords + 4;
            if (texSize.X > 0)
                textX = texSize.X + 8 * 2;
            BrokenLines textLines = smallFont.BreakLines (StringTable.Localize ("$WPBNDMENU_UNSETWP", true), 200 - (texSize.X + 8 * 3));

            double clickHeight = (smallFont.GetHeight () * textLines.Count ());
            if (texSize.Y > clickHeight) {
                textY = yCoords + 4 + (texSize.Y - clickHeight) / 2;
                clickHeight = texSize.Y;
            }

            for (int i = 0; i < textLines.Count (); i++) {
                double fHeight = smallFont.GetHeight ();
                let label = new ("S7_ZF_Label").Init ((textX, textY + (fHeight * i)), (textLines.stringWidth (i), fHeight), textLines.StringAt (i), smallFont, false, false, 1, Font.CR_WHITE);
                label.Pack (itemsFrame);
                weapControls.labels.Push (label);
            }

            button.box.size.Y = clickHeight + 4 * 2;
            // Icon
            /*let icon = new ("S7_ZF_Image").Init ((8, yCoords + 4 + (clickHeight - texSize.Y) / 2), texSize, weap.weapIcon, noOffsets: true);
            icon.Pack (itemsFrame);
            weapControls.icon = icon;*/

            items.Push (weapControls);
            lowestCoord = yCoords;
            yCoords += button.box.size.Y;
        }

        let inv = CPlayer.inv;
        while (inv) {
            if (!(inv is "S7_BaseWeapon")) {
                inv = inv.inv;
                continue;
            }

            let weap = S7_BaseWeapon (inv);
            let tex = TexMan.CheckForTexture (weap.weapIcon, TexMan.Type_Any);
            if ((weap.shortTag == "" && !tex.IsValid ()) || weap.bindSlot != slot || link.weapBinds.WeaponBound (weap)) {
                inv = inv.inv;
                continue;
            }

            let weapControls = new ("S7_WeapAssignMenu_ListWeap");
            weapControls.weaponName = weap.GetClassName ();
            weapControls.weaponInst = weap;

            if (yCoords > 0) {
                let sep = new ("S7_ZF_Image").Init ((0, yCoords), (200, 2), "graphics/Menu/WeapAssignment/ListSep.png");
                sep.Pack (itemsFrame);
                yCoords += 2;
            }

            Vector2 texSize = (0, 0);
            if (tex)
                texSize = TexMan.GetScaledSize (tex);

            // Clickable area
            let button = new ("S7_ZF_Button").Init ((0, yCoords), (200, 40), "", handler, String.Format ("Weapon:%s", weapControls.weaponName), null, null, null, null, null);
            button.SetTexture ("", "", "", "");
            button.Pack (itemsFrame);
            weapControls.clickableArea = button;

            // Text
            double textX = 8;
            double textY = yCoords + 4;
            if (texSize.X > 0)
                textX = texSize.X + 8 * 2;
            BrokenLines textLines = smallFont.BreakLines (StringTable.Localize (weap.shortTag, true), 200 - (texSize.X + 8 * 3));

            double clickHeight = (smallFont.GetHeight () * textLines.Count ());
            if (texSize.Y > clickHeight) {
                textY = yCoords + 4 + (texSize.Y - clickHeight) / 2;
                clickHeight = texSize.Y;
            }

            for (int i = 0; i < textLines.Count (); i++) {
                double fHeight = smallFont.GetHeight ();
                let label = new ("S7_ZF_Label").Init ((textX, textY + (fHeight * i)), (textLines.stringWidth (i), fHeight), textLines.StringAt (i), smallFont, false, false, 1, Font.CR_WHITE);
                label.Pack (itemsFrame);
                weapControls.labels.Push (label);
            }

            button.box.size.Y = clickHeight + 4 * 2;
            // Icon
            let icon = new ("S7_ZF_Image").Init ((8, yCoords + 4 + (clickHeight - texSize.Y) / 2), texSize, weap.weapIcon, noOffsets: true);
            icon.Pack (itemsFrame);
            weapControls.icon = icon;

            items.Push (weapControls);
            lowestCoord = yCoords;
            yCoords += button.box.size.Y;

            inv = inv.inv;
        }

        itemsFrame.box.size.Y = yCoords + 50;
        itemsFrame.box.pos.Y = 0;

        return true;
    }

    void Select (S7_WeapAssignMenu_ListWeap item) {
        Array<S7_ZF_Label> labels;
        for (int i = 0; i < items.Size (); i++) {
            labels.Copy (items [i].labels);
            for (int j = 0; j < labels.Size (); j++)
                labels [j].textColor = (items [i] == item ? Font.CR_RED : Font.CR_WHITE);
            labels.Clear ();
        }
    }
}
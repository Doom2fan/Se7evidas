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

class S7_WeaponEnchantmentMenu_ListHandler : S7_ZF_Handler {
    S7_WeaponEnchantmentMenu link;

    S7_WeapAssignMenu_ListWeap FindWeap (string weaponName) {
        if (!link)
            return null;

        let list = link.itemsList;
        if (!list)
            return null;

        S7_WeapAssignMenu_ListWeap item = null;

        for (int i = 0; i < list.items.Size (); i++) {
            if (list.items [i] && list.items [i].weaponName ~== weaponName) {
                item = list.items [i];
                break;
            }
        }

        return item;
    }

    override void buttonClickCommand (S7_ZF_Button caller, string command) {
        if (command.IndexOf (":") < 0) { // Currently empty
        } else {
            Array<String> commandStrings; commandStrings.Clear ();
            command.Split (commandStrings, ":");

            if (commandStrings.Size () >= 2) {
                if (link && commandStrings [0] == "Weapon") {
                    let item = FindWeap (commandStrings [1]);

                    if (!item)
                        return;

                    if (link.selectedWeap != item.weaponInst) {
                        link.selectedWeap = item.weaponInst;
                        link.itemsList.Select (item);
                    } else {
                        link.selectedWeap = null;
                        link.itemsList.Select (null);
                    }

                    link.enchantmentPower = 1;

                    Menu.MenuSound ("S7Menu/SelectionMove");
                }
            }
        }
    }
}

class S7_WeaponEnchantmentMenu_List : S7_ZF_Frame {
    S7_WeaponEnchantmentMenu_ListHandler handler;

    S7_WeaponEnchantmentMenu link;
    S7_BasePlayer CPlayer;

    Font bigFont, smallFont;
    S7_ZF_Image background;
    S7_ZF_Frame clippingFrame, itemsFrame;
    Array<S7_WeapAssignMenu_ListWeap> items;
    double lowestCoord;

    void Config (S7_WeaponEnchantmentMenu menuLink, S7_ZF_Frame frame, S7_BasePlayer pPawn) {
        alpha = 1;

        link = menuLink;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');
        background = S7_ZF_Image.Create ((0, 0), (200, 400), "graphics/Menu/Shop/ItemList.png", S7_ZF_Image.AlignType_TopLeft);
        background.Pack (self);

        clippingFrame = S7_ZF_Frame.Create ((0, 3), (200, 400 - 3));
        clippingFrame.Pack (self);

        handler = new ('S7_WeaponEnchantmentMenu_ListHandler');
        handler.link = link;

        CPlayer = pPawn;
    }

    static S7_WeaponEnchantmentMenu_List CreateList (S7_WeaponEnchantmentMenu menuLink, S7_ZF_Frame frame, S7_BasePlayer pPawn) {
        let ret = new ('S7_WeaponEnchantmentMenu_List');

        ret.SetBox ((25, 50), (200, 400));
        ret.Pack (frame);
        ret.Config (menuLink, frame, pPawn);

        return ret;
    }

    override void Ticker () {
        Super.Ticker ();
        UpdateScroll ();
    }

    override void OnUIEvent (S7_ZF_UiEvent ev) { // Type_WheelUp
        Super.OnUIEvent (ev);

        if (itemsFrame && itemsFrame.isEnabled ()) {
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

    bool PopulateList () {
        if (!CPlayer)
            return false;

        if (itemsFrame && clippingFrame && clippingFrame.elements.Find (itemsFrame) != clippingFrame.elements.Size ()) {
            clippingFrame.elements.Delete (clippingFrame.elements.Find (itemsFrame));
            itemsFrame.master = null;
            itemsFrame.Destroy ();
            itemsFrame = null;
        }
        if (items.Size () > 0) {
            for (int i = items.Size () - 1; i >= 0; i--) {
                if (!items [i])
                    continue;

                items [i].weaponInst = null;
                if (items [i].clickableArea) {
                    items [i].clickableArea.Destroy ();
                    items [i].clickableArea = null;
                }
                items [i].labels.Clear ();
                if (items [i].icon) {
                    items [i].icon.Destroy ();
                    items [i].icon = null;
                }
            }
            items.Clear ();
        }

        itemsFrame = S7_ZF_Frame.Create ((0, 3), (200, 0));
        itemsFrame.Pack (clippingFrame);

        double yCoords = 0.0; // We have to do it like this because entries have variable lengths based on contents

        let inv = CPlayer.inv;
        while (inv) {
            if (!(inv is 'S7_BaseWeapon')) {
                inv = inv.inv;
                continue;
            }

            let weap = S7_BaseWeapon (inv);
            let tex = TexMan.CheckForTexture (weap.weapIcon, TexMan.Type_Any);
            if (
                (weap.shortTag == "" && !tex.IsValid ()) ||
                (!weap.enchantment_canEnchant)
            ) {
                inv = inv.inv;
                continue;
            }

            let weapControls = new ('S7_WeapAssignMenu_ListWeap');
            weapControls.weaponName = weap.GetClassName ();
            weapControls.weaponInst = weap;

            Vector2 texSize = (0, 0);
            if (tex)
                texSize = TexMan.GetScaledSize (tex);

            // Clickable area
            let button = S7_ZF_Button.Create ((0, yCoords), (200, 40), "", cmdHandler: handler, command: String.Format ("Weapon:%s", weapControls.weaponName), null, null, null, null, null);
            button.Pack (itemsFrame);
            weapControls.clickableArea = button;

            // Text
            double textX = 8;
            double textY = yCoords + 4;
            if (texSize.X > 0)
                textX = texSize.X + 8 * 2;
            BrokenLines textLines = smallFont.BreakLines (StringTable.Localize (weap.shortTag, true), int (200 - (texSize.X + 8 * 3)));

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
                label.Pack (itemsFrame);
                weapControls.labels.Push (label);
            }

            button.box.size.Y = clickHeight + 4 * 2;
            // Icon
            let icon = S7_ZF_Image.Create ((8, yCoords + 4 + (clickHeight - texSize.Y) / 2), texSize, weap.weapIcon);
            icon.Pack (itemsFrame);
            weapControls.icon = icon;

            items.Push (weapControls);
            lowestCoord = yCoords;
            yCoords += button.box.size.Y;

            let sep = S7_ZF_Image.Create ((0, yCoords), (200, 2), "graphics/Menu/WeapAssignment/ListSep.png");
            sep.Pack (itemsFrame);
            yCoords += 2;

            inv = inv.inv;
        }

        itemsFrame.box.size.Y = yCoords + 50;
        itemsFrame.box.pos.Y = 0;

        return true;
    }

    void Select (S7_WeapAssignMenu_ListWeap item) {
        for (int i = 0; i < items.Size (); i++) {
            if (!items [i])
                continue;

            for (int j = 0; j < items [i].labels.Size (); j++)
                items [i].labels [j].textColor = (items [i] == item ? Font.CR_LightBlue : Font.CR_White);
        }
    }
}
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

class S7_WeapAssignMenu_ListHandler : S7_ZF_Handler {
    S7_WeapAssignMenu link;

    override void ButtonClickCommand (S7_ZF_Button caller, string command) {
        if (command.IndexOf (":") < 0) { // Currently empty
        } else {
            Array<String> commandStrings; commandStrings.Clear ();
            command.Split (commandStrings, ":");

            if (commandStrings.Size () >= 2) {
                if (link && commandStrings [0] == "Weapon")
                    link.SetWeapon (commandStrings [1]);
            }
        }
    }

    override void ElementHoverChanged (S7_ZF_Element caller, string command, bool lostFocus) {
        Array<String> commandStrings; commandStrings.Clear ();
        command.Split (commandStrings, ":");

        if (commandStrings.Size () >= 2) {
            if (commandStrings [0] == "Weapon")
                ListHover (commandStrings [1], lostFocus);
        }
    }

    void ListHover (string weaponName, bool lostFocus) {
        if (!link)
            return;

        S7_WeapAssignMenu_ListWeap item;
        let list = link.itemsList;
        if (!list)
            return;

        for (int i = 0; i < list.items.Size (); i++) {
            if (list.items [i] && list.items [i].weaponName ~== weaponName) {
                item = list.items [i];
                break;
            }
        }

        if (!item)
            return;

        if (!lostFocus)
            link.hoveredWeap = item.weaponInst;
        else if (link.hoveredWeap == item.weaponInst)
            link.hoveredWeap = null;
    }
}

class S7_WeapAssignMenu_List : S7_ZF_Frame {
    S7_WeapAssignMenu_ListHandler handler;

    S7_WeapAssignMenu link;
    S7_BasePlayer CPlayer;

    protected Font bigFont, smallFont;
    protected S7_ZF_Image background;
    protected S7_ZF_Frame clippingFrame, itemsFrame;
    Array<S7_WeapAssignMenu_ListWeap> items;
    protected double lowestCoord;
    protected Vector2 mousePos;
    protected bool isDraco;

    protected S7_WeaponSlots activateRequest;
    protected bool deactivateRequest;

    void Config (S7_WeapAssignMenu menuLink, S7_BasePlayer pPawn, bool draco) {
        alpha = 1;

        link = menuLink;
        isDraco = draco;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        background = S7_ZF_Image.Create ((0, 0), (200, 246), "graphics/Menu/WeapAssignment/ListBG.png", S7_ZF_Image.AlignType_TopLeft);
        background.Pack (self);

        clippingFrame = S7_ZF_Frame.Create ((0, 3), (200, 246 - 3 - 5));
        clippingFrame.Pack (self);

        handler = new ('S7_WeapAssignMenu_ListHandler');
        handler.link = link;

        CPlayer = pPawn;
    }

    static S7_WeapAssignMenu_List CreateList (S7_WeapAssignMenu menuLink, S7_ZF_Frame frame, S7_BasePlayer pPawn, bool draco) {
        let ret = new ('S7_WeapAssignMenu_List');

        ret.SetBox ((19, 12), (200, 246));
        ret.Pack (frame);
        ret.Config (menuLink, pPawn, draco);

        return ret;
    }

    override void Ticker () {
        Super.Ticker ();
        if (activateRequest != -1) {
            DoActivate (activateRequest);
            activateRequest = -1;
        }

        if (deactivateRequest) {
            DoDeactivate ();
            deactivateRequest = false;
        }

        UpdateScroll ();
    }

    override bool OnUIEvent (S7_ZF_UiEvent ev) {
        if (itemsFrame && !itemsFrame.IsDisabled () && ContainsMouse ()) {
            if (ev.type == UIEvent.Type_WheelDown) {
                itemsFrame.SetPosY (itemsFrame.GetPosY () - 15);
                UpdateScroll ();
                return true;
            } else if (ev.type == UIEvent.Type_WheelUp) {
                itemsFrame.SetPosY (itemsFrame.GetPosY () + 15);
                UpdateScroll ();
                return true;
            }
        }

        return Super.OnUIEvent (ev);
    }

    protected void UpdateScroll () {
        if (itemsFrame && clippingFrame) {
            if (clippingFrame.GetHeight () > itemsFrame.GetHeight ())
                itemsFrame.SetPosY (0);
            else if (itemsFrame.GetPosY () <= -lowestCoord)
                itemsFrame.SetPosY (-lowestCoord);
            else if (itemsFrame.GetPosY () > 0)
                itemsFrame.SetPosY (0);
        }
    }

    void Activate (S7_WeaponSlots slot) {
        activateRequest = slot;
    }

    void Deactivate () {
        deactivateRequest = true;
    }

    protected void DoActivate (S7_WeaponSlots slot) {
        PopulateList (slot);
    }

    protected void DoDeactivate () {
        if (items.Size () > 0) {
            for (int i = items.Size () - 1; i >= 0; i--) {
                if (!items [i])
                    continue;

                items [i].weaponInst = null;
                if (items [i].clickableArea) {
                    items [i].clickableArea.Unpack ();
                    items [i].clickableArea = null;
                }
                items [i].labels.Clear ();
                if (items [i].icon) {
                    items [i].icon.Unpack ();
                    items [i].icon = null;
                }
            }
            items.Clear ();
        }

        if (itemsFrame) {
            itemsFrame.Unpack ();
            itemsFrame = null;
        }
    }

    protected bool PopulateList (S7_WeaponSlots slot) {
        if (!CPlayer || slot < 0)
            return false;

        if (items.Size () > 0) {
            for (int i = items.Size () - 1; i >= 0; i--) {
                if (!items [i])
                    continue;

                items [i].weaponInst = null;
                if (items [i].clickableArea) {
                    items [i].clickableArea.Unpack ();
                    items [i].clickableArea.Destroy ();
                    items [i].clickableArea = null;
                }
                items [i].labels.Clear ();
                if (items [i].icon) {
                    items [i].icon.Unpack ();
                    items [i].icon.Destroy ();
                    items [i].icon = null;
                }
            }
            items.Clear ();
        }

        if (itemsFrame) {
            itemsFrame.Unpack ();
            itemsFrame = null;
        }

        itemsFrame = S7_ZF_Frame.Create ((0, 3), (200, 0));
        itemsFrame.Pack (clippingFrame);

        double yCoords = 0.0; // We have to do it like this because entries have variable lengths based on contents

        if (link.selectedX >= 0 && link.selectedY >= 0 && link.weapBinds.BindUsed (link.selectedX + 1, link.selectedY, isDraco)) {
            let weapControls = new ('S7_WeapAssignMenu_ListWeap');
            weapControls.weaponName = "@__NoWeapon__";
            weapControls.weaponInst = null;

            Vector2 texSize = (0, 0);

            // Clickable area
            let button = S7_ZF_Button.Create ((0, yCoords), (200, 40), "", cmdHandler: handler, command: "Weapon:@__NoWeapon__", null, null, null, null, null);
            button.Pack (itemsFrame);
            weapControls.clickableArea = button;

            // Text
            double textX = 8;
            double textY = yCoords + 4;
            if (texSize.X > 0)
                textX = texSize.X + 8 * 2;
            BrokenLines textLines = smallFont.BreakLines (StringTable.Localize ("$WPBNDMENU_UNSETWP", true), int (200 - (texSize.X + 8 * 3)));

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
                weapControls.labels.Push (label);
            }

            button.SetHeight (clickHeight + 4 * 2);

            items.Push (weapControls);
            lowestCoord = yCoords;
            yCoords += button.GetHeight ();

            let sep = S7_ZF_Image.Create ((0, yCoords), (200, 2), "graphics/Menu/WeapAssignment/ListSep.png");
            sep.SetDontBlockMouse (true);
            sep.Pack (itemsFrame);
            yCoords += 2;
        }

        let inv = CPlayer.inv;
        while (inv) {
            if (!(inv is 'S7_BaseWeapon') ||
                (!isDraco &&  (inv is 'S7_DracoWeapon')) ||
                ( isDraco && !(inv is 'S7_DracoWeapon'))
            ) {
                inv = inv.inv;
                continue;
            }

            let weap = S7_BaseWeapon (inv);
            let tex = TexMan.CheckForTexture (weap.weapIcon, TexMan.Type_Any);
            if ((weap.shortTag == "" && !tex.IsValid ()) || (!isDraco && weap.bindSlot != slot) || link.weapBinds.WeaponBound (weap, isDraco)) {
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
                label.SetDontBlockMouse (true);
                label.Pack (itemsFrame);
                weapControls.labels.Push (label);
            }

            button.SetHeight (clickHeight + 4 * 2);
            // Icon
            let icon = S7_ZF_Image.Create ((8, yCoords + 4 + (clickHeight - texSize.Y) / 2), texSize, weap.weapIcon);
            icon.SetDontBlockMouse (true);
            icon.Pack (itemsFrame);
            weapControls.icon = icon;

            items.Push (weapControls);
            lowestCoord = yCoords;
            yCoords += button.GetHeight ();

            let sep = S7_ZF_Image.Create ((0, yCoords), (200, 2), "graphics/Menu/WeapAssignment/ListSep.png");
            sep.SetDontBlockMouse (true);
            sep.Pack (itemsFrame);
            yCoords += 2;

            inv = inv.inv;
        }

        itemsFrame.SetHeight (yCoords + 50);
        itemsFrame.SetPosY (0);

        return true;
    }

    void Select (S7_WeapAssignMenu_ListWeap item) {
        for (int i = 0; i < items.Size (); i++) {
            if (!items [i])
                continue;

            for (int j = 0; j < items [i].labels.Size (); j++)
                items [i].labels [j].SetTextColor (items [i] == item ? Font.CR_LightBlue : Font.CR_White);
        }
    }
}
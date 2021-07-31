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

class S7_WeapAssignMenuHandler : S7_ZF_Handler {
    S7_WeapAssignMenu link;

    override void ButtonClickCommand (S7_ZF_Button caller, string command) {
        Array<String> strings; strings.Clear ();
        command.Split (strings, ":");

        if (strings [0] ~== "SetSlot" && strings.Size () == 2) {
            Array<String> coords; coords.Clear ();
            strings [1].Split (coords, ",");

            if (coords.Size () == 2) {
                int selectedX = coords [0].ToInt (),
                    selectedY = coords [1].ToInt ();

                if (link.selectedX == selectedX && link.selectedY == selectedY) {
                    selectedX = -1;
                    selectedY = -1;
                }

                link.selectedX = selectedX;
                link.selectedY = selectedY;

                link.ActivateSelFrame (selectedX + 1);

                Menu.MenuSound ("S7Menu/Choose");
            }
        }
    }
}

class S7_WeapAssignMenu_ListWeap {
    string weaponName;
    S7_ZF_Button clickableArea;
    Array<S7_ZF_Label> labels;
    S7_ZF_Image icon;
    S7_BaseWeapon weaponInst;
}

class S7_WeapAssignMenu : S7_ZF_GenericMenu {
    S7_WeapAssignMenuHandler handler;

    PlayerInfo CPlayer;
    S7_WeapBindsSystem weapBinds;

    Font bigFont;
    Font smallFont;
    Font textBigFont;

    S7_ZF_BoxTextures weapSlotIdle, weapSlotHover;
    S7_ZF_BoxTextures weapSlotClick, weapSlotDisabled;

    S7_ZF_Frame slotsFrame, weapSelFrame;
    S7_WeapAssignMenu_List itemsList;
    S7_ZF_Image infoBG;
    S7_ZF_Label infoNameLabel;
    S7_ZF_Label infoLabel;
    S7_ZF_Button slotButtons [5] [3];
    S7_ZF_Image  slotImages  [5] [3];

    int selectedX, selectedY;
    S7_BaseWeapon hoveredWeap;

    bool isDraco;

    static const String weapLabelsText [] = {
        "Medium", "Light", "Heavy", "Area-damage", "Special"
    };
    override void Init (Menu parent) {
        Super.Init (parent);
        SetBaseResolution ((640, 480));
        menuactive = Menu.OnNoPause;

        CPlayer = players [consolePlayer];
        weapBinds = S7_WeapBindsSystem (CPlayer.mo.FindInventory ('S7_WeapBindsSystem'));

        handler = new ('S7_WeapAssignMenuHandler');
        handler.link = self;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');
        textBigFont = Font.GetFont ('S7TxtBig.FON2');

        slotsFrame = S7_ZF_Frame.Create ((0, 0), (640, 210));
        slotsFrame.Pack (mainFrame);
        weapSelFrame = S7_ZF_Frame.Create ((0, 210), (640, 270));
        weapSelFrame.Pack (mainFrame);

        OnInit ();

        string labelText = "WEAPON SLOT ASSIGNMENT";
        S7_ZF_Label label = S7_ZF_Label.Create ((0, 12), (0, bigFont.GetHeight ()), text: labelText, fnt: bigFont, wrap: false, autoSize: true, textColor: Font.CR_White);
        label.SetPosX (320.0 - (bigFont.stringWidth (labelText) / 2.0));
        label.Pack (slotsFrame);

        weapSlotIdle = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/WeapAssignment/WeapSlot.png", true);
        weapSlotHover = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/WeapAssignment/WeapSlotHover.png", true);
        weapSlotClick = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/WeapAssignment/WeapSlotPressed.png", true);
        weapSlotDisabled = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/WeapAssignment/WeapSlotDisabled.png", true);

        for (int x = 0; x < 5; x++) {
            double xCoords = 19.0 + ((105.0 + 19.0) * x);
            labelText = weapLabelsText [x];
            label = S7_ZF_Label.Create ((xCoords, 48), (0, smallFont.GetHeight ()), text: labelText, fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_White);
            label.SetPosX (label.GetPosX () + (105.0 / 2) - (smallFont.stringWidth (labelText) / 2.0));
            label.Pack (slotsFrame);

            for (int y = 0; y < 3; y++) {
                double yCoords = 72.0 + ((40.0 + 8.0) * y);
                // Button
                slotButtons [x] [y] = S7_ZF_Button.Create ((xCoords, yCoords), (107, 42), text: "", cmdHandler: handler, command: String.Format ("SetSlot:%d,%d", x, y), null, null, null, null);
                slotButtons [x] [y].SetTextures (weapSlotIdle, weapSlotHover, weapSlotClick, weapSlotDisabled);
                slotButtons [x] [y].Pack (slotsFrame);
                // Image
                slotImages [x] [y] = S7_ZF_Image.Create ((xCoords + 1, yCoords + 1), (105, 40), "", S7_ZF_Image.AlignType_Center);
                slotImages [x] [y].SetDontBlockMouse (true);
                slotImages [x] [y].Pack (slotsFrame);
            }
        }

        infoBG = S7_ZF_Image.Create ((221, 12), (400, 246), "graphics/Menu/WeapAssignment/InfoBG.png", S7_ZF_Image.AlignType_TopLeft);
        infoBG.Pack (weapSelFrame);

        double InfoNameLabelScale = .75;
        infoNameLabel = S7_ZF_Label.Create (
            (221 + 5, 12 + 5), (400 - (5*2), textBigFont.GetHeight () * InfoNameLabelScale),

            text: "", fnt: textBigFont,
            wrap: true, autoSize: false,
            textScale: InfoNameLabelScale, textColor: Font.CR_White
        );
        infoNameLabel.Pack (weapSelFrame);

        let infoLabelOrigin = infoNameLabel.GetPos () + (15, infoNameLabel.GetHeight () + 2);
        infoLabel = S7_ZF_Label.Create (
            infoLabelOrigin,
            (616 - 15, 253) - infoLabelOrigin,

            text: "", fnt: smallFont,
            wrap: true, autoSize: false,
            textColor: Font.CR_White, lineSpacing: 1
        );
        infoLabel.Pack (weapSelFrame);

        itemsList = S7_WeapAssignMenu_List.CreateList (self, weapSelFrame, S7_BasePlayer (CPlayer.mo), isDraco);

        selectedX = selectedY = -1;
    }

    virtual void OnInit () { isDraco = false; }

    override void Ticker () {
        Super.Ticker ();
        menuactive = Menu.OnNoPause;

        if (!CPlayer || !CPlayer.mo || CPlayer.mo.health < 1) {
            self.Close ();
            return;
        }

        UpdateData ();
    }

    void UpdateData () {
        if (!weapBinds)
            weapBinds = S7_WeapBindsSystem (CPlayer.mo.FindInventory ('S7_WeapBindsSystem'));

        S7_BaseWeapon selectedWeap;

        S7_BaseWeapon weap;
        for (int x = 0; x < 5; x++) {
            if (x == selectedX && weapBinds.SlotCount (x + 1, isDraco) > selectedY)
                selectedWeap = weapBinds.GetBind (x + 1, selectedY, isDraco);

            for (int y = 0; y < 3; y++) {
                if (y < weapBinds.SlotCount (x + 1, isDraco) && y < weapBinds.GetSlotMaximum (x + 1, isDraco) && (weap = weapBinds.GetBind (x + 1, y, isDraco)))
                    slotImages [x] [y].SetImage (weap.weapIcon);
                else {
                    slotButtons [x] [y].Enable ();
                    slotImages [x] [y].SetImage ("");
                    if (y > weapBinds.SlotCount (x + 1, isDraco) || y >= weapBinds.GetSlotMaximum (x + 1, isDraco))
                        slotButtons [x] [y].Disable ();
                }
                if (x == selectedX && y == selectedY) {
                    slotButtons [x] [y].SetTextures (weapSlotClick, weapSlotHover, weapSlotIdle, weapSlotDisabled);
                } else {
                    slotButtons [x] [y].SetTextures (weapSlotIdle, weapSlotHover, weapSlotClick, weapSlotDisabled);
                }
            }
        }

        if (selectedX > -1 && selectedY > -1 && (weapSelFrame.IsDisabled () || weapSelFrame.IsHidden ()))
            ActivateSelFrame (selectedX + 1);
        else if ((selectedX < 0 || selectedY < 0) && (!weapSelFrame.IsDisabled () || !weapSelFrame.IsHidden ()))
            ActivateSelFrame (-1);

        if (hoveredWeap)
            SetInfo (hoveredWeap);
        else if (selectedX >= 0 && selectedY >= 0 && selectedWeap)
            SetInfo (selectedWeap);
        else
            SetInfo (null);
    }

    void ActivateSelFrame (S7_WeaponSlots slot) {
        bool deactivate = slot < 0;

        if (weapSelFrame) {
            weapSelFrame.SetDisabled (deactivate);
            weapSelFrame.SetHidden (deactivate);
        }

        if (itemsList) {
            if (!deactivate)
                itemsList.Activate (slot);
            else
                itemsList.Deactivate ();
        }
    }

    void SetWeapon (string weap) {
        if (selectedX < 0 || selectedY < 0)
            return;

        if (weap == "@__NoWeapon__")
            EventHandler.SendNetworkEvent ("S7_WeapBindsSystem:UnsetSlot", selectedX + 1, selectedY, (isDraco ? 1 : 0));
        else
            EventHandler.SendNetworkEvent (String.Format ("S7_WeapBindsSystem:SetSlot:%s", weap), selectedX + 1, selectedY, (isDraco ? 1 : 0));

        MenuSound ("S7Menu/SelectionMove");

        selectedX = selectedY = -1;
        hoveredWeap = null;
        ActivateSelFrame (-1);
        UpdateData ();
    }

    void SetInfo (S7_BaseWeapon weap) {
        string weaponName = "";
        string info = "";

        if (weap) {
            weaponName = StringTable.Localize (weap.shortTag, true);

            string weapName = weap.GetClassName ();
            Array<String> strings;
            for (int i = 0; i < S7_WeapData.WeaponDescs.Size (); i++) {
                strings.Clear ();
                S7_WeapData.WeaponDescs [i].Split (strings, ":");

                if (strings.Size () != 2)
                    continue;

                if (strings [0] ~== weapName)
                    info = StringTable.Localize (strings [1], true);
            }
        }

        infoNameLabel.SetText (weaponName);
        infoLabel.SetText (info);
    }
}

class S7_WeapAssignMenu_EventHandler : EventHandler {
    override void NetworkProcess (ConsoleEvent e) {
        if (e.IsManual || e.Player < 0) // Don't execute this if it was called manually or the player isn't given/valid
            return;
        if (!playeringame [e.Player] || !players [e.Player].mo) // Don't execute if the player isn't ingame, the player is null or the player's PlayerPawn is null
            return;

        let pPawn = players [e.Player].mo;

        Array<String> strings; strings.Clear ();
        e.Name.Split (strings, ":");
        if (strings.Size () < 2 || strings [0] != "S7_WeapBindsSystem") // Return if the array doesn't contain exactly two strings or the first string isn't "S7_WeapBindsSystem"
            return;

        if (strings [1] == "SetSlot" && strings.Size () == 3) {
            if (!pPawn)
                return;

            let weapBinds = S7_WeapBindsSystem (pPawn.FindInventory ('S7_WeapBindsSystem'));
            if (!weapBinds)
                return;

            int slot = e.Args [0], pos = e.Args [1];
            let weap = S7_BaseWeapon (pPawn.FindInventory (strings [2]));
            if (!weap)
                return;

            weapBinds.SetBind (slot, pos, weap, !!e.args [2]);
        } else if (strings [1] == "UnsetSlot") {
            if (!pPawn)
                return;

            let weapBinds = S7_WeapBindsSystem (pPawn.FindInventory ('S7_WeapBindsSystem'));
            if (!weapBinds)
                return;

            int slot = e.Args [0], pos = e.Args [1];

            weapBinds.SetBind (slot, pos, null, !!e.args [2]);
        }
    }
}

class S7_DracoWeapAssignMenu : S7_WeapAssignMenu {
    override void OnInit () { isDraco = true; }
}
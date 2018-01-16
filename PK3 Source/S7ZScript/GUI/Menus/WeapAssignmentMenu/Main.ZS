class S7_WeapAssignMenuHandler : S7_ZF_Handler {
    S7_WeapAssignMenu link;

    override void buttonCommand (S7_ZF_Button caller, string command) {
        Array<String> strings;
        command.Split (strings, ":");

        if (strings [0] ~== "SetSlot" && strings.Size () == 2) {
            Array<String> coords;
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

    S7_ZF_Frame slotsFrame, weapSelFrame;
    S7_WeapAssignMenu_List itemsList;
    S7_ZF_Image infoBG;
    S7_ZF_Label infoLabel;
    S7_ZF_Button slotButtons [3] [5];
    S7_ZF_Image  slotImages  [3] [5];

    int selectedX, selectedY;
    S7_BaseWeapon hoveredWeap;

    static const String weapLabelsText [] = {
        "Medium", "Light", "Heavy", "Area-damage", "Special"
    };
    override void Init (Menu parent) {
        Super.Init (parent);
        SetBaseResolution ((640, 480));
        menuactive = Menu.OnNoPause;

        CPlayer = players [consolePlayer];
        weapBinds = S7_WeapBindsSystem (CPlayer.mo.FindInventory ("S7_WeapBindsSystem"));

        handler = new ("S7_WeapAssignMenuHandler");
        handler.link = self;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        slotsFrame = new ("S7_ZF_Frame").Init ((0, 0), (640, 210));
        slotsFrame.Pack (mainFrame);
        weapSelFrame = new ("S7_ZF_Frame").Init ((0, 210), (640, 270));
        weapSelFrame.Pack (mainFrame);

        string labelText = "WEAPON SLOT ASSIGNMENT";
        S7_ZF_Label label = new ("S7_ZF_Label").Init ((0, 12), (0, bigFont.GetHeight ()), labelText, bigFont, false, true, 1, Font.CR_WHITE);
        label.box.pos.X = 320.0 - (bigFont.stringWidth (labelText) / 2.0);
        label.Pack (slotsFrame);

        for (int x = 0; x < 5; x++) {
            double xCoords = 19.0 + ((105.0 + 19.0) * x);
            labelText = weapLabelsText [x];
            label = new ("S7_ZF_Label").Init ((xCoords, 48), (0, smallFont.GetHeight ()), labelText, smallFont, false, true, 1, Font.CR_WHITE);
            label.box.pos.X += (105.0 / 2) - (smallFont.stringWidth (labelText) / 2.0);
            label.Pack (slotsFrame);

            for (int y = 0; y < 3; y++) {
                double yCoords = 72.0 + ((40.0 + 8.0) * y);
                // Button
                slotButtons [x] [y] = new ("S7_ZF_Button").Init ((xCoords, yCoords), (107, 42), "", handler, String.Format ("SetSlot:%d,%d", x, y), null, null, null, null);
                slotButtons [x] [y].SetTexture (
                    "graphics/Menu/WeapAssignment/WeapSlot.png", "graphics/Menu/WeapAssignment/WeapSlotHover.png",
                    "graphics/Menu/WeapAssignment/WeapSlotPressed.png", "graphics/Menu/WeapAssignment/WeapSlotDisabled.png"
                );
                slotButtons [x] [y].Pack (slotsFrame);
                // Image
                slotImages [x] [y] = new ("S7_ZF_Image").Init ((xCoords + 1, yCoords + 1), (105, 40), "", S7_ZF_Image.AlignCenter, noOffsets: true);
                slotImages [x] [y].Pack (slotsFrame);
            }
        }

        infoBG = new ("S7_ZF_Image").Init ((221, 12), (400, 246), "graphics/Menu/WeapAssignment/InfoBG.png", S7_ZF_Image.AlignTopLeft, noOffsets: true);
        infoBG.Pack (weapSelFrame);
        infoLabel = new ("S7_ZF_Label").Init ((221 + 5, 12 + 5), (400 - 5, 246 - 5), "", smallFont, true, false, 1, Font.CR_WHITE);
        infoLabel.Pack (weapSelFrame);
        itemsList = S7_WeapAssignMenu_List (new ("S7_WeapAssignMenu_List").InitList (self, weapSelFrame, S7_BasePlayer (CPlayer.mo)));

        selectedX = selectedY = -1;

        //dontDim = true;
    }

    override void Ticker () { // GetClassName
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
            weapBinds = S7_WeapBindsSystem (CPlayer.mo.FindInventory ("S7_WeapBindsSystem"));

        S7_BaseWeapon selectedWeap;

        Array<S7_BaseWeapon> weapons;
        S7_BaseWeapon weap;
        for (int x = 0; x < 5; x++) {
            weapons.Clear ();
            weapons.Copy (weapBinds.Binds [x + 1]);

            if (x == selectedX && weapons.Size () > selectedY)
                selectedWeap = weapons [selectedY];

            for (int y = 0; y < 3; y++) {
                if (y < weapBinds.Binds [x + 1].Size () && (weap = weapons [y]))
                    slotImages [x] [y].image = weap.weapIcon;
                else {
                    slotButtons [x] [y].disabled = false;
                    slotImages [x] [y].image = "";
                    if (y > weapBinds.Binds [x + 1].Size ())
                        slotButtons [x] [y].disabled = true;
                }
                if (x == selectedX && y == selectedY) {
                    slotButtons [x] [y].SetTexture (
                        "graphics/Menu/WeapAssignment/WeapSlotPressed.png", "graphics/Menu/WeapAssignment/WeapSlotHover.png",
                        "graphics/Menu/WeapAssignment/WeapSlot.png", "graphics/Menu/WeapAssignment/WeapSlotDisabled.png"
                    );
                } else {
                    slotButtons [x] [y].SetTexture (
                        "graphics/Menu/WeapAssignment/WeapSlot.png", "graphics/Menu/WeapAssignment/WeapSlotHover.png",
                        "graphics/Menu/WeapAssignment/WeapSlotPressed.png", "graphics/Menu/WeapAssignment/WeapSlotDisabled.png"
                    );
                }
            }
        }
        weapons.Clear ();

        if (selectedX > -1 && selectedY > -1 && (weapSelFrame.disabled || weapSelFrame.hidden))
            ActivateSelFrame (selectedX + 1);
        else if ((selectedX < 0 || selectedY < 0) && (!weapSelFrame.disabled || !weapSelFrame.hidden))
            ActivateSelFrame (-1);

        if (hoveredWeap)
            SetInfo (hoveredWeap);
        else if (selectedX >= 0 && selectedY >= 0 && selectedWeap)
            SetInfo (selectedWeap);
        else
            SetInfo (NULL);
    }

    void ActivateSelFrame (S7_WeaponSlots slot) {
        bool deactivate = slot < 0;

        if (weapSelFrame) {
            weapSelFrame.disabled = deactivate;
            weapSelFrame.hidden = deactivate;
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
            EventHandler.SendNetworkEvent ("S7_WeapBindsSystem:UnsetSlot", selectedX + 1, selectedY);
        else
            EventHandler.SendNetworkEvent (String.Format ("S7_WeapBindsSystem:SetSlot:%s", weap), selectedX + 1, selectedY);

        selectedX = selectedY = -1;
        ActivateSelFrame (-1);
        UpdateData ();
    }

    void SetInfo (S7_BaseWeapon weap) {
        string info = "";

        if (weap) {
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

        infoLabel.text = info;
    }
}

class S7_WeapAssignMenu_EventHandler : EventHandler {
    override void NetworkProcess (ConsoleEvent e) {
        if (e.IsManual || e.Player < 0) // Don't execute this if it was called manually or the player isn't given/valid
            return;
        if (!playeringame [e.Player] || !players [e.Player].mo) // Don't execute if the player isn't ingame, the player is null or the player's PlayerPawn is null
            return;

        let pPawn = players [e.Player].mo;

        Array<String> strings;
        e.Name.Split (strings, ":");
        if (strings.Size () < 2 || strings [0] != "S7_WeapBindsSystem") // Return if the array doesn't contain exactly two strings or the first string isn't "S7_WeapBindsSystem"
            return;

        if (strings [1] == "SetSlot" && strings.Size () == 3) {
            if (!pPawn)
                return;

            let weapBinds = S7_WeapBindsSystem (pPawn.FindInventory ("S7_WeapBindsSystem"));
            if (!weapBinds)
                return;

            int slot = e.Args [0], pos = e.Args [1];
            let weap = S7_BaseWeapon (pPawn.FindInventory (strings [2]));
            if (!weap)
                return;

            weapBinds.SetBind (slot, pos, weap);
        } else if (strings [1] == "UnsetSlot") {
            if (!pPawn)
                return;

            let weapBinds = S7_WeapBindsSystem (pPawn.FindInventory ("S7_WeapBindsSystem"));
            if (!weapBinds)
                return;

            int slot = e.Args [0], pos = e.Args [1];

            weapBinds.SetBind (slot, pos, NULL);
        }
    }
}
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

class S7_WeaponEnchantmentMenuHandler : S7_ZF_Handler {
    S7_WeaponEnchantmentMenu link;

    void RepeatableButtons (string command) {
        if (command == "enchantsListUp") {
            if (!link.enchantsListFrame)
                return;

            link.enchantsListFrame.UpdateScroll (+1);
        } else if (command == "enchantsListDown") {
            if (!link.enchantsListFrame)
                return;

            link.enchantsListFrame.UpdateScroll (-1);
        } else if (command == "increasePower") {
            link.enchantmentPower = min (link.enchantmentPower + 1, 1 << 24);

            Menu.MenuSound ("S7Menu/SliderMove");
        } else if (command == "decreasePower") {
            link.enchantmentPower = max (link.enchantmentPower - 1, 1);

            Menu.MenuSound ("S7Menu/SliderMove");
        }
    }

    override void ButtonClickCommand (S7_ZF_Button caller, string command) {
        if (!link)
            return;

        if (caller && (command == "increasePower" || command == "decreasePower"))
            caller.SetHoldTicInterval (15);

        RepeatableButtons (command);

        if (command == "buyEnchantment") {
            if (!link.selectedWeap)
                return;

            EventHandler.SendNetworkEvent (String.Format ("S7_WeaponEnchantmentMenu:DoEnchant:%s", link.selectedWeap.GetClassName ()), link.enchantmentPower);
            Menu.MenuSound ("S7Menu/Close");
        }
    }

    override void ButtonHeldCommand (S7_ZF_Button caller, string command) {
        if (!link)
            return;

        RepeatableButtons (command);

        if (command == "increasePower" || command == "decreasePower")
            caller.SetHoldTicInterval (3);
    }
}

class S7_WeaponEnchantmentMenu_EnchantsList : S7_ZF_Frame {
    S7_ZF_Frame itemsFrame;

    static S7_WeaponEnchantmentMenu_EnchantsList Create (Vector2 pos, Vector2 size) {
        let ret = new ('S7_WeaponEnchantmentMenu_EnchantsList');

        ret.SetBox (pos, size);
        ret.alpha = 1;

        return ret;
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

    void ClearItemsFrame () {
        while (itemsFrame.elements.Size () > 0)
            itemsFrame.elements [0].Unpack ();
    }

    double GetLowestCoord () {
        return -(itemsFrame.GetHeight () - GetHeight ());
    }

    void UpdateScroll (int direction = 0) {
        if (!itemsFrame)
            return;

        itemsFrame.SetPosY (itemsFrame.GetPosY () + 15 * direction);

        double lowestCoord = GetLowestCoord ();

        if (GetHeight () > itemsFrame.GetHeight ())
            itemsFrame.SetPosY (0);
        else if (itemsFrame.GetPosY () < lowestCoord)
            itemsFrame.SetPosY (lowestCoord);
        else if (itemsFrame.GetPosY () > 0)
            itemsFrame.SetPosY (0);
    }
}

class S7_WeaponEnchantmentMenu : S7_ZF_GenericMenu {
    S7_WeaponEnchantmentMenuHandler handler;

    PlayerInfo CPlayer;

    Font bigFont;
    Font smallFont;

    S7_ZF_Frame dataFrame;
    S7_ZF_Image mainWindowBG;
    S7_ZF_Label tooltipLabel;

    S7_WeaponEnchantmentMenu_List itemsList;

    S7_ZF_Label weapNameLabel;
    S7_ZF_Image weapImage;
    S7_ZF_Label priceLabel, powerLabel, curTotalPowerLabel, newTotalPowerLabel;
    S7_ZF_Button increasePowerButton, decreasePowerButton;
    S7_ZF_Button buyButton;

    S7_WeaponEnchantmentMenu_EnchantsList enchantsListFrame;
    S7_ZF_Frame enchantsListInnerFrame;
    S7_ZF_Button enchantsListUpButton, enchantsListDownButton;

    S7_BaseWeapon hoveredWeap, selectedWeap;

    int enchantmentPower;

    override void Init (Menu parent) {
        Super.Init (parent);
        SetBaseResolution ((640, 480));

        CPlayer = players [consolePlayer];

        handler = new ('S7_WeaponEnchantmentMenuHandler');
        handler.link = self;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        {
            string labelText = StringTable.Localize ("$WEAPONENCHANTMENTMENUHEADER", true);
            S7_ZF_Label label = S7_ZF_Label.Create ((0, 12), (0, bigFont.GetHeight ()), text: labelText, fnt: bigFont, wrap: false, autoSize: true, textColor: Font.CR_White);
            label.SetPosX (320. - (bigFont.stringWidth (labelText) / 2.));
            label.Pack (mainFrame);
        }

        itemsList = S7_WeaponEnchantmentMenu_List.CreateList (self, mainFrame, S7_BasePlayer (CPlayer.mo));
        itemsList.PopulateList ();

        dataFrame = S7_ZF_Frame.Create ((250, 50), (365, 400));
        dataFrame.Pack (mainFrame);

        mainWindowBG = S7_ZF_Image.Create ((0, 0), dataFrame.GetSize (), "graphics/Menu/EnchantmentMenu/MainWindow.png", S7_ZF_Image.AlignType_TopLeft);
        mainWindowBG.Pack (dataFrame);

        /** Weapon data **/
        weapNameLabel = S7_ZF_Label.Create ((0, 8), (0, smallFont.GetHeight ()*1.0), text: "", fnt: smallFont, wrap: false, autoSize: false, textScale: 1.0, textColor: Font.CR_White);
        weapNameLabel.Pack (dataFrame);

        weapImage = S7_ZF_Image.Create ((0, 8 + smallFont.GetHeight () + 12), (dataFrame.GetWidth (), 200), "", S7_ZF_Image.AlignType_Center, imageScale: (2.5, 2.5));
        weapImage.Pack (dataFrame);

        priceLabel = S7_ZF_Label.Create ((8, 0), (0, smallFont.GetHeight ()), text: "", fnt: smallFont, wrap: false, autoSize: false, textColor: Font.CR_White);
        priceLabel.Pack (dataFrame);

        powerLabel = S7_ZF_Label.Create ((8, 0), (0, smallFont.GetHeight ()), text: "", fnt: smallFont, wrap: false, autoSize: false, textColor: Font.CR_White);
        powerLabel.Pack (dataFrame);

        curTotalPowerLabel = S7_ZF_Label.Create ((8, 0), (0, smallFont.GetHeight ()), text: "", fnt: smallFont, wrap: false, autoSize: false, textColor: Font.CR_DarkGray);
        curTotalPowerLabel.Pack (dataFrame);

        newTotalPowerLabel = S7_ZF_Label.Create ((8, 0), (0, smallFont.GetHeight ()), text: "", fnt: smallFont, wrap: false, autoSize: false, textColor: Font.CR_DarkRed);
        newTotalPowerLabel.Pack (dataFrame);

        let incDecButtonIdle = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/EnchantmentMenu/IncDecButton.png", true);
        let incDecButtonHover = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/EnchantmentMenu/IncDecButtonHover.png", true);
        let incDecButtonClick = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/EnchantmentMenu/IncDecButtonPressed.png", true);

        increasePowerButton = S7_ZF_Button.Create ((4, 0), (69, 17),
            StringTable.Localize ("$WEAPONENCHANTMENTMENU_INC_POWER", true), cmdHandler: handler, command: "increasePower", fnt: smallFont, textColor: Font.CR_White, holdInterval: 3
        );
        increasePowerButton.SetTextures (incDecButtonIdle, incDecButtonHover, incDecButtonClick, incDecButtonIdle);
        increasePowerButton.Pack (dataFrame);

        decreasePowerButton = S7_ZF_Button.Create ((4 + 69 + 4, 0), (69, 17),
            StringTable.Localize ("$WEAPONENCHANTMENTMENU_DEC_POWER", true), cmdHandler: handler, command: "decreasePower", fnt: smallFont, textColor: Font.CR_White, holdInterval: 3
        );
        decreasePowerButton.SetTextures (incDecButtonIdle, incDecButtonHover, incDecButtonClick, incDecButtonIdle);
        decreasePowerButton.Pack (dataFrame);

        buyButton = S7_ZF_Button.Create ((dataFrame.GetWidth () - (69 + 4), 235 - (17 + 4)), (69, 17),
            StringTable.Localize ("$WEAPONENCHANTMENTMENU_BUY", true), cmdHandler: handler, command: "buyEnchantment", fnt: smallFont, textColor: Font.CR_White
        );
        buyButton.SetTextures (incDecButtonIdle, incDecButtonHover, incDecButtonClick, incDecButtonIdle);
        buyButton.Pack (dataFrame);

        /** Current enchantments list **/
        S7_ZF_Label curEnchantmentsLabel;
        {
            let fnt = smallFont;

            string labelText = StringTable.Localize ("$WEAPONENCHANTMENTMENU_CURENCHANTS", true);

            curEnchantmentsLabel = S7_ZF_Label.Create ((5, 239), (0, smallFont.GetHeight ()), text: labelText, fnt: smallFont, wrap: false, autoSize: true, textColor: Font.CR_White);
            curEnchantmentsLabel.Pack (dataFrame);
        }

        {
            enchantsListFrame = S7_WeaponEnchantmentMenu_EnchantsList.Create ((10, 237), (351, 160));
            enchantsListFrame.Pack (dataFrame);

            double newYPos = curEnchantmentsLabel.GetPosY () + curEnchantmentsLabel.GetHeight () + 4;
            enchantsListFrame.SetHeight (enchantsListFrame.GetHeight () - newYPos - enchantsListFrame.GetPosY ());
            enchantsListFrame.SetPosY (newYPos);
        }

        enchantsListInnerFrame = S7_ZF_Frame.Create ((0, 0), enchantsListFrame.GetSize ());
        enchantsListInnerFrame.Pack (enchantsListFrame);
        enchantsListFrame.itemsFrame = enchantsListInnerFrame;

        let enchantsListUpIdle = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/HUD/INVGEMU2.png", true);
        let enchantsListUpHover = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/HUD/INVGEMU1.png", true);
        let enchantsListDownIdle = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/HUD/INVGEMD2.png", true);
        let enchantsListDownHover = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/HUD/INVGEMD1.png", true);

        enchantsListUpButton = S7_ZF_Button.Create ((enchantsListFrame.GetWidth () - (12+2), 0), (12, 8),
            "", cmdHandler: handler, command: "enchantsListUp", holdInterval: 3
        );
        enchantsListUpButton.SetTextures (enchantsListUpIdle, enchantsListUpHover, enchantsListUpIdle, enchantsListUpIdle);
        enchantsListUpButton.Pack (enchantsListFrame);

        enchantsListDownButton = S7_ZF_Button.Create ((enchantsListUpButton.GetPosX (), enchantsListFrame.GetHeight () - (8 + 2)), (12, 8),
            "", cmdHandler: handler, command: "enchantsListDown", holdInterval: 3
        );
        enchantsListDownButton.SetTextures (enchantsListDownIdle, enchantsListDownHover, enchantsListDownIdle, enchantsListDownIdle);
        enchantsListDownButton.Pack (enchantsListFrame);

        /** Misc **/
        tooltipLabel = S7_ZF_Label.Create ((0, 455), (640, 20), text: "", fnt: smallFont, alignment: S7_ZF_Label.AlignType_Center, wrap: true, autoSize: false, textColor: Font.CR_White);
        tooltipLabel.Pack (mainFrame);

        enchantmentPower = 1;
    }

    int, double GetNewEnchantmentData (S7_BaseWeapon weap) {
        int ret1; double ret2;

        [ret1, ret2] = weap.Enchantments_GetNewEnchantmentData (enchantmentPower, weap.enchantments_List.Size ());

        return ret1, ret2;
    }

    override void Ticker () {
        Super.Ticker ();
        menuactive = Menu.OnNoPause;

        let pPawn = S7_BasePlayer (CPlayer.mo);

        if (hoveredWeap)
            Select (hoveredWeap);
        else if (selectedWeap)
            Select (selectedWeap);
        else
            Select (null);

        if (pPawn.playerData.transactData.done) {
            enchantmentPower = 1;
            enchantsListFrame.UpdateScroll (-8192);

            pPawn.playerData.transactData.done = false;
        }
    }

    void UpdateLabel (S7_ZF_Label label, S7_ZF_Element prevItem, string labelText, string valueRepl, double yOffset = 2.5) {
        Array<string> valueReplStrings;
        valueReplStrings.Clear ();
        valueRepl.Split (valueReplStrings, ":");

        string labelText = StringTable.Localize (labelText, true);
        for (int i = 0; i < valueReplStrings.Size (); i++) {
            labelText.Replace (String.Format ("%%%d", i + 1), valueReplStrings [i]);
            label.SetText (labelText);
        }

        label.SetPosY (prevItem.GetPosY () + prevItem.GetHeight () + yOffset);
        label.SetWidth (label.GetFont ().StringWidth (label.GetText ()) * label.GetTextScale ());
    }

    string FormatFraction (double val) {
        string ret = S7_Utils.TrimZeroes (String.Format ("%.6f", val));

        if (ret == ".")
            return "0";

        int lastChar = ret.Length () - 1;
        if (ret.Mid (lastChar, 1) == ".")
            return ret.Left (lastChar);

        return ret;
    }

    void Select (S7_BaseWeapon weap) {
        if (!weap) {
            // Hide and disable the data frame and return
            dataFrame.Hide ();
            dataFrame.Disable ();
            return;
        }

        // Show and enable the data frame
        dataFrame.Show ();
        dataFrame.Enable ();

        // Update the weapon name and icon
        string weapName = weap.shortTag;
        weapNameLabel.SetText (weapName);

        let fnt = weapNameLabel.GetFont ();
        double strLen = fnt.stringWidth (weapName) * weapNameLabel.GetTextScale ();
        weapNameLabel.SetWidth (strLen);
        weapNameLabel.SetPosX ((365.0 - strLen) / 2.);

        Vector2 iconSize = (0, 0);
        iconSize = TexMan.GetScaledSize (TexMan.CheckForTexture (weap.weapIcon, TexMan.Type_Any));
        iconSize = S7_Math.Vec2Mul (iconSize, weapImage.GetImageScale ());

        weapImage.SetImage (weap.weapIcon);
        weapImage.SetHeight (iconSize.Y);

        // Calculate the values for the weapon data
        int finalPrice; double finalPower;
        int curTotalPowerAmount; double curTotalPower;
        int newTotalPowerAmount; double newTotalPower;

        [finalPrice, finalPower] = GetNewEnchantmentData (weap);

        int enchantmentsCount = weap.enchantments_List.Size ();
        for (int i = 0; i < enchantmentsCount; i++)
            curTotalPowerAmount += weap.enchantments_List [i];
        curTotalPower = (weap.enchantment_BasePower * curTotalPowerAmount);
        newTotalPowerAmount = (curTotalPowerAmount + enchantmentPower);
        newTotalPower = (curTotalPower + finalPower);

        // Update the text labels
        UpdateLabel (priceLabel,
            weapImage,
            "$WEAPONENCHANTMENTMENU_PRICE",
            String.Format ("%d", finalPrice),
            25.
        );
        UpdateLabel (powerLabel, priceLabel, "$WEAPONENCHANTMENTMENU_POWER", String.Format ("%d:%s", enchantmentPower, FormatFraction (finalPower)));
        UpdateLabel (curTotalPowerLabel, powerLabel, "$WEAPONENCHANTMENTMENU_CURTOTALPOWER", String.Format ("%d:%s", curTotalPowerAmount, FormatFraction (curTotalPower)));
        UpdateLabel (newTotalPowerLabel, curTotalPowerLabel, "$WEAPONENCHANTMENTMENU_NEWTOTALPOWER", String.Format ("%d:%s", newTotalPowerAmount, FormatFraction (newTotalPower)));

        int cashAmount = CPlayer.mo.CountInv ("S7_Cash");
        priceLabel.SetTextColor (finalPrice > cashAmount ? Font.CR_Red : Font.CR_White);

        // Set the buttons' positions
        increasePowerButton.SetPosY (newTotalPowerLabel.GetPosY () + newTotalPowerLabel.GetHeight () + 4);
        decreasePowerButton.SetPosY (increasePowerButton.GetPosY ());

        // Update the increase, decrease and buy buttons
        int nextLevelPrice; {
            double MUDA;
            [nextLevelPrice, MUDA] = weap.Enchantments_GetNewEnchantmentData (enchantmentPower + 1, weap.enchantments_List.Size ());
        }
        decreasePowerButton.SetDisabled (enchantmentPower <= 1);
        increasePowerButton.SetDisabled (finalPrice > cashAmount || nextLevelPrice > cashAmount);
        buyButton.SetDisabled (finalPrice > cashAmount);

        decreasePowerButton.SetTextColor (decreasePowerButton.IsDisabled () ? Font.CR_DarkGray : Font.CR_White);
        increasePowerButton.SetTextColor (increasePowerButton.IsDisabled () ? Font.CR_DarkGray : Font.CR_White);
        buyButton.SetTextColor (buyButton.IsDisabled () ? Font.CR_DarkGray : Font.CR_White);

        // Destroy all the labels in the enchantment list and clear it
        enchantsListFrame.ClearItemsFrame ();

        // Populate the current enchantments list
        int smallFontHeight = smallFont.GetHeight ();
        for (int i = 0; i < enchantmentsCount; i++) {
            int power = weap.enchantments_List [i];
            string label = String.Format ("%d. Level %d (%s)", i + 1, power, FormatFraction (power * weap.enchantment_BasePower));

            S7_ZF_Label.Create (
                (0, (smallFontHeight + 4) * i), (smallFont.StringWidth (label), smallFontHeight),
                text: label, fnt: smallFont,
                wrap: false, autoSize: false,
                textColor: Font.CR_White
            ).Pack (enchantsListInnerFrame);
        }
        enchantsListInnerFrame.SetHeight (((smallFontHeight + 4) * (enchantmentsCount - 1)) + smallFontHeight + 1);

        // Update the up/down arrows in the enchantments list
        double lowestCoord = enchantsListFrame.GetLowestCoord ();
        bool disableDownArrow = (
            (enchantsListInnerFrame.GetPosY () <= lowestCoord) ||
            (enchantsListInnerFrame.GetHeight () <= enchantsListFrame.GetHeight ())
        );
        enchantsListDownButton.SetDisabled (disableDownArrow);
        enchantsListDownButton.SetHidden (disableDownArrow);

        bool disableUpArrow = enchantsListInnerFrame.GetPosY () >= 0.;
        enchantsListUpButton.SetDisabled (disableUpArrow);
        enchantsListUpButton.SetHidden (disableUpArrow);
    }

    void SetTooltip (string text) {
        if (tooltipLabel)
            tooltipLabel.SetText (text);
    }
}

class S7_WeaponEnchantmentMenuEventHandler : EventHandler {
    override void NetworkProcess (ConsoleEvent e) {
        if (e.IsManual || e.Player < 0) // Don't execute this if it was called manually or the player isn't given/valid
            return;
        if (!playeringame [e.Player] || !players [e.Player].mo) // Don't execute if the player isn't ingame, the player is null or the player's PlayerPawn is null
            return;

        Array<String> strings; strings.Clear ();
        e.Name.Split (strings, ":");
        if (strings.Size () < 2 || strings [0] != "S7_WeaponEnchantmentMenu") // Return if the array doesn't contain at least two strings or the first string isn't "S7_WeaponEnchantmentMenu"
            return;

        let pPawn = S7_BasePlayer (players [e.Player].mo);

        if (strings [1] == "DoEnchant") {
            let weap = S7_BaseWeapon (pPawn.FindInventory (strings [2]));

            if (!weap)
                return;

            int finalPrice; double finalPower;
            [finalPrice, finalPower] = weap.Enchantments_GetNewEnchantmentData (e.Args [0], weap.enchantments_List.Size ());

            if (finalPrice > pPawn.CountInv ("S7_Cash"))
                return;

            weap.enchantments_List.Push (e.Args [0]);
            pPawn.TakeInventory ("S7_Cash", finalPrice);

            pPawn.playerData.transactData.done = true;
        }
    }
}
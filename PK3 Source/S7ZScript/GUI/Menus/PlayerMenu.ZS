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

class S7_PlayerMenuHandler : S7_ZF_Handler {
    S7_PlayerMenu link;

    static void ChangeMenu (name menuName) {
        Menu.SetMenu (menuName);
        Menu.MenuSound ("S7Menu/Choose");
    }

    override void ButtonClickCommand (S7_ZF_Button caller, string command) {
        if (command == "openXPSysMenu")
            ChangeMenu ('S7_XPSystemMenu');
        else if (command == "openLuciusShop")
            ChangeMenu ('S7_LuciusShopMenu');
        else if (command == "openWeapAssignMenu")
            ChangeMenu ('S7_WeapAssignMenu');
        else if (command == "openDracoWeapMenu")
            ChangeMenu ('S7_DracoWeapAssignMenu');
        else if (command == "openAutogunMenu")
            ChangeMenu ('S7_AutogunMenu');
        else if (command == "openWeaponEnchantmentMenu")
            ChangeMenu ('S7_WeaponEnchantmentMenu');
    }
}

class S7_PlayerMenu : S7_ZF_GenericMenu {
    S7_PlayerMenuHandler handler;

    PlayerInfo CPlayer;

    Font bigFont;
    Font smallFont;
    S7_ZF_Frame menusFrame;
    S7_ZF_Button xpSysButton, luciusShopButton, weapAssignButton, dracoWeapAssignButton, weapEnchantButton, m400AutogunButton;

    override void Init (Menu parent) {
        Super.Init (parent);
        SetBaseResolution ((640, 480));
        menuactive = Menu.OnNoPause;

        CPlayer = players [consolePlayer];

        if (!CPlayer || !CPlayer.mo)
            return;

        handler = new ('S7_PlayerMenuHandler');
        handler.link = self;

        bigFont = Font.GetFont ('BigFont');
        smallFont = Font.GetFont ('S7TxtFnt.FON2');

        menusFrame = S7_ZF_Frame.Create ((0, 0), (640, 480));
        menusFrame.Pack (mainFrame);

        string labelText = StringTable.Localize ("$PLAYERMENUHEADER", true);
        S7_ZF_Label label = S7_ZF_Label.Create ((0, 12), (0, bigFont.GetHeight ()), text: labelText, fnt: bigFont, wrap: false, autoSize: true, textColor: Font.CR_White);
        label.SetPosX (320.0 - (bigFont.stringWidth (labelText) / 2.0));
        label.Pack (menusFrame);

        double fontHeight = smallFont.GetHeight ();

        int buttonCount = 0;
        AddButton (xpSysButton, "$PLAYERMENU_XPMENU", 15 + ((fontHeight+4) * buttonCount++), handler, "openXPSysMenu");
        AddButton (luciusShopButton, "$PLAYERMENU_LUCIUSSHOP", 15 + ((fontHeight+4) * buttonCount++), handler, "openLuciusShop");
        AddButton (weapAssignButton, "$PLAYERMENU_WEAPASSIGN", 15 + ((fontHeight+4) * buttonCount++), handler, "openWeapAssignMenu");
        if (false) //CheckInventory ('S7_DracoStored'))
            AddButton (dracoWeapAssignButton, "$PLAYERMENU_DRACOWEAPASSIGN", 15 + ((fontHeight+4) * buttonCount++), handler, "openDracoWeapMenu");
        AddButton (weapEnchantButton, "$PLAYERMENU_WEAPENCHANTMENT", 15 + ((fontHeight+4) * buttonCount++), handler, "openWeaponEnchantmentMenu");
        if (CheckInventory ('S7_M400AutogunStored'))
            AddButton (m400AutogunButton, "$PLAYERMENU_M400AUTOGUN", 15 + ((fontHeight+4) * buttonCount++), handler, "openAutogunMenu");
    }

    bool CheckInventory (Class<Inventory> item, int amount = 1) {
        if (CPlayer == null)
            return false;

        let it = CPlayer.mo.FindInventory (item);
        return it != null && it.Amount >= amount;
    }

    void AddButton (out S7_ZF_Button button, string label, double yOffs, S7_ZF_Handler cmdHandler = null, string command = "") {
        string btnText = StringTable.Localize (label, true);
        int btnTextWidth = smallFont.StringWidth (btnText), btnTextHeight = smallFont.GetHeight ();

        button = S7_ZF_Button.Create (((640 - btnTextWidth) / 2, ((480 - btnTextHeight) / 2) + yOffs), (btnTextWidth, btnTextHeight),
            btnText, cmdHandler: cmdHandler, command: command, fnt: smallFont);
        button.Pack (menusFrame);
    }

    override void Ticker () {
        Super.Ticker ();
        menuactive = Menu.OnNoPause;

        if (!CPlayer || !CPlayer.mo || CPlayer.mo.health < 1) {
            self.Close ();
            return;
        }

        xpSysButton.SetTextColor       (      xpSysButton.IsHovered () ? Font.CR_LightBlue : Font.CR_White);
        luciusShopButton.SetTextColor  ( luciusShopButton.IsHovered () ? Font.CR_LightBlue : Font.CR_White);
        weapAssignButton.SetTextColor  ( weapAssignButton.IsHovered () ? Font.CR_LightBlue : Font.CR_White);
        weapEnchantButton.SetTextColor (weapEnchantButton.IsHovered () ? Font.CR_LightBlue : Font.CR_White);
        if (dracoWeapAssignButton)
            dracoWeapAssignButton.SetTextColor (dracoWeapAssignButton.IsHovered () ? Font.CR_LightBlue : Font.CR_White);
        if (m400AutogunButton)
            m400AutogunButton.SetTextColor (m400AutogunButton.IsHovered () ? Font.CR_LightBlue : Font.CR_White);
    }
}
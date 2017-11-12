class S7_WeapAssignMenu : GenericMenu {
    S7_WeapAssignMenuElement e;

    override void Init (Menu parent) {
        Super.Init (parent);
        dontDim = true;
        e = S7_WeapAssignMenuElement (new ('S7_WeapAssignMenuElement').Init ());
        e.CPlayer = players [consoleplayer];
    }

    override void Ticker () {
        super.Ticker ();
        if (e) e.OnTick();
    }

    override void Drawer () {
        if (e) e.OnDraw ();
    }

    override bool OnUIEvent (UIEvent ev) {
        if (e) return e.OnProcessUi (ev);
        return false;
    }

    override bool OnInputEvent (InputEvent ev) {
        if (e) return e.OnProcessInput (ev);
        return false;
    }

    override bool MenuEvent (int mkey, bool fromcontroller) {
        if (e && e.MenuEvent (mkey, fromcontroller))
            return true;
        return Menu.MenuEvent (mkey, fromcontroller);
    }
}

class S7_WeapAssignMenu_ButtonsArray { Array<S7_Menu_Button> Arrays; }
class S7_WeapAssignMenuElement : S7_BaseMenu {
    Font SmallFont;
    Font BigFont;

    PlayerInfo CPlayer;

    private Vector2 selectedButton;
    private Array<S7_WeapAssignMenu_ButtonsArray> mButtons;
    private S7_Menu_Label AddLabel (string text, Vector2 coords, Font fnt = 'SmallFont') {
        S7_Menu_Label label = new ('S7_Menu_Label');
        label.Init ();
        AddChild (label);
        label.mRect = Rect.FromXYWH (coords.X, coords.Y, fnt.StringWidth (text), fnt.GetHeight ());
        label.TextFont = fnt;
        label.Text = text;

        return label;
    }
    private S7_Menu_Button AddButton (string text, uint column, Vector2 coords, Font fnt = 'SmallFont') {
        S7_Menu_Button button = new ('S7_Menu_Button');
        button.Init ();
        AddChild (button);
        button.mRect = Rect.FromXYWH (coords.X, coords.Y, fnt.StringWidth (text), fnt.GetHeight ());
        button.TextFont = fnt;
        button.Text = text;
        if (column >= mButtons.Size ()) {
            while ((column + 1) > mButtons.Size ())
                mButtons.Push (new ("S7_WeapAssignMenu_ButtonsArray"));
        }

        mButtons [column].Arrays.Push (button);

        return button;
    }
    private S7_Menu_Image AddImage (string img, Vector2 coords) {
        S7_Menu_Image image = new ('S7_Menu_Image');
        image.Init ();
        AddChild (image);
        image.SetImage (img, true);
        image.mRect.X = coords.X;
        image.mRect.Y = coords.Y;

        return image;
    }

    static const String weapLabelsText [] = {
        "Medium", "Light", "Heavy", "Area-damage", "Special"
    };
    S7_Menu_Label  weapLabels [5];
    S7_Menu_Image  weapImg    [3] [5];
    S7_Menu_Button weapButton [3] [5];
    override void OnCreate () {
        mRect = Rect.FromXYWH (0, 0, Screen.GetWidth (), Screen.GetHeight ());
        mScale = max (1.0, Screen.GetWidth () / 640.0);

        //selectedButton = 0;
        SmallFont = Font.GetFont ('SmallFont');
        BigFont = Font.GetFont ('BigFont');

        let label = AddLabel ("WEAPON SLOT ASSIGNMENT", (0, 12), BigFont);
        label.mRect.X = 320.0 - (label.mRect.Width / 2.0);
        label.Colour = Font.CR_WHITE;

        for (int x = 0; x < 5; x++) {
            double xCoords = 19.0 + ((105.0 + 19.0) * x);
            weapLabels [x] = AddLabel (weapLabelsText [x], (xCoords, 48.0), "S7FSHUDFNT.lmp");
            weapLabels [x].mRect.X += (105.0 / 2) - (weapLabels [x].mRect.Width / 2.0);
            weapLabels [x].Colour = Font.CR_WHITE;
            for (int y = 0; y < 3; y++) {
                double yCoords = 72.0 + ((40.0 + 8.0) * y);
                // Buttons
                weapButton [x] [y] = AddButton ("", x, (xCoords, yCoords));
                weapButton [x] [y].mRect = Rect.FromXYWH (xCoords, yCoords, 105.0, 40.0);
                weapButton [x] [y].IsEnabled = false;
                weapButton [x] [y].SetBackground (
                    "graphics/Menu/WeapAssignment/WeapSlot.png",
                    "graphics/Menu/WeapAssignment/WeapSlotHover.png",
                    "graphics/Menu/WeapAssignment/WeapSlotHover.png",
                    "graphics/Menu/WeapAssignment/WeapSlotPressed.png",
                    ""
                );
                // Images
                weapImg [x] [y] = AddImage ("", (0, 0));
                weapImg [x] [y].mRect = Rect.FromXYWH (xCoords, yCoords, 105.0, 40.0);
            }
        }

        //SetFocus ();
    }

    override void Draw () {
        Rect r = GetClientRect ();
        Drawer d = GetDrawer ();

        d.Dim (0x000000, 0.5, 0, 0, r.Width, r.Height);
    }

    override void Tick () { // GetClassName
        if (!CPlayer || !CPlayer.mo)
            return;

        let weapBinds = S7_WeapBindsSystem (CPlayer.mo.FindInventory ("S7_WeapBindsSystem"));
        
        Array<S7_BaseWeapon> weapons;
        S7_BaseWeapon weap;
        for (int i = 0; i < 5; i++) {
            weapons.Clear ();
            weapons.Copy (weapBinds.Binds [i + 1]);

            for (int j = 0; j < 3; j++) {
                if (j < weapBinds.Binds [i + 1].Size () && (weap = weapons [j])){
                    weapImg [i] [j].SetImage (weap.weapIcon, false);
                    int imgWidth, imgHeight;
                    [imgWidth, imgHeight] = TexMan.GetSize (weapImg [i] [j].Image);
                    weapImg [i] [j].Offset.X = (105.0 / 2.0) - (imgWidth / 2.0);
                    weapImg [i] [j].Offset.Y = (40.0 / 2.0) - (imgHeight / 2.0);

                    weapButton [i] [j].IsEnabled = true;
                } else {
                    weapImg [i] [j].SetImage ("", false);
                    weapImg [i] [j].Offset.X = weapImg [i] [j].Offset.Y = 0; // Set these just to make sure
                    weapButton [i] [j].IsEnabled = (j + 1 > weapBinds.SlotMaximum [j]) ? true : false;
                }
            }
        }
    }

    override void SetFocus (Element control) {
        Array<S7_Menu_Button> arrays;

        if (control == null) { // Probably just a very small increase in performance, but whatever
            selectedButton.X = selectedButton.Y = 0;
            for (int x = 0; x < mButtons.Size (); x++) {
                arrays.Clear ();
                arrays.Copy (mButtons [x].Arrays);
                for (int y = 0; y < arrays.Size (); y++)
                    arrays [y].IsFocused = false;
            }
        } else {
            for (int x = 0; x < mButtons.Size (); x++) {
                arrays.Clear ();
                arrays.Copy (mButtons [x].Arrays);
                for (int y = 0; y < arrays.Size (); y++) {
                    bool theButton = (arrays [y] == control);
                    arrays [y].IsFocused = theButton;
                    if (theButton) {
                        selectedButton.X = x;
                        selectedButton.Y = y;
                    }
                }
            }
        }
    }

    bool MenuEvent (int mkey, bool fromcontroller) { // This is so bad...
        Array<S7_Menu_Button> arrays;
        switch (mkey) {
            case Menu.MKEY_Up:
                arrays.Copy (mButtons [selectedButton.X].Arrays);
                if (selectedButton.Y > 0) {
                    do {
                        selectedButton.Y--;
                    } while (selectedButton.Y > 0 && !arrays [selectedButton.Y].IsEnabled);
                }

                SetFocus (arrays [selectedButton.Y]);
                return true;

            case Menu.MKEY_Down:
                arrays.Copy (mButtons [selectedButton.X].Arrays);
                if (selectedButton.Y < arrays.Size () - 1) {
                    do {
                        selectedButton.Y++;
                    } while (selectedButton.Y < arrays.Size () && !arrays [selectedButton.Y].IsEnabled);
                }

                SetFocus (arrays [selectedButton.Y]);
                return true;

            case Menu.MKEY_Left:
                arrays.Copy (mButtons [selectedButton.X].Arrays);
                if (selectedButton.X > 0) {
                    do {
                        selectedButton.X--;
                        arrays.Clear ();
                        arrays.Copy (mButtons [selectedButton.X].Arrays);
                    } while (selectedButton.X > 0 && !arrays [selectedButton.Y].IsEnabled);
                }

                SetFocus (arrays [selectedButton.Y]);
                return true;

            case Menu.MKEY_Right:
                arrays.Copy (mButtons [selectedButton.X].Arrays);
                if (selectedButton.X < mButtons.Size () - 1) {
                    do {
                        selectedButton.X++;
                        arrays.Clear ();
                        arrays.Copy (mButtons [selectedButton.X].Arrays);
                    } while (selectedButton.X < mButtons.Size () && !arrays [selectedButton.Y].IsEnabled);
                }

                SetFocus (arrays [selectedButton.Y]);
                return true;

            case Menu.MKEY_Enter:
                arrays.Copy (mButtons [selectedButton.X].Arrays);
                arrays [selectedButton.Y].Click ();
                return true;
        }

        return false;
    }
}

class S7_WeapAssignMenu_EventHandler : EventHandler {
    override void NetworkProcess (ConsoleEvent e) {
        if (e.IsManual || e.Player < 0) // Don't execute this if it was called manually or the player isn't given/valid
            return;
        if (!playeringame [e.Player] || !players [e.Player].mo) // Don't execute if the player isn't ingame, the player is null or the player's PlayerPawn is null
            return;

        Array<String> strings;
        e.Name.Split (strings, ":");
        if (strings.Size () != 2 || strings [0] != "S7_WeapBindsSystem") // Return if the array doesn't contain exactly two strings or the first string isn't "S7_WeapBindsSystem"
            return;

    }
}   
class S7_Menu_Button : S7_Menu_BaseControl {
    protected bool IsDown;
    protected bool IsClicked;
    protected bool IsHovered;
    
    // Background
    Vector2 BackgroundOffset;
    TextureID BackgroundDisabled;
    TextureID BackgroundHover;
    TextureID BackgroundFocused;
    TextureID BackgroundPressed;
    TextureID Background;
    // Colors
    int DisabledColour;
    int HoverColour;
    int FocusedColour;
    int PressedColour;
    int Colour;
    // Button status
    bool IsEnabled;
    bool IsFocused;
    // Text
    Vector2 TextOffset;
    Font TextFont;
    String Text;

    void SetBackground (string img, string imgHover = "", string imgFocused = "", string imgPressed = "", string imgDisabled = "") {
        Background = TexMan.CheckForTexture (img, TexMan.Type_Any);
        BackgroundHover = TexMan.CheckForTexture (imgHover, TexMan.Type_Any);
        BackgroundFocused = TexMan.CheckForTexture (imgFocused, TexMan.Type_Any);
        BackgroundPressed = TexMan.CheckForTexture (imgPressed, TexMan.Type_Any);
        BackgroundDisabled = TexMan.CheckForTexture (imgDisabled, TexMan.Type_Any);
    }
    
    // Returns true if this button was clicked in this or previous tick
    bool CheckClicked () {
        return IsClicked;
    }

    override void OnCreate () {
        super.OnCreate ();

        DisabledColour = Font.CR_DARKGRAY; // Default colors
        HoverColour = Font.CR_BRICK;
        FocusedColour = Font.CR_RED;
        PressedColour = Font.CR_DARKRED;
        Colour = Font.CR_UNTRANSLATED;

        IsDown = false;
        IsEnabled = true;
        IsFocused = false;

        TextFont = Font.GetFont ('SmallFont');
        Text = "button";
    }
    
    override void Draw () {
        Rect r = GetClientRect ();
        Drawer d = GetDrawer ();
        int curColour;
        TextureID bg;

        if (!IsEnabled) {
            curColour = DisabledColour;
            bg = BackgroundDisabled;
        } else if (IsHovered && !IsDown) {
            curColour = HoverColour;
            bg = BackgroundHover;
        } else if (IsFocused && !IsDown) {
            curColour = FocusedColour;
            bg = BackgroundFocused;
        } else if (!IsDown) {
            curColour = Colour;
            bg = Background;
        } else {
            curColour = PressedColour;
            bg = BackgroundPressed;
        }

        d.DrawText (TextFont, curColour, TextOffset.X, TextOffset.Y, Text, Alpha, Drawer.Align_Left);
        d.DrawTexture (bg, true, BackgroundOffset.X, BackgroundOffset.Y, Alpha);
    }
    
    override bool Process (ElementEvent e) {
        if (!IsEnabled) return false;
    
        Rect r = GetClientRect ();
        r.X = 0;
        r.Y = 0;
        
        if (e.Type >= UiEvent.Type_FirstMouseEvent && e.Type <= UiEvent.Type_LastMouseEvent) {
            vector2 m = GetMouseXY ();
            bool mouseInRect = (m.x >= r.X && m.x < r.X + r.Width &&
                                m.y >= r.Y && m.y < r.Y + r.Height);
            IsHovered = mouseInRect;
            
            if (mouseInRect && e.Type == UiEvent.Type_LButtonDown) {
                IsDown = true;
                S7_BaseMenu (mParent).SetFocus (self);
                return true;
            } else if (e.Type == UiEvent.Type_LButtonUp) {
                if (IsDown)
                    S7_BaseMenu (mParent).SetFocus (null);

                IsClicked = IsDown && IsHovered; // you can click, move mouse away and release, and it wont click - just like windows
                IsDown = false;
                return false;
            }
        }
        
        return false;
    }
    
    override void Tick () {
        IsClicked = false;
    }
    
    void Click () {
        IsClicked = true;
    }
}
class S7_Menu_Button : Element {
    protected bool IsDown;
    protected bool IsClicked;
    protected bool IsHovered;
    
    // Background
    Vector2 backgroundOffset;
    protected TextureID backgroundDisabled;
    protected TextureID backgroundHover;
    protected TextureID backgroundFocused;
    protected TextureID backgroundPressed;
    protected TextureID background;
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
    Font TextFont;
    String Text;

    void SetBackground (string img, string imgHover = "", string imgFocused = "", string imgPressed = "", string imgDisabled = "") {
        background = TexMan.CheckForTexture (img, TexMan.Type_Any);
        backgroundHover = TexMan.CheckForTexture (imgHover, TexMan.Type_Any);
        backgroundFocused = TexMan.CheckForTexture (imgFocused, TexMan.Type_Any);
        backgroundPressed = TexMan.CheckForTexture (imgPressed, TexMan.Type_Any);
        backgroundDisabled = TexMan.CheckForTexture (imgDisabled, TexMan.Type_Any);
    }
    
    // Returns true if this button was clicked in this or previous tick
    bool CheckClicked () {
        return IsClicked;
    }

    override void OnCreate () {
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
            bg = backgroundDisabled;
        } else if (IsHovered && !IsDown) {
            curColour = HoverColour;
            bg = backgroundHover;
        } else if (IsFocused && !IsDown) {
            curColour = FocusedColour;
            bg = backgroundFocused;
        } else if (!IsDown) {
            curColour = Colour;
            bg = background;
        } else {
            curColour = PressedColour;
            bg = backgroundPressed;
        }

        d.DrawText (TextFont, curColour, 0.0, 0.0, Text, 1.0, Drawer.Align_Left);
        d.DrawTexture (bg, true, backgroundOffset.X, backgroundOffset.Y, 1.0);
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
class S7_Menu_Label : S7_Menu_BaseControl {
    int Colour;
    Font TextFont;
    String Text;

    override void OnCreate () {
        super.OnCreate ();

        Colour = Font.CR_UNTRANSLATED;
        TextFont = Font.GetFont ('SmallFont');
        Text = "button";
    }
    
    override void Draw () {
        Rect r = GetClientRect ();
        Drawer d = GetDrawer ();

        d.DrawText (TextFont, Colour, 0.0, 0.0, Text, Alpha, Drawer.Align_Left);
    }
}
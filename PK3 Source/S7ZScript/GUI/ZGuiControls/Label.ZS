class S7_Menu_Label : Element {
    int Colour;
    Font TextFont;
    String Text;

    override void OnCreate () {
        Colour = Font.CR_UNTRANSLATED;
        TextFont = Font.GetFont ('SmallFont');
        Text = "button";
    }
    
    override void Draw () {
        Rect r = GetClientRect ();
        Drawer d = GetDrawer ();

        d.DrawText (TextFont, Colour, 0.0, 0.0, Text, 1.0, Drawer.Align_Left);
    }
    
    override bool Process (ElementEvent e) {
        return false;
    }
}
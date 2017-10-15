class S7_Menu_Image : S7_Menu_BaseControl {
    Vector2 Offset;
    TextureID Image;

    override void OnCreate () {
        super.OnCreate ();

        Offset = (0.0, 0.0);
    }

    void SetImage (string img, bool setSize = false) {
        Image = TexMan.CheckForTexture (img, TexMan.Type_Any);

        if (setSize) {
            int width, height;
            [width, height] = TexMan.GetSize (Image);
            mRect.Width = width;
            mRect.Height = height;
        }
    }
    
    override void Draw () {
        Rect r = GetClientRect ();
        Drawer d = GetDrawer ();

        d.DrawTexture (Image, true, Offset.X, Offset.Y, Alpha);
    }
}
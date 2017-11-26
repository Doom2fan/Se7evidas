class S7_ZF_Image : S7_ZF_Element {
    enum Align {
        AlignLeft    = 1,
        AlignHCenter = 2,
        AlignRight   = 3,

        AlignTop     = 1 << 4,
        AlignVCenter = 2 << 4,
        AlignBottom  = 3 << 4,

        AlignTopLeft   = AlignTop | AlignLeft,
        AlignTopCenter = AlignTop | AlignHCenter,
        AlignTopRight  = AlignTop | AlignRight,

        AlignCenterLeft  = AlignVCenter | AlignLeft,
        AlignCenter      = AlignVCenter | AlignHCenter,
        AlignCenterRight = AlignVCenter | AlignRight,

        AlignBottomLeft   = AlignBottom | AlignLeft,
        AlignBottomCenter = AlignBottom | AlignHCenter,
        AlignBottomRight  = AlignBottom | AlignRight,
    }

    string image;
    int alignment;
    Vector2 imageScale;
    bool noOffsets;
    
    void config(string image = "", int alignment = AlignTopLeft, Vector2 imageScale = (1, 1), bool noOffsets = true) {
        self.image = image;
        self.alignment = alignment;
        self.imageScale = imageScale;
        self.noOffsets = noOffsets;
    }
    
    S7_ZF_Image init(Vector2 pos, Vector2 size, string image = "", int alignment = AlignTopLeft, Vector2 imageScale = (1, 1), bool noOffsets = true) {
        self.config(image, alignment, imageScale, noOffsets);
        self.setBox(pos, size);
        
        return self;
    }
    
    override void drawer() {
        TextureID tex = TexMan.checkForTexture(image, TexMan.Type_Any);

        if (!tex)
            return;

        Vector2 imageSize = TexMan.GetScaledSize (tex);
        Vector2 pos;

        if (alignment & AlignLeft)
            pos.x = 0.0;
        else if (alignment & AlignHCenter)
            pos.x = (box.size.x - imageSize.x) / 2;
        else if (alignment & AlignRight)
            pos.x = box.size.x - imageSize.x;

        if (alignment & AlignTop)
            pos.y = 0.0;
        else if (alignment & AlignVCenter)
            pos.y = (box.size.y - imageSize.y) / 2;
        else if (alignment & AlignBottom)
            pos.y = box.size.y - imageSize.y;

        drawImage(pos, image, true, imageScale, clipRect: boxToScreen(), offsets: !noOffsets);
    }
}
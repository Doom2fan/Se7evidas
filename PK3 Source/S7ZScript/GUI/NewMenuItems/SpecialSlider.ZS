class OptionMenuItemS7_SliderSpcVal : OptionMenuItemSlider {
    String TextSpc;
    double SpecialVal;
    double mRetMin;
    int mClickVal;
    
    OptionMenuItemS7_SliderSpcVal Init (String label, Name command, double min, double max, double step, double spcVal, double retMin, String spcText) {
        Super.Init (label, command, min, max, step, 0);
        mCVar = CVar.FindCVar (command);

        SpecialVal = spcVal;
        mRetMin = retMin;
        TextSpc = spcText;

        mClickVal = -10;

        return self;
    }

    //=============================================================================
    override int Draw (OptionMenuDescriptor desc, int y, int indent, bool selected) {
        drawLabel (indent, y, selected ? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor);

        int Selection = int (GetSliderValue ());

        if (Selection == SpecialVal) {
            String text = ((Selection == SpecialVal) ? TextSpc : "");
            screen.DrawText (SmallFont, OptionMenuSettings.mFontColorValue, indent + CursorSpace (), y, text, DTA_CleanNoMove_1, true);
        } else {
            mDrawX = indent + CursorSpace ();
            DrawSlider (mDrawX, y, mMin, mMax, GetSliderValue (), mShowValue, indent);
        }
        return indent;
    }

    override bool MenuEvent (int mkey, bool fromcontroller) {
        double value = GetSliderValue ();

        if (mkey == Menu.MKEY_Right && value ~== SpecialVal) {
            bool ret = Super.MenuEvent (mkey, fromcontroller);

            if (ret)
                SetSliderValue (mRetMin);

            return ret;
        }

        return Super.MenuEvent (mkey, fromcontroller);
    }
    
    override bool MouseEvent (int type, int x, int y) {
        int value = int (GetSliderValue ());

        switch (type) {
            case Menu.MOUSE_Click:
                mClickVal = value;
                if (value <= 0) return false;
                return Super.MouseEvent (type, x, y);
                
            case Menu.MOUSE_Move:
                if (mClickVal <= 0) return false;
                return Super.MouseEvent (type, x, y);
                
            case Menu.MOUSE_Release:
                if (mClickVal <= 0) {
                    mClickVal = -10;
                    SetSliderValue (value + 1);
                    return true;
                }
                mClickVal = -10;
                return Super.MouseEvent (type, x, y);
        }
        return false;
    }
}
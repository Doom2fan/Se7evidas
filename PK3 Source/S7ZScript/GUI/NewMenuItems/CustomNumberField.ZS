class OptionMenuItemCustomNumberField : OptionMenuFieldBase {
    TextEnterMenu mEnter;
    float mMinimum;
    float mMaximum;

    OptionMenuItemCustomNumberField Init (string label, Name command, string minimum = "0", string maximum = "", CVar graycheck = null) {
        Super.Init (label, command, graycheck);

        mMinimum = (minimum == "" ? -float.Infinity : minimum.ToDouble ());
        mMaximum = (maximum == "" ?  float.Infinity : maximum.ToDouble ());

        return self;
    }

    override String Represent () {
        if (mEnter)
            return mEnter.GetText () .. SmallFont.GetCursor ();

        return String.Format ("%.3f", mCVar.GetFloat ());
    }

    override int Draw (OptionMenuDescriptor desc, int y, int indent, bool selected) {
        if (mEnter) {
            // reposition the text so that the cursor is visible when in entering mode.
            String text = Represent ();
            int tlen = SmallFont.StringWidth (text) * CleanXfac_1;
            int newindent = screen.GetWidth () - tlen - CursorSpace ();

            if (newindent < indent)
                indent = newindent;
        }

        return Super.Draw (desc, y, indent, selected);
    }

    override bool MenuEvent (int mkey, bool fromcontroller) {
        if (mkey == Menu.MKEY_Enter) {
            Menu.MenuSound ("menu/choose");

            mEnter = TextEnterMenu.Open (Menu.GetCurrentMenu (), GetCVarString (), -1, 2, fromcontroller);
            mEnter.ActivateMenu ();
        } if (mkey == Menu.MKEY_Input) {
            float value = mCVar.GetFloat ();

            value = mEnter.GetText ().ToDouble ();
            Console.PrintF ("%f", value);

            if (value > mMaximum)
                value = mMaximum;
            else if (value < mMinimum)
                value = mMinimum;

            if (mCVar) {
                int cvarType = mCVar.GetRealType ();

                if (cvarType == CVar.CVAR_Int)
                    mCVar.SetInt (int (value));
                else if (cvarType == CVar.CVAR_Float)
                    mCVar.SetFloat (value);
            }

            mEnter = null;
        } else if (mkey == Menu.MKEY_Abort)
            mEnter = null;
        else
            return Super.MenuEvent (mkey, fromcontroller);

        return true;
    }
}
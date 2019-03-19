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
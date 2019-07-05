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

class S7_PlayerclassMenu : OptionMenu {
    enum PlayerClassFlags {
        PCF_NOMENU = 1, // Hide in new game menu
    };

    //=============================================================================
    //
    // Constants
    //
    //=============================================================================
    const DESCBOX_ArrowRightTex = "INVGEMR1";
    const DESCBOX_ArrowLeftTex  = "INVGEML1";
    const DESCBOX_ArrowScale = 1.5;
    const DESCBOX_Width = (100 + 72 + 100);
    const DESCBOX_Height = (132 - 8) * 2;
    string classDesc;
    int curPage, pagesCount;

    int arrowsX;
    int arrowRightY, arrowLeftY;

    //=============================================================================
    //
    // Init
    //
    //=============================================================================
    override void Init (Menu parent, OptionMenuDescriptor desc) {
        Super.Init (parent, desc);
        /*mParentMenu = parent;
        mDesc = desc;
        DontDim = desc.mDontDim;
        if (mDesc != NULL && mDesc.mSelectedItem == -1) mDesc.mSelectedItem = FirstSelectable ();
        mDesc.CalcIndent ();

        // notify all items that the menu was just created.
        for (int i=0;i<mDesc.mItems.Size (); i++)
        {
            mDesc.mItems [i].OnMenuCreated ();
        }*/

        desc.mMenuName = "S7_PlayerclassMenu";
        desc.mTitle = "$MNU_CHOOSECLASS";
        desc.mScrollPos = 0;
        desc.mClass = GetClass ();
        desc.mPosition = -15;
        desc.mScrollTop = 0;
        desc.mIndent = 125;
        desc.mDontDim = false;
        desc.mNetgameMessage = "$NEWGAME";

        if (desc.mItems.Size () == 0) {
            desc.mItems.Clear ();
            for (int i = 0; i < PlayerClasses.Size (); i++) {
                if (!(PlayerClasses [i].Type is 'S7_BasePlayer'))
                    continue;

                if (!(PlayerClasses [i].Flags & PCF_NoMenu)) {
                    string pname = PlayerPawn.GetPrintableDisplayName (PlayerClasses [i].Type);

                    if (pname) {
                        let it = CreateOptionMenuItemSubmenu (pname, "Episodemenu", i);
                        desc.mItems.Push (it);
                    }
                }

                desc.mSelectedItem = 0;
            }

            let it = CreateOptionMenuItemSubmenu ("Random", "Episodemenu", -1);
            desc.mItems.Push (it);

            let pDisplay = new ('OptionMenuItemS7_PlayerDisplay');
            if (pDisplay) {
                pDisplay.DoInit (desc, "20 00 00", "80 00 40");
                desc.mItems.Push (pDisplay);
            }
        }
    }

    OptionMenuItem CreateOptionMenuItemSubmenu (string label, name cmd, int param) {
        let p = new ('OptionMenuItemS7_Submenu');

        if (p) {
            p.Init (label, cmd, param, false);
        }

        return p;
    }

    //=============================================================================
    //
    // Ticker
    //
    //=============================================================================
    void UpdatePlayerClass () {
        if (mDesc.mSelectedItem < 0 || PlayerClasses.Size () == 0) {
            classDesc = "";
            return;
        }

        int classnum;
        Name seltype;

        [seltype, classnum] = mDesc.mItems [mDesc.mSelectedItem].GetAction ();

        if (seltype != 'Episodemenu' || classnum < 0 || classnum >= PlayerClasses.Size ()) {
            classDesc = "";
            return;
        }

        let defs = GetDefaultByType ((class<S7_BasePlayer>) (PlayerClasses [classnum].Type));

        if (defs)
            classDesc = defs.classDesc;
    }

    override void Ticker () {
        Super.Ticker ();

        UpdatePlayerClass ();
    }

    //=============================================================================
    //
    // Input
    //
    //=============================================================================
    override bool MenuEvent (int mkey, bool fromcontroller) {
        switch (mkey) {
        case MKEY_Left:
            curPage--;

            if (curPage < 0) curPage = 0;
            else MenuSound ("menu/cursor");

            return true;
        break;

        case MKEY_Right:
            curPage++;

            if (curPage >= pagesCount) curPage = pagesCount - 1;
            else MenuSound ("menu/cursor");

            return true;
        break;
        }

        int curSelected = mDesc.mSelectedItem;
        bool ret = Super.MenuEvent (mkey, fromcontroller);

        if (curSelected != mDesc.mSelectedItem)
            curPage = 0;

        return ret;
    }

    override bool MouseEvent (int type, int x, int y) {
        if (type == MOUSE_Click) {
            let arrowLeft  = TexMan.CheckForTexture (DESCBOX_ArrowLeftTex , TexMan.Type_Any),
                arrowRight = TexMan.CheckForTexture (DESCBOX_ArrowRightTex, TexMan.Type_Any);

            Vector2 arrowLeftSize  = TexMan.GetScaledSize (arrowLeft ) * DESCBOX_ArrowScale,
                    arrowRightSize = TexMan.GetScaledSize (arrowRight) * DESCBOX_ArrowScale;
            arrowLeftSize  = ( arrowLeftSize.X * CleanXfac_1,  arrowLeftSize.Y * CleanYfac_1);
            arrowRightSize = (arrowRightSize.X * CleanXfac_1, arrowRightSize.Y * CleanYfac_1);

            if (x >= arrowsX) {
                if ((x <= arrowsX + arrowLeftSize.X) && (y >= arrowLeftY) && (y <= arrowLeftY + arrowLeftSize.Y)) {
                    MenuEvent (MKEY_Left, false);
                    return true;
                } else if ((x <= arrowsX + arrowRightSize.X) && (y >= arrowRightY) && (y <= arrowRightY + arrowRightSize.Y)) {
                    MenuEvent (MKEY_Right, false);
                    return true;
                }
            }
        }


        y = (y / CleanYfac_1) - mDesc.mDrawTop;

        if (x >= (int (mDesc.mIndent - 160) * CleanXfac_1 + (Screen.GetWidth  () >> 1)))
            return false;

        if (mFocusControl) {
            mFocusControl.MouseEvent (type, x, y);
            return true;
        } else if (type == MOUSE_Click) {
            int yline = (y / OptionMenuSettings.mLinespacing);

            if (yline >= mDesc.mScrollTop)
                yline += mDesc.mScrollPos;

            if (yline >= 0 && yline < mDesc.mItems.Size () && mDesc.mItems [yline].Selectable ()) {
                if (yline != mDesc.mSelectedItem) {
                    MenuSound ("menu/cursor");
                    mDesc.mSelectedItem = yline;
                    curPage = 0;
                } else
                    mDesc.mItems [yline].MouseEvent (MOUSE_Release, x, y);

                return true;
            }
        }

        return false;
    }

    static Vector2, Vector2 GetBoxSizes (OptionMenu menu) {
        if (!menu)
            return (0, 0), (0, 0);

        int width  = Screen.GetWidth  ();
        int height = Screen.GetHeight ();
        int indent = menu.GetIndent ();

        return
            (indent + OptionWidth ("◄") + 2 + 3 + 8, height * .35),
            (DESCBOX_Width  * CleanXfac_1, DESCBOX_Height * CleanYfac_1)
        ;
    }

    //=============================================================================
    //
    // Drawer
    //
    //=============================================================================
    override void Drawer () {
        Super.Drawer ();

        if (classDesc == "")
            return;

        // Calculate box
        int descBoxX, descBoxY,
            descBoxW, descBoxH;
        {
            Vector2 descBoxPos, descBoxSize;
            [descBoxPos, descBoxSize] = GetBoxSizes (self);

            descBoxX = int (descBoxPos.X ); descBoxY = int (descBoxPos.Y );
            descBoxW = int (descBoxSize.X); descBoxH = int (descBoxSize.Y);
        }

        // Draw box
        Screen.Dim ("000000", 1, descBoxX, descBoxY, descBoxW, descBoxH);
        Screen.DrawFrame (descBoxX, descBoxY, descBoxW, descBoxH);

        // Get arrow textures
        let arrowLeft  = TexMan.CheckForTexture (DESCBOX_ArrowLeftTex , TexMan.Type_Any),
            arrowRight = TexMan.CheckForTexture (DESCBOX_ArrowRightTex, TexMan.Type_Any);
        Vector2 arrowLeftSize  = TexMan.GetScaledSize (arrowLeft ) * DESCBOX_ArrowScale,
                arrowRightSize = TexMan.GetScaledSize (arrowRight) * DESCBOX_ArrowScale;
        arrowLeftSize  = ( arrowLeftSize.X * CleanXfac_1,  arrowLeftSize.Y * CleanYfac_1);
        arrowRightSize = (arrowRightSize.X * CleanXfac_1, arrowRightSize.Y * CleanYfac_1);

        // Calculate arrow coords
        arrowsX = descBoxX + descBoxW + 3 + 2;
        arrowRightY = int (descBoxY + descBoxH - arrowRightSize.Y);

        arrowLeftY = int (arrowRightY - (arrowLeftSize.Y + 2));

        // Calculate lines
        let fnt = OptionFont (); //Font.GetFont ('S7TxtFnt.FON2');

        int fntHeight = fnt.GetHeight ();
        int maxLines = int (floor ((DESCBOX_Height - 4.*2.) / fntHeight));

        let lines = fnt.BreakLines (StringTable.Localize (classDesc, true), DESCBOX_Width-4);
        pagesCount = int (ceil (double (lines.Count ()) / maxLines));

        // Draw lines
        int lineX = int (descBoxX + (4 * CleanXfac_1));
        int iMax = min (lines.Count () - (curPage * (maxLines)), maxLines);
        for (int i = 0; i < iMax; i++) {
            string line = lines.StringAt ((curPage * maxLines) + i);
            int lineY = int ((descBoxY + 2 * CleanYfac_1) + (fntHeight * CleanYfac_1) * i);

            Screen.DrawText (fnt, Font.CR_White, lineX, lineY, line, DTA_CleanNoMove_1, true, DTA_KeepRatio, true);
        }

        // Draw arrows
        if (curPage > 0) {
            Screen.DrawTexture (
                arrowLeft , true,
                arrowsX, arrowLeftY ,
                DTA_CleanNoMove_1, true,
                DTA_KeepRatio, true,
                DTA_DestWidthF , arrowLeftSize.X,
                DTA_DestHeightF, arrowLeftSize.Y
            );
        }
        if (curPage < (pagesCount - 1)) {
            Screen.DrawTexture (
                arrowRight, true,
                arrowsX, arrowRightY,
                DTA_CleanNoMove_1, true,
                DTA_KeepRatio, true,
                DTA_DestWidthF , arrowRightSize.X,
                DTA_DestHeightF, arrowRightSize.Y
            );
        }
    }
}

class OptionMenuItemS7_Submenu : OptionMenuItemSubmenu {
    override Name, int GetAction () {
        return mAction, mParam;
    }
}

class OptionMenuItemS7_PlayerDisplay : OptionMenuItem {
    OptionMenuDescriptor mOwner;
    TextureID mBackdrop;
    PlayerClass mPlayerClass;
    State mPlayerState;
    int mPlayerTics;
    int8 mRotation;
    int8 mMode; // 0: automatic (used by class selection), 1: manual (used by player setup)
    int8 mTranslate;
    int mSkin;
    int mRandomClass;
    int mRandomTimer;
    int mClassNum;
    Color mBaseColor;
    Color mAddColor;

    enum EPDFlags {
        PDF_ROTATION = 0x10001,
        PDF_SKIN = 0x10002,
        PDF_CLASS = 0x10003,
        PDF_MODE = 0x10004,
        PDF_TRANSLATE = 0x10005,
    };

    //=============================================================================
    //
    //
    //
    //=============================================================================
    void DoInit (OptionMenuDescriptor menu, Color c1, Color c2, Name command = 'None') {
        mAction = "None";
        mEnabled = false;
        mOwner = menu;

        mBaseColor = c1;
        mAddColor = c2;

        mBackdrop = TexMan.CheckForTexture ("B@CKDROP", TexMan.Type_MiscPatch);  // The weird name is to avoid clashes with mods.
        mPlayerClass = NULL;
        mPlayerState = NULL;
        mMode = 0;
        mRotation = 0;
        mTranslate = false;
        mSkin = 0;
        mRandomClass = 0;
        mRandomTimer = 0;
        mClassNum = -1;
    }

    override bool Selectable () {
        return false;
    }

    private void UpdatePlayer (int classnum) {
        mPlayerClass = PlayerClasses [classnum];

        State newState = GetDefaultByType (mPlayerClass.Type).SeeState;

        if (newState == NULL) // No see state, so try spawn state.
            newState = GetDefaultByType (mPlayerClass.Type).SpawnState;

        if (newState)
            SetState (newState);
        else
            mPlayerTics = -1;
    }

    //=============================================================================
    //
    //
    //
    //=============================================================================

    private void UpdateRandomClass () {
        if (--mRandomTimer < 0) {
            if (++mRandomClass >= PlayerClasses.Size ()) mRandomClass = 0;
            UpdatePlayer (mRandomClass);
            if (mPlayerState)
                SetState (mPlayerState);
            else
                mPlayerTics = -1;
            mRandomTimer = 6;

            // Since the newly displayed class may use a different translation
            // range than the old one, we need to update the translation, too.
            Translation.SetPlayerTranslation (TRANSLATION_Players, MAXPLAYERS, consoleplayer, mPlayerClass);
        }
    }

    //=============================================================================
    //
    //
    //
    //=============================================================================

    void SetPlayerClass (int classnum, bool force = false) {
        if (classnum < 0 || classnum >= PlayerClasses.Size ()) {
            if (mClassNum != -1) {
                mClassNum = -1;
                mRandomTimer = 0;
                UpdateRandomClass ();
            }
        } else if (mPlayerClass != PlayerClasses [classnum] || force) {
            UpdatePlayer (classnum);
            mClassNum = classnum;
        }
    }

    //=============================================================================
    //
    //
    //
    //=============================================================================

    bool UpdatePlayerClass () {
        if (mOwner.mSelectedItem >= 0) {
            int classnum;
            Name seltype;

            [seltype, classnum] = mOwner.mItems [mOwner.mSelectedItem].GetAction ();

            if (seltype != 'Episodemenu') return false;
            if (PlayerClasses.Size () == 0) return false;

            SetPlayerClass (classnum);
            return true;
        }
        return false;
    }

    //=============================================================================
    //
    //
    //
    //=============================================================================

    override bool SetValue (int i, int value) {
        switch (i) {
        case PDF_MODE:
            mMode = value;
            return true;

        case PDF_ROTATION:
            mRotation = value;
            return true;

        case PDF_TRANSLATE:
            mTranslate = value;

        case PDF_CLASS:
            SetPlayerClass (value, true);
            break;

        case PDF_SKIN:
            mSkin = value;
            break;
        }
        return false;
    }

    void SetState (State st) {
        State next = st;
        do {
            mPlayerState = next;
            mPlayerTics = mPlayerState.Tics;
            next = mPlayerState.NextState;
        } while (mPlayerTics <= 0);
    }

    //=============================================================================
    //
    //
    //
    //=============================================================================

    override void Ticker () {
        if (mClassNum < 0) UpdateRandomClass ();

        if (mPlayerState != NULL && mPlayerState.Tics != -1 && mPlayerState.NextState != NULL) {
            if (--mPlayerTics <= 0)
                SetState (mPlayerState.NextState);
        }
    }

    //=============================================================================
    //
    //
    //
    //=============================================================================

    const DisplayWidth  = 120;
    const DisplayHeight = 120;
    override int Draw (OptionMenuDescriptor desc, int y, int indent, bool selected) {
        if (mMode == 0 && !UpdatePlayerClass ())
            return 0;

        let playdef = GetDefaultByType ((class<PlayerPawn>) (mPlayerClass.Type));

        Name portrait = playdef.Portrait;

        Vector2 boxPos, boxSize;
        [boxPos, boxSize] = S7_PlayerclassMenu.GetBoxSizes (OptionMenu (Menu.GetCurrentMenu ()));

        int x = int (boxPos.X + ((boxSize.X - DisplayWidth * CleanXFac_1) / 2.));
        int y = int (boxPos.Y - ((DisplayHeight + 16) * CleanYFac_1));

        int r = mBaseColor.r + mAddColor.r;
        int g = mBaseColor.g + mAddColor.g;
        int b = mBaseColor.b + mAddColor.b;
        int m = max (r, g, b);
        r = r * 255 / m;
        g = g * 255 / m;
        b = b * 255 / m;
        Color c = Color (255, r, g, b);

        screen.DrawTexture (mBackdrop, false, x, y - 1,
            DTA_CleanNoMove_1, true,
            DTA_DestWidthF , DisplayWidth  * CleanXfac_1,
            DTA_DestHeightF, DisplayHeight * CleanYfac_1,
            DTA_Color, c,
            DTA_Masked, true
        );

        Screen.DrawFrame (x, y, DisplayWidth * CleanXfac_1, DisplayHeight * CleanYfac_1 - 1);

        if (mPlayerState != NULL) {
            Vector2 Scale;
            TextureID sprite;
            bool flip;

            [sprite, flip, Scale] = mPlayerState.GetSpriteTexture (mRotation, mSkin, playdef.Scale);

            if (sprite.IsValid ()) {
                int trans = mTranslate ? Translation.MakeID (TRANSLATION_Players, MAXPLAYERS) : 0;
                let tscale = TexMan.GetScaledSize (sprite);
                Scale.X *= tscale.X * 1.5 * CleanXfac_1;
                Scale.Y *= tscale.Y * 1.5 * CleanYfac_1;

                screen.DrawTexture (sprite, false,
                    int (x + (DisplayWidth  * CleanXfac_1 / 2.)),
                    int (y + (DisplayHeight * CleanYfac_1 * .825)),
                    DTA_CleanNoMove_1, true,
                    DTA_DestWidthF , Scale.X,
                    DTA_DestHeightF, Scale.Y,
                    DTA_TranslationIndex, trans,
                    DTA_FlipX, flip
                );
            }
        }

        return 0;
    }
}
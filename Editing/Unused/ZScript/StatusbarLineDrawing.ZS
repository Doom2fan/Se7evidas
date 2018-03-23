    /** Custom drawing functions **/
    void DrawLine (Vector2 v1, Vector2 v2, Color col, int flags = 0, double alpha = 1., Vector2 scale = (1, 1)) {
        // scaling is borking this. idk why.
        alpha *= self.alpha;
        if (col.a <= 0 || alpha <= 0)
            return;

        // resolve auto-alignment before making any adjustments to the position values.
        if (!(flags & DI_SCREEN_MANUAL_ALIGN)) {
            if (v1.X < 0 && v2.X < 0)
                flags |= DI_SCREEN_RIGHT;
            else
                flags |= DI_SCREEN_LEFT;
            if (v1.Y < 0 && v2.Y < 0)
                flags |= DI_SCREEN_BOTTOM;
            else
                flags |= DI_SCREEN_TOP;
        }

        v1 += (drawOffset.X, drawOffset.Y);
        v2 += (drawOffset.X, drawOffset.Y);

        if (!fullscreenOffsets) {
            [v1.X, v1.Y] = StatusbarToRealCoords (v1.X, v1.Y, -1, -1);
            [v2.X, v2.Y] = StatusbarToRealCoords (v2.X, v2.Y, -1, -1);
        } else {
            double orgx, orgy;

            switch (flags & DI_SCREEN_HMASK) {
            default: orgx = 0; break;
            case DI_SCREEN_HCENTER: orgx = Screen.GetWidth () / 2; break;
            case DI_SCREEN_RIGHT:   orgx = Screen.GetWidth (); break;
            }

            switch (flags & DI_SCREEN_VMASK) {
            default: orgy = 0; break;
            case DI_SCREEN_VCENTER: orgy = Screen.GetHeight () / 2; break;
            case DI_SCREEN_BOTTOM:  orgy = Screen.GetHeight (); break;
            }

            // move stuff in the top right corner a bit down if the fps counter is on.
            if ((flags & (DI_SCREEN_HMASK|DI_SCREEN_VMASK)) == DI_SCREEN_RIGHT_TOP && vid_fps) orgy += 10;

            Vector2 hudScale = GetHUDScale ();

            v1.X *= hudScale.X; v2.X *= hudScale.X;
            v1.X *= hudScale.Y; v2.X *= hudScale.Y;
            v1 += (orgx, orgy);
            v2 += (orgx, orgy);
        }

        Screen.DrawLine (v1.X, v1.Y, v2.X, v2.Y, Color (int (col.a * alpha), col.r, col.g, col.b));
    }
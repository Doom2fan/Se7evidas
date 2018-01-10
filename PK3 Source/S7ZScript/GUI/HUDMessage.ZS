class S7_HudMessageData {
    int id;
    int targetPlayer;
    string text;
    Vector2 pos;
    int finalTics;

    int flags;
    int alignment;
    int color;
    int style;
    Font fnt;
    double alpha;
    Vector2 screenSize;

    protected int tics;

    virtual bool Tick () { // Returns true if the message is to be removed
        if (tics > finalTics)
            return true;

        tics++;

        return false;
    }

    virtual ui void Draw () {
        if (targetPlayer > -1 && targetPlayer != consoleplayer)
            return;

        Vector2 offsets = (0, 0);
        Vector2 textSize = (fnt.StringWidth (text), fnt.GetHeight ());

        if (alignment & S7_HudMessage.AlignLeft)
            offsets.x = 0.0;
        else if (alignment & S7_HudMessage.AlignHCenter)
            offsets.x = textSize.x / 2;
        else if (alignment & S7_HudMessage.AlignRight)
            offsets.x = textSize.x;

        if (alignment & S7_HudMessage.AlignTop)
            offsets.y = 0.0;
        else if (alignment & S7_HudMessage.AlignVCenter)
            offsets.y = textSize.y / 2;
        else if (alignment & S7_HudMessage.AlignBottom)
            offsets.y = textSize.y;

        if (screenSize != (0, 0)) {
            if (screenSize.x < 0 && screenSize.y < 0)
                Screen.DrawText (fnt, color, (Screen.GetWidth () * (pos.x / -screenSize.x)) - offsets.x, (Screen.GetHeight () * (pos.y / -screenSize.y)) - offsets.y, text, DTA_Alpha, alpha);
            else
                Screen.DrawText (fnt, color, pos.x - offsets.x, pos.y - offsets.y, text, DTA_VirtualWidthF, screenSize.x, DTA_VirtualHeightF, screenSize.y, DTA_KeepRatio, true, DTA_Alpha, alpha);
        } else {
            Screen.DrawText (fnt, color, (Screen.GetWidth () * pos.x) - offsets.x, (Screen.GetHeight () * pos.y) - offsets.y, text, DTA_Alpha, alpha);
        }
    }
}

class S7_HudMessageFadeData : S7_HudMessageData {
    double finalAlpha;
    int finalInTics, finalOutTics;

    protected int inTics, outTics;

    override bool Tick () {
        if (inTics < finalInTics) {
            alpha = finalAlpha * (Clamp (double (inTics), 0, finalInTics) / finalInTics);
            inTics++;
        } else if (tics < finalTics) {
            alpha = finalAlpha;
            tics++;
        } else if (outTics < finalOutTics) {
            alpha = finalAlpha * (1 - (Clamp (double (outTics), 0, finalOutTics) / finalOutTics));
            outTics++;
        } else
            return true;

        return false;
    }
}

class S7_HudMessage : EventHandler {
    enum Alignment {
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

    enum Flags {
        MSG_Log = 1,
    }

    private Array<S7_HudMessageData> hudMsgs;

    static void Show (int targetPlayer, string text, int id, Vector2 pos, int holdTics, int flags = 0, int alignment = S7_HudMessage.AlignTopLeft,
        int color = Font.CR_UNTRANSLATED, int style = STYLE_Normal, Font fnt = "SmallFont", double alpha = 1.0, Vector2 screenSize = (0, 0)
    ) {
        let h = S7_HudMessage (EventHandler.Find ("S7_HudMessage"));

        if (!h)
            return;

        if (id != 0) {
            for (int i = h.hudMsgs.Size () - 1; i >= 0; i--) {
                if (!h.hudMsgs [i]) {
                    h.hudMsgs.Delete (i, 1);
                    continue;
                } else if (h.hudMsgs [i].id == id) {
                    let tmp = h.hudMsgs [i];
                    h.hudMsgs.Delete (i, 1);
                    if (tmp)
                        tmp.Destroy ();
                }
            }
        }

        if (flags & MSG_Log && (targetPlayer < 0 || targetPlayer == consoleplayer))
            Console.PrintF (text); // This is the best I can do for now, unfortunately.

        let hudmsg = new ("S7_HudMessageData");
        hudmsg.id = id;
        hudmsg.targetPlayer = targetPlayer;
        hudmsg.text = text;
        hudmsg.pos = pos;
        hudmsg.finalTics = holdTics;

        hudmsg.flags = flags;
        hudmsg.alignment = alignment;
        hudmsg.color = color;
        hudmsg.style = style;
        hudmsg.fnt = fnt;
        hudmsg.alpha = alpha;
        hudmsg.screenSize = screenSize;

        h.hudMsgs.Push (hudmsg);
    }

    static void ShowFade (int targetPlayer, string text, int id, Vector2 pos, int holdTics, int inTics, int outTics, int flags = 0,
        int alignment = S7_HudMessage.AlignTopLeft, int color = Font.CR_UNTRANSLATED, int style = STYLE_Normal, Font fnt = "SmallFont",
        double alpha = 1.0, Vector2 screenSize = (0, 0)
    ) {
        let h = S7_HudMessage (EventHandler.Find ("S7_HudMessage"));

        if (!h)
            return;

        if (id != 0) {
            for (int i = h.hudMsgs.Size () - 1; i >= 0; i--) {
                if (!h.hudMsgs [i]) {
                    h.hudMsgs.Delete (i, 1);
                    continue;
                } else if (h.hudMsgs [i].id == id) {
                    let tmp = h.hudMsgs [i];
                    h.hudMsgs.Delete (i, 1);
                    if (tmp)
                        tmp.Destroy ();
                }
            }
        }

        if (flags & MSG_Log && (targetPlayer < 0 || targetPlayer == consoleplayer))
            Console.PrintF (text);

        let hudmsg = new ("S7_HudMessageFadeData");
        hudmsg.id = id;
        hudmsg.targetPlayer = targetPlayer;
        hudmsg.text = text;
        hudmsg.pos = pos;
        hudmsg.finalTics = holdTics;
        hudmsg.finalInTics  = inTics;
        hudmsg.finalOutTics = outTics;

        hudmsg.flags = flags;
        hudmsg.alignment = alignment;
        hudmsg.color = color;
        hudmsg.style = style;
        hudmsg.fnt = fnt;
        hudmsg.finalAlpha = alpha;
        hudmsg.screenSize = screenSize;

        h.hudMsgs.Push (hudmsg);
    }

    override void WorldTick () {
        Array<int> toDelete; // HudMessages to delete
        toDelete.Clear ();

        for (int i = 0; i < hudMsgs.Size (); i++) {
            if (!hudMsgs [i]) {
                toDelete.Push (i);
                continue;
            }
            if (hudMsgs [i].Tick ())
                toDelete.Push (i);
        }

        for (int i = toDelete.Size () - 1; i >= 0; i--)
            hudMsgs.Delete (toDelete [i], 1);
        toDelete.Clear ();
    }

    override void RenderOverlay (RenderEvent e) {
        for (int i = 0; i < hudMsgs.Size (); i++) {
            if (hudMsgs [i])
                hudMsgs [i].Draw ();
        }
    }
}
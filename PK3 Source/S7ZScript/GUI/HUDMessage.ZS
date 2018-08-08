class S7_HudMessageData {
    int targetPlayer;
    string text;
    Vector2 pos;
    int tics;

    int flags;
    int alignment;
    int color;
    int style;
    string fnt;
    double alpha;
    Vector2 screenSize;
}

class S7_HudMessage : HUDMessageBase {
    enum Alignment {
        AlignLeft    = 1,
        AlignHCenter = 2,
        AlignRight   = 3,

        AlignTop     = 1 << 16,
        AlignVCenter = 2 << 16,
        AlignBottom  = 3 << 16,

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

    S7_HudMessageData data;

    protected int tics;

    override bool Tick () {
        if (tics > data.Tics) {
            StatusBar.DetachMessage (self);
            return true;
        }

        tics++;

        return false;
    }

    override void Draw (int bottom, int visibility) {
        if (data.targetPlayer > -1 && data.targetPlayer != consoleplayer)
            return;

        string text = data.text;
        Font fnt = Font.GetFont (data.fnt);
        double alpha = data.alpha;

        Vector2 offsets = (0, 0);
        Vector2 pos = data.pos;
        Vector2 textSize = (fnt.StringWidth (text), fnt.GetHeight ());
        Vector2 screenSize = data.screenSize;

        let hAlign = data.alignment & 0x0000FFFF;
        let vAlign = data.alignment & 0xFFFF0000;

        if (hAlign == S7_HudMessage.AlignLeft)
            offsets.x = 0.0;
        else if (hAlign == S7_HudMessage.AlignHCenter)
            offsets.x = textSize.x / 2;
        else if (hAlign == S7_HudMessage.AlignRight)
            offsets.x = textSize.x;

        if (vAlign == S7_HudMessage.AlignTop)
            offsets.y = 0.0;
        else if (vAlign == S7_HudMessage.AlignVCenter)
            offsets.y = textSize.y / 2;
        else if (vAlign == S7_HudMessage.AlignBottom)
            offsets.y = textSize.y;

        if (screenSize != (0, 0)) {
            if (screenSize.x < 0 && screenSize.y < 0)
                Screen.DrawText (fnt, data.color, (Screen.GetWidth () * (pos.x / -screenSize.x)) - offsets.x, (Screen.GetHeight () * (pos.y / -screenSize.y)) - offsets.y, text, DTA_Alpha, alpha);
            else
                Screen.DrawText (fnt, data.color, pos.x - offsets.x, pos.y - offsets.y, text, DTA_VirtualWidthF, screenSize.x, DTA_VirtualHeightF, screenSize.y, DTA_KeepRatio, true, DTA_Alpha, alpha);
        } else {
            Screen.DrawText (fnt, data.color, (Screen.GetWidth () * pos.x) - offsets.x, (Screen.GetHeight () * pos.y) - offsets.y, text, DTA_Alpha, alpha);
        }
    }

    static play void Show (int targetPlayer, string text, int id, Vector2 pos, int holdTics, int flags = 0, int alignment = S7_HudMessage.AlignTopLeft,
        int color = Font.CR_UNTRANSLATED, int style = STYLE_Normal, string fnt = "SmallFont", double alpha = 1.0, Vector2 screenSize = (0, 0), int layer = BaseStatusbar.HUDMSGLayer_Default
    ) {
        let h = S7_HudMessageHandler (EventHandler.Find ("S7_HudMessageHandler"));

        if (!h)
            return;

        if (flags & MSG_Log && (targetPlayer < 0 || targetPlayer == consoleplayer))
            Console.PrintF (text); // This is the best I can do for now, unfortunately.

        let hudmsg = new ("S7_HudMessageData");
        hudmsg.targetPlayer = targetPlayer;
        hudmsg.text = text;
        hudmsg.pos = pos;
        hudmsg.tics = holdTics;

        hudmsg.flags = flags;
        hudmsg.alignment = alignment;
        hudmsg.color = color;
        hudmsg.style = style;
        hudmsg.fnt = fnt;
        hudmsg.alpha = alpha;
        hudmsg.screenSize = screenSize;

        let queued = new ("S7_QueuedHudMessage");
        queued.msgClass = 'S7_HudMessage';
        queued.msg = hudmsg;
        queued.id = id;
        queued.layer = layer;
        queued.ticAdded = level.time;

        h.queuedMsgs.Push (queued);
    }
}

class S7_HudMessageFadeData : S7_HudMessageData {
    double finalAlpha;
    int finalInTics, finalOutTics;
}

class S7_HudMessageFade : S7_HudMessage {
    protected int inTics, outTics;

    override bool Tick () {
        if (!(data is "S7_HudMessageFadeData")) // wtf?
            return false;

        let fadeData = S7_HudMessageFadeData (data);

        double finalAlpha   = fadeData.finalAlpha;
        double finalTics    = fadeData.tics;
        double finalInTics  = fadeData.finalInTics;
        double finalOutTics = fadeData.finalOutTics;

        if (inTics < finalInTics) {
            data.alpha = finalAlpha * (Clamp (double (inTics), 0, finalInTics) / finalInTics);
            inTics++;
        } else if (tics < finalTics) {
            data.alpha = finalAlpha;
            tics++;
        } else if (outTics < finalOutTics) {
            data.alpha = finalAlpha * (1 - (Clamp (double (outTics), 0, finalOutTics) / finalOutTics));
            outTics++;
        } else {
            StatusBar.DetachMessage (self);
            return true;
        }

        return false;
    }

    static play void Show (int targetPlayer, string text, int id, Vector2 pos, int holdTics, int inTics, int outTics, int flags = 0,
        int alignment = S7_HudMessage.AlignTopLeft, int color = Font.CR_UNTRANSLATED, int style = STYLE_Normal, string fnt = "SmallFont",
        double alpha = 1.0, Vector2 screenSize = (0, 0), int layer = BaseStatusbar.HUDMSGLayer_Default
    ) {
        let h = S7_HudMessageHandler (EventHandler.Find ("S7_HudMessageHandler"));

        if (!h)
            return;

        if (flags & MSG_Log && (targetPlayer < 0 || targetPlayer == consoleplayer))
            Console.PrintF (text); // This is the best I can do for now, unfortunately.

        let hudmsg = new ("S7_HudMessageFadeData");
        hudmsg.targetPlayer = targetPlayer;
        hudmsg.text = text;
        hudmsg.pos = pos;
        hudmsg.tics = holdTics;
        hudmsg.finalInTics  = inTics;
        hudmsg.finalOutTics = outTics;

        hudmsg.flags = flags;
        hudmsg.alignment = alignment;
        hudmsg.color = color;
        hudmsg.style = style;
        hudmsg.fnt = fnt;
        hudmsg.finalAlpha = alpha;
        hudmsg.screenSize = screenSize;

        let queued = new ("S7_QueuedHudMessage");
        queued.msgClass = 'S7_HudMessageFade';
        queued.msg = hudmsg;
        queued.id = id;
        queued.layer = layer;
        queued.ticAdded = level.time;

        h.queuedMsgs.Push (queued);
    }
}

class S7_QueuedHudMessage {
    class<S7_HudMessage> msgClass;
    S7_HudMessageData msg;
    int id;
    int layer;
    int ticAdded;
}

class S7_HudMessageHandler : EventHandler {
    Array<S7_QueuedHudMessage> queuedMsgs;

    override void PostUITick () {
        if (!StatusBar) // wtf?
            return;

        for (int i = 0; i < queuedMsgs.Size (); i++) {
            let queuedMsg = queuedMsgs [i];

            if (!queuedMsg || !queuedMsg.msg)
                continue;

            let msg = S7_HudMessage (new (queuedMsg.msgClass));
            msg.data = queuedMsg.msg;

            StatusBar.AttachMessage (msg, queuedMsg.id, queuedMsg.layer);
        }
    }

    override void WorldTick () {
        for (int i = queuedMsgs.Size () - 1; i >= 0; i--) {
            let queuedMsg = queuedMsgs [i];

            if (!queuedMsg || !queuedMsg.msg || level.time > queuedMsg.ticAdded)
                queuedMsgs.Delete (i, 1);
        }
    }
}
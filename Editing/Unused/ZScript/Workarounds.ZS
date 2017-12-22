/*
** This file is meant to be used for workarounds for broken or missing features.
*/

class S7_WorkaroundsHandler {
    virtual ui bool KeyDown (InputEvent e) { return false; }
    virtual ui bool KeyUp (InputEvent e) { return false; }
}

class S7_InputManager : StaticEventHandler {
    private ui Array<S7_WorkaroundsHandler> handlers;
    private ui bool m_KeyStates [InputEvent.Num_Keys];

    override bool InputProcess (InputEvent e) {
        switch (e.Type) {
        case InputEvent.Type_KeyDown:
            m_KeyStates [e.KeyScan] = true;
            for (int i = 0; i < handlers.Size (); i++) {
                if (handlers [i] && handlers [i].KeyDown (e))
                    return true;
            }
            break;
        case InputEvent.Type_KeyUp:
            m_KeyStates [e.KeyScan] = false;
            for (int i = 0; i < handlers.Size (); i++) {
                if (handlers [i] && handlers [i].KeyUp (e))
                    return true;
            }
            break;
        }

        return false;
    }

    static ui bool AddHandler (S7_WorkaroundsHandler handler) {
        let im = S7_InputManager (EventHandler.Find ("S7_InputManager")); // im will always be valid, so no need for useless checks.
        return (im.handlers.Push (handler) >= 0);
    }

    static ui bool RemoveHandler (S7_WorkaroundsHandler handler) {
        let im = S7_InputManager (EventHandler.Find ("S7_InputManager"));
        uint idx = im.handlers.Find (handler);

        if (idx < 0)
            return false;

        im.handlers.Delete (idx, 1);
        return true;
    }

    static ui bool IsKeyDown (int scancode) {
        let im = S7_InputManager (EventHandler.Find ("S7_InputManager"));
        return im.m_KeyStates [scancode];
    }

    static ui bool IsKeyUp (int scancode) {
        let im = S7_InputManager (EventHandler.Find ("S7_InputManager"));
        return !im.m_KeyStates [scancode];
    }
}
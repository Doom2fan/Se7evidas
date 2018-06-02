class S7_ZF_HoldButton : S7_ZF_Button {
    int tics;
    int ticsCountdown;

    void config(string text = "", int tics = 1, S7_ZF_Handler cmdHandler = NULL, string command = "",
                S7_ZF_BoxTextures inactive = NULL, S7_ZF_BoxTextures hover = NULL,
                S7_ZF_BoxTextures click = NULL, S7_ZF_BoxTextures disabled = NULL,
                Font fnt = NULL, double textScale = 1, int textColor = Font.CR_WHITE) {
        if (fnt == NULL) {
            self.fnt = smallfont;
        }
        else {
            self.fnt = fnt;
        }
        self.cmdHandler = cmdHandler;
        self.command = command;
        self.tics = tics;
        self.text = text;
        self.textScale = textScale;
        self.textures[B_INACTIVE] = inactive;
        self.textures[B_HOVER] = hover;
        self.textures[B_CLICK] = click;
        self.textures[B_DISABLED] = disabled;
        self.singleTex = false;
        self.textColor = textColor;
    }

    S7_ZF_HoldButton init(Vector2 pos, Vector2 size, string text = "", int tics = 1, S7_ZF_Handler cmdHandler = NULL, string command = "",
                   S7_ZF_BoxTextures inactive = NULL, S7_ZF_BoxTextures hover = NULL, S7_ZF_BoxTextures click = NULL,
                   S7_ZF_BoxTextures disabled = NULL, Font fnt = NULL, double textScale = 1, int textColor = Font.CR_WHITE) {
        self.config(text, tics, cmdHandler, command, inactive, hover, click, disabled, fnt, textScale, textColor);
        self.setBox(pos, size);

        return self;
    }

    override void ticker() {
        if (!isEnabled()) {
            ticsCountdown = 0;
            return;
        }

        if (buttonState == B_CLICK && ticsCountdown <= 0) {
            if (cmdHandler) {
                cmdHandler.buttonCommand(self, command);
            }
            ticsCountdown = tics;
        }
        else if (buttonState == B_CLICK && ticsCountdown > 0) {
            ticsCountdown--;
        }
        else if (buttonState != B_CLICK && ticsCountdown != 0) {
            ticsCountdown = 0;
        }
    }

    override void onUIEvent(UIEvent ev) {
        // if the player's clicked, and their mouse is in the right place, set the state accordingly
        if (ev.type == UIEvent.Type_LButtonDown) {
            if (isEnabled() && boxToScreen().pointCollides(mousePos)) {
                buttonState = B_CLICK;
            }
        }
        // if the player's releasing, check if their mouse is still in the correct range and trigger method if it was
        else if (ev.type == UIEvent.Type_LButtonUp) {
            if (!isEnabled()) {
                buttonState = B_DISABLED;
            }
            else if (boxToScreen().pointCollides(mousePos) && buttonState == B_CLICK) {
                buttonState = B_HOVER;
            }
            else {
                buttonState = B_INACTIVE;
            }
        }
        // if the player's mouse has moved, update the tracked position and do a quick hover check
        else if (ev.type == UIEvent.Type_MouseMove) {
            mousePos = (ev.mouseX, ev.mouseY);
            if (!isEnabled()) {
                buttonState = B_DISABLED;
            }
            else if (buttonState != B_CLICK) {
                if (boxToScreen().pointCollides(mousePos)) {
                    buttonState = B_HOVER;
                }
                else {
                    buttonState = B_INACTIVE;
                }
            }
            doHover(mousePos);
        }
    }
}
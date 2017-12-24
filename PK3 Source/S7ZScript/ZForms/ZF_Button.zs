class S7_ZF_Button : S7_ZF_Element {
	enum ButtonStates {
		B_INACTIVE,
		B_HOVER,
		B_CLICK,
		B_DISABLED
	}

	Font fnt;
	string text;
	int textColor;
	double textScale;

	S7_ZF_BoxTextures textures[4];
	string btnTextures [4];
	bool singleTex;

	int buttonState;

	Vector2 mousePos;

	void setTexture(string inactive, string hover, string click, string disabled) {
		self.btnTextures[B_INACTIVE] = inactive;
		self.btnTextures[B_HOVER] = hover;
		self.btnTextures[B_CLICK] = click;
		self.btnTextures[B_DISABLED] = disabled;
		self.singleTex = true;
	}

	void config(string text = "", S7_ZF_Handler cmdHandler = NULL, string command = "",
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
		self.text = text;
		self.textScale = textScale;
		self.textures[B_INACTIVE] = inactive;
		self.textures[B_HOVER] = hover;
		self.textures[B_CLICK] = click;
		self.textures[B_DISABLED] = disabled;
		self.singleTex = false;
		self.textColor = textColor;
	}

	S7_ZF_Button init(Vector2 pos, Vector2 size, string text = "", S7_ZF_Handler cmdHandler = NULL, string command = "",
	               S7_ZF_BoxTextures inactive = NULL, S7_ZF_BoxTextures hover = NULL, S7_ZF_BoxTextures click = NULL,
	               S7_ZF_BoxTextures disabled = NULL, Font fnt = NULL, double textScale = 1, int textColor = Font.CR_WHITE) {
		self.config(text, cmdHandler, command, inactive, hover, click, disabled, fnt, textScale, textColor);
		self.setBox(pos, size);

		return self;
	}

	override void ticker() {
	}

	override void drawer() {
		if (!isShown()) {
			return;
		}

		if (singleTex) {
			string texture = btnTextures[buttonState];
			drawImage((0, 0), texture, true);
		} else {
			S7_ZF_BoxTextures textures = textures[buttonState];
			drawBox((0, 0), box.size, textures);
		}

		// draw the text in the middle of the button
		Vector2 textSize = (fnt.stringWidth(text), fnt.getHeight()) * textScale;
		Vector2 textPos = (box.size - textSize) / 2;
		drawText(textPos, fnt, text, textColor, textScale);
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
				cmdHandler.buttonCommand(self, command);
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
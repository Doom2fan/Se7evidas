class S7_ZF_Button : S7_ZF_ButtonBase {
	protected int holdTicInterval;
	int getHoldTicInterval() { return self.holdTicInterval; }
	void setHoldTicInterval(int holdTicInterval) { self.holdTicInterval = holdTicInterval; }

	protected int currentHoldTicsRemaining;

	void config(
		string text = "", S7_ZF_Handler cmdHandler = NULL, string command = "",
		S7_ZF_BoxTextures inactive = NULL, S7_ZF_BoxTextures hover = NULL,
		S7_ZF_BoxTextures click = NULL, S7_ZF_BoxTextures disabled = NULL,
		Font fnt = NULL, double textScale = 1, int textColor = Font.CR_WHITE,
		int holdInterval = -1, AlignType alignment = AlignType_Center
	) {
		setFont(fnt);
		setHoldTicInterval(holdInterval);
		setText(text);
		setTextScale(textScale);
		setTextures(inactive, hover, click, disabled);
		setTextColor(textColor);
		setAlignment(alignment);
		setAlpha(1.0);

		self.cmdHandler = cmdHandler;
		self.command = command;
	}

	static S7_ZF_Button create(
		Vector2 pos, Vector2 size, string text = "", S7_ZF_Handler cmdHandler = NULL, string command = "",
		S7_ZF_BoxTextures inactive = NULL, S7_ZF_BoxTextures hover = NULL, S7_ZF_BoxTextures click = NULL,
		S7_ZF_BoxTextures disabled = NULL, Font fnt = NULL, double textScale = 1, int textColor = Font.CR_WHITE,
		int holdInterval = -1, AlignType alignment = AlignType_Center
	) {
		let ret = new('S7_ZF_Button');

		ret.config(text, cmdHandler, command, inactive, hover, click, disabled, fnt, textScale, textColor, holdInterval, alignment);
		ret.setBox(pos, size);

		return ret;
	}

	override void ticker() {
		if (!isEnabled()) {
			curButtonState = ButtonState_Disabled;
			currentHoldTicsRemaining = 0;
			return;
		}
		if (holdTicInterval == -1) {
			currentHoldTicsRemaining = 0;
			return;
		}

		if (curButtonState == ButtonState_Click && currentHoldTicsRemaining <= 0) {
			if (cmdHandler) {
				cmdHandler.buttonHeldCommand(self, command);
			}
			currentHoldTicsRemaining = holdTicInterval;
		}
		else if (curButtonState == ButtonState_Click && currentHoldTicsRemaining > 0) {
			currentHoldTicsRemaining--;
		}
		else if (curButtonState != ButtonState_Click && currentHoldTicsRemaining != 0) {
			currentHoldTicsRemaining = 0;
		}
	}

	override bool handleMousePosition(bool mouseBlock, Vector2 mousePos) {
		S7_ZF_AABB screenBox; boxToScreen(screenBox);
		if (!isEnabled()) {
			curButtonState = ButtonState_Disabled;
		}
		else if (curButtonState != ButtonState_Click) {
			if (!mouseBlock && !getHoverBlock() && screenBox.pointCollides(mousePos)) {
				curButtonState = ButtonState_Hover;
			}
			else {
				curButtonState = ButtonState_Inactive;
			}
		}
		return false;
	}

	override bool onNavEvent(S7_ZF_NavEventType type, bool fromController) {
		if (isEnabled() && isFocused() && type == S7_ZF_NavEventType_Confirm && holdTicInterval == -1) {
			if (cmdHandler != NULL) cmdHandler.buttonClickCommand(self, command);
			return true;
		}
		return false;
	}

	override bool onUIEvent(S7_ZF_UiEvent ev) {
		// if the player's clicked, and their mouse is in the right place, set the state accordingly
		if (ev.type == UIEvent.Type_LButtonDown) {
			let mousePos = getGlobalStore().mousePos;
			S7_ZF_AABB screenBox; boxToScreen(screenBox);
			if (!mouseBlock && isEnabled() && screenBox.pointCollides(mousePos)) {
				if (cmdHandler && holdTicInterval >= 0) {
					cmdHandler.buttonClickCommand(self, command);
					currentHoldTicsRemaining = holdTicInterval;
				}
				curButtonState = ButtonState_Click;
				setHoverBlock(self);
			}
		}
		// if the player's releasing, check if their mouse is still in the correct range and trigger method if it was
		else if (ev.type == UIEvent.Type_LButtonUp) {
			let mousePos = getGlobalStore().mousePos;
			S7_ZF_AABB screenBox; boxToScreen(screenBox);
			if (!isEnabled()) {
				curButtonState = ButtonState_Disabled;
			}
			else if (screenBox.pointCollides(mousePos) && curButtonState == ButtonState_Click) {
				if (cmdHandler && holdTicInterval == -1) {
					cmdHandler.buttonClickCommand(self, command);
				}

				curButtonState = ButtonState_Hover;
			}
			else {
				curButtonState = ButtonState_Inactive;
			}
			setHoverBlock(NULL);
		}
		return false;
	}
}

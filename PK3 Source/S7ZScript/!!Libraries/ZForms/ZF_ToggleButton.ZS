class S7_ZF_ToggleButton : S7_ZF_ButtonBase {
	protected bool on;

	protected bool hover;
	protected bool click;

	void config(
		string text = "",
		S7_ZF_BoxTextures inactive = NULL, S7_ZF_BoxTextures hover = NULL,
		S7_ZF_BoxTextures click = NULL, S7_ZF_BoxTextures disabled = NULL,
		Font fnt = NULL, double textScale = 1, int textColor = Font.CR_WHITE,
		AlignType alignment = AlignType_Center, S7_ZF_Handler cmdHandler = NULL, string command = ""
	) {
		setFont(fnt);
		setText(text);
		setTextScale(textScale);
		setTextures(inactive, hover, click, disabled);
		setTextColor(textColor);
		setAlignment(alignment);
		setAlpha(1.0);

		self.cmdHandler = cmdHandler;
		self.command = command;
	}

	static S7_ZF_ToggleButton create(
		Vector2 pos, Vector2 size, string text = "",
		S7_ZF_BoxTextures inactive = NULL, S7_ZF_BoxTextures hover = NULL, S7_ZF_BoxTextures click = NULL,
		S7_ZF_BoxTextures disabled = NULL, Font fnt = NULL, double textScale = 1, int textColor = Font.CR_WHITE,
		AlignType alignment = AlignType_Center, S7_ZF_Handler cmdHandler = NULL, string command = ""
	) {
		let ret = new('S7_ZF_ToggleButton');

		ret.config(text, inactive, hover, click, disabled, fnt, textScale, textColor, alignment, cmdHandler, command);
		ret.setBox(pos, size);

		return ret;
	}

	override bool handleMousePosition(bool mouseBlock, Vector2 mousePos) {
		if (isEnabled()) {
			S7_ZF_AABB screenBox; boxToScreen(screenBox);
			if (!mouseBlock && screenBox.pointCollides(mousePos)) {
				hover = true;
			}
			else {
				hover = false;
			}
		}
		return false;
	}

	override void drawer() {
		if (!isEnabled()) { curButtonState = ButtonState_Disabled; }
		else if ((!getHoverBlock() && hover) || click) { curButtonState = ButtonState_Hover; }
		else if (on) { curButtonState = ButtonState_Click; }
		else { curButtonState = ButtonState_Inactive; }
		Super.drawer();
	}

	override bool onNavEvent(S7_ZF_NavEventType type, bool fromController) {
		if (isEnabled() && isFocused() && type == S7_ZF_NavEventType_Confirm) {
			on = !on;
			if (cmdHandler != NULL) {
				cmdHandler.toggleButtonChanged(self, command, on);
			}
			return true;
		}
		return false;
	}

	override void activate() {
		on = !on;
		if (cmdHandler != NULL) {
			cmdHandler.toggleButtonChanged(self, command, on);
		}
	}

	override bool onUIEvent(S7_ZF_UiEvent ev) {
		// if the player's clicked, and their mouse is in the right place, set the state accordingly
		if (ev.type == UIEvent.Type_LButtonDown) {
			let mousePos = getGlobalStore().mousePos;
			S7_ZF_AABB screenBox; boxToScreen(screenBox);
			if (!mouseBlock && isEnabled() && screenBox.pointCollides(mousePos)) {
				click = true;
				setHoverBlock(self);
			}
		}
		// if the player's releasing, check if their mouse is still in the correct range and trigger method if it was
		else if (ev.type == UIEvent.Type_LButtonUp) {
			if (isEnabled()) {
				let mousePos = getGlobalStore().mousePos;
				S7_ZF_AABB screenBox; boxToScreen(screenBox);
				if (screenBox.pointCollides(mousePos) && click) {
					on = !on;
					if (cmdHandler != NULL) {
						cmdHandler.toggleButtonChanged(self, command, on);
					}
				}
				click = false;
				setHoverBlock(NULL);
			}
		}
		return false;
	}
}

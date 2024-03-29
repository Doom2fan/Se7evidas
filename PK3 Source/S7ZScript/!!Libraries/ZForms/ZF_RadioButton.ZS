class S7_ZF_RadioController {
	int curVal;
}

class S7_ZF_RadioButton : S7_ZF_ButtonBase {
	protected S7_ZF_RadioController variable;
	S7_ZF_RadioController getVariable() { return self.variable; }
	void setVariable(S7_ZF_RadioController variable) { self.variable = variable; }

	protected int value;
	int getValue() { return self.value; }
	void setValue(int value) { self.value = value; }

	protected bool click;
	protected bool hover;

	void config(
		S7_ZF_RadioController variable, int value,
		S7_ZF_BoxTextures inactive = NULL, S7_ZF_BoxTextures hover = NULL,
		S7_ZF_BoxTextures click = NULL, S7_ZF_BoxTextures disabled = NULL,
		string text = "", Font fnt = NULL, double textScale = 1, int textColor = Font.CR_WHITE,
		AlignType alignment = AlignType_Center, S7_ZF_Handler cmdHandler = NULL, string command = ""
	) {
		setFont(fnt);
		setText(text);
		setTextScale(textScale);
		setTextures(inactive, hover, click, disabled);
		setTextColor(textColor);
		setAlignment(alignment);
		setVariable(variable);
		setValue(value);
		setAlpha(1.0);

		self.cmdHandler = cmdHandler;
		self.command = command;
	}

	static S7_ZF_RadioButton create(
		Vector2 pos, Vector2 size,
		S7_ZF_RadioController variable, int value,
		S7_ZF_BoxTextures inactive = NULL, S7_ZF_BoxTextures hover = NULL,
		S7_ZF_BoxTextures click = NULL, S7_ZF_BoxTextures disabled = NULL,
		string text = "", Font fnt = NULL, double textScale = 1, int textColor = Font.CR_WHITE,
		AlignType alignment = AlignType_Center, S7_ZF_Handler cmdHandler = NULL, string command = ""
	) {
		let ret = new('S7_ZF_RadioButton');

		ret.config(variable, value, inactive, hover, click, disabled, text, fnt, textScale, textColor, alignment, cmdHandler, command);
		ret.setBox(pos, size);

		return ret;
	}

	override bool onNavEvent(S7_ZF_NavEventType type, bool fromController) {
		if (isEnabled() && isFocused() && type == S7_ZF_NavEventType_Confirm) {
			variable.curVal = value;
			if (cmdHandler != NULL) {
				cmdHandler.radioButtonChanged(self, command, variable);
			}
			return true;
		}
		return false;
	}

	override void activate() {
		variable.curVal = value;
		if (cmdHandler != NULL) {
			cmdHandler.radioButtonChanged(self, command, variable);
		}
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
		else if (variable.curVal == value) { curButtonState = ButtonState_Click; }
		else if ((!getHoverBlock() && hover) || click) { curButtonState = ButtonState_Hover; }
		else { curButtonState = ButtonState_Inactive; }
		Super.drawer();
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
					variable.curVal = value;
					if (cmdHandler != NULL) {
						cmdHandler.radioButtonChanged(self, command, variable);
					}
				}
				click = false;
				setHoverBlock(NULL);
			}
		}
		// if the player's mouse has moved, update the tracked position and do a quick hover check
		return false;
	}
}

class S7_ZF_ButtonBase : S7_ZF_Element {
	enum ButtonState {
		ButtonState_Inactive,
		ButtonState_Hover,
		ButtonState_Click,
		ButtonState_Disabled
	}

	protected S7_ZF_BoxTextures textures[4];

	S7_ZF_BoxTextures getInactiveTexture() { return textures[ButtonState_Inactive]; }
	void setInactiveTexture(S7_ZF_BoxTextures tex) { textures[ButtonState_Inactive] = tex; }

	S7_ZF_BoxTextures getHoverTexture() { return textures[ButtonState_Hover]; }
	void setHoverTexture(S7_ZF_BoxTextures tex) { textures[ButtonState_Hover] = tex; }

	S7_ZF_BoxTextures getClickTexture() { return textures[ButtonState_Click]; }
	void setClickTexture(S7_ZF_BoxTextures tex) { textures[ButtonState_Click] = tex; }

	S7_ZF_BoxTextures getDisabledTexture() { return textures[ButtonState_Disabled]; }
	void setDisabledTexture(S7_ZF_BoxTextures tex) { textures[ButtonState_Disabled] = tex; }

	void setTextures(S7_ZF_BoxTextures inactive, S7_ZF_BoxTextures hover, S7_ZF_BoxTextures click, S7_ZF_BoxTextures disabled) {
		self.textures[ButtonState_Inactive] = inactive;
		self.textures[ButtonState_Hover] = hover;
		self.textures[ButtonState_Click] = click;
		self.textures[ButtonState_Disabled] = disabled;
	}

	protected S7_ZF_BoxDrawer drawers[4];

	protected Font fnt;
	Font getFont() { return self.fnt; }
	void setFont(Font fnt) {
		if (fnt == NULL) {
			self.fnt = smallfont;
		}
		else {
			self.fnt = fnt;
		}
	}

	protected string text;
	string getText() { return self.text; }
	void setText(string text) { self.text = text; }

	protected int textColor;
	int getTextColor() { return self.textColor; }
	void setTextColor(int textColor) { self.textColor = textColor; }

	protected double textScale;
	double getTextScale() { return self.textScale; }
	void setTextScale(double textScale) { self.textScale = textScale; }

	protected AlignType alignment;
	AlignType getAlignment() { return self.alignment; }
	void setAlignment(AlignType alignment) { self.alignment = alignment; }

	protected ButtonState curButtonState;
	ButtonState getCurButtonState() { return self.curButtonState; }

	override void drawer() {
		if (hidden) { return; }

		S7_ZF_AABB beforeClip, clipRect;
		screenClip(beforeClip, clipRect);
		Screen.setClipRect(int(clipRect.pos.x), int(clipRect.pos.y), int(clipRect.size.x), int(clipRect.size.y));

		S7_ZF_BoxTextures textures = textures[curButtonState];
		if (textures != NULL) {
			drawers[curButtonState].draw(self, (0, 0), box.size, textures, true);
		}

		Vector2 textPos = getAlignedDrawPos(box.size, (fnt.stringWidth(text), fnt.getHeight()) * textScale, alignment);
		drawText(textPos, fnt, text, textColor, textScale);

		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}
}

class S7_ZF_Label : S7_ZF_Element {
	protected Font fnt;
	Font getFont() { return fnt; }
	void setFont(Font fnt) {
		if (fnt == NULL) {
			self.fnt = smallfont;
		}
		else {
			self.fnt = fnt;
		}
		recalculateLines();
	}

	protected string text;
	string getText() { return self.text; }
	void setText(string text) { self.text = text; recalculateLines(); }

	protected double textScale;
	double getTextScale() { return self.textScale; }
	void setTextScale(double textScale) { self.textScale = textScale; recalculateLines(); }

	protected AlignType alignment;
	AlignType getAlignment() { return self.alignment; }
	void setAlignment(AlignType alignment) { self.alignment = alignment; }

	protected int textColor;
	int getTextColor() { return self.textColor; }
	void setTextColor(int textColor) { self.textColor = textColor; }

	protected bool wrap;
	bool getWrap() { return self.wrap; }
	void setWrap(bool wrap) { self.wrap = wrap; recalculateLines(); }

	protected bool autoSize;
	bool getAutoSize() { return self.autoSize; }
	void setAutoSize(bool autoSize) { self.autoSize = autoSize; }

	protected double lineSpacing;
	double getLineSpacing() { return self.lineSpacing; }
	void setLineSpacing(double lineSpacing) { self.lineSpacing = lineSpacing; }

	protected S7_ZF_Element forElement;
	S7_ZF_Element getForElement() { return self.forElement; }
	void setForElement(S7_ZF_Element forElement) { self.forElement = forElement; }

	protected bool clicking;

	protected BrokenLines lines;
	protected bool calculate;
	void recalculateLines() {
		if (calculate && wrap) {
			lines = fnt.breakLines(text, int(box.size.x / textScale));
		}
	}

	override void onBoxChanged() {
		recalculateLines();
	}

	void config(
		string text = "", Font fnt = NULL, AlignType alignment = AlignType_TopLeft, bool wrap = true,
		bool autoSize = false, double textScale = 1, int textColor = Font.CR_WHITE, double lineSpacing = 0,
		S7_ZF_Element forElement = NULL
	) {
		calculate = false;
		setFont(fnt);
		setText(text);
		setAlignment(alignment);
		setWrap(wrap);
		setAutoSize(autoSize);
		setTextScale(textScale);
		setTextColor(textColor);
		setAlpha(1.0);
		setLineSpacing(lineSpacing);
		setForElement(forElement);
		calculate = true;

		recalculateLines();
	}

	static S7_ZF_Label create(
		Vector2 pos, Vector2 size, string text = "", Font fnt = NULL, AlignType alignment = AlignType_TopLeft,
		bool wrap = true, bool autoSize = false, double textScale = 1, int textColor = Font.CR_WHITE,
		double lineSpacing = 0, S7_ZF_Element forElement = NULL
	) {
		let ret = new('S7_ZF_Label');

		ret.setBox(pos, size);
		ret.config(text, fnt, alignment, wrap, autoSize, textScale, textColor, lineSpacing, forElement);

		return ret;
	}

	override void ticker() {
		if (autoSize) {
			if (wrap) {
				int fntHeight = fnt.getHeight();
				box.size.y = fntHeight * textScale * lines.count();
			}
			else {
				Array<string> split;
				text.split(split, "\n");
				int fntHeight = fnt.getHeight();
				box.size.y = fntHeight * split.size() * textScale;
				box.size.x = fnt.stringWidth(text) * textScale;
			}
		}
	}

	override void drawer() {
		S7_ZF_AABB beforeClip, clipRect;
		screenClip(beforeClip, clipRect);
		Screen.setClipRect(int(clipRect.pos.x), int(clipRect.pos.y), int(clipRect.size.x), int(clipRect.size.y));

		if (!wrap) {
			Array<string> split;
			text.split(split, "\n");
			Vector2 pos = getAlignedDrawPos(box.size, (fnt.stringWidth(text), split.size() * fnt.getHeight()) * textScale, alignment);
			drawText(pos, fnt, text, textColor, textScale);
		}
		else {
			int fntHeight = fnt.getHeight();
			float lineHeight = fntHeight + lineSpacing;

			Vector2 pos = getAlignedDrawPos(
				box.size,
				(0, (lineHeight * lines.count() - lineSpacing) * textScale),
				alignment
			);

			for (int i = 0; i < lines.count(); i++) {
				string line = lines.stringAt(i);
				Vector2 linePos = getAlignedDrawPos(box.size, (fnt.stringWidth(line) * textScale, 0), alignment);
				drawText((linePos.x, pos.y + (lineHeight * i * textScale)), fnt, line, textColor, textScale);
			}
		}

		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}

	override bool onNavEvent(S7_ZF_NavEventType type, bool fromController) {
		if (forElement == NULL) return false;

		if (isFocused() && type == S7_ZF_NavEventType_Confirm) {
			if (forElement.isEnabled()) {
				forElement.activate();
				return true;
			}
		}
		return false;
	}

	override bool onUIEvent(S7_ZF_UiEvent ev) {
		if (forElement == NULL) return false;
		if (ev.type == UIEvent.Type_LButtonDown) {
			S7_ZF_AABB screenBox; boxToScreen(screenBox);
			let mousePos = getGlobalStore().mousePos;
			if (!mouseBlock && isEnabled() && screenBox.pointCollides(mousePos)) {
				clicking = true;
				setHoverBlock(self);
			}
		}
		else if (ev.type == UIEvent.Type_LButtonUp) {
			S7_ZF_AABB screenBox; boxToScreen(screenBox);
			let mousePos = getGlobalStore().mousePos;
			if (isEnabled() && screenBox.pointCollides(mousePos) && clicking) {
				if (forElement.isEnabled()) forElement.activate();
				clicking = false;
				setHoverBlock(NULL);
			}
		}
		return false;
	}
}

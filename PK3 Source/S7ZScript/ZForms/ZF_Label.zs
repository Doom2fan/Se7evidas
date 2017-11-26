class S7_ZF_Label : S7_ZF_Element {
	Font fnt;
	string text;
	double textScale;
	int textColor;
	bool wrap;
	bool autoSize;
	
	void config(string text = "", Font fnt = NULL, bool wrap = true, bool autoSize = false,
	            double textScale = 1, int textColor = Font.CR_WHITE) {
		if (fnt == NULL) {
			self.fnt = smallfont;
		}
		else {
			self.fnt = fnt;
		}
		self.text = text;
		self.wrap = wrap;
		self.autoSize = autoSize;
		self.textScale = textScale;
		self.textColor = textColor;
	}
	
	S7_ZF_Label init(Vector2 pos, Vector2 size, string text = "", Font fnt = NULL, bool wrap = true,
	              bool autoSize = false, double textScale = 1, int textColor = Font.CR_WHITE) {
		self.config(text, fnt, wrap, autoSize, textScale, textColor);
		self.setBox(pos, size);
		
		return self;
	}
	
	override void ticker() {
		if (autoSize) {
			if (wrap) {
				int fntHeight = fnt.getHeight();
				BrokenLines textLines = fnt.breakLines(text, int(box.size.x / textScale));
				box.size.y = fntHeight * textScale * textLines.count();
			}
			else {
				int fntHeight = fnt.getHeight();
				box.size.y = fntHeight * textScale;
				box.size.x = fnt.stringWidth(text) * textScale;
			}
		}
	}
	
	override void drawer() {
		S7_ZF_AABB beforeClip = getClipAABB();
		S7_ZF_AABB clipTest = boxToScreen();
		S7_ZF_AABB clipRect = clipTest.rectOfIntersection(beforeClip);
		S7_ZF_AABB screenClip = new("S7_ZF_AABB");
		screenClip.size = screenSize();
		clipRect = clipRect.rectOfIntersection(screenClip);
		Screen.setClipRect(int(clipRect.pos.x), int(clipRect.pos.y), int(clipRect.size.x), int(clipRect.size.y));
		
		if (!wrap) {
			drawText((0, 0), fnt, text, textColor, textScale);
		}
		else {
			BrokenLines printLines = fnt.breakLines(text, int(box.size.x / textScale));
			int fntHeight = fnt.getHeight();
			for (int i = 0; i < printLines.count(); i++) {
				drawText((0, fntHeight * i * textScale), fnt, printLines.stringAt(i), textColor, textScale);
			}
		}
		
		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}
}
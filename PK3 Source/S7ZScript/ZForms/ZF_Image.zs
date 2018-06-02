class S7_ZF_Image : S7_ZF_Element {
	enum AlignType {
		AlignType_Left    = 1,
		AlignType_HCenter = 2,
		AlignType_Right   = 3,

		AlignType_Top     = 1 << 4,
		AlignType_VCenter = 2 << 4,
		AlignType_Bottom  = 3 << 4,

		AlignType_TopLeft   = AlignType_Top | AlignType_Left,
		AlignType_TopCenter = AlignType_Top | AlignType_HCenter,
		AlignType_TopRight  = AlignType_Top | AlignType_Right,

		AlignType_CenterLeft  = AlignType_VCenter | AlignType_Left,
		AlignType_Center      = AlignType_VCenter | AlignType_HCenter,
		AlignType_CenterRight = AlignType_VCenter | AlignType_Right,

		AlignType_BottomLeft   = AlignType_Bottom | AlignType_Left,
		AlignType_BottomCenter = AlignType_Bottom | AlignType_HCenter,
		AlignType_BottomRight  = AlignType_Bottom | AlignType_Right,
	}

	string image;
	AlignType alignment;
	Vector2 imageScale;
	bool noOffsets;

	void config(string image = "", AlignType alignment = AlignType_TopLeft, Vector2 imageScale = (1, 1), bool noOffsets = true) {
		self.image = image;
		self.alignment = alignment;
		self.imageScale = imageScale;
		self.noOffsets = noOffsets;
	}

	S7_ZF_Image init(Vector2 pos, Vector2 size, string image = "", AlignType alignment = AlignType_TopLeft, Vector2 imageScale = (1, 1), bool noOffsets = true) {
		self.config(image, alignment, imageScale, noOffsets);
		self.setBox(pos, size);

		return self;
	}

	override void drawer() {
		if (!isShown()) {
			return;
		}

		TextureID tex = TexMan.checkForTexture(image, TexMan.Type_Any);

		if (!tex) {
			return;
		}

		Vector2 imageSize = TexMan.getScaledSize(tex);
		Vector2 pos;

		imageSize.x *= imageScale.x;
		imageSize.y *= imageScale.y;

		int horzAlign = alignment &  15;
		int vertAlign = alignment & (15 << 4);

		if (horzAlign == AlignType_Left) {
			pos.x = 0.0;
		}
		else if (horzAlign == AlignType_HCenter) {
			pos.x = (box.size.x - imageSize.x) / 2;
		}
		else if (horzAlign == AlignType_Right) {
			pos.x = box.size.x - imageSize.x;
		}

		if (vertAlign == AlignType_Top) {
			pos.y = 0.0;
		}
		else if (vertAlign == AlignType_VCenter) {
			pos.y = (box.size.y - imageSize.y) / 2;
		}
		else if (vertAlign == AlignType_Bottom) {
			pos.y = box.size.y - imageSize.y;
		}

		drawImage(pos, image, true, imageScale, clipRect: boxToScreen(), offsets: !noOffsets);
	}

	override void onUIEvent(UIEvent ev) {
		if (ev.type == UIEvent.Type_MouseMove) {
			doHover((ev.mouseX, ev.mouseY));
		}
	}
}
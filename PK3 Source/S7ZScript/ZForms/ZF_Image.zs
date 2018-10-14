class S7_ZF_Image : S7_ZF_Element {
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

		imageSize.x *= imageScale.x;
		imageSize.y *= imageScale.y;

		Vector2 pos = getAlignedDrawPos(box.size, imageSize, alignment);

		drawImage(pos, image, true, imageScale, clipRect: boxToScreen(), offsets: !noOffsets);
	}

	override void onUIEvent(UIEvent ev) {
		if (ev.type == UIEvent.Type_MouseMove) {
			doHover((ev.mouseX, ev.mouseY));
		}
	}
}
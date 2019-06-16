class S7_ZF_Image : S7_ZF_Element {
	string image;
	AlignType alignment;
	Vector2 imageScale;
	bool tiled;

	void config(string image = "", AlignType alignment = AlignType_TopLeft, Vector2 imageScale = (1, 1), bool tiled = false) {
		self.image = image;
		self.alignment = alignment;
		self.imageScale = imageScale;
		self.tiled = tiled;
		self.alpha = 1;
	}

	S7_ZF_Image init(Vector2 pos, Vector2 size, string image = "", AlignType alignment = AlignType_TopLeft, Vector2 imageScale = (1, 1), bool tiled = false) {
		self.config(image, alignment, imageScale, tiled);
		self.setBox(pos, size);

		return self;
	}

	override void drawer() {
		TextureID tex = TexMan.checkForTexture(image, TexMan.Type_Any);

		if (!tex) {
			return;
		}

		Vector2 imageSize = TexMan.getScaledSize(tex);

		imageSize.x *= imageScale.x;
		imageSize.y *= imageScale.y;

		Vector2 pos = getAlignedDrawPos(box.size, imageSize, alignment);

		if (tiled) {
			drawTiledImage(pos, box.size, image, true, imageScale);
		}
		else {
			drawImage(pos, image, true, imageScale, clipRect: boxToScreen());
		}
	}

	override void onUIEvent(S7_ZF_UiEvent ev) {
		if (ev.type == UIEvent.Type_MouseMove) {
			doHover((ev.mouseX, ev.mouseY));
		}
	}
}
class S7_ZF_Image : S7_ZF_Element {
	protected string image;
	string getImage() { return self.image; }
	void setImage(string image) { self.image = image; }

	protected AlignType alignment;
	AlignType getAlignment() { return self.alignment; }
	void setAlignment(AlignType alignment) { self.alignment = alignment; }

	protected Vector2 imageScale;
	Vector2 getImageScale() { return self.imageScale; }
	void setImageScale(Vector2 imageScale) { self.imageScale = imageScale; }

	protected bool tiled;
	bool getTiled() { return self.tiled; }
	void setTiled(bool tiled) { self.tiled = tiled; }

	void config(string image = "", AlignType alignment = AlignType_TopLeft, Vector2 imageScale = (1, 1), bool tiled = false) {
		self.image = image;
		self.alignment = alignment;
		self.imageScale = imageScale;
		self.tiled = tiled;
		self.alpha = 1;
	}

	static S7_ZF_Image create(Vector2 pos, Vector2 size, string image = "", AlignType alignment = AlignType_TopLeft, Vector2 imageScale = (1, 1), bool tiled = false) {
		let ret = new('S7_ZF_Image');

		ret.config(image, alignment, imageScale, tiled);
		ret.setBox(pos, size);

		return ret;
	}

	override void drawer() {
		S7_ZF_AABB beforeClip, clipRect;
		screenClip(beforeClip, clipRect);
		Screen.setClipRect(int(clipRect.pos.x), int(clipRect.pos.y), int(clipRect.size.x), int(clipRect.size.y));

		TextureID tex = TexMan.checkForTexture(image, TexMan.Type_Any);

		if (!tex) {
			return;
		}

		Vector2 imageSize = TexMan.getScaledSize(tex);

		imageSize.x *= imageScale.x;
		imageSize.y *= imageScale.y;

		if (tiled) {
			drawTiledImage((0, 0), box.size, image, true, imageScale);
		}
		else {
			Vector2 pos = getAlignedDrawPos(box.size, imageSize, alignment);
			drawImage(pos, image, true, imageScale);
		}

		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}
}

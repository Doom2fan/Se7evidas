class S7_ZF_BoxImage : S7_ZF_Element {
	protected S7_ZF_BoxTextures boxTex;
	S7_ZF_BoxTextures getBoxTex() { return self.boxTex; }
	void setBoxTex(S7_ZF_BoxTextures boxTex) { self.boxTex = boxTex; }
	protected S7_ZF_BoxDrawer boxDrawer;

	protected Vector2 boxScale;
	Vector2 getBoxScale() { return self.boxScale; }
	void setBoxScale(Vector2 boxScale) { self.boxScale = boxScale; }

	void config(S7_ZF_BoxTextures textures = NULL, Vector2 scale = (1, 1)) {
		setBoxTex(textures);
		setBoxScale(scale);
		setAlpha(1.0);
	}

	static S7_ZF_BoxImage create(Vector2 pos, Vector2 size, S7_ZF_BoxTextures textures = NULL, Vector2 scale = (1, 1)) {
		let ret = new('S7_ZF_BoxImage');

		ret.config(textures, scale);
		ret.setBox(pos, size);

		return ret;
	}

	override void drawer() {
		if (hidden) { return; }

		S7_ZF_AABB beforeClip, clipRect;
		screenClip(beforeClip, clipRect);
		Screen.setClipRect(int(clipRect.pos.x), int(clipRect.pos.y), int(clipRect.size.x), int(clipRect.size.y));

		boxDrawer.draw(self, (0, 0), box.size, boxTex, true, boxScale);

		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}
}

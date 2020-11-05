class S7_ZF_BoxImage : S7_ZF_Element {
	S7_ZF_BoxTextures boxTex;
	Vector2 boxScale;

	void config(S7_ZF_BoxTextures textures = NULL, Vector2 scale = (1, 1)) {
		self.boxTex = textures;
		self.boxScale = scale;

		self.alpha = 1;
	}

	S7_ZF_BoxImage init(Vector2 pos, Vector2 size, S7_ZF_BoxTextures textures = NULL, Vector2 scale = (1, 1)) {
		self.config(textures, scale);
		self.setBox(pos, size);

		return self;
	}

	override void drawer() {
		drawBox((0, 0), box.size, boxTex, true, boxScale);
	}

	override void onUIEvent (S7_ZF_UiEvent ev) {
		if (ev.type == UIEvent.Type_MouseMove) {
			doHover((ev.mouseX, ev.mouseY));
		}
	}
}
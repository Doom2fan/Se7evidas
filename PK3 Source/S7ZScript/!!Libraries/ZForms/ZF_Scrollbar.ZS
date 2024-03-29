class S7_ZF_Scrollbar : S7_ZF_Element {
	// these are intentionally not protected
	// since the only intended purpose of this element
	// is to be used in another element, which should deal with
	// encapsulation itself
	S7_ZF_BoxTextures background;
	S7_ZF_BoxDrawer bgDrawer;
	S7_ZF_BoxTextures textures[3];
	S7_ZF_BoxDrawer barDrawers[3];

	enum BarState {
		BarState_Normal,
		BarState_Hover,
		BarState_Click
	}

	double position;
	double size;

	protected BarState curBarState;

	protected double originalPos;
	protected Vector2 originalMousePos;
	protected bool clicking;

	void config(
		S7_ZF_BoxTextures normal, S7_ZF_BoxTextures hover = NULL,
		S7_ZF_BoxTextures click = NULL, S7_ZF_BoxTextures background = NULL
	) {
		self.background = background;
		self.textures[BarState_Normal] = normal;
		self.textures[BarState_Hover] = (hover != NULL) ? hover : normal;
		self.textures[BarState_Click] = (click != NULL) ? click : normal;
		self.alpha = 1.0;
	}

	static S7_ZF_Scrollbar create(
		Vector2 pos, Vector2 size,
		S7_ZF_BoxTextures normal, S7_ZF_BoxTextures hover = NULL,
		S7_ZF_BoxTextures click = NULL, S7_ZF_BoxTextures background = NULL
	) {
		let ret = new('S7_ZF_Scrollbar');

		ret.config(normal, hover, click, background);
		ret.setBox(pos, size);

		return ret;
	}

	void barBox(S7_ZF_AABB ret) {
		ret.pos = (0, box.size.y * position);
		ret.size = (box.size.x, box.size.y * size);
	}

	override bool handleMousePosition(bool mouseBlock, Vector2 mousePos) {
		if (curBarState == BarState_Click) {
			if (size < 1.0) {
				let delta = mousePos - relToScreen((0, 0)) - originalMousePos;
				delta /= getScale();
				position = originalPos + delta.y / box.size.y;
				clampBarPos();
			}
		}
		else {
			S7_ZF_AABB box; barBox(box);
			S7_ZF_AABB screenBox; aabbToScreen(screenBox, box);
			if (!mouseBlock && isEnabled() && !getHoverBlock() && screenBox.pointCollides(mousePos)) {
				curBarState = BarState_Hover;
			}
			else {
				curBarState = BarState_Normal;
			}
		}

		return false;
	}

	override void drawer() {
		S7_ZF_AABB beforeClip, clipRect;
		screenClip(beforeClip, clipRect);
		Screen.setClipRect(int(clipRect.pos.x), int(clipRect.pos.y), int(clipRect.size.x), int(clipRect.size.y));

		if (background) {
			bgDrawer.draw(self, (0, 0), box.size, background, true);
		}

		if (size < 1.0) {
			S7_ZF_AABB box; barBox(box);
			barDrawers[curBarState].draw(self, box.pos, box.size, textures[curBarState], true);
		}

		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}

	void clampBarPos() {
		position = clamp(position, 0.0, 1.0 - size);
	}

	override bool onUIEvent(S7_ZF_UiEvent ev) {
		let mousePos = getGlobalStore().mousePos;
		if (ev.type == UIEvent.Type_LButtonDown) {
			S7_ZF_AABB box; barBox(box);
			S7_ZF_AABB screenBox; aabbToScreen(screenBox, box);
			if (!mouseBlock && isEnabled() && screenBox.pointCollides(mousePos)) {
				curBarState = BarState_Click;
				originalPos = position;
				originalMousePos = mousePos - relToScreen((0, 0));
				setHoverBlock(self);
			}
		}
		else if (ev.type == UIEvent.Type_LButtonUp) {
			S7_ZF_AABB box; barBox(box);
			S7_ZF_AABB screenBox; aabbToScreen(screenBox, box);
			if (!mouseBlock && screenBox.pointCollides(mousePos) && curBarState == BarState_Click) {
				curBarState = BarState_Hover;
			}
			else {
				curBarState = BarState_Normal;
			}
			setHoverBlock(NULL);
		}
		return false;
	}
}

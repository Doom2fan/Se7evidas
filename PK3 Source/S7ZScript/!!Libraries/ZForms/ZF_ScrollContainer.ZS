class S7_ZF_ScrollContainer : S7_ZF_ElementContainer {
	protected S7_ZF_Element scrollArea;
	S7_ZF_Element getScrollArea() { return scrollArea; }
	protected S7_ZF_Scrollbar bar;

	protected double scrollWidth;
	protected double scrollAreaHeight;
	protected double scrollNotchJump;
	protected double contentBarGap;

	void config(
		double scrollWidth, double scrollAreaHeight, double scrollNotchJump,
		S7_ZF_BoxTextures scrollBarNormal, S7_ZF_BoxTextures scrollBarHover = NULL,
		S7_ZF_BoxTextures scrollBarClick = NULL, S7_ZF_BoxTextures scrollBg = NULL,
		double contentBarGap = 0.0
	) {
		self.scrollAreaHeight = max(scrollAreaHeight, box.size.y);
		self.scrollNotchJump = scrollNotchJump;
		self.contentBarGap = contentBarGap;
		self.scrollWidth = scrollWidth;

		scrollArea.setBox((0, 0), (box.size.x - scrollWidth - contentBarGap, scrollAreaHeight));
		bar.setBox((box.size.x - scrollWidth, 0.0), (scrollWidth, box.size.y));
		bar.config(scrollBarNormal, scrollBarHover, scrollBarClick, scrollBg);

		self.alpha = 1.0;
	}

	static S7_ZF_ScrollContainer create(
		Vector2 pos, Vector2 size,
		double scrollWidth, double scrollAreaHeight, double scrollNotchJump,
		S7_ZF_BoxTextures scrollBarNormal, S7_ZF_BoxTextures scrollBarHover = NULL,
		S7_ZF_BoxTextures scrollBarClick = NULL, S7_ZF_BoxTextures scrollBg = NULL,
		S7_ZF_Element scrollArea = NULL, double contentBarGap = 0.0
	) {
		let ret = new('S7_ZF_ScrollContainer');

		ret.setBox(pos, size);

		if (scrollArea == NULL) {
			ret.scrollArea = S7_ZF_Frame.create((0, 0), (0, 0));
		}
		else {
			ret.scrollArea = scrollArea;
		}
		ret.bar = S7_ZF_Scrollbar.create((0, 0), (0, 0), NULL, NULL);

		ret.config(scrollWidth, scrollAreaHeight, scrollNotchJump, scrollBarNormal, scrollBarHover, scrollBarClick, scrollBg, contentBarGap);
		ret.elements.push(ret.bar);
		ret.bar.master = ret;
		ret.elements.push(ret.scrollArea);
		ret.scrollArea.master = ret;

		return ret;
	}

	override bool onNavEvent(S7_ZF_NavEventType type, bool fromController) {
		if (isFocused() && isEnabled()) {
			switch (type) {
			case S7_ZF_NavEventType_Down: {
				let oldPos = bar.position;
				bar.position += scrollNotchJump / scrollAreaHeight;
				bar.clampBarPos();
				return bar.position != oldPos;
			}
			case S7_ZF_NavEventType_Up: {
				let oldPos = bar.position;
				bar.position -= scrollNotchJump / scrollAreaHeight;
				bar.clampBarPos();
				return bar.position != oldPos;
			}
			}
		}
		return Super.onNavEvent(type, fromController);
	}

	override bool onUIEvent(S7_ZF_UiEvent ev) {
		if (Super.onUIEvent(ev)) return true;
		let mousePos = getGlobalStore().mousePos;
		if (ev.type == UiEvent.Type_WheelDown || ev.type == UiEvent.Type_WheelUp) {
			S7_ZF_AABB screenBox; boxToScreen(screenBox);
			if (isEnabled() && screenBox.pointCollides(mousePos)) {
				let dir = ev.type == UiEvent.Type_WheelDown ? 1.0 : -1.0;
				let oldPos = bar.position;
				bar.position += (dir * scrollNotchJump) / scrollAreaHeight;
				bar.clampBarPos();
				return oldPos != bar.position;
			}
		}
		return false;
	}

	override void topDrawer() {
		scrollArea.setBox((0, 0), (box.size.x - scrollWidth - contentBarGap, scrollAreaHeight));
		bar.setBox((box.size.x - scrollWidth, 0.0), (scrollWidth, box.size.y));
		bar.size = box.size.y / scrollAreaHeight;
		bar.size = min(bar.size, 1.0);
		scrollArea.box.pos.y = -bar.position * scrollAreaHeight;
		Super.topDrawer();
	}
}

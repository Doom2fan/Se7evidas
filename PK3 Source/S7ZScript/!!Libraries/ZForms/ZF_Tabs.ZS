class S7_ZF_Tabs : S7_ZF_ElementContainer {
	protected Array<S7_ZF_RadioButton> tabLabels;
	protected Array<S7_ZF_Frame> tabFrames;
	protected S7_ZF_RadioController curTab;

	protected double tabHeight;
	double getTabHeight() { return self.tabHeight; }
	void setTabHeight(double tabHeight) { self.tabHeight = tabHeight; }

	protected double tabLabelMargin;
	double getTabLabelMargin() { return self.tabLabelMargin; }
	void setTabLabelMargin(double tabLabelMargin) { self.tabLabelMargin = tabLabelMargin; }

	protected Font tabFont;
	Font getTabFont() { return self.tabFont; }
	void setTabFont(Font tabFont) {
		if (tabFont == NULL) {
			self.tabFont = smallfont;
		}
		else {
			self.tabFont = tabFont;
		}
	}

	protected double tabTextScale;
	double getTabTextScale() { return self.tabTextScale; }
	void setTabTextScale(double tabTextScale) { self.tabTextScale = tabTextScale; }

	protected S7_ZF_BoxTextures tabNormal;
	S7_ZF_BoxTextures getTabNormalTexture() { return self.tabNormal; }
	void setTabNormalTexture(S7_ZF_BoxTextures tabNormal) { self.tabNormal = tabNormal; setTabLabelBoxes(); }

	protected S7_ZF_BoxTextures tabHover;
	S7_ZF_BoxTextures getTabHoverTexture() { return self.tabHover; }
	void setTabHoverTexture(S7_ZF_BoxTextures tabHover) { self.tabHover = tabHover; setTabLabelBoxes(); }

	protected S7_ZF_BoxTextures tabActive;
	S7_ZF_BoxTextures getTabActiveTexture() { return self.tabActive; }
	void setTabActiveTexture(S7_ZF_BoxTextures tabActive) { self.tabActive = tabActive; setTabLabelBoxes(); }

	protected uint tabFocus;

	protected int lastTab;

	protected bool setBoxes;
	void setTabLabelBoxes() {
		if (setBoxes) {
			double curX = 0.0;
			for (int i = 0; i < tabLabels.size(); i++) {
				let l = tabLabels[i];
				l.setBox((curX, 0.0), (tabFont.stringWidth(l.getText()) * tabTextScale + 2.0 * tabLabelMargin, tabHeight));
				l.config(curTab, i, tabNormal, tabHover, tabActive, NULL, l.getText(), tabFont, tabTextScale);
				curX += l.box.size.x;
			}
		}
	}
	
	void config(
		double tabHeight, double tabLabelMargin, Font tabFont = NULL, double tabTextScale = 1.0,
		S7_ZF_BoxTextures tabNormal = NULL, S7_ZF_BoxTextures tabHover = NULL, S7_ZF_BoxTextures tabActive = NULL
	) {
		self.setBoxes = false;

		setTabHeight(tabHeight);
		setTabLabelMargin(tabLabelMargin);
		setTabFont(tabFont);
		setTabTextScale(tabTextScale);
		setTabNormalTexture(tabNormal);
		setTabHoverTexture(tabHover);
		setTabActiveTexture(tabActive);
		setAlpha(1.0);

		self.setBoxes = true;

		setTabLabelBoxes();
	}

	static S7_ZF_Tabs create(
		Vector2 pos, Vector2 size,
		double tabHeight, double tabLabelMargin, Font tabFont = NULL, double tabTextScale = 1.0,
		S7_ZF_BoxTextures tabNormal = NULL, S7_ZF_BoxTextures tabHover = NULL, S7_ZF_BoxTextures tabActive = NULL
	) {
		let ret = new("S7_ZF_Tabs");

		ret.setBox(pos, size);
		ret.curTab = new("S7_ZF_RadioController");
		ret.config(tabHeight, tabLabelMargin, tabFont, tabTextScale, tabNormal, tabHover, tabActive);

		return ret;
	}

	override void getFocusAABB(S7_ZF_AABB box) {
		let label = tabLabels[tabFocus];
		box.pos = label.relToMainFrame((0, 0));
		box.size = label.box.size;
	}

	override void beenFocused(S7_ZF_NavEventType type) {
		switch (type) {
		case S7_ZF_NavEventType_Left: tabFocus = tabLabels.size() - 1; break;

		case S7_ZF_NavEventType_Right:
		case S7_ZF_NavEventType_Tab:
			tabFocus = 0; break;

		case S7_ZF_NavEventType_Down:
		case S7_ZF_NavEventType_Up:
			tabFocus = curTab.curVal; break;
		}
	}

	void showCorrectTab() {
		for (int i = 0; i < tabFrames.size(); i++) {
			if (i == curTab.curVal) { tabFrames[i].show(); }
			else { tabFrames[i].hide(); }
		}
	}

	void addTab(string label) {
		let button = S7_ZF_RadioButton.create((0, 0), (0, 0), curTab, 0, text: label);
		let frame = S7_ZF_Frame.create((0.0, tabHeight), (box.size.x, box.size.y - tabHeight));

		button.master = self;
		frame.master = self;

		elements.push(button);
		elements.push(frame);

		tabLabels.push(button);
		tabFrames.push(frame);

		setTabLabelBoxes();

		showCorrectTab();
	}

	S7_ZF_Frame getTabFrame(int index) {
		return tabFrames[index];
	}

	override void topDrawer() {
		if (curTab.curVal != lastTab) {
			lastTab = curTab.curVal;
			showCorrectTab();
		}
		Super.topDrawer();
	}

	override void drawer() {
		if (curTab.curVal != lastTab) {
			lastTab = curTab.curVal;
			showCorrectTab();
		}
		Super.drawer();
	}

	override bool onNavEvent(S7_ZF_NavEventType type, bool fromController) {
		if (isFocused() && isEnabled()) {
			switch (type) {
			case S7_ZF_NavEventType_Right:
				if (tabFocus != tabLabels.size() - 1) {
					tabFocus += 1;
					return true;
				}
				break;
			case S7_ZF_NavEventType_Left:
				if (tabFocus != 0) {
					tabFocus -= 1;
					return true;
				}
				break;
			case S7_ZF_NavEventType_Confirm:
				curTab.curVal = tabFocus;
				break;
			}
		}
		return Super.onNavEvent(type, fromController);
	}

}

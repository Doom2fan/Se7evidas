class S7_ZF_DropdownItems {
	Array<string> items;
}

class S7_ZF_DropdownList : S7_ZF_Element {
	protected S7_ZF_DropdownItems items;
	S7_ZF_DropdownItems getItems() { return self.items; }
	void setItems(S7_ZF_DropdownItems items) { self.items = items; }

	protected int textColor;
	int getTextColor() { return self.textColor; }
	void setTextColor(int textColor) { self.textColor = textColor; }

	protected Font fnt;
	Font getFont() { return self.fnt; }
	void setFont(Font fnt) {
		if (fnt == NULL) {
			self.fnt = smallfont;
		}
		else {
			self.fnt = fnt;
		}
	}

	protected double textScale;
	double getTextScale() { return self.textScale; }
	void setTextScale(double textScale) { self.textScale = textScale; }

	protected int selection;
	int getSelection() { return self.selection; }

	protected S7_ZF_Frame bindingFrame;
	S7_ZF_Frame getBindingFrame() { return self.bindingFrame; }
	void setBindingFrame(S7_ZF_Frame bindingFrame) { self.bindingFrame = bindingFrame; }

	protected S7_ZF_BoxTextures boxBg;
	S7_ZF_BoxTextures getBoxBgTexture() { return self.boxBg; }
	void setBoxBgTexture(S7_ZF_BoxTextures boxBg) { self.boxBg = boxBg; }
	protected S7_ZF_BoxDrawer boxBgDrawer;

	protected S7_ZF_BoxTextures listBg;
	S7_ZF_BoxTextures getListBgTexture() { return self.listBg; }
	void setListBgTexture(S7_ZF_BoxTextures listBg) { self.listBg = listBg; }
	protected S7_ZF_BoxDrawer listBgDrawer;

	protected S7_ZF_BoxTextures highlightBg;
	S7_ZF_BoxTextures getHighlightBgTexture() { return self.highlightBg; }
	void setHighlightBgTexture(S7_ZF_BoxTextures highlightBg) { self.highlightBg = highlightBg; }
	protected S7_ZF_BoxDrawer highlightBgDrawer;

	protected string dropTex;
	string getDropTex() { return self.dropTex; }
	void setDropTex(string dropTex) { self.dropTex = dropTex; }

	protected bool clicking;
	protected bool active;
	protected int hover;
	protected bool lastKey;

	void config(
		S7_ZF_DropdownItems items, Font fnt = NULL, double textScale = 1.0, int textColor = Font.CR_WHITE,
		S7_ZF_BoxTextures boxBg = NULL, S7_ZF_BoxTextures listBg = NULL, S7_ZF_BoxTextures highlightBg = NULL,
		string dropTex = "", int defaultSelection = -1, S7_ZF_Handler cmdHandler = NULL, string command = "",
		S7_ZF_Frame bindingFrame = NULL
	) {
		setFont(fnt);
		setItems(items);
		setTextScale(textScale);
		setTextColor(textColor);
		setBoxBgTexture(boxBg);
		setListBgTexture(listBg);
		setHighlightBgTexture(highlightBg);
		setDropTex(dropTex);
		setBindingFrame(bindingFrame);
		setAlpha(1.0);

		self.cmdHandler = cmdHandler;
		self.command = command;
		self.selection = defaultSelection;
	}

	static S7_ZF_DropdownList create(
		Vector2 pos, Vector2 size,
		S7_ZF_DropdownItems items, Font fnt = NULL, double textScale = 1.0, int textColor = Font.CR_WHITE,
		S7_ZF_BoxTextures boxBg = NULL, S7_ZF_BoxTextures listBg = NULL, S7_ZF_BoxTextures highlightBg = NULL,
		string dropTex = "", int defaultSelection = -1, S7_ZF_Handler cmdHandler = NULL, string command = "",
		S7_ZF_Frame bindingFrame = NULL
	) {
		let ret = new("S7_ZF_DropdownList");

		ret.config(
			items, fnt, textScale, textColor, boxBg, listBg, highlightBg, dropTex,
			defaultSelection, cmdHandler, command, bindingFrame
		);
		ret.setBox(pos, size);

		return ret;
	}

	void dropdownAABB(S7_ZF_AABB screenBox) {
		S7_ZF_AABB aabb;
		aabb.pos = (0.0, getDropdownYOff());
		aabb.size = (box.size.x, box.size.y * items.items.size());
		aabbToScreen(screenBox, aabb, false);
		if (bindingFrame != NULL) {
			S7_ZF_AABB bindingBox; bindingFrame.boxToScreen(bindingBox);
			screenBox.rectOfIntersection(screenBox, bindingBox);
		}
	}

	override bool blocksMousePriority(Vector2 mousePos) {
		if (dontBlockMouse) return false;
		if (!active) return false;
		S7_ZF_AABB screenBox; dropdownAABB(screenBox);
		return screenBox.pointCollides(mousePos);
	}

	override void drawer() {
		if (hidden) { return; }

		S7_ZF_AABB beforeClip, clipRect;
		screenClip(beforeClip, clipRect);
		Screen.setClipRect(int(clipRect.pos.x), int(clipRect.pos.y), int(clipRect.size.x), int(clipRect.size.y));

		if (clicking) {
			if (highlightBg) highlightBgDrawer.draw(self, (0, 0), box.size, highlightBg, true);
		} else if (boxBg) {
			boxBgDrawer.draw(self, (0, 0), box.size, boxBg, true);
		}
		if (selection != -1) {
			let text = items.items[selection];
			Vector2 pos = getAlignedDrawPos(box.size, (fnt.stringWidth(text), fnt.getHeight()) * textScale, AlignType_CenterLeft);
			drawText(pos + (4.0 * textScale, 0.0), fnt, text, textColor, textScale);
		}
		TextureID dropTexID = TexMan.checkForTexture(dropTex, TexMan.Type_Any);
		if (dropTexID) {
			let dropSize = TexMan.getScaledSize(dropTexID);
			let dropPos = (box.size.x - box.size.y / 2.0, box.size.y / 2.0) - dropSize / 2.0;
			drawImage(dropPos, dropTex, true, (1.0, 1.0));
		}

		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}

	double getDropdownYOff() {
		S7_ZF_AABB aabb;
		aabb.pos = (0.0, box.size.y);
		aabb.size = (box.size.x, box.size.y * items.items.size());
		S7_ZF_AABB dropdownBox; aabbToScreen(dropdownBox, aabb, false);
		S7_ZF_AABB masterBox;
		if (bindingFrame != NULL) {
			bindingFrame.boxToScreen(masterBox);
		}
		else {
			masterBox.size.x = Screen.getWidth();
			masterBox.size.y = Screen.getHeight();
		}
		if (dropdownBox.pos.y + dropdownBox.size.y > masterBox.pos.y + masterBox.size.y) {
			aabb.pos.y = -box.size.y * items.items.size();
			aabbToScreen(dropdownBox, aabb, false);
			if (dropdownBox.pos.y < masterBox.pos.y) {
				return -box.size.y * items.items.size() + (masterBox.pos.y - dropdownBox.pos.y) / getScale();
			}
			else {
				return -box.size.y * items.items.size();
			}
		}
		else {
			return box.size.y;
		}
	}

	override void topDrawer() {
		if (hidden) { return; }
		if (!active) return;

		S7_ZF_AABB screenBox; dropdownAABB(screenBox);
		let mousePos = getGlobalStore().mousePos;
		if (screenBox.pointCollides(mousePos)) {
			hover = -1;
			let diff = mousePos - screenBox.pos;
			diff /= getScale();
			int newSelection = int(diff.y / box.size.y);
			hover = newSelection;
			lastKey = false;
		} else if (!lastKey) {
			hover = -1;
		}

		S7_ZF_AABB beforeClip, clipRect;
		if (bindingFrame != NULL) {
			bindingFrame.screenClip(beforeClip, clipRect);
			Screen.setClipRect(int(clipRect.pos.x), int(clipRect.pos.y), int(clipRect.size.x), int(clipRect.size.y));
		}
		else {
			screenClip(beforeClip, clipRect);
			Screen.clearClipRect();
		}

		if (listBg) {
			listBgDrawer.draw(self, (0, getDropdownYOff()), (box.size.x, box.size.y * items.items.size()), listBg, true);
		}
		if (hover != -1 && highlightBg) {
			highlightBgDrawer.draw(self, (0, getDropdownYOff() + box.size.y * hover), (box.size.x, box.size.y), highlightBg, true);
		}
		for (int i = 0; i < items.items.size(); i++) {
			let text = items.items[i];
			Vector2 pos = getAlignedDrawPos(box.size, (fnt.stringWidth(text), fnt.getHeight()) * textScale, AlignType_CenterLeft);
			drawText(pos + (4.0 * textScale, getDropdownYOff() + box.size.y * i), fnt, text, textColor, textScale);
		}

		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}

	bool setSelection() {
		let mousePos = getGlobalStore().mousePos;
		S7_ZF_AABB dropdownBox; dropdownAABB(dropdownBox);
		if (dropdownBox.pointCollides(mousePos) && hover != -1) {
			let newSelection = hover;
			let fireEvent = selection != newSelection;
			selection = newSelection;
			if (fireEvent && cmdHandler != NULL) {
				cmdHandler.dropdownChanged(self, command);
			}
			return true;
		}
		S7_ZF_AABB screenBox; boxToScreen(screenBox);
		return screenBox.pointCollides(mousePos);
	}

	override bool onNavEvent(S7_ZF_NavEventType type, bool fromController) {
		if (isEnabled()) {
			if (active) {
				switch (type) {
				case S7_ZF_NavEventType_Confirm: {
					let newSelection = hover;
					let fireEvent = selection != newSelection;
					selection = newSelection;
					if (fireEvent && cmdHandler != NULL) {
						cmdHandler.dropdownChanged(self, command);
					}
					active = false;
					break;
				}
				case S7_ZF_NavEventType_Down: {
					if (hover == -1) { hover = 0; }
					else {
						hover += 1;
						if (hover == items.items.size()) {
							hover -= 1;
						}
					}
					lastKey = true;
					break;
				}
				case S7_ZF_NavEventType_Up: {
					if (hover == -1) { hover = items.items.size() - 1; }
					else {
						hover -= 1;
						if (hover == -1) {
							hover = 0;
						}
					}
					lastKey = true;
					break;
				}
				}
				return true;
			} else if (isFocused() && type == S7_ZF_NavEventType_Confirm) {
				active = true;
				setHoverBlock(self);
				hover = -1;
				return true;
			}
		}
		return false;
	}

	override bool onUIEventPriority(S7_ZF_UiEvent ev) {
		let mousePos = getGlobalStore().mousePos;
		if (ev.type == UIEvent.Type_LButtonDown) {
			if (isEnabled()) {
				if (active) {
					active = false;
					return setSelection();
				}
				return false;
			}
		}
		else if (ev.type == UIEvent.Type_LButtonUp && clicking) {
			clicking = false;
			setHoverBlock(NULL);
			S7_ZF_AABB screenBox; dropdownAABB(screenBox);
			if (active && screenBox.pointCollides(mousePos)) {
				active = false;
				return setSelection();
			}
		}
		else if (ev.type == UIEvent.Type_WheelDown || ev.type == UIEvent.Type_WheelUp) {
			active = false;
		}
		return false;
	}

	override bool onUIEvent(S7_ZF_UiEvent ev) {
		if (ev.type == UIEvent.Type_LButtonDown) {
			if (isEnabled()) {
				S7_ZF_AABB screenBox; boxToScreen(screenBox);
				let mousePos = getGlobalStore().mousePos;
				if (!active && !mouseBlock && screenBox.pointCollides(mousePos)) {
					active = true;
					hover = -1;
					clicking = true;
					S7_ZF_AABB dropdownBox; dropdownAABB(dropdownBox);
					if (dropdownBox.pointCollides(mousePos)) {
						clicking = false;
					}
					setHoverBlock(self);
				}
			}
		}
		return false;
	}
}

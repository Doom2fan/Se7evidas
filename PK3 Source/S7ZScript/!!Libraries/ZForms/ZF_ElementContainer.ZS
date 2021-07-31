class S7_ZF_ElementContainer : S7_ZF_Element {
	protected Array<S7_ZF_Element> elements;

	override bool handleBack() {
		let ret = false;
		for (int i = 0; i < elements.size(); i++) {
			if (elements[i] != NULL) {
				ret = ret || elements[i].handleBack();
			}
		}
		return ret;
	}

	override void ticker() {
		for (int i = 0; i < elements.size(); i++) {
			if (elements[i] != NULL) {
				elements[i].ticker();
			}
		}
	}

	void drawerInternal(bool top) {
		if (hidden) { return; }

		// stuff in the frame shouldn't draw outside the frame
		S7_ZF_AABB beforeClip; getClipAABB(beforeClip);
		if (master != NULL) {
			S7_ZF_AABB clipCoords; boxToScreen(clipCoords);
			S7_ZF_AABB screenClip;
			screenClip.size = screenSize();
			clipCoords.rectOfIntersection(clipCoords, screenClip);

			Screen.setClipRect(int(clipCoords.pos.x), int(clipCoords.pos.y), int(clipCoords.size.x), int(clipCoords.size.y));
		}
		
		let globalStore = getGlobalStore();

		for (int i = 0; i < elements.size(); i++) {
			if (elements[i] != NULL && !elements[i].hidden) {
				if (top) { elements[i].topDrawer(); }
				else { drawSubElement(elements[i]); }
			}
		}

		if (!top) {
			if (master == NULL && globalStore.focusPriority == S7_ZF_FocusPriority_AboveAll) {
				drawFocusIndicator(globalStore);
			}
		}

		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}

	override bool handlePriorityMouseBlock(bool mouseBlock, Vector2 mousePos) {
		for (int i = elements.size() - 1; i >= 0; i--) {
			let elem = elements[i];
			if (elem != NULL && !elem.hidden) {
				elem.mouseBlock = mouseBlock;
				let res = elem.handlePriorityMouseBlock(mouseBlock, mousePos);
				mouseBlock = mouseBlock || res;
			}
		}
		return mouseBlock;
	}

	override bool handleMousePosition(bool mouseBlock, Vector2 mousePos) {
		for (int i = elements.size() - 1; i >= 0; i--) {
			let elem = elements[i];
			if (elem != NULL && !elem.hidden) {
				elem.mouseBlock = mouseBlock;
				let res = elem.mousePosAndBlock(mouseBlock, mousePos);
				elem.doHover(mouseBlock, mousePos);
				mouseBlock = mouseBlock || res;
			}
		}
		return mouseBlock;
	}

	override void drawer() {
		drawerInternal(false);
	}
	override void topDrawer() {
		drawerInternal(true);
	}
	
	override bool onNavEvent(S7_ZF_NavEventType type, bool fromController) {
		for (int i = elements.size() - 1; i >= 0; i--) {
			let elem = elements[i];
			if (elem != NULL && !elem.hidden) {
				let res = elem.onNavEvent(type, fromController);
				if (res) return true;
			}
		}
		return false;
	}

	override bool onUIEventPriority(S7_ZF_UiEvent ev) {
		let mousePos = getGlobalStore().mousePos;
		for (int i = elements.size() - 1; i >= 0; i--) {
			let elem = elements[i];
			if (elem != NULL && !elem.hidden) {
				let res = elem.onUIEventPriority(ev);
				if (res) return true;
			}
		}
		return false;
	}

	override bool onUIEvent(S7_ZF_UiEvent ev) {
		let mousePos = getGlobalStore().mousePos;
		for (int i = elements.size() - 1; i >= 0; i--) {
			let elem = elements[i];
			if (elem != NULL && !elem.hidden) {
				let res = elem.onUIEvent(ev);
				if (res) return true;
			}
		}
		return false;
	}

}

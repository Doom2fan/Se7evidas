class S7_ZF_ElementTreeGlobal {
	Vector2 baseScreenSize;

	bool blockMenuEvent;

	S7_ZF_Frame mainFrame;
	S7_ZF_Element hoverBlock;

	S7_ZF_Element focus;
	S7_ZF_Element focusIndicator;
	S7_ZF_FocusPriority focusPriority;

	Vector2 mousePos;

	bool needsMouseUpdate;
}

enum S7_ZF_NavEventType {
	S7_ZF_NavEventType_Left,
	S7_ZF_NavEventType_Right,
	S7_ZF_NavEventType_Up,
	S7_ZF_NavEventType_Down,

	S7_ZF_NavEventType_Tab,

	// not used for focus changing beyond this point

	S7_ZF_NavEventType_FocusChangeCount,

	S7_ZF_NavEventType_PageUp = S7_ZF_NavEventType_FocusChangeCount,
	S7_ZF_NavEventType_PageDown,

	S7_ZF_NavEventType_Confirm,
	S7_ZF_NavEventType_Deny
}

class S7_ZF_Element ui {
	enum AlignType {
		AlignType_Left    = 1,
		AlignType_HCenter = 2,
		AlignType_Right   = 3,

		AlignType_Top     = 1 << 4,
		AlignType_VCenter = 2 << 4,
		AlignType_Bottom  = 3 << 4,

		AlignType_TopLeft   = AlignType_Top | AlignType_Left,
		AlignType_TopCenter = AlignType_Top | AlignType_HCenter,
		AlignType_TopRight  = AlignType_Top | AlignType_Right,

		AlignType_CenterLeft  = AlignType_VCenter | AlignType_Left,
		AlignType_Center      = AlignType_VCenter | AlignType_HCenter,
		AlignType_CenterRight = AlignType_VCenter | AlignType_Right,

		AlignType_BottomLeft   = AlignType_Bottom | AlignType_Left,
		AlignType_BottomCenter = AlignType_Bottom | AlignType_HCenter,
		AlignType_BottomRight  = AlignType_Bottom | AlignType_Right,
	}

	protected S7_ZF_Element master;

	protected S7_ZF_ElementTreeGlobal globalStore;
	void setGlobalStore(S7_ZF_ElementTreeGlobal globalStore) {
		if (master == NULL) {
			self.globalStore = globalStore;
		}
	}

	void requestMouseUpdate() {
		let s = getGlobalStore();
		if (s != NULL) {
			s.needsMouseUpdate = true;
		}
	}

	protected S7_ZF_Handler cmdHandler;
	S7_ZF_Handler getCmdHandler() {return self.cmdHandler; }
	void setCmdHandler(S7_ZF_Handler cmdHandler) {self.cmdHandler = cmdHandler; }
	protected string command;
	string getCommand() {return self.command; }
	void setCommand(string command) {self.command = command; }

	protected S7_ZF_AABB box;
	Vector2 getPos() { return self.box.pos; }
	double getPosX() { return self.box.pos.x; }
	double getPosY() { return self.box.pos.y; }
	void setPos(Vector2 pos) { boxChange(pos, self.box.size); }
	void setPosX(double x) { boxChange((x, self.box.pos.y), self.box.size); }
	void setPosY(double y) { boxChange((self.box.pos.x, y), self.box.size); }
	Vector2 getSize() { return self.box.size; }
	double getWidth() { return self.box.size.x; }
	double getHeight() { return self.box.size.y; }
	void setSize(Vector2 size) { boxChange(self.box.pos, size); }
	void setWidth(double width) { boxChange(self.box.pos, (width, self.box.size.y)); }
	void setHeight(double height) { boxChange(self.box.pos, (self.box.size.x, height)); }

	void setBox(Vector2 pos, Vector2 size) {
		boxChange(pos, size);
	}
	
	void boxChange(Vector2 newPos, Vector2 newSize) {
		if (newPos == box.pos && newSize == box.size) return;
		box.pos = newPos;
		box.size = newSize;
		requestMouseUpdate();
		onBoxChanged();
	}
	virtual void onBoxChanged() {}

	protected S7_ZF_Element focusNeighbors[S7_ZF_NavEventType_FocusChangeCount];
	S7_ZF_Element getFocusNeighbor(S7_ZF_NavEventType type) {
		return self.focusNeighbors[type];
	}
	void setFocusNeighbor(S7_ZF_NavEventType type, S7_ZF_Element neighbor) {
		self.focusNeighbors[type] = neighbor;
	}

	bool isFocused() {
		return getGlobalStore().focus == self;
	}

	protected double alpha;
	double getAlpha() { return self.alpha; }
	void setAlpha(double alpha) { self.alpha = clamp(alpha, 0.0, 1.0); }

	protected bool disabled;
	bool isDisabled() { return self.disabled; }
	void setDisabled(bool disabled) { self.disabled = disabled; requestMouseUpdate(); }
	void enable() { disabled = false; requestMouseUpdate(); }
	void disable() { disabled = true; requestMouseUpdate(); }

	protected bool hidden;
	bool isHidden() { return hidden; }
	void setHidden(bool hidden) { self.hidden = hidden; requestMouseUpdate(); }
	void show() { hidden = false; requestMouseUpdate(); }
	void hide() { hidden = true; requestMouseUpdate(); }

	protected bool elemHovered;
	bool isHovered() { return self.elemHovered; }

	bool containsMouse() {
		S7_ZF_AABB screenBox;
		boxToScreen(screenBox);
		return screenBox.pointCollides(getGlobalStore().mousePos);
	}

	private bool noGlobalStore;
	void setNoGlobalStore() { noGlobalStore = true; }

	protected bool mouseBlock;

	protected bool dontBlockMouse;
	bool getDontBlockMouse() { return self.dontBlockMouse; }
	void setDontBlockMouse(bool dontBlockMouse) { self.dontBlockMouse = dontBlockMouse; requestMouseUpdate(); }

	int round(double roundee) {
		if (roundee < 0) {
			return int(roundee - 0.5);
		}
		else {
			return int(roundee + 0.5);
		}
	}

	void setHoverBlock(S7_ZF_Element val) {
		let s = getGlobalStore();
		if (s != NULL) {
			s.hoverBlock = val;
		}
	}

	bool getHoverBlock() {
		let s = getGlobalStore();
		if (s != NULL) {
			return s.hoverBlock != NULL && s.hoverBlock != self;
		}
		return false;
	}

	void getClipAABB(S7_ZF_AABB curClip) {
		[curClip.pos.x, curClip.pos.y, curClip.size.x, curClip.size.y] = screen.GetClipRect();
		if (curClip.size.x == -1) {
			curClip.pos = (0, 0);
			curClip.size = screenSize();
		}
	}

	Vector2 getAspectRatioOffset() {
		Vector2 screenSize = screenSize();
		Vector2 virtualSize = getBaseVirtualSize();
		Vector2 baseScreenSize = baseScreenSize();
		if (screenSize.x / baseScreenSize.x == screenSize.y / baseScreenSize.y) {
			return (0, 0);
		}
		else if (screenSize.x / baseScreenSize.x < screenSize.y / baseScreenSize.y) {
			return (0, (screenSize.y - (screenSize.x * (baseScreenSize.y / baseScreenSize.x)))) / 2;
		}
		else {
			return ((screenSize.x - (screenSize.y * (baseScreenSize.x / baseScreenSize.y))), 0) / 2;
		}
	}

	Vector2 relToMainFrame(Vector2 relPos) {
		if (master == NULL) return relPos;
		return master.relToMainFrame(box.pos + relPos);
	}

	/// Converts relative positioning to screen positioning.
	virtual Vector2 relToScreen(Vector2 relPos) {
		return master.relToScreen(box.pos + relPos);
	}

	Vector2 screenToRel(Vector2 screenPos) {
		return screenScaledToRel(screenPos / getScale()) - getAspectRatioOffset() / getScale();
	}

	/// Converts screen positioning to relative positioning.
	virtual Vector2 screenScaledToRel(Vector2 screenPos) {
		return master.screenToRel(screenPos - box.pos);
	}

	protected S7_ZF_ElementTreeGlobal getGlobalStore() {
		if (noGlobalStore) return NULL;
		if (globalStore != NULL) return globalStore;
		if (master != NULL) {
			globalStore = master.getGlobalStore();
			return globalStore;
		}
		return NULL;
	}

	void setBaseResolution(Vector2 res) {
		let s = getGlobalStore();
		if (s != NULL) {
			s.baseScreenSize = res;
			s.needsMouseUpdate = true;
		}
	}

	Vector2 baseScreenSize() {
		let s = getGlobalStore();
		if (s != NULL) {
			return s.baseScreenSize;
		}
		return screenSize();
	}

	void aabbToScreen(S7_ZF_AABB ret, S7_ZF_AABB bounds, bool intersect = true) {
		ret.pos = relToScreen(bounds.pos) * getScale();
		ret.size = bounds.size * getScale();

		if (intersect && master != NULL) {
			S7_ZF_AABB screenBox; master.boxToScreen(screenBox, true);
			ret.rectOfIntersection(ret, screenBox);
		}
	}

	/// Return a bounding box which uses absolute coordinates.
	void boxToScreen(S7_ZF_AABB ret, bool intersect = true) {
		ret.pos = relToScreen((0, 0)) * getScale();
		ret.size = box.size * getScale();

		if (intersect && master != NULL) {
			S7_ZF_AABB screenBox; master.boxToScreen(screenBox, true);
			ret.rectOfIntersection(ret, screenBox);
		}
	}

	Vector2 screenSize() {
		return (Screen.getWidth(), Screen.getHeight());
	}

	double getScale() {
		Vector2 screenSize = screenSize();
		let baseScreenSize = baseScreenSize();
		return min(screenSize.x / baseScreenSize.x, screenSize.y / baseScreenSize.y);
	}

	Vector2 getBaseVirtualSize() {
		return screenSize() / getScale();
	}

	/// Converts a scale to virtual coordinates for drawing elements at a scale factor.
	Vector2 scaleToVirtualSize(Vector2 scale) {
		Vector2 screenSize = getBaseVirtualSize();
		return (screenSize.x / scale.x, screenSize.y / scale.y);
	}

	Vector2 texSize(string texture) {
		return TexMan.getScaledSize(TexMan.checkForTexture(texture, TexMan.Type_Any));
	}

	/// Gets the correct position to draw aligned content at.
	Vector2 getAlignedDrawPos(Vector2 boxSize, Vector2 contentSize, AlignType align) {
		Vector2 pos = (0, 0);
		int horzAlign = align &  15;
		int vertAlign = align & (15 << 4);

		if (horzAlign == AlignType_HCenter) {
			pos.x = (boxSize.x - contentSize.x) / 2.0;
		}
		else if (horzAlign == AlignType_Right) {
			pos.x = boxSize.x - contentSize.x;
		}

		if (vertAlign == AlignType_VCenter) {
			pos.y = (boxSize.y - contentSize.y) / 2.0;
		}
		else if (vertAlign == AlignType_Bottom) {
			pos.y = boxSize.y - contentSize.y;
		}

		return pos;
	}

	/// Gets the cumulative alpha value for the element.
	double getDrawAlpha() {
		double calcAlpha = 1;

		S7_ZF_Element elem = self;
		while (elem) {
			calcAlpha *= elem.alpha;
			elem = elem.master;
		}

		return calcAlpha;
	}

	void screenClip(S7_ZF_AABB beforeClip, S7_ZF_AABB clipRect, S7_ZF_AABB aabb = NULL) {
		getClipAABB(beforeClip);
		if (aabb == NULL) boxToScreen(clipRect);
		else aabbToScreen(clipRect, aabb);
		clipRect.rectOfIntersection(clipRect, beforeClip);
		S7_ZF_AABB screenClip;
		screenClip.size = screenSize();
		clipRect.rectOfIntersection(clipRect, screenClip);
	}

	/// Draws text, taking into account relative positioning, and scale factor.
	void drawText(Vector2 relPos, Font fnt, string text, int color = Font.CR_WHITE, double scale = 1, double alpha = 1) {
		if (scale == 0) return;

		Vector2 drawPos = relToScreen(relPos) / scale;
		Vector2 virtualSize = scaleToVirtualSize((scale, scale));
		Screen.drawText(fnt, color, drawPos.x, drawPos.y, text, DTA_VirtualWidthF, virtualSize.x, DTA_VirtualHeightF, virtualSize.y, DTA_KeepRatio, true, DTA_Alpha, alpha * getDrawAlpha());
	}

	void drawLine(Vector2 start, Vector2 end, double thickness, Color color) {
		Vector2 drawPosStart = relToScreen(start) * getScale();
		Vector2 drawPosEnd = relToScreen(end) * getScale();
		thickness *= getScale();

		S7_ZF_AABB aabb; getClipAABB(aabb);
		bool draw;
		Vector2 clippedStart, clippedEnd;
		[draw, clippedStart, clippedEnd] = aabb.cohenSutherlandClip(drawPosStart, drawPosEnd);

		if (draw) {
			Screen.drawThickLine(
				int(clippedStart.x), int(clippedStart.y),
				int(clippedEnd.x), int(clippedEnd.y),
				thickness, color
			);
		}
	}

	/// Draws an image, taking into account relative positioning, and scale factor.
	void drawImage(Vector2 relPos, string imageName, bool animate, Vector2 scale = (1, 1), double alpha = 1, S7_ZF_AABB clipRect = NULL) {
		if (scale.x == 0 || scale.y == 0) return;

		S7_ZF_AABB c;
		if (clipRect == NULL) {
			getClipAABB(c);
		}
		else {
			c.pos = clipRect.pos;
			c.size = clipRect.size;
		}
		TextureID tex = TexMan.checkForTexture(imageName, TexMan.Type_Any);
		Vector2 drawPos = relToScreen(relPos);
		drawPos = (drawPos.x / scale.x, drawPos.y / scale.y);
		Vector2 virtualSize = scaleToVirtualSize(scale);
		Screen.DrawTexture(
			tex, animate, drawPos.x, drawPos.y, DTA_VirtualWidthF, virtualSize.x, DTA_VirtualHeightF, virtualSize.y,
			DTA_KeepRatio, true, DTA_Alpha, alpha * getDrawAlpha(),
			DTA_ClipLeft, int(c.pos.x), DTA_ClipTop, int(c.pos.y), DTA_ClipRight, int(c.pos.x + c.size.x), DTA_ClipBottom, int(c.pos.y + c.size.y),
			DTA_TopOffset, 0, DTA_LeftOffset, 0
		);
	}

	Vector2 scaleVec(Vector2 vec, Vector2 scale) {
		return (vec.x * scale.x, vec.y * scale.y);
	}

	/// Adds an axis-aligned quad to a Shape2D instance.
	void shape2DAddQuad(Shape2D shape, Vector2 pos, Vector2 size, Vector2 uvPos, Vector2 uvSize, out int vertCount) {
		shape.pushVertex((pos.x         , pos.y         ));
		shape.pushVertex((pos.x + size.x, pos.y         ));
		shape.pushVertex((pos.x         , pos.y + size.y));
		shape.pushVertex((pos.x + size.x, pos.y + size.y));

		shape.pushTriangle(vertCount + 0, vertCount + 3, vertCount + 1);
		shape.pushTriangle(vertCount + 0, vertCount + 2, vertCount + 3);

		shape.pushCoord((uvPos.x           , uvPos.y           ));
		shape.pushCoord((uvPos.x + uvSize.x, uvPos.y           ));
		shape.pushCoord((uvPos.x           , uvPos.y + uvSize.y));
		shape.pushCoord((uvPos.x + uvSize.x, uvPos.y + uvSize.y));

		vertCount += 4;
	}

	/// Draws a grid of images according to the size Vector2.
	/// Scales the image instead of tiling if possible.
	void drawTiledImage(Vector2 relPos, Vector2 size, string imageName, bool animate, Vector2 scale = (1, 1), double alpha = 1.0) {
		if (scale.x == 0 || scale.y == 0) {
			return;
		}

		Vector2 imageSize = texSize(imageName) * getScale();

		// Abort if the image has an invalid resolution.
		if (imageSize.x < 0 || imageSize.x ~== 0 || imageSize.y < 0 || imageSize.y ~== 0) {
			return;
		}

		Vector2 imageScale = scaleVec(imageSize, scale);
		let absPos = relToScreen(relPos) * getScale();
		let scaledSize = size * getScale();
		if (scaledSize ~== (0, 0)) {
			return;
		}

		let shape = new("Shape2D");
		shape.clear();

		double xSize = scaledSize.x / imageScale.x;
		double ySize = scaledSize.y / imageScale.y;
		int vertCount = 0;
		shape2DAddQuad(shape, absPos, scaledSize, (0, 0), (xSize, ySize), vertCount);

		let texID = TexMan.checkForTexture(imageName, TexMan.Type_Any);
		S7_ZF_AABB clipRect; getClipAABB(clipRect);
		Screen.drawShape(texID, animate, shape, DTA_Alpha, alpha * getDrawAlpha(), DTA_ClipLeft, int(floor(clipRect.pos.x)), DTA_ClipTop, int(floor(clipRect.pos.y)), DTA_ClipRight, int(ceil(clipRect.pos.x + clipRect.size.x)), DTA_ClipBottom, int (ceil(clipRect.pos.y + clipRect.size.y)));

		shape.clear();
		shape.destroy();
	}

	/// Draws a coloured region, taking into account relative positioning, and scale factor.
	void fill(Vector2 relStartPos, Vector2 size, Color col, double amount) {
		S7_ZF_AABB aabb;
		Vector2 startPos = relToScreen(relStartPos) * getScale();
		aabb.pos = startPos;
		aabb.size = size * getScale();
		S7_ZF_AABB clip;
		getClipAABB(clip);
		aabb.rectOfIntersection(aabb, clip);
		
		if (aabb.size.x > 0.0 && aabb.size.y > 0.0) {
			Screen.dim(col, amount * getDrawAlpha(), int(aabb.pos.x), int(aabb.pos.y), int(aabb.size.x), int(aabb.size.y));
		}
	}

	/// Packs the element into the master frame.
	void pack(S7_ZF_Frame master) {
		master.internalPack(self);
		requestMouseUpdate();
	}

	/// Unpacks the element from its master frame.
	void unpack() {
		if (master == NULL) {
			return;
		}
		if (!(master is "S7_ZF_Frame")) {
			throwAbortException("Tried to unpack a non-frame-bound element");
		}

		requestMouseUpdate();

		let masterFrame = S7_ZF_Frame(master);
		masterFrame.internalUnpack(self);
	}

	void drawFocusIndicator(S7_ZF_ElementTreeGlobal globalStore) {
		if (globalStore.focusIndicator == NULL) return;

		S7_ZF_AABB beforeClip;
		getClipAABB(beforeClip);
		Screen.clearClipRect();

		globalStore.focusIndicator.master = globalStore.mainFrame;
		globalStore.focusIndicator.drawer();
		globalStore.focusIndicator.master = NULL;

		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}

	void drawSubElement(S7_ZF_Element elem) {
		let globalStore = getGlobalStore();
		if (globalStore.focusPriority == S7_ZF_FocusPriority_JustBelowFocused && elem == globalStore.focus) {
			drawFocusIndicator(globalStore);
		}
		elem.drawer();
		if (globalStore.focusPriority == S7_ZF_FocusPriority_JustAboveFocused && elem == globalStore.focus) {
			drawFocusIndicator(globalStore);
		}
	}

	bool mousePosAndBlock(bool mouseBlock, Vector2 mousePos) {
		let res = handleMousePosition(mouseBlock, mousePos);
		if (res) return true;
		return blocksMouse(mousePos);
	}

	// methods for overriding in derived elements
	virtual void ticker() {}
	virtual bool handleMousePosition(bool mouseBlock, Vector2 mousePos) { return false; }
	virtual bool handlePriorityMouseBlock(bool mouseBlock, Vector2 mousePos) { return mouseBlock || blocksMousePriority(mousePos); }
	virtual void drawer() {}
	virtual void topDrawer() {}
	virtual bool onNavEvent(S7_ZF_NavEventType type, bool fromController) { return false; }
	virtual bool onUIEvent(S7_ZF_UiEvent ev) { return false; }
	virtual bool onUIEventPriority(S7_ZF_UiEvent ev) { return false; }

	virtual bool blocksMousePriority(Vector2 mousePos) { return false; }
	virtual bool blocksMouse(Vector2 mousePos) {
		if (dontBlockMouse) return false;
		S7_ZF_AABB screenBox; boxToScreen(screenBox);
		return screenBox.pointCollides(mousePos);
	}

	virtual bool handleBack() { return false; }

	virtual void getFocusAABB(S7_ZF_AABB box) { box.pos = relToMainFrame((0, 0)); box.size = self.box.size; }
	virtual void beenFocused(S7_ZF_NavEventType type) {}

	// Added by Chronos "phantombeta" Ouroboros
	bool isEnabled() {
		S7_ZF_Element elem = self;
		while (elem) {
			if (elem.disabled) {
				return false;
			}

			elem = elem.master;
		}

		return true;
	}

	virtual void doHover (bool mouseBlock, Vector2 mousePos) {
		S7_ZF_AABB screenBox; boxToScreen(screenBox);
		bool hover = (getHoverBlock() || mouseBlock) ? false : screenBox.pointCollides(mousePos);

		if (hover && !elemHovered) {
			if (cmdHandler) {
				cmdHandler.elementHoverChanged(self, command, false);
			}
			elemHovered = true;
		}
		else if (!hover && elemHovered) {
			if (cmdHandler) {
				cmdHandler.elementHoverChanged(self, command, true);
			}
			elemHovered = false;
		}
	}

	virtual void activate() {}
}

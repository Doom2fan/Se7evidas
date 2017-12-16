class S7_ZF_Element ui {
	S7_ZF_Frame master;

	Vector2 baseScreenSize;
	S7_ZF_AABB box;
	bool disabled;
	bool hidden;

	int round(double roundee) {
		if (roundee < 0) {
			return int(roundee - 0.5);
		}
		else {
			return int(roundee + 0.5);
		}
	}

	S7_ZF_AABB getClipAABB() {
		S7_ZF_AABB curClip = new("S7_ZF_AABB");
		[curClip.pos.x, curClip.pos.y, curClip.size.x, curClip.size.y] = screen.GetClipRect();
		if (curClip.size.x != -1) {
			return curClip;
		}
		else {
			curClip.pos = (0, 0);
			curClip.size = screenSize();
			return curClip;
		}
	}

	Vector2 getAspectRatioOffset() {
		Vector2 screenSize = screenSize();
		Vector2 virtualSize = getBaseVirtualSize();
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

	/// Return a bounding box which uses absolute coordinates.
	virtual S7_ZF_AABB boxToScreen() {
		S7_ZF_AABB ret = new("S7_ZF_AABB");
		ret.pos = relToScreen((0, 0)) * getScale();
		ret.size = box.size * getScale();
		return ret;
	}

	Vector2 screenSize() {
		return (Screen.getWidth(), Screen.getHeight());
	}

	double getScale() {
		Vector2 screenSize = screenSize();
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

	/// Draws text, taking into account relative positioning, and scale factor.
	void drawText(Vector2 relPos, Font fnt, string text, int color = Font.CR_WHITE, double scale = 1, double alpha = 1) {
		if (scale == 0) return;

		Vector2 drawPos = relToScreen(relPos) / scale;
		Vector2 virtualSize = scaleToVirtualSize((scale, scale));
		Screen.drawText(fnt, color, drawPos.x, drawPos.y, text, DTA_VirtualWidthF, virtualSize.x, DTA_VirtualHeightF, virtualSize.y, DTA_KeepRatio, true, DTA_Alpha, alpha);
	}

	/// Draws an image, taking into account relative positioning, and scale factor.
	void drawImage(Vector2 relPos, string imageName, bool animate, Vector2 scale = (1, 1), double alpha = 1, S7_ZF_AABB clipRect = NULL, bool offsets = true) {
		if (scale.x == 0 || scale.y == 0) return;

		if (clipRect == NULL) {
			clipRect = new("S7_ZF_AABB");
			clipRect.pos = (0, 0);
			clipRect.size = screenSize();
		}
		TextureID tex = TexMan.checkForTexture(imageName, TexMan.Type_Any);
		Vector2 drawPos = relToScreen(relPos);
		drawPos = (drawPos.x / scale.x, drawPos.y / scale.y);
		Vector2 virtualSize = scaleToVirtualSize(scale);
		if (offsets)
			Screen.DrawTexture(tex, animate, drawPos.x, drawPos.y, DTA_VirtualWidthF, virtualSize.x, DTA_VirtualHeightF, virtualSize.y, DTA_KeepRatio, true, DTA_Alpha, alpha, DTA_ClipLeft, int(clipRect.pos.x), DTA_ClipTop, int(clipRect.pos.y), DTA_ClipRight, int(clipRect.pos.x + clipRect.size.x), DTA_ClipBottom, int(clipRect.pos.y + clipRect.size.y));
		else
			Screen.DrawTexture(tex, animate, drawPos.x, drawPos.y, DTA_VirtualWidthF, virtualSize.x, DTA_VirtualHeightF, virtualSize.y, DTA_KeepRatio, true, DTA_Alpha, alpha, DTA_ClipLeft, int(clipRect.pos.x), DTA_ClipTop, int(clipRect.pos.y), DTA_ClipRight, int(clipRect.pos.x + clipRect.size.x), DTA_ClipBottom, int(clipRect.pos.y + clipRect.size.y), DTA_TopOffset, 0, DTA_LeftOffset, 0);
	}

	Vector2 scaleVec(Vector2 vec, Vector2 scale) {
		return (vec.x * scale.x, vec.y * scale.y);
	}

	/// Draws a grid of images according to the size Vector2.
	/// Scales the image instead of tiling if possible.
	void drawTiledImage(Vector2 relPos, Vector2 size, string imageName, Vector2 scale = (1, 1)) {
		Vector2 imageSize = texSize(imageName);

		S7_ZF_AABB beforeClip = getClipAABB();
		S7_ZF_AABB clipTest = new("S7_ZF_AABB");
		Vector2 clipPos = relToScreen(relPos);
		Vector2 clipSize = size;
		[clipTest.pos, clipTest.size] = Screen.virtualToRealCoords(clipPos, size, getBaseVirtualSize(), false, false);
		clipTest.pos = (round(clipTest.pos.x), round(clipTest.pos.y));
		clipTest.size = (round(clipTest.size.x), round(clipTest.size.y));
		S7_ZF_AABB clipRect = clipTest.rectOfIntersection(beforeClip);
		S7_ZF_AABB screenClip = new("S7_ZF_AABB");
		screenClip.size = screenSize();
		clipRect = clipRect.rectOfIntersection(screenClip);
		//Screen.setClipRect(clipRect.pos.x, clipRect.pos.y, clipRect.size.x, clipRect.size.y);

		Vector2 loopSize;
		loopSize.x = imageSize.x == 1 ? 1 : size.x;
		loopSize.y = imageSize.y == 1 ? 1 : size.y;
		Vector2 imageScale;
		imageScale.x = imageSize.x == 1 ? scale.x * size.x : scale.x;
		imageScale.y = imageSize.y == 1 ? scale.y * size.y : scale.y;

		for (int x = 0; x < int(loopSize.x); x += int(imageSize.x)) {
			for (int y = 0; y < int(loopSize.y); y += int(imageSize.y)) {
				drawImage(relPos + scaleVec((x, y), scale), imageName, true, imageScale, 1, clipRect);
			}
		}
		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}

	/// Draw a box using a S7_ZF_BoxTextures struct.
	void drawBox(Vector2 pos, Vector2 size, S7_ZF_BoxTextures textures, Vector2 scale = (1, 1)) {
		pos *= getScale();
		string tlName = textures.corners[textures.C_TOPLEFT];
		Vector2 cornerSize = texSize(tlName);
		drawImage(pos, tlName, true, scale);
		string trName = textures.corners[textures.C_TOPRIGHT];
		drawImage((pos.x + (size.x - cornerSize.x) * scale.x, pos.y), trName, true, scale);
		string blName = textures.corners[textures.C_BOTTOMLEFT];
		drawImage((pos.x, pos.y + (size.y - cornerSize.y) * scale.y), blName, true, scale);
		string brName = textures.corners[textures.C_BOTTOMRIGHT];
		drawImage(pos + scaleVec((size - cornerSize), scale), brName, true, scale);

		string tName = textures.sides[textures.S_TOP];
		drawTiledImage((pos.x + cornerSize.x * scale.x, pos.y), scaleVec((size.x - (cornerSize.x * 2), cornerSize.y), scale), tName, scale);
		string bName = textures.sides[textures.S_BOTTOM];
		drawTiledImage((pos.x + cornerSize.x * scale.x, pos.y + (size.y - cornerSize.y) * scale.y), scaleVec((size.x - (cornerSize.x * 2), cornerSize.y), scale), bName, scale);
		string lName = textures.sides[textures.S_LEFT];
		drawTiledImage((pos.x, pos.y + cornerSize.y * scale.y), scaleVec((cornerSize.x, size.y - (cornerSize.y * 2)), scale), lName, scale);
		string rName = textures.sides[textures.S_RIGHT];
		drawTiledImage((pos.x + (size.x - cornerSize.x) * scale.x, pos.y + cornerSize.y * scale.y), scaleVec((cornerSize.x, size.y - (cornerSize.y * 2)), scale), rName, scale);

		drawTiledImage(pos + scaleVec(cornerSize, scale), scaleVec(size - (cornerSize * 2), scale), textures.midTex);
	}

	/// Draws a coloured region, taking into account relative positioning, and scale factor.
	void fill(Vector2 relStartPos, Vector2 size, Color col, double amount) {
		S7_ZF_AABB beforeClip = getClipAABB();
		Vector2 clipPos = (relToScreen(relStartPos)) * getScale();
		S7_ZF_AABB clipTest = new("S7_ZF_AABB");
		clipTest.pos = clipPos;
		clipTest.size = size;
		S7_ZF_AABB clipRect = clipTest.rectOfIntersection(beforeClip);
		Screen.setClipRect(int(clipRect.pos.x), int(clipRect.pos.y), int(clipRect.size.x), int(clipRect.size.y));

		Vector2 startPos = (relToScreen(relStartPos)) * getScale();
		size *= getScale();
		Screen.dim(col, amount, int(startPos.x), int(startPos.y), int(size.x), int(size.y));

		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}

	/// Packs the element into the master frame.
	void pack(S7_ZF_Frame master) {
		self.master = master;
		master.elements.push(self);
		baseScreenSize = master.baseScreenSize;
	}

	void setBox(Vector2 pos, Vector2 size) {
		if (box == NULL) {
			box = new("S7_ZF_AABB");
		}
		box.pos = pos;
		box.size = size;
	}

	// methods for overriding in derived elements
	virtual void ticker() {}
	virtual void drawer() {}
	virtual void onUIEvent(UIEvent ev) {}

	// Added by Chronos "phantombeta" Ouroboros
	virtual bool isEnabled() {
		return (master.isEnabled() ? !disabled : false);
	}
	virtual bool isShown() {
		return (master.isShown() ? !hidden : false);
	}
}
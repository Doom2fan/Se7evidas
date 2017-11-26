/// Frame class - one frame at least is used in any menu, but frames can be put in frames
/// for easy subpositioning.
class S7_ZF_Frame : S7_ZF_Element {
	Array<S7_ZF_Element> elements;
	
	void setBaseResolution(Vector2 res) {
		baseScreenSize = res;
		for (int i = 0; i < elements.size(); i++) {
			if (elements[i] != NULL) {
				elements[i].baseScreenSize = res;
			}
		}
	}
	
	S7_ZF_Frame init(Vector2 pos, Vector2 size) {
		self.setBox(pos, size);
		
		return self;
	}
	
	override void ticker() {
		for (int i = 0; i < elements.size(); i++) {
			if (elements[i] != NULL) {
				elements[i].ticker();
			}
		}
	}
	
	override void drawer() {
		// stuff in the frame shouldn't draw outside the frame
		S7_ZF_AABB beforeClip = getClipAABB();
		if (master != NULL) {
			S7_ZF_AABB clipCoords = boxToScreen();
			S7_ZF_AABB screenClip = new("S7_ZF_AABB");
			screenClip.size = screenSize();
			clipCoords = clipCoords.rectOfIntersection(screenClip);
			
			Screen.setClipRect(int(clipCoords.pos.x), int(clipCoords.pos.y), int(clipCoords.size.x), int(clipCoords.size.y));
		}
		
		for (int i = 0; i < elements.size(); i++) {
			if (elements[i] != NULL) {
				elements[i].drawer();
			}
		}
		
		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}
	
	override void onUIEvent(UIEvent ev) {
		for (int i = 0; i < elements.size(); i++) {
			if (elements[i] != NULL) {
				elements[i].onUIEvent(ev);
			}
		}
	}
	
	/// Return a bounding box which uses absolute coordinates.
	override S7_ZF_AABB boxToScreen() {
		S7_ZF_AABB ret = new("S7_ZF_AABB");
		if (master != NULL) {
			ret.pos = relToScreen((0, 0)) * getScale();
		}
		else {
			ret.pos = box.pos * getScale();
		}
		ret.size = box.size * getScale();
		return ret;
	}
	
	/// Converts relative positioning to screen positioning.
	override Vector2 relToScreen(Vector2 relPos) {
		if (master == NULL) {
			return box.pos + relPos + getAspectRatioOffset() / getScale();
		}
		return master.relToScreen(box.pos + relPos);
	}
	
	/// Converts screen positioning to relative positioning.
	override Vector2 screenScaledToRel(Vector2 screenPos) {
		if (master == NULL) {
			return screenPos - box.pos;
		}
		return master.screenScaledToRel(screenPos - box.pos);
	}
}
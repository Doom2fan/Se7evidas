/// Frame class - one frame at least is used in any menu, but frames can be put in frames
/// for easy subpositioning.
class S7_ZF_Frame : S7_ZF_ElementContainer {
	uint elementCount() { return elements.size(); }
	int indexOfElement(S7_ZF_Element elem) { return elements.find(elem); }
	void swapElements(uint index0, uint index1) {
		let tmp = elements[index0];
		elements[index0] = elements[index1];
		elements[index1] = tmp;
	}
	void moveElement(uint beforeIndex, uint afterIndex) {
		if (beforeIndex == afterIndex) return;
		if (afterIndex > beforeIndex) afterIndex -= 1;
		let tmp = elements[beforeIndex];
		elements.delete(beforeIndex);
		elements.insert(afterIndex, tmp);
	}

	void internalPack(S7_ZF_Element elem) {
		if (elem.master != NULL) {
			elem.unpack();
		}
		elem.master = self;
		self.elements.push(elem);
		self.onPack(elem);
	}
	void internalUnpack(S7_ZF_Element elem) {
		if (elem.master != self) {
			throwAbortException("This shouldn't happen unless the user called internalUnpack themselves");
		}
		int index = self.elements.find (elem);
		if (index != self.elements.Size ()) {
			self.elements.delete(index, 1);
		}
		elem.master = NULL;
		elem.globalStore = NULL;
	}

	static S7_ZF_Frame create(Vector2 pos, Vector2 size) {
		let ret = new('S7_ZF_Frame');

		ret.setBox(pos, size);
		ret.alpha = 1;

		return ret;
	}

	virtual void onPack(S7_ZF_Element elem) {}

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

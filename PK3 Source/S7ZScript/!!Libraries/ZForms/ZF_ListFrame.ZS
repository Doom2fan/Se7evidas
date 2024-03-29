class S7_ZF_ListFrame : S7_ZF_Frame {
	protected double padding;
	double getPadding() { return self.padding; }
	void setPadding(double padding) { self.padding = padding; }

	void setElementBoxes() {
		let pos = 0.0;
		for (int i = 0; i < elements.size(); i++) {
			elements[i].box.pos = (0.0, pos);
			elements[i].box.size.x = box.size.x;
			pos += elements[i].box.size.y + padding;
		}
	}

	static S7_ZF_ListFrame create(
		Vector2 pos, Vector2 size, double padding
	) {
		let ret = new('S7_ZF_ListFrame');

		ret.setBox(pos, size);
		ret.padding = padding;
		ret.alpha = 1.0;

		return ret;
	}

	override void drawer() {
		setElementBoxes();
		Super.drawer();
	}

	override void onPack(S7_ZF_Element elem) {
		setElementBoxes();
	}
}

/// The base menu class for menus to inherit from.
/// Contains a mainFrame to put items in.
class S7_ZF_GenericMenu : GenericMenu {
	S7_ZF_Frame mainFrame;

	override void init(Menu parent) {
		Super.init(parent);
		mainFrame = new("S7_ZF_Frame");
		mainFrame.init((0, 0), (320, 200));
		mainFrame.setBaseResolution((320, 200));
	}

	void setBaseResolution(Vector2 size) {
		mainFrame.setBox((0, 0), size);
		mainFrame.setBaseResolution(size);
	}

	override void ticker() {
		Super.ticker();
		mainFrame.ticker();
	}

	override void drawer() {
		Super.drawer();
		mainFrame.drawer();
	}

	// "relay" all UI events down to the elements so they can handle them
	override bool onUIEvent(UIEvent ev) {
		mainFrame.onUIEvent(ev);
		return Super.onUIEvent(ev);
	}
}
enum S7_ZF_FocusPriority {
	S7_ZF_FocusPriority_AboveAll,
	S7_ZF_FocusPriority_JustBelowFocused,
	S7_ZF_FocusPriority_JustAboveFocused,
}

/// The base menu class for menus to inherit from.
/// Contains a mainFrame to put items in.
class S7_ZF_GenericMenu : GenericMenu {
	S7_ZF_Frame mainFrame;

	S7_ZF_Element focusDefaults[S7_ZF_NavEventType_FocusChangeCount];

	private S7_ZF_ElementTreeGlobal globalStore;

	Vector2 getMousePos() { return globalStore.mousePos; }

	void setFocus(S7_ZF_Element elem, S7_ZF_NavEventType type) {
		let old = globalStore.focus;
		globalStore.focus = elem;
		elem.beenFocused(type);
		changeFocusIndicator(old, globalStore.focus);
		if (globalStore.focusIndicator != NULL) globalStore.focusIndicator.show();
	}
	S7_ZF_Element getFocusIndicator() { return globalStore.focusIndicator; }
	void setFocusIndicator(S7_ZF_Element focusIndicator) { globalStore.focusIndicator = focusIndicator; }

	S7_ZF_FocusPriority getFocusPriority() { return globalStore.focusPriority; }
	void setFocusPriority(S7_ZF_FocusPriority focusPriority) { globalStore.focusPriority = focusPriority; }

	override void init(Menu parent) {
		Super.init(parent);
		mainFrame = S7_ZF_Frame.create((0, 0), (320, 200));
		globalStore = new("S7_ZF_ElementTreeGlobal");
		mainFrame.setGlobalStore(globalStore);
		mainFrame.setBaseResolution((320, 200));
		globalStore.mainFrame = mainFrame;
		globalStore.needsMouseUpdate = true;
		setupFocusIndicator();
		if (globalStore.focusIndicator != NULL) {
			globalStore.focusIndicator.setNoGlobalStore();
			globalStore.focusIndicator.hide();
		}
	}

	void setBaseResolution(Vector2 size) {
		mainFrame.setBox((0, 0), size);
		mainFrame.setBaseResolution(size);
	}

	virtual void handleBack() {
		if (!mainFrame.handleBack()) {
			close();
			let m = GetCurrentMenu();
			MenuSound(m != null ? "menu/backup" : "menu/clear");
			if (!m) menuDelegate.MenuDismissed();
		}
	}

	override bool translateKeyboardEvents() {
		if (globalStore == NULL) return true;
		return !globalStore.blockMenuEvent;
	}

	override void ticker() {
		Super.ticker();
		mainFrame.ticker();
	}

	override void drawer() {
		if (globalStore.focus != NULL) {
			S7_ZF_AABB box;
			globalStore.focus.getFocusAABB(box);
			positionFocusIndicator(box.pos, box.size);
		}

		if (globalStore.needsMouseUpdate) {
			let mouseBlock = mainFrame.handlePriorityMouseBlock(false, globalStore.mousePos);
			mainFrame.handleMousePosition(mouseBlock, globalStore.mousePos);
			globalStore.needsMouseUpdate = false;
		}
		mainFrame.drawer();
		mainFrame.topDrawer();
	}

	virtual void setupFocusIndicator() {}
	virtual void changeFocusIndicator(S7_ZF_Element oldFocus, S7_ZF_Element newFocus) {}
	virtual void positionFocusIndicator(Vector2 pos, Vector2 size) {}

	void fireNavigationEvent(S7_ZF_NavEventType type, bool fromController) {
		if (type == S7_ZF_NavEventType_Deny) {
			handleBack();
		}

		if (mainFrame.onNavEvent(type, fromController)) return;

		if (type < S7_ZF_NavEventType_FocusChangeCount) {
			S7_ZF_Element newFocus;
			if (globalStore.focus == NULL) {
				newFocus = focusDefaults[type];
			} else {
				newFocus = globalStore.focus.getFocusNeighbor(type);
			}
			if (newFocus != NULL) {
				let oldFocus = globalStore.focus;
				setFocus(newFocus, type);
			}
		}
	}

	// "relay" all UI events down to the elements so they can handle them
	override bool onUIEvent(UIEvent ev) {
		if (ev.type == UIEvent.Type_KeyDown && (ev.keyChar == UIEvent.Key_Escape || ev.keyChar == UIEvent.Key_Back)) {
			handleBack();
		}
		if (ev.type == UIEvent.Type_MouseMove) {
			globalStore.mousePos.x = ev.mouseX;
			globalStore.mousePos.y = ev.mouseY;
			globalStore.needsMouseUpdate = true;
			return true;
		}
		if (ev.type == UIEvent.Type_LButtonDown) {
			let oldFocus = globalStore.focus;
			globalStore.focus = NULL;
			changeFocusIndicator(oldFocus, NULL);
			if (globalStore.focusIndicator != NULL) globalStore.focusIndicator.hide();
			SetCapture(true);
		}
		if (ev.type == UIEvent.Type_LButtonUp) {
			SetCapture(false);
		}

		S7_ZF_UiEvent zfEv;

		S7_ZF_UiEvent.fromGZDUiEvent(ev, zfEv);
		if (mainFrame.onUIEventPriority(zfEv)) return true;
		if (mainFrame.onUIEvent(zfEv)) return true;

		return true;
	}

	override bool menuEvent(int mkey, bool fromcontroller) {
		if (globalStore != NULL && globalStore.blockMenuEvent) return true;

		switch (mkey) {
		case MKEY_Up:    fireNavigationEvent(S7_ZF_NavEventType_Up, fromcontroller); break;
		case MKEY_Down:  fireNavigationEvent(S7_ZF_NavEventType_Down, fromcontroller); break;
		case MKEY_Left:  fireNavigationEvent(S7_ZF_NavEventType_Left, fromcontroller); break;
		case MKEY_Right: fireNavigationEvent(S7_ZF_NavEventType_Right, fromcontroller); break;

		case MKEY_PageUp:   fireNavigationEvent(S7_ZF_NavEventType_PageUp, fromcontroller); break;
		case MKEY_PageDown: fireNavigationEvent(S7_ZF_NavEventType_PageDown, fromcontroller); break;

		case MKEY_Enter: fireNavigationEvent(S7_ZF_NavEventType_Confirm, fromcontroller); break;
		case MKEY_Back:  fireNavigationEvent(S7_ZF_NavEventType_Deny, fromcontroller); break;
		}
		return true;
	}
}

class S7_ZF_EventHandlerMenu ui {
	S7_ZF_Frame mainFrame;

	protected bool useCustomCursor;
	protected string customCursor;

	virtual void init() {
		mainFrame = S7_ZF_Frame.create((0, 0), (320, 200));
		mainFrame.setBaseResolution((320, 200));
	}

	void setBaseResolution(Vector2 size) {
		mainFrame.setBox((0, 0), size);
		mainFrame.setBaseResolution(size);
	}

	void doTick() {
		ticker();
	}

	virtual void handleBack() {
		mainFrame.handleBack();
	}

	protected virtual void ticker() {
		// Trigger a mouse movement UI event to fix things "sticking" sometimes
		S7_ZF_UiEvent zfEv;
		zfEv.type = UIEvent.Type_MouseMove;
		zfEv.mouseX = inputProc_MouseX;
		zfEv.mouseY = inputProc_MouseY;
		mainFrame.onUIEvent(zfEv);

		mainFrame.ticker();
	}

	void doDraw() {
		drawer();

		if (useCustomCursor) {
			Screen.DrawTexture(TexMan.checkForTexture(customCursor, TexMan.Type_Any), true, inputProc_MouseX, inputProc_MouseY);
		}
	}

	protected virtual void drawer() {
		mainFrame.drawer();
		mainFrame.topDrawer();
	}

	// "relay" all UI events down to the elements so they can handle them
	virtual bool onUIEvent(UIEvent ev) {
		if (ev.type == UIEvent.Type_KeyDown && (ev.keyChar == UIEvent.Key_Escape || ev.keyChar == UIEvent.Key_Back)) {
			handleBack();
		}

		S7_ZF_UiEvent zfEv;

		S7_ZF_UiEvent.fromGZDUiEvent(ev, zfEv);
		if (mainFrame.onUIEventPriority(zfEv)) return true;
		mainFrame.onUIEvent(zfEv);
		return true;
	}

	private bool inputProc_Alt;
	private bool inputProc_Shift;
	private bool inputProc_Ctrl;
	protected int inputProc_MouseX;
	protected int inputProc_MouseY;

	int, int getCustomMousePosition() {
		return inputProc_MouseX, inputProc_MouseY;
	}

	void setCustomMousePosition(int posX, int posY) {
		inputProc_MouseX = posX;
		inputProc_MouseY = posY;
	}

	void copyCustomMousePosition(S7_ZF_EventHandlerMenu other) {
		inputProc_MouseX = other.inputProc_MouseX;
		inputProc_MouseY = other.inputProc_MouseY;
	}

	void onInputEvent(InputEvent gzdEv) {
		S7_ZF_UiEvent ev;

		ev.KeyString = gzdEv.KeyString;
		ev.KeyChar = gzdEv.KeyChar;

		ev.Type = -1;

		switch (gzdEv.Type) {
			case InputEvent.Type_None: ev.Type = UiEvent.Type_None; break;

			case InputEvent.Type_KeyDown:
				switch (gzdEv.KeyScan) {
					// Mouse events
					case InputEvent.Key_Mouse1     : ev.Type = UiEvent.Type_LButtonDown   ; break;
					case InputEvent.Key_Mouse2     : ev.Type = UiEvent.Type_RButtonDown   ; break;
					case InputEvent.Key_Mouse3     : ev.Type = UiEvent.Type_MButtonDown   ; break;
					case InputEvent.Key_MWheelUp   : ev.Type = UiEvent.Type_WheelUp       ; break;
					case InputEvent.Key_MWheelDown : ev.Type = UiEvent.Type_WheelDown     ; break;
					case InputEvent.Key_MWheelLeft : ev.Type = UiEvent.Type_WheelLeft     ; break;
					case InputEvent.Key_MWheelRight: ev.Type = UiEvent.Type_WheelRight    ; break;
					case InputEvent.Key_Mouse4     : ev.Type = UiEvent.Type_BackButtonDown; break;
					case InputEvent.Key_Mouse5     : ev.Type = UiEvent.Type_FwdButtonDown ; break;

					// Ctrl, shift and alt
					case InputEvent.Key_LShift: inputProc_Alt   = true; break;
					case InputEvent.Key_LCtrl : inputProc_Shift = true; break;
					case InputEvent.Key_LAlt  : inputProc_Ctrl  = true; break;

					// Everything else
					default: {
						ev.Type = UiEvent.Type_KeyDown;

						int val = convertDIKToGUIKey(gzdEv.KeyScan);

						if (val != -1) {
							ev.KeyChar = val;
						}
					}
					break;
				}
			break;

			case InputEvent.Type_KeyUp:
				switch (gzdEv.KeyScan) {
					// Mouse events
					case InputEvent.Key_Mouse1     : ev.Type = UiEvent.Type_LButtonUp   ; break;
					case InputEvent.Key_Mouse2     : ev.Type = UiEvent.Type_RButtonUp   ; break;
					case InputEvent.Key_Mouse3     : ev.Type = UiEvent.Type_MButtonUp   ; break;
					case InputEvent.Key_Mouse4     : ev.Type = UiEvent.Type_BackButtonUp; break;
					case InputEvent.Key_Mouse5     : ev.Type = UiEvent.Type_FwdButtonUp ; break;

					// Ctrl, shift and alt
					case InputEvent.Key_LShift: inputProc_Alt   = false; break;
					case InputEvent.Key_LCtrl : inputProc_Shift = false; break;
					case InputEvent.Key_LAlt  : inputProc_Ctrl  = false; break;

					// Everything else
					default: {
						ev.Type = UiEvent.Type_KeyUp;

						int val = convertDIKToGUIKey(gzdEv.KeyScan);

						if (val != -1) {
							ev.KeyChar = val;
						}
					}
					break;
				}
			break;

			case InputEvent.Type_Mouse:
				inputProc_MouseX = clamp(inputProc_MouseX + gzdEv.MouseX, 0, Screen.GetWidth ());
				inputProc_MouseY = clamp(inputProc_MouseY - gzdEv.MouseY, 0, Screen.GetHeight());

				ev.Type = UiEvent.Type_MouseMove;
				ev.MouseX = inputProc_MouseX;
				ev.MouseY = inputProc_MouseY;
			break;
		}

		if (ev.Type == -1) {
			return;
		}

		mainFrame.onUIEvent(ev);
	}

	private int convertDIKToGUIKey(int keyScan) {
		switch (keyScan) {
			case InputEvent.Key_PgDn: return UiEvent.Key_PgDn;
			case InputEvent.Key_PgUp: return UiEvent.Key_PgUp;
			case InputEvent.Key_Home: return UiEvent.Key_Home;
			case InputEvent.Key_End : return UiEvent.Key_End ;

			case InputEvent.Key_UpArrow   : return UiEvent.Key_Up   ;
			case InputEvent.Key_DownArrow : return UiEvent.Key_Down ;
			case InputEvent.Key_LeftArrow : return UiEvent.Key_Left ;
			case InputEvent.Key_RightArrow: return UiEvent.Key_Right;

			case InputEvent.Key_Escape   : return UiEvent.Key_Escape   ;
			case InputEvent.Key_Enter    : return UiEvent.Key_Return   ;
			case InputEvent.Key_Tab      : return UiEvent.Key_Tab      ;
			case InputEvent.Key_Del      : return UiEvent.Key_Del      ;
			case InputEvent.Key_Backspace: return UiEvent.Key_Backspace;

			case InputEvent.Key_F1 : return UiEvent.Key_F1 ;
			case InputEvent.Key_F2 : return UiEvent.Key_F2 ;
			case InputEvent.Key_F3 : return UiEvent.Key_F3 ;
			case InputEvent.Key_F4 : return UiEvent.Key_F4 ;
			case InputEvent.Key_F5 : return UiEvent.Key_F5 ;
			case InputEvent.Key_F6 : return UiEvent.Key_F6 ;
			case InputEvent.Key_F7 : return UiEvent.Key_F7 ;
			case InputEvent.Key_F8 : return UiEvent.Key_F8 ;
			case InputEvent.Key_F9 : return UiEvent.Key_F9 ;
			case InputEvent.Key_F10: return UiEvent.Key_F10;
			case InputEvent.Key_F11: return UiEvent.Key_F11;
			case InputEvent.Key_F12: return UiEvent.Key_F12;
		}

		return -1;
	}
}

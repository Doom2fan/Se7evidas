class S7_ZF_Slider : S7_ZF_Element {
	protected double low, high, step;
	double getLow() { return self.low; }
	void setLow(double low) { self.low = low; swapIfNecessary(); }
	double getHigh() { return self.high; }
	void setHigh(double high) { self.high = high; swapIfNecessary(); }
	double getStep() { return self.step; }
	void setStep(double step) { self.step = max(step, 0.0); }

	void swapIfNecessary() {
		if (low > high) {
			let tmp = low;
			low = high;
			high = tmp;
		}
	}

	protected double value;
	double getValue() { return self.value; }
	void setValue(double value) { self.value = value; }

	protected S7_ZF_BoxTextures background;
	S7_ZF_BoxTextures getBackgroundTexture() { return self.background; }
	void setBackgroundTexture(S7_ZF_BoxTextures background) { self.background = background; }
	S7_ZF_BoxDrawer backgroundDrawer;

	enum HandleType {
		Handle_Normal,
		Handle_Hover,
		Handle_Click
	}
	protected S7_ZF_BoxTextures handle[3];

	S7_ZF_BoxTextures getHandleTexture() { return handle[Handle_Normal]; }
	void setHandleTexture(S7_ZF_BoxTextures tex) { handle[Handle_Normal] = tex; }

	S7_ZF_BoxTextures getHandleHoverTexture() { return handle[Handle_Hover]; }
	void setHandleHoverTexture(S7_ZF_BoxTextures tex) { handle[Handle_Hover] = (tex != NULL) ? tex : handle[Handle_Normal]; }
	
	S7_ZF_BoxTextures getHandleClickTexture() { return handle[Handle_Click]; }
	void setHandleClickTexture(S7_ZF_BoxTextures tex) { handle[Handle_Click] = (tex != NULL) ? tex : handle[Handle_Normal]; }

	protected S7_ZF_BoxDrawer handleDrawer[3];

	protected double handleWidth;
	double getHandleWidth() { return self.handleWidth; }
	void setHandleWidth(double handleWidth) { self.handleWidth = handleWidth; }

	protected bool clicking;
	protected bool hover;

	double getDrawHandleWidth() {
		if (handleWidth <= 0.0) {
			if (step == 0.0) {
				return self.box.size.y;
			}
			else {
				let ratio = (high - low) / step + 1;
				return 1.0 / ratio * self.box.size.x;
			}
		}
		else {
			return handleWidth;
		}
	}

	void config(
		double low, double high, double value, double step, double handleWidth,
		S7_ZF_BoxTextures handle, S7_ZF_BoxTextures handleHover, S7_ZF_BoxTextures handleClick = NULL,
		S7_ZF_BoxTextures background = NULL, S7_ZF_Handler cmdHandler = NULL, string command = ""
	) {
		setLow(low);
		setHigh(high);
		setStep(step);
		setValue(value);
		setHandleWidth(handleWidth);
		setBackgroundTexture(background);
		setHandleTexture(handle);
		setHandleHoverTexture(handleHover);
		setHandleClickTexture(handleClick);
		setAlpha(1.0);
		self.cmdHandler = cmdHandler;
		self.command = command;
	}

	static S7_ZF_Slider create(
		Vector2 pos, Vector2 size,
		double low, double high, double value, double step, double handleWidth,
		S7_ZF_BoxTextures handle, S7_ZF_BoxTextures handleHover, S7_ZF_BoxTextures handleClick = NULL,
		S7_ZF_BoxTextures background = NULL, S7_ZF_Handler cmdHandler = NULL, string command = ""
	) {
		let ret = new("S7_ZF_Slider");

		ret.setBox(pos, size);
		ret.config(low, high, value, step, handleWidth, handle, handleHover, handleClick, background, cmdHandler, command);

		return ret;
	}

	override void drawer() {
		S7_ZF_AABB screenBox; boxToScreen(screenBox);
		let mousePos = getGlobalStore().mousePos;
		if (!mouseBlock && !getHoverBlock() && isEnabled() && screenBox.pointCollides(mousePos)) {
			hover = true;
		}
		else {
			hover = false;
		}

		double oldVal = value;
		if (clicking) {
			S7_ZF_AABB screenBox; boxToScreen(screenBox);
			let diff = mousePos - screenBox.pos;
			diff /= getScale();
			diff.x -= getDrawHandleWidth() / 2;
			let t = diff.x / (box.size.x - getDrawHandleWidth());
			t = clamp(t, 0.0, 1.0);
			let newVal = (high - low) * t;
			if (step != 0.0) {
				newVal /= step;
				newVal = round(newVal);
				newVal *= step;
			}
			value = low + newVal;
		}
		value = clamp(value, low, high);
		if (cmdHandler != NULL && oldVal != value) {
			cmdHandler.sliderChanged(self, command);
		}

		S7_ZF_AABB beforeClip, clipRect;
		screenClip(beforeClip, clipRect);
		Screen.setClipRect(int(clipRect.pos.x), int(clipRect.pos.y), int(clipRect.size.x), int(clipRect.size.y));
		
		if (background) {
			backgroundDrawer.draw(self, (0, 0), box.size, background, true);
		}
		let t = (high == low) ? 0.0 : ((value - low) / (high - low));
		let i = clicking ? Handle_Click : hover ? Handle_Hover : Handle_Normal;
		handleDrawer[i].draw(
			self,
			(t * (box.size.x - getDrawHandleWidth()), 0), (getDrawHandleWidth(), box.size.y),
			handle[i], true
		);

		Screen.setClipRect(int(beforeClip.pos.x), int(beforeClip.pos.y), int(beforeClip.size.x), int(beforeClip.size.y));
	}

	override bool onNavEvent(S7_ZF_NavEventType type, bool fromController) {
		if (isEnabled() && isFocused()) {
			let newStep = step;
			if (step == 0.0) {
				newStep = (high - low) / 25.0;
			}
			let oldVal = value;
			switch (type) {
			case S7_ZF_NavEventType_Left: {
				value -= newStep;
				value = clamp(value, low, high);
				if (cmdHandler != NULL && oldVal != value) {
					cmdHandler.sliderChanged(self, command);
				}
				return true;
			}
			case S7_ZF_NavEventType_Right: {
				value += newStep;
				value = clamp(value, low, high);
				if (cmdHandler != NULL && oldVal != value) {
					cmdHandler.sliderChanged(self, command);
				}
				return true;
			}
			}
		}
		return false;
	}

	override bool onUIEvent(S7_ZF_UiEvent ev) {
		if (ev.type == UIEvent.Type_LButtonDown) {
			S7_ZF_AABB screenBox; boxToScreen(screenBox);
			let mousePos = getGlobalStore().mousePos;
			if (!mouseBlock && isEnabled() && screenBox.pointCollides(mousePos)) {
				clicking = true;
				setHoverBlock(self);
			}
		}
		else if (ev.type == UIEvent.Type_LButtonUp) {
			clicking = false;
			setHoverBlock(NULL);
		}
		return false;
	}
}

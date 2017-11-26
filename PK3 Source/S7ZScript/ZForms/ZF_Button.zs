class S7_ZF_Button : S7_ZF_Element {
	enum ButtonStates {
		B_INACTIVE,
		B_HOVER,
		B_CLICK,
		B_DISABLED
	}
	
	S7_ZF_Handler handler;
	string command;
	
	Font fnt;
	string text;
	double textScale;
	
	S7_ZF_BoxTextures textures[4];
	string btnTextures [4];
	bool singleTex;
	
	int buttonState;
	
	Vector2 mousePos;

	void setTexture(string inactive, string hover, string click) {
		self.btnTextures[B_INACTIVE] = inactive;
		self.btnTextures[B_HOVER] = hover;
		self.btnTextures[B_CLICK] = click;
		self.singleTex = true;
	}
	
	void config(string text = "", S7_ZF_Handler handler = NULL, string command = "",
	            S7_ZF_BoxTextures inactive = NULL, S7_ZF_BoxTextures hover = NULL,
	            S7_ZF_BoxTextures click = NULL, Font fnt = NULL, double textScale = 1) {
		if (fnt == NULL) {
			self.fnt = smallfont;
		}
		else {
			self.fnt = fnt;
		}
		self.handler = handler;
		self.command = command;
		self.text = text;
		self.textScale = textScale;
		self.textures[B_INACTIVE] = inactive;
		self.textures[B_HOVER] = hover;
		self.textures[B_CLICK] = click;
		self.singleTex = false;
	}
	
	S7_ZF_Button init(Vector2 pos, Vector2 size, string text = "", S7_ZF_Handler handler = NULL, string command = "", 
	               S7_ZF_BoxTextures inactive = NULL, S7_ZF_BoxTextures hover = NULL, S7_ZF_BoxTextures click = NULL,
	               Font fnt = NULL, double textScale = 1) {
		self.config(text, handler, command, inactive, hover, click, fnt, textScale);
		self.setBox(pos, size);
		
		return self;
	}
	
	override void ticker() {
	}
	
	override void drawer() {		
		if (singleTex) {
			string texture = btnTextures[buttonState];
			drawImage((0, 0), texture, true);
		} else {
			S7_ZF_BoxTextures textures = textures[buttonState];
			drawBox((0, 0), box.size, textures);
		}
		
		// draw the text in the middle of the button
		Vector2 textSize = (fnt.stringWidth(text), fnt.getHeight()) * textScale;
		Vector2 textPos = (box.size - textSize) / 2;
		drawText(textPos, fnt, text, Font.CR_WHITE, textScale);
	}
	
	override void onUIEvent(UIEvent ev) {
		// if the player's clicked, and their mouse is in the right place, set the state accordingly
		if (ev.type == UIEvent.Type_LButtonDown) {
			if (box.pointCollides(master.screenToRel(mousePos))) {
				buttonState = B_CLICK;
			}
		}
		// if the player's releasing, check if their mouse is still in the correct range and trigger method if it was
		else if (ev.type == UIEvent.Type_LButtonUp) {
			if (box.pointCollides(master.screenToRel(mousePos)) && buttonState == B_CLICK) {
				buttonState = B_HOVER;
				handler.buttonCommand(command);
			}
			else {
				buttonState = B_INACTIVE;
			}
		}
		// if the player's mouse has moved, update the tracked position and do a quick hover check
		else if (ev.type == UIEvent.Type_MouseMove) {
			mousePos = (ev.mouseX, ev.mouseY);
			if (buttonState != B_CLICK) {
				if (box.pointCollides(master.screenToRel(mousePos))) {
					buttonState = B_HOVER;
				}
				else {
					buttonState = B_INACTIVE;
				}
			}
		}
	}
}
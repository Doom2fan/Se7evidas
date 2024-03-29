/// Used to determine what to be drawn to the screen for boxes.
class S7_ZF_BoxTextures ui {
	private string boxTexture;
	string getBoxTexture() { return boxTexture; }

	private bool scaleSides;
	bool getscaleSides() { return scaleSides; }
	
	private bool scaleMiddle;
	bool getScaleMiddle() { return scaleMiddle; }

	private Vector2 midSliceTopLeft;
	Vector2 getMidSliceTopLeft() { return midSliceTopLeft; }

	private Vector2 midSliceBottomRight;
	Vector2 getMidSliceBottomRight() { return midSliceBottomRight; }

	static S7_ZF_BoxTextures createSingleTexture(string tex, bool scaleTex) {
		let ret = new('S7_ZF_BoxTextures');

		ret.setSingleTexture(tex);
		ret.scaleMiddle = scaleTex;

		return ret;
	}

	static S7_ZF_BoxTextures createTexturePixels(
		string boxTex, Vector2 topLeft, Vector2 bottomRight, bool scaleSides,
		bool scaleMiddle
	) {
		let ret = new('S7_ZF_BoxTextures');

		ret.setTexturePixels(boxTex, topLeft, bottomRight);
		ret.scaleSides = scaleSides;
		ret.scaleMiddle = scaleMiddle;

		return ret;
	}

	static S7_ZF_BoxTextures createTextureNormalized(
		string boxTex, Vector2 topLeft, Vector2 bottomRight, bool scaleSides,
		bool scaleMiddle
	) {
		let ret = new('S7_ZF_BoxTextures');

		ret.setTextureNormalized(boxTex, topLeft, bottomRight);
		ret.scaleSides = scaleSides;
		ret.scaleMiddle = scaleMiddle;

		return ret;
	}

	private void setSingleTexture(string tex) {
		boxTexture = tex;

		midSliceTopLeft = (0, 0);
		midSliceBottomRight = (1, 1);
	}

	private void setTexturePixels(string boxTex, Vector2 topLeft, Vector2 bottomRight) {
		boxTexture = boxTex;

		Vector2 texSize = TexMan.getScaledSize(TexMan.checkForTexture(boxTexture, TexMan.Type_Any));
		midSliceTopLeft = (topLeft.x / texSize.x, topLeft.y / texSize.y);
		midSliceBottomRight = (bottomRight.x / texSize.x, bottomRight.y / texSize.y);
	}

	private void setTextureNormalized(string boxTex, Vector2 topLeft, Vector2 bottomRight) {
		boxTexture = boxTex;

		midSliceTopLeft = topLeft;
		midSliceBottomRight = bottomRight;
	}
}

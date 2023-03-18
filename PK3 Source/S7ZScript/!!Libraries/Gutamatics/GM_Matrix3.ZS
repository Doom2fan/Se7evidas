class S7_GM_Matrix3 {
	const ROWS = 3;
	const COLUMNS = 3;

	double values[ROWS][COLUMNS];

	/// Initialises a new Matrix3 in a static context.
	static S7_GM_Matrix3 create() {
		return new("S7_GM_Matrix3");
	}

	/// Returns an identity matrix.
	static S7_GM_Matrix3 identity() {
		let ret = S7_GM_Matrix3.create();
		ret.values[0][0] = 1;
		ret.values[1][1] = 1;
		ret.values[2][2] = 1;
		return ret;
	}

	/// Returns a rotation matrix.
	static S7_GM_Matrix3 rotate(double angle) {
		S7_GM_Matrix3 ret = S7_GM_Matrix3.identity();
		double s = sin(angle);
		double c = cos(angle);

		ret.values[0][0] = c;
		ret.values[0][1] = -s;

		ret.values[1][0] = s;
		ret.values[1][1] = c;

		return ret;
	}

	/// Returns a translation matrix.
	static S7_GM_Matrix3 translate(Vector2 translate) {
		S7_GM_Matrix3 ret = S7_GM_Matrix3.identity();
		ret.values[0][2] = translate.x;
		ret.values[1][2] = translate.y;

		return ret;
	}

	/// Returns a scaling matrix.
	static S7_GM_Matrix3 scale(Vector2 scale) {
		S7_GM_Matrix3 ret = S7_GM_Matrix3.create();
		ret.values[0][0] = scale.x;
		ret.values[1][1] = scale.y;
		ret.values[2][2] = 1.0;

		return ret;
	}

	static S7_GM_Matrix3 createTRS(Vector2 translate, double angle, Vector2 scale) {
		S7_GM_Matrix3 translateMat = S7_GM_Matrix3.identity();
		translateMat.values[0][2] = translate.x;
		translateMat.values[1][2] = translate.y;

		S7_GM_Matrix3 rotateMat = S7_GM_Matrix3.rotate(angle);

		S7_GM_Matrix3 scaleMat = S7_GM_Matrix3.identity();
		scaleMat.values[0][0] = scale.x;
		scaleMat.values[1][1] = scale.y;

		S7_GM_Matrix3 ret = translateMat.multiplyMatrix(rotateMat);
		ret = ret.multiplyMatrix(scaleMat);
		return ret;
	}

	S7_GM_Matrix3 clone() const {
		let ret = S7_GM_Matrix3.create();
		for (int r = 0; r < ROWS; r++) {
			for (int c = 0; c < COLUMNS; c++) {
				ret.values[r][c] = self.values[r][c];
			}
		}
		return ret;
	}

	S7_GM_Matrix3 transpose() const {
		let ret = S7_GM_Matrix3.create();
		for (int r = 0; r < ROWS; r++) {
			for (int c = 0; c < COLUMNS; c++) {
				ret.values[r][c] = self.values[c][r];
			}
		}
		return ret;
	}

	/// Adds two matrices and returns the result.
	S7_GM_Matrix3 addMatrix(S7_GM_Matrix3 other) const {
		S7_GM_Matrix3 ret = S7_GM_Matrix3.create();
		ret.values[0][0] = values[0][0] + other.values[0][0];
		ret.values[0][1] = values[0][1] + other.values[0][1];
		ret.values[0][2] = values[0][2] + other.values[0][2];

		ret.values[1][0] = values[1][0] + other.values[1][0];
		ret.values[1][1] = values[1][1] + other.values[1][1];
		ret.values[1][2] = values[1][2] + other.values[1][2];

		ret.values[2][0] = values[2][0] + other.values[2][0];
		ret.values[2][1] = values[2][1] + other.values[2][1];
		ret.values[2][2] = values[2][2] + other.values[2][2];
		return ret;
	}

	/// Multiplies the matrix by a scalar and returns the result.
	S7_GM_Matrix3 multiplyScalar(double scalar) const {
		S7_GM_Matrix3 ret = S7_GM_Matrix3.create();
		ret.values[0][0] = values[0][0] * scalar;
		ret.values[0][1] = values[0][1] * scalar;
		ret.values[0][2] = values[0][2] * scalar;

		ret.values[1][0] = values[1][0] * scalar;
		ret.values[1][1] = values[1][1] * scalar;
		ret.values[1][2] = values[1][2] * scalar;

		ret.values[2][0] = values[2][0] * scalar;
		ret.values[2][1] = values[2][1] * scalar;
		ret.values[2][2] = values[2][2] * scalar;
		return ret;
	}

	/// Multiplies two matrices and returns the result.
	S7_GM_Matrix3 multiplyMatrix(S7_GM_Matrix3 other) const {
		S7_GM_Matrix3 ret = S7_GM_Matrix3.create();
		for (int row = 0; row < ROWS; row++) {
			ret.values[row][0] =
				values[row][0] * other.values[0][0] +
				values[row][1] * other.values[1][0] +
				values[row][2] * other.values[2][0];

			ret.values[row][1] =
				values[row][0] * other.values[0][1] +
				values[row][1] * other.values[1][1] +
				values[row][2] * other.values[2][1];

			ret.values[row][2] =
				values[row][0] * other.values[0][2] +
				values[row][1] * other.values[1][2] +
				values[row][2] * other.values[2][2];
		}
		return ret;
	}

	/// Multiplies two matrices and returns the result, implicitly transposing the latter.
	S7_GM_Matrix3 multiplyTranspose(S7_GM_Matrix3 other) const {
		S7_GM_Matrix3 ret = S7_GM_Matrix3.create();
		for (int row = 0; row < ROWS; row++) {
			ret.values[row][0] =
				values[row][0] * other.values[0][0] +
				values[row][1] * other.values[0][1] +
				values[row][2] * other.values[0][2];

			ret.values[row][1] =
				values[row][0] * other.values[1][0] +
				values[row][1] * other.values[1][1] +
				values[row][2] * other.values[1][2];

			ret.values[row][2] =
				values[row][0] * other.values[2][0] +
				values[row][1] * other.values[2][1] +
				values[row][2] * other.values[2][2];
		}
		return ret;
	}

	/// Multiplies this Matrix by a 3D vector.
	Vector3 multiplyVector3(Vector3 vec) const {
		let ret = (
			values[0][0] * vec.x + values[0][1] * vec.y + values[0][2] * vec.z,
			values[1][0] * vec.x + values[1][1] * vec.y + values[1][2] * vec.z,
			values[2][0] * vec.x + values[2][1] * vec.y + values[2][2] * vec.z
		);

		return ret;
	}

	/// Multiplies this Matrix by a 2D vector.
	Vector2 multiplyVector2(Vector2 vec, S7_GM_VectorType type = S7_GM_Vector_Position, bool divideW = true) const {
		let vecZ = (type == S7_GM_Vector_Position) ? 1.0 : 0.0;

		let ret = (
			values[0][0] * vec.x + values[0][1] * vec.y + values[0][2] * vecZ,
			values[1][0] * vec.x + values[1][1] * vec.y + values[1][2] * vecZ
		);

		if (divideW) {
			let retW  = values[2][0] * vec.x + values[2][1] * vec.y + values[2][2] * vecZ;
			ret /= retW;
		}

		return ret;
	}

	void swapEntries(int r0, int c0, int r1, int c1) {
		let tmp = self.values[r0][c0];
		self.values[r0][c0] = self.values[r1][c1];
		self.values[r1][c1] = tmp;
	}

	void swapRows(int row0, int row1) {
		for (int i = 0; i < ROWS; i++) {
			self.swapEntries(row0, i, row1, i);
		}
	}

	S7_GM_Matrix3 inverse() const {
		let n = ROWS;
		let lhs = self.clone();
		let rhs = S7_GM_Matrix3.identity();
		for (int p = 0; p < n; p++) {
			let largestNum = abs(lhs.values[p][p]);
			let largestRow = p;
			for (int r = p + 1; r < n; r++) {
				let test = abs(lhs.values[r][p]);
				if (test > largestNum) {
					largestNum = test;
					largestRow = r;
				}
			}
			lhs.swapRows(p, largestRow);
			rhs.swapRows(p, largestRow);

			let pivot = lhs.values[p][p];
			let mul = 1.0 / pivot;

			for (int i = 0; i < n; i++) {
				lhs.values[p][i] = lhs.values[p][i] * mul;
				rhs.values[p][i] = rhs.values[p][i] * mul;
			}

			for (int r = 0; r < n; r++) {
				if (r == p) {
					continue;
				}
				let mul = lhs.values[r][p];
				for (int i = 0; i < n; i++) {
					lhs.values[r][i] = lhs.values[r][i] - mul * lhs.values[p][i];
					rhs.values[r][i] = rhs.values[r][i] - mul * rhs.values[p][i];
				}
			}
		}
		return rhs;
	}

	String repr() const {
		let scientific = false;
		for (let i = 0u; i < ROWS * COLUMNS; i++) {
			let val = self.values[i / COLUMNS][i % COLUMNS];
			scientific |= (abs(S7_GM_GlobalMaths.getDoubleExponent(val)) > 4);
			if (scientific) {
				break;
			}
		}
		Array<String> strs;
		for (let i = 0u; i < ROWS * COLUMNS; i++) {
			let val = self.values[i / COLUMNS][i % COLUMNS];
			let str = scientific ? String.format("%e", val) : String.format("%g", val);
			if (!scientific && val != double.infinity && val == val && str.indexOf(".") == -1) {
				str.appendFormat(".0");
			}
			strs.push(str);
		}
		Array<uint> pointIndices;
		let maxPointIndex = 0;
		for (let i = 0u; i < ROWS * COLUMNS; i++) {
			let str = strs[i];
			let pointIndex = str.indexOf(".");
			if (pointIndex == -1) {
				pointIndex = 0;
			}
			pointIndices.push(pointIndex);
			maxPointIndex = max(maxPointIndex, str.indexOf("."));
		}
		for (let i = 0u; i < ROWS * COLUMNS; i++) {
			let str = strs[i];
			strs[i] = String.format(
				"% " .. str.length() + (maxPointIndex - pointIndices[i]) .. "s",
				str
			);
		}
		let maxLength = 0;
		for (let i = 0u; i < self.values.size(); i++) {
			let str = strs[i];
			maxLength = max(maxLength, str.length());
		}

		String ret = "";
		let fmt = "%-" .. maxLength .. "s";
		for (let r = 0u; r < ROWS; r++) {
			ret.appendFormat(r == 0 ? "[[ " : "\n [ ");
			for (let c = 0u; c < COLUMNS; c++) {
				ret.appendFormat(fmt, strs[COLUMNS * r + c]);
				if (c != COLUMNS - 1) {
					ret.appendFormat(", ");
				}
			}
			ret.appendFormat(" ]");
			if (r != ROWS - 1) {
				ret.appendFormat(",");
			}
		}
		ret.appendFormat("]");
		return ret;
	}

	void toTransformInPlace(Shape2DTransform t) {
		t.from2D(
			self.values[0][0],
			self.values[0][1],
			self.values[1][0],
			self.values[1][1],

			self.values[0][2],
			self.values[1][2]
		);
	}

	Shape2DTransform toTransform() {
		let s = new("Shape2DTransform");
		self.toTransformInPlace(s);
		return s;
	}
}

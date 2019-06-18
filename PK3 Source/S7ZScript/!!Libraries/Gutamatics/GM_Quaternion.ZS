class S7_GM_Quaternion {
	double w, x, y, z;

	/// Initialises the Quaternion.
	S7_GM_Quaternion init(double w, double x, double y, double z) {
		self.w = w;
		self.x = x;
		self.y = y;
		self.z = z;

		return self;
	}

	/// Initialises the Quaternion in a static context.
	static S7_GM_Quaternion create(double w, double x, double y, double z) {
		return new("S7_GM_Quaternion").init(w, x, y, z);
	}

	/// Sets up the quaternion using axis and angle.
	void setAxisAngle(Vector3 axis, double angle) {
		double lengthSquared = axis dot axis;
		// avoid a division by 0 and just return the identity
		if (S7_GM_GlobalMaths.closeEnough(lengthSquared, 0)) {
			init(1, 0, 0, 0);
			return;
		}

		angle *= 0.5;

		double sinTheta = sin(angle);
		double cosTheta = cos(angle);
		double factor = sinTheta / sqrt(lengthSquared);

		w = cosTheta;
		x = factor * axis.x;
		y = factor * axis.y;
		z = factor * axis.z;
	}

	/// Initialises the Quaternion using axis and angle.
	S7_GM_Quaternion initFromAxisAngle(Vector3 axis, double angle) {
		setAxisAngle(axis, angle);
		return self;
	}

	/// Initialises the Quaternion using axis and angle in a static context.
	static S7_GM_Quaternion createFromAxisAngle(Vector3 axis, double angle) {
		return new("S7_GM_Quaternion").initFromAxisAngle(axis, angle);
	}

	/// Sets up the quaternion using euler angles.
	void setAngles(double yaw, double pitch, double roll) {
		S7_GM_Quaternion zRotation = new("S7_GM_Quaternion").initFromAxisAngle((0, 0, 1), yaw);
		S7_GM_Quaternion yRotation = new("S7_GM_Quaternion").initFromAxisAngle((0, 1, 0), pitch);
		S7_GM_Quaternion xRotation = new("S7_GM_Quaternion").initFromAxisAngle((1, 0, 0), roll);
		S7_GM_Quaternion finalRotation = zRotation.multiplyQuat(yRotation);
		finalRotation = finalRotation.multiplyQuat(xRotation);
		copy(finalRotation);
	}

	/// Initialises the quaternion using euler angles.
	S7_GM_Quaternion initFromAngles(double yaw, double pitch, double roll) {
		setAngles(yaw, pitch, roll);
		return self;
	}

	/// Initialises the quaternion using euler angles in a static context.
	static S7_GM_Quaternion createFromAngles(double yaw, double pitch, double roll) {
		return new("S7_GM_Quaternion").initFromAngles(yaw, pitch, roll);
	}

	/// Returns the euler angles from the Quaternion.
	double, double, double toAngles() {
		double singularityTest = z * x - w * y;
		double yawY = 2 * (w * z + x * y);
		double yawX = (1 - 2 * (y * y + z * z));

		double singularityThreshold = 0.4999995;

		double yaw = 0;
		double pitch = 0;
		double roll = 0;

		if (singularityTest < -singularityThreshold) {
			pitch = 90;
			yaw = atan2(yawY, yawX);
			roll = S7_GM_GlobalMaths.normalize180(yaw + (2 * atan2(x, w)));
		}
		else if (singularityTest > singularityThreshold) {
			pitch = -90;
			yaw = atan2(yawY, yawX);
			roll = S7_GM_GlobalMaths.normalize180(yaw + (2 * atan2(x, w)));
		}
		else {
			pitch = -asin(2 * singularityTest);
			yaw = atan2(yawY, yawX);
			roll = atan2(2 * (w * x + y * z), (1 - 2 * (x * x + y * y)));
		}

		return yaw, pitch, roll;
	}

	/// Returns the conjugate of the Quaternion.
	S7_GM_Quaternion conjugate() const {
		return new("S7_GM_Quaternion").init(w, -x, -y, -z);
	}

	/// Returns the normalised form of the Quaternion.
	S7_GM_Quaternion unit() const {
		double lengthSquared = w * w + x * x + y * y + z * z;
		if (S7_GM_GlobalMaths.closeEnough(lengthSquared, 0)) {
			return zero();
		}
		double factor = 1 / sqrt(lengthSquared);
		return new("S7_GM_Quaternion").init(w * factor, x * factor, y * factor, z * factor);
	}

	/// Returns the inverse of the Quaternion (equal to conjugate if normalised).
	S7_GM_Quaternion inverse() {
		double norm = w * w + x * x + y * y + z * z;
		// if this is a zero quaternion, just return self
		if (S7_GM_GlobalMaths.closeEnough(norm, 0)) {
			return self;
		}
		double inverseNorm = 1/norm;
		return new("S7_GM_Quaternion").init(w * inverseNorm, x * -inverseNorm, y * -inverseNorm, z * -inverseNorm);
	}

	/// Adds two Quaternions, returning the result.
	S7_GM_Quaternion add(S7_GM_Quaternion other) const {
		return new("S7_GM_Quaternion").init(w + other.w, x + other.x, y + other.y, z + other.z);
	}

	/// Subtracts two Quaternions, returning the result.
	S7_GM_Quaternion subtract(S7_GM_Quaternion other) const {
		return new("S7_GM_Quaternion").init(w - other.w, x - other.x, y - other.y, z - other.z);
	}

	/// Multiplies the Quaternion by a scalar, returning the result.
	S7_GM_Quaternion multiplyScalar(double scalar) const {
		return new("S7_GM_Quaternion").init(w * scalar, x * scalar, y * scalar, z * scalar);
	}

	/// Multiplies two Quaternions, returning the result.
	S7_GM_Quaternion multiplyQuat(S7_GM_Quaternion other) const {
		return new("S7_GM_Quaternion").init(w * other.w - x * other.x - y * other.y - z * other.z,
		                                   w * other.x + x * other.w + y * other.z - z * other.y,
		                                   w * other.y + y * other.w + z * other.x - x * other.z,
		                                   w * other.z + z * other.w + x * other.y - y * other.x );
	}

	/// Negates the Quaternion.
	S7_GM_Quaternion negate() const {
		return new("S7_GM_Quaternion").init(-w, -x, -y, -z);
	}

	/// Sets the values to 0 if they're close enough to 0.
	void clean() {
		if (S7_GM_GlobalMaths.closeEnough(w, 0)) w = 0;
		if (S7_GM_GlobalMaths.closeEnough(x, 0)) x = 0;
		if (S7_GM_GlobalMaths.closeEnough(y, 0)) y = 0;
		if (S7_GM_GlobalMaths.closeEnough(z, 0)) z = 0;
	}

	/// Returns the length of the Quaternion squared.
	double lengthSquared() const {
		return (w * w + x * x + y * y + z * z);
	}

	/// Returns the length of the Quaternion.
	double length() const {
		return sqrt(w * w + x * x + y * y + z * z);
	}

	/// Returns whether the two Quaternions are equal.
	bool equals(S7_GM_Quaternion other) const {
		return S7_GM_GlobalMaths.closeEnough(w, other.w) && S7_GM_GlobalMaths.closeEnough(x, other.x) &&
		       S7_GM_GlobalMaths.closeEnough(y, other.y) && S7_GM_GlobalMaths.closeEnough(z, other.z)   ;
	}

	/// Returns if the Quaternion is a 0 Quaternion.
	bool isZero() const {
		return S7_GM_GlobalMaths.closeEnough(w * w + x * x + y * y + z * z, 0);
	}

	/// Returns if the Quaternion is a unit Quaternion.
	bool isUnit() const {
		return S7_GM_GlobalMaths.closeEnough(w * w + x * x + y * y + z * z, 1);
	}

	/// Returns if the Quaternion is an identity Quaternion.
	bool isIdentity() const {
		return S7_GM_GlobalMaths.closeEnough(w, 1) && S7_GM_GlobalMaths.closeEnough(x, 0) &&
		       S7_GM_GlobalMaths.closeEnough(y, 0) && S7_GM_GlobalMaths.closeEnough(z, 0)   ;
	}

	/// Returns the dot product of two Quaternions.
	double dotProduct(S7_GM_Quaternion other) const {
		return (w * other.w + x * other.x + y * other.y + z * other.z);
	}

	/// Copies another Quaternion into this one.
	void copy(S7_GM_Quaternion other) {
		w = other.w;
		x = other.x;
		y = other.y;
		z = other.z;
	}

	/// Rotates a Vector3 using this Quaternion.
	Vector3 rotateVector3(Vector3 vec) const {
		S7_GM_Quaternion q = unit();

		Vector3 u = (q.x, q.y, q.z);
		double s = q.w;

		return 2 * (u dot vec) * u + (s * s - (u dot u)) * vec + 2 * s * u cross vec;
	}

	/// Linearly interpolates between two Quaternions, clamping the parameters.
	static S7_GM_Quaternion lerp(S7_GM_Quaternion from, S7_GM_Quaternion to, double time) {
		time = clamp(time, 0, 1);
		return lerpUnclamped(from, to, time);
	}

	/// Linearly interpolates between two Quaternions.
	static S7_GM_Quaternion lerpUnclamped(S7_GM_Quaternion from, S7_GM_Quaternion to, double time) {
		S7_GM_Quaternion ret = new("S7_GM_Quaternion");
		double reverseTime = 1 - time;
		ret.x = reverseTime * from.x + time * to.x;
		ret.y = reverseTime * from.y + time * to.y;
		ret.z = reverseTime * from.z + time * to.z;
		ret.w = reverseTime * from.w + time * to.w;
		ret = ret.unit();
		return ret;
	}

	/// Spherically interpolates between two Quaternions, clamping the parameters.
	static S7_GM_Quaternion slerp(S7_GM_Quaternion from, S7_GM_Quaternion to, double time) {
		time = clamp(time, 0, 1);
		return slerpUnclamped(from, to, time);
	}

	/// Spherically interpolates between two Quaternions.
	static S7_GM_Quaternion slerpUnclamped(S7_GM_Quaternion from, S7_GM_Quaternion to, double time) {
		S7_GM_Quaternion q3;
		double fromToDot = from.dotProduct(to);

		if (fromToDot < 0) {
			fromToDot = -fromToDot;
			q3 = to.negate();
		}
		else {
			q3 = to;
		}

		if (fromToDot < 0.95) {
			double angle = acos(fromToDot);
			return ((from.multiplyScalar(sin(angle * (1 - time)))).add(q3.multiplyScalar(sin(angle * time)))).multiplyScalar(1 / sin(angle));
		}
		else {
			return lerp(from, q3, time);
		}
	}

	/// Returns the 0 Quaternion.
	static S7_GM_Quaternion zero() {
		return new("S7_GM_Quaternion").init(0, 0, 0, 0);
	}

	/// Returns the identity Quaternion.
	static S7_GM_Quaternion identity() {
		return new("S7_GM_Quaternion").init(1, 0, 0, 0);
	}
}

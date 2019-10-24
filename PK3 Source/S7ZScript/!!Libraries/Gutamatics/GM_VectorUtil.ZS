/*
 * Copyright 2017 Jonathan Russell
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

class S7_GM_VectorUtil {
	/// Linearly interpolates between two Vector3s, clamping the parameters.
	static Vector3 lerpVec3(Vector3 from, Vector3 to, double time) {
		time = clamp(time, 0, 1);
		return lerpUnclampedVec3(from, to, time);
	}

	/// Linearly interpolates between two Vector3s.
	static Vector3 lerpUnclampedVec3(Vector3 from, Vector3 to, double time) {
		Vector3 ret;
		double reverseTime = 1 - time;
		ret = reverseTime * from + time * to;
		return ret;
	}

	/// Linearly interpolates between two Vector2s, clamping the parameters.
	static Vector2 lerpVec2(Vector2 from, Vector2 to, double time) {
		time = clamp(time, 0, 1);
		return lerpUnclampedVec2(from, to, time);
	}

	/// Linearly interpolates between two Vector2s.
	static Vector2 lerpUnclampedVec2(Vector2 from, Vector2 to, double time) {
		Vector2 ret;
		double reverseTime = 1 - time;
		ret = reverseTime * from + time * to;
		return ret;
	}
}
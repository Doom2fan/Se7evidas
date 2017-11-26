/// Bounding box class for positioning items.
class S7_ZF_AABB {
	Vector2 pos;
	Vector2 size;
	
	bool pointCollides(Vector2 point) {
		if (point.x > pos.x && point.x < pos.x + size.x &&
		    point.y > pos.y && point.y < pos.y + size.y   ) {
			return true;
		}
		return false;
	}
	
	S7_ZF_AABB rectOfIntersection(S7_ZF_AABB other) {
		double left = max(pos.x, other.pos.x);
		double right = min(pos.x + size.x, other.pos.x + other.size.x);
		double top = max(pos.y, other.pos.y);
		double bottom = min(pos.y + size.y, other.pos.y + other.size.y);
		if (right - left > 0 && bottom - top > 0) {
			S7_ZF_AABB ret = new("S7_ZF_AABB");
			ret.pos = (left, top);
			ret.size = (right - left, bottom - top);
			return ret;
		}
		return new("S7_ZF_AABB");
	}
}
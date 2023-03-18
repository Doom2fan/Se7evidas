class S7_GM_Hasher abstract {
	abstract virtualscope uint hash(Object o);
	abstract virtualscope bool eq(Object o0, Object o1);
	static void hashCombine(out uint seed, uint other) {
		seed ^= other + 0x9E3779B9 + (seed << 6) + (seed >> 2);
	}
}

class S7_GM_BoxedInt {
	int val;
	static S7_GM_BoxedInt create(int val) {
		let ret = new();
		ret.val = val;
		return ret;
	}
	S7_GM_BoxedInt clone() {
		let ret = new();
		ret.val = self.val;
		return ret;
	}
}
class S7_GM_IntHasher : S7_GM_Hasher {
	override uint hash(Object o) { return S7_GM_BoxedInt(o).val; }
	override bool eq(Object o0, Object o1) { return S7_GM_BoxedInt(o0).val == S7_GM_BoxedInt(o1).val; }
}

class S7_GM_BoxedUInt {
	uint val;
	static S7_GM_BoxedUInt create(uint val) {
		let ret = new();
		ret.val = val;
		return ret;
	}
	S7_GM_BoxedUInt clone() {
		let ret = new();
		ret.val = self.val;
		return ret;
	}
}
class S7_GM_UIntHasher : S7_GM_Hasher {
	override uint hash(Object o) { return S7_GM_BoxedUInt(o).val; }
	override bool eq(Object o0, Object o1) { return S7_GM_BoxedUInt(o0).val == S7_GM_BoxedUInt(o1).val; }
}

class S7_GM_BoxedDouble {
	double val;
	static S7_GM_BoxedDouble create(double val) {
		let ret = new();
		ret.val = val;
		return ret;
	}
	S7_GM_BoxedDouble clone() {
		let ret = new();
		ret.val = self.val;
		return ret;
	}
}

class S7_GM_BoxedString {
	String val;
	static S7_GM_BoxedString create(String val) {
		let ret = new();
		ret.val = val;
		return ret;
	}
	S7_GM_BoxedString clone() {
		let ret = new();
		ret.val = self.val;
		return ret;
	}
}

class S7_GM_HashSentinel {}

class S7_GM_HashUnoccupied {}

class S7_GM_KVStorage {
	Array<Object> keys;
	Array<Object> values;
	uint loadCount;

	S7_GM_HashUnoccupied unoccupied;

	S7_GM_HashSentinel empty;
	S7_GM_HashSentinel tombstone;

	Object get(Object key, S7_GM_Hasher hasher) {
		let hash = hasher.hash(key);
		let size = uint(self.keys.size());
		let index = hash % size;
		let i = index;
		while (true) {
			let kb = self.keys[i];
			if (kb == self.empty) {
				break;
			}
			if (kb != self.tombstone && hasher.eq(kb, key)) {
				return self.values[i];
			}
			i = (i + 1) % size;
		}
		return self.unoccupied;
	}

	S7_GM_KVStorage resized(uint newSize, S7_GM_Hasher hasher) {
		let newKV = new("S7_GM_KVStorage");
		newKV.keys.resize(newSize);
		newKV.values.resize(newSize);

		newKV.unoccupied = self.unoccupied;
		newKV.empty = self.empty;
		newKV.tombstone = self.tombstone;

		newKV.clear();

		for (let i = 0u; i < self.keys.size(); i++) {
			let k = self.keys[i];
			if (k != self.empty && k != self.tombstone) {
				newKV.insert(k, self.values[i], hasher);
			}
		}

		return newKV;
	}

	void insert(Object key, Object value, S7_GM_Hasher hasher) {
		let hash = hasher.hash(key);
		let size = uint(self.keys.size());
		let index = hash % size;
		{
			let i = index;
			while (true) {
				let kb = self.keys[i];
				if (kb == self.empty) {
					break;
				}
				if (kb != self.tombstone && hasher.eq(kb, key)) {
					self.values[i] = value;
					return;
				}
				i = (i + 1) % size;
			}
		}
		{
			let i = index;
			while (true) {
				let kb = self.keys[i];
				if (kb == self.empty || kb == self.tombstone) {
					self.keys[i] = key;
					self.values[i] = value;
					if (kb == self.empty) {
						self.loadCount += 1;
					}
					break;
				}
				i = (i + 1) % size;
			}
		}
	}

	Object remove(Object key, S7_GM_Hasher hasher) {
		let hash = hasher.hash(key);
		let size = uint(self.keys.size());
		{
			let index = hash % size;
			let i = index;
			while (true) {
				let kb = self.keys[i];
				if (kb == self.empty) {
					break;
				}
				if (kb != self.tombstone && hasher.eq(kb, key)) {
					let val = self.values[i];
					self.keys[i] = self.tombstone;
					self.values[i] = NULL;
					return val;
				}
				i = (i + 1) % size;
			}
		}
		return self.unoccupied;
	}

	bool isEmpty() {
		for (let i = 0u; i < self.keys.size(); i++) {
			let k = self.keys[i];
			if (k != self.empty && k != self.tombstone) {
				return false;
			}
		}
		return true;
	}

	void clear() {
		for (let i = 0u; i < self.keys.size(); i++) {
			self.keys[i] = self.empty;
			self.values[i] = NULL;
		}
		self.loadCount = 0u;
	}
}

class S7_GM_HashMapIterator {
	private S7_GM_KVStorage m;
	private uint i;

	static S7_GM_HashMapIterator internalCreate(S7_GM_KVStorage kv) {
		let ret = new();
		ret.m = kv;
		ret.i = 0;
		return ret;
	}

	Object, Object next() {
		while (self.i < m.keys.size()) {
			let k = m.keys[self.i];
			let v = m.values[self.i];
			self.i += 1;
			if (k != self.m.empty && k != self.m.tombstone) {
				return k, v;
			}
		}
		return self.m.unoccupied, NULL;
	}
}

class S7_GM_HashMap {
	private S7_GM_KVStorage kv;
	private S7_GM_Hasher hasher;

	static S7_GM_HashMap create(S7_GM_Hasher hasher) {
		let ret = new();
		ret.kv = new("S7_GM_KVStorage");
		ret.kv.keys.resize(8);
		ret.kv.values.resize(8);
		ret.kv.unoccupied = new("S7_GM_HashUnoccupied");
		ret.kv.empty = new("S7_GM_HashSentinel");
		ret.kv.tombstone = new("S7_GM_HashSentinel");
		ret.kv.clear();
		ret.hasher = hasher;
		return ret;
	}

	Object get(Object key) {
		return self.kv.get(key, self.hasher);
	}

	bool containsKey(Object key) {
		return !(self.kv.get(key, self.hasher) is "S7_GM_HashUnoccupied");
	}

	void resize(uint newSize) {
		self.kv = self.kv.resized(newSize, hasher);
	}

	void insert(Object key, Object value) {
		if (self.kv.loadCount + 1 > self.kv.keys.size() / 2) {
			self.resize(self.kv.keys.size() * 2);
		}
		self.kv.insert(key, value, self.hasher);
	}

	Object remove(Object key) {
		return self.kv.remove(key, self.hasher);
	}

	bool isEmpty() {
		return self.kv.isEmpty();
	}
	
	void clear() {
		self.kv.clear();
	}

	S7_GM_HashMapIterator iter() {
		return S7_GM_HashMapIterator.internalCreate(self.kv);
	}

	String debugRepr() {
		let ret = "";
		for (let i = 0u; i < self.kv.keys.size(); i++) {
			ret.appendFormat("%d : ", i);
			let k = self.kv.keys[i];
			if (k == self.kv.empty) {
				ret.appendFormat("EMPTY");
			} else if (k == self.kv.tombstone) {
				ret.appendFormat("TOMBSTONE");
			} else {
				ret.appendFormat("%p -> %p", k, self.kv.values[i]);
			}
			if (i != self.kv.keys.size() - 1) {
				ret.appendFormat("\n");
			}
		}
		return ret;
	}
}

class S7_GM_HashSetIterator {
	private S7_GM_HashMapIterator i;

	static S7_GM_HashSetIterator internalCreate(S7_GM_HashMapIterator i) {
		let ret = new();
		ret.i = i;
		return ret;
	}

	Object next() {
		return self.i.next();
	}
}

class S7_GM_HashSet {
	private S7_GM_HashMap hm;

	static S7_GM_HashSet create(S7_GM_Hasher hasher) {
		let ret = new();
		ret.hm = S7_GM_HashMap.create(hasher);
		return ret;
	}

	bool contains(Object key) {
		return self.hm.containsKey(key);
	}

	void resize(uint newSize) {
		self.hm.resize(newSize);
	}

	void insert(Object key) {
		self.hm.insert(key, NULL);
	}

	Object remove(Object key) {
		return self.hm.remove(key);
	}

	bool isEmpty() {
		return self.hm.isEmpty();
	}

	void clear() {
		self.hm.clear();
	}

	S7_GM_HashSetIterator iter() {
		return S7_GM_HashSetIterator.internalCreate(self.hm.iter());
	}

	String debugRepr() {
		return self.hm.debugRepr();
	}
}

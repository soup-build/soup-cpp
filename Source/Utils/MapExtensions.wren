
class MapExtensions {
	static Equal(lhs, rhs) {
		// System.print("Equal %(lhs) == %(rhs)")
		if (lhs is Null || rhs is Null) {
			return lhs is Null && rhs is Null
		}

		if (lhs.count != rhs.count) {
			return false
		}

		// Check that every key exists in both maps and the value is equal
		for (entry in lhs) {
			// System.print("SequenceEqual %(entry.key) %(entry.value)")
			if (!rhs.containsKey(entry.key) || !(entry.value == rhs[entry.key])) {
				return false
			}
		}

		return true
	}

	static EnsureList(parent, key) {
		if (!parent.containsKey(key)) {
			parent[key] = []
		}

		return parent[key]
	}

	static EnsureTable(parent, key) {
		if (!parent.containsKey(key)) {
			parent[key] = {}
		}

		return parent[key]
	}
}
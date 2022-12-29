
class ListExtensions {
	static SequenceEqual(lhs, rhs) {
		if (lhs.count != rhs) {
			return false
		}

		for (i in [0...lhs.count]) {
			if (lhs[i] != rhs[i]) {
				return false
			}
		}

		return true
	}
}
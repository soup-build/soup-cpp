
import "./Path" for Path

class ListExtensions {
	static SequenceEqual(lhs, rhs) {
		// System.print("SequenceEqual %(lhs) == %(rhs) %(lhs.count)")
		if (lhs is Null || rhs is Null) {
			return lhs is Null && rhs is Null
		}

		if (lhs.count != rhs.count) {
			return false
		}

		for (i in 0...lhs.count) {
			// System.print("SequenceEqual %(lhs[i]) == %(rhs[i])")
			if (!(lhs[i] == rhs[i])) {
				return false
			}
		}

		return true
	}

	static ConvertToPathList(list) {
		var result = []
		for (value in list) {
			result.add(Path.new(value.toString))
		}

		return result
	}

	static ConvertFromPathList(list) {
		var result = []
		for (value in list) {
			result.add(value.toString)
		}

		return result
	}

	static Append(target, source) {
		target = target + source
	}
}
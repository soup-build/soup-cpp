
class Set {
	construct new() {
		_list = []
	}

	list { _list }

	add(item) {
		var insertAddEnd = true
		for (index in 0..._list.count) {
			var current = _list[index]
			if (current == item) {
				// The value already exists
				insertAddEnd = false
				break
			}
		}

		if (insertAddEnd) {
			_list.add(item)
		}
	}

	contains(item) {
		for (current in _list) {
			if (current == item) {
				return true
			}
		}

		return false
	}
}
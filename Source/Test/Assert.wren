import "../Utils/ListExtensions" for ListExtensions

class Assert {
	static True(value) {
		if (!value) {
			Fiber.abort("Value must be true")
		}
	}

	static False(value) {
		if (value) {
			Fiber.abort("Value must be false")
		}
	}

	static ListEqual(expected, actual) {
		if (ListExtensions.SequenceEqual(expected, actual)) {
			Fiber.abort("Values must be equal [%(expected)] [%(actual)]")
		}
	}

	static Equal(expected, actual) {
		if (expected != actual) {
			Fiber.abort("Values must be equal [%(expected)] [%(actual)]")
		}
	}
}
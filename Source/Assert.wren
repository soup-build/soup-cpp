
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

	static Equal(expected, actual) {
		if (expected != actual) {
			Fiber.abort("Values must be equal [%(expected)] [%(actual)]")
		}
	}
}
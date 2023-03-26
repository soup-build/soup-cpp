Version: 4
Closures: {
	Root: {
		"C++": [
			{ Name: "copy", Version: "1.0.0", Build: "Build0" }
			{ Name: "mkdir", Version: "1.0.0", Build: "Build0" }
		]
		Wren: [
			{ Name: "Soup.Build.Utils", Version: "0.3.0", Build: "Build1" }
			{ Name: "Soup.Cpp", Version: "./", Build: "Build0" }
			{ Name: "Soup.Cpp.Compiler", Version: "0.6.1", Build: "Build1" }
			{ Name: "Soup.Cpp.Compiler.MSVC", Version: "0.6.0", Build: "Build1" }
		]
	}
	Build0: {
		Wren: [
			{ Name: "Soup.Cpp", Version: "0.6.2" }
			{ Name: "Soup.Wren", Version: "0.1.2" }
		]
	}
	Build1: {
		Wren: [
			{ Name: "Soup.Wren", Version: "0.1.2" }
		]
	}
}
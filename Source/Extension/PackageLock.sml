Version: 4
Closures: {
	Root: {
		Wren: [
			{ Name: "Soup.Build.Utils", Version: "0.4.0", Build: "Build0", Tool: "Tool0" }
			{ Name: "Soup.Cpp", Version: "../Extension", Build: "Build0", Tool: "Tool0" }
			{ Name: "Soup.Cpp.Compiler", Version: "0.7.0", Build: "Build0", Tool: "Tool0" }
			{ Name: "Soup.Cpp.Compiler.GCC", Version: "0.1.1", Build: "Build0", Tool: "Tool0" }
			{ Name: "Soup.Cpp.Compiler.MSVC", Version: "0.7.0", Build: "Build0", Tool: "Tool0" }
		]
	}
	Build0: {
		Wren: [
			{ Name: "Soup.Wren", Version: "0.2.0" }
		]
	}
	Tool0: {
		"C++": [
			{ Name: "copy", Version: "1.0.0" }
			{ Name: "mkdir", Version: "1.0.0" }
		]
	}
}
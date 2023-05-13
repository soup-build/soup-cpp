Version: 4
Closures: {
	Root: {
		Wren: [
			{ Name: "Soup.Build.Utils", Version: "0.4.1", Build: "Build0", Tool: "Tool0" }
			{ Name: "Soup.Cpp", Version: "./", Build: "Build0", Tool: "Tool0" }
			{ Name: "Soup.Cpp.Compiler", Version: "../Compiler/Core/", Build: "Build0", Tool: "Tool0" }
			{ Name: "Soup.Cpp.Compiler.Clang", Version: "../Compiler/Clang/", Build: "Build0", Tool: "Tool0" }
			{ Name: "Soup.Cpp.Compiler.GCC", Version: "../Compiler/GCC/", Build: "Build0", Tool: "Tool0" }
			{ Name: "Soup.Cpp.Compiler.MSVC", Version: "../Compiler/MSVC/", Build: "Build0", Tool: "Tool0" }
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
Version: 5
Closures: {
	Root: {
		Wren: {
			Cpp: { Version: './', Build: 'Build0', Tool: 'Tool0' }
			'Cpp.Compiler': { Version: '../compiler/core/', Build: 'Build0', Tool: 'Tool0' }
			'Cpp.Compiler.Clang': { Version: '../compiler/clang/', Build: 'Build0', Tool: 'Tool0' }
			'Cpp.Compiler.GCC': { Version: '../compiler/gcc/', Build: 'Build0', Tool: 'Tool0' }
			'Cpp.Compiler.MSVC': { Version: '../compiler/msvc/', Build: 'Build0', Tool: 'Tool0' }
			'Soup|Build.Utils': { Version: 0.9.1, Build: 'Build0', Tool: 'Tool0' }
			'Soup|Cpp': { Version: './', Build: 'Build0', Tool: 'Tool0' }
			'Soup|Cpp.Compiler': { Version: '../compiler/core/', Build: 'Build0', Tool: 'Tool0' }
			'Soup|Cpp.Compiler.Clang': { Version: '../compiler/clang/', Build: 'Build0', Tool: 'Tool0' }
			'Soup|Cpp.Compiler.GCC': { Version: '../compiler/gcc/', Build: 'Build0', Tool: 'Tool0' }
			'Soup|Cpp.Compiler.MSVC': { Version: '../compiler/msvc/', Build: 'Build0', Tool: 'Tool0' }
		}
	}
	Build0: {
		Wren: {
			'Soup|Wren': { Version: 0.5.4 }
		}
	}
	Tool0: {
		'C++': {
			'mwasplund|copy': { Version: 1.2.0 }
			'mwasplund|mkdir': { Version: 1.2.0 }
		}
	}
}
Version: 5
Closures: {
	Root: {
		Wren: {
			Cpp: { Version: './', Build: 'Build0', Tool: 'Tool0' }
			'Soup|Build.Utils': { Version: 0.8.0, Build: 'Build0', Tool: 'Tool0' }
			'Soup|Cpp': { Version: './', Build: 'Build0', Tool: 'Tool0' }
			'Soup|Cpp.Compiler': { Version: '../compiler/core/', Build: 'Build0', Tool: 'Tool0' }
			'Soup|Cpp.Compiler.Clang': { Version: '../compiler/clang/', Build: 'Build0', Tool: 'Tool0' }
			'Soup|Cpp.Compiler.GCC': { Version: '../compiler/gcc/', Build: 'Build0', Tool: 'Tool0' }
			'Soup|Cpp.Compiler.MSVC': { Version: '../compiler/msvc/', Build: 'Build0', Tool: 'Tool0' }
		}
	}
	Build0: {
		Wren: {
			'Soup|Wren': { Version: 0.4.3 }
		}
	}
	Tool0: {
		'C++': {
			'mwasplund|copy': { Version: 1.1.0 }
			'mwasplund|mkdir': { Version: 1.1.0 }
		}
	}
}
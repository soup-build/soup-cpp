Version: 5
Closures: {
	Root: {
		Wren: {
			'mwasplund|Soup.Build.Utils': { Version: '0.7.0', Build: 'Build0', Tool: 'Tool0' }
			'mwasplund|Soup.Cpp.Compiler': { Version: '../Compiler/Core/', Build: 'Build0', Tool: 'Tool0' }
			'mwasplund|Soup.Cpp.Compiler.Clang': { Version: '../Compiler/Clang/', Build: 'Build0', Tool: 'Tool0' }
			'mwasplund|Soup.Cpp.Compiler.GCC': { Version: '../Compiler/GCC/', Build: 'Build0', Tool: 'Tool0' }
			'mwasplund|Soup.Cpp.Compiler.MSVC': { Version: '../Compiler/MSVC/', Build: 'Build0', Tool: 'Tool0' }
			'mwasplund|Soup.Cpp': { Version: '../Extension', Build: 'Build0', Tool: 'Tool0' }
			'Soup.Cpp': { Version: '../Extension', Build: 'Build0', Tool: 'Tool0' }
		}
	}
	Build0: {
		Wren: {
			'mwasplund|Soup.Wren': { Version: '0.4.1' }
		}
	}
	Tool0: {
		'C++': {
			'mwasplund|copy': { Version: '1.1.0' }
			'mwasplund|mkdir': { Version: '1.1.0' }
		}
	}
}
Name: 'Soup.Cpp'
Language: 'Wren|0'
Version: '0.13.0'
Source: [
	'Tasks/BuildTask.wren'
	'Tasks/ExpandSourceTask.wren'
	'Tasks/InitializeDefaultsTask.wren'
	'Tasks/RecipeBuildTask.wren'
	'Tasks/ResolveDependenciesTask.wren'
	'Tasks/ResolveToolsTask.wren'
]

Dependencies: {
	Runtime: [
		'mwasplund|Soup.Cpp.Compiler@0'
		'mwasplund|Soup.Cpp.Compiler.Clang@0'
		'mwasplund|Soup.Cpp.Compiler.GCC@0'
		'mwasplund|Soup.Cpp.Compiler.MSVC@0'
		'mwasplund|Soup.Build.Utils@0'
	]
	Tool: [
		'[C++]mwasplund|copy@1'
		'[C++]mwasplund|mkdir@1'
	]
}
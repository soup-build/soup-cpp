Name: 'Cpp'
Language: 'Wren|0'
Version: 0.14.0
Source: [
	'tasks/BuildTask.wren'
	'tasks/ExpandSourceTask.wren'
	'tasks/InitializeDefaultsTask.wren'
	'tasks/ParseModuleFinalizerTask.wren'
	'tasks/RecipeBuildTask.wren'
	'tasks/ResolveDependenciesTask.wren'
	'tasks/ResolveToolsTask.wren'
]

Dependencies: {
	Runtime: [
		'Soup|Cpp.Compiler@0'
		'Soup|Cpp.Compiler.Clang@0'
		'Soup|Cpp.Compiler.GCC@0'
		'Soup|Cpp.Compiler.MSVC@0'
		'Soup|Build.Utils@0'
	]
	Tool: [
		'[C++]mwasplund|copy@1'
		'[C++]mwasplund|mkdir@1'
		'[C++]mwasplund|parse.module@1'
	]
}
Name: 'Cpp'
Language: 'Wren|0'
Version: 0.16.0
Source: [
	'tasks/build-task.wren'
	'tasks/expand-source-task.wren'
	'tasks/initialize-defaults-task.wren'
	'tasks/parse-module-preprocessor-task.wren'
	'tasks/recipe-build-task.wren'
	'tasks/resolve-dependencies-task.wren'
	'tasks/resolve-tools-task.wren'
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
		'[C++]mwasplund|parse.modules@1'
	]
}
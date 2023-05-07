Name: "Soup.Cpp"
Language: "Wren|0.1"
Version: "0.9.0"
Source: [
	"Tasks/BuildTask.wren"
	"Tasks/InitializeDefaultsTask.wren"
	"Tasks/RecipeBuildTask.wren"
	"Tasks/ResolveDependenciesTask.wren"
	"Tasks/ResolveToolsTask.wren"
]

Dependencies: {
	Runtime: [
		"Soup.Cpp.Compiler@0.8"
		"Soup.Cpp.Compiler.Clang@0.1"
		"Soup.Cpp.Compiler.GCC@0.2"
		"Soup.Cpp.Compiler.MSVC@0.8"
		"Soup.Build.Utils@0.3"
	]
	Tool: [
		"C++|copy@1.0"
		"C++|mkdir@1.0"
	]
}
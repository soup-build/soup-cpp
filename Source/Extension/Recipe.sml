Name: "Soup.Cpp"
Language: "Wren|0.1"
Version: "0.4.3"
Source: [
	"Tasks/BuildTask.wren"
	"Tasks/RecipeBuildTask.wren"
	"Tasks/ResolveDependenciesTask.wren"
	"Tasks/ResolveToolsTask.wren"
]

Dependencies: {
	Runtime: [
		"../Utils/"
		"../Compiler/Core/"
		"../Compiler/MSVC/"
	]
}
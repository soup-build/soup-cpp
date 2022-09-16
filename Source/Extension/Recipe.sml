Name: "Soup.Cpp"
Language: "C#|0.1"
Version: "0.3.0"
Source: [
	"Tasks/BuildTask.cs"
	"Tasks/RecipeBuildTask.cs"
	"Tasks/ResolveDependenciesTask.cs"
	"Tasks/ResolveToolsTask.cs"
]

Dependencies: {
	Runtime: [
		{ Reference: "Opal@1.1.0", }
		{ Reference: "Soup.Build@0.2.0", ExcludeRuntime: true, }
		{ Reference: "Soup.Build.Extensions@0.3.0", }
		{ Reference: "Soup.Build.Extensions.Utilities@0.3.0", }
		{ Reference: "Soup.Cpp.Compiler@0.4.0", }
		{ Reference: "Soup.Cpp.Compiler.MSVC@0.4.0", }
	]
}

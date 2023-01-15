Name: "Soup.Cpp.Compiler"
Language: "Wren|0.1"
Version: "0.5.1"
Source: [
	"BuildArguments.cs"
	"BuildEngine.cs"
	"BuildResult.cs"
	"CompileArguments.cs"
	"ICompiler.cs"
	"LinkArguments.cs"
	"MockCompiler.cs"
]

Dependencies: {
	Runtime: [
		{ Reference: "Opal@1.2.0" }
		{ Reference: "Soup.Build@0.2.0", ExcludeRuntime: true }
		{ Reference: "Soup.Build.Extensions@0.4.1" }
		{ Reference: "Soup.Build.Extensions.Utilities@0.4.1" }
	]
}
Name: "Soup.Cpp.Compiler"
Language: "Wren|0.1"
Version: "0.8.0"
Source: [
	"BuildArguments.wren"
	"BuildEngine.wren"
	"BuildResult.wren"
	"CompileArguments.wren"
	"ICompiler.wren"
	"LinkArguments.wren"
	"MockCompiler.wren"
]

Dependencies: {
	Runtime: [
		"Soup.Build.Utils@0.1"
	]
}
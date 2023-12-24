Name: "Soup.Cpp.Compiler"
Language: "Wren|0"
Version: "0.10.0"
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
		"Soup.Build.Utils@0"
	]
}
import "./Compiler/MSVC/Compiler" for Compiler
import "./Compiler/Core/BuildEngine" for BuildEngine

var compilerExecutable = "cl.exe"
var linkerExecutable = "link.exe"
var libraryExecutable = "lib.exe"
var rcExecutable = "rc.exe"
var mlExecutable = "ml.exe"

var compiler = Compiler.new(
	compilerExecutable,
	linkerExecutable,
	libraryExecutable,
	rcExecutable,
	mlExecutable)

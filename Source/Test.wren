import "./Compiler/MSVC/Compiler" for Compiler
import "./Compiler/Core/BuildArguments" for BuildArguments, BuildTargetType
import "./Compiler/Core/BuildEngine" for BuildEngine
import "./BuildState" for BuildState
import "./Path" for Path

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

var engine = BuildEngine.new(compiler)

var buildState = BuildState.new()

var targetName = "TestProject"
var targetArchitecture = "x64"
var targetType = BuildTargetType.StaticLibrary
var sourceRootDirectory = Path.new("source/")
var targetRootDirectory = Path.new("target/")
var objectDirectory = Path.new("obj/")
var binaryDirectory = Path.new("bin/")
var arguments = BuildArguments.new(
	targetName,
	targetArchitecture,
	targetType,
	sourceRootDirectory,
	targetRootDirectory,
	objectDirectory,
	binaryDirectory)

engine.Execute(buildState, arguments)
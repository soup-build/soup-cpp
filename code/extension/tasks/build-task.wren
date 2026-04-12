// <copyright file="build-task.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "soup|build-utils:./path" for Path
import "soup|build-utils:./set" for Set
import "soup|build-utils:./list-extensions" for ListExtensions
import "soup|build-utils:./map-extensions" for MapExtensions
import "soup|cpp-compiler:./build-arguments" for BuildArguments, BuildOptimizationLevel, SourceFile, HeaderFileSet
import "soup|cpp-compiler:./build-engine" for BuildEngine
import "soup|cpp-compiler-clang:./clang-compiler" for ClangCompiler
import "soup|cpp-compiler-gcc:./gcc-compiler" for GCCCompiler
import "soup|cpp-compiler-msvc:./msvc-compiler" for MSVCCompiler

class BuildTask is SoupTask {
	/// <summary>
	/// Get the run before list
	/// </summary>
	static runBefore { [] }

	/// <summary>
	/// Get the run after list
	/// </summary>
	static runAfter { [] }

	static registerCompiler(name, factory) {
		if (__compilerFactory is Null) __compilerFactory = {}
		__compilerFactory[name] = factory
	}

	/// <summary>
	/// The Core Execute task
	/// </summary>
	static evaluate() {
		// Register default compilers
		BuildTask.registerCompiler("Clang", BuildTask.createClangCompiler)
		BuildTask.registerCompiler("GCC", BuildTask.createGCCCompiler)
		BuildTask.registerCompiler("MSVC", BuildTask.createMSVCCompiler)

		var activeState = Soup.activeState
		var sharedState = Soup.sharedState

		var buildTable = activeState["Build"]

		// Check if this build should skip this system
		if (buildTable.containsKey("TargetSystems")) {
			var targetSystems = buildTable["TargetSystems"]
			var system = buildTable["System"]

			if (!targetSystems.contains(system)) {
				Soup.info("Target System is not supported: %(system)")
				return
			}
		}

		var arguments = BuildArguments.new()
		arguments.TargetArchitecture = buildTable["Architecture"]
		arguments.TargetName = buildTable["TargetName"]
		arguments.TargetType = buildTable["TargetType"]
		arguments.LanguageStandard = buildTable["LanguageStandard"]
		arguments.SourceRootDirectory = Path.new(buildTable["SourceRootDirectory"])
		arguments.TargetRootDirectory = Path.new(buildTable["TargetRootDirectory"])
		arguments.ObjectDirectory = Path.new(buildTable["ObjectDirectory"])
		arguments.BinaryDirectory = Path.new(buildTable["BinaryDirectory"])

		if (buildTable.containsKey("ResourcesFile")) {
			arguments.ResourceFile = Path.new(buildTable["ResourcesFile"])
		}

		if (buildTable.containsKey("Source")) {
			var sourceFiles = []
			for (source in buildTable["Source"]) {
				var file = Path.new(source["File"])
				var root = Path.new(source["Root"])

				var module = null
				if (source.containsKey("Module")) {
					module = source["Module"]
				}

				var isInterface = null
				if (source.containsKey("IsInterface")) {
					isInterface = source["IsInterface"]
				}

				var partition = null
				if (source.containsKey("Partition")) {
					partition = source["Partition"]
				}

				var imports = []
				if (source.containsKey("Imports")) {
					imports = source["Imports"]
				}

				sourceFiles.add(SourceFile.new(
					file,
					root,
					module,
					isInterface,
					partition,
					imports))
			}

			arguments.SourceFiles = sourceFiles
		}

		if (buildTable.containsKey("AssemblySource")) {
			arguments.AssemblySourceFiles = ListExtensions.ConvertToPathList(buildTable["AssemblySource"])
		}

		if (buildTable.containsKey("PublicHeaderSets")) {
			var publicHeaderSets = []
			for (value in buildTable["PublicHeaderSets"]) {
				var root = Path.new(value["Root"].toString)
				var target = null
				var files = ListExtensions.ConvertToPathList(value["Files"])

				if (value.containsKey("Target")) {
					target = Path.new(value["Target"].toString)
				}

				publicHeaderSets.add(HeaderFileSet.new(root, target, files))
			}

			arguments.PublicHeaderSets = publicHeaderSets
		}

		if (buildTable.containsKey("IncludeDirectories")) {
			arguments.IncludeDirectories = ListExtensions.ConvertToPathList(buildTable["IncludeDirectories"])
		}

		if (buildTable.containsKey("PublicIncludes")) {
			arguments.PublicIncludes = ListExtensions.ConvertToPathList(buildTable["PublicIncludes"])
		}

		if (buildTable.containsKey("PlatformLibraries")) {
			arguments.PlatformLinkDependencies = ListExtensions.ConvertToPathList(buildTable["PlatformLibraries"])
		}

		if (buildTable.containsKey("LinkLibraries")) {
			arguments.LinkDependencies = BuildTask.MakeUnique(ListExtensions.ConvertToPathList(buildTable["LinkLibraries"]))
		}

		if (buildTable.containsKey("LibraryPaths")) {
			arguments.LibraryPaths = ListExtensions.ConvertToPathList(buildTable["LibraryPaths"])
		}

		if (buildTable.containsKey("PreprocessorDefinitions")) {
			arguments.PreprocessorDefinitions = buildTable["PreprocessorDefinitions"]
		}

		if (buildTable.containsKey("OptimizationLevel")) {
			arguments.OptimizationLevel = buildTable["OptimizationLevel"]
		} else {
			arguments.OptimizationLevel = BuildOptimizationLevel.None
		}

		if (buildTable.containsKey("GenerateSourceDebugInfo")) {
			arguments.GenerateSourceDebugInfo = buildTable["GenerateSourceDebugInfo"]
		} else {
			arguments.GenerateSourceDebugInfo = false
		}

		// Load the runtime dependencies
		if (buildTable.containsKey("RuntimeDependencies")) {
			arguments.RuntimeDependencies = BuildTask.MakeUnique(ListExtensions.ConvertToPathList(buildTable["RuntimeDependencies"]))
		}

		// Load the link dependencies
		if (buildTable.containsKey("LinkDependencies")) {
			arguments.LinkDependencies = BuildTask.CombineUnique(
				arguments.LinkDependencies,
				ListExtensions.ConvertToPathList(buildTable["LinkDependencies"]))
		}

		// Load the module references
		if (buildTable.containsKey("ModuleDependencies")) {
			arguments.ModuleDependencies = MapExtensions.ConvertToPathMap(buildTable["ModuleDependencies"])
		}

		// Load the list of disabled warnings
		if (buildTable.containsKey("EnableWarningsAsErrors")) {
			arguments.EnableWarningsAsErrors = buildTable["EnableWarningsAsErrors"]
		} else {
			arguments.GenerateSourceDebugInfo = false
		}

		// Load the list of disabled warnings
		if (buildTable.containsKey("DisabledWarnings")) {
			arguments.DisabledWarnings = buildTable["DisabledWarnings"]
		}

		// Check for any custom compiler flags
		if (buildTable.containsKey("CustomCompilerProperties")) {
			arguments.CustomProperties = buildTable["CustomCompilerProperties"]
		}

		// Initialize the compiler to use
		var compilerName = buildTable["Compiler"]
		Soup.info("Using Compiler: %(compilerName)")
		if (!__compilerFactory.containsKey(compilerName)) {
			Fiber.abort("Unknown compiler: %(compilerName)")
		}

		var compiler = __compilerFactory[compilerName].call(activeState)

		var buildEngine = BuildEngine.new(compiler)
		var buildResult = buildEngine.Execute(arguments)

		// Pass along internal state for other stages to gain access
		buildTable["InternalLinkDependencies"] = ListExtensions.ConvertFromPathList(buildResult.InternalLinkDependencies)

		// Always pass along required input to shared build tasks
		var sharedBuildTable = MapExtensions.EnsureTable(sharedState, "Build")
		sharedBuildTable["ModuleDependencies"] = MapExtensions.ConvertFromPathMap(buildResult.ModuleDependencies)
		sharedBuildTable["RuntimeDependencies"] = ListExtensions.ConvertFromPathList(buildResult.RuntimeDependencies)
		sharedBuildTable["LinkDependencies"] = ListExtensions.ConvertFromPathList(buildResult.LinkDependencies)

		if (!(buildResult.TargetFile is Null)) {
			sharedBuildTable["TargetFile"] = buildResult.TargetFile.toString
			sharedBuildTable["RunExecutable"] = buildResult.TargetFile.toString
			sharedBuildTable["RunArguments"] = []
		}

		if (buildResult.PublicIncludes.count > 0) {
			sharedBuildTable["PublicIncludes"] = ListExtensions.ConvertFromPathList(buildResult.PublicIncludes)
		}

		// Register the build operations
		for (operation in buildResult.BuildOperations) {
			Soup.createOperation(
				operation.Title,
				operation.Executable.toString,
				operation.Arguments,
				operation.WorkingDirectory.toString,
				ListExtensions.ConvertFromPathList(operation.DeclaredInput),
				ListExtensions.ConvertFromPathList(operation.DeclaredOutput))
		}
		
		// Register the operation proxies
		for (operation in buildResult.OperationProxies) {
			Soup.createOperationProxy(
				operation.Title,
				operation.Executable.toString,
				operation.Arguments,
				operation.WorkingDirectory.toString,
				ListExtensions.ConvertFromPathList(operation.DeclaredInput),
				operation.ResultFile.toString,
				operation.FinalizerTask,
				operation.FinalizerState)
		}

		Soup.info("Build Generate Done")
	}

	static createClangCompiler {
		return Fn.new { |activeState|
			var clang = BuildTask.CheckGet(activeState, "Clang")
			var version = BuildTask.CheckGet(clang, "Version")
			var archiverToolPath = Path.new(BuildTask.CheckGet(clang, "Archiver"))
			var cppCompilerToolPath = Path.new(BuildTask.CheckGet(clang, "CppCompiler"))

			var cppScannerToolPath = null
			if (clang.containsKey("CppScanner")) {
				cppScannerToolPath = Path.new(clang["CppScanner"])
			}

			return ClangCompiler.new(
				version,
				archiverToolPath,
				cppCompilerToolPath,
				cppScannerToolPath)
		}
	}

	static createGCCCompiler {
		return Fn.new { |activeState|
			var gcc = activeState["GCC"]
			var gccToolPath = Path.new(gcc["CppCompiler"])
			return GCCCompiler.new(
				gccToolPath)
		}
	}

	static createMSVCCompiler {
		return Fn.new { |activeState|
			var msvc = activeState["MSVC"]
			var clToolPath = Path.new(msvc["ClToolPath"])
			var linkToolPath = Path.new(msvc["LinkToolPath"])
			var libToolPath = Path.new(msvc["LibToolPath"])
			var rcToolPath = Path.new(msvc["RCToolPath"])
			var mlToolPath = Path.new(msvc["MLToolPath"])
			return MSVCCompiler.new(
				clToolPath,
				linkToolPath,
				libToolPath,
				rcToolPath,
				mlToolPath)
		}
	}

	static CombineUnique(collection1, collection2) {
		var valueSet = Set.new()
		for (value in collection1) {
			valueSet.add(value.toString)
		}
		for (value in collection2) {
			valueSet.add(value.toString)
		}

		return ListExtensions.ConvertToPathList(valueSet.list)
	}

	static MakeUnique(collection) {
		var valueSet = Set.new()
		for (value in collection) {
			valueSet.add(value.toString)
		}

		return ListExtensions.ConvertToPathList(valueSet.list)
	}

	static CheckGet(values, key) {
		if (!values.containsKey(key)) {
			Fiber.abort("Missing key: %(key) %(values)")
		}

		return values[key]
	}
}
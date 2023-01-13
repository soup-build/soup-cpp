// <copyright file="BuildTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupExtension
import "../../Utils/Path" for Path
import "../../Utils/Set" for Set
import "../../Utils/ListExtensions" for ListExtensions
import "../../Utils/MapExtensions" for MapExtensions
import "../../Compiler/Core/BuildArguments" for BuildArguments, BuildOptimizationLevel, PartitionSourceFile
import "../../Compiler/Core/BuildEngine" for BuildEngine
import "../../Compiler/MSVC/MSVCCompiler" for MSVCCompiler

class BuildTask is SoupExtension {
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

	static evaluate() {
		// Register default compilers
		BuildTask.registerCompiler("MSVC", BuildTask.createMSVCCompiler)

		var globalState = Soup.globalState
		var activeState = Soup.activeState
		var sharedState = Soup.sharedState

		var buildTable = activeState["Build"]
		var parametersTable = globalState["Parameters"]

		var arguments = BuildArguments.new()
		arguments.TargetArchitecture = parametersTable["Architecture"]
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

		if (buildTable.containsKey("ModuleInterfacePartitionSourceFiles")) {
			var paritionTargets = []
			for (partition in buildTable["ModuleInterfacePartitionSourceFiles"]) {
				var partitionTable = partition

				var partitionImports = []
				if (partitionTable.containsKey("Imports")) {
					partitionImports = ListExtensions.ConvertToPathList(partitionTable["Imports"])
				}

				paritionTargets.add(PartitionSourceFile.new(
					Path.new(partitionTable["Source"]),
					partitionImports))
			}

			arguments.ModuleInterfacePartitionSourceFiles = paritionTargets
		}

		if (buildTable.containsKey("ModuleInterfaceSourceFile")) {
			arguments.ModuleInterfaceSourceFile = Path.new(buildTable["ModuleInterfaceSourceFile"])
		}

		if (buildTable.containsKey("Source")) {
			arguments.SourceFiles = ListExtensions.ConvertToPathList(buildTable["Source"])
		}

		if (buildTable.containsKey("AssemblySource")) {
			arguments.AssemblySourceFiles = ListExtensions.ConvertToPathList(buildTable["AssemblySource"])
		}

		if (buildTable.containsKey("IncludeDirectories")) {
			arguments.IncludeDirectories = ListExtensions.ConvertToPathList(buildTable["IncludeDirectories"])
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
			arguments.ModuleDependencies = BuildTask.MakeUnique(ListExtensions.ConvertToPathList(buildTable["ModuleDependencies"]))
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
		var compilerName = parametersTable["Compiler"]
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
		sharedBuildTable["ModuleDependencies"] = ListExtensions.ConvertFromPathList(buildResult.ModuleDependencies)
		sharedBuildTable["RuntimeDependencies"] = ListExtensions.ConvertFromPathList(buildResult.RuntimeDependencies)
		sharedBuildTable["LinkDependencies"] = ListExtensions.ConvertFromPathList(buildResult.LinkDependencies)

		if (!buildResult.TargetFile is Null) {
			sharedBuildTable["TargetFile"] = buildResult.TargetFile.toString
			sharedBuildTable["RunExecutable"] = buildResult.TargetFile.toString
			sharedBuildTable["RunArguments"] = []
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

		Soup.info("Build Generate Done")
	}

	static createMSVCCompiler {
		return Fn.new { |activeState|
			var clToolPath = Path.new(activeState["MSVC.ClToolPath"])
			var linkToolPath = Path.new(activeState["MSVC.LinkToolPath"])
			var libToolPath = Path.new(activeState["MSVC.LibToolPath"])
			var rcToolPath = Path.new(activeState["MSVC.RCToolPath"])
			var mlToolPath = Path.new(activeState["MSVC.MLToolPath"])
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
}

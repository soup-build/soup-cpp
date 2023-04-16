// <copyright file="BuildTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "Soup.Build.Utils:./Path" for Path
import "Soup.Build.Utils:./Set" for Set
import "Soup.Build.Utils:./ListExtensions" for ListExtensions
import "Soup.Build.Utils:./MapExtensions" for MapExtensions
import "Soup.Cpp.Compiler:./BuildArguments" for BuildArguments, BuildOptimizationLevel, PartitionSourceFile
import "Soup.Cpp.Compiler:./BuildEngine" for BuildEngine
import "Soup.Cpp.Compiler.Clang:./ClangCompiler" for ClangCompiler
import "Soup.Cpp.Compiler.GCC:./GCCCompiler" for GCCCompiler
import "Soup.Cpp.Compiler.MSVC:./MSVCCompiler" for MSVCCompiler

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

	static evaluate() {
		// Register default compilers
		BuildTask.registerCompiler("Clang", BuildTask.createClangCompiler)
		BuildTask.registerCompiler("GCC", BuildTask.createGCCCompiler)
		BuildTask.registerCompiler("MSVC", BuildTask.createMSVCCompiler)

		var activeState = Soup.activeState
		var sharedState = Soup.sharedState

		var buildTable = activeState["Build"]

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

		if (buildTable.containsKey("PublicHeaders")) {
			arguments.PublicHeaderFiles = ListExtensions.ConvertToPathList(buildTable["PublicHeaders"])
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
		var compilerName = buildTable["Compiler"]
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

		if (!(buildResult.TargetFile is Null)) {
			sharedBuildTable["TargetFile"] = buildResult.TargetFile.toString
			sharedBuildTable["RunExecutable"] = buildResult.TargetFile.toString
			sharedBuildTable["RunArguments"] = []
		}

		if (!(buildResult.PublicInclude is Null)) {
			sharedBuildTable["PublicInclude"] = buildResult.PublicInclude.toString
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

	static createClangCompiler {
		return Fn.new { |activeState|
			var clang = activeState["Clang"]
			var clToolPath = Path.new("/usr/bin/clang++")
			var linkToolPath = Path.new("/usr/bin/clang++")
			var libToolPath = Path.new("")
			var rcToolPath = Path.new("")
			var mlToolPath = Path.new("")
			return ClangCompiler.new(
				clToolPath,
				linkToolPath,
				libToolPath,
				rcToolPath,
				mlToolPath)
		}
	}

	static createGCCCompiler {
		return Fn.new { |activeState|
			var gcc = activeState["GCC"]
			var clToolPath = Path.new("/usr/bin/g++-12")
			var linkToolPath = Path.new("/usr/bin/g++-12")
			var libToolPath = Path.new("")
			var rcToolPath = Path.new("")
			var mlToolPath = Path.new("")
			return GCCCompiler.new(
				clToolPath,
				linkToolPath,
				libToolPath,
				rcToolPath,
				mlToolPath)
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
}

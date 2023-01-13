// <copyright file="RecipeBuildTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "../../Utils/Path" for Path
import "../../Utils/Set" for Set
import "../../Utils/ListExtensions" for ListExtensions
import "../../Utils/MapExtensions" for MapExtensions
import "../../Compiler/Core/BuildArguments" for BuildOptimizationLevel, BuildTargetType
import "../../Compiler/Core/CompileArguments" for LanguageStandard

/// <summary>
/// The recipe build task that knows how to build a single recipe
/// </summary>
class RecipeBuildTask is SoupTask {
	/// <summary>
	/// Get the run before list
	/// </summary>
	static runBefore { [
		"BuildTask",
	] }

	/// <summary>
	/// Get the run after list
	/// </summary>
	static runAfter { [
		"ResolveToolsTask",
	] }

	/// <summary>
	/// The Core Execute task
	/// </summary>
	static evaluate() {
		var globalState = Soup.globalState
		var activeState = Soup.activeState
		var parametersTable = globalState["Parameters"]
		var recipeTable = globalState["Recipe"]
		var buildTable = MapExtensions.EnsureTable(activeState, "Build")

		// Load the input properties
		var compilerName = parametersTable["Compiler"]
		var packageRoot = Path.new(parametersTable["PackageDirectory"])
		var buildFlavor = parametersTable["Flavor"]
		var platformLibraries = ListExtensions.ConvertToPathList(activeState["PlatformLibraries"])
		var platformIncludePaths = ListExtensions.ConvertToPathList(activeState["PlatformIncludePaths"])
		var platformLibraryPaths = ListExtensions.ConvertToPathList(activeState["PlatformLibraryPaths"])
		var platformPreprocessorDefinitions = activeState["PlatformPreprocessorDefinitions"]

		// Load Recipe properties
		var name = recipeTable["Name"]

		// Add any explicit platform dependencies that were added in the recipe
		if (recipeTable.containsKey("PlatformLibraries")) {
			for (value in ListExtensions.ConvertToPathList(recipeTable["PlatformLibraries"])) {
				platformLibraries.add(value)
			}
		}

		// Add the dependency static library closure to link if targeting an executable or dynamic library
		var linkLibraries = []
		if (recipeTable.containsKey("LinkLibraries")) {
			for (value in ListExtensions.ConvertToPathList(recipeTable["LinkLibraries"])) {
				// If relative then resolve to working directory
				if (value.HasRoot) {
					linkLibraries.add(value)
				} else {
					linkLibraries.add(packageRoot + value)
				}
			}
		}

		// Add the dependency runtime dependencies closure if present
		if (recipeTable.containsKey("RuntimeDependencies")) {
			var runtimeDependencies = []
			if (buildTable.containsKey("RuntimeDependencies")) {
				runtimeDependencies = ListExtensions.ConvertToPathList(buildTable["RuntimeDependencies"])
			}

			for (value in ListExtensions.ConvertToPathList(recipeTable["RuntimeDependencies"])) {
				// If relative then resolve to working directory
				if (value.HasRoot) {
					runtimeDependencies.add(value)
				} else {
					runtimeDependencies.add(packageRoot + value)
				}
			}

			MapExtensions.EnsureList(buildTable, "RuntimeDependencies").SetAll(runtimeDependencies)
		}

		// Combine the include paths from the recipe and the system
		var includePaths = []
		if (recipeTable.containsKey("IncludePaths")) {
			includePaths = ListExtensions.ConvertToPathList(recipeTable["IncludePaths"])
		}

		// Add the platform include paths
		includePaths = includePaths + platformIncludePaths

		// Load the extra library paths provided to the build system
		var libraryPaths = []

		// Add the platform library paths
		libraryPaths = libraryPaths + platformLibraryPaths

		// Combine the defines with the default set and the platform
		var preprocessorDefinitions = []
		if (recipeTable.containsKey("Defines")) {
			preprocessorDefinitions = recipeTable["Defines"]
		}

		preprocessorDefinitions = preprocessorDefinitions + platformPreprocessorDefinitions
		preprocessorDefinitions.add("SOUP_BUILD")

		// Build up arguments to build this individual recipe
		var targetDirectory = Path.new(parametersTable["TargetDirectory"])
		var binaryDirectory = Path.new("bin/")
		var objectDirectory = Path.new("obj/")

		// Load the resources file if present
		var resourcesFile
		if (recipeTable.containsKey("Resources")) {
			var resourcesFilePath = Path.new(recipeTable["Resources"])

			resourcesFile = resourcesFilePath.toString
		}

		// Load the module interface partition files if present
		var moduleInterfacePartitionSourceFiles = []
		if (recipeTable.containsKey("Partitions")) {
			for (partition in recipeTable["Partitions"]) {
				var targetPartitionTable = {}
				if (partition.IsString()) {
					targetPartitionTable["Source"] = partition
				} else if (partition.IsTable()) {
					var partitionTable = partition
					if (partitionTable.containsKey("Source")) {
						targetPartitionTable["Source"] = partitionTable["Source"]
					} else {
						Fiber.abort("Partition table missing Source")
					}

					if (partitionTable.containsKey("Imports")) {
						var partitionImports = partitionTable["Imports"]
						targetPartitionTable["Imports"] = partitionImports
					}
				} else {
					Fiber.abort("Unknown partition type.")
				}

				moduleInterfacePartitionSourceFiles.add(targetPartitionTable)
			}
		}

		// Load the module interface file if present
		var moduleInterfaceSourceFile
		if (recipeTable.containsKey("Interface")) {
			var moduleInterfaceSourceFilePath = Path.new(recipeTable["Interface"])

			// TODO: Clang requires annoying cppm extension
			if (compilerName == "Clang") {
				moduleInterfaceSourceFilePath.SetFileExtension("cppm")
			}

			moduleInterfaceSourceFile = moduleInterfaceSourceFilePath.toString
		}

		// Load the source files if present
		var sourceFiles = []
		if (recipeTable.containsKey("Source")) {
			sourceFiles = recipeTable["Source"]
		}

		// Load the assembly source files if present
		var assemblySourceFiles = []
		if (recipeTable.containsKey("AssemblySource")) {
			assemblySourceFiles = recipeTable["AssemblySource"]
		}

		// Check for warning settings
		var enableWarningsAsErrors = true
		if (recipeTable.containsKey("EnableWarningsAsErrors")) {
			enableWarningsAsErrors = recipeTable["EnableWarningsAsErrors"]
		}

		// Set the correct optimization level for the requested flavor
		var optimizationLevel = BuildOptimizationLevel.None
		var generateSourceDebugInfo = false
		if (buildFlavor == "debug") {
			// preprocessorDefinitions.pushthis.back("DEBUG")
			generateSourceDebugInfo = true
		} else if (buildFlavor == "debugrelease") {
			preprocessorDefinitions.add("RELEASE")
			generateSourceDebugInfo = true
			optimizationLevel = BuildOptimizationLevel.Speed
		} else if (buildFlavor == "release") {
			preprocessorDefinitions.add("RELEASE")
			optimizationLevel = BuildOptimizationLevel.Speed
		} else {
			Fiber.abort("Unknown build flavors type.")
		}

		buildTable["TargetName"] = name
		buildTable["SourceRootDirectory"] = packageRoot.toString
		buildTable["TargetRootDirectory"] = targetDirectory.toString
		buildTable["ObjectDirectory"] = objectDirectory.toString
		buildTable["BinaryDirectory"] = binaryDirectory.toString
		if (!(resourcesFile is Null)) {
			buildTable["ResourcesFile"] = resourcesFile
		}
		ListExtensions.Append(
			MapExtensions.EnsureList(buildTable, "ModuleInterfacePartitionSourceFiles"),
			moduleInterfacePartitionSourceFiles)
		if (!(moduleInterfaceSourceFile is Null)) {
			buildTable["ModuleInterfaceSourceFile"] = moduleInterfaceSourceFile
		}
		buildTable["OptimizationLevel"] = optimizationLevel
		buildTable["GenerateSourceDebugInfo"] = generateSourceDebugInfo

		ListExtensions.Append(
			MapExtensions.EnsureList(buildTable, "PlatformLibraries"),
			ListExtensions.ConvertFromPathList(platformLibraries))
		ListExtensions.Append(
			MapExtensions.EnsureList(buildTable, "LinkLibraries"),
			linkLibraries)
		ListExtensions.Append(
			MapExtensions.EnsureList(buildTable, "PreprocessorDefinitions"),
			preprocessorDefinitions)
		ListExtensions.Append(
			MapExtensions.EnsureList(buildTable, "IncludeDirectories"),
			includePaths)
		ListExtensions.Append(
			MapExtensions.EnsureList(buildTable, "LibraryPaths"),
			libraryPaths)
		ListExtensions.Append(
			MapExtensions.EnsureList(buildTable, "Source"),
			sourceFiles)
		ListExtensions.Append(
			MapExtensions.EnsureList(buildTable, "AssemblySource"),
			assemblySourceFiles)

		buildTable["EnableWarningsAsErrors"] = enableWarningsAsErrors

		// Convert the recipe type to the required build type
		var targetType = BuildTargetType.StaticLibrary
		if (recipeTable.containsKey("Type")) {
			targetType = RecipeBuildTask.ParseType(recipeTable["Type"])
		}

		buildTable["TargetType"] = targetType

		// Convert the recipe language version to the required build language
		var languageStandard = LanguageStandard.CPP20
		if (recipeTable.containsKey("LanguageVersion")) {
			languageStandard = RecipeBuildTask.ParseLanguageStandard(recipeTable["LanguageVersion"])
		}

		buildTable["LanguageStandard"] = languageStandard
	}

	static ParseType(value) {
		if (value == "Executable") {
			return BuildTargetType.Executable
		} else if (value == "Windows") {
			return BuildTargetType.WindowsApplication
		} else if (value == "StaticLibrary") {
			return BuildTargetType.StaticLibrary
		} else if (value == "DynamicLibrary") {
			return BuildTargetType.DynamicLibrary
		} else {
			Fiber.abort("Unknown target type value.")
		}
	}

	static ParseLanguageStandard(value) {
		if (value == "C++11") {
			return LanguageStandard.CPP11
		} else if (value == "C++14") {
			return LanguageStandard.CPP14
		} else if (value == "C++17") {
			return LanguageStandard.CPP17
		} else if (value == "C++20") {
			return LanguageStandard.CPP20
		} else {
			Fiber.abort("Unknown recipe language standard value.")
		}
	}
}

// <copyright file="RecipeBuildTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "Soup.Build.Utils:./Path" for Path
import "Soup.Build.Utils:./Set" for Set
import "Soup.Build.Utils:./ListExtensions" for ListExtensions
import "Soup.Build.Utils:./MapExtensions" for MapExtensions
import "Soup.Cpp.Compiler:./BuildArguments" for BuildOptimizationLevel, BuildTargetType
import "Soup.Cpp.Compiler:./CompileArguments" for LanguageStandard

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
		"InitializeDefaultsTask",
		"ResolveToolsTask",
	] }

	/// <summary>
	/// The Core Execute task
	/// </summary>
	static evaluate() {
		var globalState = Soup.globalState
		var activeState = Soup.activeState

		var context = globalState["Context"]
		var recipe = globalState["Recipe"]

		var build = MapExtensions.EnsureTable(activeState, "Build")

		// Load the input properties
		var compiler = build["Compiler"]
		var packageRoot = Path.new(context["PackageDirectory"])
		var flavor = build["Flavor"]

		var platformLibraries = []
		if (build.containsKey("PlatformLibraries")) {
			platformLibraries = ListExtensions.ConvertToPathList(build["PlatformLibraries"])
		}

		var platformIncludePaths = []
		if (build.containsKey("PlatformIncludePaths")) {
			platformIncludePaths = ListExtensions.ConvertToPathList(build["PlatformIncludePaths"])
		}

		var platformLibraryPaths = []
		if (build.containsKey("PlatformLibraryPaths")) {
			platformLibraryPaths = ListExtensions.ConvertToPathList(build["PlatformLibraryPaths"])
		}

		var platformPreprocessorDefinitions = []
		if (build.containsKey("PlatformPreprocessorDefinitions")) {
			platformPreprocessorDefinitions = build["PlatformPreprocessorDefinitions"]
		}

		// Load Recipe properties
		var name = recipe["Name"]

		// Add any explicit platform dependencies that were added in the recipe
		if (recipe.containsKey("PlatformLibraries")) {
			for (value in ListExtensions.ConvertToPathList(recipe["PlatformLibraries"])) {
				platformLibraries.add(value)
			}
		}

		// Add the dependency static library closure to link if targeting an executable or dynamic library
		var linkLibraries = []
		if (recipe.containsKey("LinkLibraries")) {
			for (value in ListExtensions.ConvertToPathList(recipe["LinkLibraries"])) {
				// If relative then resolve to working directory
				if (value.HasRoot) {
					linkLibraries.add(value)
				} else {
					linkLibraries.add(packageRoot + value)
				}
			}
		}

		// Add the dependency runtime dependencies closure if present
		if (recipe.containsKey("RuntimeDependencies")) {
			var runtimeDependencies = []
			if (build.containsKey("RuntimeDependencies")) {
				runtimeDependencies = ListExtensions.ConvertToPathList(build["RuntimeDependencies"])
			}

			for (value in ListExtensions.ConvertToPathList(recipe["RuntimeDependencies"])) {
				// If relative then resolve to working directory
				if (value.HasRoot) {
					runtimeDependencies.add(value)
				} else {
					runtimeDependencies.add(packageRoot + value)
				}
			}

			build["RuntimeDependencies"] = ListExtensions.ConvertFromPathList(runtimeDependencies)
		}

		// Combine the include paths from the recipe and the system
		var includePaths = []
		if (recipe.containsKey("IncludePaths")) {
			includePaths = ListExtensions.ConvertToPathList(recipe["IncludePaths"])
		}

		// Add the platform include paths
		includePaths = includePaths + platformIncludePaths

		// Load the extra library paths provided to the build system
		var libraryPaths = []

		// Add the platform library paths
		libraryPaths = libraryPaths + platformLibraryPaths

		// Combine the defines with the default set and the platform
		var preprocessorDefinitions = []
		if (recipe.containsKey("Defines")) {
			preprocessorDefinitions = recipe["Defines"]
		}

		preprocessorDefinitions = preprocessorDefinitions + platformPreprocessorDefinitions
		preprocessorDefinitions.add("SOUP_BUILD")

		// Build up arguments to build this individual recipe
		var targetDirectory = Path.new(context["TargetDirectory"])
		var binaryDirectory = Path.new("bin/")
		var objectDirectory = Path.new("obj/")

		// Load the resources file if present
		var resourcesFile
		if (recipe.containsKey("Resources")) {
			var resourcesFilePath = Path.new(recipe["Resources"])

			resourcesFile = resourcesFilePath.toString
		}

		// Load the module interface partition files if present
		var moduleInterfacePartitionSourceFiles = []
		if (recipe.containsKey("Partitions")) {
			for (partition in recipe["Partitions"]) {
				var targetPartitionTable = {}
				if (partition is String) {
					targetPartitionTable["Source"] = partition
				} else if (partition is Map) {
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
		if (recipe.containsKey("Interface")) {
			var moduleInterfaceSourceFilePath = Path.new(recipe["Interface"])
			moduleInterfaceSourceFile = moduleInterfaceSourceFilePath.toString
		}

		// Load the source files if present
		var sourceFiles = []
		if (recipe.containsKey("Source")) {
			sourceFiles = recipe["Source"]
		}

		// Load the assembly source files if present
		var assemblySourceFiles = []
		if (recipe.containsKey("AssemblySource")) {
			assemblySourceFiles = recipe["AssemblySource"]
		}

		// Load the public header files if present
		var publicHeaderFiles = []
		if (recipe.containsKey("PublicHeaders")) {
			publicHeaderFiles = recipe["PublicHeaders"]
		}

		// Check for warning settings
		var enableWarningsAsErrors = true
		if (recipe.containsKey("EnableWarningsAsErrors")) {
			enableWarningsAsErrors = recipe["EnableWarningsAsErrors"]
		}

		// Set the correct optimization level for the requested flavor
		var optimizationLevel = BuildOptimizationLevel.None
		var generateSourceDebugInfo = false
		if (flavor == "Debug") {
			// preprocessorDefinitions.pushthis.back("DEBUG")
			generateSourceDebugInfo = true
		} else if (flavor == "DebugRelease") {
			preprocessorDefinitions.add("RELEASE")
			generateSourceDebugInfo = true
			optimizationLevel = BuildOptimizationLevel.Speed
		} else if (flavor == "Release") {
			preprocessorDefinitions.add("RELEASE")
			optimizationLevel = BuildOptimizationLevel.Speed
		} else {
			Fiber.abort("Unknown build flavor: %(flavor)")
		}

		build["TargetName"] = name
		build["SourceRootDirectory"] = packageRoot.toString
		build["TargetRootDirectory"] = targetDirectory.toString
		build["ObjectDirectory"] = objectDirectory.toString
		build["BinaryDirectory"] = binaryDirectory.toString
		if (!(resourcesFile is Null)) {
			build["ResourcesFile"] = resourcesFile
		}
		ListExtensions.Append(
			MapExtensions.EnsureList(build, "ModuleInterfacePartitionSourceFiles"),
			moduleInterfacePartitionSourceFiles)
		if (!(moduleInterfaceSourceFile is Null)) {
			build["ModuleInterfaceSourceFile"] = moduleInterfaceSourceFile
		}
		build["OptimizationLevel"] = optimizationLevel
		build["GenerateSourceDebugInfo"] = generateSourceDebugInfo

		ListExtensions.Append(
			MapExtensions.EnsureList(build, "PlatformLibraries"),
			ListExtensions.ConvertFromPathList(platformLibraries))
		ListExtensions.Append(
			MapExtensions.EnsureList(build, "LinkLibraries"),
			ListExtensions.ConvertFromPathList(linkLibraries))
		ListExtensions.Append(
			MapExtensions.EnsureList(build, "PreprocessorDefinitions"),
			preprocessorDefinitions)
		ListExtensions.Append(
			MapExtensions.EnsureList(build, "IncludeDirectories"),
			ListExtensions.ConvertFromPathList(includePaths))
		ListExtensions.Append(
			MapExtensions.EnsureList(build, "LibraryPaths"),
			ListExtensions.ConvertFromPathList(libraryPaths))
		ListExtensions.Append(
			MapExtensions.EnsureList(build, "Source"),
			sourceFiles)
		ListExtensions.Append(
			MapExtensions.EnsureList(build, "AssemblySource"),
			assemblySourceFiles)
		ListExtensions.Append(
			MapExtensions.EnsureList(build, "PublicHeaders"),
			publicHeaderFiles)

		build["EnableWarningsAsErrors"] = enableWarningsAsErrors

		// Convert the recipe type to the required build type
		var targetType = BuildTargetType.StaticLibrary
		if (recipe.containsKey("Type")) {
			targetType = RecipeBuildTask.ParseType(recipe["Type"])
		}

		build["TargetType"] = targetType

		// Convert the recipe language version to the required build language
		var languageStandard = LanguageStandard.CPP20
		if (recipe.containsKey("LanguageVersion")) {
			languageStandard = RecipeBuildTask.ParseLanguageStandard(recipe["LanguageVersion"])
		}

		build["LanguageStandard"] = languageStandard
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

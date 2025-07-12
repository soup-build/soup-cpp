// <copyright file="parse-module-preprocessor-task.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupPreprocessorTask
import "Soup|Build.Utils:./glob" for Glob
import "Soup|Build.Utils:./path" for Path
import "Soup|Build.Utils:./list-extensions" for ListExtensions
import "Soup|Build.Utils:./shared-operations" for SharedOperations

class ParseModulePreprocessorTask is SoupPreprocessorTask {
	/// <summary>
	/// The Core Execute task
	/// </summary>
	static evaluate() {
		Soup.info("Finalizer")

		var globalState = Soup.globalState
		var recipe = globalState["Recipe"]

		var allowedPaths = []
		if (recipe.containsKey("Source")) {
			// Fill in the info on existing source files
			allowedPaths = ListExtensions.ConvertToPathList(recipe["Source"])
		} else {
			// Default to matching all C++ files under the root
			allowedPaths.add(Path.new("./**/*.cpp"))
		}

		// Expand the source from all discovered files
		Soup.info("Expand Source")
		var filesystem = globalState["FileSystem"]
		var sourceFiles = ParseModulePreprocessorTask.DiscoverCompileFiles(filesystem, Path.new(), allowedPaths)

		var context = globalState["Context"]
		var packageRoot = Path.new(context["PackageDirectory"])
		var targetDirectory = Path.new(context["TargetDirectory"])
		var objectDirectory = Path.new("obj/")

		// Discover the dependency tool
		var parseModuleExecutable = SharedOperations.ResolveRuntimeDependencyRunExecutable("mwasplund|parse.modules")

		// Ensure the output directories exists as the first step
		var createObjectDirectory = SharedOperations.CreateCreateDirectoryOperation(
			targetDirectory,
			objectDirectory)
		Soup.createOperation(
			createObjectDirectory.Title,
			createObjectDirectory.Executable.toString,
			createObjectDirectory.Arguments,
			createObjectDirectory.WorkingDirectory.toString,
			ListExtensions.ConvertFromPathList(createObjectDirectory.DeclaredInput),
			ListExtensions.ConvertFromPathList(createObjectDirectory.DeclaredOutput))

		for (sourceFile in sourceFiles) {
			var targetFile = targetDirectory + objectDirectory + Path.new(sourceFile.GetFileName())
			targetFile.SetFileExtension("txt")

			Soup.createOperation(
				"Scan %(sourceFile)",
				parseModuleExecutable,
				[
					targetFile.toString,
					sourceFile.toString,
				],
				packageRoot.toString,
				[
					sourceFile.toString,
				],
				[
					targetFile.toString,
				])
		}
	}

	static DiscoverCompileFiles(currentDirectory, workingDirectory, allowedPaths) {
		var files = []
		for (directoryEntity in currentDirectory) {
			if (directoryEntity is String) {
				var file = workingDirectory + Path.new(directoryEntity)
				Soup.info("Check File: %(file)")
				if (ParseModulePreprocessorTask.IsMatchAny(allowedPaths, file)) {
					files.add(file)
				}
			} else {
				for (child in directoryEntity) {
					var directory = workingDirectory + Path.new(child.key)
					Soup.info("Found Directory: %(directory)")
					var subFiles = ParseModulePreprocessorTask.DiscoverCompileFiles(child.value, directory, allowedPaths)
					ListExtensions.Append(files, subFiles)
				}
			}
		}

		return files
	}

	static IsMatchAny(allowedPaths, file) {
		for (allowedPath in allowedPaths) {
			if (Glob.IsMatch(allowedPath, file)) {
				return true
			}
		}

		return false
	}
}
// <copyright file="ParseModulePreprocessorTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupPreprocessorTask
import "Soup|Build.Utils:./Path" for Path
import "Soup|Build.Utils:./ListExtensions" for ListExtensions
import "Soup|Build.Utils:./SharedOperations" for SharedOperations

class ParseModulePreprocessorTask is SoupPreprocessorTask {
	/// <summary>
	/// The Core Execute task
	/// </summary>
	static evaluate() {
		Soup.info("Finalizer")

		var globalState = Soup.globalState

		Soup.info("Expand Source")
		var filesystem = globalState["FileSystem"]
		var sourceFiles = ParseModulePreprocessorTask.DiscoverCompileFiles(filesystem, Path.new())

		var context = globalState["Context"]
		var packageRoot = Path.new(context["PackageDirectory"])
		var targetDirectory = Path.new(context["TargetDirectory"])
		var objectDirectory = Path.new("obj/")

		// Discover the dependency tool
		var parseModuleExecutable = SharedOperations.ResolveRuntimeDependencyRunExecutable("mwasplund|parse.module")

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

	static DiscoverCompileFiles(currentDirectory, workingDirectory) {
		Soup.info("Discover Files %(workingDirectory)")
		var files = []
		for (directoryEntity in currentDirectory) {
			if (directoryEntity is String) {
				if (directoryEntity.endsWith(".cpp")) {
					var file = workingDirectory + Path.new(directoryEntity)
					Soup.info("Found Cpp File: %(file)")
					files.add(file)
				}
			} else {
				for (child in directoryEntity) {
					var directory = workingDirectory + Path.new(child.key)
					Soup.info("Found Directory: %(directory)")
					var subFiles = ParseModulePreprocessorTask.DiscoverCompileFiles(child.value, directory)
					ListExtensions.Append(files, subFiles)
				}
			}
		}

		return files
	}
}
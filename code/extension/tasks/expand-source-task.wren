// <copyright file="expand-source-task.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "soup|build-utils:./glob" for Glob
import "soup|build-utils:./path" for Path
import "soup|build-utils:./list-extensions" for ListExtensions
import "soup|build-utils:./map-extensions" for MapExtensions

/// <summary>
/// The expand source task that knows how to discover source files from the file system state
/// </summary>
class ExpandSourceTask is SoupTask {
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
		"RecipeBuildTask",
	] }

	/// <summary>
	/// The Core Execute task
	/// </summary>
	static evaluate() {
		var globalState = Soup.globalState
		var activeState = Soup.activeState

		var buildTable = activeState["Build"]
		ExpandSourceTask.expandSource(globalState, buildTable)
		ExpandSourceTask.expandPublicHeaderSets(globalState, buildTable)
	}

	static expandSource(globalState, buildTable) {
		var allowedPaths = []
		if (buildTable.containsKey("KnownSource")) {
			// Fill in the info on existing source files
			allowedPaths = ListExtensions.ConvertToPathList(buildTable["KnownSource"])
		} else {
			// Default to matching all C++ files under the root
			allowedPaths.add(Path.new("./**/*.cpp"))
		}

		var excludePaths = []
		if (buildTable.containsKey("KnownSourceExclude")) {
			// Fill in the info on existing excluded files
			excludePaths = ListExtensions.ConvertToPathList(buildTable["KnownSourceExclude"])
		}

		// Expand the source from all discovered files
		Soup.info("Expand Source")
		var filesystem = globalState["FileSystem"]
		var preprocessors = globalState["Preprocessors"]
		var sourceFiles = ExpandSourceTask.DiscoverCompileFiles(
			filesystem, Path.new(), preprocessors, allowedPaths, excludePaths)

		ListExtensions.Append(
			MapExtensions.EnsureList(buildTable, "Source"),
			sourceFiles)
	}

	static expandPublicHeaderSets(globalState, buildTable) {
		if (buildTable.containsKey("KnownPublicHeaderSets")) {
			// Expand the source from all discovered files
			Soup.info("Expand Public Header Sets")
			var filesystem = globalState["FileSystem"]

			var publicHeaderSets = []
			for (value in buildTable["KnownPublicHeaderSets"]) {
				var packageHeaderSet = {}
				var root = Path.new(value["Root"])
				packageHeaderSet["Root"] = root.toString
				if (value.containsKey("Target")) {
					packageHeaderSet["Target"] = value["Target"]
				}

				var allowedPaths = []
				if (value.containsKey("Files")) {
					// Fill in the info on existing files
					for (file in ListExtensions.ConvertToPathList(value["Files"])) {
						allowedPaths.add(root + file)
					}
				} else {
					// Default to matching all header files under the root
					allowedPaths.add(root + Path.new("./**/*.h"))
				}

				var headerFiles = ExpandSourceTask.DiscoverHeaderFiles(
					filesystem, Path.new(), allowedPaths)

				// Strip out the root so we can still resolve the final file path correctly
				var relativeHeaderFiles = []
				for (file in headerFiles) {
					relativeHeaderFiles.add(file.GetRelativeTo(root))
				}

				packageHeaderSet["Files"] = ListExtensions.ConvertFromPathList(relativeHeaderFiles)

				publicHeaderSets.add(packageHeaderSet)
			}

			ListExtensions.Append(
				MapExtensions.EnsureList(buildTable, "PublicHeaderSets"),
				publicHeaderSets)
		}
	}

	static DiscoverCompileFiles(
		currentDirectory, workingDirectory, preprocessors, allowedPaths, excludePaths) {
		var files = []
		for (directoryEntity in currentDirectory) {
			if (directoryEntity is String) {
				var file = workingDirectory + Path.new(directoryEntity)
				// Soup.info("Check File: %(file)")
				if (ExpandSourceTask.ShouldInclude(allowedPaths, excludePaths, file)) {
					files.add(ExpandSourceTask.CreateSourceInfo(file, preprocessors))
				}
			} else {
				for (child in directoryEntity) {
					var directory = workingDirectory + Path.new(child.key)
					// Soup.info("Found Directory: %(directory)")
					var subFiles = ExpandSourceTask.DiscoverCompileFiles(
						child.value, directory, preprocessors, allowedPaths, excludePaths)
					ListExtensions.Append(files, subFiles)
				}
			}
		}

		return files
	}

	static DiscoverHeaderFiles(currentDirectory, workingDirectory, allowedPaths) {
		var files = []
		for (directoryEntity in currentDirectory) {
			if (directoryEntity is String) {
				var file = workingDirectory + Path.new(directoryEntity)
				// Soup.info("Check File: %(file)")
				if (ExpandSourceTask.IsMatchAny(allowedPaths, file)) {
					files.add(file)
				}
			} else {
				for (child in directoryEntity) {
					var directory = workingDirectory + Path.new(child.key)
					// Soup.info("Found Directory: %(directory)")
					var subFiles = ExpandSourceTask.DiscoverHeaderFiles(
						child.value, directory, allowedPaths)
					ListExtensions.Append(files, subFiles)
				}
			}
		}

		return files
	}

	static ShouldInclude(allowedPaths, excludePaths, file) {
		if (ExpandSourceTask.IsMatchAny(allowedPaths, file)) {
			// If we matched included, check if there is an explicit exclude
			if (ExpandSourceTask.IsMatchAny(excludePaths, file)) {
				return false
			} else {
				return true
			}
		} else {
			return false
		}
	}

	static IsMatchAny(allowedPaths, file) {
		for (allowedPath in allowedPaths) {
			if (Glob.IsMatch(allowedPath, file)) {
				return true
			}
		}

		return false
	}

	static CreateSourceInfo(file, preprocessors) {
		Soup.info("Found Source File: %(file)")

		var preprocessorResult = ExpandSourceTask.ResolvePreprocessorResult(file, preprocessors)
		var result = preprocessorResult["Result"]

		var sourceInfo = {}
		sourceInfo["Root"] = "./"
		sourceInfo["File"] = file.toString
		sourceInfo["Imports"] = result["Imports"]

		if (result["IsModule"]) {
			var name = result["Name"]
			var module = name.split(":")
			sourceInfo["IsInterface"] = result["IsInterface"]
			sourceInfo["Module"] = module[0]
			if (module.count == 2) {
				sourceInfo["Partition"] = module[1]
			}
		}

		return sourceInfo
	}

	static ResolvePreprocessorResult(file, preprocessors) {
		var preprocessorName = "Scan %(file)"

		Soup.info("Preprocessor: %(preprocessorName)")
		for (preprocessor in preprocessors) {
			if (preprocessor["Title"] == preprocessorName) {
				return preprocessor
			}
		}

		Fiber.abort("Preprocessor result missing for %(file)")
	}
}
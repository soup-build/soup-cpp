﻿// <copyright file="ExpandSourceTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "Soup|Build.Utils:./Path" for Path
import "Soup|Build.Utils:./ListExtensions" for ListExtensions
import "Soup|Build.Utils:./MapExtensions" for MapExtensions

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

		Soup.info("Check Expand Source")
		if (!buildTable.containsKey("Source")) {
			Soup.info("Expand Source")
			var filesystem = globalState["FileSystem"]
			var preprocessors = globalState["Preprocessors"]
			var sourceFiles = ExpandSourceTask.DiscoverCompileFiles(filesystem, Path.new(), preprocessors)

			ListExtensions.Append(
				MapExtensions.EnsureList(buildTable, "Source"),
				sourceFiles)
		}
	}

	static DiscoverCompileFiles(currentDirectory, workingDirectory, preprocessors) {
		Soup.info("Discover Files %(workingDirectory)")
		var files = []
		for (directoryEntity in currentDirectory) {
			if (directoryEntity is String) {
				if (directoryEntity.endsWith(".cpp")) {
					files.add(ExpandSourceTask.CreateSourceInfo(workingDirectory, directoryEntity, preprocessors))
				}
			} else {
				for (child in directoryEntity) {
					var directory = workingDirectory + Path.new(child.key)
					Soup.info("Found Directory: %(directory)")
					var subFiles = ExpandSourceTask.DiscoverCompileFiles(child.value, directory, preprocessors)
					ListExtensions.Append(files, subFiles)
				}
			}
		}

		return files
	}

	static CreateSourceInfo(workingDirectory, directoryEntity, preprocessors) {
		var file = workingDirectory + Path.new(directoryEntity)
		Soup.info("Found Source File: %(file)")

		var sourceInfo = {}
		sourceInfo["File"] = file.toString
		var preprocessorResult = ExpandSourceTask.ResolvePreprocessorResult(file, preprocessors)
		var imports = []
		for (entry in preprocessorResult["Result"]) {
			var parseResult = entry.split(" ")
			if (parseResult.count == 0) {
				Fiber.abort("Found empty parse result")
			}

			var resultType = parseResult[0]
			if (resultType == "import") {
				if (parseResult.count == 2) {
					imports.add(parseResult[1])
				} else {
					Fiber.abort("Import result must have exactly two values")
				}
			} else if (resultType == "module") {
				if (parseResult.count == 2) {
					var module = parseResult[1].split(":")
					sourceInfo["Module"] = module[0]
					if (module.count == 2) {
						sourceInfo["Partition"] = module[1]
					}
				} else {
					Fiber.abort("Module result must have exactly two values")
				}

			} else {
				Fiber.abort("Unknown parser result type %(resultType)")
			}
		}

		sourceInfo["Imports"] = imports

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
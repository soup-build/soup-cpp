// <copyright file="expand-source-task.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "Soup|Build.Utils:./glob" for Glob
import "Soup|Build.Utils:./path" for Path
import "Soup|Build.Utils:./list-extensions" for ListExtensions
import "Soup|Build.Utils:./map-extensions" for MapExtensions

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

		var allowedPaths = []
		if (buildTable.containsKey("KnownSource")) {
			// Fill in the info on existing source files
			allowedPaths = ListExtensions.ConvertToPathList(buildTable["KnownSource"])
		} else {
			// Default to matching all C++ files under the root
			allowedPaths.add(Path.new("./**/*.cpp"))
		}

		// Expand the source from all discovered files
		Soup.info("Expand Source")
		var filesystem = globalState["FileSystem"]
		var preprocessors = globalState["Preprocessors"]
		var sourceFiles = ExpandSourceTask.DiscoverCompileFiles(filesystem, Path.new(), preprocessors, allowedPaths)

		ListExtensions.Append(
			MapExtensions.EnsureList(buildTable, "Source"),
			sourceFiles)
	}

	static DiscoverCompileFiles(currentDirectory, workingDirectory, preprocessors, allowedPaths) {
		var files = []
		for (directoryEntity in currentDirectory) {
			if (directoryEntity is String) {
				var file = workingDirectory + Path.new(directoryEntity)
				Soup.info("Check File: %(file)")
				if (ExpandSourceTask.IsMatchAny(allowedPaths, file)) {
					files.add(ExpandSourceTask.CreateSourceInfo(file, preprocessors))
				}
			} else {
				for (child in directoryEntity) {
					var directory = workingDirectory + Path.new(child.key)
					Soup.info("Found Directory: %(directory)")
					var subFiles = ExpandSourceTask.DiscoverCompileFiles(child.value, directory, preprocessors, allowedPaths)
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

	static CreateSourceInfo(file, preprocessors) {
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
			} else if (resultType == "module-implementation") {
				if (parseResult.count == 2) {
					var module = parseResult[1].split(":")
					sourceInfo["IsInterface"] = false
					sourceInfo["Module"] = module[0]
					if (module.count == 2) {
						sourceInfo["Partition"] = module[1]
					}
				} else {
					Fiber.abort("Module result must have exactly two values")
				}

			} else if (resultType == "module-interface") {
				if (parseResult.count == 2) {
					var module = parseResult[1].split(":")
					sourceInfo["IsInterface"] = true
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
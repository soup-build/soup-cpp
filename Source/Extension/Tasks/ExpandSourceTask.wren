// <copyright file="ResolveToolsTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "mwasplund|Soup.Build.Utils:./Path" for Path
import "mwasplund|Soup.Build.Utils:./ListExtensions" for ListExtensions
import "mwasplund|Soup.Build.Utils:./MapExtensions" for MapExtensions

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

		var sourceFiles = []
		if (buildTable.containsKey("Source")) {
			sourceFiles = ListExtensions.ConvertToPathList(buildTable["Source"])
		}

		if (sourceFiles.count == 0) {
			Soup.info("Expand Source: %(sourceFiles)")
			sourceFiles = ExpandSourceTask.DiscoverCompileFiles(globalState)

			ListExtensions.Append(
				MapExtensions.EnsureList(buildTable, "Source"),
				sourceFiles)
		}
	}

	static DiscoverCompileFiles(globalState) {
		var files = []
		var filesystem = globalState["FileSystem"]
		for (directoryEntity in filesystem) {
			if (directoryEntity.endsWith(".cpp")) {
				Soup.info("Found Cpp File: %(directoryEntity)")
				files.add(directoryEntity)
			}
		}

		return files
	}
}

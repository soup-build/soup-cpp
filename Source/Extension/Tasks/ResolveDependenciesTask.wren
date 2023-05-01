// <copyright file="ResolveToolsTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "Soup.Build.Utils:./ListExtensions" for ListExtensions
import "Soup.Build.Utils:./MapExtensions" for MapExtensions

/// <summary>
/// The resolve dependencies build task that knows how to combine all previous state
/// into the active state.
/// </summary>
class ResolveDependenciesTask is SoupTask {
	/// <summary>
	/// Get the run before list
	/// </summary>
	static runBefore { [
		"BuildTask",
	] }

	/// <summary>
	/// Get the run after list
	/// </summary>
	static runAfter { [] }

	/// <summary>
	/// The Core Execute task
	/// </summary>
	static evaluate() {
		var activeState = Soup.activeState
		var globalState = Soup.globalState

		if (globalState.containsKey("Dependencies")) {
			var dependenciesTable = globalState["Dependencies"]
			if (dependenciesTable.containsKey("Runtime")) {
				var runtimeDependenciesTable = dependenciesTable["Runtime"]
				var buildTable = MapExtensions.EnsureTable(activeState, "Build")

				for (dependencyName in runtimeDependenciesTable.keys) {
					// Combine the core dependency build inputs for the core build task
					Soup.info("Combine Runtime Dependency: %(dependencyName)")
					var dependencyTable = runtimeDependenciesTable[dependencyName]
					var dependencySharedStateTable = dependencyTable["SharedState"]

					if (dependencySharedStateTable.containsKey("Build")) {
						var dependencyBuildTable = dependencySharedStateTable["Build"]

						if (dependencyBuildTable.containsKey("ModuleDependencies")) {
							var moduleDependencies = dependencyBuildTable["ModuleDependencies"]
							ListExtensions.Append(
								MapExtensions.EnsureList(buildTable, "ModuleDependencies"),
								moduleDependencies)
						}

						if (dependencyBuildTable.containsKey("RuntimeDependencies")) {
							var runtimeDependencies = dependencyBuildTable["RuntimeDependencies"]
							ListExtensions.Append(
								MapExtensions.EnsureList(buildTable, "RuntimeDependencies"),
								runtimeDependencies)
						}

						if (dependencyBuildTable.containsKey("LibraryPaths")) {
							var libraryPaths = dependencyBuildTable["LibraryPaths"]
							ListExtensions.Append(
								MapExtensions.EnsureList(buildTable, "LibraryPaths"),
								libraryPaths)
						}

						if (dependencyBuildTable.containsKey("LinkStaticLibraryNames")) {
							var linkStaticLibraryNames = dependencyBuildTable["LinkStaticLibraryNames"]
							ListExtensions.Append(
								MapExtensions.EnsureList(buildTable, "LinkStaticLibraryNames"),
								linkStaticLibraryNames)
						}

						if (dependencyBuildTable.containsKey("LinkStaticLibraries")) {
							var linkStaticLibraries = dependencyBuildTable["LinkStaticLibraries"]
							ListExtensions.Append(
								MapExtensions.EnsureList(buildTable, "LinkStaticLibraries"),
								linkStaticLibraries)
						}

						if (dependencyBuildTable.containsKey("LinkDynamicLibraries")) {
							var linkDynamicLibraries = dependencyBuildTable["LinkDynamicLibraries"]
							ListExtensions.Append(
								MapExtensions.EnsureList(buildTable, "LinkDynamicLibraries"),
								linkDynamicLibraries)
						}

						if (dependencyBuildTable.containsKey("PublicInclude")) {
							var publicInclude = dependencyBuildTable["PublicInclude"]
							MapExtensions.EnsureList(buildTable, "IncludeDirectories").add(publicInclude)
						}
					}
				}
			}
		}
	}
}

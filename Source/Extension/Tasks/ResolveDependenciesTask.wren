// <copyright file="ResolveToolsTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupExtension
import "../../Utils/MapExtensions" for MapExtensions

/// <summary>
/// The resolve dependencies build task that knows how to combine all previous state
/// into the active state.
/// </summary>
class ResolveDependenciesTask is SoupExtension {
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

		if (activeState.containsKey("Dependencies")) {
			var dependenciesTable = activeState["Dependencies"]
			if (dependenciesTable.containsKey("Runtime")) {
				var runtimeDependenciesTable = dependenciesTable["Runtime"]
				var buildTable = MapExtensions.EnsureTable(activeState.EnsureValueTable, "Build")

				for ( dependencyName in runtimeDependenciesTable.Keys) {
					// Combine the core dependency build inputs for the core build task
					Soup.info("Combine Runtime Dependency: %(dependencyName)")
					var dependencyTable = runtimeDependenciesTable[dependencyName]

					if (dependencyTable.containsKey("Build")) {
						var dependencyBuildTable = dependencyTable["Build"]

						if (dependencyBuildTable.containsKey("ModuleDependencies")) {
							var moduleDependencies = dependencyBuildTable["ModuleDependencies"]
							MapExtensions.EnsureList(buildTable, "ModuleDependencies").Append(moduleDependencies)
						}

						if (dependencyBuildTable.containsKey("RuntimeDependencies")) {
							var runtimeDependencies = dependencyBuildTable["RuntimeDependencies"]
							MapExtensions.EnsureList(buildTable, "RuntimeDependencies").Append(runtimeDependencies)
						}

						if (dependencyBuildTable.containsKey("LinkDependencies")) {
							var linkDependencies = dependencyBuildTable["LinkDependencies"]
							MapExtensions.EnsureList(buildTable, "LinkDependencies").Append(linkDependencies)
						}
					}
				}
			}
		}
	}
}

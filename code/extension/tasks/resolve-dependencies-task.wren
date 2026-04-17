// <copyright file="resolve-dependencies-task.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "soup|build-utils:./list-extensions" for ListExtensions
import "soup|build-utils:./map-extensions" for MapExtensions
import "soup|build-utils:./semantic-version" for SemanticVersion

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
				var moduleDependencies = MapExtensions.EnsureTable(buildTable, "ModuleDependencies")
				var publicIncludes = MapExtensions.EnsureList(buildTable, "PublicIncludes")
				var runtimeDependencies = MapExtensions.EnsureList(buildTable, "RuntimeDependencies")
				var linkDependencies = MapExtensions.EnsureList(buildTable, "LinkDependencies")

				for (dependencyName in runtimeDependenciesTable.keys) {
					// Combine the core dependency build inputs for the core build task
					Soup.info("Combine Runtime Dependency: %(dependencyName)")
					var dependencyTable = runtimeDependenciesTable[dependencyName]
					var dependencySharedStateTable = dependencyTable["SharedState"]

					ResolveDependenciesTask.resolveRuntimeDependency(
						dependencyName, dependencySharedStateTable, moduleDependencies, publicIncludes, runtimeDependencies, linkDependencies)
				}
			}
		}
	}

	static resolveRuntimeDependency(dependencyName, dependencySharedState, moduleDependencies, publicIncludes, runtimeDependencies, linkDependencies) {
		if (!(dependencySharedState.containsKey("Language"))) {
			Fiber.abort("Missing required shared state Language, we do not know how to process %(dependencyName)")
		}

		if (!(dependencySharedState.containsKey("Version"))) {
			Fiber.abort("Missing required shared state Version, we do not know how to process: %(dependencyName)")
		}

		var language = dependencySharedState["Language"]
		var version = SemanticVersion.Parse(dependencySharedState["Version"])

		if (language == "C++") {
			ResolveDependenciesTask.resolveCPPRuntimeDependency(
				dependencyName, version, dependencySharedState, moduleDependencies, publicIncludes, runtimeDependencies, linkDependencies)
		} else if (language == "C") {
			ResolveDependenciesTask.resolveCRuntimeDependency(
				dependencyName, version, dependencySharedState, publicIncludes, runtimeDependencies, linkDependencies)
		} else {
			Fiber.abort("Unknown language %(language) for dependency %(dependencyName)")
		}
	}

	static resolveCPPRuntimeDependency(
		dependencyName, version, dependencySharedState, moduleDependencies, publicIncludes, runtimeDependencies, linkDependencies) {
		if (!(dependencySharedState.containsKey("Build"))) {
			Fiber.abort("C++ dependency missing Build table %(dependencyName)")
		}

		var requiredLanguageVersion = SemanticVersion.new(1, 0, 0)
		if (!(SemanticVersion.IsUpCompatible(version, requiredLanguageVersion))) {
			Fiber.abort("Incompatible C++ version %(version)")
		}

		var dependencyBuildTable = dependencySharedState["Build"]

		if (dependencyBuildTable.containsKey("ModuleDependencies")) {
			var dependencyModuleDependencies = dependencyBuildTable["ModuleDependencies"]
			MapExtensions.Append(
				moduleDependencies,
				dependencyModuleDependencies)
		}

		if (dependencyBuildTable.containsKey("RuntimeDependencies")) {
			var dependencyRuntimeDependencies = dependencyBuildTable["RuntimeDependencies"]
			ListExtensions.Append(
				runtimeDependencies,
				dependencyRuntimeDependencies)
		}

		if (dependencyBuildTable.containsKey("LinkDependencies")) {
			var dependencyLinkDependencies = dependencyBuildTable["LinkDependencies"]
			ListExtensions.Append(
				linkDependencies,
				dependencyLinkDependencies)
		}

		if (dependencyBuildTable.containsKey("PublicIncludes")) {
			var dependencyPublicIncludes = dependencyBuildTable["PublicIncludes"]
			MapExtensions.Append(
				publicIncludes,
				dependencyPublicIncludes)
		}
	}

	static resolveCRuntimeDependency(
		dependencyName, version, dependencySharedState, publicIncludes, runtimeDependencies, linkDependencies) {
		if (!(dependencySharedState.containsKey("Build"))) {
			Fiber.abort("C dependency missing Build table %(dependencyName)")
		}

		var requiredLanguageVersion = SemanticVersion.new(1, 0, 0)
		if (!(SemanticVersion.IsUpCompatible(version, requiredLanguageVersion))) {
			Fiber.abort("Incompatible C version %(version)")
		}

		var dependencyBuildTable = dependencySharedState["Build"]

		if (dependencyBuildTable.containsKey("RuntimeDependencies")) {
			var dependencyRuntimeDependencies = dependencyBuildTable["RuntimeDependencies"]
			ListExtensions.Append(
				runtimeDependencies,
				dependencyRuntimeDependencies)
		}

		if (dependencyBuildTable.containsKey("LinkDependencies")) {
			var dependencyLinkDependencies = dependencyBuildTable["LinkDependencies"]
			ListExtensions.Append(
				linkDependencies,
				dependencyLinkDependencies)
		}

		if (dependencyBuildTable.containsKey("PublicIncludes")) {
			var dependencyPublicIncludes = dependencyBuildTable["PublicIncludes"]
			ListExtensions.Append(
				publicIncludes,
				dependencyPublicIncludes)
		}
	}
}

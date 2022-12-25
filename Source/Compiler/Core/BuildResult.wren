// <copyright file="BuildResult.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

/// <summary>
/// The build result
/// </summary>
class BuildResult {
	construct new() {
	}

	/// <summary>
	/// Gets or sets the resulting root build operations
	/// </summary>
	BuildOperations {}

	/// <summary>
	/// Gets or sets the list of module dependencies
	/// </summary>
	ModuleDependencies { _moduleDependencies }
	ModuleDependencies=(value) { _moduleDependencies = value }

	/// <summary>
	/// Gets or sets the list of link libraries that downstream builds should use when linking
	/// </summary>
	LinkDependencies {}

	/// <summary>
	/// Gets or sets the list of internal link libraries that were used to link the final result
	/// </summary>
	InternalLinkDependencies {}

	/// <summary>
	/// Gets or sets the list of runtime dependencies
	/// </summary>
	RuntimeDependencies {}

	/// <summary>
	/// Gets or sets the target file for the build
	/// </summary>
	TargetFile {}
}

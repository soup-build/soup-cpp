// <copyright file="build-result.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

/// <summary>
/// The build result
/// </summary>
class BuildResult {
	construct new() {
		_buildOperations = []
		_operationProxies = []
		_moduleDependencies = {}
		_linkDependencies = []
		_internalLinkDependencies = []
		_runtimeDependencies = []
		_runtimeDependencies = []
		_targetFile = null
	}

	/// <summary>
	/// Gets or sets the resulting root build operations
	/// </summary>
	BuildOperations { _buildOperations }
	BuildOperations=(value) { _buildOperations = value }

	/// <summary>
	/// Gets or sets the resulting root generate operations
	/// </summary>
	OperationProxies { _operationProxies }
	OperationProxies=(value) { _operationProxies = value }

	/// <summary>
	/// Gets or sets the list of module dependencies
	/// </summary>
	ModuleDependencies { _moduleDependencies }
	ModuleDependencies=(value) { _moduleDependencies = value }

	/// <summary>
	/// Gets or sets the list of link libraries that downstream builds should use when linking
	/// </summary>
	LinkDependencies { _linkDependencies }
	LinkDependencies=(value) { _linkDependencies = value }

	/// <summary>
	/// Gets or sets the list of internal link libraries that were used to link the final result
	/// </summary>
	InternalLinkDependencies { _internalLinkDependencies }
	InternalLinkDependencies=(value) { _internalLinkDependencies = value }

	/// <summary>
	/// Gets or sets the list of runtime dependencies
	/// </summary>
	RuntimeDependencies { _runtimeDependencies }
	RuntimeDependencies=(value) { _runtimeDependencies = value }

	/// <summary>
	/// Gets or sets the target file for the build
	/// </summary>
	TargetFile { _targetFile }
	TargetFile=(value) { _targetFile = value }
	
	/// <summary>
	/// Gets or sets the public include directory for the build
	/// </summary>
	PublicInclude { _publicInclude }
	PublicInclude=(value) { _publicInclude = value }
}
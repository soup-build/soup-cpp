// <copyright file="LinkArguments.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

/// <summary>
/// The enumeration of link targets
/// </summary>
class LinkTarget {
	/// <summary>
	/// Static Library
	/// </summary>
	StaticLibrary { "StaticLibrary" }

	/// <summary>
	/// Dynamic Library
	/// </summary>
	DynamicLibrary { "DynamicLibrary" }

	/// <summary>
	/// Executable
	/// </summary>
	Executable { "Executable" }

	/// <summary>
	/// Windows Application
	/// </summary>
	WindowsApplication { "WindowsApplication" }
}

/// <summary>
/// The shared link arguments
/// </summary>
class LinkArguments {
	construct new(
		targetFile,
		targetArchitecture,
		implementationFile,
		targetRootDirectory,
		libraryPaths,
		generateSourceDebugInfo) {
		_targetFile = targetFile
		_targetArchitecture = targetArchitecture
		_implementationFile = implementationFile
		_targetRootDirectory = targetRootDirectory
		_libraryPaths = libraryPaths
		_generateSourceDebugInfo = generateSourceDebugInfo
	}
	/// <summary>
	/// Gets or sets the target file
	/// </summary>
	TargetFile { _targetFile }

	/// <summary>
	/// Gets or sets the target type
	/// </summary>
	TargetType { _targetArchitecture }

	/// <summary>
	/// Gets or sets the implementation file
	/// </summary>
	ImplementationFile { _implementationFile }

	/// <summary>
	/// Gets or sets the root directory
	/// </summary>
	TargetRootDirectory { _targetRootDirectory }

	/// <summary>
	/// Gets or sets the target architecture
	/// </summary>
	TargetArchitecture {}

	/// <summary>
	/// Gets or sets the list of object files
	/// </summary>
	ObjectFiles {}

	/// <summary>
	/// Gets or sets the list of library files
	/// </summary>
	LibraryFiles { }

	/// <summary>
	/// Gets or sets the list of external library files
	/// </summary>
	ExternalLibraryFiles {}

	/// <summary>
	/// Gets or sets the list of library paths
	/// </summary>
	LibraryPaths { _libraryPaths }

	/// <summary>
	/// Gets or sets a value indicating whether to generate source debug information
	/// </summary>
	GenerateSourceDebugInfo { _generateSourceDebugInfo }
}

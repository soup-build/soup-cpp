// <copyright file="LinkArguments.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

/// <summary>
/// The enumeration of link targets
/// </summary>
class LinkTarget
{
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
class LinkArguments
{
	/// <summary>
	/// Gets or sets the target file
	/// </summary>
	TargetFile {}

	/// <summary>
	/// Gets or sets the target type
	/// </summary>
	TargetType {}

	/// <summary>
	/// Gets or sets the implementation file
	/// </summary>
	ImplementationFile {}

	/// <summary>
	/// Gets or sets the root directory
	/// </summary>
	TargetRootDirectory {}

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
	LibraryFiles {}

	/// <summary>
	/// Gets or sets the list of external library files
	/// </summary>
	ExternalLibraryFiles {}

	/// <summary>
	/// Gets or sets the list of library paths
	/// </summary>
	LibraryPaths {}

	/// <summary>
	/// Gets or sets a value indicating whether to generate source debug information
	/// </summary>
	GenerateSourceDebugInfo {}
}

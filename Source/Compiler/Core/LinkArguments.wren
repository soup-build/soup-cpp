// <copyright file="LinkArguments.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "Soup.Build.Utils:./ListExtensions" for ListExtensions

/// <summary>
/// The enumeration of link targets
/// </summary>
class LinkTarget {
	/// <summary>
	/// Static Library
	/// </summary>
	static StaticLibrary { "StaticLibrary" }

	/// <summary>
	/// Dynamic Library
	/// </summary>
	static DynamicLibrary { "DynamicLibrary" }

	/// <summary>
	/// Executable
	/// </summary>
	static Executable { "Executable" }

	/// <summary>
	/// Windows Application
	/// </summary>
	static WindowsApplication { "WindowsApplication" }
}

/// <summary>
/// The shared link arguments
/// </summary>
class LinkArguments {
	construct new() {
		_targetFile = null
		_targetType = null
		_implementationFile = null
		_targetRootDirectory = null
		_targetArchitecture = null
		_objectFiles = []
		_libraryFiles = []
		_externalLibraryFiles = []
		_libraryPaths = []
		_generateSourceDebugInfo = false
	}

	/// <summary>
	/// Gets or sets the target file
	/// </summary>
	TargetFile { _targetFile }
	TargetFile=(value) { _targetFile = value }

	/// <summary>
	/// Gets or sets the target type
	/// </summary>
	TargetType { _targetType }
	TargetType=(value) { _targetType = value }

	/// <summary>
	/// Gets or sets the implementation file
	/// </summary>
	ImplementationFile { _implementationFile }
	ImplementationFile=(value) { _implementationFile = value }

	/// <summary>
	/// Gets or sets the root directory
	/// </summary>
	TargetRootDirectory { _targetRootDirectory }
	TargetRootDirectory=(value) { _targetRootDirectory = value }

	/// <summary>
	/// Gets or sets the target architecture
	/// </summary>
	TargetArchitecture { _targetArchitecture }
	TargetArchitecture=(value) { _targetArchitecture = value }

	/// <summary>
	/// Gets or sets the list of object files
	/// </summary>
	ObjectFiles { _objectFiles }
	ObjectFiles=(value) { _objectFiles = value }

	/// <summary>
	/// Gets or sets the list of library files
	/// </summary>
	LibraryFiles { _libraryFiles }
	LibraryFiles=(value) { _libraryFiles = value }

	/// <summary>
	/// Gets or sets the list of external library files
	/// </summary>
	ExternalLibraryFiles { _externalLibraryFiles }
	ExternalLibraryFiles=(value) { _externalLibraryFiles = value }

	/// <summary>
	/// Gets or sets the list of library paths
	/// </summary>
	LibraryPaths { _libraryPaths }
	LibraryPaths=(value) { _libraryPaths = value }

	/// <summary>
	/// Gets or sets a value indicating whether to generate source debug information
	/// </summary>
	GenerateSourceDebugInfo { _generateSourceDebugInfo }
	GenerateSourceDebugInfo=(value) { _generateSourceDebugInfo = value }

	==(other) {
		// System.print("LinkArguments==")
		if (other is Null) {
			return false
		}

		return this.TargetFile == other.TargetFile &&
			this.TargetType == other.TargetType &&
			this.ImplementationFile == other.ImplementationFile &&
			this.TargetRootDirectory == other.TargetRootDirectory &&
			this.TargetArchitecture == other.TargetArchitecture &&
			ListExtensions.SequenceEqual(this.ObjectFiles, other.ObjectFiles) &&
			ListExtensions.SequenceEqual(this.LibraryFiles, other.LibraryFiles) &&
			ListExtensions.SequenceEqual(this.ExternalLibraryFiles, other.ExternalLibraryFiles) &&
			ListExtensions.SequenceEqual(this.LibraryPaths, other.LibraryPaths) &&
			this.GenerateSourceDebugInfo == other.GenerateSourceDebugInfo
	}

	toString {
		return "LinkArguments { TargetFile=%(_targetFile), TargetType=%(_targetType), ImplementationFile=%(_implementationFile), TargetRootDirectory=%(_targetRootDirectory), TargetArchitecture=%(_targetArchitecture), ObjectFiles=%(_objectFiles), LibraryFiles=%(_libraryFiles), ExternalLibraryFiles=%(_externalLibraryFiles), LibraryPaths=%(_libraryPaths), GenerateSourceDebugInfo=%(_generateSourceDebugInfo) }"
	}
}

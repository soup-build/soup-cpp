// <copyright file="BuildArguments.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

/// <summary>
/// The enumeration of build optimization levels
/// </summary>
class BuildOptimizationLevel {
	/// <summary>
	/// Debug
	/// </summary>
	None { "None" }

	/// <summary>
	/// Optimize for runtime speed, may sacrifice size
	/// </summary>
	Speed { "Speed" }

	/// <summary>
	/// Optimize for speed and size
	/// </summary>
	Size { "Size" }
}

/// <summary>
/// The enumeration of target types
/// </summary>
class BuildTargetType {
	/// <summary>
	/// Windows Application
	/// </summary>
	static WindowsApplication { "WindowsApplication" }

	/// <summary>
	/// Executable
	/// </summary>
	static Executable { "Executable" }

	/// <summary>
	/// Static Library
	/// </summary>
	static StaticLibrary { "StaticLibrary" }

	/// <summary>
	/// Dynamic Library
	/// </summary>
	static DynamicLibrary { "DynamicLibrary" }
}

/// <summary>
/// The source file definition
/// </summary>
class SourceFile {
	File {}
	IsModule {}
}

/// <summary>
/// The partition source file definition
/// </summary>
class PartitionSourceFile {
	File {}
	Imports {}
}

/// <summary>
/// The set of build arguments
/// </summary>
class BuildArguments {
	construct new(
		targetName,
		targetArchitecture,
		targetType,
		sourceRootDirectory,
		targetRootDirectory,
		objectDirectory,
		binaryDirectory) {
		_targetName = targetName
		_targetArchitecture = targetArchitecture
		_targetType = targetType
		_sourceRootDirectory = sourceRootDirectory
		_targetRootDirectory = targetRootDirectory
		_objectDirectory = objectDirectory
		_binaryDirectory = binaryDirectory
		_moduleInterfacePartitionSourceFiles = []
		_moduleInterfaceSourceFile = null
		_sourceFiles = []
		_assemblySourceFiles = []
		_moduleDependencies = []
		_linkDependencies = []
		_libraryPaths = []
		_runtimeDependencies = []
	}

	/// <summary>
	/// Gets or sets the target name
	/// </summary>
	TargetName { _targetName }

	/// <summary>
	/// Gets or sets the target architecture
	/// </summary>
	TargetArchitecture { _targetArchitecture }

	/// <summary>
	/// Gets or sets the target type
	/// </summary>
	TargetType { _targetType }

	/// <summary>
	/// Gets or sets the language standard
	/// </summary>
	LanguageStandard {}

	/// <summary>
	/// Gets or sets the source directory
	/// </summary>
	SourceRootDirectory { _sourceRootDirectory }

	/// <summary>
	/// Gets or sets the target directory
	/// </summary>
	TargetRootDirectory { _targetRootDirectory }

	/// <summary>
	/// Gets or sets the output object directory
	/// </summary>
	ObjectDirectory { _objectDirectory }

	/// <summary>
	/// Gets or sets the output binary directory
	/// </summary>
	BinaryDirectory { _binaryDirectory }

	/// <summary>
	/// Gets or sets the list of module interface partition source files
	/// Note: These files can be plain old translation units 
	/// or they can be module implementation units
	/// </summary>
	ModuleInterfacePartitionSourceFiles { _moduleInterfacePartitionSourceFiles }

	/// <summary>
	/// Gets or sets the single module interface source file
	/// </summary>
	ModuleInterfaceSourceFile { _moduleInterfaceSourceFile}

	/// <summary>
	/// Gets or sets the MSVC Resrouce file
	/// TODO: Abstract for multi-compiler/platform support
	/// </summary>
	ResourceFile { _resourceFile}

	/// <summary>
	/// Gets or sets the list of source files
	/// Note: These files can be plain old translation units 
	/// or they can be module implementation units
	/// </summary>
	SourceFiles { _sourceFiles }

	/// <summary>
	/// Gets or sets the list of assembly source files
	/// </summary>
	AssemblySourceFiles { _assemblySourceFiles }

	/// <summary>
	/// Gets or sets the list of include directories
	/// </summary>
	IncludeDirectories { _includeDirectories }

	/// <summary>
	/// Gets or sets the list of module dependencies
	/// </summary>
	ModuleDependencies { _moduleDependencies }

	/// <summary>
	/// Gets or sets the list of platform link libraries
	/// Note: These libraries will be included at link time, but will not be an input
	/// for the incremental builds
	/// </summary>
	PlatformLinkDependencies { _platformLinkDependencies }

	/// <summary>
	/// Gets or sets the list of link libraries
	/// </summary>
	LinkDependencies { _linkDependencies }

	/// <summary>
	/// Gets or sets the list of library paths
	/// </summary>
	LibraryPaths { _libraryPaths }

	/// <summary>
	/// Gets or sets the list of preprocessor definitions
	/// </summary>
	PreprocessorDefinitions { _preprocessorDefinitions }

	/// <summary>
	/// Gets or sets the list of runtime dependencies
	/// </summary>
	RuntimeDependencies { _runtimeDependencies }

	/// <summary>
	/// Gets or sets the optimization level
	/// </summary>
	OptimizationLevel { _optimizationLevel }

	/// <summary>
	/// Gets or sets a value indicating whether to generate source debug information
	/// </summary>
	GenerateSourceDebugInfo { _generateSourceDebugInfo }

	/// <summary>
	/// Gets or sets a value indicating whether to enable warnings as errors
	/// </summary>
	EnableWarningsAsErrors { _enableWarningsAsErrors}

	/// <summary>
	/// Gets or sets the list of disabled warnings
	/// </summary>
	DisabledWarnings { _disabledWarnings}

	/// <summary>
	/// Gets or sets the list of enabled warnings
	/// </summary>
	EnabledWarnings { _enabledWarnings }

	/// <summary>
	/// Gets or sets the set of custom properties for the known compiler
	/// </summary>
	CustomProperties { _customProperties }
}

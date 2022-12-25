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
	WindowsApplication { "WindowsApplication" }

	/// <summary>
	/// Executable
	/// </summary>
	Executable { "Executable" }

	/// <summary>
	/// Static Library
	/// </summary>
	StaticLibrary { "StaticLibrary" }

	/// <summary>
	/// Dynamic Library
	/// </summary>
	DynamicLibrary { "DynamicLibrary" }
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
	/// <summary>
	/// Gets or sets the target name
	/// </summary>
	TargetName {}

	/// <summary>
	/// Gets or sets the target architecture
	/// </summary>
	TargetArchitecture {}

	/// <summary>
	/// Gets or sets the target type
	/// </summary>
	TargetType {}

	/// <summary>
	/// Gets or sets the language standard
	/// </summary>
	LanguageStandard {}

	/// <summary>
	/// Gets or sets the source directory
	/// </summary>
	SourceRootDirectory {}

	/// <summary>
	/// Gets or sets the target directory
	/// </summary>
	TargetRootDirectory {}

	/// <summary>
	/// Gets or sets the output object directory
	/// </summary>
	ObjectDirectory {}

	/// <summary>
	/// Gets or sets the output binary directory
	/// </summary>
	BinaryDirectory {}

	/// <summary>
	/// Gets or sets the list of module interface partition source files
	/// Note: These files can be plain old translation units 
	/// or they can be module implementation units
	/// </summary>
	ModuleInterfacePartitionSourceFiles {}

	/// <summary>
	/// Gets or sets the single module interface source file
	/// </summary>
	ModuleInterfaceSourceFile {}

	/// <summary>
	/// Gets or sets the MSVC Resrouce file
	/// TODO: Abstract for multi-compiler/platform support
	/// </summary>
	ResourceFile {}

	/// <summary>
	/// Gets or sets the list of source files
	/// Note: These files can be plain old translation units 
	/// or they can be module implementation units
	/// </summary>
	SourceFiles {}

	/// <summary>
	/// Gets or sets the list of assembly source files
	/// </summary>
	AssemblySourceFiles {}

	/// <summary>
	/// Gets or sets the list of include directories
	/// </summary>
	IncludeDirectories {}

	/// <summary>
	/// Gets or sets the list of module dependencies
	/// </summary>
	ModuleDependencies {}

	/// <summary>
	/// Gets or sets the list of platform link libraries
	/// Note: These libraries will be included at link time, but will not be an input
	/// for the incremental builds
	/// </summary>
	PlatformLinkDependencies {}

	/// <summary>
	/// Gets or sets the list of link libraries
	/// </summary>
	LinkDependencies {}

	/// <summary>
	/// Gets or sets the list of library paths
	/// </summary>
	LibraryPaths {}

	/// <summary>
	/// Gets or sets the list of preprocessor definitions
	/// </summary>
	PreprocessorDefinitions {}

	/// <summary>
	/// Gets or sets the list of runtime dependencies
	/// </summary>
	RuntimeDependencies {}

	/// <summary>
	/// Gets or sets the optimization level
	/// </summary>
	OptimizationLevel {}

	/// <summary>
	/// Gets or sets a value indicating whether to generate source debug information
	/// </summary>
	GenerateSourceDebugInfo {}

	/// <summary>
	/// Gets or sets a value indicating whether to enable warnings as errors
	/// </summary>
	EnableWarningsAsErrors {}

	/// <summary>
	/// Gets or sets the list of disabled warnings
	/// </summary>
	DisabledWarnings {}

	/// <summary>
	/// Gets or sets the list of enabled warnings
	/// </summary>
	EnabledWarnings {}

	/// <summary>
	/// Gets or sets the set of custom properties for the known compiler
	/// </summary>
	CustomProperties {}
}

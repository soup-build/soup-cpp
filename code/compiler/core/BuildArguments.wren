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
	static None { "None" }

	/// <summary>
	/// Optimize for runtime speed, may sacrifice size
	/// </summary>
	static Speed { "Speed" }

	/// <summary>
	/// Optimize for speed and size
	/// </summary>
	static Size { "Size" }
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
	construct new() {
		_file = null
		_module = null
		_partition = null
		_imports = []
	}

	construct new(file, module, partition, imports) {
		_file = file
		_module = module
		_partition = partition
		_imports = imports
	}

	File { _file }
	File=(value) { _file = value }

	Module { _module }
	Module=(value) { _module = value }

	Partition { _partition }
	Partition=(value) { _partition = value }

	Imports { _imports }
	Imports=(value) { _imports = value }

	getFullModuleName() {
		return _partition is Null ? _module : "%(_module):%(_partition)"
	}
}

/// <summary>
/// The header file set
/// </summary>
class HeaderFileSet {
	construct new() {
		_root = null
		_target = null
		_files = []
	}

	construct new(root, target, files) {
		_root = root
		_target = target
		_files = files
	}

	Root { _root }
	Root=(value) { _root = value }

	Target { _target }
	Target=(value) { _target = value }

	Files { _files }
	Files=(value) { _files = value }
}

/// <summary>
/// The set of build arguments
/// </summary>
class BuildArguments {
	construct new() {
		_targetName = null
		_targetArchitecture = null
		_targetType = null
		_languageStandard = null
		_sourceRootDirectory = null
		_targetRootDirectory = null
		_objectDirectory = null
		_binaryDirectory = null
		_resourceFile = null
		_sourceFiles = []
		_assemblySourceFiles = []
		_publicHeaderSets = []
		_includeDirectories = []
		_moduleDependencies = {}
		_platformLinkDependencies = []
		_linkDependencies = []
		_libraryPaths = []
		_preprocessorDefinitions = []
		_runtimeDependencies = []
		_optimizationLevel = null
		_generateSourceDebugInfo = false
		_enableWarningsAsErrors = false
		_disabledWarnings = []
		_enabledWarnings = []
		_customProperties = {}
	}

	/// <summary>
	/// Gets or sets the target name
	/// </summary>
	TargetName { _targetName }
	TargetName=(value) { _targetName = value }

	/// <summary>
	/// Gets or sets the target architecture
	/// </summary>
	TargetArchitecture { _targetArchitecture }
	TargetArchitecture=(value) { _targetArchitecture = value }

	/// <summary>
	/// Gets or sets the target type
	/// </summary>
	TargetType { _targetType }
	TargetType=(value) { _targetType = value }

	/// <summary>
	/// Gets or sets the language standard
	/// </summary>
	LanguageStandard { _languageStandard }
	LanguageStandard=(value) { _languageStandard = value }

	/// <summary>
	/// Gets or sets the source directory
	/// </summary>
	SourceRootDirectory { _sourceRootDirectory }
	SourceRootDirectory=(value) { _sourceRootDirectory = value }

	/// <summary>
	/// Gets or sets the target directory
	/// </summary>
	TargetRootDirectory { _targetRootDirectory }
	TargetRootDirectory=(value) { _targetRootDirectory = value }

	/// <summary>
	/// Gets or sets the output object directory
	/// </summary>
	ObjectDirectory { _objectDirectory }
	ObjectDirectory=(value) { _objectDirectory = value }

	/// <summary>
	/// Gets or sets the output binary directory
	/// </summary>
	BinaryDirectory { _binaryDirectory }
	BinaryDirectory=(value) { _binaryDirectory = value }

	/// <summary>
	/// Gets or sets the MSVC Resrouce file
	/// TODO: Abstract for multi-compiler/platform support
	/// </summary>
	ResourceFile { _resourceFile }
	ResourceFile=(value) { _resourceFile = value }

	/// <summary>
	/// Gets or sets the list of source files
	/// Note: These files can be plain old translation units 
	/// or they can be module implementation units
	/// </summary>
	SourceFiles { _sourceFiles }
	SourceFiles=(value) { _sourceFiles = value }

	/// <summary>
	/// Gets or sets the list of assembly source files
	/// </summary>
	AssemblySourceFiles { _assemblySourceFiles }
	AssemblySourceFiles=(value) { _assemblySourceFiles = value }

	/// <summary>
	/// Gets or sets the list of public headers file sets
	/// </summary>
	PublicHeaderSets { _publicHeaderSets }
	PublicHeaderSets=(value) { _publicHeaderSets = value }

	/// <summary>
	/// Gets or sets the list of include directories
	/// </summary>
	IncludeDirectories { _includeDirectories }
	IncludeDirectories=(value) { _includeDirectories = value }

	/// <summary>
	/// Gets or sets the set of module dependencies
	/// </summary>
	ModuleDependencies { _moduleDependencies }
	ModuleDependencies=(value) { _moduleDependencies = value }

	/// <summary>
	/// Gets or sets the list of platform link libraries
	/// Note: These libraries will be included at link time, but will not be an input
	/// for the incremental builds
	/// </summary>
	PlatformLinkDependencies { _platformLinkDependencies }
	PlatformLinkDependencies=(value) { _platformLinkDependencies = value }

	/// <summary>
	/// Gets or sets the list of link libraries
	/// </summary>
	LinkDependencies { _linkDependencies }
	LinkDependencies=(value) { _linkDependencies = value }

	/// <summary>
	/// Gets or sets the list of library paths
	/// </summary>
	LibraryPaths { _libraryPaths }
	LibraryPaths=(value) { _libraryPaths = value }

	/// <summary>
	/// Gets or sets the list of preprocessor definitions
	/// </summary>
	PreprocessorDefinitions { _preprocessorDefinitions }
	PreprocessorDefinitions=(value) { _preprocessorDefinitions = value }

	/// <summary>
	/// Gets or sets the list of runtime dependencies
	/// </summary>
	RuntimeDependencies { _runtimeDependencies }
	RuntimeDependencies=(value) { _runtimeDependencies = value }

	/// <summary>
	/// Gets or sets the optimization level
	/// </summary>
	OptimizationLevel { _optimizationLevel }
	OptimizationLevel=(value) { _optimizationLevel = value }

	/// <summary>
	/// Gets or sets a value indicating whether to generate source debug information
	/// </summary>
	GenerateSourceDebugInfo { _generateSourceDebugInfo }
	GenerateSourceDebugInfo=(value) { _generateSourceDebugInfo = value }

	/// <summary>
	/// Gets or sets a value indicating whether to enable warnings as errors
	/// </summary>
	EnableWarningsAsErrors { _enableWarningsAsErrors}
	EnableWarningsAsErrors=(value) { _enableWarningsAsErrors = value }

	/// <summary>
	/// Gets or sets the list of disabled warnings
	/// </summary>
	DisabledWarnings { _disabledWarnings}
	DisabledWarnings=(value) { _disabledWarnings = value }

	/// <summary>
	/// Gets or sets the list of enabled warnings
	/// </summary>
	EnabledWarnings { _enabledWarnings }
	EnabledWarnings=(value) { _enabledWarnings = value }

	/// <summary>
	/// Gets or sets the set of custom properties for the known compiler
	/// </summary>
	CustomProperties { _customProperties }
	CustomProperties=(value) { _customProperties = value }
}
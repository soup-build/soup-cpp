// <copyright file="CompilerArguments.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

/// <summary>
/// The enumeration of language standards
/// </summary>
class LanguageStandard {
	/// <summary>
	/// C++ 11
	/// </summary>
	CPP11 { "CPP11" }

	/// <summary>
	/// C++ 14
	/// </summary>
	CPP14 { "CPP14" }

	/// <summary>
	/// C++ 17
	/// </summary>
	CPP17 { "CPP17" }

	/// <summary>
	/// C++ 20
	/// </summary>
	CPP20 { "CPP20" }
}

/// <summary>
/// The enumeration of optimization levels
/// </summary>
class OptimizationLevel {
	/// <summary>
	/// Disable all optimization for build speed and debugability
	/// </summary>
	None { "None" }

	/// <summary>
	/// Optimize for speed
	/// </summary>
	Speed { "Speed" }

	/// <summary>
	/// Optimize for size
	/// </summary>
	Size { "Size" }
}

/// <summary>
/// The set of file specific compiler arguments
/// </summary>
class TranslationUnitCompileArguments {
	construct new(sourceFile, targetFile, includeModules) {
		_sourceFile = sourceFile
		_targetFile = targetFile
		_includeModules = includeModules
	}

	/// <summary>
	/// Gets or sets the source file
	/// </summary>
	SourceFile { _sourceFile }

	/// <summary>
	/// Gets or sets the target file
	/// </summary>
	TargetFile { _targetFile }

	/// <summary>
	/// Gets or sets the list of modules
	/// </summary>
	IncludeModules { _includeModules }
}

/// <summary>
/// The set of file specific compiler arguments
/// </summary>
class InterfaceUnitCompileArguments is TranslationUnitCompileArguments {
	construct new(
		sourceFile,
		targetFile,
		includeModules,
		moduleInterfaceTarget) {
		super(sourceFile, targetFile, includeModules)
		_moduleInterfaceTarget = moduleInterfaceTarget
	}

	/// <summary>
	/// Gets or sets the source file
	/// </summary>
	ModuleInterfaceTarget { _moduleInterfaceTarget }
}

/// <summary>
/// The set of shared compiler arguments
/// </summary>
class SharedCompileArguments {

	construct new(
		standard,
		optimizationLevel,
		sourceRootDirectory,
		targetRootDirectory,
		objectDirectory,
		includeDirectories,
		moduleDependencies,
		preprocessorDefinitions,
		generateSourceDebugInfo,
		enableWarningsAsErrors,
		disabledWarnings,
		enabledWarnings,
		customProperties) {
		_standard = standard
		_optimize = optimize
		_sourceRootDirectory = sourceRootDirectory
		_targetRootDirectory = targetRootDirectory
		_objectDirectory = objectDirectory
		_includeDirectories = includeDirectories
		_includeModules = moduleDependencies
		_preprocessorDefinitions = preprocessorDefinitions
		_generateSourceDebugInfo = generateSourceDebugInfo
		_enableWarningsAsErrors = enableWarningsAsErrors
		_disabledWarnings = disabledWarnings
		_enabledWarnings = enabledWarnings
		_customProperties = customProperties
	}

	/// <summary>
	/// Gets or sets the language standard
	/// </summary>
	Standard {}

	/// <summary>
	/// Gets or sets the optimization level
	/// </summary>
	Optimize {}

	/// <summary>
	/// Gets or sets the source directory
	/// </summary>
	SourceRootDirectory {}

	/// <summary>
	/// Gets or sets the target directory
	/// </summary>
	TargetRootDirectory {}

	/// <summary>
	/// Gets or sets the object directory
	/// </summary>
	ObjectDirectory {}

	/// <summary>
	/// Gets or sets the list of preprocessor definitions
	/// </summary>
	PreprocessorDefinitions {}

	/// <summary>
	/// Gets or sets the list of include directories
	/// </summary>
	IncludeDirectories {}

	/// <summary>
	/// Gets or sets the list of modules
	/// </summary>
	IncludeModules {}

	/// <summary>
	/// Gets or sets a value indicating whether to generate source debug information
	/// </summary>
	GenerateSourceDebugInfo {}

	/// <summary>
	/// Gets or sets the list of interface partition translation units to compile
	/// </summary>
	InterfacePartitionUnits {}

	/// <summary>
	/// Gets or sets the single optional interface unit to compile
	/// </summary>
	InterfaceUnit {}

	/// <summary>
	/// Gets or sets the list of individual translation units to compile
	/// </summary>
	ImplementationUnits {}

	/// <summary>
	/// Gets or sets the list of individual assembly units to compile
	/// </summary>
	AssemblyUnits {}

	/// <summary>
	/// Gets or sets the single optional resource file to compile
	/// </summary>
	ResourceFile {}

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


/// <summary>
/// The set of resource file specific compiler arguments
/// </summary>
class ResourceCompileArguments {
	construct new(sourceFile, targetFile) {
		_sourceFile = sourceFile
		_targetFile = targetFile
	}

	/// <summary>
	/// Gets or sets the resource file
	/// </summary>
	SourceFile {}

	/// <summary>
	/// Gets or sets the target file
	/// </summary>
	TargetFile {}
}

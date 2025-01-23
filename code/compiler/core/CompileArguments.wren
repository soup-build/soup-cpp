// <copyright file="CompilerArguments.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "Soup|Build.Utils:./ListExtensions" for ListExtensions
import "Soup|Build.Utils:./MapExtensions" for MapExtensions

/// <summary>
/// The enumeration of language standards
/// </summary>
class LanguageStandard {
	/// <summary>
	/// C++ 11
	/// </summary>
	static CPP11 { "CPP11" }

	/// <summary>
	/// C++ 14
	/// </summary>
	static CPP14 { "CPP14" }

	/// <summary>
	/// C++ 17
	/// </summary>
	static CPP17 { "CPP17" }

	/// <summary>
	/// C++ 20
	/// </summary>
	static CPP20 { "CPP20" }
}

/// <summary>
/// The enumeration of optimization levels
/// </summary>
class OptimizationLevel {
	/// <summary>
	/// Disable all optimization for build speed and debugability
	/// </summary>
	static None { "None" }

	/// <summary>
	/// Optimize for speed
	/// </summary>
	static Speed { "Speed" }

	/// <summary>
	/// Optimize for size
	/// </summary>
	static Size { "Size" }
}

/// <summary>
/// The set of file specific compiler arguments
/// </summary>
class TranslationUnitCompileArguments {
	construct new() {
		_sourceFile = null
		_targetFile = null
		_includeModules = {}
	}

	construct new(sourceFile, targetFile, includeModules) {
		_sourceFile = sourceFile
		_targetFile = targetFile
		_includeModules = includeModules
	}

	/// <summary>
	/// Gets or sets the source file
	/// </summary>
	SourceFile { _sourceFile }
	SourceFile=(value) { _sourceFile = value }

	/// <summary>
	/// Gets or sets the target file
	/// </summary>
	TargetFile { _targetFile }
	TargetFile=(value) { _targetFile = value }

	/// <summary>
	/// Gets or sets the list of modules
	/// </summary>
	IncludeModules { _includeModules }
	IncludeModules=(value) { _includeModules = value }

	==(other) {
		// System.print("TranslationUnitCompileArguments==")
		if (other is Null) {
			return false
		}

		return this.SourceFile == other.SourceFile &&
			this.TargetFile == other.TargetFile &&
			MapExtensions.Equal(this.IncludeModules, other.IncludeModules)
	}

	toString {
		return "TranslationUnitCompileArguments { SourceFile=%(_sourceFile), TargetFile=%(_targetFile), IncludeModules=%(_includeModules) }"
	}
}

/// <summary>
/// The set of file specific compiler arguments
/// </summary>
class InterfaceUnitCompileArguments is TranslationUnitCompileArguments {
	construct new() {
		super()
		_moduleName = null
		_moduleInterfaceTarget = null
	}

	construct new(sourceFile, targetFile, includeModules, moduleName, moduleInterfaceTarget) {
		super(sourceFile, targetFile, includeModules)
		_moduleName = moduleName
		_moduleInterfaceTarget = moduleInterfaceTarget
	}

	/// <summary>
	/// Gets or sets the module name
	/// </summary>
	ModuleName { _moduleName }
	ModuleName=(value) { _moduleName = value }

	/// <summary>
	/// Gets or sets the module interface target
	/// </summary>
	ModuleInterfaceTarget { _moduleInterfaceTarget }
	ModuleInterfaceTarget=(value) { _moduleInterfaceTarget = value }

	==(other) {
		// System.print("InterfaceUnitCompileArguments==")
		if (other is Null) {
			return false
		}

		return this.SourceFile == other.SourceFile &&
			this.TargetFile == other.TargetFile &&
			MapExtensions.Equal(this.IncludeModules, other.IncludeModules) &&
			this.ModuleName == other.ModuleName &&
			this.ModuleInterfaceTarget == other.ModuleInterfaceTarget
	}

	toString {
		return "InterfaceUnitCompileArguments { SourceFile=%(this.SourceFile), TargetFile=%(this.TargetFile), IncludeModules=%(this.IncludeModules), ModuleName=%(this.ModuleName) ModuleInterfaceTarget=%(this.ModuleInterfaceTarget) }"
	}
}

/// <summary>
/// The set of shared compiler arguments
/// </summary>
class SharedCompileArguments {
	construct new() {
		_standard = null
		_optimize = null
		_sourceRootDirectory = null
		_targetRootDirectory = null
		_objectDirectory = null
		_preprocessorDefinitions = []
		_includeDirectories = []
		_includeModules = {}
		_generateSourceDebugInfo = false
		_interfacePartitionUnits = []
		_interfaceUnit = null
		_implementationUnits = []
		_assemblyUnits = []
		_resourceFile = null
		_enableWarningsAsErrors = false
		_disabledWarnings = []
		_enabledWarnings = []
		_customProperties = {}
	}

	/// <summary>
	/// Gets or sets the language standard
	/// </summary>
	Standard { _standard }
	Standard=(value) { _standard = value }

	/// <summary>
	/// Gets or sets the optimization level
	/// </summary>
	Optimize { _optimize }
	Optimize=(value) { _optimize = value }

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
	/// Gets or sets the object directory
	/// </summary>
	ObjectDirectory { _objectDirectory }
	ObjectDirectory=(value) { _objectDirectory = value }

	/// <summary>
	/// Gets or sets the list of preprocessor definitions
	/// </summary>
	PreprocessorDefinitions { _preprocessorDefinitions }
	PreprocessorDefinitions=(value) { _preprocessorDefinitions = value }

	/// <summary>
	/// Gets or sets the list of include directories
	/// </summary>
	IncludeDirectories { _includeDirectories }
	IncludeDirectories=(value) { _includeDirectories = value }

	/// <summary>
	/// Gets or sets the list of modules
	/// </summary>
	IncludeModules { _includeModules }
	IncludeModules=(value) { _includeModules = value }

	/// <summary>
	/// Gets or sets a value indicating whether to generate source debug information
	/// </summary>
	GenerateSourceDebugInfo { _generateSourceDebugInfo }
	GenerateSourceDebugInfo=(value) { _generateSourceDebugInfo = value }

	/// <summary>
	/// Gets or sets the list of interface partition translation units to compile
	/// </summary>
	InterfacePartitionUnits { _interfacePartitionUnits }
	InterfacePartitionUnits=(value) { _interfacePartitionUnits = value }

	/// <summary>
	/// Gets or sets the single optional interface unit to compile
	/// </summary>
	InterfaceUnit { _interfaceUnit }
	InterfaceUnit=(value) { _interfaceUnit = value }

	/// <summary>
	/// Gets or sets the list of individual translation units to compile
	/// </summary>
	ImplementationUnits { _implementationUnits }
	ImplementationUnits=(value) { _implementationUnits = value }

	/// <summary>
	/// Gets or sets the list of individual assembly units to compile
	/// </summary>
	AssemblyUnits { _assemblyUnits }
	AssemblyUnits=(value) { _assemblyUnits = value }

	/// <summary>
	/// Gets or sets the single optional resource file to compile
	/// </summary>
	ResourceFile { _resourceFile }
	ResourceFile=(value) { _resourceFile = value }

	/// <summary>
	/// Gets or sets a value indicating whether to enable warnings as errors
	/// </summary>
	EnableWarningsAsErrors { _enableWarningsAsErrors }
	EnableWarningsAsErrors=(value) { _enableWarningsAsErrors = value }

	/// <summary>
	/// Gets or sets the list of disabled warnings
	/// </summary>
	DisabledWarnings { _disabledWarnings }
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

	==(other) {
		// System.print("SharedCompileArguments==")
		if (other is Null) {
			return false
		}

		return this.Standard == other.Standard &&
			this.Optimize == other.Optimize  &&
			this.SourceRootDirectory == other.SourceRootDirectory &&
			this.TargetRootDirectory == other.TargetRootDirectory &&
			this.ObjectDirectory == other.ObjectDirectory &&
			ListExtensions.SequenceEqual(this.PreprocessorDefinitions, other.PreprocessorDefinitions) &&
			ListExtensions.SequenceEqual(this.IncludeDirectories, other.IncludeDirectories) &&
			MapExtensions.Equal(this.IncludeModules, other.IncludeModules) &&
			this.GenerateSourceDebugInfo == other.GenerateSourceDebugInfo &&
			ListExtensions.SequenceEqual(this.InterfacePartitionUnits, other.InterfacePartitionUnits) &&
			this.InterfaceUnit == other.InterfaceUnit &&
			ListExtensions.SequenceEqual(this.ImplementationUnits, other.ImplementationUnits) &&
			ListExtensions.SequenceEqual(this.AssemblyUnits, other.AssemblyUnits) &&
			this.ResourceFile == other.ResourceFile &&
			this.EnableWarningsAsErrors == other.EnableWarningsAsErrors &&
			ListExtensions.SequenceEqual(this.DisabledWarnings, other.DisabledWarnings) &&
			ListExtensions.SequenceEqual(this.EnabledWarnings, other.EnabledWarnings)
			MapExtensions.Equal(this.CustomProperties, other.CustomProperties)
	}

	toString {
		return "SharedCompileArguments { Standard=%(_standard), Optimize=%(_optimize), SourceRootDirectory=%(_sourceRootDirectory), TargetRootDirectory=%(_targetRootDirectory), ObjectDirectory=%(_objectDirectory), PreprocessorDefinitions=%(_preprocessorDefinitions), IncludeDirectories=%(_includeDirectories), IncludeModules=%(_includeModules), GenerateSourceDebugInfo=%(_generateSourceDebugInfo), InterfacePartitionUnits=%(_interfacePartitionUnits), InterfaceUnit=%(_interfaceUnit), ImplementationUnits=%(_implementationUnits), AssemblyUnits=%(_assemblyUnits), ResourceFile=%(_resourceFile), EnableWarningsAsErrors=%(_enableWarningsAsErrors), DisabledWarnings=%(_disabledWarnings), EnabledWarnings=%(_enabledWarnings), CustomProperties=%(_customProperties) }"
	}
}

/// <summary>
/// The set of resource file specific compiler arguments
/// </summary>
class ResourceCompileArguments {
	construct new() {
		_sourceFile = null
		_targetFile = null
	}

	construct new(sourceFile, targetFile) {
		_sourceFile = sourceFile
		_targetFile = targetFile
	}

	/// <summary>
	/// Gets or sets the resource file
	/// </summary>
	SourceFile { _sourceFile }
	SourceFile=(value) { _sourceFile = value }

	/// <summary>
	/// Gets or sets the target file
	/// </summary>
	TargetFile { _targetFile }
	TargetFile=(value) { _targetFile = value }

	==(other) {
		// System.print("ResourceCompileArguments==")
		if (other is Null) {
			return false
		}

		return this.SourceFile == other.SourceFile &&
			this.TargetFile == other.TargetFile
	}
}

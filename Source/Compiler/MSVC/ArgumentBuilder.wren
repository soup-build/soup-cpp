// <copyright file="ArgumentBuilder.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>
import "../Core/CompileArguments" for LanguageStandard, OptimizationLevel
import "../Core/LinkArguments" for LinkTarget

/// <summary>
/// A helper class that builds the correct set of compiler arguments for a given
/// set of options.
/// </summary>
class ArgumentBuilder {
	static ArgumentFlag_NoLogo { "nologo" }

	static Compiler_ArgumentFlag_GenerateDebugInformation { "Z7" }
	static Compiler_ArgumentFlag_GenerateDebugInformationExternal { "Zi" }
	static Compiler_ArgumentFlag_CompileOnly { "c" }
	static Compiler_ArgumentFlag_IgnoreStandardIncludePaths { "X" }
	static Compiler_ArgumentFlag_Optimization_Disable { "Od" }
	static Compiler_ArgumentFlag_Optimization_Speed { "Ot" }
	static Compiler_ArgumentFlag_Optimization_Size { "Os" }
	static Compiler_ArgumentFlag_RuntimeChecks { "RTC1" }
	static Compiler_ArgumentFlag_Runtime_MultithreadedDynamic_Debug { "MDd" }
	static Compiler_ArgumentFlag_Runtime_MultithreadedDynamic_Release { "MD" }
	static Compiler_ArgumentFlag_Runtime_MultithreadedStatic_Debug { "MTd" }
	static Compiler_ArgumentFlag_Runtime_MultithreadedStatic_Release { "MT" }
	static Compiler_ArgumentParameter_Standard { "std" }
	static Compiler_ArgumentParameter_Experimental { "experimental" }
	static Compiler_ArgumentParameter_ObjectFile { "Fo" }
	static Compiler_ArgumentParameter_Include { "I" }
	static Compiler_ArgumentParameter_PreprocessorDefine { "D" }

	static Linker_ArgumentFlag_NoDefaultLibraries { "nodefaultlib" }
	static Linker_ArgumentFlag_DLL { "dll" }
	static Linker_ArgumentFlag_Verbose { "verbose" }
	static Linker_ArgumentParameter_Output { "out" }
	static Linker_ArgumentParameter_ImplementationLibrary { "implib" }
	static Linker_ArgumentParameter_LibraryPath { "libpath" }
	static Linker_ArgumentParameter_Machine { "machine" }
	static Linker_ArgumentParameter_DefaultLibrary { "defaultlib" }
	static Linker_ArgumentValue_X64 { "X64" }
	static Linker_ArgumentValue_X86 { "X86" }

	BuildSharedCompilerArguments(arguments) {
		// Calculate object output file
		var commandArguments = []

		// Disable the logo
		this.AddFlag(commandArguments, this.ArgumentFlag_NoLogo)

		// Enable full paths for errors
		this.AddFlag(commandArguments, "FC")

		// Enable standards-conforming compiler behavior
		// https://docs.microsoft.com/en-us/cpp/build/reference/permissive-standards-conformance?view=vs-2019
		// Note: Enables /Zc:referenceBinding, /Zc:strictStrings, and /Zc:rvalueCast
		// And after 15.3 /Zc:ternary
		this.AddFlag(commandArguments, "permissive-")

		// Enable the __cplusplus macro to report the supported standard
		// https://docs.microsoft.com/en-us/cpp/build/reference/zc-cplusplus?view=vs-2019
		var disableCPlusPlusMacroConformance = arguments.CustomProperties.containsKey("DisableCPlusPlusMacroConformance")
		if (!disableCPlusPlusMacroConformance) {
			this.AddParameter(commandArguments, "Zc", "__cplusplus")
		}

		// Enable external linkage for constexpr variables
		// https://docs.microsoft.com/en-us/cpp/build/reference/zc-externconstexpr?view=vs-2019
		this.AddParameter(commandArguments, "Zc", "externConstexpr")

		// Remove unreferenced function or data if it is COMDAT or has internal linkage only
		// https://docs.microsoft.com/en-us/cpp/build/reference/zc-inline-remove-unreferenced-comdat?view=vs-2019
		this.AddParameter(commandArguments, "Zc", "inline")

		// Assume operator new throws on failure
		// https://docs.microsoft.com/en-us/cpp/build/reference/zc-throwingnew-assume-operator-new-throws?view=vs-2019
		this.AddParameter(commandArguments, "Zc", "throwingNew")

		// Generate source debug information
		if (arguments.GenerateSourceDebugInfo) {
			this.AddFlag(commandArguments, this.Compiler_ArgumentFlag_GenerateDebugInformation)
		}

		// Disabled individual warnings
		if (arguments.EnableWarningsAsErrors) {
			this.AddFlag(commandArguments, "WX")
		}

		this.AddFlag(commandArguments, "W4")

		// Disable any requested warnings
		for (warning in arguments.DisabledWarnings) {
			this.AddFlagValue(commandArguments, "wd", warning)
		}

		// Enable any requested warnings
		for (warning in arguments.EnabledWarnings) {
			this.AddFlagValue(commandArguments, "w", warning)
		}

		// Set the language standard
		if (arguments.Standard == LanguageStandard.CPP11) {
			this.AddParameter(commandArguments, this.Compiler_ArgumentParameter_Standard, "c++11")
		} else if (arguments.Standard == LanguageStandard.CPP14) {
			this.AddParameter(commandArguments, this.Compiler_ArgumentParameter_Standard, "c++14")
		} else if (arguments.Standard == LanguageStandard.CPP17) {
			this.AddParameter(commandArguments, this.Compiler_ArgumentParameter_Standard, "c++17")
		} else if (arguments.Standard == LanguageStandard.CPP20) {
			this.AddParameter(commandArguments, this.Compiler_ArgumentParameter_Standard, "c++latest")
		} else {
			Fiber.abort("Unknown language standard.")
		}

		// Set the optimization level
		if (arguments.Optimize == OptimizationLevel.None) {
			this.AddFlag(commandArguments, this.Compiler_ArgumentFlag_Optimization_Disable)
		} else if (arguments.Optimize == OptimizationLevel.Speed) {
			this.AddFlag(commandArguments, this.Compiler_ArgumentFlag_Optimization_Speed)
		} else if (arguments.Optimize == OptimizationLevel.Size) {
			this.AddFlag(commandArguments, this.Compiler_ArgumentFlag_Optimization_Size)
		} else {
			Fiber.abort("Unknown optimization level.")
		}

		// Set the include paths
		for (directory in arguments.IncludeDirectories) {
			this.AddFlagValueWithQuotes(commandArguments, this.Compiler_ArgumentParameter_Include, directory.ToString())
		}

		// Set the preprocessor definitions
		for (definition in arguments.PreprocessorDefinitions) {
			this.AddFlagValue(commandArguments, this.Compiler_ArgumentParameter_PreprocessorDefine, definition)
		}

		// Ignore Standard Include Paths to prevent pulling in accidental headers
		this.AddFlag(commandArguments, this.Compiler_ArgumentFlag_IgnoreStandardIncludePaths)

		// Enable basic runtime checks
		this.AddFlag(commandArguments, this.Compiler_ArgumentFlag_RuntimeChecks)

		// Enable c++ exceptions
		this.AddFlag(commandArguments, "EHsc")

		// Enable multithreaded runtime static linked
		if (arguments.GenerateSourceDebugInfo) {
			this.AddFlag(commandArguments, this.Compiler_ArgumentFlag_Runtime_MultithreadedStatic_Debug)
		} else {
			this.AddFlag(commandArguments, this.Compiler_ArgumentFlag_Runtime_MultithreadedStatic_Release)
		}

		// Add the module references as input
		for (moduleFile in arguments.IncludeModules) {
			this.AddFlag(commandArguments, "reference")
			this.AddValueWithQuotes(commandArguments, moduleFile.ToString())
		}

		// TODO: For now we allow exports to be large
		this.AddFlag(commandArguments, "bigobj")

		// Only run preprocessor, compile and assemble
		this.AddFlag(commandArguments, this.Compiler_ArgumentFlag_CompileOnly)

		return commandArguments
	}

	static BuildResourceCompilerArguments(
		targetRootDirectory,
		arguments) {
		if (arguments.ResourceFile == null) {
			Fiber.abort("Argument null")
		}

		// Build the arguments for a standard translation unit
		var commandArguments = []

		// Disable the logo
		this.AddFlag(commandArguments, this.ArgumentFlag_NoLogo)

		// TODO: Defines?
		this.AddFlagValue(commandArguments, this.Compiler_ArgumentParameter_PreprocessorDefine, "_UNICODE")
		this.AddFlagValue(commandArguments, this.Compiler_ArgumentParameter_PreprocessorDefine, "UNICODE")

		// Specify default language using language identifier
		this.AddFlagValueWithQuotes(commandArguments, "l", "0x0409")

		// Set the include paths
		for (directory in arguments.IncludeDirectories) {
			this.AddFlagValueWithQuotes(commandArguments, this.Compiler_ArgumentParameter_Include, directory.ToString())
		}

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.ResourceFile.TargetFile
		this.AddFlagValueWithQuotes(
			commandArguments,
			this.Compiler_ArgumentParameter_ObjectFile,
			absoluteTargetFile.ToString())

		// Add the source file as input
		commandArguments.add(arguments.ResourceFile.SourceFile.ToString())

		return commandArguments
	}

	static BuildInterfaceUnitCompilerArguments(
		targetRootDirectory,
		arguments,
		responseFile) {
		// Build the arguments for a standard translation unit
		var commandArguments = []

		// Add the response file
		commandArguments.add("@" + responseFile.ToString())

		// Add the module references as input
		for (moduleFile in arguments.IncludeModules) {
			this.AddFlag(commandArguments, "reference")
			this.AddValueWithQuotes(commandArguments, moduleFile.ToString())
		}

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.ToString())

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.TargetFile
		this.AddFlagValueWithQuotes(
			commandArguments,
			this.Compiler_ArgumentParameter_ObjectFile,
			absoluteTargetFile.ToString())

		// Add the unique arguments for an interface unit
		this.AddFlag(commandArguments, "interface")

		// Specify the module interface file output
		this.AddFlag(commandArguments, "ifcOutput")

		var absoluteModuleInterfaceFile = targetRootDirectory + arguments.ModuleInterfaceTarget
		this.AddValueWithQuotes(commandArguments, absoluteModuleInterfaceFile.ToString())

		return commandArguments
	}

	static BuildAssemblyUnitCompilerArguments(
		targetRootDirectory,
		sharedArguments,
		arguments) {
		// Build the arguments for a standard translation unit
		var commandArguments = []

		// Disable the logo
		this.AddFlag(commandArguments, this.ArgumentFlag_NoLogo)

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.TargetFile
		this.AddFlagValueWithQuotes(
			commandArguments,
			this.Compiler_ArgumentParameter_ObjectFile,
			absoluteTargetFile.ToString())

		// Only run preprocessor, compile and assemble
		this.AddFlag(commandArguments, this.Compiler_ArgumentFlag_CompileOnly)

		// Generate debug information
		this.AddFlag(commandArguments, this.Compiler_ArgumentFlag_GenerateDebugInformation)

		// Enable warnings
		this.AddFlag(commandArguments, "W3")

		// Set the include paths
		for (directory in sharedArguments.IncludeDirectories) {
			this.AddFlagValueWithQuotes(commandArguments, this.Compiler_ArgumentParameter_Include, directory.ToString())
		}

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.ToString())

		return commandArguments
	}
	
	static BuildPartitionUnitCompilerArguments(
		targetRootDirectory,
		arguments,
		responseFile) {
		// Build the arguments for a standard translation unit
		var commandArguments = []

		// Add the response file
		commandArguments.add("@" + responseFile.ToString())

		// Add the module references as input
		for (moduleFile in arguments.IncludeModules) {
			this.AddFlag(commandArguments, "reference")
			this.AddValueWithQuotes(commandArguments, moduleFile.ToString())
		}

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.ToString())

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.TargetFile
		this.AddFlagValueWithQuotes(
			commandArguments,
			this.Compiler_ArgumentParameter_ObjectFile,
			absoluteTargetFile.ToString())

		// Add the unique arguments for an partition unit
		this.AddFlag(commandArguments, "interface")

		// Specify the module interface file output
		this.AddFlag(commandArguments, "ifcOutput")

		var absoluteModuleInterfaceFile = targetRootDirectory + arguments.ModuleInterfaceTarget
		this.AddValueWithQuotes(commandArguments, absoluteModuleInterfaceFile.ToString())

		return commandArguments
	}

	static BuildTranslationUnitCompilerArguments(
		targetRootDirectory,
		arguments,
		responseFile,
		internalModules) {
		// Calculate object output file
		var commandArguments = []

		// Add the response file
		commandArguments.add("@" + responseFile.ToString())

		// Add the internal module references as input
		for (moduleFile in arguments.IncludeModules) {
			this.AddFlag(commandArguments, "reference")
			this.AddValueWithQuotes(commandArguments, moduleFile.ToString())
		}

		// Add the internal module references as input
		for (moduleFile in internalModules) {
			this.AddFlag(commandArguments, "reference")
			this.AddValueWithQuotes(commandArguments, moduleFile.ToString())
		}

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.ToString())

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.TargetFile
		this.AddFlagValueWithQuotes(
			commandArguments,
			this.Compiler_ArgumentParameter_ObjectFile,
			absoluteTargetFile.ToString())

		return commandArguments
	}

	static BuildLinkerArguments(arguments) {
		// Verify the input
		if (arguments.TargetFile.GetFileName() == null) {
			Fiber.abort("Target file cannot be empty.")
		}

		var commandArguments = []

		// Disable the logo
		this.AddFlag(commandArguments, this.ArgumentFlag_NoLogo)

		// Disable the default libraries, we will set this up
		// this.AddFlag(commandArguments, this.Linker_ArgumentFlag_NoDefaultLibraries)

		// Enable verbose output
		// this.AddFlag(commandArguments, this.Linker_ArgumentFlag_Verbose)

		// Generate source debug information
		if (arguments.GenerateSourceDebugInfo) {
			this.AddParameter(commandArguments, "debug", "full")
		}

		// Calculate object output file
		if (arguments.TargetType == LinkTarget.StaticLibrary) {
			// Nothing to do
		} else if (arguments.TargetType == LinkTarget.DynamicLibrary) {
			// TODO: May want to specify the exact value
			// set the default lib to mutlithreaded
			// this.AddParameter(commandArguments, "defaultlib", "libcmt")
			this.AddParameter(commandArguments, "subsystem", "console")

			// Create a dynamic library
			this.AddFlag(commandArguments, this.Linker_ArgumentFlag_DLL)

			// Set the output implementation library
			this.AddParameterWithQuotes(
				commandArguments,
				this.Linker_ArgumentParameter_ImplementationLibrary,
				arguments.ImplementationFile.ToString())
		} else if (arguments.TargetType == LinkTarget.Executable) {
			// TODO: May want to specify the exact value
			// set the default lib to multithreaded
			// this.AddParameter(commandArguments, "defaultlib", "libcmt")
			this.AddParameter(commandArguments, "subsystem", "console")
		} else if (arguments.TargetType == LinkTarget.WindowsApplication) {
			// TODO: May want to specify the exact value
			// set the default lib to multithreaded
			// this.AddParameter(commandArguments, "defaultlib", "libcmt")
			this.AddParameter(commandArguments, "subsystem", "windows")
		} else {
			Fiber.abort("Unknown LinkTarget.")
		}

		// Add the machine target
		if (arguments.TargetArchitecture == "x64") {
			this.AddParameter(commandArguments, this.Linker_ArgumentParameter_Machine, this.Linker_ArgumentValue_X64)
		} else if (arguments.TargetArchitecture == "x86") {
			this.AddParameter(commandArguments, this.Linker_ArgumentParameter_Machine, this.Linker_ArgumentValue_X86)
		} else {
			Fiber.abort("Unknown target architecture.")
		}

		// Set the library paths
		for (directory in arguments.LibraryPaths) {
			this.AddParameterWithQuotes(commandArguments, this.Linker_ArgumentParameter_LibraryPath, directory.ToString())
		}

		// Add the target as an output
		this.AddParameterWithQuotes(commandArguments, this.Linker_ArgumentParameter_Output, arguments.TargetFile.ToString())

		// Add the library files
		for (file in arguments.LibraryFiles) {
			// Add the library files as input
			commandArguments.add(file.ToString())
		}

		// Add the external libraries as default libraries so they are resolved last
		for (file in arguments.ExternalLibraryFiles) {
			// Add the external library files as input
			// TODO: Explicitly ignore these files from the input for now
			this.AddParameter(commandArguments, this.Linker_ArgumentParameter_DefaultLibrary, file.ToString())
		}

		// Add the object files
		for (file in arguments.ObjectFiles) {
			// Add the object files as input
			commandArguments.add(file.ToString())
		}

		return commandArguments
	}

	static AddValueWithQuotes(arguments, value) {
		arguments.add("\"%(value)\"")
	}

	static AddFlag(arguments, flag) {
		arguments.add("/%(flag)")
	}

	static AddFlagValue(arguments, flag, value) {
		arguments.add("/%(flag)%(value)")
	}

	static AddFlagValueWithQuotes(arguments, flag, value) {
		arguments.add("/%(flag)\"%(value)\"")
	}

	static AddParameter(arguments, name, value) {
		arguments.add("/%(name):%(value)")
	}

	static AddParameterWithQuotes(arguments, name, value) {
		arguments.add("/%(name):\"%(value)\"")
	}
}

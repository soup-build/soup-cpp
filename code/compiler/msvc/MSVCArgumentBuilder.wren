// <copyright file="MSVCArgumentBuilder.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "Soup|Cpp.Compiler:./CompileArguments" for LanguageStandard, OptimizationLevel
import "Soup|Cpp.Compiler:./LinkArguments" for LinkTarget

/// <summary>
/// A helper class that builds the correct set of compiler arguments for a given
/// set of options.
/// </summary>
class MSVCArgumentBuilder {
	static ArgumentFlag_NoLogo { "nologo" }

	static Compiler_ArgumentFlag_GenerateDebugInformation { "Z7" }
	static Compiler_ArgumentFlag_GenerateDebugInformationExternal { "Zi" }
	static Compiler_ArgumentFlag_CompileOnly { "c" }
	static Compiler_ArgumentFlag_IgnoreStandardIncludePaths { "X" }
	static Compiler_ArgumentFlag_Optimization_Disable { "Od" }
	static Compiler_ArgumentFlag_Optimization_Speed { "O2" }
	static Compiler_ArgumentFlag_Optimization_Size { "O1" }
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

	static BuildSharedCompilerArguments(arguments) {
		// Calculate object output file
		var commandArguments = []

		// Disable the logo
		MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.ArgumentFlag_NoLogo)

		// Treat all files as C++
		MSVCArgumentBuilder.AddFlag(commandArguments, "TP")

		// Enable full paths for errors
		MSVCArgumentBuilder.AddFlag(commandArguments, "FC")

		// Enable standards-conforming compiler behavior
		// https://docs.microsoft.com/en-us/cpp/build/reference/permissive-standards-conformance?view=vs-2019
		// Note: Enables /Zc:referenceBinding, /Zc:strictStrings, and /Zc:rvalueCast
		// And after 15.3 /Zc:ternary
		MSVCArgumentBuilder.AddFlag(commandArguments, "permissive-")

		// Enable the __cplusplus macro to report the supported standard
		// https://docs.microsoft.com/en-us/cpp/build/reference/zc-cplusplus?view=vs-2019
		var disableCPlusPlusMacroConformance = arguments.CustomProperties.containsKey("DisableCPlusPlusMacroConformance")
		if (!disableCPlusPlusMacroConformance) {
			MSVCArgumentBuilder.AddParameter(commandArguments, "Zc", "__cplusplus")
		}

		// Enable external linkage for constexpr variables
		// https://docs.microsoft.com/en-us/cpp/build/reference/zc-externconstexpr?view=vs-2019
		MSVCArgumentBuilder.AddParameter(commandArguments, "Zc", "externConstexpr")

		// Remove unreferenced function or data if it is COMDAT or has internal linkage only
		// https://docs.microsoft.com/en-us/cpp/build/reference/zc-inline-remove-unreferenced-comdat?view=vs-2019
		MSVCArgumentBuilder.AddParameter(commandArguments, "Zc", "inline")

		// Assume operator new throws on failure
		// https://docs.microsoft.com/en-us/cpp/build/reference/zc-throwingnew-assume-operator-new-throws?view=vs-2019
		MSVCArgumentBuilder.AddParameter(commandArguments, "Zc", "throwingNew")

		// Generate source debug information
		if (arguments.GenerateSourceDebugInfo) {
			MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentFlag_GenerateDebugInformation)
		}

		// Disabled individual warnings
		if (arguments.EnableWarningsAsErrors) {
			MSVCArgumentBuilder.AddFlag(commandArguments, "WX")
		}

		MSVCArgumentBuilder.AddFlag(commandArguments, "W4")

		// Disable any requested warnings
		for (warning in arguments.DisabledWarnings) {
			MSVCArgumentBuilder.AddFlagValue(commandArguments, "wd", warning)
		}

		// Enable any requested warnings
		for (warning in arguments.EnabledWarnings) {
			MSVCArgumentBuilder.AddFlagValue(commandArguments, "w", warning)
		}

		// Set the language standard
		if (arguments.Standard == LanguageStandard.CPP11) {
			MSVCArgumentBuilder.AddParameter(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++11")
		} else if (arguments.Standard == LanguageStandard.CPP14) {
			MSVCArgumentBuilder.AddParameter(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++14")
		} else if (arguments.Standard == LanguageStandard.CPP17) {
			MSVCArgumentBuilder.AddParameter(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++17")
		} else if (arguments.Standard == LanguageStandard.CPP20) {
			MSVCArgumentBuilder.AddParameter(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++20")
		} else if (arguments.Standard == LanguageStandard.CPP23) {
			MSVCArgumentBuilder.AddParameter(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++23preview")
		} else if (arguments.Standard == LanguageStandard.CPP26) {
			MSVCArgumentBuilder.AddParameter(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++latest")
		} else {
			Fiber.abort("Unknown language standard %(arguments.Standard).")
		}

		// Set the optimization level
		if (arguments.Optimize == OptimizationLevel.None) {
			MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentFlag_Optimization_Disable)
		} else if (arguments.Optimize == OptimizationLevel.Speed) {
			MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentFlag_Optimization_Speed)
		} else if (arguments.Optimize == OptimizationLevel.Size) {
			MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentFlag_Optimization_Size)
		} else {
			Fiber.abort("Unknown optimization level %(arguments.Optimize)")
		}

		// Set the include paths
		for (directory in arguments.IncludeDirectories) {
			MSVCArgumentBuilder.AddFlagValueWithQuotes(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentParameter_Include, directory.toString)
		}

		// Set the preprocessor definitions
		for (definition in arguments.PreprocessorDefinitions) {
			MSVCArgumentBuilder.AddFlagValue(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentParameter_PreprocessorDefine, definition)
		}

		// Ignore Standard Include Paths to prevent pulling in accidental headers
		MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentFlag_IgnoreStandardIncludePaths)

		if (arguments.Optimize != OptimizationLevel.Speed) {
			// Enable basic runtime checks
			MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentFlag_RuntimeChecks)
		}

		// Enable c++ exceptions
		MSVCArgumentBuilder.AddFlag(commandArguments, "EHsc")

		// Enable multithreaded runtime static linked
		if (arguments.GenerateSourceDebugInfo) {
			MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentFlag_Runtime_MultithreadedStatic_Debug)
		} else {
			MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentFlag_Runtime_MultithreadedStatic_Release)
		}

		// Add the module references as input
		for (module in arguments.IncludeModules) {
			MSVCArgumentBuilder.AddFlag(commandArguments, "reference")
			MSVCArgumentBuilder.AddValue(commandArguments, module.value.toString)
		}

		// TODO: For now we allow exports to be large
		MSVCArgumentBuilder.AddFlag(commandArguments, "bigobj")

		// Only run preprocessor, compile and assemble
		MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentFlag_CompileOnly)

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
		MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.ArgumentFlag_NoLogo)

		// TODO: Defines?
		MSVCArgumentBuilder.AddFlagValue(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentParameter_PreprocessorDefine, "_UNICODE")
		MSVCArgumentBuilder.AddFlagValue(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentParameter_PreprocessorDefine, "UNICODE")

		// Specify default language using language identifier
		MSVCArgumentBuilder.AddFlagValueWithQuotes(commandArguments, "l", "0x0409")

		// Set the include paths
		for (directory in arguments.IncludeDirectories) {
			MSVCArgumentBuilder.AddFlagValueWithQuotes(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentParameter_Include, directory.toString)
		}

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.ResourceFile.TargetFile
		MSVCArgumentBuilder.AddFlagValueWithQuotes(
			commandArguments,
			MSVCArgumentBuilder.Compiler_ArgumentParameter_ObjectFile,
			absoluteTargetFile.toString)

		// Add the source file as input
		commandArguments.add(arguments.ResourceFile.SourceFile.toString)

		return commandArguments
	}

	static BuildInterfaceUnitCompilerArguments(
		targetRootDirectory,
		arguments,
		responseFile) {
		// Build the arguments for a standard translation unit
		var commandArguments = []

		// Add the response file
		commandArguments.add("@" + responseFile.toString)

		// Add the module references as input
		for (module in arguments.IncludeModules) {
			MSVCArgumentBuilder.AddFlag(commandArguments, "reference")
			MSVCArgumentBuilder.AddValue(commandArguments, module.value.toString)
		}

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.toString)

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.TargetFile
		MSVCArgumentBuilder.AddFlagValueWithQuotes(
			commandArguments,
			MSVCArgumentBuilder.Compiler_ArgumentParameter_ObjectFile,
			absoluteTargetFile.toString)

		// Add the unique arguments for an interface unit
		MSVCArgumentBuilder.AddFlag(commandArguments, "interface")

		// Specify the module interface file output
		MSVCArgumentBuilder.AddFlag(commandArguments, "ifcOutput")

		var absoluteModuleInterfaceFile = targetRootDirectory + arguments.ModuleInterfaceTarget
		MSVCArgumentBuilder.AddValue(commandArguments, absoluteModuleInterfaceFile.toString)

		return commandArguments
	}

	static BuildPartitionUnitCompilerArguments(
		targetRootDirectory,
		arguments,
		responseFile) {
		// Build the arguments for a standard translation unit
		var commandArguments = []

		// Add the response file
		commandArguments.add("@" + responseFile.toString)

		// Add the module references as input
		for (module in arguments.IncludeModules) {
			MSVCArgumentBuilder.AddFlag(commandArguments, "reference")
			MSVCArgumentBuilder.AddValue(commandArguments, module.value.toString)
		}

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.toString)

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.TargetFile
		MSVCArgumentBuilder.AddFlagValueWithQuotes(
			commandArguments,
			MSVCArgumentBuilder.Compiler_ArgumentParameter_ObjectFile,
			absoluteTargetFile.toString)

		// Add the unique arguments for an partition unit
		MSVCArgumentBuilder.AddFlag(commandArguments, "interface")

		// Specify the module interface file output
		MSVCArgumentBuilder.AddFlag(commandArguments, "ifcOutput")

		var absoluteModuleInterfaceFile = targetRootDirectory + arguments.ModuleInterfaceTarget
		MSVCArgumentBuilder.AddValue(commandArguments, absoluteModuleInterfaceFile.toString)

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
		commandArguments.add("@" + responseFile.toString)

		// Add the internal module references as input
		for (module in arguments.IncludeModules) {
			MSVCArgumentBuilder.AddFlag(commandArguments, "reference")
			MSVCArgumentBuilder.AddValue(commandArguments, module.value.toString)
		}

		// Add the internal module references as input
		for (module in internalModules) {
			MSVCArgumentBuilder.AddFlag(commandArguments, "reference")
			MSVCArgumentBuilder.AddValue(commandArguments, module.value.toString)
		}

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.toString)

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.TargetFile
		MSVCArgumentBuilder.AddFlagValueWithQuotes(
			commandArguments,
			MSVCArgumentBuilder.Compiler_ArgumentParameter_ObjectFile,
			absoluteTargetFile.toString)

		return commandArguments
	}

	static BuildAssemblyUnitCompilerArguments(
		targetRootDirectory,
		sharedArguments,
		arguments) {
		// Build the arguments for a standard translation unit
		var commandArguments = []

		// Disable the logo
		MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.ArgumentFlag_NoLogo)

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.TargetFile
		MSVCArgumentBuilder.AddFlagValueWithQuotes(
			commandArguments,
			MSVCArgumentBuilder.Compiler_ArgumentParameter_ObjectFile,
			absoluteTargetFile.toString)

		// Only run preprocessor, compile and assemble
		MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentFlag_CompileOnly)

		// Generate debug information
		MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentFlag_GenerateDebugInformation)

		// Enable warnings
		MSVCArgumentBuilder.AddFlag(commandArguments, "W3")

		// Set the include paths
		for (directory in sharedArguments.IncludeDirectories) {
			MSVCArgumentBuilder.AddFlagValueWithQuotes(commandArguments, MSVCArgumentBuilder.Compiler_ArgumentParameter_Include, directory.toString)
		}

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.toString)

		return commandArguments
	}

	static BuildLinkerArguments(arguments) {
		// Verify the input
		if (arguments.TargetFile.GetFileName() == null) {
			Fiber.abort("Target file cannot be empty.")
		}

		var commandArguments = []

		// Disable the logo
		MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.ArgumentFlag_NoLogo)

		// Disable incremental linking. I believe this is causing issues as the linker reads and writes to the same file
		MSVCArgumentBuilder.AddParameter(commandArguments, "INCREMENTAL", "NO")

		// Disable the default libraries, we will set this up
		// MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Linker_ArgumentFlag_NoDefaultLibraries)

		// Enable verbose output
		// MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Linker_ArgumentFlag_Verbose)

		// Generate source debug information
		if (arguments.GenerateSourceDebugInfo) {
			MSVCArgumentBuilder.AddParameter(commandArguments, "debug", "full")
		}

		// Calculate object output file
		if (arguments.TargetType == LinkTarget.StaticLibrary) {
			// Nothing to do
		} else if (arguments.TargetType == LinkTarget.DynamicLibrary) {
			// TODO: May want to specify the exact value
			// set the default lib to mutlithreaded
			// MSVCArgumentBuilder.AddParameter(commandArguments, "defaultlib", "libcmt")
			MSVCArgumentBuilder.AddParameter(commandArguments, "subsystem", "console")

			// Create a dynamic library
			MSVCArgumentBuilder.AddFlag(commandArguments, MSVCArgumentBuilder.Linker_ArgumentFlag_DLL)

			// Set the output implementation library
			MSVCArgumentBuilder.AddParameterWithQuotes(
				commandArguments,
				MSVCArgumentBuilder.Linker_ArgumentParameter_ImplementationLibrary,
				arguments.ImplementationFile.toString)
		} else if (arguments.TargetType == LinkTarget.Executable) {
			// TODO: May want to specify the exact value
			// set the default lib to multithreaded
			// MSVCArgumentBuilder.AddParameter(commandArguments, "defaultlib", "libcmt")
			MSVCArgumentBuilder.AddParameter(commandArguments, "subsystem", "console")
		} else if (arguments.TargetType == LinkTarget.WindowsApplication) {
			// TODO: May want to specify the exact value
			// set the default lib to multithreaded
			// MSVCArgumentBuilder.AddParameter(commandArguments, "defaultlib", "libcmt")
			MSVCArgumentBuilder.AddParameter(commandArguments, "subsystem", "windows")
		} else {
			Fiber.abort("Unknown LinkTarget.")
		}

		// Add the machine target
		if (arguments.TargetArchitecture == "x64") {
			MSVCArgumentBuilder.AddParameter(commandArguments, MSVCArgumentBuilder.Linker_ArgumentParameter_Machine, MSVCArgumentBuilder.Linker_ArgumentValue_X64)
		} else if (arguments.TargetArchitecture == "x86") {
			MSVCArgumentBuilder.AddParameter(commandArguments, MSVCArgumentBuilder.Linker_ArgumentParameter_Machine, MSVCArgumentBuilder.Linker_ArgumentValue_X86)
		} else {
			Fiber.abort("Unknown target architecture.")
		}

		// Set the library paths
		for (directory in arguments.LibraryPaths) {
			MSVCArgumentBuilder.AddParameterWithQuotes(commandArguments, MSVCArgumentBuilder.Linker_ArgumentParameter_LibraryPath, directory.toString)
		}

		// Add the target as an output
		MSVCArgumentBuilder.AddParameterWithQuotes(commandArguments, MSVCArgumentBuilder.Linker_ArgumentParameter_Output, arguments.TargetFile.toString)

		// Add the library files
		for (file in arguments.LibraryFiles) {
			// Add the library files as input
			commandArguments.add(file.toString)
		}

		// Add the external libraries as default libraries so they are resolved last
		for (file in arguments.ExternalLibraryFiles) {
			// Add the external library files as input
			// TODO: Explicitly ignore these files from the input for now
			MSVCArgumentBuilder.AddParameter(commandArguments, MSVCArgumentBuilder.Linker_ArgumentParameter_DefaultLibrary, file.toString)
		}

		// Add the object files
		for (file in arguments.ObjectFiles) {
			// Add the object files as input
			commandArguments.add(file.toString)
		}

		return commandArguments
	}

	static AddValue(arguments, value) {
		arguments.add("%(value)")
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

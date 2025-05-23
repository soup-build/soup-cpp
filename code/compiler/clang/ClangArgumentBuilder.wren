// <copyright file="ClangArgumentBuilder.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "Soup|Cpp.Compiler:./CompileArguments" for LanguageStandard, OptimizationLevel
import "Soup|Cpp.Compiler:./LinkArguments" for LinkTarget

/// <summary>
/// A helper class that builds the correct set of compiler arguments for a given
/// set of options.
/// </summary>
class ClangArgumentBuilder {
	static Compiler_ArgumentFlag_GenerateDebugInformation { "g" }
	static Compiler_ArgumentFlag_CompileOnly { "c" }
	static Compiler_ArgumentFlag_Optimization_Disable { "O0" }
	static Compiler_ArgumentFlag_Optimization_Speed { "O3" }
	static Compiler_ArgumentFlag_Optimization_Size { "Os" }
	static Compiler_ArgumentParameter_Standard { "std" }
	static Compiler_ArgumentParameter_Output { "o" }
	static Compiler_ArgumentParameter_Include { "I" }
	static Compiler_ArgumentParameter_PreprocessorDefine { "D" }

	static Linker_ArgumentFlag_DLL { "dll" }
	static Linker_ArgumentParameter_Output { "o" }
	static Linker_ArgumentParameter_ImplementationLibrary { "implib" }
	static Linker_ArgumentParameter_LibraryPath { "libpath" }
	static Linker_ArgumentParameter_DefaultLibrary { "defaultlib" }
	static Linker_ArgumentValue_X64 { "X64" }
	static Linker_ArgumentValue_X86 { "X86" }

	static BuildSharedCompilerArguments(arguments) {
		// Calculate object output file
		var commandArguments = []

		// Generate source debug information
		if (arguments.GenerateSourceDebugInfo) {
			ClangArgumentBuilder.AddFlag(commandArguments, ClangArgumentBuilder.Compiler_ArgumentFlag_GenerateDebugInformation)
		}

		// Enable verbose output
		// ClangArgumentBuilder.AddFlag(commandArguments, "v")

		// Disabled individual warnings
		if (arguments.EnableWarningsAsErrors) {
			ClangArgumentBuilder.AddFlag(commandArguments, "Werror")
		}

		// Disable any requested warnings
		for (warning in arguments.DisabledWarnings) {
			ClangArgumentBuilder.AddFlagValue(commandArguments, "wd", warning)
		}

		// Enable any requested warnings
		for (warning in arguments.EnabledWarnings) {
			ClangArgumentBuilder.AddFlagValue(commandArguments, "w", warning)
		}

		// Convert absolute addresses to relative addresses
		ClangArgumentBuilder.AddFlag(commandArguments, "fpic")
		
		// Uncomment to enable memory checks
		// ClangArgumentBuilder.AddParameter(commandArguments, "fsanitize", "address")
		// ClangArgumentBuilder.AddFlag(commandArguments, "fno-omit-frame-pointer")

		// Set the language standard
		if (arguments.Standard == LanguageStandard.CPP11) {
			ClangArgumentBuilder.AddParameter(commandArguments, ClangArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++11")
		} else if (arguments.Standard == LanguageStandard.CPP14) {
			ClangArgumentBuilder.AddParameter(commandArguments, ClangArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++14")
		} else if (arguments.Standard == LanguageStandard.CPP17) {
			ClangArgumentBuilder.AddParameter(commandArguments, ClangArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++17")
		} else if (arguments.Standard == LanguageStandard.CPP20) {
			ClangArgumentBuilder.AddParameter(commandArguments, ClangArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++20")
		} else {
			Fiber.abort("Unknown language standard %(arguments.Standard).")
		}

		// Set the optimization level
		if (arguments.Optimize == OptimizationLevel.None) {
			ClangArgumentBuilder.AddFlag(commandArguments, ClangArgumentBuilder.Compiler_ArgumentFlag_Optimization_Disable)
		} else if (arguments.Optimize == OptimizationLevel.Speed) {
			ClangArgumentBuilder.AddFlag(commandArguments, ClangArgumentBuilder.Compiler_ArgumentFlag_Optimization_Speed)
		} else if (arguments.Optimize == OptimizationLevel.Size) {
			ClangArgumentBuilder.AddFlag(commandArguments, ClangArgumentBuilder.Compiler_ArgumentFlag_Optimization_Size)
		} else {
			Fiber.abort("Unknown optimization level %(arguments.Optimize)")
		}

		// Set the include paths
		for (directory in arguments.IncludeDirectories) {
			ClangArgumentBuilder.AddFlagValueWithQuotes(commandArguments, ClangArgumentBuilder.Compiler_ArgumentParameter_Include, directory.toString)
		}

		// Set the preprocessor definitions
		for (definition in arguments.PreprocessorDefinitions) {
			ClangArgumentBuilder.AddFlagValue(commandArguments, ClangArgumentBuilder.Compiler_ArgumentParameter_PreprocessorDefine, definition)
		}

		// Add the module references as input
		for (module in arguments.IncludeModules) {
			ClangArgumentBuilder.AddDoubleParameter(
				commandArguments,
				"fmodule-file",
				module.key,
				module.value.toString)
		}

		// Enable SIMD features
		// TODO: Put behind an optional flag
		ClangArgumentBuilder.AddFlag(commandArguments, "mpclmul")
		ClangArgumentBuilder.AddFlag(commandArguments, "maes")
		ClangArgumentBuilder.AddFlag(commandArguments, "msse4.1")
		ClangArgumentBuilder.AddFlag(commandArguments, "msha")

		// Only run preprocessor, compile and assemble
		ClangArgumentBuilder.AddFlag(commandArguments, ClangArgumentBuilder.Compiler_ArgumentFlag_CompileOnly)

		// option ClangArgumentBuilder.AddParameter(commandArguments, "stdlib", "libc++")

		return commandArguments
	}

	static BuildInterfaceUnitPrecompileCompilerArguments(
		targetRootDirectory,
		arguments,
		responseFile) {
		// Build the arguments for a standard translation unit
		var commandArguments = []

		// Add the response file
		commandArguments.add("@" + responseFile.toString)

		// Add the module references as input
		for (module in arguments.IncludeModules) {
			ClangArgumentBuilder.AddDoubleParameter(
				commandArguments,
				"fmodule-file",
				module.key,
				module.value.toString)
		}

		// Clang wants to use cppm for their module files, I think this is dumb
		ClangArgumentBuilder.AddFlag(commandArguments, "x")
		ClangArgumentBuilder.AddValue(commandArguments, "c++-module")

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.toString)

		// Precompile the module interface
		ClangArgumentBuilder.AddFlag(commandArguments, "-precompile")

		// Add the module interface file as outputs
		var absoluteModuleInterfaceFile = targetRootDirectory + arguments.ModuleInterfaceTarget
		ClangArgumentBuilder.AddFlag(
			commandArguments,
			ClangArgumentBuilder.Compiler_ArgumentParameter_Output)
		ClangArgumentBuilder.AddValue(
			commandArguments,
			absoluteModuleInterfaceFile.toString)

		return commandArguments
	}

	static BuildInterfaceUnitCompileCompilerArguments(
		sharedArguments,
		arguments) {
		// Build the arguments for a standard translation unit
		var commandArguments = []

		// Convert absolute addresses to relative addresses
		ClangArgumentBuilder.AddFlag(commandArguments, "fpic")

		// Only run preprocessor, compile and assemble
		ClangArgumentBuilder.AddFlag(commandArguments, ClangArgumentBuilder.Compiler_ArgumentFlag_CompileOnly)

		// Generate source debug information
		if (sharedArguments.GenerateSourceDebugInfo) {
			ClangArgumentBuilder.AddFlag(commandArguments, ClangArgumentBuilder.Compiler_ArgumentFlag_GenerateDebugInformation)
		}

		// Add the shared module references as input
		for (module in sharedArguments.IncludeModules) {
			ClangArgumentBuilder.AddDoubleParameter(
				commandArguments,
				"fmodule-file",
				module.key,
				module.value.toString)
		}

		// Add the module references as input
		for (module in arguments.IncludeModules) {
			ClangArgumentBuilder.AddDoubleParameter(
				commandArguments,
				"fmodule-file",
				module.key,
				module.value.toString)
		}

		// Reference the single precompiled interface
		var absoluteModuleInterfaceFile = sharedArguments.TargetRootDirectory + arguments.ModuleInterfaceTarget
		ClangArgumentBuilder.AddValue(commandArguments, absoluteModuleInterfaceFile.toString)

		// Add the target file as outputs
		var absoluteTargetFile = sharedArguments.TargetRootDirectory + arguments.TargetFile
		ClangArgumentBuilder.AddFlag(
			commandArguments,
			ClangArgumentBuilder.Compiler_ArgumentParameter_Output)
		ClangArgumentBuilder.AddValue(
			commandArguments,
			absoluteTargetFile.toString)

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
			ClangArgumentBuilder.AddDoubleParameter(
				commandArguments,
				"fmodule-file",
				module.key,
				module.value.toString)
		}

		// Add the internal module references as input
		for (module in internalModules) {
			ClangArgumentBuilder.AddDoubleParameter(
				commandArguments,
				"fmodule-file",
				module.key,
				module.value.toString)
		}

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.toString)

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.TargetFile
		ClangArgumentBuilder.AddFlag(
			commandArguments,
			ClangArgumentBuilder.Compiler_ArgumentParameter_Output)
		ClangArgumentBuilder.AddValue(
			commandArguments,
			absoluteTargetFile.toString)

		return commandArguments
	}

	static BuildAssemblyUnitCompilerArguments(
		targetRootDirectory,
		sharedArguments,
		arguments) {
		// Build the arguments for a standard translation unit
		var commandArguments = []

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.TargetFile
		ClangArgumentBuilder.AddFlag(
			commandArguments,
			ClangArgumentBuilder.Compiler_ArgumentParameter_Output)
		ClangArgumentBuilder.AddValue(
			commandArguments,
			absoluteTargetFile.toString)

		// Only run preprocessor, compile and assemble
		ClangArgumentBuilder.AddFlag(commandArguments, ClangArgumentBuilder.Compiler_ArgumentFlag_CompileOnly)

		// Set the include paths
		for (directory in sharedArguments.IncludeDirectories) {
			ClangArgumentBuilder.AddFlagValueWithQuotes(commandArguments, ClangArgumentBuilder.Compiler_ArgumentParameter_Include, directory.toString)
		}

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.toString)

		return commandArguments
	}

	static BuildStaticLibraryLinkerArguments(arguments) {
		// Verify the input
		if (arguments.TargetFile.GetFileName() == null) {
			Fiber.abort("Target file cannot be empty.")
		}

		var commandArguments = []

		// Create an archive
		ClangArgumentBuilder.AddFlag(commandArguments, "r")
		ClangArgumentBuilder.AddValue(
			commandArguments,
			arguments.TargetFile.toString)

		// Add the object files
		for (file in arguments.ObjectFiles) {
			// Add the object files as input
			commandArguments.add(file.toString)
		}

		return commandArguments
	}

	static BuildDynamicLibraryLinkerArguments(arguments) {
		// Verify the input
		if (arguments.TargetFile.GetFileName() == null) {
			Fiber.abort("Target file cannot be empty.")
		}

		var commandArguments = []

		// Create a shared library
		ClangArgumentBuilder.AddFlag(commandArguments, "shared")

		// Convert absolute addresses to relative addresses
		ClangArgumentBuilder.AddFlag(commandArguments, "fpic")

		// Set the library paths
		for (directory in arguments.LibraryPaths) {
			ClangArgumentBuilder.AddParameterWithQuotes(
				commandArguments,
				ClangArgumentBuilder.Linker_ArgumentParameter_LibraryPath,
				directory.toString)
		}

		// Add the target as an output
		ClangArgumentBuilder.AddFlag(
			commandArguments,
			ClangArgumentBuilder.Linker_ArgumentParameter_Output)
		ClangArgumentBuilder.AddValue(
			commandArguments,
			arguments.TargetFile.toString)

		// Add the object files
		for (file in arguments.ObjectFiles) {
			// Add the object files as input
			commandArguments.add(file.toString)
		}

		// Add the library files
		for (file in arguments.LibraryFiles) {
			// Add the library files as input
			commandArguments.add(file.toString)
		}

		// Add the external libraries as default libraries so they are resolved last
		for (file in arguments.ExternalLibraryFiles) {
			// Add the external library files as input
			// TODO: Explicitly ignore these files from the input for now
			ClangArgumentBuilder.AddParameter(
				commandArguments,
				ClangArgumentBuilder.Linker_ArgumentParameter_DefaultLibrary,
				file.toString)
		}

		return commandArguments
	}

	static BuildExecutableLinkerArguments(arguments) {
		// Verify the input
		if (arguments.TargetFile.GetFileName() == null) {
			Fiber.abort("Target file cannot be empty.")
		}

		var commandArguments = []

		// Enable verbose output
		// ClangArgumentBuilder.AddFlag(commandArguments, "v")

		// Memory checks
		// ClangArgumentBuilder.AddParameter(commandArguments, "fsanitize", "address")
		// ClangArgumentBuilder.AddFlag(commandArguments, "fno-omit-frame-pointer")
		
		// Set the library paths
		for (directory in arguments.LibraryPaths) {
			ClangArgumentBuilder.AddParameterWithQuotes(
				commandArguments,
				ClangArgumentBuilder.Linker_ArgumentParameter_LibraryPath,
				directory.toString)
		}

		// Add the target as an output
		ClangArgumentBuilder.AddFlag(
			commandArguments,
			ClangArgumentBuilder.Linker_ArgumentParameter_Output)
		ClangArgumentBuilder.AddValue(
			commandArguments,
			arguments.TargetFile.toString)

		// Add the object files
		for (file in arguments.ObjectFiles) {
			// Add the object files as input
			commandArguments.add(file.toString)
		}

		// Add the library files
		for (file in arguments.LibraryFiles) {
			// Add the library files as input
			commandArguments.add(file.toString)
		}

		// Add the external libraries as default libraries so they are resolved last
		for (file in arguments.ExternalLibraryFiles) {
			// Add the external library files as input
			// TODO: Explicitly ignore these files from the input for now
			ClangArgumentBuilder.AddParameter(
				commandArguments,
				ClangArgumentBuilder.Linker_ArgumentParameter_DefaultLibrary,
				file.toString)
		}

		return commandArguments
	}

	static AddValue(arguments, value) {
		arguments.add("%(value)")
	}

	static AddFlag(arguments, flag) {
		arguments.add("-%(flag)")
	}

	static AddFlagValue(arguments, flag, value) {
		arguments.add("-%(flag)%(value)")
	}

	static AddFlagValueWithQuotes(arguments, flag, value) {
		arguments.add("-%(flag)\"%(value)\"")
	}

	static AddParameter(arguments, name, value) {
		arguments.add("-%(name)=%(value)")
	}

	static AddParameterWithQuotes(arguments, name, value) {
		arguments.add("-%(name)=\"%(value)\"")
	}

	static AddDoubleParameter(arguments, name, value1, value2) {
		arguments.add("-%(name)=%(value1)=%(value2)")
	}
}

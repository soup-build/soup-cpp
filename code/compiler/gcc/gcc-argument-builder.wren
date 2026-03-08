// <copyright file="gcc-argument-builder.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "Soup|Cpp.Compiler:./compile-arguments" for LanguageStandard, OptimizationLevel
import "Soup|Cpp.Compiler:./link-arguments" for LinkTarget

/// <summary>
/// A helper class that builds the correct set of compiler arguments for a given
/// set of options.
/// </summary>
class GCCArgumentBuilder {
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
			GCCArgumentBuilder.AddFlag(commandArguments, GCCArgumentBuilder.Compiler_ArgumentFlag_GenerateDebugInformation)
		}

		// Disabled individual warnings
		if (arguments.EnableWarningsAsErrors) {
			GCCArgumentBuilder.AddFlag(commandArguments, "Werror")
		}

		// Disable any requested warnings
		for (warning in arguments.DisabledWarnings) {
			GCCArgumentBuilder.AddFlagValue(commandArguments, "wd", warning)
		}

		// Enable any requested warnings
		for (warning in arguments.EnabledWarnings) {
			GCCArgumentBuilder.AddFlagValue(commandArguments, "w", warning)
		}

		// Uncomment to enable memory checks
		// GCCArgumentBuilder.AddParameter(commandArguments, "fsanitize", "address")
		
		// Set the language standard
		if (arguments.Standard == LanguageStandard.CPP11) {
			GCCArgumentBuilder.AddParameter(commandArguments, GCCArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++11")
		} else if (arguments.Standard == LanguageStandard.CPP14) {
			GCCArgumentBuilder.AddParameter(commandArguments, GCCArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++14")
		} else if (arguments.Standard == LanguageStandard.CPP17) {
			GCCArgumentBuilder.AddParameter(commandArguments, GCCArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++17")
		} else if (arguments.Standard == LanguageStandard.CPP20) {
			GCCArgumentBuilder.AddParameter(commandArguments, GCCArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++20")
		} else if (arguments.Standard == LanguageStandard.CPP23) {
			GCCArgumentBuilder.AddParameter(commandArguments, GCCArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++23")
		} else if (arguments.Standard == LanguageStandard.CPP26) {
			GCCArgumentBuilder.AddParameter(commandArguments, GCCArgumentBuilder.Compiler_ArgumentParameter_Standard, "c++26")
		} else {
			Fiber.abort("Unknown language standard %(arguments.Standard).")
		}

		// Set the optimization level
		if (arguments.Optimize == OptimizationLevel.None) {
			GCCArgumentBuilder.AddFlag(commandArguments, GCCArgumentBuilder.Compiler_ArgumentFlag_Optimization_Disable)
		} else if (arguments.Optimize == OptimizationLevel.Speed) {
			GCCArgumentBuilder.AddFlag(commandArguments, GCCArgumentBuilder.Compiler_ArgumentFlag_Optimization_Speed)
		} else if (arguments.Optimize == OptimizationLevel.Size) {
			GCCArgumentBuilder.AddFlag(commandArguments, GCCArgumentBuilder.Compiler_ArgumentFlag_Optimization_Size)
		} else {
			Fiber.abort("Unknown optimization level %(arguments.Optimize)")
		}

		// Set the include paths
		for (directory in arguments.IncludeDirectories) {
			GCCArgumentBuilder.AddFlagValueWithQuotes(commandArguments, GCCArgumentBuilder.Compiler_ArgumentParameter_Include, directory.toString)
		}

		// Set the preprocessor definitions
		for (definition in arguments.PreprocessorDefinitions) {
			GCCArgumentBuilder.AddFlagValue(commandArguments, GCCArgumentBuilder.Compiler_ArgumentParameter_PreprocessorDefine, definition)
		}

		// Add the module references as input
		for (module in arguments.IncludeModules) {
			GCCArgumentBuilder.AddFlag(commandArguments, "reference")
			GCCArgumentBuilder.AddValue(commandArguments, module.value.toString)
		}

		// Only run preprocessor, compile and assemble
		GCCArgumentBuilder.AddFlag(commandArguments, GCCArgumentBuilder.Compiler_ArgumentFlag_CompileOnly)

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

		// TODO: Defines?
		GCCArgumentBuilder.AddFlagValue(commandArguments, GCCArgumentBuilder.Compiler_ArgumentParameter_PreprocessorDefine, "_UNICODE")
		GCCArgumentBuilder.AddFlagValue(commandArguments, GCCArgumentBuilder.Compiler_ArgumentParameter_PreprocessorDefine, "UNICODE")

		// Specify default language using language identifier
		GCCArgumentBuilder.AddFlagValueWithQuotes(commandArguments, "l", "0x0409")

		// Set the include paths
		for (directory in arguments.IncludeDirectories) {
			GCCArgumentBuilder.AddFlagValueWithQuotes(commandArguments, GCCArgumentBuilder.Compiler_ArgumentParameter_Include, directory.toString)
		}

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.ResourceFile.TargetFile
		GCCArgumentBuilder.AddFlag(
			commandArguments,
			GCCArgumentBuilder.Compiler_ArgumentParameter_Output)
		GCCArgumentBuilder.AddValue(
			commandArguments,
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
			GCCArgumentBuilder.AddFlag(commandArguments, "reference")
			GCCArgumentBuilder.AddValue(commandArguments, module.value.toString)
		}

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.toString)

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.TargetFile
		GCCArgumentBuilder.AddFlag(
			commandArguments,
			GCCArgumentBuilder.Compiler_ArgumentParameter_Output)
		GCCArgumentBuilder.AddValue(
			commandArguments,
			absoluteTargetFile.toString)

		// Add the unique arguments for an interface unit
		GCCArgumentBuilder.AddFlag(commandArguments, "fmodules-ts")

		// Specify the module interface file output
		// GCCArgumentBuilder.AddFlag(commandArguments, "ifcOutput")

		// var absoluteModuleInterfaceFile = targetRootDirectory + arguments.ModuleInterfaceTarget
		// GCCArgumentBuilder.AddValue(commandArguments, absoluteModuleInterfaceFile.toString)

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
			GCCArgumentBuilder.AddFlag(commandArguments, "reference")
			GCCArgumentBuilder.AddValue(commandArguments, module.value.toString)
		}

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.toString)

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.TargetFile
		GCCArgumentBuilder.AddFlag(
			commandArguments,
			GCCArgumentBuilder.Compiler_ArgumentParameter_Output)
		GCCArgumentBuilder.AddValue(
			commandArguments,
			absoluteTargetFile.toString)

		// Add the unique arguments for an partition unit
		GCCArgumentBuilder.AddFlag(commandArguments, "interface")

		// Specify the module interface file output
		GCCArgumentBuilder.AddFlag(commandArguments, "ifcOutput")

		var absoluteModuleInterfaceFile = targetRootDirectory + arguments.ModuleInterfaceTarget
		GCCArgumentBuilder.AddValue(commandArguments, absoluteModuleInterfaceFile.toString)

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
			GCCArgumentBuilder.AddFlag(commandArguments, "reference")
			GCCArgumentBuilder.AddValue(commandArguments, module.value.toString)
		}

		// Add the internal module references as input
		for (module in internalModules) {
			GCCArgumentBuilder.AddFlag(commandArguments, "reference")
			GCCArgumentBuilder.AddValue(commandArguments, module.value.toString)
		}

		// Add the source file as input
		commandArguments.add(arguments.SourceFile.toString)

		// Add the target file as outputs
		var absoluteTargetFile = targetRootDirectory + arguments.TargetFile
		GCCArgumentBuilder.AddFlag(
			commandArguments,
			GCCArgumentBuilder.Compiler_ArgumentParameter_Output)
		GCCArgumentBuilder.AddValue(
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
		GCCArgumentBuilder.AddFlag(
			commandArguments,
			GCCArgumentBuilder.Compiler_ArgumentParameter_Output)
		GCCArgumentBuilder.AddValue(
			commandArguments,
			absoluteTargetFile.toString)

		// Only run preprocessor, compile and assemble
		GCCArgumentBuilder.AddFlag(commandArguments, GCCArgumentBuilder.Compiler_ArgumentFlag_CompileOnly)

		// Generate debug information
		GCCArgumentBuilder.AddFlag(commandArguments, GCCArgumentBuilder.Compiler_ArgumentFlag_GenerateDebugInformation)

		// Enable warnings
		GCCArgumentBuilder.AddFlag(commandArguments, "W3")

		// Set the include paths
		for (directory in sharedArguments.IncludeDirectories) {
			GCCArgumentBuilder.AddFlagValueWithQuotes(commandArguments, GCCArgumentBuilder.Compiler_ArgumentParameter_Include, directory.toString)
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

		// Calculate object output file
		if (arguments.TargetType == LinkTarget.StaticLibrary) {
			// Nothing to do
		} else if (arguments.TargetType == LinkTarget.DynamicLibrary) {
			// Create a dynamic library
			GCCArgumentBuilder.AddFlag(commandArguments, GCCArgumentBuilder.Linker_ArgumentFlag_DLL)

			// Set the output implementation library
			GCCArgumentBuilder.AddParameterWithQuotes(
				commandArguments,
				GCCArgumentBuilder.Linker_ArgumentParameter_ImplementationLibrary,
				arguments.ImplementationFile.toString)
		} else if (arguments.TargetType == LinkTarget.Executable) {
		} else if (arguments.TargetType == LinkTarget.WindowsApplication) {
		} else {
			Fiber.abort("Unknown LinkTarget.")
		}

		// Set the library paths
		for (directory in arguments.LibraryPaths) {
			GCCArgumentBuilder.AddParameterWithQuotes(
				commandArguments,
				GCCArgumentBuilder.Linker_ArgumentParameter_LibraryPath,
				directory.toString)
		}

		// Add the target as an output
		GCCArgumentBuilder.AddFlag(
			commandArguments,
			GCCArgumentBuilder.Linker_ArgumentParameter_Output)
		GCCArgumentBuilder.AddValue(
			commandArguments,
			arguments.TargetFile.toString)

		// Add the library files
		for (file in arguments.LibraryFiles) {
			// Add the library files as input
			commandArguments.add(file.toString)
		}

		// Add the external libraries as default libraries so they are resolved last
		for (file in arguments.ExternalLibraryFiles) {
			// Add the external library files as input
			// TODO: Explicitly ignore these files from the input for now
			GCCArgumentBuilder.AddParameter(commandArguments, GCCArgumentBuilder.Linker_ArgumentParameter_DefaultLibrary, file.toString)
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
}

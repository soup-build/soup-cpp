// <copyright file="ClangCompiler.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "Soup|Cpp.Compiler:./ICompiler" for ICompiler
import "Soup|Cpp.Compiler:./LinkArguments" for LinkTarget
import "Soup|Build.Utils:./BuildOperation" for BuildOperation
import "Soup|Build.Utils:./SharedOperations" for SharedOperations
import "Soup|Build.Utils:./Path" for Path
import "./ClangArgumentBuilder" for ClangArgumentBuilder

/// <summary>
/// The Clang compiler implementation
/// </summary>
class ClangCompiler is ICompiler {
	construct new(
		compilerExecutable,
		archiveExecutable) {
		_compilerExecutable = compilerExecutable
		_archiveExecutable = archiveExecutable
	}

	/// <summary>
	/// Gets the unique name for the compiler
	/// </summary>
	Name { "Clang" }

	/// <summary>
	/// Gets the object file extension for the compiler
	/// </summary>
	ObjectFileExtension { "o" }

	/// <summary>
	/// Gets the module file extension for the compiler
	/// </summary>
	ModuleFileExtension { "pcm" }

	/// <summary>
	/// Gets the static library file extension for the compiler
	/// TODO: This is platform specific
	/// </summary>
	CreateStaticLibraryFileName(name) {
		return Path.new("lib%(name).a")
	}

	/// <summary>
	/// Gets the dynamic library file extension for the compiler
	/// TODO: This is platform specific
	/// </summary>
	DynamicLibraryFileExtension { "so" }
	DynamicLibraryLinkFileExtension { "so" }

	/// <summary>
	/// Gets the resource file extension for the compiler
	/// </summary>
	ResourceFileExtension { "res" }

	/// <summary>
	/// Compile
	/// </summary>
	CreateCompileOperations(arguments) {
		var operations = []

		// Write the shared arguments to the response file
		var responseFile = arguments.ObjectDirectory + Path.new("SharedCompileArguments.rsp")
		var sharedCommandArguments = ClangArgumentBuilder.BuildSharedCompilerArguments(arguments)
		var writeSharedArgumentsOperation = SharedOperations.CreateWriteFileOperation(
			arguments.TargetRootDirectory,
			responseFile,
			ClangCompiler.CombineArguments(sharedCommandArguments))
		operations.add(writeSharedArgumentsOperation)

		// Initialize a shared input set
		var sharedInputFiles = []
		for (module in arguments.IncludeModules) {
			sharedInputFiles.add(module.value)
		}

		var absoluteResponseFile = arguments.TargetRootDirectory + responseFile

		// Generate the resource build operation if present
		if (arguments.ResourceFile) {
			Fiber.abort("ResourceFile not supported.")
		}

		var internalModules = {}
		for (partitionUnitArguments in arguments.InterfacePartitionUnits) {
			// Build up the input/output sets
			var inputFiles = [] + sharedInputFiles
			inputFiles.add(partitionUnitArguments.SourceFile)
			inputFiles.add(absoluteResponseFile)
			for (module in partitionUnitArguments.IncludeModules) {
				inputFiles.add(module.value)
			}

			var outputFiles = [
				arguments.TargetRootDirectory + partitionUnitArguments.TargetFile,
				arguments.TargetRootDirectory + partitionUnitArguments.ModuleInterfaceTarget,
			]

			// Build the unique arguments for this translation unit
			var commandArguments = ClangArgumentBuilder.BuildPartitionUnitCompilerArguments(
				arguments.TargetRootDirectory,
				partitionUnitArguments,
				absoluteResponseFile)

			// Generate the operation
			var buildOperation = BuildOperation.new(
				partitionUnitArguments.SourceFile.toString,
				arguments.SourceRootDirectory,
				_compilerExecutable,
				commandArguments,
				inputFiles,
				outputFiles)
			operations.add(buildOperation)

			// Add our module interface back in for the downstream compilers
			internalModules[partitionUnitArguments.ModuleName] = arguments.TargetRootDirectory + partitionUnitArguments.ModuleInterfaceTarget
		}

		// Generate the interface build operation if present
		if (arguments.InterfaceUnit) {
			var interfaceUnitArguments = arguments.InterfaceUnit

			// Clang believes that two phase builds will be faster by precompiling the modue interface
			// and then compiling the object files
			// TODO: This needs to be verified.

			// Build up the input/output sets
			var precompileInputFiles = [] + sharedInputFiles
			precompileInputFiles.add(interfaceUnitArguments.SourceFile)
			precompileInputFiles.add(absoluteResponseFile)
			for (module in interfaceUnitArguments.IncludeModules) {
				precompileInputFiles.add(module.value)
			}

			var precompileOutputFiles = [
				arguments.TargetRootDirectory + interfaceUnitArguments.ModuleInterfaceTarget,
			]

			// Build the unique arguments to precompile this translation unit
			var precompileArguments = ClangArgumentBuilder.BuildInterfaceUnitPrecompileCompilerArguments(
				arguments.TargetRootDirectory,
				interfaceUnitArguments,
				absoluteResponseFile)

			// Generate the precompile operation
			var precompileOperation = BuildOperation.new(
				interfaceUnitArguments.SourceFile.toString,
				arguments.SourceRootDirectory,
				_compilerExecutable,
				precompileArguments,
				precompileInputFiles,
				precompileOutputFiles)
			operations.add(precompileOperation)

			// Build the unique arguments to compile the precompiled module
			var compileArguments = ClangArgumentBuilder.BuildInterfaceUnitCompileCompilerArguments(
				arguments,
				interfaceUnitArguments)

			// Build up the input/output sets
			var compileInputFiles = [
				arguments.TargetRootDirectory + interfaceUnitArguments.ModuleInterfaceTarget,
			]

			var compileOutputFiles = [
				arguments.TargetRootDirectory + interfaceUnitArguments.TargetFile,
			]

			// Generate the compile operation
			var compileOperation = BuildOperation.new(
				interfaceUnitArguments.ModuleInterfaceTarget.toString,
				arguments.SourceRootDirectory,
				_compilerExecutable,
				compileArguments,
				compileInputFiles,
				compileOutputFiles)
			operations.add(compileOperation)

			// Add our module interface back in for the downstream compilers
			internalModules[interfaceUnitArguments.ModuleName] = arguments.TargetRootDirectory + interfaceUnitArguments.ModuleInterfaceTarget
		}

		for (implementationUnitArguments in arguments.ImplementationUnits) {
			// Build up the input/output sets
			var inputFiles = [] + sharedInputFiles
			inputFiles.add(implementationUnitArguments.SourceFile)
			inputFiles.add(absoluteResponseFile)

			for (module in implementationUnitArguments.IncludeModules) {
				inputFiles.add(module.value)
			}

			for (module in internalModules) {
				inputFiles.add(module.value)
			}

			var outputFiles = [
				arguments.TargetRootDirectory + implementationUnitArguments.TargetFile,
			]

			// Build the unique arguments for this translation unit
			var commandArguments = ClangArgumentBuilder.BuildTranslationUnitCompilerArguments(
				arguments.TargetRootDirectory,
				implementationUnitArguments,
				absoluteResponseFile,
				internalModules)

			// Generate the operation
			var buildOperation = BuildOperation.new(
				implementationUnitArguments.SourceFile.toString,
				arguments.SourceRootDirectory,
				_compilerExecutable,
				commandArguments,
				inputFiles,
				outputFiles)
			operations.add(buildOperation)
		}

		for (assemblyUnitArguments in arguments.AssemblyUnits) {
			// Build up the input/output sets
			var inputFiles = [] + sharedInputFiles
			inputFiles.add(assemblyUnitArguments.SourceFile)

			var outputFiles = [
				arguments.TargetRootDirectory + assemblyUnitArguments.TargetFile,
			]

			// Build the unique arguments for this assembly unit
			var commandArguments = ClangArgumentBuilder.BuildAssemblyUnitCompilerArguments(
				arguments.TargetRootDirectory,
				arguments,
				assemblyUnitArguments)

			// Generate the operation
			var buildOperation = BuildOperation.new(
				assemblyUnitArguments.SourceFile.toString,
				arguments.SourceRootDirectory,
				_compilerExecutable,
				commandArguments,
				inputFiles,
				outputFiles)
			operations.add(buildOperation)
		}

		return operations
	}

	/// <summary>
	/// Link
	/// </summary>
	CreateLinkOperation(arguments) {
		// Select the correct executable for linking libraries or executables
		var executablePath
		var commandarguments
		if (arguments.TargetType == LinkTarget.StaticLibrary) {
			executablePath = _archiveExecutable
			commandarguments = ClangArgumentBuilder.BuildStaticLibraryLinkerArguments(arguments)
		} else if (arguments.TargetType == LinkTarget.DynamicLibrary) {
			executablePath = _compilerExecutable
			commandarguments = ClangArgumentBuilder.BuildDynamicLibraryLinkerArguments(arguments)
		} else if (arguments.TargetType == LinkTarget.Executable) {
			executablePath = _compilerExecutable
			commandarguments = ClangArgumentBuilder.BuildExecutableLinkerArguments(arguments)
		} else {
			Fiber.abort("Unknown LinkTarget: %(arguments.TargetType)")
		}

		// Build the set of input/output files along with the arguments
		var inputFiles = []
		inputFiles = inputFiles + arguments.LibraryFiles
		inputFiles = inputFiles + arguments.ObjectFiles
		var outputFiles = [
			arguments.TargetRootDirectory + arguments.TargetFile,
		]

		var buildOperation = BuildOperation.new(
			arguments.TargetFile.toString,
			arguments.TargetRootDirectory,
			executablePath,
			commandarguments,
			inputFiles,
			outputFiles)

		return buildOperation
	}

	static CombineArguments(arguments) {
		return arguments.join(" ")
	}
}

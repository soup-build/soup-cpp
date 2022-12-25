// <copyright file="Compiler.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>
import "../Core/ICompiler" for ICompiler
import "../Core/LinkArguments" for LinkTarget
import "../../BuildOperation" for BuildOperation
import "../../SharedOperations" for SharedOperations
import "../../Path" for Path
import "./ArgumentBuilder" for ArgumentBuilder

/// <summary>
/// The Clang compiler implementation
/// </summary>
class Compiler is ICompiler {
	construct new(
		compilerExecutable,
		linkerExecutable,
		libraryExecutable,
		rcExecutable,
		mlExecutable) {
		_compilerExecutable = compilerExecutable
		_linkerExecutable = linkerExecutable
		_libraryExecutable = libraryExecutable
		_rcExecutable = rcExecutable
		_mlExecutable = mlExecutable
	}

	/// <summary>
	/// Gets the unique name for the compiler
	/// </summary>
	Name { "MSVC" }

	/// <summary>
	/// Gets the object file extension for the compiler
	/// </summary>
	ObjectFileExtension { "obj" }

	/// <summary>
	/// Gets the module file extension for the compiler
	/// </summary>
	ModuleFileExtension { "ifc" }

	/// <summary>
	/// Gets the static library file extension for the compiler
	/// TODO: This is platform specific
	/// </summary>
	StaticLibraryFileExtension { "lib" }

	/// <summary>
	/// Gets the dynamic library file extension for the compiler
	/// TODO: This is platform specific
	/// </summary>
	DynamicLibraryFileExtension { "dll" }

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
		var sharedCommandArguments = ArgumentBuilder.BuildSharedCompilerArguments(arguments)
		var writeSharedArgumentsOperation = SharedOperations.CreateWriteFileOperation(
			arguments.TargetRootDirectory,
			responseFile,
			this.CombineArguments(sharedCommandArguments))
		operations.Add(writeSharedArgumentsOperation)

		// Initialize a shared input set
		var sharedInputFiles = []
		sharedInputFiles.AddRange(arguments.IncludeModules)

		var absoluteResponseFile = arguments.TargetRootDirectory + responseFile

		// Generate the resource build operation if present
		if (arguments.ResourceFile) {
			var resourceFileArguments = arguments.ResourceFile

			// Build up the input/output sets
			var inputFiles = sharedInputFiles.ToList()
			inputFiles.Add(resourceFileArguments.SourceFile)
			// TODO: The temp files require read access, need a way to tell build operation
			inputFiles.Add(arguments.TargetRootDirectory + Path.new("fake_file"))
			var outputFiles = [
				arguments.TargetRootDirectory + resourceFileArguments.TargetFile,
			]

			// Build the unique arguments for this resource file
			var commandArguments = ArgumentBuilder.BuildResourceCompilerArguments(
				arguments.TargetRootDirectory,
				arguments)

			// Generate the operation
			var buildOperation = BuildOperation.new(
				resourceFileArguments.SourceFile.ToString(),
				arguments.SourceRootDirectory,
				_rcExecutable,
				this.CombineArguments(commandArguments),
				inputFiles,
				outputFiles)
			operations.Add(buildOperation)
		}

		var internalModules = []
		for (partitionUnitArguments in arguments.InterfacePartitionUnits) {
			// Build up the input/output sets
			var inputFiles = sharedInputFiles.ToList()
			inputFiles.Add(partitionUnitArguments.SourceFile)
			inputFiles.Add(absoluteResponseFile)
			inputFiles.AddRange(partitionUnitArguments.IncludeModules)

			var outputFiles = [
				arguments.TargetRootDirectory + partitionUnitArguments.TargetFile,
				arguments.TargetRootDirectory + partitionUnitArguments.ModuleInterfaceTarget,
			]

			// Build the unique arguments for this translation unit
			var commandArguments = ArgumentBuilder.BuildPartitionUnitCompilerArguments(
				arguments.TargetRootDirectory,
				partitionUnitArguments,
				absoluteResponseFile)

			// Generate the operation
			var buildOperation = BuildOperation.new(
				partitionUnitArguments.SourceFile.ToString(),
				arguments.SourceRootDirectory,
				_compilerExecutable,
				this.CombineArguments(commandArguments),
				inputFiles.ToArray(),
				outputFiles)
			operations.Add(buildOperation)

			// Add our module interface back in for the downstream compilers
			internalModules.Add(arguments.TargetRootDirectory + partitionUnitArguments.ModuleInterfaceTarget)
		}

		// Generate the interface build operation if present
		if (arguments.InterfaceUnit) {
			var interfaceUnitArguments = arguments.InterfaceUnit

			// Build up the input/output sets
			var inputFiles = sharedInputFiles.ToList()
			inputFiles.Add(interfaceUnitArguments.SourceFile)
			inputFiles.Add(absoluteResponseFile)
			inputFiles.AddRange(interfaceUnitArguments.IncludeModules)

			var outputFiles = [
				arguments.TargetRootDirectory + interfaceUnitArguments.TargetFile,
				arguments.TargetRootDirectory + interfaceUnitArguments.ModuleInterfaceTarget,
			]

			// Build the unique arguments for this translation unit
			var commandArguments = ArgumentBuilder.BuildInterfaceUnitCompilerArguments(
				arguments.TargetRootDirectory,
				interfaceUnitArguments,
				absoluteResponseFile)

			// Generate the operation
			var buildOperation = BuildOperation.new(
				interfaceUnitArguments.SourceFile.ToString(),
				arguments.SourceRootDirectory,
				_compilerExecutable,
				this.CombineArguments(commandArguments),
				inputFiles,
				outputFiles)
			operations.Add(buildOperation)

			// Add our module interface back in for the downstream compilers
			internalModules.Add(arguments.TargetRootDirectory + interfaceUnitArguments.ModuleInterfaceTarget)
		}

		for (implementationUnitArguments in arguments.ImplementationUnits) {
			// Build up the input/output sets
			var inputFiles = sharedInputFiles.ToList()
			inputFiles.Add(implementationUnitArguments.SourceFile)
			inputFiles.Add(absoluteResponseFile)
			inputFiles.AddRange(implementationUnitArguments.IncludeModules)
			inputFiles.AddRange(internalModules)

			var outputFiles = [
				arguments.TargetRootDirectory + implementationUnitArguments.TargetFile,
			]

			// Build the unique arguments for this translation unit
			var commandArguments = ArgumentBuilder.BuildTranslationUnitCompilerArguments(
				arguments.TargetRootDirectory,
				implementationUnitArguments,
				absoluteResponseFile,
				internalModules)

			// Generate the operation
			var buildOperation = BuildOperation.new(
				implementationUnitArguments.SourceFile.ToString(),
				arguments.SourceRootDirectory,
				_compilerExecutable,
				this.CombineArguments(commandArguments),
				inputFiles.ToArray(),
				outputFiles)
			operations.Add(buildOperation)
		}

		for (assemblyUnitArguments in arguments.AssemblyUnits) {
			// Build up the input/output sets
			var inputFiles = sharedInputFiles.ToList()
			inputFiles.Add(assemblyUnitArguments.SourceFile)

			var outputFiles = [
				arguments.TargetRootDirectory + assemblyUnitArguments.TargetFile,
			]

			// Build the unique arguments for this assembly unit
			var commandArguments = ArgumentBuilder.BuildAssemblyUnitCompilerArguments(
				arguments.TargetRootDirectory,
				arguments,
				assemblyUnitArguments)

			// Generate the operation
			var buildOperation = BuildOperation.new(
				assemblyUnitArguments.SourceFile.ToString(),
				arguments.SourceRootDirectory,
				_mlExecutable,
				this.CombineArguments(commandArguments),
				inputFiles.ToArray(),
				outputFiles)
			operations.Add(buildOperation)
		}

		return operations
	}

	/// <summary>
	/// Link
	/// </summary>
	CreateLinkOperation(arguments) {
		// Select the correct executable for linking libraries or executables
		executablePath
		if (arguments.TargetType == LinkTarget.StaticLibrary) {
			executable= _libraryExecutable
		} else if (arguments.TargetType == LinkTarget.DynamicLibrary ||
			arguments.TargetType == LinkTarget.Executable ||
			arguments.TargetType == LinkTarget.WindowsApplication) {
			executable= _linkerExecutable
		} else {
			Fiber.abort("Unknown LinkTarget.")
		}

		// Build the set of input/output files along with the arguments
		var inputFiles = []
		inputFiles.AddRange(arguments.LibraryFiles)
		inputFiles.AddRange(arguments.ObjectFiles)
		var outputFiles = [
			arguments.TargetRootDirectory + arguments.TargetFile,
		]
		var commandarguments = ArgumentBuilder.BuildLinkerArguments(arguments)

		var buildOperation = BuildOperation.new(
			arguments.TargetFile.ToString(),
			arguments.TargetRootDirectory,
			executablePath,
			this.CombineArguments(commandarguments),
			inputFiles,
			outputFiles)

		return buildOperation
	}

	static CombineArguments(arguments) {
		return string.Join(" ", arguments)
	}
}

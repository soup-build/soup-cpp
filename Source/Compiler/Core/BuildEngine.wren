// <copyright file="BuildEngine.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "./BuildResult" for BuildResult
import "./BuildArguments" for BuildOptimizationLevel, BuildTargetType
import "./LinkArguments" for LinkArguments, LinkTarget
import "./CompileArguments" for InterfaceUnitCompileArguments, OptimizationLevel, ResourceCompileArguments, SharedCompileArguments, TranslationUnitCompileArguments
import "../../IBuildState" for TraceLevel
import "../../Path" for Path
import "../../Set" for Set
import "../../SharedOperations" for SharedOperations

/// <summary>
/// The build engine
/// </summary>
class BuildEngine {
	construct new(compiler) {
		_compiler = compiler
	}

	/// <summary>
	/// Generate the required build operations for the requested build
	/// </summary>
	Execute(buildState, arguments) {
		var result = BuildResult.new()

		// All dependencies must include the entire interface dependency closure
		result.ModuleDependencies = []
		result.ModuleDependencies = result.ModuleDependencies + arguments.ModuleDependencies

		// Ensure the output directories exists as the first step
		result.BuildOperations.Add(
			SharedOperations.CreateCreateDirectoryOperation(
				arguments.TargetRootDirectory,
				arguments.ObjectDirectory))
		result.BuildOperations.Add(
			SharedOperations.CreateCreateDirectoryOperation(
				arguments.TargetRootDirectory,
				arguments.BinaryDirectory))

		// Perform the core compilation of the source files
		this.CoreCompile(buildState, arguments, result)

		// Link the final target after all of the compile graph is done
		this.CoreLink(buildState, arguments, result)

		// Copy previous runtime dependencies after linking has completed
		this.CopyRuntimeDependencies(arguments, result)

		return result
	}

	/// <summary>
	/// Compile the module and source files
	/// </summary>
	CoreCompile(buildState, arguments, result) {
		// Ensure there are actually files to build
		if (arguments.ModuleInterfacePartitionSourceFiles.Count != 0 ||
			!arguments.ModuleInterfaceSourceFile.IsEmpty ||
			arguments.SourceFiles.Count != 0 ||
			arguments.AssemblySourceFiles.Count != 0) {
			// Setup the shared properties
			var compileArguments = SharedCompileArguments.new(
				arguments.LanguageStandard,
				this.ConvertBuildOptimizationLevel(arguments.OptimizationLevel),
				arguments.SourceRootDirectory,
				arguments.TargetRootDirectory,
				arguments.ObjectDirectory,
				arguments.IncludeDirectories,
				arguments.ModuleDependencies,
				arguments.PreprocessorDefinitions,
				arguments.GenerateSourceDebugInfo,
				arguments.EnableWarningsAsErrors,
				arguments.DisabledWarnings,
				arguments.EnabledWarnings,
				arguments.CustomProperties)

			// Compile the resource file if present
			if (!arguments.ResourceFile.IsEmpty) {
				buildState.LogTrace(TraceLevel.Information, "Generate Resource File Compile: " + arguments.ResourceFile.ToString())

				var compiledResourceFile =
					arguments.ObjectDirectory +
					Path.new(arguments.ResourceFile.GetFileName())
				compiledResourceFile.SetFileExtension(_compiler.ResourceFileExtension)

				var compileResourceFileArguments = ResourceCompileArguments.new(
					arguments.ResourceFile,
					compiledResourceFile)

				// Add the resource file arguments to the shared build definition
				compileArguments.ResourceFile = compileResourceFileArguments
			}

			// Build up the entire Interface Dependency Closure for each file
			var partitionInterfaceDependencyLookup = {}
			for (file in arguments.ModuleInterfacePartitionSourceFiles) {
				partitionInterfaceDependencyLookup.Add(file.File, file.Imports)
			}

			// Compile the individual module interface partition translation units
			var compileInterfacePartitionUnits = []
			var allPartitionInterfaces = []
			for (file in arguments.ModuleInterfacePartitionSourceFiles) {
				buildState.LogTrace(TraceLevel.Information, "Generate Module Interface Partition Compile Operation: " + file.File.ToString())

				var objectModuleInterfaceFile =
					arguments.ObjectDirectory +
					Path.new(file.File.GetFileName())
				objectModuleInterfaceFile.SetFileExtension(_compiler.ModuleFileExtension)

				var interfaceDependencyClosure = Set.new()
				this.BuildClosure(interfaceDependencyClosure, file.File, partitionInterfaceDependencyLookup)
				if (interfaceDependencyClosure.Contains(file.File)) {
					Fiber.abort("Circular partition references in: %(file.File)")
				}

				var partitionImports = []
				for (dependency in interfaceDependencyClosure) {
					var importInterface = arguments.ObjectDirectory + Path.new(dependency.GetFileName())
					importInterface.SetFileExtension(_compiler.ModuleFileExtension)
					partitionImports.Add(arguments.TargetRootDirectory + importInterface)
				}

				var compileFileArguments = InterfaceUnitCompileArguments.new(
					file.File,
					arguments.ObjectDirectory + Path.new(file.File.GetFileName()),
					partitionImports,
					objectModuleInterfaceFile)

				compileFileArguments.TargetFile.SetFileExtension(_compiler.ObjectFileExtension)

				compileInterfacePartitionUnits.Add(compileFileArguments)
				allPartitionInterfaces.Add(arguments.TargetRootDirectory + objectModuleInterfaceFile)
			}

			// Add all partition unit interface files as module dependencies since MSVC does not
			// combine the interfaces into the final interface unit
			for (module in allPartitionInterfaces) {
				result.ModuleDependencies.Add(module)
			}

			compileArguments.InterfacePartitionUnits = compileInterfacePartitionUnits

			// Compile the module interface unit if present
			if (!arguments.ModuleInterfaceSourceFile.IsEmpty) {
				buildState.LogTrace(TraceLevel.Information, "Generate Module Interface Unit Compile: " + arguments.ModuleInterfaceSourceFile.ToString())

				var objectModuleInterfaceFile =
					arguments.ObjectDirectory +
					Path.new(arguments.ModuleInterfaceSourceFile.GetFileName())
				objectModuleInterfaceFile.SetFileExtension(_compiler.ModuleFileExtension)
				var binaryOutputModuleInterfaceFile =
					arguments.BinaryDirectory +
					Path.new(arguments.TargetName + "." + _compiler.ModuleFileExtension)

				var compileModuleFileArguments = InterfaceUnitCompileArguments.new(
					arguments.ModuleInterfaceSourceFile,
					arguments.ObjectDirectory + Path.new(arguments.ModuleInterfaceSourceFile.GetFileName()),
					allPartitionInterfaces,
					objectModuleInterfaceFile)

				compileModuleFileArguments.TargetFile.SetFileExtension(_compiler.ObjectFileExtension)

				// Add the interface unit arguments to the shared build definition
				compileArguments.InterfaceUnit = compileModuleFileArguments

				// Copy the binary module interface to the binary directory after compiling
				var copyInterfaceOperation =
					SharedOperations.CreateCopyFileOperation(
						arguments.TargetRootDirectory,
						objectModuleInterfaceFile,
						binaryOutputModuleInterfaceFile)
				result.BuildOperations.Add(copyInterfaceOperation)

				// Add output module interface to the parent set of modules
				// This will allow the module implementation units access as well as downstream
				// dependencies to the public interface.
				result.ModuleDependencies.Add(
					binaryOutputModuleInterfaceFile.HasRoot ?
						binaryOutputModuleInterfaceFile :
						arguments.TargetRootDirectory + binaryOutputModuleInterfaceFile)
			}

			// Compile the individual translation units
			var compileImplementationUnits = []
			for (file in arguments.SourceFiles) {
				buildState.LogTrace(TraceLevel.Information, "Generate Compile Operation: " + file.ToString())

				var compileFileArguments = TranslationUnitCompileArguments.new()
				compileFileArguments.SourceFile = file
				compileFileArguments.TargetFile = arguments.ObjectDirectory + Path.new(file.GetFileName())
				compileFileArguments.TargetFile.SetFileExtension(_compiler.ObjectFileExtension)

				compileImplementationUnits.Add(compileFileArguments)
			}

			compileArguments.ImplementationUnits = compileImplementationUnits

			// Compile the individual assembly units
			var compileAssemblyUnits = []
			for (file in arguments.AssemblySourceFiles) {
				buildState.LogTrace(TraceLevel.Information, "Generate Compile Assembly Operation: " + file.ToString())

				var compileFileArguments = TranslationUnitCompileArguments.new()
				compileFileArguments.SourceFile = file
				compileFileArguments.TargetFile = arguments.ObjectDirectory + Path.new(file.GetFileName())
				compileFileArguments.TargetFile.SetFileExtension(_compiler.ObjectFileExtension)

				compileAssemblyUnits.Add(compileFileArguments)
			}

			compileArguments.AssemblyUnits = compileAssemblyUnits

			// Compile all source files as a single call
			var compileOperations = _compiler.CreateCompileOperations(compileArguments)
			for (operation in compileOperations) {
				result.BuildOperations.Add(operation)
			}
		}
	}

	/// <summary>
	/// Link the library
	/// </summary>
	CoreLink(
		buildState,
		arguments,
		result) {
		buildState.LogTrace(TraceLevel.Information, "CoreLink")

		var targetFile
		var implementationFile = Path.new()
		if (arguments.TargetType == BuildTargetType.StaticLibrary) {
			targetFile = arguments.BinaryDirectory +
				Path.new(arguments.TargetName + "." + _compiler.StaticLibraryFileExtension)
		} else if (arguments.TargetType == BuildTargetType.DynamicLibrary) {
			targetFile = arguments.BinaryDirectory +
				Path.new(arguments.TargetName + "." + _compiler.DynamicLibraryFileExtension)
			implementationFile = arguments.BinaryDirectory +
				Path.new(arguments.TargetName + "." + _compiler.StaticLibraryFileExtension)
		} else if (arguments.TargetType == BuildTargetType.Executable ||
			arguments.TargetType == BuildTargetType.WindowsApplication) {
			targetFile = arguments.BinaryDirectory + 
				Path.new(arguments.TargetName + ".exe")
		} else {
			Fiber.abort("Unknown build target type.")
		}

		buildState.LogTrace(TraceLevel.Information, "Linking target")

		var linkArguments = LinkArguments.new(
			targetFile,
			arguments.TargetArchitecture,
			implementationFile,
			arguments.TargetRootDirectory,
			arguments.LibraryPaths,
			arguments.GenerateSourceDebugInfo)

		// Only resolve link libraries if not a library ourself
		if (arguments.TargetType != BuildTargetType.StaticLibrary) {
			linkArguments.ExternalLibraryFiles = arguments.PlatformLinkDependencies
			linkArguments.LibraryFiles = arguments.LinkDependencies
		}

		// Translate the target type into the link target
		// and determine what dependencies to inject into downstream builds

		if (arguments.TargetType == BuildTargetType.StaticLibrary) {
			linkArguments.TargetType = LinkTarget.StaticLibrary
			
			// Add the library as a link dependency and all recursive libraries
			result.LinkDependencies = []
			var absoluteTargetFile = linkArguments.TargetFile.HasRoot ? linkArguments.TargetFile : linkArguments.TargetRootDirectory + linkArguments.TargetFile
			result.LinkDependencies.Add(absoluteTargetFile)
		} else if (arguments.TargetType == BuildTargetType.DynamicLibrary) {
			linkArguments.TargetType = LinkTarget.DynamicLibrary

			// Add the DLL as a runtime dependency
			var absoluteTargetFile = linkArguments.TargetFile.HasRoot ? linkArguments.TargetFile : linkArguments.TargetRootDirectory + linkArguments.TargetFile
			result.RuntimeDependencies.Add(absoluteTargetFile)

			// Clear out all previous link dependencies and replace with the 
			// single implementation library for the DLL
			var absoluteImplementationFile = linkArguments.ImplementationFile.HasRoot ? linkArguments.ImplementationFile : linkArguments.TargetRootDirectory + linkArguments.ImplementationFile
			result.LinkDependencies.Add(absoluteImplementationFile)

			// Set the targe file
			result.TargetFile = absoluteTargetFile
		} else if (arguments.TargetType == BuildTargetType.Executable) {
			linkArguments.TargetType = LinkTarget.Executable

			// Add the Executable as a runtime dependency
			var absoluteTargetFile = linkArguments.TargetFile.HasRoot ? linkArguments.TargetFile : linkArguments.TargetRootDirectory + linkArguments.TargetFile
			result.RuntimeDependencies.Add(absoluteTargetFile)

			// All link dependencies stop here.

			// Set the targe file
			result.TargetFile = absoluteTargetFile
		} else if (arguments.TargetType == BuildTargetType.WindowsApplication) {
			linkArguments.TargetType = LinkTarget.WindowsApplication

			// Add the Executable as a runtime dependency
			var absoluteTargetFile = linkArguments.TargetFile.HasRoot ? linkArguments.TargetFile : linkArguments.TargetRootDirectory + linkArguments.TargetFile
			result.RuntimeDependencies.Add(absoluteTargetFile)

			// All link dependencies stop here.

			// Set the targe file
			result.TargetFile = absoluteTargetFile
		} else {
			Fiber.abort("Unknown build target type.")
		}

		// Build up the set of object files
		var objectFiles = []

		// Add the resource file if present
		if (!arguments.ResourceFile.IsEmpty) {
			var compiledResourceFile =
				arguments.ObjectDirectory +
				Path.new(arguments.ResourceFile.GetFileName())
			compiledResourceFile.SetFileExtension(_compiler.ResourceFileExtension)

			objectFiles.Add(compiledResourceFile)
		}

		// Add the partition object files
		for (sourceFile in arguments.ModuleInterfacePartitionSourceFiles) {
			var objectFile = arguments.ObjectDirectory + Path.new(sourceFile.File.GetFileName())
			objectFile.SetFileExtension(_compiler.ObjectFileExtension)
			objectFiles.Add(objectFile)
		}

		// Add the module interface object file if present
		if (!arguments.ModuleInterfaceSourceFile.IsEmpty) {
			var objectFile = arguments.ObjectDirectory + Path.new(arguments.ModuleInterfaceSourceFile.GetFileName())
			objectFile.SetFileExtension(_compiler.ObjectFileExtension)
			objectFiles.Add(objectFile)
		}

		// Add the implementation unit object files
		for (sourceFile in arguments.SourceFiles) {
			var objectFile = arguments.ObjectDirectory + Path.new(sourceFile.GetFileName())
			objectFile.SetFileExtension(_compiler.ObjectFileExtension)
			objectFiles.Add(objectFile)
		}

		// Add the assembly unit object files
		for (sourceFile in arguments.AssemblySourceFiles) {
			var objectFile = arguments.ObjectDirectory + Path.new(sourceFile.GetFileName())
			objectFile.SetFileExtension(_compiler.ObjectFileExtension)
			objectFiles.Add(objectFile)
		}

		linkArguments.ObjectFiles = objectFiles

		// Perform the link
		buildState.LogTrace(TraceLevel.Information, "Generate Link Operation: " + linkArguments.TargetFile.ToString())
		var linkOperation = _compiler.CreateLinkOperation(linkArguments)
		result.BuildOperations.Add(linkOperation)

		// Pass along the link arguments for internal access
		result.InternalLinkDependencies = []
		result.InternalLinkDependencies = result.InternalLinkDependencies + arguments.LinkDependencies
		for (file in linkArguments.ObjectFiles) {
			result.InternalLinkDependencies.Add(file)
		}
	}

	/// <summary>
	/// Copy runtime dependencies
	/// </summary>
	CopyRuntimeDependencies(arguments, result) {
		if (arguments.TargetType == BuildTargetType.Executable ||
			arguments.TargetType == BuildTargetType.WindowsApplication ||
			arguments.TargetType == BuildTargetType.DynamicLibrary) {
			for (source in arguments.RuntimeDependencies) {
				var target = arguments.BinaryDirectory + Path.new(source.GetFileName())
				var operation = SharedOperations.CreateCopyFileOperation(
					arguments.TargetRootDirectory,
					source,
					target)
				result.BuildOperations.Add(operation)

				// Add the copied file as the new runtime dependency
				result.RuntimeDependencies.Add(target)
			}
		} else {
			// Pass along all runtime dependencies in their original location
			for (source in arguments.RuntimeDependencies) {
				result.RuntimeDependencies.Add(source)
			}
		}
	}

	BuildClosure(closure, file, partitionInterfaceDependencyLookup) {
		for (childFile in partitionInterfaceDependencyLookup[file]) {
			closure.Add(childFile)
			this.BuildClosure(closure, childFile, partitionInterfaceDependencyLookup)
		}
	}

	ConvertBuildOptimizationLevel(value) {
		if (value == BuildOptimizationLevel.None) {
			return OptimizationLevel.None
		} else if (value == BuildOptimizationLevel.Speed) {
			return OptimizationLevel.Speed
		} else if (value == BuildOptimizationLevel.Size) {
			return OptimizationLevel.Size
		} else {
			Fiber.abort("Unknown BuildOptimizationLevel.")
		}
	}
}

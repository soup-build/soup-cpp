// <copyright file="mock-compiler.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "Soup|Build.Utils:./build-operation" for BuildOperation
import "Soup|Build.Utils:./path" for Path
import "./i-compiler" for ICompiler

/// <summary>
/// A mock compiler interface implementation
/// TODO: Move into test projects
/// </summary>
class MockCompiler is ICompiler {
	/// <summary>
	/// Initializes a new instance of the <see cref='Compiler'/> class.
	/// </summary>
	construct new() {
		_compileRequests = []
		_linkRequests = []
	}

	/// <summary>
	/// Get the compile requests
	/// </summary>
	GetCompileRequests() {
		return _compileRequests
	}

	/// <summary>
	/// Get the link requests
	/// </summary>
	GetLinkRequests() {
		return _linkRequests
	}

	/// <summary>
	/// Gets the unique name for the compiler
	/// </summary>
	Name { "MockCompiler" }

	/// <summary>
	/// Gets the object file extension for the compiler
	/// </summary>
	ObjectFileExtension { "mock.obj" }

	/// <summary>
	/// Gets the module file extension for the compiler
	/// </summary>
	ModuleFileExtension { "mock.bmi" }

	/// <summary>
	/// Gets the static library file extension for the compiler
	/// TODO: This is platform specific
	/// </summary>
	CreateStaticLibraryFileName(name) {
		return Path.new("%(name).mock.lib")
	}

	/// <summary>
	/// Gets the dynamic library file extension for the compiler
	/// TODO: This is platform specific
	/// </summary>
	DynamicLibraryFileExtension { "mock.dll" }
	DynamicLibraryLinkFileExtension { "mock.link.dll" }

	/// <summary>
	/// Gets the resource file extension for the compiler
	/// </summary>
	ResourceFileExtension { "mock.res" }

	/// <summary>
	/// Compile
	/// </summary>
	CreateCompileOperations(arguments) {
		_compileRequests.add(arguments)

		var result = []

		for (moduleInterfaceUnitArguments in arguments.ModuleInterfaceUnits) {
			result.add(
				BuildOperation.new(
					"MockCompileModuleInterface: %(_compileRequests.count)",
					Path.new("MockWorkingDirectory"),
					Path.new("MockCompiler.exe"),
					[
						"Arguments",
					],
					[
						moduleInterfaceUnitArguments.SourceFile,
					],
					[
						moduleInterfaceUnitArguments.TargetFile,
						moduleInterfaceUnitArguments.ModuleInterfaceTarget,
					]))
		}

		for (translationUnitArguments in arguments.TranslationUnits) {
			result.add(
				BuildOperation.new(
					"MockCompile: %(_compileRequests.count)",
					Path.new("MockWorkingDirectory"),
					Path.new("MockCompiler.exe"),
					[
						"Arguments",
					],
					[
						translationUnitArguments.SourceFile,
					],
					[
						translationUnitArguments.TargetFile,
					]))
		}

		return result
	}

	/// <summary>
	/// Link
	/// </summary>
	CreateLinkOperation(arguments) {
		_linkRequests.add(arguments)
		return BuildOperation.new(
			"MockLink: %(_linkRequests.count)",
			Path.new("MockWorkingDirectory"),
			Path.new("MockLinker.exe"),
			[
				"Arguments",
			],
			[
				Path.new("InputFile.in"),
			],
			[
				Path.new("OutputFile.out"),
			])
	}
}

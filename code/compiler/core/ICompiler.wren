// <copyright file="icompiler.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

/// <summary>
/// The compiler interface definition
/// </summary>
class ICompiler {
	/// <summary>
	/// Gets the unique name for the compiler
	/// </summary>
	Name {}

	/// <summary>
	/// Gets the object file extension for the compiler
	/// </summary>
	ObjectFileExtension {}

	/// <summary>
	/// Gets the module file extension for the compiler
	/// </summary>
	ModuleFileExtension {}

	/// <summary>
	/// Gets the static library file extension for the compiler
	/// TODO: This is platform specific
	/// </summary>
	CreateStaticLibraryFileName(name) {}

	/// <summary>
	/// Gets the dynamic library file extension for the compiler
	/// TODO: This is platform specific
	/// </summary>
	DynamicLibraryFileExtension {}
	DynamicLibraryLinkFileExtension {}

	/// <summary>
	/// Gets the resource file extension for the compiler
	/// </summary>
	ResourceFileExtension {}

	/// <summary>
	/// Compile
	/// </summary>
	CreateCompileOperations(arguments) {}

	/// <summary>
	/// Link
	/// </summary>
	CreateLinkOperation(arguments) {}
}

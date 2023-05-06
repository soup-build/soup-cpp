// <copyright file="ClangLinkerArgumentBuilderUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../Clang/ClangArgumentBuilder" for ClangArgumentBuilder
import "Soup.Build.Utils:./Path" for Path
import "../../Test/Assert" for Assert
import "../Core/LinkArguments" for LinkArguments, LinkTarget

class ClangLinkerArgumentBuilderUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("ClangLinkerArgumentBuilderUnitTests.ZeroObjectFiles")
		this.ZeroObjectFiles()
		// System.print("ClangLinkerArgumentBuilderUnitTests.EmptyTargetFile_Throws")
		// this.EmptyTargetFile_Throws()
		System.print("ClangLinkerArgumentBuilderUnitTests.StaticLibrary")
		this.StaticLibrary()
		System.print("ClangLinkerArgumentBuilderUnitTests.StaticLibrary_LibraryPaths")
		this.StaticLibrary_LibraryPaths()
		System.print("ClangLinkerArgumentBuilderUnitTests.DynamicLibrary")
		this.DynamicLibrary()
		System.print("ClangLinkerArgumentBuilderUnitTests.Executable")
		this.Executable()
		// System.print("ClangLinkerArgumentBuilderUnitTests.WindowsApplication")
		// this.WindowsApplication()
	}

	// [Fact]
	ZeroObjectFiles() {
		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.StaticLibrary
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Library.mock.a")
		arguments.ObjectFiles = []

		var actualArguments = ClangArgumentBuilder.BuildStaticLibraryLinkerArguments(arguments)

		var expectedArguments = [
			"-r",
			"./Library.mock.a",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	// EmptyTargetFile_Throws() {
	// 	var arguments = LinkArguments.new()
	// 	arguments.TargetType = LinkTarget.StaticLibrary
	// 	arguments.TargetFile = Path.new("")
	// 	arguments.ObjectFiles = [
	// 		Path.new("File.mock.o"),
	// 	]
	// 	Assert.Throws<InvalidOperationException>(() => {
	// 		var actualArguments = ClangArgumentBuilder.BuildLinkerArguments(arguments)
	// 	})
	// }

	// [Fact]
	StaticLibrary() {
		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.StaticLibrary
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Library.mock.a")
		arguments.ObjectFiles = [
			Path.new("File.mock.o"),
		]

		var actualArguments = ClangArgumentBuilder.BuildStaticLibraryLinkerArguments(arguments)

		var expectedArguments = [
			"-r",
			"./Library.mock.a",
			"./File.mock.o",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	StaticLibrary_LibraryPaths() {
		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.StaticLibrary
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Library.mock.a")
		arguments.ObjectFiles = [
			Path.new("File.mock.o"),
		]
		arguments.LibraryPaths = [
			Path.new("../libraries/"),
		]

		var actualArguments = ClangArgumentBuilder.BuildStaticLibraryLinkerArguments(arguments)

		var expectedArguments = [
			"-r",
			"./Library.mock.a",
			"./File.mock.o",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	DynamicLibrary() {
		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.DynamicLibrary
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Library.mock.so")
		arguments.ImplementationFile = Path.new("Library.mock.a")
		arguments.ObjectFiles = [
			Path.new("File.mock.o"),
		]

		var actualArguments = ClangArgumentBuilder.BuildDynamicLibraryLinkerArguments(arguments)

		var expectedArguments = [
			"-shared",
			"-fpic",
			"-o",
			"./Library.mock.so",
			"./File.mock.o",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	Executable() {
		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.Executable
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("out/Something")
		arguments.ObjectFiles = [
			Path.new("File.mock.o"),
		]
		arguments.LibraryFiles = [
			Path.new("Library.mock.a"),
		]

		var actualArguments = ClangArgumentBuilder.BuildExecutableLinkerArguments(arguments)

		var expectedArguments = [
			"-o",
			"./out/Something",
			"./File.mock.o",
			"./Library.mock.a",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	WindowsApplication() {
		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.WindowsApplication
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("out/Something.exe")
		arguments.ObjectFiles = [
			Path.new("File.mock.o"),
		]
		arguments.LibraryFiles = [
			Path.new("Library.mock.a"),
		]

		var actualArguments = ClangArgumentBuilder.BuildLinkerArguments(arguments)

		var expectedArguments = [
			"-o",
			"./out/Something.exe",
			"./Library.mock.a",
			"./File.mock.o",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}
}

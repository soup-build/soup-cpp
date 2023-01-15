// <copyright file="MSVCLinkerArgumentBuilderUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../MSVC/MSVCArgumentBuilder" for MSVCArgumentBuilder
import "../../Utils/Path" for Path
import "../../Test/Assert" for Assert
import "../Core/LinkArguments" for LinkArguments, LinkTarget

class MSVCLinkerArgumentBuilderUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("MSVCLinkerArgumentBuilderUnitTests.ZeroObjectFiles")
		this.ZeroObjectFiles()
		// System.print("MSVCLinkerArgumentBuilderUnitTests.EmptyTargetFile_Throws")
		// this.EmptyTargetFile_Throws()
		System.print("MSVCLinkerArgumentBuilderUnitTests.StaticLibrary")
		this.StaticLibrary()
		System.print("MSVCLinkerArgumentBuilderUnitTests.StaticLibrary_LibraryPaths")
		this.StaticLibrary_LibraryPaths()
		System.print("MSVCLinkerArgumentBuilderUnitTests.DynamicLibrary")
		this.DynamicLibrary()
		System.print("MSVCLinkerArgumentBuilderUnitTests.Executable")
		this.Executable()
		System.print("MSVCLinkerArgumentBuilderUnitTests.WindowsApplication")
		this.WindowsApplication()
	}

	// [Fact]
	ZeroObjectFiles() {
		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.StaticLibrary
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Library.mock.lib")
		arguments.ObjectFiles = []

		var actualArguments = MSVCArgumentBuilder.BuildLinkerArguments(arguments)

		var expectedArguments = [
			"/nologo",
			"/INCREMENTAL:NO",
			"/machine:X64",
			"/out:\"./Library.mock.lib\"",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	// EmptyTargetFile_Throws() {
	// 	var arguments = LinkArguments.new()
	// 	arguments.TargetType = LinkTarget.StaticLibrary
	// 	arguments.TargetFile = Path.new("")
	// 	arguments.ObjectFiles = [
	// 		Path.new("File.mock.obj"),
	// 	]
	// 	Assert.Throws<InvalidOperationException>(() => {
	// 		var actualArguments = MSVCArgumentBuilder.BuildLinkerArguments(arguments)
	// 	})
	// }

	// [Fact]
	StaticLibrary() {
		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.StaticLibrary
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Library.mock.lib")
		arguments.ObjectFiles = [
			Path.new("File.mock.o"),
		]

		var actualArguments = MSVCArgumentBuilder.BuildLinkerArguments(arguments)

		var expectedArguments = [
			"/nologo",
			"/INCREMENTAL:NO",
			"/machine:X64",
			"/out:\"./Library.mock.lib\"",
			"./File.mock.o",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	StaticLibrary_LibraryPaths() {
		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.StaticLibrary
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Library.mock.lib")
		arguments.ObjectFiles = [
			Path.new("File.mock.o"),
		]
		arguments.LibraryPaths = [
			Path.new("../libraries/"),
		]

		var actualArguments = MSVCArgumentBuilder.BuildLinkerArguments(arguments)

		var expectedArguments = [
			"/nologo",
			"/INCREMENTAL:NO",
			"/machine:X64",
			"/libpath:\"../libraries/\"",
			"/out:\"./Library.mock.lib\"",
			"./File.mock.o",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	DynamicLibrary() {
		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.DynamicLibrary
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Library.mock.dll")
		arguments.ImplementationFile = Path.new("Library.mock.lib")
		arguments.ObjectFiles = [
			Path.new("File.mock.obj"),
		]

		var actualArguments = MSVCArgumentBuilder.BuildLinkerArguments(arguments)

		var expectedArguments = [
			"/nologo",
			"/INCREMENTAL:NO",
			"/subsystem:console",
			"/dll",
			"/implib:\"./Library.mock.lib\"",
			"/machine:X64",
			"/out:\"./Library.mock.dll\"",
			"./File.mock.obj",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	Executable() {
		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.Executable
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("out/Something.exe")
		arguments.ObjectFiles = [
			Path.new("File.mock.obj"),
		]
		arguments.LibraryFiles = [
			Path.new("Library.mock.lib"),
		]

		var actualArguments = MSVCArgumentBuilder.BuildLinkerArguments(arguments)

		var expectedArguments = [
			"/nologo",
			"/INCREMENTAL:NO",
			"/subsystem:console",
			"/machine:X64",
			"/out:\"./out/Something.exe\"",
			"./Library.mock.lib",
			"./File.mock.obj",
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
			Path.new("File.mock.obj"),
		]
		arguments.LibraryFiles = [
			Path.new("Library.mock.lib"),
		]

		var actualArguments = MSVCArgumentBuilder.BuildLinkerArguments(arguments)

		var expectedArguments = [
			"/nologo",
			"/INCREMENTAL:NO",
			"/subsystem:windows",
			"/machine:X64",
			"/out:\"./out/Something.exe\"",
			"./Library.mock.lib",
			"./File.mock.obj",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}
}

// <copyright file="gcc-linker-argument-builder-unit-tests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "Soup|Build.Utils:./path" for Path
import "../../test/assert" for Assert
import "../gcc/gcc-argument-builder" for GCCArgumentBuilder
import "../core/link-arguments" for LinkArguments, LinkTarget

class GCCLinkerArgumentBuilderUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("GCCLinkerArgumentBuilderUnitTests.ZeroObjectFiles")
		this.ZeroObjectFiles()
		// System.print("GCCLinkerArgumentBuilderUnitTests.EmptyTargetFile_Throws")
		// this.EmptyTargetFile_Throws()
		System.print("GCCLinkerArgumentBuilderUnitTests.StaticLibrary")
		this.StaticLibrary()
		System.print("GCCLinkerArgumentBuilderUnitTests.StaticLibrary_LibraryPaths")
		this.StaticLibrary_LibraryPaths()
		System.print("GCCLinkerArgumentBuilderUnitTests.DynamicLibrary")
		this.DynamicLibrary()
		System.print("GCCLinkerArgumentBuilderUnitTests.Executable")
		this.Executable()
		System.print("GCCLinkerArgumentBuilderUnitTests.WindowsApplication")
		this.WindowsApplication()
	}

	// [Fact]
	ZeroObjectFiles() {
		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.StaticLibrary
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Library.mock.lib")
		arguments.ObjectFiles = []

		var actualArguments = GCCArgumentBuilder.BuildLinkerArguments(arguments)

		var expectedArguments = [
			"-o",
			"./Library.mock.lib",
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
	// 		var actualArguments = GCCArgumentBuilder.BuildLinkerArguments(arguments)
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

		var actualArguments = GCCArgumentBuilder.BuildLinkerArguments(arguments)

		var expectedArguments = [
			"-o",
			"./Library.mock.lib",
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

		var actualArguments = GCCArgumentBuilder.BuildLinkerArguments(arguments)

		var expectedArguments = [
			"-libpath=\"../libraries/\"",
			"-o",
			"./Library.mock.lib",
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

		var actualArguments = GCCArgumentBuilder.BuildLinkerArguments(arguments)

		var expectedArguments = [
			"-dll",
			"-implib=\"./Library.mock.lib\"",
			"-o",
			"./Library.mock.dll",
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

		var actualArguments = GCCArgumentBuilder.BuildLinkerArguments(arguments)

		var expectedArguments = [
			"-o",
			"./out/Something.exe",
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

		var actualArguments = GCCArgumentBuilder.BuildLinkerArguments(arguments)

		var expectedArguments = [
			"-o",
			"./out/Something.exe",
			"./Library.mock.lib",
			"./File.mock.obj",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}
}

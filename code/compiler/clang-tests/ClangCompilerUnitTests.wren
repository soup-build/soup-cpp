// <copyright file="ClangCompilerUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../clang/ClangCompiler" for ClangCompiler
import "Soup|Build.Utils:./Path" for Path
import "Soup|Build.Utils:./BuildOperation" for BuildOperation
import "../../test/Assert" for Assert
import "../core/LinkArguments" for LinkArguments, LinkTarget
import "../core/CompileArguments" for InterfaceUnitCompileArguments, LanguageStandard, OptimizationLevel,  SharedCompileArguments, ResourceCompileArguments, TranslationUnitCompileArguments

class ClangCompilerUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("ClangCompilerUnitTests.Initialize")
		this.Initialize()
		System.print("ClangCompilerUnitTests.Compile_Simple")
		this.Compile_Simple()
		System.print("ClangCompilerUnitTests.Compile_Module_Partition")
		this.Compile_Module_Partition()
		System.print("ClangCompilerUnitTests.Compile_Module_Interface")
		this.Compile_Module_Interface()
		System.print("ClangCompilerUnitTests.Compile_Module_PartitionInterfaceAndImplementation")
		this.Compile_Module_PartitionInterfaceAndImplementation()
		// System.print("ClangCompilerUnitTests.Compile_Resource")
		// this.Compile_Resource()
		System.print("ClangCompilerUnitTests.LinkStaticLibrary_Simple")
		this.LinkStaticLibrary_Simple()
		System.print("ClangCompilerUnitTests.LinkExecutable_Simple")
		this.LinkExecutable_Simple()
		// System.print("ClangCompilerUnitTests.LinkWindowsApplication_Simple")
		// this.LinkWindowsApplication_Simple()
	}

	// [Fact]
	Initialize() {
		var uut = ClangCompiler.new(
			Path.new("C:/bin/mock.clang++"),
			Path.new("C:/bin/mock.ar"))
		Assert.Equal("Clang", uut.Name)
		Assert.Equal("o", uut.ObjectFileExtension)
		Assert.Equal("pcm", uut.ModuleFileExtension)
		Assert.Equal(Path.new("libTest.a"), uut.CreateStaticLibraryFileName("Test"))
		Assert.Equal("so", uut.DynamicLibraryFileExtension)
		Assert.Equal("res", uut.ResourceFileExtension)
	}

	// [Fact]
	Compile_Simple(){
		var uut = ClangCompiler.new(
			Path.new("C:/bin/mock.clang++"),
			Path.new("C:/bin/mock.ar"))

		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP11
		arguments.Optimize = OptimizationLevel.None
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("ObjectDir/")

		var translationUnitArguments = TranslationUnitCompileArguments.new()
		translationUnitArguments.SourceFile = Path.new("File.cpp")
		translationUnitArguments.TargetFile = Path.new("obj/File.o")

		arguments.ImplementationUnits = [
			translationUnitArguments,
		]

		var result = uut.CreateCompileOperations(arguments)

		// Verify result
		var expected = [
			BuildOperation.new(
				"WriteFile [./ObjectDir/SharedCompileArguments.rsp]",
				Path.new("C:/target/"),
				Path.new("./writefile.exe"),
				[
					"./ObjectDir/SharedCompileArguments.rsp",
					"-fpic -std=c++11 -O0 -mpclmul -maes -msse4.1 -msha -c",
				],
				[],
				[
					Path.new("./ObjectDir/SharedCompileArguments.rsp"),
				]),
			BuildOperation.new(
				"./File.cpp",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.clang++"),
				[
					"@C:/target/ObjectDir/SharedCompileArguments.rsp",
					"./File.cpp",
					"-o",
					"C:/target/obj/File.o",
				],
				[
					Path.new("File.cpp"),
					Path.new("C:/target/ObjectDir/SharedCompileArguments.rsp"),
				],
				[
					Path.new("C:/target/obj/File.o"),
				]),
		]

		Assert.ListEqual(expected, result)
	}

	// [Fact]
	Compile_Module_Partition() {
		var uut = ClangCompiler.new(
			Path.new("C:/bin/mock.clang++"),
			Path.new("C:/bin/mock.ar"))

		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP11
		arguments.Optimize = OptimizationLevel.None
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("ObjectDir/")
		arguments.IncludeDirectories = [
			Path.new("Includes"),
		]
		arguments.IncludeModules = {
			"Module": Path.new("Module.pcm"),
		}
		arguments.PreprocessorDefinitions = [
			"DEBUG",
		]
		arguments.InterfacePartitionUnits = [
			InterfaceUnitCompileArguments.new(
				Path.new("File.cpp"),
				Path.new("obj/File.o"),
				{
					"Other": Path.new("obj/Other.pcm"),
				},
				"Module1:File",
				Path.new("obj/File.pcm")),
		]

		var result = uut.CreateCompileOperations(arguments)

		// Verify result
		var expected = [
			BuildOperation.new(
				"WriteFile [./ObjectDir/SharedCompileArguments.rsp]",
				Path.new("C:/target/"),
				Path.new("./writefile.exe"),
				[
					"./ObjectDir/SharedCompileArguments.rsp",
					"-fpic -std=c++11 -O0 -I\"./Includes\" -DDEBUG -fmodule-file=Module=./Module.pcm -mpclmul -maes -msse4.1 -msha -c",
				],
				[],
				[
					Path.new("./ObjectDir/SharedCompileArguments.rsp"),
				]),
			BuildOperation.new(
				"./File.cpp",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.clang++"),
				[
					"@C:/target/ObjectDir/SharedCompileArguments.rsp",
					"-fmodule-file=Other=./obj/Other.pcm",
					"-x",
					"c++-module",
					"./File.cpp",
					"-o",
					"C:/target/obj/File.o",
					"--precompile",
					"-o",
					"C:/target/obj/File.pcm",
				],
				[
					Path.new("Module.pcm"),
					Path.new("File.cpp"),
					Path.new("C:/target/ObjectDir/SharedCompileArguments.rsp"),
					Path.new("obj/Other.pcm"),
				],
				[
					Path.new("C:/target/obj/File.o"),
					Path.new("C:/target/obj/File.pcm"),
				]),
		]

		Assert.ListEqual(expected, result)
	}

	// [Fact]
	Compile_Module_Interface() {
		var uut = ClangCompiler.new(
			Path.new("C:/bin/mock.clang++"),
			Path.new("C:/bin/mock.ar"))

		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP11
		arguments.Optimize = OptimizationLevel.None
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("ObjectDir/")
		arguments.IncludeDirectories = [
			Path.new("Includes"),
		]
		arguments.IncludeModules = {
			"Module": Path.new("Module.pcm"),
		}
		arguments.PreprocessorDefinitions = [
			"DEBUG",
		]

		arguments.InterfaceUnit = InterfaceUnitCompileArguments.new(
			Path.new("File.cpp"),
			Path.new("obj/File.o"),
			{
				"Other": Path.new("obj/Other.pcm")
			},
			"Module1",
			Path.new("obj/File.pcm"))

		var result = uut.CreateCompileOperations(arguments)

		// Verify result
		var expected = [
			BuildOperation.new(
				"WriteFile [./ObjectDir/SharedCompileArguments.rsp]",
				Path.new("C:/target/"),
				Path.new("./writefile.exe"),
				[
					"./ObjectDir/SharedCompileArguments.rsp",
					"-fpic -std=c++11 -O0 -I\"./Includes\" -DDEBUG -fmodule-file=Module=./Module.pcm -mpclmul -maes -msse4.1 -msha -c",
				],
				[],
				[
					Path.new("./ObjectDir/SharedCompileArguments.rsp"),
				]),
			BuildOperation.new(
				"./File.cpp",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.clang++"),
				[
					"@C:/target/ObjectDir/SharedCompileArguments.rsp",
					"-fmodule-file=Other=./obj/Other.pcm",
					"-x",
					"c++-module",
					"./File.cpp",
					"--precompile",
					"-o",
					"C:/target/obj/File.pcm",
				],
				[
					Path.new("Module.pcm"),
					Path.new("File.cpp"),
					Path.new("C:/target/ObjectDir/SharedCompileArguments.rsp"),
					Path.new("obj/Other.pcm"),
				],
				[
					Path.new("C:/target/obj/File.pcm"),
				]),
			BuildOperation.new(
				"./obj/File.pcm",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.clang++"),
				[
					"-c",
					"-fmodule-file=Module=./Module.pcm",
					"C:/target/obj/File.pcm",
					"-o",
					"C:/target/obj/File.o",
				],
				[
					Path.new("C:/target/obj/File.pcm"),
				],
				[
					Path.new("C:/target/obj/File.o"),
				]),
		]

		Assert.ListEqual(expected, result)
	}

	// [Fact]
	Compile_Module_PartitionInterfaceAndImplementation() {
		var uut = ClangCompiler.new(
			Path.new("C:/bin/mock.clang++"),
			Path.new("C:/bin/mock.ar"))

		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP11
		arguments.Optimize = OptimizationLevel.None
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("ObjectDir/")
		arguments.IncludeDirectories = [
			Path.new("Includes"),
		]
		arguments.IncludeModules = {
			"Module": Path.new("Module.pcm"),
		}
		arguments.PreprocessorDefinitions = [
			"DEBUG",
		]
		arguments.InterfacePartitionUnits = [
			InterfaceUnitCompileArguments.new(
				Path.new("File1.cpp"),
				Path.new("obj/File1.o"),
				{
					"Other1": Path.new("obj/Other1.pcm")
				},
				"Module1:File1",
				Path.new("obj/File1.pcm")),
		]
		arguments.InterfaceUnit = InterfaceUnitCompileArguments.new(
			Path.new("File2.cpp"),
			Path.new("obj/File2.o"),
			{
				"Other2": Path.new("obj/Other2.pcm")
			},
			"Module1",
			Path.new("obj/File2.pcm"))
		arguments.ImplementationUnits = [
			TranslationUnitCompileArguments.new(
				Path.new("File3.cpp"),
				Path.new("obj/File3.o"),
				{
					"Other3": Path.new("obj/Other3.pcm")
				})
		]

		var result = uut.CreateCompileOperations(arguments)

		// Verify result
		var expected = [
			BuildOperation.new(
				"WriteFile [./ObjectDir/SharedCompileArguments.rsp]",
				Path.new("C:/target/"),
				Path.new("./writefile.exe"),
				[
					"./ObjectDir/SharedCompileArguments.rsp",
					"-fpic -std=c++11 -O0 -I\"./Includes\" -DDEBUG -fmodule-file=Module=./Module.pcm -mpclmul -maes -msse4.1 -msha -c",
				],
				[],
				[
					Path.new("./ObjectDir/SharedCompileArguments.rsp"),
				]),
			BuildOperation.new(
				"./File1.cpp",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.clang++"),
				[
					"@C:/target/ObjectDir/SharedCompileArguments.rsp",
					"-fmodule-file=Other1=./obj/Other1.pcm",
					"-x",
					"c++-module",
					"./File1.cpp",
					"-o",
					"C:/target/obj/File1.o",
					"--precompile",
					"-o",
					"C:/target/obj/File1.pcm",
				],
				[
					Path.new("Module.pcm"),
					Path.new("File1.cpp"),
					Path.new("C:/target/ObjectDir/SharedCompileArguments.rsp"),
					Path.new("obj/Other1.pcm"),
				],
				[
					Path.new("C:/target/obj/File1.o"),
					Path.new("C:/target/obj/File1.pcm"),
				]),
			BuildOperation.new(
				"./File2.cpp",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.clang++"),
				[
					"@C:/target/ObjectDir/SharedCompileArguments.rsp",
					"-fmodule-file=Other2=./obj/Other2.pcm",
					"-x",
					"c++-module",
					"./File2.cpp",
					"--precompile",
					"-o",
					"C:/target/obj/File2.pcm",
				],
				[
					Path.new("Module.pcm"),
					Path.new("File2.cpp"),
					Path.new("C:/target/ObjectDir/SharedCompileArguments.rsp"),
					Path.new("obj/Other2.pcm"),
				],
				[
					Path.new("C:/target/obj/File2.pcm"),
				]),
			BuildOperation.new(
				"./obj/File2.pcm",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.clang++"),
				[
					"-c",
					"-fmodule-file=Module=./Module.pcm",
					"C:/target/obj/File2.pcm",
					"-o",
					"C:/target/obj/File2.o",
				],
				[
					Path.new("C:/target/obj/File2.pcm"),
				],
				[
					Path.new("C:/target/obj/File2.o"),
				]),
			BuildOperation.new(
				"./File3.cpp",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.clang++"),
				[
					"@C:/target/ObjectDir/SharedCompileArguments.rsp",
					"-fmodule-file=Other3=./obj/Other3.pcm",
					"-fmodule-file=Module1=C:/target/obj/File2.pcm",
					"-fmodule-file=Module1:File1=C:/target/obj/File1.pcm",
					"./File3.cpp",
					"-o",
					"C:/target/obj/File3.o",
				],
				[
					Path.new("Module.pcm"),
					Path.new("File3.cpp"),
					Path.new("C:/target/ObjectDir/SharedCompileArguments.rsp"),
					Path.new("obj/Other3.pcm"),
					Path.new("C:/target/obj/File2.pcm"),
					Path.new("C:/target/obj/File1.pcm"),
				],
				[
					Path.new("C:/target/obj/File3.o"),
				]),
		]

		Assert.ListEqual(expected, result)
	}

	// [Fact]
	Compile_Resource() {
		var uut = ClangCompiler.new(
			Path.new("C:/bin/mock.clang++"),
			Path.new("C:/bin/mock.ar"))

		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP11
		arguments.Optimize = OptimizationLevel.None
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("ObjectDir/")
		arguments.IncludeDirectories = [
			Path.new("Includes"),
		]
		arguments.IncludeModules = {
			"Module": Path.new("Module.pcm"),
		}
		arguments.PreprocessorDefinitions = [
			"DEBUG"
		]
		arguments.ResourceFile = ResourceCompileArguments.new(
			Path.new("Resources.rc"),
			Path.new("obj/Resources.res"))

		var result = uut.CreateCompileOperations(arguments)

		// Verify result
		var expected = [
			BuildOperation.new(
				"WriteFile [./ObjectDir/SharedCompileArguments.rsp]",
				Path.new("C:/target/"),
				Path.new("./writefile.exe"),
				[
					"./ObjectDir/SharedCompileArguments.rsp",
					"-std=c++11 -O0 -I\"./Includes\" -DDEBUG -fmodule-file=Module=./Module.pcm -mpclmul -maes -msse4.1 -msha -c",
				],
				[],
				[
					Path.new("./ObjectDir/SharedCompileArguments.rsp"),
				]),
			BuildOperation.new(
				"./Resources.rc",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.rc.exe"),
				[
					"-D_UNICODE",
					"-DUNICODE",
					"-l\"0x0409\"",
					"-I\"./Includes\"",
					"-o",
					"C:/target/obj/Resources.res",
					"./Resources.rc",
				],
				[
					Path.new("Module.pcm"),
					Path.new("Resources.rc"),
					Path.new("C:/target/fake_file"),
				],
				[
					Path.new("C:/target/obj/Resources.res"),
				]),
		]

		Assert.ListEqual(expected, result)
	}

	// [Fact]
	LinkStaticLibrary_Simple() {
		var uut = ClangCompiler.new(
			Path.new("C:/bin/mock.clang++"),
			Path.new("C:/bin/mock.ar"))

		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.StaticLibrary
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Library.mock.a")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectFiles = [
			Path.new("File.mock.o"),
		]

		var result = uut.CreateLinkOperation(arguments)

		// Verify result
		var expected = BuildOperation.new(
			"./Library.mock.a",
			Path.new("C:/target/"),
			Path.new("C:/bin/mock.ar"),
			[
				"-r",
				"./Library.mock.a",
				"./File.mock.o",
			],
			[
				Path.new("File.mock.o"),
			],
			[
				Path.new("C:/target/Library.mock.a"),
			])

		Assert.Equal(expected, result)
	}

	// [Fact]
	LinkExecutable_Simple() {
		var uut = ClangCompiler.new(
			Path.new("C:/bin/mock.clang++"),
			Path.new("C:/bin/mock.ar"))

		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.Executable
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Something.exe")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectFiles = [
			Path.new("File.mock.o"),
		]
		arguments.LibraryFiles = [
			Path.new("Library.mock.a"),
		]

		var result = uut.CreateLinkOperation(arguments)

		// Verify result
		var expected = BuildOperation.new(
			"./Something.exe",
			Path.new("C:/target/"),
			Path.new("C:/bin/mock.clang++"),
			[
				"-fsanitize=address",
				"-fno-omit-frame-pointer",
				"-o",
				"./Something.exe",
				"./File.mock.o",
				"./Library.mock.a",
			],
			[
				Path.new("Library.mock.a"),
				Path.new("File.mock.o"),
			],
			[
				Path.new("C:/target/Something.exe"),
			])

		Assert.Equal(expected, result)
	}

	// [Fact]
	LinkWindowsApplication_Simple() {
		var uut = ClangCompiler.new(
			Path.new("C:/bin/mock.clang++"),
			Path.new("C:/bin/mock.ar"))

		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.WindowsApplication
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Something.exe")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectFiles = [
			Path.new("File.mock.o"),
		]
		arguments.LibraryFiles = [
			Path.new("Library.mock.a"),
		]

		var result = uut.CreateLinkOperation(arguments)

		// Verify result
		var expected = BuildOperation.new(
			"./Something.exe",
			Path.new("C:/target/"),
			Path.new("C:/bin/mock.clang++"),
			[
				"-o",
				"./Something.exe",
				"./Library.mock.a",
				"./File.mock.o",
			],
			[
				Path.new("Library.mock.a"),
				Path.new("File.mock.o"),
			],
			[
				Path.new("C:/target/Something.exe"),
			])

		Assert.Equal(expected, result)
	}
}

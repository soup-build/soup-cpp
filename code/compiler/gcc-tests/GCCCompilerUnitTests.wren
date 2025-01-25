// <copyright file="GCCCompilerUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../gcc/GCCCompiler" for GCCCompiler
import "Soup|Build.Utils:./Path" for Path
import "../../test/Assert" for Assert
import "Soup|Build.Utils:./BuildOperation" for BuildOperation
import "../core/LinkArguments" for LinkArguments, LinkTarget
import "../core/CompileArguments" for InterfaceUnitCompileArguments, LanguageStandard, OptimizationLevel,  SharedCompileArguments, ResourceCompileArguments, TranslationUnitCompileArguments

class GCCCompilerUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("GCCCompilerUnitTests.Initialize")
		this.Initialize()
		System.print("GCCCompilerUnitTests.Compile_Simple")
		this.Compile_Simple()
		System.print("GCCCompilerUnitTests.Compile_Module_Partition")
		this.Compile_Module_Partition()
		System.print("GCCCompilerUnitTests.Compile_Module_Interface")
		this.Compile_Module_Interface()
		System.print("GCCCompilerUnitTests.Compile_Module_PartitionInterfaceAndImplementation")
		this.Compile_Module_PartitionInterfaceAndImplementation()
		System.print("GCCCompilerUnitTests.Compile_Resource")
		this.Compile_Resource()
		System.print("GCCCompilerUnitTests.LinkStaticLibrary_Simple")
		this.LinkStaticLibrary_Simple()
		System.print("GCCCompilerUnitTests.LinkExecutable_Simple")
		this.LinkExecutable_Simple()
		System.print("GCCCompilerUnitTests.LinkWindowsApplication_Simple")
		this.LinkWindowsApplication_Simple()
	}

	// [Fact]
	Initialize() {
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.gcc.exe"))
		Assert.Equal("GCC", uut.Name)
		Assert.Equal("o", uut.ObjectFileExtension)
		Assert.Equal("ifc", uut.ModuleFileExtension)
		Assert.Equal(Path.new("libTest.a"), uut.CreateStaticLibraryFileName("Test"))
		Assert.Equal("so", uut.DynamicLibraryFileExtension)
		Assert.Equal("res", uut.ResourceFileExtension)
	}

	// [Fact]
	Compile_Simple(){
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.gcc.exe"))

		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP11
		arguments.Optimize = OptimizationLevel.None
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("ObjectDir/")

		var translationUnitArguments = TranslationUnitCompileArguments.new()
		translationUnitArguments.SourceFile = Path.new("File.cpp")
		translationUnitArguments.TargetFile = Path.new("obj/File.obj")

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
					"-std=c++11 -O0 -c",
				],
				[],
				[
					Path.new("./ObjectDir/SharedCompileArguments.rsp"),
				]),
			BuildOperation.new(
				"./File.cpp",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.gcc.exe"),
				[
					"@C:/target/ObjectDir/SharedCompileArguments.rsp",
					"./File.cpp",
					"-o",
					"C:/target/obj/File.obj",
				],
				[
					Path.new("File.cpp"),
					Path.new("C:/target/ObjectDir/SharedCompileArguments.rsp"),
				],
				[
					Path.new("C:/target/obj/File.obj"),
				]),
		]

		Assert.ListEqual(expected, result)
	}

	// [Fact]
	Compile_Module_Partition() {
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.gcc.exe"))

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
				Path.new("obj/File.obj"),
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
					"-std=c++11 -O0 -I\"./Includes\" -DDEBUG -reference ./Module.pcm -c",
				],
				[],
				[
					Path.new("./ObjectDir/SharedCompileArguments.rsp"),
				]),
			BuildOperation.new(
				"./File.cpp",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.gcc.exe"),
				[
					"@C:/target/ObjectDir/SharedCompileArguments.rsp",
					"-reference",
					"./obj/Other.pcm",
					"./File.cpp",
					"-o",
					"C:/target/obj/File.obj",
					"-interface",
					"-ifcOutput",
					"C:/target/obj/File.pcm",
				],
				[
					Path.new("Module.pcm"),
					Path.new("File.cpp"),
					Path.new("C:/target/ObjectDir/SharedCompileArguments.rsp"),
					Path.new("obj/Other.pcm"),
				],
				[
					Path.new("C:/target/obj/File.obj"),
					Path.new("C:/target/obj/File.pcm"),
				]),
		]

		Assert.ListEqual(expected, result)
	}

	// [Fact]
	Compile_Module_Interface() {
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.gcc.exe"))

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
			Path.new("obj/File.obj"),
			{
				"Other": Path.new("obj/Other.pcm"),
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
					"-std=c++11 -O0 -I\"./Includes\" -DDEBUG -reference ./Module.pcm -c",
				],
				[],
				[
					Path.new("./ObjectDir/SharedCompileArguments.rsp"),
				]),
			BuildOperation.new(
				"./File.cpp",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.gcc.exe"),
				[
					"@C:/target/ObjectDir/SharedCompileArguments.rsp",
					"-reference",
					"./obj/Other.pcm",
					"./File.cpp",
					"-o",
					"C:/target/obj/File.obj",
					"-fmodules-ts",
				],
				[
					Path.new("Module.pcm"),
					Path.new("File.cpp"),
					Path.new("C:/target/ObjectDir/SharedCompileArguments.rsp"),
					Path.new("obj/Other.pcm"),
				],
				[
					Path.new("C:/target/obj/File.obj"),
					Path.new("C:/target/obj/File.pcm"),
				]),
		]

		Assert.ListEqual(expected, result)
	}

	// [Fact]
	Compile_Module_PartitionInterfaceAndImplementation() {
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.gcc.exe"))

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
				Path.new("obj/File1.obj"),
				{
					"Other1": Path.new("obj/Other1.pcm")
				},
				"Module1:File1",
				Path.new("obj/File1.pcm")),
		]
		arguments.InterfaceUnit = InterfaceUnitCompileArguments.new(
			Path.new("File2.cpp"),
			Path.new("obj/File2.obj"),
			{
				"Other2": Path.new("obj/Other2.pcm"),
			},
			"Module1",
			Path.new("obj/File2.pcm"))
		arguments.ImplementationUnits = [
			TranslationUnitCompileArguments.new(
				Path.new("File3.cpp"),
				Path.new("obj/File3.obj"),
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
					"-std=c++11 -O0 -I\"./Includes\" -DDEBUG -reference ./Module.pcm -c",
				],
				[],
				[
					Path.new("./ObjectDir/SharedCompileArguments.rsp"),
				]),
			BuildOperation.new(
				"./File1.cpp",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.gcc.exe"),
				[
					"@C:/target/ObjectDir/SharedCompileArguments.rsp",
					"-reference",
					"./obj/Other1.pcm",
					"./File1.cpp",
					"-o",
					"C:/target/obj/File1.obj",
					"-interface",
					"-ifcOutput",
					"C:/target/obj/File1.pcm",
				],
				[
					Path.new("Module.pcm"),
					Path.new("File1.cpp"),
					Path.new("C:/target/ObjectDir/SharedCompileArguments.rsp"),
					Path.new("obj/Other1.pcm"),
				],
				[
					Path.new("C:/target/obj/File1.obj"),
					Path.new("C:/target/obj/File1.pcm"),
				]),
			BuildOperation.new(
				"./File2.cpp",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.gcc.exe"),
				[
					"@C:/target/ObjectDir/SharedCompileArguments.rsp",
					"-reference",
					"./obj/Other2.pcm",
					"./File2.cpp",
					"-o",
					"C:/target/obj/File2.obj",
					"-fmodules-ts",
				],
				[
					Path.new("Module.pcm"),
					Path.new("File2.cpp"),
					Path.new("C:/target/ObjectDir/SharedCompileArguments.rsp"),
					Path.new("obj/Other2.pcm"),
				],
				[
					Path.new("C:/target/obj/File2.obj"),
					Path.new("C:/target/obj/File2.pcm"),
				]),
			BuildOperation.new(
				"./File3.cpp",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.gcc.exe"),
				[
					"@C:/target/ObjectDir/SharedCompileArguments.rsp",
					"-reference",
					"./obj/Other3.pcm",
					"-reference",
					"C:/target/obj/File2.pcm",
					"-reference",
					"C:/target/obj/File1.pcm",
					"./File3.cpp",
					"-o",
					"C:/target/obj/File3.obj",
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
					Path.new("C:/target/obj/File3.obj"),
				]),
		]

		Assert.ListEqual(expected, result)
	}

	// [Fact]
	Compile_Resource() {
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.gcc.exe"))

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
					"-std=c++11 -O0 -I\"./Includes\" -DDEBUG -reference ./Module.pcm -c",
				],
				[],
				[
					Path.new("./ObjectDir/SharedCompileArguments.rsp"),
				]),
			BuildOperation.new(
				"./Resources.rc",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.gcc.exe"),
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
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.gcc.exe"))

		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.StaticLibrary
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Library.mock.a")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectFiles = [
			Path.new("File.mock.obj"),
		]

		var result = uut.CreateLinkOperation(arguments)

		// Verify result
		var expected = BuildOperation.new(
			"./Library.mock.a",
			Path.new("C:/target/"),
			Path.new("C:/bin/mock.gcc.exe"),
			[
				"-o",
				"./Library.mock.a",
				"./File.mock.obj",
			],
			[
				Path.new("File.mock.obj"),
			],
			[
				Path.new("C:/target/Library.mock.a"),
			])

		Assert.Equal(expected, result)
	}

	// [Fact]
	LinkExecutable_Simple() {
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.gcc.exe"))

		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.Executable
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Something.exe")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectFiles = [
			Path.new("File.mock.obj"),
		]
		arguments.LibraryFiles = [
			Path.new("Library.mock.a"),
		]

		var result = uut.CreateLinkOperation(arguments)

		// Verify result
		var expected = BuildOperation.new(
			"./Something.exe",
			Path.new("C:/target/"),
			Path.new("C:/bin/mock.gcc.exe"),
			[
				"-o",
				"./Something.exe",
				"./Library.mock.a",
				"./File.mock.obj",
			],
			[
				Path.new("Library.mock.a"),
				Path.new("File.mock.obj"),
			],
			[
				Path.new("C:/target/Something.exe"),
			])

		Assert.Equal(expected, result)
	}

	// [Fact]
	LinkWindowsApplication_Simple() {
		var uut = GCCCompiler.new(
			Path.new("C:/bin/mock.gcc.exe"))

		var arguments = LinkArguments.new()
		arguments.TargetType = LinkTarget.WindowsApplication
		arguments.TargetArchitecture = "x64"
		arguments.TargetFile = Path.new("Something.exe")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectFiles = [
			Path.new("File.mock.obj"),
		]
		arguments.LibraryFiles = [
			Path.new("Library.mock.a"),
		]

		var result = uut.CreateLinkOperation(arguments)

		// Verify result
		var expected = BuildOperation.new(
			"./Something.exe",
			Path.new("C:/target/"),
			Path.new("C:/bin/mock.gcc.exe"),
			[
				"-o",
				"./Something.exe",
				"./Library.mock.a",
				"./File.mock.obj",
			],
			[
				Path.new("Library.mock.a"),
				Path.new("File.mock.obj"),
			],
			[
				Path.new("C:/target/Something.exe"),
			])

		Assert.Equal(expected, result)
	}
}

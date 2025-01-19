// <copyright file="MSVCArgumentBuilderUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../msvc/MSVCArgumentBuilder" for MSVCArgumentBuilder
import "Soup|Build.Utils:./Path" for Path
import "../../test/Assert" for Assert
import "../core/CompileArguments" for InterfaceUnitCompileArguments, LanguageStandard, OptimizationLevel, SharedCompileArguments, TranslationUnitCompileArguments

class MSVCArgumentBuilderUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_LanguageStandard")
		this.BSCA_SingleArgument_LanguageStandard(LanguageStandard.CPP11, "/std:c++11")
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_LanguageStandard")
		this.BSCA_SingleArgument_LanguageStandard(LanguageStandard.CPP14, "/std:c++14")
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_LanguageStandard")
		this.BSCA_SingleArgument_LanguageStandard(LanguageStandard.CPP17, "/std:c++17")
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_LanguageStandard_CPP20")
		this.BSCA_SingleArgument_LanguageStandard_CPP20()
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_OptimizationLevel_Disabled")
		this.BSCA_SingleArgument_OptimizationLevel_Disabled()
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_OptimizationLevel")
		this.BSCA_SingleArgument_OptimizationLevel(OptimizationLevel.Size, "/Os")
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_OptimizationLevel")
		this.BSCA_SingleArgument_OptimizationLevel(OptimizationLevel.Speed, "/Ot")
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_EnableWarningsAsErrors")
		this.BSCA_SingleArgument_EnableWarningsAsErrors()
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_GenerateDebugInformation")
		this.BSCA_SingleArgument_GenerateDebugInformation()
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_IncludePaths")
		this.BSCA_SingleArgument_IncludePaths()
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_PreprocessorDefinitions")
		this.BSCA_SingleArgument_PreprocessorDefinitions()
		System.print("MSVCArgumentBuilderUnitTests.BSCA_SingleArgument_Modules")
		this.BSCA_SingleArgument_Modules()
		System.print("MSVCArgumentBuilderUnitTests.BuildPartitionUnitCompilerArguments")
		this.BuildPartitionUnitCompilerArguments()
		System.print("MSVCArgumentBuilderUnitTests.BuildInterfaceUnitCompilerArguments")
		this.BuildInterfaceUnitCompilerArguments()
		System.print("MSVCArgumentBuilderUnitTests.BuildTranslationUnitCompilerArguments_Simple")
		this.BuildTranslationUnitCompilerArguments_Simple()
		System.print("MSVCArgumentBuilderUnitTests.BuildTranslationUnitCompilerArguments_InternalModules")
		this.BuildTranslationUnitCompilerArguments_InternalModules()
		System.print("MSVCArgumentBuilderUnitTests.BuildAssemblyUnitCompilerArguments_Simple")
		this.BuildAssemblyUnitCompilerArguments_Simple()
	}

	// [Theory]
	// [InlineData(LanguageStandard.CPP11, "/std:c++11")]
	// [InlineData(LanguageStandard.CPP14, "/std:c++14")]
	// [InlineData(LanguageStandard.CPP17, "/std:c++17")]
	BSCA_SingleArgument_LanguageStandard(
		standard,
		expectedFlag) {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = standard
		arguments.Optimize = OptimizationLevel.None

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/TP",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/W4",
			expectedFlag,
			"/Od",
			"/X",
			"/RTC1",
			"/EHsc",
			"/MT",
			"/bigobj",
			"/c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_LanguageStandard_CPP20() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP20
		arguments.Optimize = OptimizationLevel.None

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/TP",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/W4",
			"/std:c++latest",
			"/Od",
			"/X",
			"/RTC1",
			"/EHsc",
			"/MT",
			"/bigobj",
			"/c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_OptimizationLevel_Disabled() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP17
		arguments.Optimize = OptimizationLevel.None

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/TP",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/W4",
			"/std:c++17",
			"/Od",
			"/X",
			"/RTC1",
			"/EHsc",
			"/MT",
			"/bigobj",
			"/c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Theory]
	// [InlineData(OptimizationLevel.Size, "/Os")]
	// [InlineData(OptimizationLevel.Speed, "/Ot")]
	BSCA_SingleArgument_OptimizationLevel(
		level,
		expectedFlag) {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP17
		arguments.Optimize = level

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/TP",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/W4",
			"/std:c++17",
			expectedFlag,
			"/X",
			"/RTC1",
			"/EHsc",
			"/MT",
			"/bigobj",
			"/c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_EnableWarningsAsErrors() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP17
		arguments.Optimize = OptimizationLevel.None
		arguments.EnableWarningsAsErrors = true

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/TP",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/WX",
			"/W4",
			"/std:c++17",
			"/Od",
			"/X",
			"/RTC1",
			"/EHsc",
			"/MT",
			"/bigobj",
			"/c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_GenerateDebugInformation() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP17
		arguments.Optimize = OptimizationLevel.None
		arguments.GenerateSourceDebugInfo = true

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/TP",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/Z7",
			"/W4",
			"/std:c++17",
			"/Od",
			"/X",
			"/RTC1",
			"/EHsc",
			"/MTd",
			"/bigobj",
			"/c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_IncludePaths() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP11
		arguments.Optimize = OptimizationLevel.None
		arguments.IncludeDirectories = [
			Path.new("C:/Files/SDK/"),
			Path.new("my files/")
		]

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/TP",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/W4",
			"/std:c++11",
			"/Od",
			"/I\"C:/Files/SDK/\"",
			"/I\"./my files/\"",
			"/X",
			"/RTC1",
			"/EHsc",
			"/MT",
			"/bigobj",
			"/c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_PreprocessorDefinitions() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP11
		arguments.Optimize = OptimizationLevel.None
		arguments.PreprocessorDefinitions = [
			"DEBUG",
			"VERSION=1"
		]

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/TP",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/W4",
			"/std:c++11",
			"/Od",
			"/DDEBUG",
			"/DVERSION=1",
			"/X",
			"/RTC1",
			"/EHsc",
			"/MT",
			"/bigobj",
			"/c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_Modules() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP11
		arguments.Optimize = OptimizationLevel.None
		arguments.IncludeModules = [
			Path.new("Module.pcm"),
			Path.new("Std.pcm"),
		]

		var actualArguments = MSVCArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"/nologo",
			"/TP",
			"/FC",
			"/permissive-",
			"/Zc:__cplusplus",
			"/Zc:externConstexpr",
			"/Zc:inline",
			"/Zc:throwingNew",
			"/W4",
			"/std:c++11",
			"/Od",
			"/X",
			"/RTC1",
			"/EHsc",
			"/MT",
			"/reference",
			"./Module.pcm",
			"/reference",
			"./Std.pcm",
			"/bigobj",
			"/c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildPartitionUnitCompilerArguments() {
		var targetRootDirectory = Path.new("C:/target/")
		var arguments = InterfaceUnitCompileArguments.new()
		arguments.SourceFile = Path.new("module.cpp")
		arguments.TargetFile = Path.new("module.obj")
		arguments.ModuleInterfaceTarget = Path.new("module.ifc")

		var responseFile = Path.new("ResponseFile.txt")

		var actualArguments = MSVCArgumentBuilder.BuildPartitionUnitCompilerArguments(
			targetRootDirectory,
			arguments,
			responseFile)

		var expectedArguments = [
			"@./ResponseFile.txt",
			"./module.cpp",
			"/Fo\"C:/target/module.obj\"",
			"/interface",
			"/ifcOutput",
			"C:/target/module.ifc",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildInterfaceUnitCompilerArguments() {
		var targetRootDirectory = Path.new("C:/target/")
		var arguments = InterfaceUnitCompileArguments.new()
		arguments.SourceFile = Path.new("module.cpp")
		arguments.TargetFile = Path.new("module.obj")
		arguments.ModuleInterfaceTarget = Path.new("module.ifc")

		var responseFile = Path.new("ResponseFile.txt")

		var actualArguments = MSVCArgumentBuilder.BuildInterfaceUnitCompilerArguments(
			targetRootDirectory,
			arguments,
			responseFile)

		var expectedArguments = [
			"@./ResponseFile.txt",
			"./module.cpp",
			"/Fo\"C:/target/module.obj\"",
			"/interface",
			"/ifcOutput",
			"C:/target/module.ifc",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildTranslationUnitCompilerArguments_Simple() {
		var targetRootDirectory = Path.new("C:/target/")
		var arguments = TranslationUnitCompileArguments.new()
		arguments.SourceFile = Path.new("module.cpp")
		arguments.TargetFile = Path.new("module.obj")

		var responseFile = Path.new("ResponseFile.txt")
		var internalModules = []

		var actualArguments = MSVCArgumentBuilder.BuildTranslationUnitCompilerArguments(
			targetRootDirectory,
			arguments,
			responseFile,
			internalModules)

		var expectedArguments = [
			"@./ResponseFile.txt",
			"./module.cpp",
			"/Fo\"C:/target/module.obj\"",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildTranslationUnitCompilerArguments_InternalModules() {
		var targetRootDirectory = Path.new("C:/target/")
		var arguments = TranslationUnitCompileArguments.new()
		arguments.SourceFile = Path.new("module.cpp")
		arguments.TargetFile = Path.new("module.obj")
		arguments.IncludeModules = [
			Path.new("Module1.ifc"),
			Path.new("Module2.ifc"),
		]

		var responseFile = Path.new("ResponseFile.txt")
		var internalModules = [
			Path.new("Module3.ifc"),
			Path.new("Module4.ifc"),
		]

		var actualArguments = MSVCArgumentBuilder.BuildTranslationUnitCompilerArguments(
			targetRootDirectory,
			arguments,
			responseFile,
			internalModules)

		var expectedArguments = [
			"@./ResponseFile.txt",
			"/reference",
			"./Module1.ifc",
			"/reference",
			"./Module2.ifc",
			"/reference",
			"./Module3.ifc",
			"/reference",
			"./Module4.ifc",
			"./module.cpp",
			"/Fo\"C:/target/module.obj\"",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildAssemblyUnitCompilerArguments_Simple() {
		var targetRootDirectory = Path.new("C:/target/")
		var sharedArguments = SharedCompileArguments.new()
		var arguments = TranslationUnitCompileArguments.new()
		arguments.SourceFile = Path.new("module.asm")
		arguments.TargetFile = Path.new("module.obj")

		var actualArguments = MSVCArgumentBuilder.BuildAssemblyUnitCompilerArguments(
			targetRootDirectory,
			sharedArguments,
			arguments)

		var expectedArguments = [
			"/nologo",
			"/Fo\"C:/target/module.obj\"",
			"/c",
			"/Z7",
			"/W3",
			"./module.asm",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}
}

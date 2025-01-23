// <copyright file="ClangArgumentBuilderUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "Soup|Build.Utils:./Path" for Path
import "../clang/ClangArgumentBuilder" for ClangArgumentBuilder
import "../../test/Assert" for Assert
import "../core/CompileArguments" for InterfaceUnitCompileArguments, LanguageStandard, OptimizationLevel, SharedCompileArguments, TranslationUnitCompileArguments

class ClangArgumentBuilderUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("ClangArgumentBuilderUnitTests.BSCA_SingleArgument_LanguageStandard")
		this.BSCA_SingleArgument_LanguageStandard(LanguageStandard.CPP11, "-std=c++11")
		System.print("ClangArgumentBuilderUnitTests.BSCA_SingleArgument_LanguageStandard")
		this.BSCA_SingleArgument_LanguageStandard(LanguageStandard.CPP14, "-std=c++14")
		System.print("ClangArgumentBuilderUnitTests.BSCA_SingleArgument_LanguageStandard")
		this.BSCA_SingleArgument_LanguageStandard(LanguageStandard.CPP17, "-std=c++17")
		System.print("ClangArgumentBuilderUnitTests.BSCA_SingleArgument_LanguageStandard_CPP20")
		this.BSCA_SingleArgument_LanguageStandard_CPP20()
		System.print("ClangArgumentBuilderUnitTests.BSCA_SingleArgument_OptimizationLevel_Disabled")
		this.BSCA_SingleArgument_OptimizationLevel_Disabled()
		System.print("ClangArgumentBuilderUnitTests.BSCA_SingleArgument_OptimizationLevel")
		this.BSCA_SingleArgument_OptimizationLevel(OptimizationLevel.Size, "-Os")
		System.print("ClangArgumentBuilderUnitTests.BSCA_SingleArgument_OptimizationLevel")
		this.BSCA_SingleArgument_OptimizationLevel(OptimizationLevel.Speed, "-O3")
		System.print("ClangArgumentBuilderUnitTests.BSCA_SingleArgument_EnableWarningsAsErrors")
		this.BSCA_SingleArgument_EnableWarningsAsErrors()
		System.print("ClangArgumentBuilderUnitTests.BSCA_SingleArgument_GenerateDebugInformation")
		this.BSCA_SingleArgument_GenerateDebugInformation()
		System.print("ClangArgumentBuilderUnitTests.BSCA_SingleArgument_IncludePaths")
		this.BSCA_SingleArgument_IncludePaths()
		System.print("ClangArgumentBuilderUnitTests.BSCA_SingleArgument_PreprocessorDefinitions")
		this.BSCA_SingleArgument_PreprocessorDefinitions()
		System.print("ClangArgumentBuilderUnitTests.BSCA_SingleArgument_Modules")
		this.BSCA_SingleArgument_Modules()
		System.print("ClangArgumentBuilderUnitTests.BuildPartitionUnitCompilerArguments")
		this.BuildPartitionUnitCompilerArguments()
		System.print("ClangArgumentBuilderUnitTests.BuildInterfaceUnitPrecompileCompilerArguments")
		this.BuildInterfaceUnitPrecompileCompilerArguments()
		System.print("ClangArgumentBuilderUnitTests.BuildInterfaceUnitCompileCompilerArguments")
		this.BuildInterfaceUnitCompileCompilerArguments()
		System.print("ClangArgumentBuilderUnitTests.BuildTranslationUnitCompilerArguments_Simple")
		this.BuildTranslationUnitCompilerArguments_Simple()
		System.print("ClangArgumentBuilderUnitTests.BuildTranslationUnitCompilerArguments_InternalModules")
		this.BuildTranslationUnitCompilerArguments_InternalModules()
		System.print("ClangArgumentBuilderUnitTests.BuildAssemblyUnitCompilerArguments_Simple")
		this.BuildAssemblyUnitCompilerArguments_Simple()
	}

	// [Theory]
	// [InlineData(LanguageStandard.CPP11, "-std=c++11")]
	// [InlineData(LanguageStandard.CPP14, "-std=c++14")]
	// [InlineData(LanguageStandard.CPP17, "-std=c++17")]
	BSCA_SingleArgument_LanguageStandard(
		standard,
		expectedFlag) {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = standard
		arguments.Optimize = OptimizationLevel.None

		var actualArguments = ClangArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-fpic",
			expectedFlag,
			"-O0",
			"-mpclmul",
			"-maes",
			"-msse4.1",
			"-msha", 
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_LanguageStandard_CPP20() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP20
		arguments.Optimize = OptimizationLevel.None

		var actualArguments = ClangArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-fpic",
			"-std=c++20",
			"-O0",
			"-mpclmul",
			"-maes",
			"-msse4.1",
			"-msha", 
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_OptimizationLevel_Disabled() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP17
		arguments.Optimize = OptimizationLevel.None

		var actualArguments = ClangArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-fpic",
			"-std=c++17",
			"-O0",
			"-mpclmul",
			"-maes",
			"-msse4.1",
			"-msha", 
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Theory]
	// [InlineData(OptimizationLevel.Size, "-Os")]
	// [InlineData(OptimizationLevel.Speed, "-O3")]
	BSCA_SingleArgument_OptimizationLevel(
		level,
		expectedFlag) {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP17
		arguments.Optimize = level

		var actualArguments = ClangArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-fpic",
			"-std=c++17",
			expectedFlag,
			"-mpclmul",
			"-maes",
			"-msse4.1",
			"-msha", 
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_EnableWarningsAsErrors() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP17
		arguments.Optimize = OptimizationLevel.None
		arguments.EnableWarningsAsErrors = true

		var actualArguments = ClangArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-Werror",
			"-fpic",
			"-std=c++17",
			"-O0",
			"-mpclmul",
			"-maes",
			"-msse4.1",
			"-msha", 
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_GenerateDebugInformation() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP17
		arguments.Optimize = OptimizationLevel.None
		arguments.GenerateSourceDebugInfo = true

		var actualArguments = ClangArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-g",
			"-fpic",
			"-std=c++17",
			"-O0",
			"-mpclmul",
			"-maes",
			"-msse4.1",
			"-msha", 
			"-c",
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

		var actualArguments = ClangArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-fpic",
			"-std=c++11",
			"-O0",
			"-I\"C:/Files/SDK/\"",
			"-I\"./my files/\"",
			"-mpclmul",
			"-maes",
			"-msse4.1",
			"-msha", 
			"-c",
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

		var actualArguments = ClangArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-fpic",
			"-std=c++11",
			"-O0",
			"-DDEBUG",
			"-DVERSION=1",
			"-mpclmul",
			"-maes",
			"-msse4.1",
			"-msha", 
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BSCA_SingleArgument_Modules() {
		var arguments = SharedCompileArguments.new()
		arguments.Standard = LanguageStandard.CPP11
		arguments.Optimize = OptimizationLevel.None
		arguments.IncludeModules = {
			"Module": Path.new("Module.pcm"),
			"Std": Path.new("Std.pcm"),
		}

		var actualArguments = ClangArgumentBuilder.BuildSharedCompilerArguments(
			arguments)

		var expectedArguments = [
			"-fpic",
			"-std=c++11",
			"-O0",
			"-fmodule-file=Std=./Std.pcm",
			"-fmodule-file=Module=./Module.pcm",
			"-mpclmul",
			"-maes",
			"-msse4.1",
			"-msha", 
			"-c",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildPartitionUnitCompilerArguments() {
		var targetRootDirectory = Path.new("C:/target/")
		var arguments = InterfaceUnitCompileArguments.new()
		arguments.SourceFile = Path.new("module.cpp")
		arguments.TargetFile = Path.new("module.o")
		arguments.ModuleInterfaceTarget = Path.new("module.pcm")

		var responseFile = Path.new("ResponseFile.txt")

		var actualArguments = ClangArgumentBuilder.BuildPartitionUnitCompilerArguments(
			targetRootDirectory,
			arguments,
			responseFile)

		var expectedArguments = [
			"@./ResponseFile.txt",
			"-x",
			"c++-module",
			"./module.cpp",
			"-o",
			"C:/target/module.o",
			"--precompile",
			"-o",
			"C:/target/module.pcm",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildInterfaceUnitPrecompileCompilerArguments() {
		var targetRootDirectory = Path.new("C:/target/")
		var arguments = InterfaceUnitCompileArguments.new()
		arguments.SourceFile = Path.new("module.cpp")
		arguments.TargetFile = Path.new("module.o")
		arguments.ModuleInterfaceTarget = Path.new("module.pcm")

		var responseFile = Path.new("ResponseFile.txt")

		var actualArguments = ClangArgumentBuilder.BuildInterfaceUnitPrecompileCompilerArguments(
			targetRootDirectory,
			arguments,
			responseFile)

		var expectedArguments = [
			"@./ResponseFile.txt",
			"-x",
			"c++-module",
			"./module.cpp",
			"--precompile",
			"-o",
			"C:/target/module.pcm",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildInterfaceUnitCompileCompilerArguments() {

		var sharedArguments = SharedCompileArguments.new()
		sharedArguments.TargetRootDirectory = Path.new("C:/target/")

		var interfaceArguments = InterfaceUnitCompileArguments.new()
		interfaceArguments.SourceFile = Path.new("module.cpp")
		interfaceArguments.TargetFile = Path.new("module.o")
		interfaceArguments.ModuleInterfaceTarget = Path.new("module.pcm")

		var responseFile = Path.new("ResponseFile.txt")

		var actualArguments = ClangArgumentBuilder.BuildInterfaceUnitCompileCompilerArguments(
			sharedArguments,
			interfaceArguments)

		var expectedArguments = [
			"-c",
			"C:/target/module.pcm",
			"-o",
			"C:/target/module.o",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildTranslationUnitCompilerArguments_Simple() {
		var targetRootDirectory = Path.new("C:/target/")
		var arguments = TranslationUnitCompileArguments.new()
		arguments.SourceFile = Path.new("module.cpp")
		arguments.TargetFile = Path.new("module.o")

		var responseFile = Path.new("ResponseFile.txt")
		var internalModules = {}

		var actualArguments = ClangArgumentBuilder.BuildTranslationUnitCompilerArguments(
			targetRootDirectory,
			arguments,
			responseFile,
			internalModules)

		var expectedArguments = [
			"@./ResponseFile.txt",
			"./module.cpp",
			"-o",
			"C:/target/module.o",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildTranslationUnitCompilerArguments_InternalModules() {
		var targetRootDirectory = Path.new("C:/target/")
		var arguments = TranslationUnitCompileArguments.new()
		arguments.SourceFile = Path.new("module.cpp")
		arguments.TargetFile = Path.new("module.o")
		arguments.IncludeModules = {
			"Module1": Path.new("Module1.pcm"),
			"Module2": Path.new("Module2.pcm"),
		}

		var responseFile = Path.new("ResponseFile.txt")
		var internalModules = {
			"Module3": Path.new("Module3.pcm"),
			"Module4": Path.new("Module4.pcm"),
		}

		var actualArguments = ClangArgumentBuilder.BuildTranslationUnitCompilerArguments(
			targetRootDirectory,
			arguments,
			responseFile,
			internalModules)

		var expectedArguments = [
			"@./ResponseFile.txt",
			"-fmodule-file=Module1=./Module1.pcm",
			"-fmodule-file=Module2=./Module2.pcm",
			"-fmodule-file=Module3=./Module3.pcm",
			"-fmodule-file=Module4=./Module4.pcm",
			"./module.cpp",
			"-o",
			"C:/target/module.o",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}

	// [Fact]
	BuildAssemblyUnitCompilerArguments_Simple() {
		var targetRootDirectory = Path.new("C:/target/")
		var sharedArguments = SharedCompileArguments.new()
		var arguments = TranslationUnitCompileArguments.new()
		arguments.SourceFile = Path.new("module.asm")
		arguments.TargetFile = Path.new("module.o")

		var actualArguments = ClangArgumentBuilder.BuildAssemblyUnitCompilerArguments(
			targetRootDirectory,
			sharedArguments,
			arguments)

		var expectedArguments = [
			"-o",
			"C:/target/module.o",
			"-c",
			"./module.asm",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}
}

// <copyright file="BuildEngineUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../../Utils/Path" for Path
import "../../BuildOperation" for BuildOperation
import "../../BuildState" for BuildState
import "../../Test/Assert" for Assert
import "../Core/BuildEngine" for BuildEngine
import "../Core/MockCompiler" for MockCompiler
import "../Core/BuildArguments" for BuildArguments, BuildOptimizationLevel, BuildTargetType, PartitionSourceFile, SourceFile
import "../Core/CompileArguments" for InterfaceUnitCompileArguments, LanguageStandard, OptimizationLevel, ResourceCompileArguments, SharedCompileArguments, TranslationUnitCompileArguments
import "../Core/LinkArguments" for LinkArguments, LinkTarget

class BuildEngineUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("BuildEngineUnitTests.Initialize_Success")
		this.Initialize_Success()
		System.print("BuildEngineUnitTests.Build_WindowsApplication")
		this.Build_WindowsApplication()
		System.print("BuildEngineUnitTests.Build_WindowsApplicationWithResource")
		this.Build_WindowsApplicationWithResource()
		System.print("BuildEngineUnitTests.Build_Executable")
		this.Build_Executable()
		System.print("BuildEngineUnitTests.Build_Library_MultipleFiles")
		this.Build_Library_MultipleFiles()
		System.print("BuildEngineUnitTests.Build_Library_ModuleInterface")
		this.Build_Library_ModuleInterface()
		System.print("BuildEngineUnitTests.Build_Library_ModuleInterface_WithPartitions")
		this.Build_Library_ModuleInterface_WithPartitions()
		System.print("BuildEngineUnitTests.Build_Library_ModuleInterface_WithPartitions_TransitiveImport")
		this.Build_Library_ModuleInterface_WithPartitions_TransitiveImport()
		System.print("BuildEngineUnitTests.Build_Library_ModuleInterfaceNoSource")
		this.Build_Library_ModuleInterfaceNoSource()
	}

	Initialize_Success() {
		var compiler = MockCompiler.new()
		var uut = BuildEngine.new(compiler)
	}

	Build_WindowsApplication() {
		// Register the mock compiler
		var compiler = MockCompiler.new()

		// Setup the build arguments
		var arguments = BuildArguments.new()
		arguments.TargetName = "Program"
		arguments.TargetType = BuildTargetType.WindowsApplication
		arguments.LanguageStandard = LanguageStandard.CPP20
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("obj/")
		arguments.BinaryDirectory = Path.new("bin/")
		arguments.SourceFiles = [
			Path.new("TestFile.cpp"),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)

		var buildState = BuildState.new()
		var result = uut.Execute(buildState, arguments)

		// Verify expected logs
		// Assert.ListEqual(
		// 	[
		// 		"INFO: Generate Compile Operation: ./TestFile.cpp",
		// 		"INFO: CoreLink",
		// 		"INFO: Linking target",
		// 		"INFO: Generate Link Operation: ./bin/Program.exe",
		// 	],
		// 	testListener.GetMessages())

		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.cpp")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnitArguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.WindowsApplication
		expectedLinkArguments.TargetFile = Path.new("bin/Program.exe")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/TestFile.mock.obj"),
		]
		expectedLinkArguments.LibraryFiles = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		// Verify expected compiler calls
		Assert.ListEqual([
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual([
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./bin/\"",
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile.cpp"),
				],
				[
					Path.new("obj/TestFile.mock.obj"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.ListEqual(
			[],
			result.ModuleDependencies)

		Assert.ListEqual(
			[],
			result.LinkDependencies)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Program.exe"),
			],
			result.RuntimeDependencies)
	}

	Build_WindowsApplicationWithResource() {
		// Register the mock compiler
		var compiler = MockCompiler.new()

		// Setup the build arguments
		var arguments = BuildArguments.new()
		arguments.TargetName = "Program"
		arguments.TargetType = BuildTargetType.WindowsApplication
		arguments.LanguageStandard = LanguageStandard.CPP20
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("obj/")
		arguments.BinaryDirectory = Path.new("bin/")
		arguments.SourceFiles = [
			Path.new("TestFile.cpp"),
		]
		arguments.ResourceFile = Path.new("Resources.rc")
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)
		var buildState = BuildState.new()
		var result = uut.Execute(buildState, arguments)

		// Verify expected logs
		// Assert.ListEqual(
		// 	[
		// 		"INFO: Generate Resource File Compile: ./Resources.rc",
		// 		"INFO: Generate Compile Operation: ./TestFile.cpp",
		// 		"INFO: CoreLink",
		// 		"INFO: Linking target",
		// 		"INFO: Generate Link Operation: ./bin/Program.exe",
		// 	],
		// 	testListener.GetMessages())

		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.cpp")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnitArguments,
		]

		expectedCompileArguments.ResourceFile = ResourceCompileArguments.new()
		expectedCompileArguments.ResourceFile.SourceFile = Path.new("Resources.rc")
		expectedCompileArguments.ResourceFile.TargetFile = Path.new("obj/Resources.mock.res")

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.WindowsApplication
		expectedLinkArguments.TargetFile = Path.new("bin/Program.exe")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/Resources.mock.res"),
			Path.new("obj/TestFile.mock.obj"),
		]
		expectedLinkArguments.LibraryFiles = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./bin/\"",
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile.cpp"),
				],
				[
					Path.new("obj/TestFile.mock.obj"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.ListEqual(
			[],
			result.ModuleDependencies)

		Assert.ListEqual(
			[],
			result.LinkDependencies)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Program.exe"),
			],
			result.RuntimeDependencies)
	}

	Build_Executable() {
		// Register the mock compiler
		var compiler = MockCompiler.new()

		// Setup the build arguments
		var arguments = BuildArguments.new()
		arguments.TargetName = "Program"
		arguments.TargetType = BuildTargetType.Executable
		arguments.LanguageStandard = LanguageStandard.CPP20
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("obj/")
		arguments.BinaryDirectory = Path.new("bin/")
		arguments.SourceFiles = [
			Path.new("TestFile.cpp"),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)
		var buildState = BuildState.new()
		var result = uut.Execute(buildState, arguments)

		// Verify expected logs
		// Assert.ListEqual(
		// 	[
		// 		"INFO: Generate Compile Operation: ./TestFile.cpp",
		// 		"INFO: CoreLink",
		// 		"INFO: Linking target",
		// 		"INFO: Generate Link Operation: ./bin/Program.exe",
		// 	],
		// 	testListener.GetMessages())

		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.cpp")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnitArguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.Executable
		expectedLinkArguments.TargetFile = Path.new("bin/Program.exe")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
				Path.new("obj/TestFile.mock.obj"),
		]
		expectedLinkArguments.LibraryFiles = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./bin/\"",
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile.cpp"),
				],
				[
					Path.new("obj/TestFile.mock.obj"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.ListEqual(
			[],
			result.ModuleDependencies)

		Assert.ListEqual(
			[],
			result.LinkDependencies)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Program.exe"),
			],
			result.RuntimeDependencies)
	}

	Build_Library_MultipleFiles() {
		// Register the mock compiler
		var compiler = MockCompiler.new()

		// Setup the build arguments
		var arguments = BuildArguments.new()
		arguments.TargetName = "Library"
		arguments.TargetType = BuildTargetType.StaticLibrary
		arguments.LanguageStandard = LanguageStandard.CPP20
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("obj/")
		arguments.BinaryDirectory = Path.new("bin/")
		arguments.SourceFiles = [
			Path.new("TestFile1.cpp"),
			Path.new("TestFile2.cpp"),
			Path.new("TestFile3.cpp"),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.Size
		arguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		arguments.ModuleDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.bmi"),
			Path.new("../OtherModule2.mock.bmi"),
		]
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)
		var buildState = BuildState.new()
		var result = uut.Execute(buildState, arguments)

		// Verify expected logs
		// Assert.ListEqual(
		// 	[
		// 		"INFO: Generate Compile Operation: ./TestFile1.cpp",
		// 		"INFO: Generate Compile Operation: ./TestFile2.cpp",
		// 		"INFO: Generate Compile Operation: ./TestFile3.cpp",
		// 		"INFO: CoreLink",
		// 		"INFO: Linking target",
		// 		"INFO: Generate Link Operation: ./bin/Library.mock.lib",
		// 	],
		// 	testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.IncludeDirectories = [
				Path.new("Folder"),
				Path.new("AnotherFolder/Sub"),
		]
		expectedCompileArguments.IncludeModules = [
			Path.new("../Other/bin/OtherModule1.mock.bmi"),
			Path.new("../OtherModule2.mock.bmi"),
		]

		var expectedTranslationUnit1Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit1Arguments.SourceFile = Path.new("TestFile1.cpp")
		expectedTranslationUnit1Arguments.TargetFile = Path.new("obj/TestFile1.mock.obj")

		var expectedTranslationUnit2Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit2Arguments.SourceFile = Path.new("TestFile2.cpp")
		expectedTranslationUnit2Arguments.TargetFile = Path.new("obj/TestFile2.mock.obj")

		var expectedTranslationUnit3Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit2Arguments.SourceFile = Path.new("TestFile3.cpp")
		expectedTranslationUnit2Arguments.TargetFile = Path.new("obj/TestFile3.mock.obj")

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnit1Arguments,
			expectedTranslationUnit2Arguments,
			expectedTranslationUnit3Arguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
				Path.new("obj/TestFile1.mock.obj"),
				Path.new("obj/TestFile2.mock.obj"),
				Path.new("obj/TestFile3.mock.obj"),
		]

		// Note: There is no need to send along the static libraries for a static library linking
		expectedLinkArguments.LibraryFiles = []

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./bin/\"",
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile1.cpp"),
				],
				[
					Path.new("obj/TestFile1.mock.obj"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile2.cpp"),
				],
				[
					Path.new("obj/TestFile2.mock.obj"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile3.cpp"),
				],
				[
					Path.new("obj/TestFile3.mock.obj"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.ListEqual(
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
			],
			result.ModuleDependencies)

		Assert.ListEqual(
			[
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
				Path.new("C:/target/bin/Library.mock.lib"),
			],
			result.LinkDependencies)

		Assert.ListEqual(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			Path.new(),
			result.TargetFile)
	}

	Build_Library_ModuleInterface() {
		// Register the mock compiler
		var compiler = MockCompiler.new()

		// Setup the build arguments
		var arguments = BuildArguments.new()
		arguments.TargetName = "Library"
		arguments.TargetType = BuildTargetType.StaticLibrary
		arguments.LanguageStandard = LanguageStandard.CPP20
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("obj/")
		arguments.BinaryDirectory = Path.new("bin/")
		arguments.ModuleInterfaceSourceFile = Path.new("Public.cpp")
		arguments.SourceFiles = [
			Path.new("TestFile1.cpp"),
			Path.new("TestFile2.cpp"),
			Path.new("TestFile3.cpp"),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		arguments.ModuleDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.bmi"),
			Path.new("../OtherModule2.mock.bmi"),
		]
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]
		arguments.PreprocessorDefinitions = [
			"DEBUG",
			"AWESOME",
		]

		var uut = BuildEngine.new(compiler)
		var buildState = BuildState.new()
		var result = uut.Execute(buildState, arguments)

		// Verify expected logs
		// Assert.ListEqual(
		// 	[
		// 		"INFO: Generate Module Interface Unit Compile: ./Public.cpp",
		// 		"INFO: Generate Compile Operation: ./TestFile1.cpp",
		// 		"INFO: Generate Compile Operation: ./TestFile2.cpp",
		// 		"INFO: Generate Compile Operation: ./TestFile3.cpp",
		// 		"INFO: CoreLink",
		// 		"INFO: Linking target",
		// 		"INFO: Generate Link Operation: ./bin/Library.mock.lib",
		// 	],
		// 	testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		expectedCompileArguments.IncludeModules = [
			Path.new("../Other/bin/OtherModule1.mock.bmi"),
			Path.new("../OtherModule2.mock.bmi"),
		]
		expectedCompileArguments.PreprocessorDefinitions = [
			"DEBUG",
			"AWESOME",
		]

		var expectedCompileModuleArguments = InterfaceUnitCompileArguments.new()
		expectedCompileModuleArguments.SourceFile = Path.new("Public.cpp")
		expectedCompileModuleArguments.TargetFile = Path.new("obj/Public.mock.obj")
		expectedCompileModuleArguments.IncludeModules = []
		expectedCompileModuleArguments.ModuleInterfaceTarget = Path.new("obj/Public.mock.bmi")

		expectedCompileArguments.InterfaceUnit = expectedCompileModuleArguments

		var expectedTranslationUnit1Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit1Arguments.SourceFile = Path.new("TestFile1.cpp")
		expectedTranslationUnit1Arguments.TargetFile = Path.new("obj/TestFile1.mock.obj")

		var expectedTranslationUnit2Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit2Arguments.SourceFile = Path.new("TestFile2.cpp")
		expectedTranslationUnit2Arguments.TargetFile = Path.new("obj/TestFile2.mock.obj")

		var expectedTranslationUnit3Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit3Arguments.SourceFile = Path.new("TestFile3.cpp")
		expectedTranslationUnit3Arguments.TargetFile = Path.new("obj/TestFile3.mock.obj")

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnit1Arguments,
			expectedTranslationUnit2Arguments,
			expectedTranslationUnit3Arguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/Public.mock.obj"),
			Path.new("obj/TestFile1.mock.obj"),
			Path.new("obj/TestFile2.mock.obj"),
			Path.new("obj/TestFile3.mock.obj"),
		]

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./bin/\"",
				[],
				[
					Path.new("bin/"),
				]),
			BuildOperation.new(
				"Copy [./obj/Public.mock.bmi] -> [./bin/Library.mock.bmi]",
				Path.new("C:/target/"),
				Path.new("C:/copy.exe"),
				"\"./obj/Public.mock.bmi\" \"./bin/Library.mock.bmi\"",
				[
					Path.new("obj/Public.mock.bmi"),
				],
				[
					Path.new("bin/Library.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("Public.cpp"),
				],
				[
					Path.new("obj/Public.mock.obj"),
					Path.new("obj/Public.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile1.cpp"),
				],
				[
					Path.new("obj/TestFile1.mock.obj"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile2.cpp"),
				],
				[
					Path.new("obj/TestFile2.mock.obj"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile3.cpp"),
				],
				[
					Path.new("obj/TestFile3.mock.obj"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.ListEqual(
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
				Path.new("C:/target/bin/Library.mock.bmi"),
			],
			result.ModuleDependencies)

		Assert.ListEqual(
			[
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
				Path.new("C:/target/bin/Library.mock.lib"),
			],
			result.LinkDependencies)

		Assert.ListEqual(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			Path.new(),
			result.TargetFile)
	}

	Build_Library_ModuleInterface_WithPartitions() {
		// Register the mock compiler
		var compiler = MockCompiler.new()

		// Setup the build arguments
		var arguments = BuildArguments.new()
		arguments.TargetName = "Library"
		arguments.TargetType = BuildTargetType.StaticLibrary
		arguments.LanguageStandard = LanguageStandard.CPP20
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("obj/")
		arguments.BinaryDirectory = Path.new("bin/")
		arguments.ModuleInterfacePartitionSourceFiles = [
			PartitionSourceFile.new(
				Path.new("TestFile1.cpp"),
				[]),
			PartitionSourceFile.new(
				Path.new("TestFile2.cpp"),
				[
					Path.new("TestFile1.cpp"),
				]),
		]
		arguments.ModuleInterfaceSourceFile = Path.new("Public.cpp")
		arguments.SourceFiles = [
			Path.new("TestFile3.cpp"),
			Path.new("TestFile4.cpp"),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		arguments.ModuleDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.bmi"),
			Path.new("../OtherModule2.mock.bmi"),
		]
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]
		arguments.PreprocessorDefinitions = [
			"DEBUG",
			"AWESOME",
		]

		var uut = BuildEngine.new(compiler)
		var buildState = BuildState.new()
		var result = uut.Execute(buildState, arguments)

		// Verify expected logs
		// Assert.ListEqual(
		// 	[
		// 		"INFO: Generate Module Interface Partition Compile Operation: ./TestFile1.cpp",
		// 		"INFO: Generate Module Interface Partition Compile Operation: ./TestFile2.cpp",
		// 		"INFO: Generate Module Interface Unit Compile: ./Public.cpp",
		// 		"INFO: Generate Compile Operation: ./TestFile3.cpp",
		// 		"INFO: Generate Compile Operation: ./TestFile4.cpp",
		// 		"INFO: CoreLink",
		// 		"INFO: Linking target",
		// 		"INFO: Generate Link Operation: ./bin/Library.mock.lib",
		// 	],
		// 	testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.TargetRootDirectory = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		expectedCompileArguments.IncludeModules = [
			Path.new("../Other/bin/OtherModule1.mock.bmi"),
			Path.new("../OtherModule2.mock.bmi"),
		]
		expectedCompileArguments.PreprocessorDefinitions = [
			"DEBUG",
			"AWESOME",
		]

		var expectedInterfacePartitionUnit1Arguments = InterfaceUnitCompileArguments.new()
		expectedInterfacePartitionUnit1Arguments.SourceFile = Path.new("TestFile1.cpp")
		expectedInterfacePartitionUnit1Arguments.TargetFile = Path.new("obj/TestFile1.mock.obj")
		expectedInterfacePartitionUnit1Arguments.ModuleInterfaceTarget = Path.new("obj/TestFile1.mock.bmi")

		var expectedInterfacePartitionUnit2Arguments = InterfaceUnitCompileArguments.new()
		expectedInterfacePartitionUnit2Arguments.SourceFile = Path.new("TestFile2.cpp")
		expectedInterfacePartitionUnit2Arguments.TargetFile = Path.new("obj/TestFile2.mock.obj")
		expectedInterfacePartitionUnit2Arguments.IncludeModules = [
			Path.new("C:/target/obj/TestFile1.mock.bmi"),
		]
		expectedInterfacePartitionUnit2Arguments.ModuleInterfaceTarget = Path.new("obj/TestFile2.mock.bmi")

		expectedCompileArguments.InterfacePartitionUnits = [
			expectedInterfacePartitionUnit1Arguments,
			expectedInterfacePartitionUnit2Arguments
		]

		expectedCompileArguments.InterfaceUnit = InterfaceUnitCompileArguments.new()
		expectedCompileArguments.InterfaceUnit.SourceFile = Path.new("Public.cpp")
		expectedCompileArguments.InterfaceUnit.TargetFile = Path.new("obj/Public.mock.obj")
		expectedCompileArguments.InterfaceUnit.IncludeModules = [
			Path.new("C:/target/obj/TestFile1.mock.bmi"),
			Path.new("C:/target/obj/TestFile2.mock.bmi"),
		]
		expectedCompileArguments.InterfaceUnit.ModuleInterfaceTarget = Path.new("obj/Public.mock.bmi")

		expectedCompileArguments.ImplementationUnits = [
			TranslationUnitCompileArguments.new(
				Path.new("TestFile3.cpp"),
				Path.new("obj/TestFile3.mock.obj"),
				[]),
			TranslationUnitCompileArguments.new(
				Path.new("TestFile4.cpp"),
				Path.new("obj/TestFile4.mock.obj"),
				[]),
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/TestFile1.mock.obj"),
			Path.new("obj/TestFile2.mock.obj"),
			Path.new("obj/Public.mock.obj"),
			Path.new("obj/TestFile3.mock.obj"),
			Path.new("obj/TestFile4.mock.obj"),
		]

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./bin/\"",
				[],
				[
					Path.new("bin/"),
				]),
			BuildOperation.new(
				"Copy [./obj/Public.mock.bmi] -> [./bin/Library.mock.bmi]",
				Path.new("C:/target/"),
				Path.new("C:/copy.exe"),
				"\"./obj/Public.mock.bmi\" \"./bin/Library.mock.bmi\"",
				[
					Path.new("obj/Public.mock.bmi"),
				],
				[
					Path.new("bin/Library.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompilePartition: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile1.cpp"),
				],
				[
					Path.new("obj/TestFile1.mock.obj"),
					Path.new("obj/TestFile1.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompilePartition: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile2.cpp"),
				],
				[
					Path.new("obj/TestFile2.mock.obj"),
					Path.new("obj/TestFile2.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("Public.cpp"),
				],
				[
					Path.new("obj/Public.mock.obj"),
					Path.new("obj/Public.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile3.cpp"),
				],
				[
					Path.new("obj/TestFile3.mock.obj"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile4.cpp"),
				],
				[
					Path.new("obj/TestFile4.mock.obj"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.ListEqual(
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
				Path.new("C:/target/obj/TestFile1.mock.bmi"),
				Path.new("C:/target/obj/TestFile2.mock.bmi"),
				Path.new("C:/target/bin/Library.mock.bmi"),
			],
			result.ModuleDependencies)

		Assert.ListEqual(
			[
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
				Path.new("C:/target/bin/Library.mock.lib"),
			],
			result.LinkDependencies)

		Assert.ListEqual(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			Path.new(),
			result.TargetFile)
	}

	Build_Library_ModuleInterface_WithPartitions_TransitiveImport() {
		// Register the mock compiler
		var compiler = MockCompiler.new()

		// Setup the build arguments
		var arguments = BuildArguments.new()
		arguments.TargetName = "Library"
		arguments.TargetType = BuildTargetType.StaticLibrary
		arguments.LanguageStandard = LanguageStandard.CPP20
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("obj/")
		arguments.BinaryDirectory = Path.new("bin/")
		arguments.ModuleInterfacePartitionSourceFiles = [
			PartitionSourceFile.new(
				Path.new("TestFile1.cpp"),
				[]),
			PartitionSourceFile.new(
				Path.new("TestFile2.cpp"),
				[
					Path.new("TestFile1.cpp"),
				]),
			PartitionSourceFile.new(
				Path.new("TestFile3.cpp"),
				[
					Path.new("TestFile2.cpp"),
				]),
		]
		arguments.ModuleInterfaceSourceFile = Path.new("Public.cpp")
		arguments.SourceFiles = [
			Path.new("TestFile4.cpp"),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		arguments.ModuleDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.bmi"),
			Path.new("../OtherModule2.mock.bmi"),
		]
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]
		arguments.PreprocessorDefinitions = [
			"DEBUG",
			"AWESOME",
		]

		var uut = BuildEngine.new(compiler)
		var buildState = BuildState.new()
		var result = uut.Execute(buildState, arguments)

		// Verify expected logs
		// Assert.ListEqual(
		// 	[
		// 		"INFO: Generate Module Interface Partition Compile Operation: ./TestFile1.cpp",
		// 		"INFO: Generate Module Interface Partition Compile Operation: ./TestFile2.cpp",
		// 		"INFO: Generate Module Interface Partition Compile Operation: ./TestFile3.cpp",
		// 		"INFO: Generate Module Interface Unit Compile: ./Public.cpp",
		// 		"INFO: Generate Compile Operation: ./TestFile4.cpp",
		// 		"INFO: CoreLink",
		// 		"INFO: Linking target",
		// 		"INFO: Generate Link Operation: ./bin/Library.mock.lib",
		// 	],
		// 	testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		expectedCompileArguments.IncludeModules = [
			Path.new("../Other/bin/OtherModule1.mock.bmi"),
			Path.new("../OtherModule2.mock.bmi"),
		]
		expectedCompileArguments.PreprocessorDefinitions = [
			"DEBUG",
			"AWESOME",
		]

		var expectedInterfacePartitionUnit1 = InterfaceUnitCompileArguments.new()
		expectedInterfacePartitionUnit1.SourceFile = Path.new("TestFile1.cpp")
		expectedInterfacePartitionUnit1.TargetFile = Path.new("obj/TestFile1.mock.obj")
		expectedInterfacePartitionUnit1.IncludeModules = []
		expectedInterfacePartitionUnit1.ModuleInterfaceTarget = Path.new("obj/TestFile1.mock.bmi")

		var expectedInterfacePartitionUnit2 = InterfaceUnitCompileArguments.new()
		expectedInterfacePartitionUnit2.SourceFile = Path.new("TestFile2.cpp")
		expectedInterfacePartitionUnit2.TargetFile = Path.new("obj/TestFile2.mock.obj")
		expectedInterfacePartitionUnit2.IncludeModules = [
			Path.new("C:/target/obj/TestFile1.mock.bmi")
		]
		expectedInterfacePartitionUnit2.ModuleInterfaceTarget = Path.new("obj/TestFile2.mock.bmi")

		var expectedInterfacePartitionUnit3 = InterfaceUnitCompileArguments.new()
		expectedInterfacePartitionUnit3.SourceFile = Path.new("TestFile3.cpp")
		expectedInterfacePartitionUnit3.TargetFile = Path.new("obj/TestFile3.mock.obj")
		expectedInterfacePartitionUnit3.IncludeModules = [
			Path.new("C:/target/obj/TestFile2.mock.bmi"),
			Path.new("C:/target/obj/TestFile1.mock.bmi")
		]
		expectedInterfacePartitionUnit3.ModuleInterfaceTarget = Path.new("obj/TestFile3.mock.bmi")

		expectedCompileArguments.InterfacePartitionUnits = [
			expectedInterfacePartitionUnit1,
			expectedInterfacePartitionUnit2,
			expectedInterfacePartitionUnit3
		]

		expectedCompileArguments.InterfaceUnit = InterfaceUnitCompileArguments.new()
		expectedCompileArguments.InterfaceUnit.SourceFile = Path.new("Public.cpp")
		expectedCompileArguments.InterfaceUnit.TargetFile = Path.new("obj/Public.mock.obj")
		expectedCompileArguments.InterfaceUnit.IncludeModules = [
			Path.new("C:/target/obj/TestFile1.mock.bmi"),
			Path.new("C:/target/obj/TestFile2.mock.bmi"),
			Path.new("C:/target/obj/TestFile3.mock.bmi")
		]
		expectedCompileArguments.InterfaceUnit.ModuleInterfaceTarget = Path.new("obj/Public.mock.bmi")

		expectedCompileArguments.ImplementationUnits = [
			TranslationUnitCompileArguments.new(
				Path.new("TestFile4.cpp"),
				Path.new("obj/TestFile4.mock.obj"),
				[])
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/TestFile1.mock.obj"),
			Path.new("obj/TestFile2.mock.obj"),
			Path.new("obj/TestFile3.mock.obj"),
			Path.new("obj/Public.mock.obj"),
			Path.new("obj/TestFile4.mock.obj"),
		]

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./bin/\"",
				[],
				[
					Path.new("bin/"),
				]),
			BuildOperation.new(
				"Copy [./obj/Public.mock.bmi] -> [./bin/Library.mock.bmi]",
				Path.new("C:/target/"),
				Path.new("C:/copy.exe"),
				"\"./obj/Public.mock.bmi\" \"./bin/Library.mock.bmi\"",
				[
					Path.new("obj/Public.mock.bmi"),
				],
				[
					Path.new("bin/Library.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompilePartition: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile1.cpp"),
				],
				[
					Path.new("obj/TestFile1.mock.obj"),
					Path.new("obj/TestFile1.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompilePartition: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile2.cpp"),
				],
				[
					Path.new("obj/TestFile2.mock.obj"),
					Path.new("obj/TestFile2.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompilePartition: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile3.cpp"),
				],
				[
					Path.new("obj/TestFile3.mock.obj"),
					Path.new("obj/TestFile3.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("Public.cpp"),
				],
				[
					Path.new("obj/Public.mock.obj"),
					Path.new("obj/Public.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("TestFile4.cpp"),
				],
				[
					Path.new("obj/TestFile4.mock.obj"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.ListEqual(
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
				Path.new("C:/target/obj/TestFile1.mock.bmi"),
				Path.new("C:/target/obj/TestFile2.mock.bmi"),
				Path.new("C:/target/obj/TestFile3.mock.bmi"),
				Path.new("C:/target/bin/Library.mock.bmi"),
			],
			result.ModuleDependencies)

		Assert.ListEqual(
			[
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
				Path.new("C:/target/bin/Library.mock.lib"),
			],
			result.LinkDependencies)

		Assert.ListEqual(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			Path.new(),
			result.TargetFile)
	}

	Build_Library_ModuleInterfaceNoSource() {
		// Register the mock compiler
		var compiler = MockCompiler.new()

		// Setup the build arguments
		var arguments = BuildArguments.new()
		arguments.TargetName = "Library"
		arguments.TargetType = BuildTargetType.StaticLibrary
		arguments.LanguageStandard = LanguageStandard.CPP20
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("obj/")
		arguments.BinaryDirectory = Path.new("bin/")
		arguments.ModuleInterfaceSourceFile = Path.new("Public.cpp")
		arguments.SourceFiles = []
		arguments.OptimizationLevel = BuildOptimizationLevel.Size
		arguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		arguments.ModuleDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.bmi"),
			Path.new("../OtherModule2.mock.bmi"),
		]
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)
		var buildState = BuildState.new()
		var result = uut.Execute(buildState, arguments)

		// Verify expected logs
		// Assert.ListEqual(
		// 	[
		// 		"INFO: Generate Module Interface Unit Compile: ./Public.cpp",
		// 		"INFO: CoreLink",
		// 		"INFO: Linking target",
		// 		"INFO: Generate Link Operation: ./bin/Library.mock.lib",
		// 	],
		// 	testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.Size
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		expectedCompileArguments.IncludeModules = [
			Path.new("../Other/bin/OtherModule1.mock.bmi"),
			Path.new("../OtherModule2.mock.bmi"),
		]

		var expectedCompileModuleArguments = InterfaceUnitCompileArguments.new()
		expectedCompileModuleArguments.SourceFile = Path.new("Public.cpp")
		expectedCompileModuleArguments.TargetFile = Path.new("obj/Public.mock.obj")
		expectedCompileModuleArguments.IncludeModules = []
		expectedCompileModuleArguments.ModuleInterfaceTarget = Path.new("obj/Public.mock.bmi")

		expectedCompileArguments.InterfaceUnit = expectedCompileModuleArguments

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/Public.mock.obj"),
		]

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("./ProcessFolder/mkdir.exe"),
				"\"./bin/\"",
				[],
				[
					Path.new("bin/"),
				]),
			BuildOperation.new(
				"Copy [./obj/Public.mock.bmi] -> [./bin/Library.mock.bmi]",
				Path.new("C:/target/"),
				Path.new("C:/copy.exe"),
				"\"./obj/Public.mock.bmi\" \"./bin/Library.mock.bmi\"",
				[
					Path.new("obj/Public.mock.bmi"),
				],
				[
					Path.new("bin/Library.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
					Path.new("Public.cpp"),
				],
				[
					Path.new("obj/Public.mock.obj"),
					Path.new("obj/Public.mock.bmi"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.ListEqual(
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
				Path.new("C:/target/bin/Library.mock.bmi"),
			],
			result.ModuleDependencies)

		Assert.ListEqual(
			[
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
				Path.new("C:/target/bin/Library.mock.lib"),
			],
			result.LinkDependencies)

		Assert.ListEqual(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			Path.new(),
			result.TargetFile)
	}
}
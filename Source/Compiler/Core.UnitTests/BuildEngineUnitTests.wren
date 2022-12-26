// <copyright file="BuildEngineUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../../Path" for Path
import "../../BuildOperation" for BuildOperation
import "../../BuildState" for BuildState
import "../../Assert" for Assert
import "../Core/BuildEngine" for BuildEngine
import "../Core/MockCompiler" for MockCompiler
import "../Core/BuildArguments" for BuildArguments, BuildOptimizationLevel, BuildTargetType, PartitionSourceFile, SourceFile
import "../Core/CompileArguments" for InterfaceUnitCompileArguments, LanguageStandard, OptimizationLevel, ResourceCompileArguments, SharedCompileArguments, TranslationUnitCompileArguments
import "../Core/LinkArguments" for LinkArguments, LinkTarget

class BuildEngineUnitTests {
	construct new() {
	}

	RunTests() {
		this.Initialize_Success()
		this.Build_WindowsApplication()
		this.Build_WindowsApplicationWithResource()
		this.Build_Executable()
		this.Build_Library_MultipleFiles()
		this.Build_Library_ModuleInterface()
		this.Build_Library_ModuleInterface_WithPartitions()
		this.Build_Library_ModuleInterface_WithPartitions_TransitiveImport()
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

		// Verify expected process manager requests
		Assert.Equal(
			[
				"GetCurrentProcessFileName",
				"GetCurrentProcessFileName",
			],
			processManager.GetRequests())

		// Verify expected logs
		Assert.Equal(
			[
				"INFO: Generate Compile Operation: ./TestFile.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
			],
			testListener.GetMessages())

		var expectedCompileArguments = SharedCompileArguments.new(
			LanguageStandard.CPP20,
			OptimizationLevel.None,
			Path.new("obj/"),
			Path.new("C:/source/"),
			Path.new("C:/target/"))

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new(
			Path.new("TestFile.cpp"),
			Path.new("obj/TestFile.mock.obj"),
			[])
		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnitArguments,
		]

		var expectedLinkArguments = LinkArguments.new(
			LinkTarget.WindowsApplication,
			Path.new("bin/Program.exe"),
			Path.new("C:/target/"),
			[
				Path.new("obj/TestFile.mock.obj"),
			],
			[
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
			])

		// Verify expected compiler calls
		Assert.Equal([
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.Equal([
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
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

		Assert.Equal(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.Equal(
			[],
			result.ModuleDependencies)

		Assert.Equal(
			[],
			result.LinkDependencies)

		Assert.Equal(
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

		// Verify expected process manager requests
		Assert.Equal(
			[
				"GetCurrentProcessFileName",
				"GetCurrentProcessFileName",
			],
			processManager.GetRequests())

		// Verify expected logs
		Assert.Equal(
			[
				"INFO: Generate Resource File Compile: ./Resources.rc",
				"INFO: Generate Compile Operation: ./TestFile.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
			],
			testListener.GetMessages())

		var expectedCompileArguments = SharedCompileArguments.new(
			LanguageStandard.CPP20,
			OptimizationLevel.None,
			Path.new("obj/"),
			Path.new("C:/source/"),
			Path.new("C:/target/"))

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new(
			Path.new("TestFile.cpp"),
			Path.new("obj/TestFile.mock.obj"),
			[])
		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnitArguments,
		]

		expectedCompileArguments.ResourceFile = ResourceCompileArguments.new(
			SourceFile = Path.new("Resources.rc"),
			Path.new("obj/Resources.mock.res"))

		var expectedLinkArguments = LinkArguments.new(
			LinkTarget.WindowsApplication,
			Path.new("bin/Program.exe"),
			Path.new("C:/target/"),
			[
				Path.new("obj/Resources.mock.res"),
				Path.new("obj/TestFile.mock.obj"),
			],
			[
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
			])

		// Verify expected compiler calls
		Assert.Equal(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.Equal(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
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

		Assert.Equal(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.Equal(
			[],
			result.ModuleDependencies)

		Assert.Equal(
			[],
			result.LinkDependencies)

		Assert.Equal(
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

		// Verify expected process manager requests
		Assert.Equal(
			[
				"GetCurrentProcessFileName",
				"GetCurrentProcessFileName",
			],
			processManager.GetRequests())

		// Verify expected logs
		Assert.Equal(
			[
				"INFO: Generate Compile Operation: ./TestFile.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
			],
			testListener.GetMessages())

		var expectedCompileArguments = SharedCompileArguments.new(
			LanguageStandard.CPP20,
			OptimizationLevel.None,
			Path.new("obj/"),
			Path.new("C:/source/"),
			Path.new("C:/target/"))

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new(
			Path.new("TestFile.cpp"),
			Path.new("obj/TestFile.mock.obj"),
			[])
		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnitArguments,
		]

		var expectedLinkArguments = LinkArguments.new(
			LinkTarget.Executable,
			Path.new("bin/Program.exe"),
			Path.new("C:/target/"),
			[
				Path.new("obj/TestFile.mock.obj"),
			],
			[
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
			])

		// Verify expected compiler calls
		Assert.Equal(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.Equal(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
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

		Assert.Equal(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.Equal(
			[],
			result.ModuleDependencies)

		Assert.Equal(
			[],
			result.LinkDependencies)

		Assert.Equal(
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

		// Verify expected process manager requests
		Assert.Equal(
			[
				"GetCurrentProcessFileName",
				"GetCurrentProcessFileName",
			],
			processManager.GetRequests())

		// Verify expected logs
		Assert.Equal(
			[
				"INFO: Generate Compile Operation: ./TestFile1.cpp",
				"INFO: Generate Compile Operation: ./TestFile2.cpp",
				"INFO: Generate Compile Operation: ./TestFile3.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
			],
			testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new(
			LanguageStandard.CPP20,
			OptimizationLevel.Size,
			Path.new("C:/source/"),
			Path.new("C:/target/"),
			Path.new("obj/"),
			[
				Path.new("Folder"),
				Path.new("AnotherFolder/Sub"),
			],
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
			])

		var expectedTranslationUnit1Arguments = TranslationUnitCompileArguments.new(
			Path.new("TestFile1.cpp"),
			Path.new("obj/TestFile1.mock.obj"),
			[])

		var expectedTranslationUnit2Arguments = TranslationUnitCompileArguments.new(
			Path.new("TestFile2.cpp"),
			Path.new("obj/TestFile2.mock.obj"),
			[])

		var expectedTranslationUnit3Arguments = TranslationUnitCompileArguments.new(
			Path.new("TestFile3.cpp"),
			Path.new("obj/TestFile3.mock.obj"),
			[])

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnit1Arguments,
			expectedTranslationUnit2Arguments,
			expectedTranslationUnit3Arguments,
		]

		var expectedLinkArguments = LinkArguments.new(
			Path.new("bin/Library.mock.lib"),
			LinkTarget.StaticLibrary,
			Path.new("C:/target/"),
			[
				Path.new("obj/TestFile1.mock.obj"),
				Path.new("obj/TestFile2.mock.obj"),
				Path.new("obj/TestFile3.mock.obj"),
			])

		// Note: There is no need to send along the static libraries for a static library linking
		expectedLinkArguments.LibraryFiles = []

		// Verify expected compiler calls
		Assert.Equal(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.Equal(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
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

		Assert.Equal(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.Equal(
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
			],
			result.ModuleDependencies)

		Assert.Equal(
			[
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
				Path.new("C:/target/bin/Library.mock.lib"),
			],
			result.LinkDependencies)

		Assert.Equal(
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

		// Verify expected process manager requests
		Assert.Equal(
			[
				"GetCurrentProcessFileName",
				"GetCurrentProcessFileName",
				"GetCurrentProcessFileName",
			],
			processManager.GetRequests())

		// Verify expected logs
		Assert.Equal(
			[
				"INFO: Generate Module Interface Unit Compile: ./Public.cpp",
				"INFO: Generate Compile Operation: ./TestFile1.cpp",
				"INFO: Generate Compile Operation: ./TestFile2.cpp",
				"INFO: Generate Compile Operation: ./TestFile3.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
			],
			testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new(
			LanguageStandard.CPP20,
			OptimizationLevel.None,
			Path.new("C:/source/"),
			Path.new("C:/target/"),
			Path.new("obj/"),
			[
				Path.new("Folder"),
				Path.new("AnotherFolder/Sub"),
			],
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
			],
			[
				"DEBUG",
				"AWESOME",
			])

		var expectedCompileModuleArguments = InterfaceUnitCompileArguments.new(
			Path.new("Public.cpp"),
			Path.new("obj/Public.mock.obj"),
			[],
			Path.new("obj/Public.mock.bmi"))
		expectedCompileArguments.InterfaceUnit = expectedCompileModuleArguments

		var expectedTranslationUnit1Arguments = TranslationUnitCompileArguments.new(
			Path.new("TestFile1.cpp"),
			Path.new("obj/TestFile1.mock.obj"),
			[])

		var expectedTranslationUnit2Arguments = TranslationUnitCompileArguments.new(
			Path.new("TestFile2.cpp"),
			Path.new("obj/TestFile2.mock.obj"),
			[])

		var expectedTranslationUnit3Arguments = TranslationUnitCompileArguments.new(
			Path.new("TestFile3.cpp"),
			Path.new("obj/TestFile3.mock.obj"),
			[])

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnit1Arguments,
			expectedTranslationUnit2Arguments,
			expectedTranslationUnit3Arguments,
		]

		var expectedLinkArguments = LinkArguments.new(
			Path.new("bin/Library.mock.lib"),
			LinkTarget.StaticLibrary,
			Path.new("C:/target/"),
			[
				Path.new("obj/Public.mock.obj"),
				Path.new("obj/TestFile1.mock.obj"),
				Path.new("obj/TestFile2.mock.obj"),
				Path.new("obj/TestFile3.mock.obj"),
			],
			[])

		// Verify expected compiler calls
		Assert.Equal(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.Equal(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
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

		Assert.Equal(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.Equal(
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
				Path.new("C:/target/bin/Library.mock.bmi"),
			],
			result.ModuleDependencies)

		Assert.Equal(
			[
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
				Path.new("C:/target/bin/Library.mock.lib"),
			],
			result.LinkDependencies)

		Assert.Equal(
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

		// Verify expected process manager requests
		Assert.Equal(
			[
				"GetCurrentProcessFileName",
				"GetCurrentProcessFileName",
				"GetCurrentProcessFileName",
			],
			processManager.GetRequests())

		// Verify expected logs
		Assert.Equal(
			[
				"INFO: Generate Module Interface Partition Compile Operation: ./TestFile1.cpp",
				"INFO: Generate Module Interface Partition Compile Operation: ./TestFile2.cpp",
				"INFO: Generate Module Interface Unit Compile: ./Public.cpp",
				"INFO: Generate Compile Operation: ./TestFile3.cpp",
				"INFO: Generate Compile Operation: ./TestFile4.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
			],
			testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new(
			LanguageStandard.CPP20,
			OptimizationLevel.None,
			Path.new("C:/source/"),
			Path.new("C:/target/"),
			Path.new("obj/"),
			[
				Path.new("Folder"),
				Path.new("AnotherFolder/Sub"),
			],
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
			],
			[
				"DEBUG",
				"AWESOME",
			],
			[
				InterfaceUnitCompileArguments.new(
					Path.new("TestFile1.cpp"),
					Path.new("obj/TestFile1.mock.obj"),
					[],
					Path.new("obj/TestFile1.mock.bmi")),
				InterfaceUnitCompileArguments.new(
					Path.new("TestFile2.cpp"),
					Path.new("obj/TestFile2.mock.obj"),
					[
						Path.new("C:/target/obj/TestFile1.mock.bmi")
					],
					Path.new("obj/TestFile2.mock.bmi")),
			],
			InterfaceUnitCompileArguments.new(
				Path.new("Public.cpp"),
				Path.new("obj/Public.mock.obj"),
				[
					Path.new("C:/target/obj/TestFile1.mock.bmi"),
					Path.new("C:/target/obj/TestFile2.mock.bmi"),
				],
				Path.new("obj/Public.mock.bmi")),
			[
				TranslationUnitCompileArguments.new(
					Path.new("TestFile3.cpp"),
					Path.new("obj/TestFile3.mock.obj"),
					[]),
				TranslationUnitCompileArguments.new(
					Path.new("TestFile4.cpp"),
					Path.new("obj/TestFile4.mock.obj"),
					[]),
			])

		var expectedLinkArguments = LinkArguments.new(
			Path.new("bin/Library.mock.lib"),
			LinkTarget.StaticLibrary,
			Path.new("C:/target/"),
			[
				Path.new("obj/TestFile1.mock.obj"),
				Path.new("obj/TestFile2.mock.obj"),
				Path.new("obj/Public.mock.obj"),
				Path.new("obj/TestFile3.mock.obj"),
				Path.new("obj/TestFile4.mock.obj"),
			],
			[])

		// Verify expected compiler calls
		Assert.Equal(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.Equal(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
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

		Assert.Equal(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.Equal(
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
				Path.new("C:/target/obj/TestFile1.mock.bmi"),
				Path.new("C:/target/obj/TestFile2.mock.bmi"),
				Path.new("C:/target/bin/Library.mock.bmi"),
			],
			result.ModuleDependencies)

		Assert.Equal(
			[
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
				Path.new("C:/target/bin/Library.mock.lib"),
			],
			result.LinkDependencies)

		Assert.Equal(
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

		// Verify expected process manager requests
		Assert.Equal(
			[
				"GetCurrentProcessFileName",
				"GetCurrentProcessFileName",
				"GetCurrentProcessFileName",
			],
			processManager.GetRequests())

		// Verify expected logs
		Assert.Equal(
			[
				"INFO: Generate Module Interface Partition Compile Operation: ./TestFile1.cpp",
				"INFO: Generate Module Interface Partition Compile Operation: ./TestFile2.cpp",
				"INFO: Generate Module Interface Partition Compile Operation: ./TestFile3.cpp",
				"INFO: Generate Module Interface Unit Compile: ./Public.cpp",
				"INFO: Generate Compile Operation: ./TestFile4.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
			],
			testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new(
			LanguageStandard.CPP20,
			OptimizationLevel.None,
			Path.new("C:/source/"),
			Path.new("C:/target/"),
			Path.new("obj/"),
			[
				Path.new("Folder"),
				Path.new("AnotherFolder/Sub"),
			],
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
			],
			[
				"DEBUG",
				"AWESOME",
			],
			[
				InterfaceUnitCompileArguments.new(
					Path.new("TestFile1.cpp"),
					Path.new("obj/TestFile1.mock.obj"),
					[],
					Path.new("obj/TestFile1.mock.bmi")),
				InterfaceUnitCompileArguments.new(
					Path.new("TestFile2.cpp"),
					Path.new("obj/TestFile2.mock.obj"),
					[
						Path.new("C:/target/obj/TestFile1.mock.bmi"),
					],
					Path.new("obj/TestFile2.mock.bmi")),
				InterfaceUnitCompileArguments.new(
					Path.new("TestFile3.cpp"),
					Path.new("obj/TestFile3.mock.obj"),
					[
						Path.new("C:/target/obj/TestFile2.mock.bmi"),
						Path.new("C:/target/obj/TestFile1.mock.bmi"),
					],
					Path.new("obj/TestFile3.mock.bmi")),
			],
			InterfaceUnitCompileArguments.new(
				Path.new("Public.cpp"),
				Path.new("obj/Public.mock.obj"),
				[
					Path.new("C:/target/obj/TestFile1.mock.bmi"),
					Path.new("C:/target/obj/TestFile2.mock.bmi"),
					Path.new("C:/target/obj/TestFile3.mock.bmi"),
				],
				Path.new("obj/Public.mock.bmi")),
			[
				TranslationUnitCompileArguments.new(
					Path.new("TestFile4.cpp"),
					Path.new("obj/TestFile4.mock.obj"),
					[])
			])

		var expectedLinkArguments = LinkArguments.new(
			Path.new("bin/Library.mock.lib"),
			LinkTarget.StaticLibrary,
			Path.new("C:/target/"),
			[
				Path.new("obj/TestFile1.mock.obj"),
				Path.new("obj/TestFile2.mock.obj"),
				Path.new("obj/TestFile3.mock.obj"),
				Path.new("obj/Public.mock.obj"),
				Path.new("obj/TestFile4.mock.obj"),
			],
			[])

		// Verify expected compiler calls
		Assert.Equal(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.Equal(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
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

		Assert.Equal(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.Equal(
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
				Path.new("C:/target/obj/TestFile1.mock.bmi"),
				Path.new("C:/target/obj/TestFile2.mock.bmi"),
				Path.new("C:/target/obj/TestFile3.mock.bmi"),
				Path.new("C:/target/bin/Library.mock.bmi"),
			],
			result.ModuleDependencies)

		Assert.Equal(
			[
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
				Path.new("C:/target/bin/Library.mock.lib"),
			],
			result.LinkDependencies)

		Assert.Equal(
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

		// Verify expected process manager requests
		Assert.Equal(
			[
				"GetCurrentProcessFileName",
				"GetCurrentProcessFileName",
				"GetCurrentProcessFileName",
			],
			processManager.GetRequests())

		// Verify expected logs
		Assert.Equal(
			[
				"INFO: Generate Module Interface Unit Compile: ./Public.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
			],
			testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new(
			LanguageStandard.CPP20,
			OptimizationLevel.Size,
			Path.new("C:/source/"),
			Path.new("C:/target/"),
			Path.new("obj/"),
			[
				Path.new("Folder"),
				Path.new("AnotherFolder/Sub"),
			],
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
			])

		var expectedCompileModuleArguments = InterfaceUnitCompileArguments.new(
			Path.new("Public.cpp"),
			Path.new("obj/Public.mock.obj"),
			[],
			Path.new("obj/Public.mock.bmi"))
		expectedCompileArguments.InterfaceUnit = expectedCompileModuleArguments

		var expectedLinkArguments = LinkArguments.new(
			Path.new("bin/Library.mock.lib"),
			LinkTarget.StaticLibrary,
			Path.new("C:/target/"),
			[
				Path.new("obj/Public.mock.obj"),
			],
			[])

		// Verify expected compiler calls
		Assert.Equal(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.Equal(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[],
				[
					Path.new("obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
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

		Assert.Equal(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.Equal(
			[
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
				Path.new("C:/target/bin/Library.mock.bmi"),
			],
			result.ModuleDependencies)

		Assert.Equal(
			[
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
				Path.new("C:/target/bin/Library.mock.lib"),
			],
			result.LinkDependencies)

		Assert.Equal(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			Path.new(),
			result.TargetFile)
	}
}
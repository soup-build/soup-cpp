// <copyright file="BuildEngineUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup-test" for SoupTest
import "Soup|Build.Utils:./Path" for Path
import "Soup|Build.Utils:./BuildOperation" for BuildOperation
import "../../test/Assert" for Assert
import "../core/BuildEngine" for BuildEngine
import "../core/MockCompiler" for MockCompiler
import "../core/BuildArguments" for BuildArguments, BuildOptimizationLevel, BuildTargetType, SourceFile, HeaderFileSet
import "../core/CompileArguments" for ModuleUnitCompileArguments, LanguageStandard, OptimizationLevel, ResourceCompileArguments, SharedCompileArguments, TranslationUnitCompileArguments
import "../core/LinkArguments" for LinkArguments, LinkTarget

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
		System.print("BuildEngineUnitTests.Build_Library_PublicHeaderFiles")
		this.Build_Library_PublicHeaderFiles()
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
		SoupTest.initialize()

		var compiler = MockCompiler.new()
		var uut = BuildEngine.new(compiler)
	}

	Build_WindowsApplication() {
		// Setup the input build state
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mwasplund|mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

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
			SourceFile.new(Path.new("TestFile.cpp"), null, null, []),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)

		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Compile Operation: ./TestFile.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
			],
			SoupTest.logs)

		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.cpp")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.TranslationUnits = [
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
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
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
				[
					"Arguments",
				],
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

		Assert.MapEqual(
			{},
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
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mwasplund|mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

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
			SourceFile.new(Path.new("TestFile.cpp"), null, null, []),
		]
		arguments.ResourceFile = Path.new("Resources.rc")
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)
		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Resource File Compile: ./Resources.rc",
				"INFO: Generate Compile Operation: ./TestFile.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
			],
			SoupTest.logs)

		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.cpp")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.TranslationUnits = [
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
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
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
				[
					"Arguments",
				],
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

		Assert.MapEqual(
			{},
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
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mwasplund|mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

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
			SourceFile.new(Path.new("TestFile.cpp"), null, null, []),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)
		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Compile Operation: ./TestFile.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
			],
			SoupTest.logs)

		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.cpp")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.TranslationUnits = [
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
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
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
				[
					"Arguments",
				],
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

		Assert.MapEqual(
			{},
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

	Build_Library_PublicHeaderFiles() {
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mwasplund|copy": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/copy.exe"
					}
				}
			},
			"mwasplund|mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

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
			SourceFile.new(Path.new("TestFile1.cpp"), null, null, []),
		]
		arguments.PublicHeaderSets = [
			HeaderFileSet.new(
				Path.new("./"),
				null,
				[
					Path.new("TestFile1.h"),
					Path.new("TestFile2.h"),
				]),
			HeaderFileSet.new(
				Path.new("SubFolder/"),
				Path.new("TargetFolder/"),
				[
					Path.new("TestFile3.h"),
				]),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.Size
		arguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		arguments.ModuleDependencies = {
			"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
			"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
		}
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)
		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Compile Operation: ./TestFile1.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
				"INFO: Setup Public Headers",
				"INFO: Copy Header Set: ./",
				"INFO: Generate Copy Header: ./TestFile1.h",
				"INFO: Generate Copy Header: ./TestFile2.h",
				"INFO: Copy Header Set: ./SubFolder/",
				"INFO: Generate Copy Header: ./TestFile3.h",
			],
			SoupTest.logs)

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
		expectedCompileArguments.IncludeModules = {
			"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
			"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
		}

		var expectedTranslationUnit1Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit1Arguments.SourceFile = Path.new("TestFile1.cpp")
		expectedTranslationUnit1Arguments.TargetFile = Path.new("obj/TestFile1.mock.obj")

		expectedCompileArguments.TranslationUnits = [
			expectedTranslationUnit1Arguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/TestFile1.mock.obj"),
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
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("TestFile1.cpp"),
				],
				[
					Path.new("obj/TestFile1.mock.obj"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
			BuildOperation.new(
				"Copy [C:/source/TestFile1.h] -> [./include/TestFile1.h]",
				Path.new("C:/target/"),
				Path.new("/TARGET/copy.exe"),
				[
					"C:/source/TestFile1.h",
					"./include/TestFile1.h",
				],
				[
					Path.new("C:/source/TestFile1.h"),
				],
				[
					Path.new("include/TestFile1.h"),
				]),
			BuildOperation.new(
				"Copy [C:/source/TestFile2.h] -> [./include/TestFile2.h]",
				Path.new("C:/target/"),
				Path.new("/TARGET/copy.exe"),
				[
					"C:/source/TestFile2.h",
					"./include/TestFile2.h",
				],
				[
					Path.new("C:/source/TestFile2.h"),
				],
				[
					Path.new("include/TestFile2.h"),
				]),
			BuildOperation.new(
				"Copy [C:/source/SubFolder/TestFile3.h] -> [./include/TargetFolder/TestFile3.h]",
				Path.new("C:/target/"),
				Path.new("/TARGET/copy.exe"),
				[
					"C:/source/SubFolder/TestFile3.h",
					"./include/TargetFolder/TestFile3.h",
				],
				[
					Path.new("C:/source/SubFolder/TestFile3.h"),
				],
				[
					Path.new("include/TargetFolder/TestFile3.h"),
				]),
			BuildOperation.new(
				"MakeDir [./include/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./include/",
				],
				[],
				[
					Path.new("./include/"),
				]),
			BuildOperation.new(
				"MakeDir [./include/TargetFolder/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./include/TargetFolder/",
				],
				[],
				[
					Path.new("./include/TargetFolder/"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			result.BuildOperations)

		Assert.MapEqual(
			{
				"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
				"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
			},
			result.ModuleDependencies)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Library.mock.lib"),
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
			],
			result.LinkDependencies)

		Assert.ListEqual(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			null,
			result.TargetFile)
	}

	Build_Library_MultipleFiles() {
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mwasplund|mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

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
			SourceFile.new(Path.new("TestFile1.cpp"), null, null, []),
			SourceFile.new(Path.new("TestFile2.cpp"), null, null, []),
			SourceFile.new(Path.new("TestFile3.cpp"), null, null, []),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.Size
		arguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		arguments.ModuleDependencies = {
			"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
			"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
		}
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)
		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Compile Operation: ./TestFile1.cpp",
				"INFO: Generate Compile Operation: ./TestFile2.cpp",
				"INFO: Generate Compile Operation: ./TestFile3.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
			],
			SoupTest.logs)

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
		expectedCompileArguments.IncludeModules = {
			"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
			"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
		}

		var expectedTranslationUnit1Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit1Arguments.SourceFile = Path.new("TestFile1.cpp")
		expectedTranslationUnit1Arguments.TargetFile = Path.new("obj/TestFile1.mock.obj")

		var expectedTranslationUnit2Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit2Arguments.SourceFile = Path.new("TestFile2.cpp")
		expectedTranslationUnit2Arguments.TargetFile = Path.new("obj/TestFile2.mock.obj")

		var expectedTranslationUnit3Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit3Arguments.SourceFile = Path.new("TestFile3.cpp")
		expectedTranslationUnit3Arguments.TargetFile = Path.new("obj/TestFile3.mock.obj")

		expectedCompileArguments.TranslationUnits = [
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
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("./obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("./bin/"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
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
				[
					"Arguments",
				],
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
				[
					"Arguments",
				],
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
				[
					"Arguments",
				],
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

		Assert.MapEqual(
			{
				"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
				"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
			},
			result.ModuleDependencies)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Library.mock.lib"),
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
			],
			result.LinkDependencies)

		Assert.ListEqual(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			null,
			result.TargetFile)
	}

	Build_Library_ModuleInterface() {
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mwasplund|copy": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/copy.exe"
					}
				}
			},
			"mwasplund|mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

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
			SourceFile.new(Path.new("Public.cpp"), "Library", null, []),
			SourceFile.new(Path.new("TestFile1.cpp"), null, null, []),
			SourceFile.new(Path.new("TestFile2.cpp"), null, null, []),
			SourceFile.new(Path.new("TestFile3.cpp"), null, null, []),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		arguments.ModuleDependencies = {
			"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
			"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
		}
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]
		arguments.PreprocessorDefinitions = [
			"DEBUG",
			"AWESOME",
		]

		var uut = BuildEngine.new(compiler)
		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Compile Module Operation: ./Public.cpp",
				"INFO: Generate Compile Operation: ./TestFile1.cpp",
				"INFO: Generate Compile Operation: ./TestFile2.cpp",
				"INFO: Generate Compile Operation: ./TestFile3.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
			],
			SoupTest.logs)

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
		expectedCompileArguments.IncludeModules = {
			"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
			"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
		}
		expectedCompileArguments.PreprocessorDefinitions = [
			"DEBUG",
			"AWESOME",
		]

		var expectedCompileModuleArguments = ModuleUnitCompileArguments.new()
		expectedCompileModuleArguments.ModuleName = "Library"
		expectedCompileModuleArguments.SourceFile = Path.new("Public.cpp")
		expectedCompileModuleArguments.TargetFile = Path.new("obj/Public.mock.obj")
		expectedCompileModuleArguments.IncludeModules = {}
		expectedCompileModuleArguments.ModuleInterfaceTarget = Path.new("bin/Library.mock.bmi")

		expectedCompileArguments.ModuleUnits = [
			expectedCompileModuleArguments,
		]

		var expectedTranslationUnit1Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit1Arguments.SourceFile = Path.new("TestFile1.cpp")
		expectedTranslationUnit1Arguments.TargetFile = Path.new("obj/TestFile1.mock.obj")

		var expectedTranslationUnit2Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit2Arguments.SourceFile = Path.new("TestFile2.cpp")
		expectedTranslationUnit2Arguments.TargetFile = Path.new("obj/TestFile2.mock.obj")

		var expectedTranslationUnit3Arguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnit3Arguments.SourceFile = Path.new("TestFile3.cpp")
		expectedTranslationUnit3Arguments.TargetFile = Path.new("obj/TestFile3.mock.obj")

		expectedCompileArguments.TranslationUnits = [
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
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("bin/"),
				]),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("Public.cpp"),
				],
				[
					Path.new("obj/Public.mock.obj"),
					Path.new("bin/Library.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
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
				[
					"Arguments",
				],
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
				[
					"Arguments",
				],
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
				[
					"Arguments",
				],
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

		Assert.MapEqual(
			{
				"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
				"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
				"Library": Path.new("C:/target/bin/Library.mock.bmi"),
			},
			result.ModuleDependencies)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Library.mock.lib"),
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
			],
			result.LinkDependencies)

		Assert.ListEqual(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			null,
			result.TargetFile)
	}

	Build_Library_ModuleInterface_WithPartitions() {
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mwasplund|copy": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/copy.exe"
					}
				}
			},
			"mwasplund|mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

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
			SourceFile.new(
				Path.new("Public.cpp"),
				"Library",
				null,
				[
					":TestFile1",
					":TestFile2",
				]),
			SourceFile.new(
				Path.new("TestFile1.cpp"),
				"Library",
				"TestFile1",
				[]),
			SourceFile.new(
				Path.new("TestFile2.cpp"),
				"Library",
				"TestFile2",
				[
					":TestFile1",
				]),
			SourceFile.new(Path.new("TestFile3.cpp"), null, null, []),
			SourceFile.new(Path.new("TestFile4.cpp"), null, null, []),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		arguments.ModuleDependencies = {
			"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
			"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
		}
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]
		arguments.PreprocessorDefinitions = [
			"DEBUG",
			"AWESOME",
		]

		var uut = BuildEngine.new(compiler)
		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Compile Module Operation: ./Public.cpp",
				"INFO: Generate Compile Module Operation: ./TestFile1.cpp",
				"INFO: Generate Compile Module Operation: ./TestFile2.cpp",
				"INFO: Generate Compile Operation: ./TestFile3.cpp",
				"INFO: Generate Compile Operation: ./TestFile4.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
			],
			SoupTest.logs)

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
		expectedCompileArguments.IncludeModules = {
			"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
			"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
		}
		expectedCompileArguments.PreprocessorDefinitions = [
			"DEBUG",
			"AWESOME",
		]

		var expectedInterfaceUnitArguments = ModuleUnitCompileArguments.new()
		expectedInterfaceUnitArguments.ModuleName = "Library"
		expectedInterfaceUnitArguments.SourceFile = Path.new("Public.cpp")
		expectedInterfaceUnitArguments.TargetFile = Path.new("obj/Public.mock.obj")
		expectedInterfaceUnitArguments.IncludeModules = {
			"Library:TestFile1": Path.new("C:/target/obj/Library-TestFile1.mock.bmi"),
			"Library:TestFile2": Path.new("C:/target/obj/Library-TestFile2.mock.bmi"),
		}
		expectedInterfaceUnitArguments.ModuleInterfaceTarget = Path.new("bin/Library.mock.bmi")

		var expectedInterfacePartitionUnit1Arguments = ModuleUnitCompileArguments.new()
		expectedInterfacePartitionUnit1Arguments.ModuleName = "Library:TestFile1"
		expectedInterfacePartitionUnit1Arguments.SourceFile = Path.new("TestFile1.cpp")
		expectedInterfacePartitionUnit1Arguments.TargetFile = Path.new("obj/TestFile1.mock.obj")
		expectedInterfacePartitionUnit1Arguments.ModuleInterfaceTarget = Path.new("obj/Library-TestFile1.mock.bmi")

		var expectedInterfacePartitionUnit2Arguments = ModuleUnitCompileArguments.new()
		expectedInterfacePartitionUnit2Arguments.ModuleName = "Library:TestFile2"
		expectedInterfacePartitionUnit2Arguments.SourceFile = Path.new("TestFile2.cpp")
		expectedInterfacePartitionUnit2Arguments.TargetFile = Path.new("obj/TestFile2.mock.obj")
		expectedInterfacePartitionUnit2Arguments.IncludeModules = {
			"Library:TestFile1": Path.new("C:/target/obj/Library-TestFile1.mock.bmi"),
		}
		expectedInterfacePartitionUnit2Arguments.ModuleInterfaceTarget = Path.new("obj/Library-TestFile2.mock.bmi")

		expectedCompileArguments.ModuleUnits = [
			expectedInterfaceUnitArguments,
			expectedInterfacePartitionUnit1Arguments,
			expectedInterfacePartitionUnit2Arguments
		]

		expectedCompileArguments.TranslationUnits = [
			TranslationUnitCompileArguments.new(
				Path.new("TestFile3.cpp"),
				Path.new("obj/TestFile3.mock.obj"),
				{}),
			TranslationUnitCompileArguments.new(
				Path.new("TestFile4.cpp"),
				Path.new("obj/TestFile4.mock.obj"),
				{}),
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
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("bin/"),
				]),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("Public.cpp"),
				],
				[
					Path.new("obj/Public.mock.obj"),
					Path.new("bin/Library.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("TestFile1.cpp"),
				],
				[
					Path.new("obj/TestFile1.mock.obj"),
					Path.new("obj/Library-TestFile1.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("TestFile2.cpp"),
				],
				[
					Path.new("obj/TestFile2.mock.obj"),
					Path.new("obj/Library-TestFile2.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
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
				[
					"Arguments",
				],
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
				[
					"Arguments",
				],
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

		Assert.MapEqual(
			{
				"Library": Path.new("C:/target/bin/Library.mock.bmi"),
				"Library:TestFile1": Path.new("C:/target/obj/Library-TestFile1.mock.bmi"),
				"Library:TestFile2": Path.new("C:/target/obj/Library-TestFile2.mock.bmi"),
				"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
				"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
			},
			result.ModuleDependencies)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Library.mock.lib"),
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
			],
			result.LinkDependencies)

		Assert.ListEqual(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			null,
			result.TargetFile)
	}

	Build_Library_ModuleInterface_WithPartitions_TransitiveImport() {
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mwasplund|copy": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/copy.exe"
					}
				}
			},
			"mwasplund|mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

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
			SourceFile.new(
				Path.new("Public.cpp"),
				"Library",
				null,
				[
					":TestFile1",
					":TestFile2",
					":TestFile3",
				]),
			SourceFile.new(
				Path.new("TestFile1.cpp"),
				"Library",
				"TestFile1",
				[]),
			SourceFile.new(
				Path.new("TestFile2.cpp"),
				"Library",
				"TestFile2",
				[
					":TestFile1",
				]),
			SourceFile.new(
				Path.new("TestFile3.cpp"),
				"Library",
				"TestFile3",
				[
					":TestFile2",
				]),
			SourceFile.new(Path.new("TestFile4.cpp"), null, null, []),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.None
		arguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		arguments.ModuleDependencies = {
			"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
			"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
		}
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]
		arguments.PreprocessorDefinitions = [
			"DEBUG",
			"AWESOME",
		]

		var uut = BuildEngine.new(compiler)
		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Compile Module Operation: ./Public.cpp",
				"INFO: Generate Compile Module Operation: ./TestFile1.cpp",
				"INFO: Generate Compile Module Operation: ./TestFile2.cpp",
				"INFO: Generate Compile Module Operation: ./TestFile3.cpp",
				"INFO: Generate Compile Operation: ./TestFile4.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
			],
			SoupTest.logs)

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
		expectedCompileArguments.IncludeModules = {
			"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
			"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
		}
		expectedCompileArguments.PreprocessorDefinitions = [
			"DEBUG",
			"AWESOME",
		]

		var expectedInterfaceUnit = ModuleUnitCompileArguments.new()
		expectedInterfaceUnit.ModuleName = "Library"
		expectedInterfaceUnit.SourceFile = Path.new("Public.cpp")
		expectedInterfaceUnit.TargetFile = Path.new("obj/Public.mock.obj")
		expectedInterfaceUnit.IncludeModules = {
			"Library:TestFile1": Path.new("C:/target/obj/Library-TestFile1.mock.bmi"),
			"Library:TestFile2": Path.new("C:/target/obj/Library-TestFile2.mock.bmi"),
			"Library:TestFile3": Path.new("C:/target/obj/Library-TestFile3.mock.bmi")
		}
		expectedInterfaceUnit.ModuleInterfaceTarget = Path.new("bin/Library.mock.bmi")

		var expectedInterfacePartitionUnit1 = ModuleUnitCompileArguments.new()
		expectedInterfacePartitionUnit1.ModuleName = "Library:TestFile1"
		expectedInterfacePartitionUnit1.SourceFile = Path.new("TestFile1.cpp")
		expectedInterfacePartitionUnit1.TargetFile = Path.new("obj/TestFile1.mock.obj")
		expectedInterfacePartitionUnit1.IncludeModules = {}
		expectedInterfacePartitionUnit1.ModuleInterfaceTarget = Path.new("obj/Library-TestFile1.mock.bmi")

		var expectedInterfacePartitionUnit2 = ModuleUnitCompileArguments.new()
		expectedInterfacePartitionUnit2.ModuleName = "Library:TestFile2"
		expectedInterfacePartitionUnit2.SourceFile = Path.new("TestFile2.cpp")
		expectedInterfacePartitionUnit2.TargetFile = Path.new("obj/TestFile2.mock.obj")
		expectedInterfacePartitionUnit2.IncludeModules = {
			"Library:TestFile1": Path.new("C:/target/obj/Library-TestFile1.mock.bmi")
		}
		expectedInterfacePartitionUnit2.ModuleInterfaceTarget = Path.new("obj/Library-TestFile2.mock.bmi")

		var expectedInterfacePartitionUnit3 = ModuleUnitCompileArguments.new()
		expectedInterfacePartitionUnit3.ModuleName = "Library:TestFile3"
		expectedInterfacePartitionUnit3.SourceFile = Path.new("TestFile3.cpp")
		expectedInterfacePartitionUnit3.TargetFile = Path.new("obj/TestFile3.mock.obj")
		expectedInterfacePartitionUnit3.IncludeModules = {
			"Library:TestFile2": Path.new("C:/target/obj/Library-TestFile2.mock.bmi"),
			"Library:TestFile1": Path.new("C:/target/obj/Library-TestFile1.mock.bmi")
		}
		expectedInterfacePartitionUnit3.ModuleInterfaceTarget = Path.new("obj/Library-TestFile3.mock.bmi")

		expectedCompileArguments.ModuleUnits = [
			expectedInterfaceUnit,
			expectedInterfacePartitionUnit1,
			expectedInterfacePartitionUnit2,
			expectedInterfacePartitionUnit3
		]

		expectedCompileArguments.TranslationUnits = [
			TranslationUnitCompileArguments.new(
				Path.new("TestFile4.cpp"),
				Path.new("obj/TestFile4.mock.obj"),
				{})
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
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("bin/"),
				]),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("Public.cpp"),
				],
				[
					Path.new("obj/Public.mock.obj"),
					Path.new("bin/Library.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("TestFile1.cpp"),
				],
				[
					Path.new("obj/TestFile1.mock.obj"),
					Path.new("obj/Library-TestFile1.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("TestFile2.cpp"),
				],
				[
					Path.new("obj/TestFile2.mock.obj"),
					Path.new("obj/Library-TestFile2.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("TestFile3.cpp"),
				],
				[
					Path.new("obj/TestFile3.mock.obj"),
					Path.new("obj/Library-TestFile3.mock.bmi"),
				]),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
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
				[
					"Arguments",
				],
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

		Assert.MapEqual(
			{
				"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
				"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
				"Library:TestFile1": Path.new("C:/target/obj/Library-TestFile1.mock.bmi"),
				"Library:TestFile2": Path.new("C:/target/obj/Library-TestFile2.mock.bmi"),
				"Library:TestFile3": Path.new("C:/target/obj/Library-TestFile3.mock.bmi"),
				"Library": Path.new("C:/target/bin/Library.mock.bmi"),
			},
			result.ModuleDependencies)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Library.mock.lib"),
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
			],
			result.LinkDependencies)

		Assert.ListEqual(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			null,
			result.TargetFile)
	}

	Build_Library_ModuleInterfaceNoSource() {
		SoupTest.initialize()
		var globalState = SoupTest.globalState

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mwasplund|copy": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/copy.exe"
					}
				}
			},
			"mwasplund|mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

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
			SourceFile.new(Path.new("Public.cpp"), "Library", null, []),
		]
		arguments.OptimizationLevel = BuildOptimizationLevel.Size
		arguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		arguments.ModuleDependencies = {
			"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
			"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
		}
		arguments.LinkDependencies = [
			Path.new("../Other/bin/OtherModule1.mock.a"),
			Path.new("../OtherModule2.mock.a"),
		]

		var uut = BuildEngine.new(compiler)
		var result = uut.Execute(arguments)

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Generate Compile Module Operation: ./Public.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
			],
			SoupTest.logs)

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
		expectedCompileArguments.IncludeModules = {
			"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
			"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
		}

		var expectedCompileModuleArguments = ModuleUnitCompileArguments.new()
		expectedCompileModuleArguments.ModuleName = "Library"
		expectedCompileModuleArguments.SourceFile = Path.new("Public.cpp")
		expectedCompileModuleArguments.TargetFile = Path.new("obj/Public.mock.obj")
		expectedCompileModuleArguments.IncludeModules = {}
		expectedCompileModuleArguments.ModuleInterfaceTarget = Path.new("bin/Library.mock.bmi")

		expectedCompileArguments.ModuleUnits = [
			expectedCompileModuleArguments,
		]

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
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				[],
				[
					Path.new("obj/"),
				]),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				[],
				[
					Path.new("bin/"),
				]),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				[
					Path.new("Public.cpp"),
				],
				[
					Path.new("obj/Public.mock.obj"),
					Path.new("bin/Library.mock.bmi"),
				]),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
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

		Assert.MapEqual(
			{
				"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
				"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
				"Library": Path.new("C:/target/bin/Library.mock.bmi"),
			},
			result.ModuleDependencies)

		Assert.ListEqual(
			[
				Path.new("C:/target/bin/Library.mock.lib"),
				Path.new("../Other/bin/OtherModule1.mock.a"),
				Path.new("../OtherModule2.mock.a"),
			],
			result.LinkDependencies)

		Assert.ListEqual(
			[],
			result.RuntimeDependencies)

		Assert.Equal(
			null,
			result.TargetFile)
	}
}
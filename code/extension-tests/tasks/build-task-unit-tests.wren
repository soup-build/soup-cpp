// <copyright file="build-task-unit-tests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup-test" for SoupTest, SoupTestOperation
import "../../extension/tasks/build-task" for BuildTask
import "../../compiler/core/build-arguments" for BuildOptimizationLevel, BuildTargetType
import "../../compiler/core/link-arguments" for LinkArguments, LinkTarget
import "../../compiler/core/mock-compiler" for MockCompiler
import "../../compiler/core/compile-arguments" for ModuleInterfaceUnitCompileArguments, LanguageStandard, OptimizationLevel, SharedCompileArguments, TranslationUnitCompileArguments
import "Soup|Build.Utils:./path" for Path
import "../../test/assert" for Assert

class BuildTaskUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("BuildTaskUnitTests.Build_WindowsApplication")
		this.Build_WindowsApplication()
		System.print("BuildTaskUnitTests.Build_Executable")
		this.Build_Executable()
		System.print("BuildTaskUnitTests.Build_Library_MultipleFiles")
		this.Build_Library_MultipleFiles()
		System.print("BuildTaskUnitTests.Build_Library_ModuleInterface")
		this.Build_Library_ModuleInterface()
		System.print("BuildTaskUnitTests.Build_Library_ModuleInterface_WithPartitions")
		this.Build_Library_ModuleInterface_WithPartitions()
		System.print("BuildTaskUnitTests.Build_Library_ModuleInterfaceNoSource")
		this.Build_Library_ModuleInterfaceNoSource()
	}

	Build_WindowsApplication() {
		// Setup the input build state
		SoupTest.initialize()
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

		// Setup build table
		var buildTable = {}
		activeState["Build"] = buildTable
		buildTable["Architecture"] = "x64"
		buildTable["Compiler"] = "MOCK"
		buildTable["TargetName"] = "Program"
		buildTable["TargetType"] = BuildTargetType.WindowsApplication
		buildTable["LanguageStandard"] = LanguageStandard.CPP20
		buildTable["SourceRootDirectory"] = "C:/source/"
		buildTable["TargetRootDirectory"] = "C:/target/"
		buildTable["ObjectDirectory"] = "obj/"
		buildTable["BinaryDirectory"] = "bin/"
		buildTable["Source"] = [
			{
				"File": "TestFile.cpp",
			},
		]

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
		BuildTask.registerCompiler("MOCK", Fn.new { |activeState| compiler })

		BuildTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Using Compiler: MOCK",
				"INFO: Generate Compile Operation: ./TestFile.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
				"INFO: Build Generate Done",
			],
			SoupTest.logs)

		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.cpp")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.TranslationUnits = [
			expectedTranslationUnitArguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.WindowsApplication
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetFile = Path.new("bin/Program.exe")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/TestFile.mock.obj"),
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
			SoupTestOperation.new(
				"MakeDir [./obj/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("obj/"),
				]),
			SoupTestOperation.new(
				"MakeDir [./bin/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("bin/"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile.cpp"),
				],
				[
					Path.new("obj/TestFile.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockLink: 1",
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			SoupTest.operations)
	}

	Build_Executable() {
		// Setup the input build state
		SoupTest.initialize()
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

		// Setup build table
		var buildTable = {}
		activeState["Build"] = buildTable
		buildTable["Architecture"] = "x64"
		buildTable["Compiler"] = "MOCK"
		buildTable["TargetName"] = "Program"
		buildTable["TargetType"] = BuildTargetType.Executable
		buildTable["LanguageStandard"] = LanguageStandard.CPP20
		buildTable["SourceRootDirectory"] = "C:/source/"
		buildTable["TargetRootDirectory"] = "C:/target/"
		buildTable["ObjectDirectory"] = "obj/"
		buildTable["BinaryDirectory"] = "bin/"
		buildTable["Source"] = [
			{
				"File": "TestFile.cpp",
			},
		]

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
		BuildTask.registerCompiler("MOCK", Fn.new { |activeState| compiler })

		BuildTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Using Compiler: MOCK",
				"INFO: Generate Compile Operation: ./TestFile.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
				"INFO: Build Generate Done",
			],
			SoupTest.logs)

		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.cpp")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.TranslationUnits = [
			expectedTranslationUnitArguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.Executable
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetFile = Path.new("bin/Program.exe")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/TestFile.mock.obj"),
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
			SoupTestOperation.new(
				"MakeDir [./obj/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("./obj/"),
				]),
			SoupTestOperation.new(
				"MakeDir [./bin/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("./bin/"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile.cpp"),
				],
				[
					Path.new("obj/TestFile.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockLink: 1",
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			SoupTest.operations)
	}

	Build_Library_MultipleFiles() {
		// Setup the input build state
		SoupTest.initialize()
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

		// Setup build table
		var buildTable = {}
		activeState["Build"] = buildTable
		buildTable["Architecture"] = "x64"
		buildTable["Compiler"] = "MOCK"
		buildTable["TargetName"] = "Library"
		buildTable["TargetType"] = BuildTargetType.StaticLibrary
		buildTable["LanguageStandard"] = LanguageStandard.CPP20
		buildTable["SourceRootDirectory"] = "C:/source/"
		buildTable["TargetRootDirectory"] = "C:/target/"
		buildTable["ObjectDirectory"] = "obj/"
		buildTable["BinaryDirectory"] = "bin/"
		buildTable["Source"] = [
			{
				"File": "TestFile1.cpp",
			},
			{
				"File": "TestFile2.cpp",
			},
			{
				"File": "TestFile3.cpp",
			},
		]
		buildTable["IncludeDirectories"] = [
			"Folder",
			"AnotherFolder/Sub",
		]
		buildTable["ModuleDependencies"] = {
			"OtherModule1": "../Other/bin/OtherModule1.mock.bmi",
			"OtherModule2": "../OtherModule2.mock.bmi",
		}
		buildTable["OptimizationLevel"] = BuildOptimizationLevel.None

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
		BuildTask.registerCompiler("MOCK", Fn.new { |activeState| compiler })

		BuildTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Using Compiler: MOCK",
				"INFO: Generate Compile Operation: ./TestFile1.cpp",
				"INFO: Generate Compile Operation: ./TestFile2.cpp",
				"INFO: Generate Compile Operation: ./TestFile3.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
				"INFO: Build Generate Done",
			],
			SoupTest.logs)

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]
		expectedCompileArguments.IncludeModules = {
			"OtherModule1": Path.new("../Other/bin/OtherModule1.mock.bmi"),
			"OtherModule2": Path.new("../OtherModule2.mock.bmi"),
		}

		expectedCompileArguments.TranslationUnits = [
			TranslationUnitCompileArguments.new(
				Path.new("TestFile1.cpp"),
				Path.new("obj/TestFile1.mock.obj"),
				{}),
			TranslationUnitCompileArguments.new(
				Path.new("TestFile2.cpp"),
				Path.new("obj/TestFile2.mock.obj"),
				{}),
			TranslationUnitCompileArguments.new(
				Path.new("TestFile3.cpp"),
				Path.new("obj/TestFile3.mock.obj"),
				{}),
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/TestFile1.mock.obj"),
			Path.new("obj/TestFile2.mock.obj"),
			Path.new("obj/TestFile3.mock.obj"),
		]
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
			SoupTestOperation.new(
				"MakeDir [./obj/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("./obj/"),
				]),
			SoupTestOperation.new(
				"MakeDir [./bin/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("./bin/"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile1.cpp"),
				],
				[
					Path.new("obj/TestFile1.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile2.cpp"),
				],
				[
					Path.new("obj/TestFile2.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile3.cpp"),
				],
				[
					Path.new("obj/TestFile3.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockLink: 1",
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			SoupTest.operations)
	}

	Build_Library_ModuleInterface() {
		// Setup the input build state
		SoupTest.initialize()
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

		// Setup build table
		var buildTable = {}
		activeState["Build"] = buildTable
		buildTable["Architecture"] = "x64"
		buildTable["Compiler"] = "MOCK"
		buildTable["TargetName"] = "Library"
		buildTable["TargetType"] = BuildTargetType.StaticLibrary
		buildTable["LanguageStandard"] = LanguageStandard.CPP20
		buildTable["SourceRootDirectory"] = "C:/source/"
		buildTable["TargetRootDirectory"] = "C:/target/"
		buildTable["ObjectDirectory"] = "obj/"
		buildTable["BinaryDirectory"] = "bin/"
		buildTable["Source"] = [
			{
				"File": "Public.cpp",
				"IsInterface": true,
				"Module": "Library",
			},
			{
				"File": "TestFile1.cpp",
			},
			{
				"File": "TestFile2.cpp",
			},
			{
				"File": "TestFile3.cpp",
			},
		]
		buildTable["IncludeDirectories"] = [
			"Folder",
			"AnotherFolder/Sub",
		]
		buildTable["ModuleDependencies"] = {
			"OtherModule1": "../Other/bin/OtherModule1.mock.bmi",
			"OtherModule2": "../OtherModule2.mock.bmi",
		}
		buildTable["OptimizationLevel"] = BuildOptimizationLevel.None
		buildTable["PreprocessorDefinitions"] = [
			"DEBUG",
			"AWESOME",
		]

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
		BuildTask.registerCompiler("MOCK", Fn.new { |activeState| compiler })

		BuildTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Using Compiler: MOCK",
				"INFO: Generate Compile Module Interface Operation: ./Public.cpp",
				"INFO: Generate Compile Operation: ./TestFile1.cpp",
				"INFO: Generate Compile Operation: ./TestFile2.cpp",
				"INFO: Generate Compile Operation: ./TestFile3.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
				"INFO: Build Generate Done",
			],
			SoupTest.logs)

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
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
		expectedCompileArguments.ModuleInterfaceUnits = [
			ModuleInterfaceUnitCompileArguments.new(
				Path.new("Public.cpp"),
				Path.new("obj/Public.mock.obj"),
				{},
				"Library",
				Path.new("bin/Library.mock.bmi")),
		]
		expectedCompileArguments.TranslationUnits = [
			TranslationUnitCompileArguments.new(
				Path.new("TestFile1.cpp"),
				Path.new("obj/TestFile1.mock.obj"),
				{}),
			TranslationUnitCompileArguments.new(
				Path.new("TestFile2.cpp"),
				Path.new("obj/TestFile2.mock.obj"),
				{}),
			TranslationUnitCompileArguments.new(
				Path.new("TestFile3.cpp"),
				Path.new("obj/TestFile3.mock.obj"),
				{}),
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/Public.mock.obj"),
			Path.new("obj/TestFile1.mock.obj"),
			Path.new("obj/TestFile2.mock.obj"),
			Path.new("obj/TestFile3.mock.obj"),
		]
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
			SoupTestOperation.new(
				"MakeDir [./obj/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("obj/"),
				]),
			SoupTestOperation.new(
				"MakeDir [./bin/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("bin/"),
				]),
			SoupTestOperation.new(
				"MockCompileModuleInterface: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("Public.cpp"),
				],
				[
					Path.new("obj/Public.mock.obj"),
					Path.new("bin/Library.mock.bmi"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile1.cpp"),
				],
				[
					Path.new("obj/TestFile1.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile2.cpp"),
				],
				[
					Path.new("obj/TestFile2.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile3.cpp"),
				],
				[
					Path.new("obj/TestFile3.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockLink: 1",
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			SoupTest.operations)
	}

	Build_Library_ModuleInterface_WithPartitions() {
		// Setup the input build state
		SoupTest.initialize()
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

		// Setup build table
		var buildTable = {}
		activeState["Build"] = buildTable
		buildTable["Architecture"] = "x64"
		buildTable["Compiler"] = "MOCK"
		buildTable["TargetName"] = "Library"
		buildTable["TargetType"] = BuildTargetType.StaticLibrary
		buildTable["LanguageStandard"] = LanguageStandard.CPP20
		buildTable["SourceRootDirectory"] = "C:/source/"
		buildTable["TargetRootDirectory"] = "C:/target/"
		buildTable["ObjectDirectory"] = "obj/"
		buildTable["BinaryDirectory"] = "bin/"
		buildTable["Source"] = [
			{
				"File": "Public.cpp",
				"Module": "Library",
				"IsInterface": true,
				"Imports": [
					":TestFile1",
					":TestFile2",
				],
			},
			{
				"File": "TestFile1.cpp",
				"Module": "Library",
				"IsInterface": true,
				"Partition": "TestFile1",
			},
			{
				"File": "TestFile2.cpp",
				"Module": "Library",
				"IsInterface": true,
				"Partition": "TestFile2",
				"Imports": [ ":TestFile1", ],
			},
			{
				"File": "TestFile3.cpp",
			},
			{
				"File": "TestFile4.cpp",
			},
		]
		buildTable["IncludeDirectories"] = [
			"Folder",
			"AnotherFolder/Sub",
		]
		buildTable["ModuleDependencies"] = {
			"OtherModule1": "../Other/bin/OtherModule1.mock.bmi",
			"OtherModule2": "../OtherModule2.mock.bmi",
		}
		buildTable["OptimizationLevel"] = BuildOptimizationLevel.None
		buildTable["PreprocessorDefinitions"] = [
			"DEBUG",
			"AWESOME",
		]

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
		BuildTask.registerCompiler("MOCK", Fn.new { |activeState| compiler })

		BuildTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Using Compiler: MOCK",
				"INFO: Generate Compile Module Interface Operation: ./Public.cpp",
				"INFO: Generate Compile Module Interface Operation: ./TestFile1.cpp",
				"INFO: Generate Compile Module Interface Operation: ./TestFile2.cpp",
				"INFO: Generate Compile Operation: ./TestFile3.cpp",
				"INFO: Generate Compile Operation: ./TestFile4.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
				"INFO: Build Generate Done",
			],
			SoupTest.logs)

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
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
		expectedCompileArguments.ModuleInterfaceUnits = [
			ModuleInterfaceUnitCompileArguments.new(
				Path.new("Public.cpp"),
				Path.new("obj/Public.mock.obj"),
				{
					"Library:TestFile1": Path.new("C:/target/obj/Library-TestFile1.mock.bmi"),
					"Library:TestFile2": Path.new("C:/target/obj/Library-TestFile2.mock.bmi"),
				},
				"Library",
				Path.new("bin/Library.mock.bmi")),
			ModuleInterfaceUnitCompileArguments.new(
				Path.new("TestFile1.cpp"),
				Path.new("obj/TestFile1.mock.obj"),
				{},
				"Library:TestFile1",
				Path.new("obj/Library-TestFile1.mock.bmi")),
			ModuleInterfaceUnitCompileArguments.new(
				Path.new("TestFile2.cpp"),
				Path.new("obj/TestFile2.mock.obj"),
				{
					"Library:TestFile1": Path.new("C:/target/obj/Library-TestFile1.mock.bmi"),
				},
				"Library:TestFile2",
				Path.new("obj/Library-TestFile2.mock.bmi")),
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
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/Public.mock.obj"),
			Path.new("obj/TestFile1.mock.obj"),
			Path.new("obj/TestFile2.mock.obj"),
			Path.new("obj/TestFile3.mock.obj"),
			Path.new("obj/TestFile4.mock.obj"),
		]
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
			SoupTestOperation.new(
				"MakeDir [./obj/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("obj/"),
				]),
			SoupTestOperation.new(
				"MakeDir [./bin/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("bin/"),
				]),
			SoupTestOperation.new(
				"MockCompileModuleInterface: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("Public.cpp"),
				],
				[
					Path.new("obj/Public.mock.obj"),
					Path.new("bin/Library.mock.bmi"),
				]),
			SoupTestOperation.new(
				"MockCompileModuleInterface: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile1.cpp"),
				],
				[
					Path.new("obj/TestFile1.mock.obj"),
					Path.new("obj/Library-TestFile1.mock.bmi"),
				]),
			SoupTestOperation.new(
				"MockCompileModuleInterface: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile2.cpp"),
				],
				[
					Path.new("obj/TestFile2.mock.obj"),
					Path.new("obj/Library-TestFile2.mock.bmi"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile3.cpp"),
				],
				[
					Path.new("obj/TestFile3.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile4.cpp"),
				],
				[
					Path.new("obj/TestFile4.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockLink: 1",
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			SoupTest.operations)
	}

	Build_Library_ModuleInterfaceNoSource() {
		// Setup the input build state
		SoupTest.initialize()
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

		// Setup build table
		var buildTable = {}
		activeState["Build"] = buildTable
		buildTable["Architecture"] = "x64"
		buildTable["Compiler"] = "MOCK"
		buildTable["TargetName"] = "Library"
		buildTable["TargetType"] = BuildTargetType.StaticLibrary
		buildTable["LanguageStandard"] = LanguageStandard.CPP20
		buildTable["SourceRootDirectory"] = "C:/source/"
		buildTable["TargetRootDirectory"] = "C:/target/"
		buildTable["ObjectDirectory"] = "obj/"
		buildTable["BinaryDirectory"] = "bin/"
		buildTable["Source"] = [
			{
				"File": "Public.cpp",
				"Module": "Library",
				"IsInterface": true,
			}
		]
		buildTable["IncludeDirectories"] = [
			"Folder",
			"AnotherFolder/Sub",
		]
		buildTable["ModuleDependencies"] = {
			"OtherModule1": "../Other/bin/OtherModule1.mock.bmi",
			"OtherModule2": "../OtherModule2.mock.bmi",
		}
		buildTable["OptimizationLevel"] = BuildOptimizationLevel.None
		buildTable["PreprocessorDefinitions"] = [
			"DEBUG",
			"AWESOME",
		]

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
		BuildTask.registerCompiler("MOCK", Fn.new { |activeState| compiler })

		BuildTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Using Compiler: MOCK",
				"INFO: Generate Compile Module Interface Operation: ./Public.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
				"INFO: Build Generate Done",
			],
			SoupTest.logs)

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.CPP20
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.ObjectDirectory = Path.new("./obj/")
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
		expectedCompileArguments.ModuleInterfaceUnits = [
			ModuleInterfaceUnitCompileArguments.new(
				Path.new("./Public.cpp"),
				Path.new("./obj/Public.mock.obj"),
				{},
				"Library",
				Path.new("./bin/Library.mock.bmi")),
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/Public.mock.obj"),
		]
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
			SoupTestOperation.new(
				"MakeDir [./obj/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("obj/"),
				]),
			SoupTestOperation.new(
				"MakeDir [./bin/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("bin/"),
				]),
			SoupTestOperation.new(
				"MockCompileModuleInterface: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("Public.cpp"),
				],
				[
					Path.new("obj/Public.mock.obj"),
					Path.new("bin/Library.mock.bmi"),
				]),
				SoupTestOperation.new(
				"MockLink: 1",
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			SoupTest.operations)
	}
}

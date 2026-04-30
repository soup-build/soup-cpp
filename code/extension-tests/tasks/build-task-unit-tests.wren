// <copyright file="build-task-unit-tests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup-test" for SoupTest, SoupTestOperation
import "../../extension/tasks/build-task" for BuildTask
import "../../compiler/core/build-arguments" for BuildOptimizationLevel, BuildTargetType
import "../../compiler/core/link-arguments" for LinkArguments, LinkTarget
import "../../compiler/core/mock-compiler" for MockCompiler
import "../../compiler/core/compile-arguments" for ModuleInterfaceUnitCompileArguments, LanguageStandard, OptimizationLevel, SharedCompileArguments, TranslationUnitCompileArguments
import "soup|build-utils:./path" for Path
import "../../test/assert" for Assert

class BuildTaskUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("BuildTaskUnitTests.Build_WindowsApplication()")
		this.Build_WindowsApplication()
		System.print("BuildTaskUnitTests.Build_Executable()")
		this.Build_Executable()
		System.print("BuildTaskUnitTests.Build_Library_MultipleFiles()")
		this.Build_Library_MultipleFiles()
		System.print("BuildTaskUnitTests.Build_Library_ModuleInterface()")
		this.Build_Library_ModuleInterface()
		System.print("BuildTaskUnitTests.Build_Library_ModuleInterface_WithPartitions()")
		this.Build_Library_ModuleInterface_WithPartitions()
		System.print("BuildTaskUnitTests.Build_Library_ModuleInterfaceNoSource()")
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
		buildTable["System"] = "Win32"
		buildTable["Compiler"] = "MOCK"
		buildTable["TargetName"] = "my-program"
		buildTable["TargetType"] = BuildTargetType.WindowsApplication
		buildTable["LanguageStandard"] = LanguageStandard.CPP20
		buildTable["SourceRootDirectory"] = "C:/source/"
		buildTable["TargetRootDirectory"] = "C:/target/"
		buildTable["ObjectDirectory"] = "obj/"
		buildTable["BinaryDirectory"] = "bin/"
		buildTable["Source"] = [
			{
				"File": "src/test-file.cpp",
				"Root": "./",
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
				"INFO: Generate Compile Operation: ./src/test-file.cpp",
				"INFO: Ensure Object Folder: ./obj/src/",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/my-program.exe",
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
		expectedTranslationUnitArguments.SourceFile = Path.new("src/test-file.cpp")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/src/test-file.mock.obj")

		expectedCompileArguments.TranslationUnits = [
			expectedTranslationUnitArguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.WindowsApplication
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetFile = Path.new("bin/my-program.exe")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/src/test-file.mock.obj"),
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
				"MakeDir [./obj/src/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/src/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("obj/src/"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("src/test-file.cpp"),
				],
				[
					Path.new("obj/src/test-file.mock.obj"),
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

		var expectedSharedState = {
			"Language": "C++",
			"Version": "1.0",
			"Build": {
				"RunArguments": [],
				"LinkDependencies": [],
				"ModuleDependencies": {},
				"RuntimeDependencies": [
					"C:/target/bin/my-program.exe"
				],
				"RunExecutable": "C:/target/bin/my-program.exe",
				"TargetFile": "C:/target/bin/my-program.exe",
			}
		}
		Assert.MapEqual(
			expectedSharedState,
			SoupTest.sharedState)
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
		buildTable["System"] = "Unix"
		buildTable["Compiler"] = "MOCK"
		buildTable["TargetName"] = "my-program"
		buildTable["TargetType"] = BuildTargetType.Executable
		buildTable["LanguageStandard"] = LanguageStandard.CPP20
		buildTable["SourceRootDirectory"] = "C:/source/"
		buildTable["TargetRootDirectory"] = "C:/target/"
		buildTable["ObjectDirectory"] = "obj/"
		buildTable["BinaryDirectory"] = "bin/"
		buildTable["Source"] = [
			{
				"File": "test-file.cpp",
				"Root": "./",
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
				"INFO: Generate Compile Operation: ./test-file.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/my-program",
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
		expectedTranslationUnitArguments.SourceFile = Path.new("test-file.cpp")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/test-file.mock.obj")

		expectedCompileArguments.TranslationUnits = [
			expectedTranslationUnitArguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.Executable
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetFile = Path.new("bin/my-program")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/test-file.mock.obj"),
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
					Path.new("test-file.cpp"),
				],
				[
					Path.new("obj/test-file.mock.obj"),
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

		var expectedSharedState = {
			"Language": "C++",
			"Version": "1.0",
			"Build": {
				"RunArguments": [],
				"LinkDependencies": [],
				"ModuleDependencies": {},
				"RuntimeDependencies": [
					"C:/target/bin/my-program"
				],
				"RunExecutable": "C:/target/bin/my-program",
				"TargetFile": "C:/target/bin/my-program",
			}
		}
		Assert.MapEqual(
			expectedSharedState,
			SoupTest.sharedState)
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
		buildTable["System"] = "Win32"
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
				"File": "test-file1.cpp",
				"Root": "./",
			},
			{
				"File": "test-file2.cpp",
				"Root": "./",
			},
			{
				"File": "test-file3.cpp",
				"Root": "./",
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
				"INFO: Generate Compile Operation: ./test-file1.cpp",
				"INFO: Generate Compile Operation: ./test-file2.cpp",
				"INFO: Generate Compile Operation: ./test-file3.cpp",
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
				Path.new("test-file1.cpp"),
				Path.new("obj/test-file1.mock.obj"),
				{}),
			TranslationUnitCompileArguments.new(
				Path.new("test-file2.cpp"),
				Path.new("obj/test-file2.mock.obj"),
				{}),
			TranslationUnitCompileArguments.new(
				Path.new("test-file3.cpp"),
				Path.new("obj/test-file3.mock.obj"),
				{}),
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/test-file1.mock.obj"),
			Path.new("obj/test-file2.mock.obj"),
			Path.new("obj/test-file3.mock.obj"),
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
					Path.new("test-file1.cpp"),
				],
				[
					Path.new("obj/test-file1.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("test-file2.cpp"),
				],
				[
					Path.new("obj/test-file2.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("test-file3.cpp"),
				],
				[
					Path.new("obj/test-file3.mock.obj"),
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

		var expectedSharedState = {
			"Language": "C++",
			"Version": "1.0",
			"Build": {
				"LinkDependencies": [
					"C:/target/bin/Library.mock.lib",
				],
				"ModuleDependencies": {
					"OtherModule1": "../Other/bin/OtherModule1.mock.bmi",
					"OtherModule2": "../OtherModule2.mock.bmi",
				},
				"RuntimeDependencies": [],
			}
		}
		Assert.MapEqual(
			expectedSharedState,
			SoupTest.sharedState)
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
		buildTable["System"] = "Win32"
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
				"File": "public.cpp",
				"Root": "./",
				"IsInterface": true,
				"Module": "Library",
			},
			{
				"File": "test-file1.cpp",
				"Root": "./",
			},
			{
				"File": "test-file2.cpp",
				"Root": "./",
			},
			{
				"File": "test-file3.cpp",
				"Root": "./",
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
				"INFO: Generate Compile Module Interface Operation: ./public.cpp",
				"INFO: Generate Compile Operation: ./test-file1.cpp",
				"INFO: Generate Compile Operation: ./test-file2.cpp",
				"INFO: Generate Compile Operation: ./test-file3.cpp",
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
				Path.new("public.cpp"),
				Path.new("obj/public.mock.obj"),
				{},
				"Library",
				Path.new("bin/Library.mock.bmi")),
		]
		expectedCompileArguments.TranslationUnits = [
			TranslationUnitCompileArguments.new(
				Path.new("test-file1.cpp"),
				Path.new("obj/test-file1.mock.obj"),
				{}),
			TranslationUnitCompileArguments.new(
				Path.new("test-file2.cpp"),
				Path.new("obj/test-file2.mock.obj"),
				{}),
			TranslationUnitCompileArguments.new(
				Path.new("test-file3.cpp"),
				Path.new("obj/test-file3.mock.obj"),
				{}),
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/public.mock.obj"),
			Path.new("obj/test-file1.mock.obj"),
			Path.new("obj/test-file2.mock.obj"),
			Path.new("obj/test-file3.mock.obj"),
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
					Path.new("public.cpp"),
				],
				[
					Path.new("obj/public.mock.obj"),
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
					Path.new("test-file1.cpp"),
				],
				[
					Path.new("obj/test-file1.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("test-file2.cpp"),
				],
				[
					Path.new("obj/test-file2.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("test-file3.cpp"),
				],
				[
					Path.new("obj/test-file3.mock.obj"),
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

		var expectedSharedState = {
			"Language": "C++",
			"Version": "1.0",
			"Build": {
				"LinkDependencies": [
					"C:/target/bin/Library.mock.lib",
				],
				"ModuleDependencies": {
					"OtherModule1": "../Other/bin/OtherModule1.mock.bmi",
					"OtherModule2": "../OtherModule2.mock.bmi",
					"Library": "C:/target/bin/Library.mock.bmi",
				},
				"RuntimeDependencies": [],
			}
		}
		Assert.MapEqual(
			expectedSharedState,
			SoupTest.sharedState)
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
		buildTable["System"] = "Win32"
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
				"File": "public.cpp",
				"Root": "./",
				"Module": "Library",
				"IsInterface": true,
				"Imports": [
					":test-file1",
					":test-file2",
				],
			},
			{
				"File": "test-file1.cpp",
				"Root": "./",
				"Module": "Library",
				"IsInterface": true,
				"Partition": "test-file1",
			},
			{
				"File": "test-file2.cpp",
				"Root": "./",
				"Module": "Library",
				"IsInterface": true,
				"Partition": "test-file2",
				"Imports": [ ":test-file1", ],
			},
			{
				"File": "test-file3.cpp",
				"Root": "./",
			},
			{
				"File": "test-file4.cpp",
				"Root": "./",
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
				"INFO: Generate Compile Module Interface Operation: ./public.cpp",
				"INFO: Generate Compile Module Interface Operation: ./test-file1.cpp",
				"INFO: Generate Compile Module Interface Operation: ./test-file2.cpp",
				"INFO: Generate Compile Operation: ./test-file3.cpp",
				"INFO: Generate Compile Operation: ./test-file4.cpp",
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
				Path.new("public.cpp"),
				Path.new("obj/public.mock.obj"),
				{
					"Library:test-file1": Path.new("C:/target/obj/Library-test-file1.mock.bmi"),
					"Library:test-file2": Path.new("C:/target/obj/Library-test-file2.mock.bmi"),
				},
				"Library",
				Path.new("bin/Library.mock.bmi")),
			ModuleInterfaceUnitCompileArguments.new(
				Path.new("test-file1.cpp"),
				Path.new("obj/test-file1.mock.obj"),
				{},
				"Library:test-file1",
				Path.new("obj/Library-test-file1.mock.bmi")),
			ModuleInterfaceUnitCompileArguments.new(
				Path.new("test-file2.cpp"),
				Path.new("obj/test-file2.mock.obj"),
				{
					"Library:test-file1": Path.new("C:/target/obj/Library-test-file1.mock.bmi"),
				},
				"Library:test-file2",
				Path.new("obj/Library-test-file2.mock.bmi")),
		]
		expectedCompileArguments.TranslationUnits = [
			TranslationUnitCompileArguments.new(
				Path.new("test-file3.cpp"),
				Path.new("obj/test-file3.mock.obj"),
				{}),
			TranslationUnitCompileArguments.new(
				Path.new("test-file4.cpp"),
				Path.new("obj/test-file4.mock.obj"),
				{}),
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/public.mock.obj"),
			Path.new("obj/test-file1.mock.obj"),
			Path.new("obj/test-file2.mock.obj"),
			Path.new("obj/test-file3.mock.obj"),
			Path.new("obj/test-file4.mock.obj"),
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
					Path.new("public.cpp"),
				],
				[
					Path.new("obj/public.mock.obj"),
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
					Path.new("test-file1.cpp"),
				],
				[
					Path.new("obj/test-file1.mock.obj"),
					Path.new("obj/Library-test-file1.mock.bmi"),
				]),
			SoupTestOperation.new(
				"MockCompileModuleInterface: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("test-file2.cpp"),
				],
				[
					Path.new("obj/test-file2.mock.obj"),
					Path.new("obj/Library-test-file2.mock.bmi"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("test-file3.cpp"),
				],
				[
					Path.new("obj/test-file3.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("test-file4.cpp"),
				],
				[
					Path.new("obj/test-file4.mock.obj"),
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

		var expectedSharedState = {
			"Language": "C++",
			"Version": "1.0",
			"Build": {
				"LinkDependencies": [
					"C:/target/bin/Library.mock.lib",
				],
				"ModuleDependencies": {
					"Library": "C:/target/bin/Library.mock.bmi",
					"Library:test-file1": "C:/target/obj/Library-test-file1.mock.bmi",
					"OtherModule1": "../Other/bin/OtherModule1.mock.bmi",
					"OtherModule2": "../OtherModule2.mock.bmi",
					"Library:test-file2": "C:/target/obj/Library-test-file2.mock.bmi",
				},
				"RuntimeDependencies": [],
			}
		}
		Assert.MapEqual(
			expectedSharedState,
			SoupTest.sharedState)
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
		buildTable["System"] = "Win32"
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
				"File": "public.cpp",
				"Root": "./",
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
				"INFO: Generate Compile Module Interface Operation: ./public.cpp",
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
				Path.new("./public.cpp"),
				Path.new("./obj/public.mock.obj"),
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
			Path.new("obj/public.mock.obj"),
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
					Path.new("public.cpp"),
				],
				[
					Path.new("obj/public.mock.obj"),
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

		var expectedSharedState = {
			"Language": "C++",
			"Version": "1.0",
			"Build": {
				"LinkDependencies": [
					"C:/target/bin/Library.mock.lib",
				],
				"ModuleDependencies": {
					"Library": "C:/target/bin/Library.mock.bmi",
					"OtherModule1": "../Other/bin/OtherModule1.mock.bmi",
					"OtherModule2": "../OtherModule2.mock.bmi",
				},
				"RuntimeDependencies": [],
			}
		}
		Assert.MapEqual(
			expectedSharedState,
			SoupTest.sharedState)
	}
}

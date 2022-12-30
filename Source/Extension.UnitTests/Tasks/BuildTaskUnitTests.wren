// <copyright file="BuildTaskUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

class BuildTaskUnitTests
{
	public void Initialize_Success()
	{
		var buildState = new MockBuildState()
		var factory = new ValueFactory()
		var uut = new BuildTask(buildState, factory)
	}

	public void Build_WindowsApplication()
	{
		// Setup the input build state
		var buildState = new MockBuildState()
		var state = buildState.ActiveState

		// Setup build table
		var buildTable = new ValueTable()
		state.add("Build", new Value(buildTable))
		buildTable.add("TargetName", new Value("Program"))
		buildTable.add("TargetType", new Value((long)BuildTargetType.WindowsApplication))
		buildTable.add("LanguageStandard", new Value((long)LanguageStandard.CPP20))
		buildTable.add("SourceRootDirectory", new Value("C:/source/"))
		buildTable.add("TargetRootDirectory", new Value("C:/target/"))
		buildTable.add("ObjectDirectory", new Value("obj/"))
		buildTable.add("BinaryDirectory", new Value("bin/"))
		buildTable.add(
			"Source",
			new Value(new ValueList()
				{
					new Value("TestFile.cpp"),
				}))

		// Setup parameters table
		var parametersTable = new ValueTable()
		state.add("Parameters", new Value(parametersTable))
		parametersTable.add("Architecture", new Value("x64"))
		parametersTable.add("Compiler", new Value("MOCK"))

		// Register the mock compiler
		var compiler = new Compiler.Mock.Compiler()
		var compilerFactory = new Dictionary<string, Func<IValueTable, ICompiler>>()
		compilerFactory.add("MOCK", (IValueTable state) => { return compiler })

		var factory = new ValueFactory()
		var uut = new BuildTask(buildState, factory, compilerFactory)

		uut.Execute()

		// Verify expected logs
		Assert.Equal(
			[
			{
				"INFO: Generate Compile Operation: ./TestFile.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
				"INFO: Build Generate Done",
			},
			testListener.GetMessages())

		var expectedCompileArguments = SharedCompileArguments.new()
		{
			Standard = LanguageStandard.CPP20,
			Optimize = OptimizationLevel.None,
			SourceRootDirectory = Path.new("C:/source/"),
			TargetRootDirectory = Path.new("C:/target/"),
			ObjectDirectory = Path.new("obj/"),
		}

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.cpp")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.ImplementationUnits = new List<TranslationUnitCompileArguments>()
		{
			expectedTranslationUnitArguments,
		}

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.WindowsApplication
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetFile = Path.new("bin/Program.exe")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
		{
			Path.new("obj/TestFile.mock.obj"),
		}

		// Verify expected compiler calls
		Assert.Equal(
			new List<SharedCompileArguments>()
			{
				expectedCompileArguments,
			},
			compiler.GetCompileRequests())
		Assert.Equal(
			new List<LinkArguments>()
			{
				expectedLinkArguments,
			},
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
		{
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[,
				[
				{
					Path.new("obj/"),
				}),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./bin/\"",
				[,
				[
				{
					Path.new("bin/"),
				}),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("TestFile.cpp"),
				},
				[
				{
					Path.new("obj/TestFile.mock.obj"),
				}),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
				{
					Path.new("InputFile.in"),
				},
				[
				{
					Path.new("OutputFile.out"),
				}),
		}

		Assert.Equal(
			expectedBuildOperations,
			buildState.GetBuildOperations())
	}

	public void Build_Executable()
	{
		// Setup the input build state
		var buildState = new MockBuildState()
		var state = buildState.ActiveState

		// Setup build table
		var buildTable = new ValueTable()
		state.add("Build", new Value(buildTable))
		buildTable.add("TargetName", new Value("Program"))
		buildTable.add("TargetType", new Value((long)BuildTargetType.Executable))
		buildTable.add("LanguageStandard", new Value((long)LanguageStandard.CPP20))
		buildTable.add("SourceRootDirectory", new Value("C:/source/"))
		buildTable.add("TargetRootDirectory", new Value("C:/target/"))
		buildTable.add("ObjectDirectory", new Value("obj/"))
		buildTable.add("BinaryDirectory", new Value("bin/"))
		buildTable.add(
			"Source",
			new Value(new ValueList()
				{
					new Value("TestFile.cpp"),
				}))

		// Setup parameters table
		var parametersTable = new ValueTable()
		state.add("Parameters", new Value(parametersTable))
		parametersTable.add("Architecture", new Value("x64"))
		parametersTable.add("Compiler", new Value("MOCK"))

		// Register the mock compiler
		var compiler = new Compiler.Mock.Compiler()
		var compilerFactory = new Dictionary<string, Func<IValueTable, ICompiler>>()
		compilerFactory.add("MOCK", (IValueTable state) => { return compiler })

		var factory = new ValueFactory()
		var uut = new BuildTask(buildState, factory, compilerFactory)

		uut.Execute()

		// Verify expected logs
		Assert.Equal(
			[
			{
				"INFO: Generate Compile Operation: ./TestFile.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
				"INFO: Build Generate Done",
			},
			testListener.GetMessages())

		var expectedCompileArguments = SharedCompileArguments.new()
		{
			Standard = LanguageStandard.CPP20,
			Optimize = OptimizationLevel.None,
			SourceRootDirectory = Path.new("C:/source/"),
			TargetRootDirectory = Path.new("C:/target/"),
			ObjectDirectory = Path.new("obj/"),
		}

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.cpp")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.ImplementationUnits = new List<TranslationUnitCompileArguments>()
		{
			expectedTranslationUnitArguments,
		}

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.Executable
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetFile = Path.new("bin/Program.exe")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
		{
			Path.new("obj/TestFile.mock.obj"),
		}

		// Verify expected compiler calls
		Assert.Equal(
			new List<SharedCompileArguments>()
			{
				expectedCompileArguments,
			},
			compiler.GetCompileRequests())
		Assert.Equal(
			new List<LinkArguments>()
			{
				expectedLinkArguments,
			},
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
		{
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[,
				[
				{
					Path.new("./obj/"),
				}),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./bin/\"",
				[,
				[
				{
					Path.new("./bin/"),
				}),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("TestFile.cpp"),
				},
				[
				{
					Path.new("obj/TestFile.mock.obj"),
				}),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
				{
					Path.new("InputFile.in"),
				},
				[
				{
					Path.new("OutputFile.out"),
				}),
		}

		Assert.Equal(
			expectedBuildOperations,
			buildState.GetBuildOperations())
	}

	public void Build_Library_MultipleFiles()
	{
		// Setup the input build state
		var buildState = new MockBuildState()
		var state = buildState.ActiveState

		// Setup build table
		var buildTable = new ValueTable()
		state.add("Build", new Value(buildTable))
		buildTable.add("TargetName", new Value("Library"))
		buildTable.add("TargetType", new Value((long)BuildTargetType.StaticLibrary))
		buildTable.add("LanguageStandard", new Value((long)LanguageStandard.CPP20))
		buildTable.add("SourceRootDirectory", new Value("C:/source/"))
		buildTable.add("TargetRootDirectory", new Value("C:/target/"))
		buildTable.add("ObjectDirectory", new Value("obj/"))
		buildTable.add("BinaryDirectory", new Value("bin/"))
		buildTable.add("Source", new Value(new ValueList()
		{
			new Value("TestFile1.cpp"),
			new Value("TestFile2.cpp"),
			new Value("TestFile3.cpp"),
		}))
		buildTable.add("IncludeDirectories", new Value(new ValueList()
		{
			new Value("Folder"),
			new Value("AnotherFolder/Sub"),
		}))
		buildTable.add("ModuleDependencies", new Value(new ValueList()
		{
			new Value("../Other/bin/OtherModule1.mock.bmi"),
			new Value("../OtherModule2.mock.bmi"),
		}))
		buildTable.add("OptimizationLevel", new Value((long)BuildOptimizationLevel.None))

		// Setup parameters table
		var parametersTable = new ValueTable()
		state.add("Parameters", new Value(parametersTable))
		parametersTable.add("Architecture", new Value("x64"))
		parametersTable.add("Compiler", new Value("MOCK"))

		// Register the mock compiler
		var compiler = new Compiler.Mock.Compiler()
		var compilerFactory = new Dictionary<string, Func<IValueTable, ICompiler>>()
		compilerFactory.add("MOCK", (IValueTable state) => { return compiler })

		var factory = new ValueFactory()
		var uut = new BuildTask(buildState, factory, compilerFactory)

		uut.Execute()

		// Verify expected logs
		Assert.Equal(
			[
			{
				"INFO: Generate Compile Operation: ./TestFile1.cpp",
				"INFO: Generate Compile Operation: ./TestFile2.cpp",
				"INFO: Generate Compile Operation: ./TestFile3.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
				"INFO: Build Generate Done",
			},
			testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		{
			Standard = LanguageStandard.CPP20,
			Optimize = OptimizationLevel.None,
			SourceRootDirectory = Path.new("C:/source/"),
			TargetRootDirectory = Path.new("C:/target/"),
			ObjectDirectory = Path.new("obj/"),
			IncludeDirectories = [
			{
				Path.new("Folder"),
				Path.new("AnotherFolder/Sub"),
			},
			IncludeModules = [
			{
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
			},
		}

		expectedCompileArguments.ImplementationUnits = new List<TranslationUnitCompileArguments>()
		{
			TranslationUnitCompileArguments.new()
			{
				SourceFile = Path.new("TestFile1.cpp"),
				TargetFile = Path.new("obj/TestFile1.mock.obj"),
			},
			TranslationUnitCompileArguments.new()
			{
				SourceFile = Path.new("TestFile2.cpp"),
				TargetFile = Path.new("obj/TestFile2.mock.obj"),
			},
			TranslationUnitCompileArguments.new()
			{
				SourceFile = Path.new("TestFile3.cpp"),
				TargetFile = Path.new("obj/TestFile3.mock.obj"),
			},
		}

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
		{
			Path.new("obj/TestFile1.mock.obj"),
			Path.new("obj/TestFile2.mock.obj"),
			Path.new("obj/TestFile3.mock.obj"),
		}
		expectedLinkArguments.LibraryFiles = [

		// Verify expected compiler calls
		Assert.Equal(
			new List<SharedCompileArguments>()
			{
				expectedCompileArguments,
			},
			compiler.GetCompileRequests())
		Assert.Equal(
			new List<LinkArguments>()
			{
				expectedLinkArguments,
			},
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
		{
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[,
				[
				{
					Path.new("./obj/"),
				}),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./bin/\"",
				[,
				[
				{
					Path.new("./bin/"),
				}),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("TestFile1.cpp"),
				},
				[
				{
					Path.new("obj/TestFile1.mock.obj"),
				}),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("TestFile2.cpp"),
				},
				[
				{
					Path.new("obj/TestFile2.mock.obj"),
				}),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("TestFile3.cpp"),
				},
				[
				{
					Path.new("obj/TestFile3.mock.obj"),
				}),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
				{
					Path.new("InputFile.in"),
				},
				[
				{
					Path.new("OutputFile.out"),
				}),
		}

		Assert.Equal(
			expectedBuildOperations,
			buildState.GetBuildOperations())
	}

	public void Build_Library_ModuleInterface()
	{
		// Setup the input build state
		var buildState = new MockBuildState()
		var state = buildState.ActiveState

		// Setup build table
		var buildTable = new ValueTable()
		state.add("Build", new Value(buildTable))
		buildTable.add("TargetName", new Value("Library"))
		buildTable.add("TargetType", new Value((long)BuildTargetType.StaticLibrary))
		buildTable.add("LanguageStandard", new Value((long)LanguageStandard.CPP20))
		buildTable.add("SourceRootDirectory", new Value("C:/source/"))
		buildTable.add("TargetRootDirectory", new Value("C:/target/"))
		buildTable.add("ObjectDirectory", new Value("obj/"))
		buildTable.add("BinaryDirectory", new Value("bin/"))
		buildTable.add("ModuleInterfaceSourceFile", new Value("Public.cpp"))
		buildTable.add("Source", new Value(new ValueList()
		{
			new Value("TestFile1.cpp"),
			new Value("TestFile2.cpp"),
			new Value("TestFile3.cpp"),
		}))
		buildTable.add("IncludeDirectories", new Value(new ValueList()
		{
			new Value("Folder"),
			new Value("AnotherFolder/Sub"),
		}))
		buildTable.add("ModuleDependencies", new Value(new ValueList()
		{
			new Value("../Other/bin/OtherModule1.mock.bmi"),
			new Value("../OtherModule2.mock.bmi"),
		}))
		buildTable.add("OptimizationLevel", new Value((long)BuildOptimizationLevel.None))
		buildTable.add("PreprocessorDefinitions", new Value(new ValueList()
		{
			new Value("DEBUG"),
			new Value("AWESOME"),
		}))

		// Setup parameters table
		var parametersTable = new ValueTable()
		state.add("Parameters", new Value(parametersTable))
		parametersTable.add("Architecture", new Value("x64"))
		parametersTable.add("Compiler", new Value("MOCK"))

		// Register the mock compiler
		var compiler = new Compiler.Mock.Compiler()
		var compilerFactory = new Dictionary<string, Func<IValueTable, ICompiler>>()
		compilerFactory.add("MOCK", (IValueTable state) => { return compiler })

		var factory = new ValueFactory()
		var uut = new BuildTask(buildState, factory, compilerFactory)

		uut.Execute()

		// Verify expected logs
		Assert.Equal(
			[
			{
				"INFO: Generate Module Interface Unit Compile: ./Public.cpp",
				"INFO: Generate Compile Operation: ./TestFile1.cpp",
				"INFO: Generate Compile Operation: ./TestFile2.cpp",
				"INFO: Generate Compile Operation: ./TestFile3.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
				"INFO: Build Generate Done",
			},
			testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		{
			Standard = LanguageStandard.CPP20,
			Optimize = OptimizationLevel.None,
			SourceRootDirectory = Path.new("C:/source/"),
			TargetRootDirectory = Path.new("C:/target/"),
			ObjectDirectory = Path.new("obj/"),
			IncludeDirectories = [
			{
				Path.new("Folder"),
				Path.new("AnotherFolder/Sub"),
			},
			IncludeModules = [
			{
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
			},
			PreprocessorDefinitions = [
			{
				"DEBUG",
				"AWESOME",
			},
			InterfaceUnit = InterfaceUnitCompileArguments.new()
			{
				ModuleInterfaceTarget = Path.new("obj/Public.mock.bmi"),
				SourceFile = Path.new("Public.cpp"),
				TargetFile = Path.new("obj/Public.mock.obj"),
			},
			ImplementationUnits = new List<TranslationUnitCompileArguments>()
			{
				TranslationUnitCompileArguments.new()
				{
					SourceFile = Path.new("TestFile1.cpp"),
					TargetFile = Path.new("obj/TestFile1.mock.obj"),
				},
				TranslationUnitCompileArguments.new()
				{
					SourceFile = Path.new("TestFile2.cpp"),
					TargetFile = Path.new("obj/TestFile2.mock.obj"),
				},
				TranslationUnitCompileArguments.new()
				{
					SourceFile = Path.new("TestFile3.cpp"),
					TargetFile = Path.new("obj/TestFile3.mock.obj"),
				},
			},
		}

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
		{
			Path.new("obj/Public.mock.obj"),
			Path.new("obj/TestFile1.mock.obj"),
			Path.new("obj/TestFile2.mock.obj"),
			Path.new("obj/TestFile3.mock.obj"),
		}
		expectedLinkArguments.LibraryFiles = [

		// Verify expected compiler calls
		Assert.Equal(
			new List<SharedCompileArguments>()
			{
				expectedCompileArguments,
			},
			compiler.GetCompileRequests())
		Assert.Equal(
			new List<LinkArguments>()
			{
				expectedLinkArguments,
			},
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
		{
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[,
				[
				{
					Path.new("obj/"),
				}),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./bin/\"",
				[,
				[
				{
					Path.new("bin/"),
				}),
			BuildOperation.new(
				"Copy [./obj/Public.mock.bmi] -> [./bin/Library.mock.bmi]",
				Path.new("C:/target/"),
				Path.new("C:/copy.exe"),
				"\"./obj/Public.mock.bmi\" \"./bin/Library.mock.bmi\"",
				[
				{
					Path.new("obj/Public.mock.bmi"),
				},
				[
				{
					Path.new("bin/Library.mock.bmi"),
				}),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("Public.cpp"),
				},
				[
				{
					Path.new("obj/Public.mock.obj"),
					Path.new("obj/Public.mock.bmi"),
				}),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("TestFile1.cpp"),
				},
				[
				{
					Path.new("obj/TestFile1.mock.obj"),
				}),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("TestFile2.cpp"),
				},
				[
				{
					Path.new("obj/TestFile2.mock.obj"),
				}),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("TestFile3.cpp"),
				},
				[
				{
					Path.new("obj/TestFile3.mock.obj"),
				}),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
				{
					Path.new("InputFile.in"),
				},
				[
				{
					Path.new("OutputFile.out"),
				}),
		}

		Assert.Equal(
			expectedBuildOperations,
			buildState.GetBuildOperations())
	}

	public void Build_Library_ModuleInterface_WithPartitions()
	{
		// Setup the input build state
		var buildState = new MockBuildState()
		var state = buildState.ActiveState

		// Setup build table
		var buildTable = new ValueTable()
		state.add("Build", new Value(buildTable))
		buildTable.add("TargetName", new Value("Library"))
		buildTable.add("TargetType", new Value((long)BuildTargetType.StaticLibrary))
		buildTable.add("LanguageStandard", new Value((long)LanguageStandard.CPP20))
		buildTable.add("SourceRootDirectory", new Value("C:/source/"))
		buildTable.add("TargetRootDirectory", new Value("C:/target/"))
		buildTable.add("ObjectDirectory", new Value("obj/"))
		buildTable.add("BinaryDirectory", new Value("bin/"))
		buildTable.add("ModuleInterfacePartitionSourceFiles", new Value(new ValueList()
		{
			new Value(new ValueTable()
			{
				{ "Source", new Value("TestFile1.cpp") },
			}),
			new Value(new ValueTable()
			{
				{ "Source", new Value("TestFile2.cpp") },
				{ "Imports", new Value(new ValueList() { new Value("TestFile1.cpp"), }) },
			}),
		}))
		buildTable.add("ModuleInterfaceSourceFile", new Value("Public.cpp"))
		buildTable.add("Source", new Value(new ValueList()
		{
			new Value("TestFile3.cpp"),
			new Value("TestFile4.cpp"),
		}))
		buildTable.add("IncludeDirectories", new Value(new ValueList()
		{
			new Value("Folder"),
			new Value("AnotherFolder/Sub"),
		}))
		buildTable.add("ModuleDependencies", new Value(new ValueList()
		{
			new Value("../Other/bin/OtherModule1.mock.bmi"),
			new Value("../OtherModule2.mock.bmi"),
		}))
		buildTable.add("OptimizationLevel", new Value((long)BuildOptimizationLevel.None))
		buildTable.add("PreprocessorDefinitions", new Value(new ValueList()
		{
			new Value("DEBUG"),
			new Value("AWESOME"),
		}))

		// Setup parameters table
		var parametersTable = new ValueTable()
		state.add("Parameters", new Value(parametersTable))
		parametersTable.add("Architecture", new Value("x64"))
		parametersTable.add("Compiler", new Value("MOCK"))

		// Register the mock compiler
		var compiler = new Compiler.Mock.Compiler()
		var compilerFactory = new Dictionary<string, Func<IValueTable, ICompiler>>()
		compilerFactory.add("MOCK", (IValueTable state) => { return compiler })

		var factory = new ValueFactory()
		var uut = new BuildTask(buildState, factory, compilerFactory)

		uut.Execute()

		// Verify expected logs
		Assert.Equal(
			[
			{
				"INFO: Generate Module Interface Partition Compile Operation: ./TestFile1.cpp",
				"INFO: Generate Module Interface Partition Compile Operation: ./TestFile2.cpp",
				"INFO: Generate Module Interface Unit Compile: ./Public.cpp",
				"INFO: Generate Compile Operation: ./TestFile3.cpp",
				"INFO: Generate Compile Operation: ./TestFile4.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
				"INFO: Build Generate Done",
			},
			testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		{
			Standard = LanguageStandard.CPP20,
			Optimize = OptimizationLevel.None,
			SourceRootDirectory = Path.new("C:/source/"),
			TargetRootDirectory = Path.new("C:/target/"),
			ObjectDirectory = Path.new("obj/"),
			IncludeDirectories = [
			{
				Path.new("Folder"),
				Path.new("AnotherFolder/Sub"),
			},
			IncludeModules = [
			{
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
			},
			PreprocessorDefinitions = [
			{
				"DEBUG",
				"AWESOME",
			},
			InterfacePartitionUnits = [
			{
				InterfaceUnitCompileArguments.new()
				{
					SourceFile = Path.new("TestFile1.cpp"),
					TargetFile = Path.new("obj/TestFile1.mock.obj"),
					ModuleInterfaceTarget = Path.new("obj/TestFile1.mock.bmi"),
				},
				InterfaceUnitCompileArguments.new()
				{
					SourceFile = Path.new("TestFile2.cpp"),
					TargetFile = Path.new("obj/TestFile2.mock.obj"),
					IncludeModules = [
					{
						Path.new("C:/target/obj/TestFile1.mock.bmi"),
					},
					ModuleInterfaceTarget = Path.new("obj/TestFile2.mock.bmi"),
				},
			},
			InterfaceUnit = InterfaceUnitCompileArguments.new()
			{
				ModuleInterfaceTarget = Path.new("obj/Public.mock.bmi"),
				SourceFile = Path.new("Public.cpp"),
				IncludeModules = [
				{
					Path.new("C:/target/obj/TestFile1.mock.bmi"),
					Path.new("C:/target/obj/TestFile2.mock.bmi"),
				},
				TargetFile = Path.new("obj/Public.mock.obj"),
			},
			ImplementationUnits = new List<TranslationUnitCompileArguments>()
			{
				TranslationUnitCompileArguments.new()
				{
					SourceFile = Path.new("TestFile3.cpp"),
					TargetFile = Path.new("obj/TestFile3.mock.obj"),
				},
				TranslationUnitCompileArguments.new()
				{
					SourceFile = Path.new("TestFile4.cpp"),
					TargetFile = Path.new("obj/TestFile4.mock.obj"),
				},
			},
		}

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
		{
			Path.new("obj/TestFile1.mock.obj"),
			Path.new("obj/TestFile2.mock.obj"),
			Path.new("obj/Public.mock.obj"),
			Path.new("obj/TestFile3.mock.obj"),
			Path.new("obj/TestFile4.mock.obj"),
		}
		expectedLinkArguments.LibraryFiles = [

		// Verify expected compiler calls
		Assert.Equal(
			new List<SharedCompileArguments>()
			{
				expectedCompileArguments,
			},
			compiler.GetCompileRequests())
		Assert.Equal(
			new List<LinkArguments>()
			{
				expectedLinkArguments,
			},
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
		{
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[,
				[
				{
					Path.new("obj/"),
				}),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./bin/\"",
				[,
				[
				{
					Path.new("bin/"),
				}),
			BuildOperation.new(
				"Copy [./obj/Public.mock.bmi] -> [./bin/Library.mock.bmi]",
				Path.new("C:/target/"),
				Path.new("C:/copy.exe"),
				"\"./obj/Public.mock.bmi\" \"./bin/Library.mock.bmi\"",
				[
				{
					Path.new("obj/Public.mock.bmi"),
				},
				[
				{
					Path.new("bin/Library.mock.bmi"),
				}),
			BuildOperation.new(
				"MockCompilePartition: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("TestFile1.cpp"),
				},
				[
				{
					Path.new("obj/TestFile1.mock.obj"),
					Path.new("obj/TestFile1.mock.bmi"),
				}),
			BuildOperation.new(
				"MockCompilePartition: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("TestFile2.cpp"),
				},
				[
				{
					Path.new("obj/TestFile2.mock.obj"),
					Path.new("obj/TestFile2.mock.bmi"),
				}),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("Public.cpp"),
				},
				[
				{
					Path.new("obj/Public.mock.obj"),
					Path.new("obj/Public.mock.bmi"),
				}),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("TestFile3.cpp"),
				},
				[
				{
					Path.new("obj/TestFile3.mock.obj"),
				}),
			BuildOperation.new(
				"MockCompile: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("TestFile4.cpp"),
				},
				[
				{
					Path.new("obj/TestFile4.mock.obj"),
				}),
			BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
				{
					Path.new("InputFile.in"),
				},
				[
				{
					Path.new("OutputFile.out"),
				}),
		}

		Assert.Equal(
			expectedBuildOperations,
			buildState.GetBuildOperations())
	}

	public void Build_Library_ModuleInterfaceNoSource()
	{
		// Setup the input build state
		var buildState = new MockBuildState()
		var state = buildState.ActiveState

		// Setup build table
		var buildTable = new ValueTable()
		state.add("Build", new Value(buildTable))
		buildTable.add("TargetName", new Value("Library"))
		buildTable.add("TargetType", new Value((long)BuildTargetType.StaticLibrary))
		buildTable.add("LanguageStandard", new Value((long)LanguageStandard.CPP20))
		buildTable.add("SourceRootDirectory", new Value("C:/source/"))
		buildTable.add("TargetRootDirectory", new Value("C:/target/"))
		buildTable.add("ObjectDirectory", new Value("obj/"))
		buildTable.add("BinaryDirectory", new Value("bin/"))
		buildTable.add("ModuleInterfaceSourceFile", new Value("Public.cpp"))
		state.add("SourceFiles", new Value(new ValueList()))
		buildTable.add("IncludeDirectories", new Value(new ValueList()
		{
			new Value("Folder"),
			new Value("AnotherFolder/Sub"),
		}))
		buildTable.add("ModuleDependencies", new Value(new ValueList()
		{
			new Value("../Other/bin/OtherModule1.mock.bmi"),
			new Value("../OtherModule2.mock.bmi"),
		}))
		buildTable.add("OptimizationLevel", new Value((long)BuildOptimizationLevel.None))
		buildTable.add("PreprocessorDefinitions", new Value(new ValueList()
		{
			new Value("DEBUG"),
			new Value("AWESOME"),
		}))

		// Setup parameters table
		var parametersTable = new ValueTable()
		state.add("Parameters", new Value(parametersTable))
		parametersTable.add("Architecture", new Value("x64"))
		parametersTable.add("Compiler", new Value("MOCK"))

		// Register the mock compiler
		var compiler = new Compiler.Mock.Compiler()
		var compilerFactory = new Dictionary<string, Func<IValueTable, ICompiler>>()
		compilerFactory.add("MOCK", (IValueTable state) => { return compiler })

		var factory = new ValueFactory()
		var uut = new BuildTask(buildState, factory, compilerFactory)

		uut.Execute()

		// Verify expected logs
		Assert.Equal(
			new List<string>
			{
				"INFO: Generate Module Interface Unit Compile: ./Public.cpp",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
				"INFO: Build Generate Done",
			},
			testListener.GetMessages())

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		{
			Standard = LanguageStandard.CPP20,
			Optimize = OptimizationLevel.None,
			SourceRootDirectory = Path.new("C:/source/"),
			TargetRootDirectory = Path.new("C:/target/"),
			ObjectDirectory = Path.new("./obj/"),
			IncludeDirectories = [
			{
				Path.new("Folder"),
				Path.new("AnotherFolder/Sub"),
			},
			IncludeModules = [
			{
				Path.new("../Other/bin/OtherModule1.mock.bmi"),
				Path.new("../OtherModule2.mock.bmi"),
			},
			PreprocessorDefinitions = [
			{
				"DEBUG",
				"AWESOME",
			},
			InterfaceUnit = InterfaceUnitCompileArguments.new()
			{
				SourceFile = Path.new("./Public.cpp"),
				TargetFile = Path.new("./obj/Public.mock.obj"),
				ModuleInterfaceTarget = Path.new("./obj/Public.mock.bmi"),
			}
		}

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
		{
			Path.new("obj/Public.mock.obj"),
		}
		expectedLinkArguments.LibraryFiles = [

		// Verify expected compiler calls
		Assert.Equal(
			new List<SharedCompileArguments>()
			{
				expectedCompileArguments,
			},
			compiler.GetCompileRequests())
		Assert.Equal(
			new List<LinkArguments>()
			{
				expectedLinkArguments,
			},
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
		{
			BuildOperation.new(
				"MakeDir [./obj/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./obj/\"",
				[,
				[
				{
					Path.new("obj/"),
				}),
			BuildOperation.new(
				"MakeDir [./bin/]",
				Path.new("C:/target/"),
				Path.new("C:/mkdir.exe"),
				"\"./bin/\"",
				[,
				[
				{
					Path.new("bin/"),
				}),
			BuildOperation.new(
				"Copy [./obj/Public.mock.bmi] -> [./bin/Library.mock.bmi]",
				Path.new("C:/target/"),
				Path.new("C:/copy.exe"),
				"\"./obj/Public.mock.bmi\" \"./bin/Library.mock.bmi\"",
				[
				{
					Path.new("obj/Public.mock.bmi"),
				},
				[
				{
					Path.new("bin/Library.mock.bmi"),
				}),
			BuildOperation.new(
				"MockCompileModule: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockCompiler.exe"),
				"Arguments",
				[
				{
					Path.new("Public.cpp"),
				},
				[
				{
					Path.new("obj/Public.mock.obj"),
					Path.new("obj/Public.mock.bmi"),
				}),
				BuildOperation.new(
				"MockLink: 1",
				Path.new("MockWorkingDirectory"),
				Path.new("MockLinker.exe"),
				"Arguments",
				[
				{
					Path.new("InputFile.in"),
				},
				[
				{
					Path.new("OutputFile.out"),
				}),
		}

		Assert.Equal(
			expectedBuildOperations,
			buildState.GetBuildOperations())
	}
}

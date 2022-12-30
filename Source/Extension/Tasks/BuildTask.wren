// <copyright file="BuildTask.cs" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

using Opal
using Opal.System
using Soup.Build.Cpp.Compiler
using System
using System.Collections.Generic
using System.Linq

namespace Soup.Build.Cpp
{
	public class BuildTask : IBuildTask
	{
		private IBuildState buildState
		private IValueFactory factory
		private IDictionary<string, Func<IValueTable, ICompiler>> compilerFactory

		/// <summary>
		/// Get the run before list
		/// </summary>
		public static IReadOnlyList<string> RunBeforeList => [
		{
		}

		/// <summary>
		/// Get the run after list
		/// </summary>
		public static IReadOnlyList<string> RunAfterList => [
		{
		}

		public BuildTask(IBuildState buildState, IValueFactory factory) :
			this(buildState, factory, new Dictionary<string, Func<IValueTable, ICompiler>>())
		{
			// Register default compilers
			this.compilerFactory.Add("MSVC", (IValueTable activeState) =>
			{
				var clToolPath = Path.new(activeState["MSVC.ClToolPath"].AsString())
				var linkToolPath = Path.new(activeState["MSVC.LinkToolPath"].AsString())
				var libToolPath = Path.new(activeState["MSVC.LibToolPath"].AsString())
				var rcToolPath = Path.new(activeState["MSVC.RCToolPath"].AsString())
				var mlToolPath = Path.new(activeState["MSVC.MLToolPath"].AsString())
				return new Compiler.MSVC.Compiler(
					clToolPath,
					linkToolPath,
					libToolPath,
					rcToolPath,
					mlToolPath)
			})
		}

		public BuildTask(IBuildState buildState, IValueFactory factory, Dictionary<string, Func<IValueTable, ICompiler>> compilerFactory)
		{
			this.buildState = buildState
			this.factory = factory
			this.compilerFactory = compilerFactory
		}

		public void Execute()
		{
			var activeState = this.buildState.ActiveState
			var sharedState = this.buildState.SharedState

			var buildTable = activeState["Build"].AsTable()
			var parametersTable = activeState["Parameters"].AsTable()

			var arguments = new BuildArguments()
			arguments.TargetArchitecture = parametersTable["Architecture"].AsString()
			arguments.TargetName = buildTable["TargetName"].AsString()
			arguments.TargetType = (BuildTargetType)
				buildTable["TargetType"].AsInteger()
			arguments.LanguageStandard = (LanguageStandard)
				buildTable["LanguageStandard"].AsInteger()
			arguments.SourceRootDirectory = Path.new(buildTable["SourceRootDirectory"].AsString())
			arguments.TargetRootDirectory = Path.new(buildTable["TargetRootDirectory"].AsString())
			arguments.ObjectDirectory = Path.new(buildTable["ObjectDirectory"].AsString())
			arguments.BinaryDirectory = Path.new(buildTable["BinaryDirectory"].AsString())

			if (buildTable.TryGetValue("ResourcesFile", out var resourcesFile))
			{
				arguments.ResourceFile = Path.new(resourcesFile.AsString())
			}

			if (buildTable.TryGetValue("ModuleInterfacePartitionSourceFiles", out var moduleInterfacePartitionSourceFiles))
			{
				var paritionTargets = new List<PartitionSourceFile>()
				foreach (var partition in moduleInterfacePartitionSourceFiles.AsList())
				{
					var partitionTable = partition.AsTable()

					var partitionImports = [
					if (partitionTable.TryGetValue("Imports", out var partitionImportsValue))
					{
						partitionImports = partitionImportsValue.AsList().Select(value => Path.new(value.AsString())).ToList()
					}

					paritionTargets.Add(new PartitionSourceFile()
					{
						File = Path.new(partitionTable["Source"].AsString()),
						Imports = partitionImports,
					})
				}

				arguments.ModuleInterfacePartitionSourceFiles = paritionTargets
			}

			if (buildTable.TryGetValue("ModuleInterfaceSourceFile", out var moduleInterfaceSourceFile))
			{
				arguments.ModuleInterfaceSourceFile = Path.new(moduleInterfaceSourceFile.AsString())
			}

			if (buildTable.TryGetValue("Source", out var sourceValue))
			{
				arguments.SourceFiles = sourceValue.AsList().Select(value => Path.new(value.AsString())).ToList()
			}

			if (buildTable.TryGetValue("AssemblySource", out var assemblySourceValue))
			{
				arguments.AssemblySourceFiles = assemblySourceValue.AsList().Select(value => Path.new(value.AsString())).ToList()
			}

			if (buildTable.TryGetValue("IncludeDirectories", out var includeDirectoriesValue))
			{
				arguments.IncludeDirectories = includeDirectoriesValue.AsList().Select(value => Path.new(value.AsString())).ToList()
			}

			if (buildTable.TryGetValue("PlatformLibraries", out var platformLibrariesValue))
			{
				arguments.PlatformLinkDependencies = platformLibrariesValue.AsList().Select(value => Path.new(value.AsString())).ToList()
			}

			if (buildTable.TryGetValue("LinkLibraries", out var linkLibrariesValue))
			{
				arguments.LinkDependencies = MakeUnique(linkLibrariesValue.AsList().Select(value => Path.new(value.AsString())))
			}

			if (buildTable.TryGetValue("LibraryPaths", out var libraryPathsValue))
			{
				arguments.LibraryPaths = libraryPathsValue.AsList().Select(value => Path.new(value.AsString())).ToList()
			}

			if (buildTable.TryGetValue("PreprocessorDefinitions", out var preprocessorDefinitionsValue))
			{
				arguments.PreprocessorDefinitions = preprocessorDefinitionsValue.AsList().Select(value => value.AsString()).ToList()
			}

			if (buildTable.TryGetValue("OptimizationLevel", out var optimizationLevelValue))
			{
				arguments.OptimizationLevel = (BuildOptimizationLevel)
					optimizationLevelValue.AsInteger()
			}
			else
			{
				arguments.OptimizationLevel = BuildOptimizationLevel.None
			}

			if (buildTable.TryGetValue("GenerateSourceDebugInfo", out var generateSourceDebugInfoValue))
			{
				arguments.GenerateSourceDebugInfo = generateSourceDebugInfoValue.AsBoolean()
			}
			else
			{
				arguments.GenerateSourceDebugInfo = false
			}

			// Load the runtime dependencies
			if (buildTable.TryGetValue("RuntimeDependencies", out var runtimeDependenciesValue))
			{
				arguments.RuntimeDependencies = MakeUnique(
					runtimeDependenciesValue.AsList().Select(value => Path.new(value.AsString())))
			}

			// Load the link dependencies
			if (buildTable.TryGetValue("LinkDependencies", out var linkDependenciesValue))
			{
				arguments.LinkDependencies = CombineUnique(
					arguments.LinkDependencies,
					linkDependenciesValue.AsList().Select(value => Path.new(value.AsString())))
			}

			// Load the module references
			if (buildTable.TryGetValue("ModuleDependencies", out var moduleDependenciesValue))
			{
				arguments.ModuleDependencies = MakeUnique(
					moduleDependenciesValue.AsList().Select(value => Path.new(value.AsString())))
			}

			// Load the list of disabled warnings
			if (buildTable.TryGetValue("EnableWarningsAsErrors", out var enableWarningsAsErrorsValue))
			{
				arguments.EnableWarningsAsErrors = enableWarningsAsErrorsValue.AsBoolean()
			}
			else
			{
				arguments.GenerateSourceDebugInfo = false
			}

			// Load the list of disabled warnings
			if (buildTable.TryGetValue("DisabledWarnings", out var disabledWarningsValue))
			{
				arguments.DisabledWarnings = disabledWarningsValue.AsList().Select(value => value.AsString()).ToList()
			}

			// Check for any custom compiler flags
			if (buildTable.TryGetValue("CustomCompilerProperties", out var customCompilerPropertiesValue))
			{
				arguments.CustomProperties = customCompilerPropertiesValue.AsList().Select(value => value.AsString()).ToList()
			}

			// Initialize the compiler to use
			var compilerName = parametersTable["Compiler"].AsString()
			if (!this.compilerFactory.TryGetValue(compilerName, out var compileFactory))
			{
				this.buildState.LogTrace(TraceLevel.Error, "Unknown compiler: " + compilerName)
				throw new InvalidOperationException()
			}

			var compiler = compileFactory(activeState)

			var buildEngine = new BuildEngine(compiler)
			var buildResult = buildEngine.Execute(this.buildState, arguments)

			// Pass along internal state for other stages to gain access
			buildTable.EnsureValueList(this.factory, "InternalLinkDependencies").SetAll(this.factory, buildResult.InternalLinkDependencies)

			// Always pass along required input to shared build tasks
			var sharedBuildTable = sharedState.EnsureValueTable(this.factory, "Build")
			sharedBuildTable.EnsureValueList(this.factory, "ModuleDependencies").SetAll(this.factory, buildResult.ModuleDependencies)
			sharedBuildTable.EnsureValueList(this.factory, "RuntimeDependencies").SetAll(this.factory, buildResult.RuntimeDependencies)
			sharedBuildTable.EnsureValueList(this.factory, "LinkDependencies").SetAll(this.factory, buildResult.LinkDependencies)

			if (!buildResult.TargetFile.IsEmpty)
			{
				sharedBuildTable["TargetFile"] = this.factory.Create(buildResult.TargetFile.toString)
				sharedBuildTable["RunExecutable"] = this.factory.Create(buildResult.TargetFile.toString)
				sharedBuildTable.EnsureValueList(this.factory, "RunArguments").SetAll(this.factory, [ { })
			}

			// Register the build operations
			foreach (var operation in buildResult.BuildOperations)
			{
				this.buildState.CreateOperation(operation)
			}

			this.buildState.LogTrace(TraceLevel.Information, "Build Generate Done")
		}

		private static List<Path> CombineUnique(
			IEnumerable<Path> collection1,
			IEnumerable<Path> collection2)
		{
			var valueSet = new HashSet<string>()
			foreach (var value in collection1)
				valueSet.Add(value.toString)
			foreach (var value in collection2)
				valueSet.Add(value.toString)

			return valueSet.Select(value => Path.new(value)).ToList()
		}

		private static List<Path> MakeUnique(IEnumerable<Path> collection)
		{
			var valueSet = new HashSet<string>()
			foreach (var value in collection)
				valueSet.Add(value.toString)

			return valueSet.Select(value => Path.new(value)).ToList()
		}
	}
}

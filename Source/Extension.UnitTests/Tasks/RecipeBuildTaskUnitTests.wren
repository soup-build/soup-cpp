// <copyright file="RecipeBuildTaskUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

class RecipeBuildTaskUnitTests
{
	public void Build_Executable() {
		// Setup the input build state
		var buildState = MockBuildState.new()
		var state = buildState.ActiveState
		state.add("PlatformLibraries", new Value(new ValueList()))
		state.add("PlatformIncludePaths", new Value(new ValueList()))
		state.add("PlatformLibraryPaths", new Value(new ValueList()))
		state.add("PlatformPreprocessorDefinitions", new Value(new ValueList()))

		// Setup recipe table
		var buildTable = {}
		state.add("Recipe", new Value(buildTable))
		buildTable.add("Name", new Value("Program"))

		// Setup parameters table
		var parametersTable = {}
		state.add("Parameters", new Value(parametersTable))
		parametersTable.add("TargetDirectory", new Value("C:/Target/"))
		parametersTable.add("PackageDirectory", new Value("C:/PackageRoot/"))
		parametersTable.add("Compiler", new Value("MOCK"))
		parametersTable.add("Flavor", new Value("debug"))

		RecipeBuildTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[],
			testListener.GetMessages())

		// Verify build state
		var expectedBuildOperations = []

		Assert.ListEqual(
			expectedBuildOperations,
			buildState.GetBuildOperations())

		// TODO: Verify output build state
	}
}

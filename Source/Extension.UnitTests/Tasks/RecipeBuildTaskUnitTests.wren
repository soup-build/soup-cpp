// <copyright file="RecipeBuildTaskUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

class RecipeBuildTaskUnitTests
{
	public void Initialize_Success()
	{
		var buildState = new MockBuildState()
		var factory = new ValueFactory()
		var uut = new RecipeBuildTask(buildState, factory)
	}

	public void Build_Executable()
	{
		// Setup the input build state
		var buildState = new MockBuildState()
		var state = buildState.ActiveState
		state.add("PlatformLibraries", new Value(new ValueList()))
		state.add("PlatformIncludePaths", new Value(new ValueList()))
		state.add("PlatformLibraryPaths", new Value(new ValueList()))
		state.add("PlatformPreprocessorDefinitions", new Value(new ValueList()))

		// Setup recipe table
		var buildTable = new ValueTable()
		state.add("Recipe", new Value(buildTable))
		buildTable.add("Name", new Value("Program"))

		// Setup parameters table
		var parametersTable = new ValueTable()
		state.add("Parameters", new Value(parametersTable))
		parametersTable.add("TargetDirectory", new Value("C:/Target/"))
		parametersTable.add("PackageDirectory", new Value("C:/PackageRoot/"))
		parametersTable.add("Compiler", new Value("MOCK"))
		parametersTable.add("Flavor", new Value("debug"))

		var factory = new ValueFactory()
		var uut = new RecipeBuildTask(buildState, factory)

		uut.Execute()

		// Verify expected logs
		Assert.Equal(
			[
			{
			},
			testListener.GetMessages())

		// Verify build state
		var expectedBuildOperations = [

		Assert.Equal(
			expectedBuildOperations,
			buildState.GetBuildOperations())

		// TODO: Verify output build state
	}
}

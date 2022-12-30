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
		state.Add("PlatformLibraries", new Value(new ValueList()))
		state.Add("PlatformIncludePaths", new Value(new ValueList()))
		state.Add("PlatformLibraryPaths", new Value(new ValueList()))
		state.Add("PlatformPreprocessorDefinitions", new Value(new ValueList()))

		// Setup recipe table
		var buildTable = new ValueTable()
		state.Add("Recipe", new Value(buildTable))
		buildTable.Add("Name", new Value("Program"))

		// Setup parameters table
		var parametersTable = new ValueTable()
		state.Add("Parameters", new Value(parametersTable))
		parametersTable.Add("TargetDirectory", new Value("C:/Target/"))
		parametersTable.Add("PackageDirectory", new Value("C:/PackageRoot/"))
		parametersTable.Add("Compiler", new Value("MOCK"))
		parametersTable.Add("Flavor", new Value("debug"))

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

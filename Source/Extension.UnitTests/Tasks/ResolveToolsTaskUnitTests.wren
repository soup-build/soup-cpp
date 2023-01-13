// <copyright file="ResolveToolsTaskUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

class ResolveToolsTaskUnitTests
{
	RunTests() {
		this.Execute()
	}

	Execute() {
		// Setup the input build state
		var buildState = MockBuildState.new()
		var state = buildState.ActiveState

		// Set the sdks
		var sdks = new ValueList()
		sdks.add(new Value({}
		{
			{ "Name", new Value("MSVC") },
			{ 
				"Properties",
				new Value({}
				{
					{ "Version", new Value("1.0.0") },
					{ "VCToolsRoot", new Value("C:/VCTools/Root/") },
				})
			},
		}))
		sdks.add(new Value({}
		{
			{ "Name", new Value("Windows") },
			{
				"Properties",
				new Value({}
				{
					{ "Version", new Value("10.0.0") },
					{ "RootPath", new Value("C:/WindowsKit/Root/") },
				})
			},
		}))

		// Setup parameters table
		var parametersTable = {}
		state.add("Parameters", new Value(parametersTable))
		parametersTable.add("SDKs", new Value(sdks))
		parametersTable.add("System", new Value("win32"))
		parametersTable.add("Architecture", new Value("x64"))

		ResolveToolsTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Using VC Version: 1.0.0",
				"INFO: Using Windows Kit Version: 10.0.0",
			],
			testListener.GetMessages())

		// Verify build state
		var expectedBuildOperations = [

		Assert.ListEqual(
			expectedBuildOperations,
			buildState.GetBuildOperations())
	}
}

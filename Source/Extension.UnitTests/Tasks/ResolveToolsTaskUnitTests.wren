// <copyright file="ResolveToolsTaskUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

class ResolveToolsTaskUnitTests
{
	RunTests() {
		this.Initialize_Success()
		this.Execute()
	}

	Initialize_Success() {
		var buildState = MockBuildState.new()
		var factory = new ValueFactory()
		var uut = new ResolveToolsTask(buildState, factory)
	}

	Execute() {
		// Setup the input build state
		var buildState = MockBuildState.new()
		var state = buildState.ActiveState

		// Set the sdks
		var sdks = new ValueList()
		sdks.add(new Value(new ValueTable()
		{
			{ "Name", new Value("MSVC") },
			{ 
				"Properties",
				new Value(new ValueTable()
				{
					{ "Version", new Value("1.0.0") },
					{ "VCToolsRoot", new Value("C:/VCTools/Root/") },
				})
			},
		}))
		sdks.add(new Value(new ValueTable()
		{
			{ "Name", new Value("Windows") },
			{
				"Properties",
				new Value(new ValueTable()
				{
					{ "Version", new Value("10.0.0") },
					{ "RootPath", new Value("C:/WindowsKit/Root/") },
				})
			},
		}))

		// Setup parameters table
		var parametersTable = new ValueTable()
		state.add("Parameters", new Value(parametersTable))
		parametersTable.add("SDKs", new Value(sdks))
		parametersTable.add("System", new Value("win32"))
		parametersTable.add("Architecture", new Value("x64"))

		var factory = new ValueFactory()
		var uut = new ResolveToolsTask(buildState, factory)

		uut.Execute()

		// Verify expected logs
		Assert.Equal(
			[
				"INFO: Using VC Version: 1.0.0",
				"INFO: Using Windows Kit Version: 10.0.0",
			},
			testListener.GetMessages())

		// Verify build state
		var expectedBuildOperations = [

		Assert.Equal(
			expectedBuildOperations,
			buildState.GetBuildOperations())
	}
}

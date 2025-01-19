// <copyright file="InitializeDefaultsTaskUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup-test" for SoupTest
import "../../extension/tasks/InitializeDefaultsTask" for InitializeDefaultsTask
import "../../test/Assert" for Assert

class InitializeDefaultsTaskUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("InitializeDefaultsTaskUnitTests.Execute")
		this.Execute()
	}

	Execute() {
		SoupTest.initialize()

		// Setup the input build state
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

		// Setup context table
		var contextTable = {}
		globalState["Context"] = contextTable
		contextTable["HostPlatform"] = "Windows"

		// Setup parameters table
		var parametersTable = {}
		globalState["Parameters"] = parametersTable
		parametersTable["Architecture"] = "x64"

		InitializeDefaultsTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[],
			SoupTest.logs)

		// Verify build state
		var expectedBuildOperations = []

		Assert.ListEqual(
			expectedBuildOperations,
			SoupTest.operations)
	}
}

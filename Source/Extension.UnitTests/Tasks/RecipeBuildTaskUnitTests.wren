// <copyright file="RecipeBuildTaskUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup-test" for SoupTest
import "../../Extension/Tasks/RecipeBuildTask" for RecipeBuildTask
import "../../Test/Assert" for Assert

class RecipeBuildTaskUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("RecipeBuildTaskUnitTests.Build_Executable")
		this.Build_Executable()
	}

	Build_Executable() {
		SoupTest.initialize()

		// Setup the input build state
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

		activeState["PlatformLibraries"] = []
		activeState["PlatformIncludePaths"] = []
		activeState["PlatformLibraryPaths"] = []
		activeState["PlatformPreprocessorDefinitions"] = []

		// Setup recipe table
		var recipeTable = {}
		globalState["Recipe"] = recipeTable
		recipeTable["Name"] = "Program"

		// Setup context table
		var contextTable = {}
		globalState["Context"] = contextTable
		contextTable["TargetDirectory"] = "/(TARGET)/"
		contextTable["PackageDirectory"] = "/(PACKAGE)/"

		// Setup parameters table
		var parametersTable = {}
		globalState["Parameters"] = parametersTable
		parametersTable["Compiler"] = "MOCK"
		parametersTable["Flavor"] = "debug"

		RecipeBuildTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[],
			SoupTest.logs)

		// Verify build state
		var expectedBuildOperations = []

		Assert.ListEqual(
			expectedBuildOperations,
			SoupTest.operations)

		// TODO: Verify output build state
	}
}

// <copyright file="recipe-build-task-unit-tests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup-test" for SoupTest
import "../../extension/tasks/recipe-build-task" for RecipeBuildTask
import "../../test/assert" for Assert

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

		// Setup build table
		var buildTable = {}
		activeState["Build"] = buildTable
		buildTable["Compiler"] = "MOCK"
		buildTable["Flavor"] = "Debug"

		// Setup recipe table
		var recipeTable = {}
		globalState["Recipe"] = recipeTable
		recipeTable["Name"] = "Program"

		// Setup context table
		var contextTable = {}
		globalState["Context"] = contextTable
		contextTable["TargetDirectory"] = "/(TARGET)/"
		contextTable["PackageDirectory"] = "/(PACKAGE)/"

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

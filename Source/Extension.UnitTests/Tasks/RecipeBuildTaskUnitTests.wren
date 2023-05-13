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
		System.print("RecipeBuildTaskUnitTests.Build_Executable_LinkLibraries")
		this.Build_Executable_LinkLibraries()
	}

	Build_Executable() {
		SoupTest.initialize()

		// Setup the input build state
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

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

		var expectedActiveState = {
			"Build": {
				"LinkLibraries": [],
				"TargetType": "StaticLibrary",
				"TargetRootDirectory": "/(TARGET)/",
				"Compiler": "MOCK",
				"EnableWarningsAsErrors": true,
				"IncludeDirectories": [],
				"BinaryDirectory": "./bin/",
				"Flavor": "Debug",
				"ModuleInterfacePartitionSourceFiles": [],
				"TargetName": "Program",
				"PlatformLibraries": [],
				"LibraryPaths": [],
				"GenerateSourceDebugInfo": true,
				"PublicHeaders": [],
				"SourceRootDirectory": "/(PACKAGE)/",
				"PreprocessorDefinitions": [
					"SOUP_BUILD",
				],
				"ObjectDirectory": "./obj/",
				"OptimizationLevel": "None",
				"Source": [],
				"AssemblySource": [],
				"LanguageStandard": "CPP20"
			},
		}

		Assert.MapEqual(
			expectedActiveState,
			SoupTest.activeState)
	}

	Build_Executable_LinkLibraries() {
		SoupTest.initialize()

		// Setup the input build state
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

		// Setup build table
		var buildTable = {}
		activeState["Build"] = buildTable
		buildTable["Compiler"] = "MOCK"
		buildTable["Flavor"] = "Debug"

		// Setup recipe table
		var recipeTable = {}
		globalState["Recipe"] = recipeTable
		recipeTable["Name"] = "Program"
		recipeTable["LinkLibraries"] = [
			"../Direct/Library.lib",
		]

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

		var expectedActiveState = {
			"Build": {
				"LinkLibraries": [
					"/(PACKAGE)/../Direct/Library.lib"
				],
				"TargetType": "StaticLibrary",
				"TargetRootDirectory": "/(TARGET)/",
				"Compiler": "MOCK",
				"EnableWarningsAsErrors": true,
				"IncludeDirectories": [],
				"BinaryDirectory": "./bin/",
				"Flavor": "Debug",
				"ModuleInterfacePartitionSourceFiles": [],
				"TargetName": "Program",
				"PlatformLibraries": [],
				"LibraryPaths": [],
				"GenerateSourceDebugInfo": true,
				"PublicHeaders": [],
				"SourceRootDirectory": "/(PACKAGE)/",
				"PreprocessorDefinitions": [
					"SOUP_BUILD",
				],
				"ObjectDirectory": "./obj/",
				"OptimizationLevel": "None",
				"Source": [],
				"AssemblySource": [],
				"LanguageStandard": "CPP20"
			},
		}

		Assert.MapEqual(
			expectedActiveState,
			SoupTest.activeState)
	}
}

// <copyright file="ResolveToolsTaskUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup-test" for SoupTest
import "../../Extension/Tasks/ResolveToolsTask" for ResolveToolsTask
import "../../Test/Assert" for Assert

class ResolveToolsTaskUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("ResolveToolsTaskUnitTests.Execute")
		this.Execute()
	}

	Execute() {
		SoupTest.initialize()

		// Setup the input build state
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

		// Set the sdks
		var sdks = []
		globalState["SDKs"] = sdks
		sdks.add(
			{
				"Name": "MSVC",
				"Properties":
				{
					"Version": "1.0.0",
					"VCToolsRoot": "C:/VCTools/Root/",
				},
			})
		sdks.add(
			{
				"Name": "Windows",
				"Properties":
				{
					"Version": "10.0.0",
					"RootPath": "C:/WindowsKit/Root/",
				},
			})

		// Setup context table
		var contextTable = {}
		globalState["Context"] = contextTable
		contextTable["HostPlatform"] = "Windows"

		// Setup build table
		var buildTable = {}
		activeState["Build"] = buildTable
		buildTable["Architecture"] = "x64"
		buildTable["System"] = "Win32"

		ResolveToolsTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Using VC Version: 1.0.0",
				"INFO: Using Windows Kit Version: 10.0.0",
			],
			SoupTest.logs)

		// Verify build state
		var expectedBuildOperations = []

		Assert.ListEqual(
			expectedBuildOperations,
			SoupTest.operations)
	}
}

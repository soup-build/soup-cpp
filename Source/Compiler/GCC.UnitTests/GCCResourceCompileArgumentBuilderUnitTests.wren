// <copyright file="GCCResourceCompileArgumentBuilderUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../GCC/GCCArgumentBuilder" for GCCArgumentBuilder
import "Soup.Build.Utils:./Path" for Path
import "../../Test/Assert" for Assert
import "../Core/CompileArguments" for SharedCompileArguments, ResourceCompileArguments


class GCCResourceCompileArgumentBuilderUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("GCCResourceCompileArgumentBuilderUnitTests.BuildResourceCompilerArguments_Simple")
		this.BuildResourceCompilerArguments_Simple()
	}

	// [Fact]
	BuildResourceCompilerArguments_Simple() {
		var targetRootDirectory = Path.new("C:/target/")

		var arguments = SharedCompileArguments.new()
		arguments.ResourceFile = ResourceCompileArguments.new(
			Path.new("Resources.rc"),
			Path.new("Resources.mock.res"))

		var actualArguments = GCCArgumentBuilder.BuildResourceCompilerArguments(
			targetRootDirectory,
			arguments)

		var expectedArguments = [
			"-D_UNICODE",
			"-DUNICODE",
			"-l\"0x0409\"",
			"-o\"C:/target/Resources.mock.res\"",
			"./Resources.rc",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}
}

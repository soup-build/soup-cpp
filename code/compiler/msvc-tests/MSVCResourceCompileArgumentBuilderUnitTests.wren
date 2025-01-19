// <copyright file="MSVCResourceCompileArgumentBuilderUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../msvc/MSVCArgumentBuilder" for MSVCArgumentBuilder
import "Soup|Build.Utils:./Path" for Path
import "../../test/Assert" for Assert
import "../core/CompileArguments" for SharedCompileArguments, ResourceCompileArguments


class MSVCResourceCompileArgumentBuilderUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("MSVCResourceCompileArgumentBuilderUnitTests.BuildResourceCompilerArguments_Simple")
		this.BuildResourceCompilerArguments_Simple()
	}

	// [Fact]
	BuildResourceCompilerArguments_Simple() {
		var targetRootDirectory = Path.new("C:/target/")

		var arguments = SharedCompileArguments.new()
		arguments.ResourceFile = ResourceCompileArguments.new(
			Path.new("Resources.rc"),
			Path.new("Resources.mock.res"))

		var actualArguments = MSVCArgumentBuilder.BuildResourceCompilerArguments(
			targetRootDirectory,
			arguments)

		var expectedArguments = [
			"/nologo",
			"/D_UNICODE",
			"/DUNICODE",
			"/l\"0x0409\"",
			"/Fo\"C:/target/Resources.mock.res\"",
			"./Resources.rc",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}
}

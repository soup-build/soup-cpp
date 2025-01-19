// <copyright file="ClangResourceCompileArgumentBuilderUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../clang/ClangArgumentBuilder" for ClangArgumentBuilder
import "Soup|Build.Utils:./Path" for Path
import "../../test/Assert" for Assert
import "../core/CompileArguments" for SharedCompileArguments, ResourceCompileArguments


class ClangResourceCompileArgumentBuilderUnitTests {
	construct new() {
	}

	RunTests() {
		// System.print("ClangResourceCompileArgumentBuilderUnitTests.BuildResourceCompilerArguments_Simple")
		// this.BuildResourceCompilerArguments_Simple()
	}

	// [Fact]
	BuildResourceCompilerArguments_Simple() {
		var targetRootDirectory = Path.new("C:/target/")

		var arguments = SharedCompileArguments.new()
		arguments.ResourceFile = ResourceCompileArguments.new(
			Path.new("Resources.rc"),
			Path.new("Resources.mock.res"))

		var actualArguments = ClangArgumentBuilder.BuildResourceCompilerArguments(
			targetRootDirectory,
			arguments)

		var expectedArguments = [
			"-D_UNICODE",
			"-DUNICODE",
			"-l\"0x0409\"",
			"-o",
			"C:/target/Resources.mock.res",
			"./Resources.rc",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}
}

// <copyright file="gcc-resource-compile-argument-builder-unit-tests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "Soup|Build.Utils:./path" for Path
import "../../test/assert" for Assert
import "../gcc/gcc-argument-builder" for GCCArgumentBuilder
import "../core/compile-arguments" for SharedCompileArguments, ResourceCompileArguments


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
			"-o",
			"C:/target/Resources.mock.res",
			"./Resources.rc",
		]

		Assert.ListEqual(expectedArguments, actualArguments)
	}
}

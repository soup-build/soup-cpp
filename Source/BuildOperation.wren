// <copyright file="BuildOperation.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

class BuildOperation {
	construct new(
		title,
		workingDirectory,
		executable,
		arguments,
		declaredInput,
		declaredOutput) {
		_title = title
		_workingDirectory = workingDirectory
		_executable = executable
		_arguments = arguments
		_declaredInput = declaredInput
		_declaredOutput = declaredOutput
	}

	Title { _title }
	WorkingDirectory { _workingDirectory }
	Executable { _executable}
	Arguments { _arguments }
	DeclaredInput { _declaredInput }
	DeclaredOutput { _declaredOutput }
}

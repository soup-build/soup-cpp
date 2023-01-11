// <copyright file="BuildOperation.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "./ListExtensions" for ListExtensions

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

	
	==(other) {
		// System.print("BuildOperation==")
		if (other is Null) {
			return false
		}

		return this.Title == other.Title &&
			this.WorkingDirectory == other.WorkingDirectory  &&
			this.Executable == other.Executable &&
			this.Arguments == other.Arguments &&
			ListExtensions.SequenceEqual(this.DeclaredInput, other.DeclaredInput) &&
			ListExtensions.SequenceEqual(this.DeclaredOutput, other.DeclaredOutput)
	}

	toString {
		return "BuildOperation { Title=%(_title), WorkingDirectory=%(_workingDirectory), Executable=%(_executable), Arguments=%(_arguments), DeclaredInput=%(_declaredInput), DeclaredOutput=%(_declaredOutput) }"
	}
}

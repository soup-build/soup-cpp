// <copyright file="IBuildState.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

class TraceLevel {
	/// <summary>
	/// Exceptional state that will fail the build
	/// </summary>
	static Error { "Error" }

	/// <summary>
	/// A possible issue in the build that may be fine to continue
	/// </summary>
	static Warning { "Warning" }

	/// <summary>
	/// Highest level of logging that will be on in all but the quiet logs
	/// </summary>
	static HighPriority { "HighPriority" }

	/// <summary>
	/// Important information that will be on in verbose logs. May help users investigate what occurred during a build.
	/// </summary>
	static Information { "Information" }

	/// <summary>
	/// The most detailed of logs that will only be useful for detailed investigations into runtime issues for build engineers. Diagnostic log level.
	/// </summary>
	static Debug { "Debug" }
}

class IBuildState {
	/// <summary>
	/// Gets a reference to the active state.
	/// </summary>
	ActiveState {}

	/// <summary>
	/// Gets a reference to the shared state. All of these properties will be.
	/// moved into the active state of any parent build that has a direct reference to this build.
	/// </summary>
	SharedState{}

	/// <summary>
	/// Create a build operation.
	/// </summary>
	/// <param name="title">The title.</param>
	/// <param name="executable">The executable.</param>
	/// <param name="arguments">The arguments.</param>
	/// <param name="workingDirectory">The workingDirectory.</param>
	/// <param name="declaredInput">The declaredInput.</param>
	/// <param name="declaredOutput">The declaredOutput.</param>
	CreateOperation(
		title,
		executable,
		arguments,
		workingDirectory,
		declaredInput,
		declaredOutput) {}

	/// <summary>
	/// Log a message to the build system.
	/// </summary>
	/// <param name="level">The trace level.</param>
	/// <param name="message">The message.</param>
	LogTrace(level, message) {}
}

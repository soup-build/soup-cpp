// <copyright file="ParseModuleFinalizerTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupFinalizerTask

class ParseModuleFinalizerTask is SoupFinalizerTask {
	/// <summary>
	/// The Core Execute task
	/// </summary>
	static evaluate(state, result) {
		Soup.info("Finalizer")

		var sourceFile = state["SourceFile"]
		var targetFile = state["TargetFile"]

		Soup.createOperation(
			"Do It",
			"./Run.exe",
			[
				sourceFile,
				targetFile,
			],
			"C:/folder/",
			[
				sourceFile,
			],
			[
				targetFile,
			])
	}
}
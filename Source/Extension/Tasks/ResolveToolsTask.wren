// <copyright file="ResolveToolsTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "Soup.Build.Utils:./Path" for Path
import "Soup.Build.Utils:./ListExtensions" for ListExtensions
import "Soup.Build.Utils:./MapExtensions" for MapExtensions

/// <summary>
/// The recipe build task that knows how to build a single recipe
/// </summary>
class ResolveToolsTask is SoupTask {
	/// <summary>
	/// Get the run before list
	/// </summary>
	static runBefore { [
		"BuildTask",
	] }

	/// <summary>
	/// Get the run after list
	/// </summary>
	static runAfter { [
		"InitializeDefaultsTask",
	] }

	/// <summary>
	/// The Core Execute task
	/// </summary>
	static evaluate() {
		var globalState = Soup.globalState
		var activeState = Soup.activeState

		var build = activeState["Build"]
		var system = build["System"]

		if (system == "Win32") {
			ResolveToolsTask.LoadMSVC(globalState, activeState)
		} else if (system == "Unix") {
			ResolveToolsTask.LoadClang(globalState, activeState)
		} else {
			Soup.info("Unknown system: %(system)")
		}
	}

	static LoadMSVC(globalState, activeState) {
		var msvc = MapExtensions.EnsureTable(activeState, "MSVC")

		var build = activeState["Build"]
		var architecture = build["Architecture"]

		// Check if skip platform includes was specified
		var skipPlatform = false
		if (activeState.containsKey("SkipPlatform")) {
			skipPlatform = activeState["SkipPlatform"]
		}

		// Find the MSVC SDK
		var msvcSDKProperties = ResolveToolsTask.GetSDKProperties("MSVC", globalState)

		// Use the default version
		var visualCompilerVersion = msvcSDKProperties["Version"]
		Soup.info("Using VC Version: %(visualCompilerVersion)")

		// Get the final VC tools folder
		var visualCompilerVersionFolder = Path.new(msvcSDKProperties["VCToolsRoot"])

		// Load the Windows sdk
		var windowsSDKProperties = ResolveToolsTask.GetSDKProperties("Windows", globalState)

		// Calculate the windows kits directory
		var windows10KitPath = Path.new(windowsSDKProperties["RootPath"])
		var windows10KitIncludePath = windows10KitPath + Path.new("./include/")
		var windows10KitBinPath = windows10KitPath + Path.new("./bin/")
		var windows10KitLibPath = windows10KitPath + Path.new("./Lib/")

		var windowsKitVersion = windowsSDKProperties["Version"]

		Soup.info("Using Windows Kit Version: %(windowsKitVersion)")
		var windows10KitVersionIncludePath = windows10KitIncludePath + Path.new(windowsKitVersion + "/")
		var windows10KitVersionBinPath = windows10KitBinPath + Path.new(windowsKitVersion + "/")
		var windows10KitVersionLibPath = windows10KitLibPath + Path.new(windowsKitVersion + "/")

		// Set the VC tools binary folder
		var vcToolsBinaryFolder
		var windosKitsBinaryFolder
		if (architecture == "x64") {
			vcToolsBinaryFolder = visualCompilerVersionFolder + Path.new("./bin/Hostx64/x64/")
			windosKitsBinaryFolder = windows10KitVersionBinPath + Path.new("x64/")
		} else if (architecture == "x86") {
			vcToolsBinaryFolder = visualCompilerVersionFolder + Path.new("./bin/Hostx64/x86/")
			windosKitsBinaryFolder = windows10KitVersionBinPath + Path.new("x86/")
		} else {
			Fiber.abort("Unknown architecture: %(architecture)")
		}

		var clToolPath = vcToolsBinaryFolder + Path.new("cl.exe")
		var linkToolPath = vcToolsBinaryFolder + Path.new("link.exe")
		var libToolPath = vcToolsBinaryFolder + Path.new("lib.exe")
		var mlToolPath = vcToolsBinaryFolder + Path.new("ml64.exe")
		var rcToolPath = windosKitsBinaryFolder + Path.new("rc.exe")

		// Save the build properties
		msvc["Version"] = visualCompilerVersion
		msvc["VCToolsRoot"] = visualCompilerVersionFolder.toString
		msvc["VCToolsBinaryRoot"] = vcToolsBinaryFolder.toString
		msvc["WindosKitsBinaryRoot"] = windosKitsBinaryFolder.toString
		msvc["LinkToolPath"] = linkToolPath.toString
		msvc["LibToolPath"] = libToolPath.toString
		msvc["RCToolPath"] = rcToolPath.toString
		msvc["MLToolPath"] = mlToolPath.toString

		// Allow custom overrides for the compiler path
		if (!msvc.containsKey("ClToolPath")) {
			msvc["ClToolPath"] = clToolPath.toString
		}

		// Set the include paths
		var platformIncludePaths = []
		if (!skipPlatform) {
			platformIncludePaths = [
				visualCompilerVersionFolder + Path.new("./include/"),
				windows10KitVersionIncludePath + Path.new("./ucrt/"),
				windows10KitVersionIncludePath + Path.new("./um/"),
				windows10KitVersionIncludePath + Path.new("./winrt/"),
				windows10KitVersionIncludePath + Path.new("./shared/"),
			]
		}

		// Set the include paths
		var platformLibraryPaths = []
		if (!skipPlatform) {
			if (architecture == "x64") {
				platformLibraryPaths.add(windows10KitVersionLibPath + Path.new("./ucrt/x64/"))
				platformLibraryPaths.add(windows10KitVersionLibPath + Path.new("./um/x64/"))
				platformLibraryPaths.add(visualCompilerVersionFolder + Path.new("./atlmfc/lib/x64/"))
				platformLibraryPaths.add(visualCompilerVersionFolder + Path.new("./lib/x64/"))
			} else if (architecture == "x86") {
				platformLibraryPaths.add(windows10KitVersionLibPath + Path.new("./ucrt/x86/"))
				platformLibraryPaths.add(windows10KitVersionLibPath + Path.new("./um/x86/"))
				platformLibraryPaths.add(visualCompilerVersionFolder + Path.new("./atlmfc/lib/x86/"))
				platformLibraryPaths.add(visualCompilerVersionFolder + Path.new("./lib/x86/"))
			}
		}

		// Set the platform definitions
		var platformPreprocessorDefinitions = [
			// "this.DLL", // Link against the dynamic runtime dll
			// "this.MT", // Use multithreaded runtime
		]

		if (architecture == "x86") {
			platformPreprocessorDefinitions.add("WIN32")
		}

		// Set the platform libraries
		var platformLibraries = [
			Path.new("kernel32.lib"),
			Path.new("user32.lib"),
			Path.new("gdi32.lib"),
			Path.new("winspool.lib"),
			Path.new("comdlg32.lib"),
			Path.new("advapi32.lib"),
			Path.new("shell32.lib"),
			Path.new("ole32.lib"),
			Path.new("oleaut32.lib"),
			Path.new("uuid.lib"),
			// Path("odbc32.lib"),
			// Path("odbccp32.lib"),
			// Path("crypt32.lib"),
		]

		// if (this.options.Configuration == "debug") {
		// 	// arguments.PlatformPreprocessorDefinitions.pushthis.back("this.DEBUG")
		// 	arguments.PlatformLibraries = std::vector<Path>({
		// 		Path("msvcprtd.lib"),
		// 		Path("msvcrtd.lib"),
		// 		Path("ucrtd.lib"),
		// 		Path("vcruntimed.lib"),
		// 	})
		// } else {
		// 	arguments.PlatformLibraries = std::vector<Path>({
		// 		Path("msvcprt.lib"),
		// 		Path("msvcrt.lib"),
		// 		Path("ucrt.lib"),
		// 		Path("vcruntime.lib"),
		// 	})
		// }

		build["PlatformIncludePaths"] = ListExtensions.ConvertFromPathList(platformIncludePaths)
		build["PlatformLibraryPaths"] = ListExtensions.ConvertFromPathList(platformLibraryPaths)
		build["PlatformLibraries"] = ListExtensions.ConvertFromPathList(platformLibraries)
		build["PlatformPreprocessorDefinitions"] = platformPreprocessorDefinitions
	}

	static LoadClang(globalState, activeState) {
		var clang = MapExtensions.EnsureTable(activeState, "Clang")

		// Find the Clang SDK
			Soup.info("%(globalState)")
		var clangSDKProperties = ResolveToolsTask.GetSDKProperties("Clang", globalState)

		var cCompilerPath = Path.new(clangSDKProperties["CCompiler"])
		var cppCompilerPath = Path.new(clangSDKProperties["CppCompiler"])
		var archiverPath = Path.new(clangSDKProperties["Archiver"])

		// Save the build properties
		clang["CCompiler"] = cCompilerPath.toString
		clang["CppCompiler"] = cppCompilerPath.toString
		clang["Archiver"] = archiverPath.toString
	}

	static GetSDKProperties(name, globalState) {
		for (sdk in globalState["SDKs"]) {
			if (sdk.containsKey("Name")) {
				var nameValue = sdk["Name"]
				if (nameValue == name) {
					return sdk["Properties"]
				}
			}
		}

		Fiber.abort("Missing SDK %(name)")
	}
}

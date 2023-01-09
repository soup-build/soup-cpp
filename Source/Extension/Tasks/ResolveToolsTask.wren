// <copyright file="ResolveToolsTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupExtension
import "../../Utils/Path" for Path
import "../../Utils/ListExtensions" for ListExtensions

/// <summary>
/// The recipe build task that knows how to build a single recipe
/// </summary>
class ResolveToolsTask is SoupExtension {
	/// <summary>
	/// Get the run before list
	/// </summary>
	static runBefore { [] }

	/// <summary>
	/// Get the run after list
	/// </summary>
	static runAfter { [] }

	/// <summary>
	/// The Core Execute task
	/// </summary>
	static evaluate() {
		var globalState = Soup.globalState
		var activeState = Soup.activeState
		var parameters = globalState["Parameters"]

		var systemName = parameters["System"]
		var architectureName = parameters["Architecture"]

		if (systemName != "win32") {
			Fiber.abort("Win32 is the only supported system... so far.")
		}

		// Check if skip platform includes was specified
		var skipPlatform = false
		if (activeState.containsKey("SkipPlatform")) {
			skipPlatform = activeState["SkipPlatform"]
		}

		// Find the MSVC SDK
		var msvcSDKProperties = ResolveToolsTask.GetSDKProperties("MSVC", parameters)

		// Use the default version
		var visualCompilerVersion = msvcSDKProperties["Version"]
		Soup.debug("Using VC Version: %(visualCompilerVersion)")

		// Get the final VC tools folder
		var visualCompilerVersionFolder = Path.new(msvcSDKProperties["VCToolsRoot"])

		// Load the Windows sdk
		var windowsSDKProperties = ResolveToolsTask.GetSDKProperties("Windows", parameters)

		// Calculate the windows kits directory
		var windows10KitPath = Path.new(windowsSDKProperties["RootPath"])
		var windows10KitIncludePath = windows10KitPath + Path.new("./include/")
		var windows10KitBinPath = windows10KitPath + Path.new("./bin/")
		var windows10KitLibPath = windows10KitPath + Path.new("./Lib/")

		var windowsKitVersion = windowsSDKProperties["Version"]

		Soup.debug("Using Windows Kit Version: %(windowsKitVersion)")
		var windows10KitVersionIncludePath = windows10KitIncludePath + Path.new(windowsKitVersion + "/")
		var windows10KitVersionBinPath = windows10KitBinPath + Path.new(windowsKitVersion + "/")
		var windows10KitVersionLibPath = windows10KitLibPath + Path.new(windowsKitVersion + "/")

		// Set the VC tools binary folder
		var vcToolsBinaryFolder
		var windosKitsBinaryFolder
		if (architectureName == "x64") {
			vcToolsBinaryFolder = visualCompilerVersionFolder + Path.new("./bin/Hostx64/x64/")
			windosKitsBinaryFolder = windows10KitVersionBinPath + Path.new("x64/")
		} else if (architectureName == "x86") {
			vcToolsBinaryFolder = visualCompilerVersionFolder + Path.new("./bin/Hostx64/x86/")
			windosKitsBinaryFolder = windows10KitVersionBinPath + Path.new("x86/")
		} else {
			Fiber.abort("Unknown architecture.")
		}

		var clToolPath = vcToolsBinaryFolder + Path.new("cl.exe")
		var linkToolPath = vcToolsBinaryFolder + Path.new("link.exe")
		var libToolPath = vcToolsBinaryFolder + Path.new("lib.exe")
		var mlToolPath = vcToolsBinaryFolder + Path.new("ml64.exe")
		var rcToolPath = windosKitsBinaryFolder + Path.new("rc.exe")

		// Save the build properties
		activeState["MSVC.Version"] = visualCompilerVersion
		activeState["MSVC.VCToolsRoot"] = visualCompilerVersionFolder.toString
		activeState["MSVC.VCToolsBinaryRoot"] = vcToolsBinaryFolder.toString
		activeState["MSVC.WindosKitsBinaryRoot"] = windosKitsBinaryFolder.toString
		activeState["MSVC.LinkToolPath"] = linkToolPath.toString
		activeState["MSVC.LibToolPath"] = libToolPath.toString
		activeState["MSVC.RCToolPath"] = rcToolPath.toString
		activeState["MSVC.MLToolPath"] = mlToolPath.toString

		// Allow custom overrides for the compiler path
		if (!activeState.containsKey("MSVC.ClToolPath")) {
			activeState["MSVC.ClToolPath"] = clToolPath.toString
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
			if (architectureName == "x64") {
				platformLibraryPaths.add(windows10KitVersionLibPath + Path.new("./ucrt/x64/"))
				platformLibraryPaths.add(windows10KitVersionLibPath + Path.new("./um/x64/"))
				platformLibraryPaths.add(visualCompilerVersionFolder + Path.new("./atlmfc/lib/x64/"))
				platformLibraryPaths.add(visualCompilerVersionFolder + Path.new("./lib/x64/"))
			} else if (architectureName == "x86") {
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

		if (architectureName == "x86") {
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

		activeState["PlatformIncludePaths"] = ListExtensions.ConvertFromPathList(platformIncludePaths)
		activeState["PlatformLibraryPaths"] = ListExtensions.ConvertFromPathList(platformLibraryPaths)
		activeState["PlatformLibraries"] = ListExtensions.ConvertFromPathList(platformLibraries)
		activeState["PlatformPreprocessorDefinitions"] = platformPreprocessorDefinitions
	}

	static GetSDKProperties(name, state) {
		for (sdk in state["SDKs"]) {
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

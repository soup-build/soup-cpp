## Recipe Build

This task reads in the global state Recipe to translate the declared build into the input build state for the Build task.

### Run Before
**BuildTask** - Ensure this task sets the build state for Recipe definition before attempting to build.

### Run After
**InitializeDefaultsTask** - Ensure default values are finalized before being using build flavor and compiler.

**ResolveToolsTask** - Currently, loads in the platform dependencies that are set by the resolve tools... TODO: Remove.

### Input
* Global State
  * **Context**
    * **PackageDirectory** - Use package directory to resolve recipe references.
    * **TargetDirectory** - Use target directory to set output.
  * **Recipe**
    * **Name** - Set output names to match package name.
    * **PlatformLibraries** - Allow for direct references to platform libraries.
    * **LinkLibraries** - Allow for direct references to link libraries.
    * **RuntimeDependencies** - Allow for direct references to runtime libraries.
    * **IncludePaths** - Allow for direct references to include paths.
    * **Defines** - Allow for manual creation of global macro definitions.
    * **Resources** - List of resource files to be compiled.
    * **Partitions** - Module Partition Units that will have explicit dependencies defined.
    * **Interface** - The single Module Interface Unit that exposes all shared symbols to downstream dependencies.
    * **Source** - The list of plain old Translation Units to compile.
    * **AssemblySource** - The list of assembly source files to compile.
    * **PublicHeaders** - The list of public header files that will be shared with downstream dependencies includes.
    * **EnableWarningsAsErrors** - A flag that enables warnings as errors. Default to true.
    * **Type** - The type of the package, Can be StaticLibrary, DynamicLibrary, Executable or WindowsApplication (TODO: Can this be removed?). Default is StaticLibrary.
    * **LanguageVersion** - The C++ Language Version, Default is C++20.

## Output
* Active State
  * **Build** - TODO
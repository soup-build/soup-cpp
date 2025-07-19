## Resolve Dependencies
This task reads in the global state dependencies to reference required dependencies compiler time and runtime resources.

### Run Before
**BuildTask** - Ensure this task sets the build state  before attempting to build.

### Run After
None

### Input
* Global State
  * **Dependencies**
    * **Runtime** - Iterate over all Runtime dependencies to include their resources in the build.

## Output
* Active State
  * **Build**
    * **ModuleDependencies** - Adds compiled module interfaces to reference during compilation.
    * **RuntimeDependencies** - Adds any runtime dependencies that will be copied over to the output directory for runtime.
    * **LinkDependencies** - Adds to the list of libraries and object files that will be included during linking.
    * **PublicInclude** - A list of public include folders that will be used to resolve public header files.
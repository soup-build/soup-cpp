## Resolve Tools
This task reads in the global state SDKs to reference required platform resources and Compiler information.

### Run Before
**BuildTask** - Ensure this task sets the build state for Recipe definition before attempting to build.

### Run After
**InitializeDefaultsTask** - Ensure defaults are set before using them to select the platform.

### Input
* Global State
  * **SDKs**
    * **MSVC** - On Windows use the MSVC SDK.
    * **Windows** - On Windows use the Windows SDK.

## Output
* Active State
  * **Build** - TODO
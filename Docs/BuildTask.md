## Build

This task that converts the setup build table into final build operations. It is run last to allow for multiple different sources to initialize the build table and override default values to extend properties through the official and external build extensions.

### Run Before
None

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
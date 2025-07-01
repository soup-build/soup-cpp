## Initialize Defaults
This task reads in the global state context and parameters to initialize the default build parameters for the current host platform. It then allows the user to override the defaults by checking for matching parameters passed in through the command line interface. 

For example this task will select the default compiler and system based on the host platform. On Windows it will use the MSVC compiler to target Win32.

### Run Before
**BuildTask** - Ensure setup is performed before the core build.

### Run After
None

### Input
* Global State
  * **Parameters**
    * **Architecture** - Allow override of the Architecture for the build passed in through the command line.
    * **Flavor** - Allow override of the Flavor for the build passed in through the command line.
  * **Context**
    * **HostPlatform** - Used to determine the default compiler and system to use based on the current host machine.

## Output
* Active State
  * **Build**
    * **Architecture** - The target architecture (x64, x86, etc)
    * **Compiler** - The compiler to use (MSVC, GCC, Clang, etc).
    * **Flavor** -The high level build flavor (Debug, Release, etc)
    * **System** - The target system (Win32, etc)
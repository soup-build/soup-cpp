import "./Compiler/Core.UnitTests/BuildEngineUnitTests" for BuildEngineUnitTests
import "./Compiler/MSVC.UnitTests/MSVCArgumentBuilderUnitTests" for MSVCArgumentBuilderUnitTests
import "./Compiler/MSVC.UnitTests/MSVCCompilerUnitTests" for MSVCCompilerUnitTests
import "./Compiler/MSVC.UnitTests/MSVCLinkerArgumentBuilderUnitTests" for MSVCLinkerArgumentBuilderUnitTests
import "./Compiler/MSVC.UnitTests/MSVCResourceCompileArgumentBuilderUnitTests" for MSVCResourceCompileArgumentBuilderUnitTests
import "./Extension.UnitTests/Tasks/BuildTaskUnitTests" for BuildTaskUnitTests
import "./Extension.UnitTests/Tasks/RecipeBuildTaskUnitTests" for RecipeBuildTaskUnitTests
import "./Extension.UnitTests/Tasks/ResolveToolsTaskUnitTests" for ResolveToolsTaskUnitTests

var uut

// Compiler.Core.UnitTests
uut = BuildEngineUnitTests.new()
uut.RunTests()

// Compiler.MSVC.UnitTests
uut = MSVCArgumentBuilderUnitTests.new()
uut.RunTests()
uut = MSVCCompilerUnitTests.new()
uut.RunTests()
uut = MSVCLinkerArgumentBuilderUnitTests.new()
uut.RunTests()
uut = MSVCResourceCompileArgumentBuilderUnitTests.new()
uut.RunTests()

// Extension.UnitTests
uut = BuildTaskUnitTests.new()
uut.RunTests()
uut = RecipeBuildTaskUnitTests.new()
uut.RunTests()
uut = ResolveToolsTaskUnitTests.new()
uut.RunTests()

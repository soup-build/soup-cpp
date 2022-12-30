import "./Utils.UnitTests/PathUnitTests" for PathUnitTests
import "./Compiler/Core.UnitTests/BuildEngineUnitTests" for BuildEngineUnitTests
import "./Compiler/MSVC.UnitTests/MSVCArgumentBuilderUnitTests" for MSVCArgumentBuilderUnitTests
import "./Compiler/MSVC.UnitTests/MSVCCompilerUnitTests" for MSVCCompilerUnitTests
import "./Compiler/MSVC.UnitTests/MSVCLinkerArgumentBuilderUnitTests" for MSVCLinkerArgumentBuilderUnitTests
import "./Compiler/MSVC.UnitTests/MSVCResourceCompileArgumentBuilderUnitTests" for MSVCResourceCompileArgumentBuilderUnitTests

var uut

// Utils.UnitTests
uut = PathUnitTests.new()
uut.RunTests()

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
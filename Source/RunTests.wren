import "./Utils.UnitTests/PathUnitTests" for PathUnitTests
import "./Compiler/Core.UnitTests/BuildEngineUnitTests" for BuildEngineUnitTests

var uut

uut = PathUnitTests.new()
uut.RunTests()

uut = BuildEngineUnitTests.new()
uut.RunTests()

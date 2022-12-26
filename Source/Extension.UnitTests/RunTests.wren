import "./Tasks/BuildTaskUnitTests" for BuildTaskUnitTests
import "./Tasks/RecipeBuildTaskUnitTests" for RecipeBuildTaskUnitTests
import "./Tasks/ResolveToolsTaskUnitTests" for ResolveToolsTaskUnitTests

var uut = BuildTaskUnitTests.new()
uut.RunTests()

uut = RecipeBuildTaskUnitTests.new()
uut.RunTests()

uut = ResolveToolsTaskUnitTests.new()
uut.RunTests()

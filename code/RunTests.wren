import "./Compiler/Core.UnitTests/BuildEngineUnitTests" for BuildEngineUnitTests
import "./Compiler/Clang.UnitTests/ClangArgumentBuilderUnitTests" for ClangArgumentBuilderUnitTests
import "./Compiler/Clang.UnitTests/ClangCompilerUnitTests" for ClangCompilerUnitTests
import "./Compiler/Clang.UnitTests/ClangLinkerArgumentBuilderUnitTests" for ClangLinkerArgumentBuilderUnitTests
import "./Compiler/Clang.UnitTests/ClangResourceCompileArgumentBuilderUnitTests" for ClangResourceCompileArgumentBuilderUnitTests
import "./Compiler/GCC.UnitTests/GCCArgumentBuilderUnitTests" for GCCArgumentBuilderUnitTests
import "./Compiler/GCC.UnitTests/GCCCompilerUnitTests" for GCCCompilerUnitTests
import "./Compiler/GCC.UnitTests/GCCLinkerArgumentBuilderUnitTests" for GCCLinkerArgumentBuilderUnitTests
import "./Compiler/GCC.UnitTests/GCCResourceCompileArgumentBuilderUnitTests" for GCCResourceCompileArgumentBuilderUnitTests
import "./Compiler/MSVC.UnitTests/MSVCArgumentBuilderUnitTests" for MSVCArgumentBuilderUnitTests
import "./Compiler/MSVC.UnitTests/MSVCCompilerUnitTests" for MSVCCompilerUnitTests
import "./Compiler/MSVC.UnitTests/MSVCLinkerArgumentBuilderUnitTests" for MSVCLinkerArgumentBuilderUnitTests
import "./Compiler/MSVC.UnitTests/MSVCResourceCompileArgumentBuilderUnitTests" for MSVCResourceCompileArgumentBuilderUnitTests
import "./Extension.UnitTests/Tasks/BuildTaskUnitTests" for BuildTaskUnitTests
import "./Extension.UnitTests/Tasks/InitializeDefaultsTaskUnitTests" for InitializeDefaultsTaskUnitTests
import "./Extension.UnitTests/Tasks/RecipeBuildTaskUnitTests" for RecipeBuildTaskUnitTests
import "./Extension.UnitTests/Tasks/ResolveToolsTaskUnitTests" for ResolveToolsTaskUnitTests

var uut

// Compiler.Core.UnitTests
uut = BuildEngineUnitTests.new()
uut.RunTests()

// Compiler.Clang.UnitTests
uut = ClangArgumentBuilderUnitTests.new()
uut.RunTests()
uut = ClangCompilerUnitTests.new()
uut.RunTests()
uut = ClangLinkerArgumentBuilderUnitTests.new()
uut.RunTests()
uut = ClangResourceCompileArgumentBuilderUnitTests.new()
uut.RunTests()

// Compiler.GCC.UnitTests
uut = GCCArgumentBuilderUnitTests.new()
uut.RunTests()
uut = GCCCompilerUnitTests.new()
uut.RunTests()
uut = GCCLinkerArgumentBuilderUnitTests.new()
uut.RunTests()
uut = GCCResourceCompileArgumentBuilderUnitTests.new()
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
uut = InitializeDefaultsTaskUnitTests.new()
uut.RunTests()
uut = RecipeBuildTaskUnitTests.new()
uut.RunTests()
uut = ResolveToolsTaskUnitTests.new()
uut.RunTests()

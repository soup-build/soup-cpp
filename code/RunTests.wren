import "./compiler/core-tests/BuildEngineUnitTests" for BuildEngineUnitTests
import "./compiler/clang-tests/ClangArgumentBuilderUnitTests" for ClangArgumentBuilderUnitTests
import "./compiler/clang-tests/ClangCompilerUnitTests" for ClangCompilerUnitTests
import "./compiler/clang-tests/ClangLinkerArgumentBuilderUnitTests" for ClangLinkerArgumentBuilderUnitTests
import "./compiler/clang-tests/ClangResourceCompileArgumentBuilderUnitTests" for ClangResourceCompileArgumentBuilderUnitTests
import "./compiler/gcc-tests/GCCArgumentBuilderUnitTests" for GCCArgumentBuilderUnitTests
import "./compiler/gcc-tests/GCCCompilerUnitTests" for GCCCompilerUnitTests
import "./compiler/gcc-tests/GCCLinkerArgumentBuilderUnitTests" for GCCLinkerArgumentBuilderUnitTests
import "./compiler/gcc-tests/GCCResourceCompileArgumentBuilderUnitTests" for GCCResourceCompileArgumentBuilderUnitTests
import "./compiler/msvc-tests/MSVCArgumentBuilderUnitTests" for MSVCArgumentBuilderUnitTests
import "./compiler/msvc-tests/MSVCCompilerUnitTests" for MSVCCompilerUnitTests
import "./compiler/msvc-tests/MSVCLinkerArgumentBuilderUnitTests" for MSVCLinkerArgumentBuilderUnitTests
import "./compiler/msvc-tests/MSVCResourceCompileArgumentBuilderUnitTests" for MSVCResourceCompileArgumentBuilderUnitTests
import "./extension-tests/tasks/BuildTaskUnitTests" for BuildTaskUnitTests
import "./extension-tests/tasks/InitializeDefaultsTaskUnitTests" for InitializeDefaultsTaskUnitTests
import "./extension-tests/tasks/RecipeBuildTaskUnitTests" for RecipeBuildTaskUnitTests
import "./extension-tests/tasks/ResolveToolsTaskUnitTests" for ResolveToolsTaskUnitTests

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

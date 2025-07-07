import "./compiler/core-tests/build-engine-unit-tests" for BuildEngineUnitTests
import "./compiler/clang-tests/clang-argument-builder-unit-tests" for ClangArgumentBuilderUnitTests
import "./compiler/clang-tests/clang-compiler-unit-tests" for ClangCompilerUnitTests
import "./compiler/clang-tests/clang-linker-argument-builder-unit-tests" for ClangLinkerArgumentBuilderUnitTests
import "./compiler/clang-tests/clang-resource-compile-argument-builder-unit-tests" for ClangResourceCompileArgumentBuilderUnitTests
import "./compiler/gcc-tests/gcc-argument-builder-unit-tests" for GCCArgumentBuilderUnitTests
import "./compiler/gcc-tests/gcc-compiler-unit-tests" for GCCCompilerUnitTests
import "./compiler/gcc-tests/gcc-linker-argument-builder-unit-tests" for GCCLinkerArgumentBuilderUnitTests
import "./compiler/gcc-tests/gcc-resource-compile-argument-builder-unit-tests" for GCCResourceCompileArgumentBuilderUnitTests
import "./compiler/msvc-tests/msvc-argument-builder-unit-tests" for MSVCArgumentBuilderUnitTests
import "./compiler/msvc-tests/msvc-compiler-unit-tests" for MSVCCompilerUnitTests
import "./compiler/msvc-tests/msvc-linker-argument-builder-unit-tests" for MSVCLinkerArgumentBuilderUnitTests
import "./compiler/msvc-tests/msvc-resource-compile-argument-builder-unit-tests" for MSVCResourceCompileArgumentBuilderUnitTests
import "./extension-tests/tasks/build-task-unit-tests" for BuildTaskUnitTests
import "./extension-tests/tasks/initialize-defaults-task-unit-tests" for InitializeDefaultsTaskUnitTests
import "./extension-tests/tasks/recipe-build-task-unit-tests" for RecipeBuildTaskUnitTests
import "./extension-tests/tasks/resolve-tools-task-unit-tests" for ResolveToolsTaskUnitTests

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

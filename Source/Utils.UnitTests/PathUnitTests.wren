// <copyright file="PathTests.cs" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../Utils/Path" for Path
import "../Test/Assert" for Assert

class PathUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("PathUnitTests.DefaultInitializer()")
		this.DefaultInitializer()
		System.print("PathUnitTests.Empty()")
		this.Empty()
		System.print("PathUnitTests.RelativePath_Simple()")
		this.RelativePath_Simple()
		System.print("PathUnitTests.RelativePath_Parent()")
		this.RelativePath_Parent()
		System.print("PathUnitTests.RelativePath_Complex()")
		this.RelativePath_Complex()
		System.print("PathUnitTests.LinuxRoot()")
		this.LinuxRoot()
		System.print("PathUnitTests.SimpleAbsolutePath()")
		this.SimpleAbsolutePath()
		System.print("PathUnitTests.AlternativeDirectoriesPath()")
		this.AlternativeDirectoriesPath()
		System.print("PathUnitTests.RemoveEmptyDirectoryInside()")
		this.RemoveEmptyDirectoryInside()
		System.print("PathUnitTests.RemoveParentDirectoryInside()")
		this.RemoveParentDirectoryInside()
		System.print("PathUnitTests.RemoveTwoParentDirectoryInside()")
		this.RemoveTwoParentDirectoryInside()
		System.print("PathUnitTests.LeaveParentDirectoryAtStart()")
		this.LeaveParentDirectoryAtStart()
		System.print("PathUnitTests.CurrentDirectoryAtStart()")
		this.CurrentDirectoryAtStart()
		System.print("PathUnitTests.CurrentDirectoryAtStartAlternate()")
		this.CurrentDirectoryAtStartAlternate()
		System.print("PathUnitTests.Concatenate_Simple()")
		this.Concatenate_Simple()
		System.print("PathUnitTests.Concatenate_Empty()")
		this.Concatenate_Empty()
		System.print("PathUnitTests.Concatenate_RootFile()")
		this.Concatenate_RootFile()
		System.print("PathUnitTests.Concatenate_RootFolder()")
		this.Concatenate_RootFolder()
		System.print("PathUnitTests.Concatenate_UpDirectory()")
		this.Concatenate_UpDirectory()
		System.print("PathUnitTests.Concatenate_UpDirectoryBeginning()")
		this.Concatenate_UpDirectoryBeginning()
		System.print("PathUnitTests.SetFileExtension_Replace()")
		this.SetFileExtension_Replace()
		System.print("PathUnitTests.SetFileExtension_Replace_Rooted()")
		this.SetFileExtension_Replace_Rooted()
		System.print("PathUnitTests.SetFileExtension_Add()")
		this.SetFileExtension_Add()
		System.print("PathUnitTests.GetRelativeTo_Empty()")
		this.GetRelativeTo_Empty()
		System.print("PathUnitTests.GetRelativeTo_SingleRelative()")
		this.GetRelativeTo_SingleRelative()
		System.print("PathUnitTests.GetRelativeTo_UpParentRelative()")
		this.GetRelativeTo_UpParentRelative()
		System.print("PathUnitTests.GetRelativeTo_MismatchRelative()")
		this.GetRelativeTo_MismatchRelative()
		System.print("PathUnitTests.GetRelativeTo_Rooted_DifferentRoot()")
		this.GetRelativeTo_Rooted_DifferentRoot()
		System.print("PathUnitTests.GetRelativeTo_Rooted_SingleFolder()")
		this.GetRelativeTo_Rooted_SingleFolder()
	}

	DefaultInitializer() {
		var uut = Path.new()
		Assert.False(uut.HasRoot)
		Assert.False(uut.HasFileName)
		Assert.Equal("", uut.GetFileName())
		Assert.False(uut.HasFileStem)
		Assert.Equal("", uut.GetFileStem())
		Assert.False(uut.HasFileExtension)
		Assert.Equal("", uut.GetFileExtension())
		Assert.Equal("./", uut.toString)
		Assert.Equal(".\\", uut.ToAlternateString())
	}

	Empty() {
		var uut = Path.new("")
		Assert.False(uut.HasRoot)
		Assert.False(uut.HasFileName)
		Assert.Equal("", uut.GetFileName())
		Assert.False(uut.HasFileStem)
		Assert.Equal("", uut.GetFileStem())
		Assert.False(uut.HasFileExtension)
		Assert.Equal("", uut.GetFileExtension())
		Assert.Equal("./", uut.toString)
		Assert.Equal(".\\", uut.ToAlternateString())
	}

	RelativePath_Simple() {
		var uut = Path.new("./")
		Assert.False(uut.HasRoot)
		Assert.False(uut.HasFileName)
		Assert.Equal("", uut.GetFileName())
		Assert.False(uut.HasFileStem)
		Assert.Equal("", uut.GetFileStem())
		Assert.False(uut.HasFileExtension)
		Assert.Equal("", uut.GetFileExtension())
		Assert.Equal("./", uut.toString)
		Assert.Equal(".\\", uut.ToAlternateString())
	}

	RelativePath_Parent() {
		var uut = Path.new("../")
		Assert.False(uut.HasRoot)
		Assert.False(uut.HasFileName)
		Assert.Equal("", uut.GetFileName())
		Assert.False(uut.HasFileStem)
		Assert.Equal("", uut.GetFileStem())
		Assert.False(uut.HasFileExtension)
		Assert.Equal("", uut.GetFileExtension())
		Assert.Equal("../", uut.toString)
		Assert.Equal("..\\", uut.ToAlternateString())
	}

	RelativePath_Complex() {
		var uut = Path.new("myfolder/anotherfolder/file.txt")
		Assert.False(uut.HasRoot)
		Assert.True(uut.HasFileName)
		Assert.Equal("file.txt", uut.GetFileName())
		Assert.True(uut.HasFileStem)
		Assert.Equal("file", uut.GetFileStem())
		Assert.True(uut.HasFileExtension)
		Assert.Equal(".txt", uut.GetFileExtension())
		Assert.Equal("./myfolder/anotherfolder/file.txt", uut.toString)
		Assert.Equal(".\\myfolder\\anotherfolder\\file.txt", uut.ToAlternateString())
	}

	LinuxRoot() {
		var uut = Path.new("/")
		Assert.True(uut.HasRoot)
		Assert.Equal("", uut.GetRoot())
		Assert.False(uut.HasFileName)
		Assert.Equal("", uut.GetFileName())
		Assert.False(uut.HasFileStem)
		Assert.Equal("", uut.GetFileStem())
		Assert.False(uut.HasFileExtension)
		Assert.Equal("", uut.GetFileExtension())
		Assert.Equal("/", uut.toString)
		Assert.Equal("\\", uut.ToAlternateString())
	}

	SimpleAbsolutePath() {
		var uut = Path.new("C:/myfolder/anotherfolder/file.txt")
		Assert.True(uut.HasRoot)
		Assert.Equal("C:", uut.GetRoot())
		Assert.True(uut.HasFileName)
		Assert.Equal("file.txt", uut.GetFileName())
		Assert.True(uut.HasFileStem)
		Assert.Equal("file", uut.GetFileStem())
		Assert.True(uut.HasFileExtension)
		Assert.Equal(".txt", uut.GetFileExtension())
		Assert.Equal("C:/myfolder/anotherfolder/file.txt", uut.toString)
	}

	AlternativeDirectoriesPath() {
		var uut = Path.new("C:\\myfolder/anotherfolder\\file.txt")
		Assert.True(uut.HasRoot)
		Assert.Equal("C:", uut.GetRoot())
		Assert.True(uut.HasFileName)
		Assert.Equal("file.txt", uut.GetFileName())
		Assert.True(uut.HasFileStem)
		Assert.Equal("file", uut.GetFileStem())
		Assert.True(uut.HasFileExtension)
		Assert.Equal(".txt", uut.GetFileExtension())
		Assert.Equal("C:/myfolder/anotherfolder/file.txt", uut.toString)
	}

	RemoveEmptyDirectoryInside() {
		var uut = Path.new("C:/myfolder//file.txt")
		Assert.Equal("C:/myfolder/file.txt", uut.toString)
	}

	RemoveParentDirectoryInside() {
		var uut = Path.new("C:/myfolder/../file.txt")
		Assert.Equal("C:/file.txt", uut.toString)
	}

	RemoveTwoParentDirectoryInside() {
		var uut = Path.new("C:/myfolder/myfolder2/../../file.txt")
		Assert.Equal("C:/file.txt", uut.toString)
	}

	LeaveParentDirectoryAtStart() {
		var uut = Path.new("../file.txt")
		Assert.Equal("../file.txt", uut.toString)
	}

	CurrentDirectoryAtStart() {
		var uut = Path.new("./file.txt")
		Assert.Equal("./file.txt", uut.toString)
	}

	CurrentDirectoryAtStartAlternate() {
		var uut = Path.new(".\\../file.txt")
		Assert.Equal("../file.txt", uut.toString)
	}

	Concatenate_Simple() {
		var path1 = Path.new("C:/MyRootFolder")
		var path2 = Path.new("MyFolder/MyFile.txt")
		var uut = path1 + path2

		Assert.Equal("C:/MyRootFolder/MyFolder/MyFile.txt", uut.toString)
	}

	Concatenate_Empty() {
		var path1 = Path.new("C:/MyRootFolder")
		var path2 = Path.new("")
		var uut = path1 + path2

		// Changes the assumed file into a folder
		Assert.Equal("C:/MyRootFolder/", uut.toString)
	}

	Concatenate_RootFile() {
		var path1 = Path.new("C:")
		var path2 = Path.new("MyFile.txt")
		var uut = path1 + path2

		Assert.Equal("C:/MyFile.txt", uut.toString)
	}

	Concatenate_RootFolder() {
		var path1 = Path.new("C:")
		var path2 = Path.new("MyFolder/")
		var uut = path1 + path2

		Assert.Equal("C:/MyFolder/", uut.toString)
	}

	Concatenate_UpDirectory() {
		var path1 = Path.new("C:/MyRootFolder")
		var path2 = Path.new("../NewRoot/MyFile.txt")
		var uut = path1 + path2

		Assert.Equal("C:/NewRoot/MyFile.txt", uut.toString)
	}

	Concatenate_UpDirectoryBeginning() {
		var path1 = Path.new("../MyRootFolder")
		var path2 = Path.new("../NewRoot/MyFile.txt")
		var uut = path1 + path2

		Assert.Equal("../NewRoot/MyFile.txt", uut.toString)
	}

	SetFileExtension_Replace() {
		var uut = Path.new("../MyFile.txt")
		uut.SetFileExtension("awe")

		Assert.Equal("../MyFile.awe", uut.toString)
	}

	SetFileExtension_Replace_Rooted() {
		var uut = Path.new("C:/MyFolder/MyFile.txt")
		uut.SetFileExtension("awe")

		Assert.Equal("C:/MyFolder/MyFile.awe", uut.toString)
	}

	SetFileExtension_Add() {
		var uut = Path.new("../MyFile")
		uut.SetFileExtension("awe")

		Assert.Equal("../MyFile.awe", uut.toString)
	}

	GetRelativeTo_Empty() {
		var uut = Path.new("File.txt")
		var basePath = Path.new("")

		var result = uut.GetRelativeTo(basePath)

		Assert.Equal("./File.txt", result.toString)
	}

	GetRelativeTo_SingleRelative() {
		var uut = Path.new("Folder/File.txt")
		var basePath = Path.new("Folder/")

		var result = uut.GetRelativeTo(basePath)

		Assert.Equal("./File.txt", result.toString)
	}

	GetRelativeTo_UpParentRelative() {
		var uut = Path.new("../Folder/Target")
		var basePath = Path.new("../Folder")

		var result = uut.GetRelativeTo(basePath)

		Assert.Equal("./Target", result.toString)
	}

	GetRelativeTo_MismatchRelative() {
		var uut = Path.new("Folder1/File.txt")
		var basePath = Path.new("Folder2/")

		var result = uut.GetRelativeTo(basePath)

		Assert.Equal("../Folder1/File.txt", result.toString)
	}

	GetRelativeTo_Rooted_DifferentRoot() {
		var uut = Path.new("C:/Folder1/File.txt")
		var basePath = Path.new("D:/Folder2/")

		var result = uut.GetRelativeTo(basePath)

		Assert.Equal("C:/Folder1/File.txt", result.toString)
	}

	GetRelativeTo_Rooted_SingleFolder() {
		var uut = Path.new("C:/Folder1/File.txt")
		var basePath = Path.new("C:/Folder1/")

		var result = uut.GetRelativeTo(basePath)

		Assert.Equal("./File.txt", result.toString)
	}
}

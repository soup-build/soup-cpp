// <copyright file="PathTests.cs" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "./Path" for Path
import "./Assert" for Assert

class PathUnitTests {
	construct new() {
	}

	RunTests() {
		this.DefaultInitializer()
		this.Empty()
		this.RelativePath_Simple()
		this.RelativePath_Parent()
		this.RelativePath_Complex()
		this.LinuxRoot()
		this.SimpleAbsolutePath()
		this.AlternativeDirectoriesPath()
		this.RemoveEmptyDirectoryInside()
		this.RemoveParentDirectoryInside()
		this.RemoveTwoParentDirectoryInside()
		this.LeaveParentDirectoryAtStart()
		this.CurrentDirectoryAtStart()
		this.CurrentDirectoryAtStartAlternate()
		this.Concatenate_Simple()
		this.Concatenate_Empty()
		this.Concatenate_RootFile()
		this.Concatenate_RootFolder()
		this.Concatenate_UpDirectory()
		this.Concatenate_UpDirectoryBeginning()
		this.SetFileExtension_Replace()
		this.SetFileExtension_Replace_Rooted()
		this.SetFileExtension_Add()
		this.GetRelativeTo_Empty()
		this.GetRelativeTo_SingleRelative()
		this.GetRelativeTo_UpParentRelative()
		this.GetRelativeTo_MismatchRelative()
		this.GetRelativeTo_Rooted_DifferentRoot()
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
		Assert.Equal("./", uut.ToString())
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
		Assert.Equal("./", uut.ToString())
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
		Assert.Equal("./", uut.ToString())
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
		Assert.Equal("../", uut.ToString())
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
		Assert.Equal("./myfolder/anotherfolder/file.txt", uut.ToString())
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
		Assert.Equal("/", uut.ToString())
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
		Assert.Equal("C:/myfolder/anotherfolder/file.txt", uut.ToString())
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
		Assert.Equal("C:/myfolder/anotherfolder/file.txt", uut.ToString())
	}

	RemoveEmptyDirectoryInside() {
		var uut = Path.new("C:/myfolder//file.txt")
		Assert.Equal("C:/myfolder/file.txt", uut.ToString())
	}

	RemoveParentDirectoryInside() {
		var uut = Path.new("C:/myfolder/../file.txt")
		Assert.Equal("C:/file.txt", uut.ToString())
	}

	RemoveTwoParentDirectoryInside() {
		var uut = Path.new("C:/myfolder/myfolder2/../../file.txt")
		Assert.Equal("C:/file.txt", uut.ToString())
	}

	LeaveParentDirectoryAtStart() {
		var uut = Path.new("../file.txt")
		Assert.Equal("../file.txt", uut.ToString())
	}

	CurrentDirectoryAtStart() {
		var uut = Path.new("./file.txt")
		Assert.Equal("./file.txt", uut.ToString())
	}

	CurrentDirectoryAtStartAlternate() {
		var uut = Path.new(".\\../file.txt")
		Assert.Equal("../file.txt", uut.ToString())
	}

	Concatenate_Simple() {
		var path1 = Path.new("C:/MyRootFolder")
		var path2 = Path.new("MyFolder/MyFile.txt")
		var uut = path1 + path2

		Assert.Equal("C:/MyRootFolder/MyFolder/MyFile.txt", uut.ToString())
	}

	Concatenate_Empty() {
		var path1 = Path.new("C:/MyRootFolder")
		var path2 = Path.new("")
		var uut = path1 + path2

		// Changes the assumed file into a folder
		Assert.Equal("C:/MyRootFolder/", uut.ToString())
	}

	Concatenate_RootFile() {
		var path1 = Path.new("C:")
		var path2 = Path.new("MyFile.txt")
		var uut = path1 + path2

		Assert.Equal("C:/MyFile.txt", uut.ToString())
	}

	Concatenate_RootFolder() {
		var path1 = Path.new("C:")
		var path2 = Path.new("MyFolder/")
		var uut = path1 + path2

		Assert.Equal("C:/MyFolder/", uut.ToString())
	}

	Concatenate_UpDirectory() {
		var path1 = Path.new("C:/MyRootFolder")
		var path2 = Path.new("../NewRoot/MyFile.txt")
		var uut = path1 + path2

		Assert.Equal("C:/NewRoot/MyFile.txt", uut.ToString())
	}

	Concatenate_UpDirectoryBeginning() {
		var path1 = Path.new("../MyRootFolder")
		var path2 = Path.new("../NewRoot/MyFile.txt")
		var uut = path1 + path2

		Assert.Equal("../NewRoot/MyFile.txt", uut.ToString())
	}

	SetFileExtension_Replace() {
		var uut = Path.new("../MyFile.txt")
		uut.SetFileExtension("awe")

		Assert.Equal("../MyFile.awe", uut.ToString())
	}

	SetFileExtension_Replace_Rooted() {
		var uut = Path.new("C:/MyFolder/MyFile.txt")
		uut.SetFileExtension("awe")

		Assert.Equal("C:/MyFolder/MyFile.awe", uut.ToString())
	}

	SetFileExtension_Add() {
		var uut = Path.new("../MyFile")
		uut.SetFileExtension("awe")

		Assert.Equal("../MyFile.awe", uut.ToString())
	}

	GetRelativeTo_Empty() {
		var uut = Path.new("File.txt")
		var basePath = Path.new("")

		var result = uut.GetRelativeTo(basePath)

		Assert.Equal("./File.txt", result.ToString())
	}

	GetRelativeTo_SingleRelative() {
		var uut = Path.new("Folder/File.txt")
		var basePath = Path.new("Folder/")

		var result = uut.GetRelativeTo(basePath)

		Assert.Equal("./File.txt", result.ToString())
	}

	GetRelativeTo_UpParentRelative() {
		var uut = Path.new("../Folder/Target")
		var basePath = Path.new("../Folder")

		var result = uut.GetRelativeTo(basePath)

		Assert.Equal("./Target", result.ToString())
	}

	GetRelativeTo_MismatchRelative() {
		var uut = Path.new("Folder1/File.txt")
		var basePath = Path.new("Folder2/")

		var result = uut.GetRelativeTo(basePath)

		Assert.Equal("../Folder1/File.txt", result.ToString())
	}

	GetRelativeTo_Rooted_DifferentRoot() {
		var uut = Path.new("C:/Folder1/File.txt")
		var basePath = Path.new("D:/Folder2/")

		var result = uut.GetRelativeTo(basePath)

		Assert.Equal("C:/Folder1/File.txt", result.ToString())
	}

	GetRelativeTo_Rooted_SingleFolder() {
		var uut = Path.new("C:/Folder1/File.txt")
		var basePath = Path.new("C:/Folder1/")

		var result = uut.GetRelativeTo(basePath)

		Assert.Equal("./File.txt", result.ToString())
	}
}

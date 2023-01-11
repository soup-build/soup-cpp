// <copyright file="Path.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

/// <summary>
/// A container for a path string
/// ROOT: The optional root of the path, if not present then the path is relative and must
/// start with either the RelativeParentDirectory or RelativeDirectory special symbols
///  '/' - Rooted in the current drive
///  'A-Z:' - Rooted in a letter drive (Windows Specific)
///  '//' - Server root.
/// </summary>
class Path {
	// string _value
	// int _rootEndLocation
	// int _fileNameStartLocation

	/// <summary>
	/// Initializes a new instance of the <see cref="Path"/> class.
	/// </summary>
	construct new() {
		_value = ""
		this.SetState([ Path.RelativeDirectory ], null, null)
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Path"/> class.
	/// </summary>
	/// <param name="value">The value.</param>
	construct new(value) {
		_value = ""
		this.ParsePath(value)
	}

	/// <summary>
	/// Gets a value indicating whether the path is empty.
	/// </summary>
	IsEmpty { _value == "./" }

	/// <summary>
	/// Gets a value indicating whether the path has a root.
	/// </summary>
	HasRoot { _rootEndLocation >= 0 }

	static DirectorySeparator { "/" }

	static AlternateDirectorySeparator { "\\" }

	static AllValidDirectorySeparators { [ "/", "\\" ] }

	static LetterDriveSpecifier { ":" }

	static FileExtensionSeparator { "." }

	static RelativeDirectory { "." }

	static RelativeParentDirectory { ".." }

	==(rhs) {
		// System.print("Path: %(this)==%(rhs)")
		if (rhs is Null) {
			return false
		} else {
			return _value == rhs.toString
		}
	}

	!=(rhs) {
		if (rhs is Null) {
			return false
		} else {
			return _value != rhs.toString
		}
	}

	/// <summary>
	/// Concatenate paths.
	/// </summary>
	/// <param name="lhs">The left hand side.</param>
	/// <param name="rhs">The right hand side.</param>
	+(rhs) {
		if (rhs.HasRoot) {
			Fiber.abort("Cannot combine a rooted path on the right hand side: %(rhs)")
		}

		// Combine the directories
		var resultDirectories = Path.DecomposeDirectoriesString(this.GetDirectories())

		// Convert the left hand side filename to a directory
		if (this.HasFileName) {
			resultDirectories.add(this.GetFileName())
		}

		var rhsDirectories = Path.DecomposeDirectoriesString(rhs.GetDirectories())
		resultDirectories = resultDirectories + rhsDirectories

		Path.NormalizeDirectories(resultDirectories, this.HasRoot)

		// Set the state with the root from the LHS and the filename from the RHS
		var result = Path.new()
		result.SetState(
			resultDirectories,
			this.HasRoot ? this.GetRoot() : null,
			rhs.HasFileName ? rhs.GetFileName() : null)

		return result
	}

	/// <summary>
	/// Gets the path root.
	/// </summary>
	GetRoot() {
		if (_rootEndLocation < 0) {
			Fiber.abort("Cannot access root on path that has none")
		}
		return _value[0..._rootEndLocation]
	}

	/// <summary>
	/// Gets the parent directory.
	/// </summary>
	GetParent() {
		var result = Path.new()

		// Take the root from the left hand side
		result.rootEndLocation = _rootEndLocation

		// If there is a filename then return the directory
		// Otherwise return one less directory
		if (this.HasFileName) {
			// Pass along the path minus the filename
			result.value = _value[0..._fileNameStartLocation]
			result.fileNameStartLocation = result.value.count
		} else {
			// Pull apart the directories and remove the last one
			// TODO: This can be done in place and then a substring returned for perf gains
			var directories = Path.DecomposeDirectoriesString(this.GetDirectories())
			if (directories.count == 0) {
				// No-op when at the root
			} else if (directories.count == 1 && directories[0] == Path.RelativeDirectory) {
				// If this is only a relative folder symbol then replace with the parent symbol
				directories[0] = Path.RelativeParentDirectory
			} else if (directories.Last() == Path.RelativeParentDirectory) {
				// If this is entirely parent directories then add one more
				directories.add(Path.RelativeParentDirectory)
			} else {
				// Otherwise pop off the top level folder
				directories.removeAt(directories.count - 1)
			}

			// Set the state of the result path
			result.SetState(
				directories,
				this.HasRoot ? this.GetRoot() : null,
				null)
		}

		return result
	}

	/// <summary>
	/// Gets a value indicating whether the path has a file name.
	/// </summary>
	HasFileName { _fileNameStartLocation < _value.count }

	/// <summary>
	/// Gets the file name.
	/// </summary>
	GetFileName() {
		// Use the start location to return the end of the value that is the filename
		if (_fileNameStartLocation >= _value.count) {
			return ""
		} else {
			return _value[_fileNameStartLocation..._value.count]
		}
	}

	/// <summary>
	/// Gets a value indicating whether the file name has a stem.
	/// </summary>
	HasFileStem { this.GetFileStem() != "" }

	/// <summary>
	/// Gets the file name minus the extension.
	/// </summary>
	GetFileStem() {
		// Everything before the last period is the stem
		var fileName = this.GetFileName()
		var lastSeparator = this.LastIndexOf(fileName, Path.FileExtensionSeparator)
		if (lastSeparator != -1) {
			return fileName[0...lastSeparator]
		} else {
			// Return the entire filename if no extension
			return fileName
		}
	}

	/// <summary>
	/// Gets a value indicating whether the file name has an extension.
	/// </summary>
	HasFileExtension { this.GetFileExtension() != "" }

	/// <summary>
	/// Gets the file extension.
	/// </summary>
	GetFileExtension() {
		// Everything after and including the last period is the extension
		var fileName = this.GetFileName()
		var lastSeparator = this.LastIndexOf(fileName, Path.FileExtensionSeparator)
		if (lastSeparator != -1) {
			return fileName[lastSeparator...fileName.count]
		} else {
			return ""
		}
	}

	/// <summary>
	/// Set the filename.
	/// </summary>
	/// <param name="value">The value.</param>
	SetFilename(value) {
		// Build the new final string
		this.SetState(
			Path.DecomposeDirectoriesString(this.GetDirectories()),
			this.HasRoot ? this.GetRoot() : null,
			value)
	}

	/// <summary>
	/// Set the file extension.
	/// </summary>
	/// <param name="value">The value.</param>
	SetFileExtension(value) {
		// Build up the new filename and set the active state
		this.SetFilename("%(this.GetFileStem())%(Path.FileExtensionSeparator)%(value)")
	}

	/// <summary>
	/// Get a path relative to the provided base.
	/// </summary>
	/// <param name="basePath">The base path.</param>
	GetRelativeTo(basePath) {
		// If the root does not match then there is no way to get a relative path
		// simply return a copy of this path
		if ((basePath.HasRoot && this.HasRoot && basePath.GetRoot() != this.GetRoot()) ||
			(basePath.HasRoot != this.HasRoot)) {
			return this
		}

		// Force the base filenames as directories
		var baseDirectories = Path.DecomposeDirectoriesString(basePath.GetDirectories())
		if (basePath.HasFileName) {
			baseDirectories.add(basePath.GetFileName())
		}

		// Determine how many of the directories match
		var directories = Path.DecomposeDirectoriesString(this.GetDirectories())
		var minDirectories = baseDirectories.count.min(directories.count)
		var countMatching = 0
		for (i in 0...minDirectories) {
			if (baseDirectories[i] != directories[i]) {
				break
			}

			countMatching = countMatching + 1
		}

		// Add in up directories for any not matching in the base
		var resultDirectories = []
		if (countMatching == baseDirectories.count) {
			// Start with a single relative directory when no up directories required
			resultDirectories.add(Path.RelativeDirectory)
		} else {
			for (i in countMatching...baseDirectories.count) {
				resultDirectories.add(Path.RelativeParentDirectory)
			}
		}

		// Copy over the remaining entities from the target path
		for (i in countMatching...directories.count) {
			resultDirectories.add(directories[i])
		}

		// Set the result path with no root
		var result = Path.new()
		result.SetState(
			resultDirectories,
			null,
			this.HasFileName ? this.GetFileName() : null)

		return result
	}

	/// <summary>
	/// Convert to string
	/// </summary>
	toString { _value }

	ToAlternateString() {
		// Replace all normal separators with the windows version
		var result = _value.replace(Path.DirectorySeparator, Path.AlternateDirectorySeparator)
		return result
	}

	static IsRelativeDirectory(directory) {
		return directory == Path.RelativeDirectory || directory == Path.RelativeParentDirectory
	}

	static DecomposeDirectoriesString(value) {
		var current = 0
		var next = 0
		var directories = []
		while (current < value.count && (next = value.indexOf(Path.DirectorySeparator, current)) != -1) {
			var directory = value[current...next]
			if (directory != "") {
				directories.add(directory)
			}

			current = next + 1
		}

		// Ensure the last separator was at the end of the string
		if (current != value.count) {
			Fiber.abort("The directories string must end in a separator: %(value)")
		}

		return directories
	}

	static IsRoot(value) {
		if (value.count == 0) {
			// Empty value is root
			return true
		} else if (value.count == 2) {
			// Check for drive letter
			if (Path.IsLetter(value[0]) && value[1] == this.LetterDriveSpecifier) {
				return true
			}
		}

		return false
	}

	/// <summary>
	/// Resolve any up directory tokens or empty (double separator) directories that are inside a path.
	/// </summary>
	static NormalizeDirectories(directories, hasRoot) {
		// Remove as many up directories as we can
		var i = 0
		while (i < directories.count) {
			// Remove empty directories (double separator) or relative directories if rooted or not at start
			if (directories[i] == "" ||
				((hasRoot || i != 0) && directories[i] == Path.RelativeDirectory)) {
				directories.removeAt(i)
				i = i - 1
			} else {
				// Check if we can combine any parent directories
				// Allow the first directory to remain a parent
				if (i != 0) {
					// Remove a parent directory if possible
					if (directories[i] == Path.RelativeParentDirectory &&
						directories[i - 1] != Path.RelativeParentDirectory) {
						// If the previous is a relative then just replace it
						if (directories[i - 1] == Path.RelativeDirectory) {
							directories.removeAt(i - 1)
							i = i - 1
						} else {
							// Remove the directories and move back
							directories.removeAt(i)
							directories.removeAt(i - 1)
							i = i - 2
						}
					}
				}
			}

			i = i + 1
		}
	}

	ParsePath(value) {
		// Break out the individual components of the path
		var decomposeResult = this.DecomposeRawPathString(value)
		var directories = decomposeResult[0]
		var root = decomposeResult[1]
		var fileName = decomposeResult[2]

		// Normalize any unnecessary directories in the raw path
		var hasRoot = !(root is Null)
		Path.NormalizeDirectories(directories, hasRoot)

		// Rebuild the string value
		this.SetState(
			directories,
			root,
			fileName)
	}

	DecomposeRawPathString(value) {
		var directories = []
		var root = null
		var fileName = null

		var current = 0
		var next
		var isFirst = true
		while ((next = this.IndexOfAny(value, Path.AllValidDirectorySeparators, current)) != -1) {
			var directory = value[current...next]
			// Check if the first entry is a root
			if (isFirst) {
				if (Path.IsRoot(directory)) {
					root = directory
				} else {
					// Ensure that the unrooted path starts with a relative symbol
					if (!Path.IsRelativeDirectory(directory)) {
						directories.add(Path.RelativeDirectory)
					}

					directories.add(directory)
				}

				isFirst = false
			} else {
				directories.add(directory)
			}

			current = next + 1
		}

		// Check if there are characters beyond the last separator
		if (current != value.count) {
			var directory = value[current...value.count]

			// Check if still on the first entry
			// Could be empty root or single filename
			if (isFirst) {
				if (Path.IsRoot(directory)) {
					root = directory
				} else {
					// Ensure that the unrooted path starts with a relative symbol
					if (!Path.IsRelativeDirectory(directory)) {
						directories.add(Path.RelativeDirectory)
					}

					fileName = directory
				}

				isFirst = false
			} else {
				fileName = directory
			}
		}

		// If we saw nothing then add a single relative directory
		if (isFirst) {
			directories.add(Path.RelativeDirectory)
		}

		return [ directories, root, fileName ]
	}

	/// <summary>
	/// Convert the components of the path into the string value.
	/// </summary>
	SetState(directories, root, fileName) {
		var stringBuilder = ""

		if (!(root is Null)) {
			stringBuilder = stringBuilder + root
			stringBuilder = stringBuilder + Path.DirectorySeparator
		}

		for (directory in directories) {
			stringBuilder = stringBuilder + directory
			stringBuilder = stringBuilder + Path.DirectorySeparator
		}

		if (!(fileName is Null)) {
			stringBuilder = stringBuilder + fileName
		}

		// Store the persistant state
		_value = stringBuilder

		if (root is Null) {
			_rootEndLocation = -1
		} else {
			_rootEndLocation = root.count
		}

		if (fileName is Null) {
			_fileNameStartLocation = _value.count
		} else {
			_fileNameStartLocation = _value.count - fileName.count
		}
	}

	GetDirectories() {
		if (_rootEndLocation >= 0) {
			return _value[_rootEndLocation..._fileNameStartLocation]
		} else {
			return _value[0..._fileNameStartLocation]
		}
	}

	LastIndexOf(value, search) {
		var lastIndex = value.indexOf(search)
		var currentIndex = lastIndex
		while (currentIndex != -1) {
			currentIndex = value.indexOf(search, currentIndex + 1)
			if (currentIndex != -1) {
				lastIndex = currentIndex
			}
		}

		return lastIndex
	}

	IndexOfAny(value, searchList, start) {
		if (value == "" || value.count <= start) {
			return -1
		}

		var index = -1
		for (search in searchList) {
			var findIndex = value.indexOf(search, start)
			// Find the first of any of the requested search terms
			if (findIndex != -1 && 
				(index == -1 || findIndex < index)) {
				index = findIndex
			}
		}

		return index
	}

	static IsLetter(value) {
		if (value.count != 1) {
			Fiber.abort("IsLetter requires a string with a single character")
		}

		var character = value.bytes[0]
		if (character >= 0x0041 && character <= 0x005A) {
			// LATIN CAPITAL LETTER A-Z
			return true
		} else if (character >= 0x0061 && character <= 0x007A) {
			// LATIN SMALL LETTER a-z
			return true
		} else {
			return false
		}
	}
}

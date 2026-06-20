// <copyright file="main.cpp" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <stdexcept>
#include <iostream>
#include <memory>
#include <vector>

import Opal;
import json11;
import Soup.SML;

using namespace Opal;
using namespace Soup::SML;

#pragma warning(disable:4996)

void SplitArguments(
	std::vector<std::string> &unusedArgs,
	std::vector<std::string> &splitArgs) {
	auto flagValue = std::string("--");
	auto flagLocation = std::find(unusedArgs.begin(), unusedArgs.end(), flagValue);
	if (flagLocation != unusedArgs.end()) {
		// Consume the flag value
		auto argsStart = std::next(flagLocation);
		std::move(argsStart, unusedArgs.end(), std::back_inserter(splitArgs));
		unusedArgs.erase(flagLocation, unusedArgs.end());
	}
}

json11::Json RunChild(const Path& executable, const std::vector<std::string>& arguments)
{
	Log::Info("Running Child");
	Log::Diag(executable.ToString());

	// Execute the requested target
	auto process = System::IProcessManager::Current().CreateProcess(
		executable, arguments, Path(), true);
	process->Start();
	process->WaitForExit();

	Log::Diag("Child StdOut: {}", process->GetStandardOutput());
	Log::Diag("Child StdErr {}", process->GetStandardError());
	auto exitCode = process->GetExitCode();

	if (exitCode != 0) {
		Log::Error("Child Failed: {}", exitCode);
		throw std::runtime_error("child failed");
	}

	std::string error;
	auto result = json11::Json::parse(process->GetStandardOutput(), error);

	if (!error.empty()) {
		Log::Error("Failed to parse child json: {}", error);
		throw std::runtime_error("child result invalid");
	}

	return result;
}

SMLDocument ConvertResult(const json11::Json::object& root)
{
	Log::Info("Convert result");
	auto version = root.at("version").int_value();
	auto revision = root.at("revision").int_value();

	if (version != 1)
		throw std::runtime_error("Unknown result version");
	if (revision < 0)
		throw std::runtime_error("Unknown result revision");

	bool isModule = false;
	bool isInterface = false;
	std::string moduleName = "";
	std::vector<SMLValue> imports = {};

	auto rules = root.at("rules").array_items();
	if (rules.size() != 1)
		throw std::runtime_error("Expected exactly one rule since we invoked directly");

	auto rule = rules.at(0).object_items();

	// Check for optional provides
	auto providesResult = rule.find("provides");
	if (providesResult != rule.end()) {
		auto provides = providesResult->second.array_items();
		if (provides.size() != 1) 
			throw std::runtime_error("Provides must have exactly one item");

		auto providesItem = provides.at(0).object_items();
		isModule = true;
		isInterface = providesItem["is-interface"].bool_value();
		moduleName = providesItem["logical-name"].string_value();
	}

	// Check for optional requires
	auto requiresResult = rule.find("requires");
	if (requiresResult != rule.end()) {
		auto requiresList = requiresResult->second.array_items();
		for (auto& requiredItem : requiresList) {
			auto& requiredObject = requiredItem.object_items();
			auto requiredModule = requiredObject.at("logical-name").string_value();
			imports.push_back(SMLValue(std::move(requiredModule)));
		}
	}

	auto result = SequenceMap<std::string, SMLValue>();
	result.Insert("IsModule", SMLValue(isModule));
	if (isModule)
	{
		result.Insert("IsInterface", SMLValue(isInterface));
		result.Insert("Name", SMLValue(moduleName));
	}

	result.Insert("Imports", SMLValue(SMLArray(imports)));

	return SMLDocument(SMLTable(result));
}

// Adapter layer for child process that conforms to the describe dependencies standard
// https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2022/p1689r5.html
int main(int argc, char** argv)
{
	try
	{
		// Setup the filter
		auto defaultTypes =
			// static_cast<uint32_t>(TraceEventFlag::Diagnostic) |
			// static_cast<uint32_t>(TraceEventFlag::Information) |
			static_cast<uint32_t>(TraceEventFlag::HighPriority) |
			static_cast<uint32_t>(TraceEventFlag::Warning) |
			static_cast<uint32_t>(TraceEventFlag::Error) |
			static_cast<uint32_t>(TraceEventFlag::Critical);
		auto filter = std::make_shared<EventTypeFilter>(
			static_cast<TraceEventFlag>(defaultTypes));

		// Setup the console listener
		Log::RegisterListener(
			std::make_shared<ConsoleTraceListener>(
				"Log",
				filter,
				false,
				false,
				false));

		// Setup the real services
		System::IFileSystem::Register(std::make_shared<System::STLFileSystem>());

#if defined(_WIN32)
		System::IProcessManager::Register(
			std::make_shared<System::WindowsProcessManager>());
#elif defined(__linux__)
		System::IProcessManager::Register(std::make_shared<System::LinuxProcessManager>());
#else
#error "Unknown Platform"
#endif

		std::vector<std::string> arguments;
		for (int i = 1; i < argc; i++) {
			arguments.push_back(argv[i]);
		}

		std::vector<std::string> childArguments;
		SplitArguments(arguments, childArguments);

		if (arguments.size() > 0)
		{
			Log::Error("Invalid parameters. Expected only child arguments.");
			return -1;
		}

		if (childArguments.size() < 2)
		{
			Log::Error("Invalid parameters. Child must have at least an executable.");
			return -1;
		}

		auto childExecutable = Path::Parse(childArguments[0]);
		childArguments.erase(childArguments.begin());
		auto scanResult = RunChild(childExecutable, childArguments);
		auto result = ConvertResult(scanResult.object_items());

		Log::Info("Send to std out");
		std::cout << result << std::flush;
	}
	catch (const std::exception& ex)
	{
		Log::Error(ex.what());
		return -1;
	}
}
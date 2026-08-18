#pragma once

#include <windows.h>
#include <cstdio>
#include <cstdarg>

namespace FS::Log
{

	/// <summary>
	/// Print a formatted message to the debugger (visible in DebugView, VS
	/// Output window, or any debugger attached to gamemd.exe). Uses
	/// OutputDebugStringA so it works without depending on any game internals.
	/// Safe to call from DllMain/SyringeHandshake and from hooks.
	/// </summary>
	inline void Print(const char* fmt, ...)
	{
		char buffer[2048];
		va_list args;
		va_start(args, fmt);
		const int n = vsnprintf(buffer, sizeof(buffer), fmt, args);
		va_end(args);
		if (n > 0)
			OutputDebugStringA(buffer);
	}

} // namespace FS::Log

#ifndef FS_LOG
#define FS_LOG(...) ::FS::Log::Print(__VA_ARGS__)
#endif

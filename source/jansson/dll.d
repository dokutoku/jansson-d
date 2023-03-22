module jansson.dll;


version (Windows):
version (JANSSON_D_DYNAMIC_LIBRARY):

version (D_BetterC) {
} else {
	version = Not_BetterC;
}

private static import core.sys.windows.windef;
private static import core.sys.windows.winnt;

version (D_BetterC)
extern (Windows)
pure nothrow @safe @nogc @live
public core.sys.windows.windef.BOOL DllMain(core.sys.windows.windef.HINSTANCE hModule, core.sys.windows.windef.DWORD fdwReason, core.sys.windows.winnt.LPVOID lpvReserved)

	do
	{
		return core.sys.windows.windef.TRUE;
	}

version (Not_BetterC)
extern (Windows)
public core.sys.windows.windef.BOOL DllMain(core.sys.windows.windef.HINSTANCE hModule, core.sys.windows.windef.DWORD fdwReason, core.sys.windows.winnt.LPVOID lpvReserved)

	do
	{
		switch (fdwReason) {
			case core.sys.windows.winnt.DLL_PROCESS_ATTACH:
				core.sys.windows.dll.dll_process_attach(hModule);

				break;

			case core.sys.windows.winnt.DLL_PROCESS_DETACH:
				core.sys.windows.dll.dll_process_detach(hModule);

				break;

			case core.sys.windows.winnt.DLL_THREAD_ATTACH:
				core.sys.windows.dll.dll_thread_attach(true, true);

				break;

			case core.sys.windows.winnt.DLL_THREAD_DETACH:
				core.sys.windows.dll.dll_thread_detach(true, true);

				break;

			default:
				break;
		}

		return core.sys.windows.windef.TRUE;
	}

module jansson_d.dll;


version (Windows):
version (JANSSON_D_DYNAMIC_LIBRARY):

private static import core.sys.windows.basetsd;
private static import core.sys.windows.windef;
private static import core.sys.windows.winnt;
private static import core.sys.windows.dll;


extern (Windows)
export core.sys.windows.windef.BOOL DllMain(core.sys.windows.basetsd.HANDLE hModule, core.sys.windows.windef.DWORD reasonForCall, core.sys.windows.winnt.LPVOID lpReserved)

	do
	{
		switch (reasonForCall) {
			case core.sys.windows.winnt.DLL_PROCESS_ATTACH:
				return core.sys.windows.dll.dll_process_attach(hModule, true);

			case core.sys.windows.winnt.DLL_PROCESS_DETACH:
				core.sys.windows.dll.dll_process_detach(hModule, true);

				return core.sys.windows.windef.TRUE;

			case core.sys.windows.winnt.DLL_THREAD_ATTACH:
				return core.sys.windows.dll.dll_thread_attach(true, true);

			case core.sys.windows.winnt.DLL_THREAD_DETACH:
				return core.sys.windows.dll.dll_thread_detach(true, true);

			default:
				return core.sys.windows.windef.TRUE;
		}
	}

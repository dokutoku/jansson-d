module jansson_d.dll;


version (Windows):
version (JANSSON_D_DYNAMIC_LIBRARY):

private static import core.sys.windows.basetsd;
private static import core.sys.windows.windef;
private static import core.sys.windows.winnt;

extern (Windows)
pure nothrow @safe @nogc @live
export core.sys.windows.windef.BOOL DllMain(core.sys.windows.basetsd.HANDLE hModule, core.sys.windows.windef.DWORD reasonForCall, core.sys.windows.winnt.LPVOID lpReserved)

	do
	{
		return core.sys.windows.windef.TRUE;
	}

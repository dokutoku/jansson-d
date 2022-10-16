module jansson.dll;


version (Windows):
version (JANSSON_D_DYNAMIC_LIBRARY):

private static import core.sys.windows.windef;
private static import core.sys.windows.winnt;

extern (Windows)
pure nothrow @safe @nogc @live
public core.sys.windows.windef.BOOL DllMain(core.sys.windows.windef.HINSTANCE hModule, core.sys.windows.windef.DWORD fdwReason, core.sys.windows.winnt.LPVOID lpvReserved)

	do
	{
		return core.sys.windows.windef.TRUE;
	}

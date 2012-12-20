/**
 * \file   os_isdir.c
 * \brief  Returns true if the specified directory exists.
 * \author Copyright (c) 2002-2008 Jason Perkins and the Premake project
 */

#include <string.h>
#include <sys/stat.h>
#include "premake.h"

#if PLATFORM_WINDOWS
# include <Windows.h>
// fake lstat sets Stat.st_mode's S_IFDIR bit only 
static int lstat(const char *Filename, struct stat* Stat)
{
	DWORD dwAttr = GetFileAttributes(Filename);
	if (dwAttr == INVALID_FILE_ATTRIBUTES) {
		return -1;
	}	
	if (dwAttr & FILE_ATTRIBUTE_DIRECTORY) {
		Stat->st_mode |= S_IFDIR;
	} else {
		Stat->st_mode &= ~S_IFDIR;
	}
	return 0;
}
#endif

int os_isdir(lua_State* L)
{
	struct stat buf;
	const char* path = luaL_checkstring(L, 1);

	/* empty path is equivalent to ".", must be true */
	if (strlen(path) == 0)
	{
		lua_pushboolean(L, 1);
	}
	else if (lstat(path, &buf) == 0)
	{
		lua_pushboolean(L, buf.st_mode & S_IFDIR);
	}	
	else
	{
		lua_pushboolean(L, 0);
	}

	return 1;
}



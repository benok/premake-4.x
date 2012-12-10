--
-- _radstudio.lua
-- Define the RAD Studio 2010-XE* actions.
-- Copyright (c) 2008-2011 Jason Perkins and the Premake project
--

	premake.radstudio = { }
	local radstudio = premake.radstudio

	premake.radstudio.rs2010 = { }
	premake.radstudio.rsxe = { }
	premake.radstudio.rsxe2 = { }
	premake.radstudio.rsxe3 = { }
	
--
-- Map Premake platform identifiers to the RAD Studio versions.
--
	radstudio.platforms = { 
		Native  = "Win32",
		Generic = "Base",		-- used for base config
		x32     = "Win32", 
		x64     = "Win64",
		Universal32	= "OSX32",
		Universal64	= "OSX64",
	}

	radstudio.rs2010.platforms = { 
		Native  = "Win32",
		Generic = "Base",		-- used for base config
		x32     = "Win32", 
	}

	radstudio.rsxe.platforms = { 
		Native  = "Win32",
		Generic = "Base",		-- used for base config
		x32     = "Win32", 
	}
	
	radstudio.rsxe2.platforms = { 
		Native  = "Win32",
		Generic = "Base",		-- used for base config
		x32     = "Win32", 
--		x64     = "Win64",		-- C++ Builder doesn't support x64
		Universal32	= "OSX32",
		Universal64	= "OSX64",
	}

	radstudio.rsxe3.platforms = { 
		Native  = "Win32",
		Generic = "Base",		-- used for base config
		x32     = "Win32", 
		x64     = "Win64",
		Universal32	= "OSX32",
		Universal64	= "OSX64",
	}
	
	radstudio.config_tree = {
		{name = "Base", parent = nil},
		{name = "Debug", parent = "Base"},
		{name = "Release", parent = "Base"},
	}

	-- map from premake's kind to RadStudio's AppType
	radstudio.app_types = {
		ConsoleApp = "Console",
		WindowedApp = "Application",
		StaticLib = "StaticLibrary",
		SharedLib = "Library",
	}
	
	-- 
	radstudio.frameworks = {
		vcl = "VCL",
		fmx = "FMX",
	}

--
-- Clean RAD Studio files
--

	function radstudio.cleansolution(sln)
		premake.clean.file(sln, "%%.groupproj")
	end
	
	function radstudio.cleanproject(prj)
		local fname = premake.project.getfilename(prj, "%%")

		os.remove(fname .. ".cbproj")
	end

	function radstudio.cleantarget(name)
		os.remove(name .. ".exe.manifest")
	end

--
-- Register RAD Studio 2010
--

	newaction 
	{
		trigger         = "rs2010",
		shortname       = "RAD Studio 2010",
		description     = "Generate Embarcadero RAD Studio 2010 project files",
		os              = "windows",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++" },
		
		valid_tools     = {
			cc     = { "bcc" },
		},

		onsolution = function(sln)
			premake.generate(sln, "%%.groupproj", radstudio.gproj2010.generate)
		end,
		
		onproject = function(prj)
			premake.generate(prj, "%%.cbproj", premake.radstudio.rs2010x.generate)
		end,
		
		oncleansolution = premake.radstudio.cleansolution,
		oncleanproject  = premake.radstudio.cleanproject,
		oncleantarget   = premake.radstudio.cleantarget
	}
	
--
-- Register RAD Studio XE
--

	newaction 
	{
		trigger         = "rsxe",
		shortname       = "RAD Studio XE",
		description     = "Generate Embarcadero RAD Studio XE project files",
		os              = "windows",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++" },
		
		valid_tools     = {
			cc     = { "bcc" },
		},

		onsolution = function(sln)
			premake.generate(sln, "%%.groupproj", radstudio.gproj2010.generate)
		end,
		
		onproject = function(prj)
			premake.generate(prj, "%%.cbproj", premake.radstudio.rs2010x.generate)
		end,
		
		oncleansolution = premake.radstudio.cleansolution,
		oncleanproject  = premake.radstudio.cleanproject,
		oncleantarget   = premake.radstudio.cleantarget
	}
	
--
-- Register RAD Studio XE2
--

	newaction 
	{
		trigger         = "rsxe2",
		shortname       = "RAD Studio XE2",
		description     = "Generate Embarcadero RAD Studio XE2 project files",
		os              = "windows",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++" },
		
		valid_tools     = {
			cc     = { "bcc" },
		},

		onsolution = function(sln)
			premake.generate(sln, "%%.groupproj", radstudio.gproj2010.generate)
		end,
		
		onproject = function(prj)
			premake.generate(prj, "%%.cbproj", premake.radstudio.rs2010x.generate)
		end,
		
		oncleansolution = premake.radstudio.cleansolution,
		oncleanproject  = premake.radstudio.cleanproject,
		oncleantarget   = premake.radstudio.cleantarget
	}
	
--
-- Register RAD Studio XE3
--

	newaction 
	{
		trigger         = "rsxe3",
		shortname       = "RAD Studio XE3",
		description     = "Generate Embarcadero RAD Studio XE3 project files",
		os              = "windows",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++" },
		
		valid_tools     = {
			cc     = { "bcc" },
		},

		onsolution = function(sln)
			premake.generate(sln, "%%.groupproj", radstudio.gproj2010.generate)
		end,
		
		onproject = function(prj)
			premake.generate(prj, "%%.cbproj", premake.radstudio.rs2010x.generate)
		end,
		
		oncleansolution = premake.radstudio.cleansolution,
		oncleanproject  = premake.radstudio.cleanproject,
		oncleantarget   = premake.radstudio.cleantarget
	}
	
--
-- Assemble the project file name.
--

	function radstudio.projectfile(prj)
		local extension
		extension = ".cbproj"
		local fname = path.join(prj.location, prj.name)
		return fname..extension
	end

--
--
--

function radstudio.write_utf8_bom()
	local prev_eol = io.eol
	io.eol = ''
	_p('\239\187\191')
	io.eol = prev_eol
end

-- --
-- -- Process the solution's list of configurations and platforms, creates a list
-- -- of build configuration/platform pairs in a RAD Studio compatible format.
-- --
-- 	function radstudio.buildconfigs(sln)
-- 		local cfgs = { }
-- 		
-- 		-- sln中のplatformから、radstudioでサポートされているものをtableで返す。中身はx86など。sln側の表現
-- 		local platforms = premake.filterplatforms(sln, radstudio.platforms, "Native")
-- 
-- 		-- sln中のすべてのconfigurationに対して、platforms毎に、
-- 		for _, buildcfg in ipairs(sln.configurations) do
-- 			for _, platform in ipairs(platforms) do
-- 				local entry = { }
-- 				entry.src_buildcfg = buildcfg          -- "Debug"など
-- 				entry.src_platform = platform          -- "x86"など
-- 				
-- 				entry.buildcfg = platform .. " " .. buildcfg     -- "x86 Debug"など
-- 				entry.platform = radstudio.platforms[platform]  -- "Win32"など
-- 				
-- 				-- create a name the way VS likes it 
-- 				entry.name = entry.buildcfg .. "|" .. entry.platform -- "x86 Debug|Win32"など　(不要そう)
-- 				
-- 				table.insert(cfgs, entry)
-- 			end
-- 		end
-- 		return cfgs		
-- 	end
-- 	
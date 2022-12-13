--
-- rs2010x_cbproj.lua
-- Generate a RAD Studio 2010-XE3 C/C++ project.
-- Copyright (c) 2009-2011 Jason Perkins and the Premake project
--


--
-- Set up a namespace for this file
--

	premake.radstudio.rs2010x = { }
	premake.radstudio.cbproj = { }
	
	local radstudio = premake.radstudio
	local rs2010x = premake.radstudio.rs2010x
	local cbproj = premake.radstudio.cbproj
	local tree = premake.tree

	-- map from premake's kind to CppBuilder's ProjectType
	radstudio.cbproj.project_types = {
		ConsoleApp = "CppConsoleApplication",
		WindowedApp = "CppVCLApplication", -- or FmxGuiApplication TODO: support switching platform 
		StaticLib = "CppStaticLibrary",
		SharedLib = "CppDynamicLibrary",
	}
	
--	ProjectType
--	'CppVCLApplication' -- VCL App
--	'CppConsoleApplication' -- Console App
--	'FmxGuiApplication' -- FireMonkey App
--	'CppDynamicLibrary' -- DLL
--  'CppStaticLibrary' -- Static Library
--	'Application' -- Service

--
-- Returns the project file version
--
-- http://owlsperspective.blogspot.com/p/delphi-versions.html

	function rs2010x.project_version()
		if _ACTION == "rs2010" then
			return "12.0"
		elseif _ACTION == "rsxe" then
			return "12.3"
		elseif _ACTION == "rsxe2" then
			return "13.4"
		elseif _ACTION == "rsxe3" then
			return "14.3"
		elseif _ACTION == "rs100" then
			return "18.0" -- 10 Seattle RTM
		elseif _ACTION == "rs101" then
			return "18.1" -- 10.1 Berlin RTM
		elseif _ACTION == "rs102" then
			return "18.2" -- 10.2 Tokyo RTM
		elseif _ACTION == "rs103" then
			return "18.5" -- 10.3 Rio RTM
		elseif _ACTION == "rs104" then
			return "19.0" -- 10.4 Sydney RTM
		elseif _ACTION == "rs110" then
			return "19.3" -- 11 Alexandria RTM
		end
	end

--
-- Return supports multiple platform or not
--
	function radstudio.supported_platforms()
		return radstudio[_ACTION].platforms
	end

	function rs2010x.supports_multiple_platform()
		return not((_ACTION == "rs2010") or (_ACTION == "rsxe"))
	end
	
	function rs2010x.listup_platforms()
		return (not (_ACTION == "rs2010")) and ((_ACTION >= "rsxe") or (_ACTION >= "rs100"))
	end

	function rs2010x.import_first()
		return (_ACTION == "rs2010") or (_ACTION == "rsxe")
	end

	function rs2010x.need_novcl()
		return (_ACTION == "rs2010") or (_ACTION == "rsxe")
	end
	
	local function _config_symbol(idx, platform)
		local result = ''
		if idx == 1 then
			result = "Base"
		else
			result = string.format("Cfg_%d", idx - 1)
		end
		if platform and platform ~= 'Base' then
			result = result .. '_' .. platform
		end
		return result
    end

	local function _config_cond_expr_on_define(name, idx, rad_platform)
		if rad_platform and rad_platform ~= 'Base' then
			local sym = _config_symbol(idx) -- Base, Cfg_1, Cfg_2, ...
			return string.format("('$(Platform)'=='%s' and '$(%s)'=='true') or '$(%s_%s)'!=''",	rad_platform, sym, sym, rad_platform)
		else
			return string.format("'$(Config)'=='%s' or '$(%s)'!=''", name, _config_symbol(idx))
		end			
	end
	
	local function _config_cond_expr_on_use(name, idx, rad_platform)
		local symbol = ''
		if rad_platform and rad_platform ~= 'Base' then			
			symbol = _config_symbol(idx, rad_platform)
		else
			symbol = _config_symbol(idx)
		end
		return string.format("'$(%s)'!=''",	symbol)
	end
		
	function rs2010x.config_definition_block(platform, radconf, idx)
--		print('**platform('.. platform ..')')		
		local rad_platform = radstudio.supported_platforms()[platform]
--		print('**config_definition_block('..rad_platform..','..radconf..','..idx..')')		
		_p(1,'<PropertyGroup Condition="%s">', _config_cond_expr_on_define(radconf, idx, rad_platform))
		    local sym = _config_symbol(idx, rad_platform)
			if sym ~= 'Base' then
				_p(2,'<%s>true</%s>', sym, sym) -- put self defined
			end
			if radconf ~= 'Base' then
				-- have parent
				if (rad_platform == nil) or (rad_platform == 'Base') then
					_p(2,'<CfgParent>%s</CfgParent>', 'Base')
				else
					local parent_sym = _config_symbol(idx)
--					printf('<CfgParent>%s</CfgParent>', parent_sym)
					_p(2,'<CfgParent>%s</CfgParent>', parent_sym)
					_p(2,'<%s>true</%s>', parent_sym, parent_sym)
				end
			else
				-- no parent
				if sym ~= 'Base' then -- not root
					_p(2,'<CfgParent>Base</CfgParent>')
				end
			end
			_p(2,'<Base>true</Base>')
		_p(1,'</PropertyGroup>')		
	end
	
	function rs2010x.config_definition_blocks(prj, platforms)
		for i, radconf in ipairs(radstudio.rstudio_configs()) do
			if rs2010x.supports_multiple_platform() then				
				-- multi platform
				for _, platform in ipairs(array_concat('_Base', platforms)) do
					rs2010x.config_definition_block(platform, radconf, i, true)
				end
			else
				-- single platform (x32=Win32) only
				rs2010x.config_definition_block('_Base', radconf, i, false)
			end
		end
	end

	function bcc_options(config)
		local cfg = config
		if cfg == nil then
			return
		end
		if cfg.flags.BccUseNewCompiler then
			_p(2, '<BCC_UseClassicCompiler>false</BCC_UseClassicCompiler>')
		end
		if cfg.flags.Symbols then
			_p(2, '<BCC_SourceDebuggingOn>true</BCC_SourceDebuggingOn>')
			_p(2, '<BCC_DebugLineNumbers>true</BCC_DebugLineNumbers>')
			-- compiler options for debug -- 
			_p(2, '<BCC_ExtendedErrorInfo>true</BCC_ExtendedErrorInfo>')
			_p(2, '<BCC_UseRegisterVariables>None</BCC_UseRegisterVariables>')
			_p(2, '<BCC_DisableOptimizations>true</BCC_DisableOptimizations>')
			_p(2, '<BCC_OptimizeForSpeed>false</BCC_OptimizeForSpeed>')
			-- linker options for debug -- 
			_p(2, '<ILINK_FullDebugInfo>true</ILINK_FullDebugInfo>')
			-- assembler options for debug --
			_p(2, '<TASM_DisplaySourceLines>true</TASM_DisplaySourceLines>')		
		end
		
		if cfg.flags.Optimize or cfg.flags.OptimizeSpeed then
			_p(2, '<BCC_OptimizeForSpeed>true</BCC_OptimizeForSpeed>')
			_p(2, '<BCC_UseRegisterVariables>None</BCC_UseRegisterVariables>')
		elseif cfg.flags.OptimizeSize then
			_p(2, '<BCC_OptimizeForSize>true</BCC_OptimizeForSize>')
			_p(2, '<BCC_UseRegisterVariables>None</BCC_UseRegisterVariables>')
		end
				
		if cfg.flags.NoPCH then
			_p(2, '<BCC_PCHUsage>None</BCC_PCHUsage>')
		end

		if cfg.flags.NoRTTI then
			_p(2, '<BCC_EnableRTTI>false</BCC_EnableRTTI>')
		end
		
		if cfg.flags.FatalWarnings then
			_p(2,'<BCC_WarningIsError>true</BCC_WarningIsError>')
		end
	end
	
	function rs2010x.config_block(prj, platform, radconf, idx)
--		print("platform:"..platform)
		local rad_platform = radstudio.supported_platforms()[platform]
		local conf_symbol = _config_symbol(idx, rad_platform)
--		print('**config_block('..rad_platform..','..radconf..','..idx..')')

		_p(1,'<PropertyGroup Condition="%s">', _config_cond_expr_on_use(radconf, idx, rad_platform))
			if conf_symbol == 'Base' then
				_p(2,'<ProjectType>%s</ProjectType>', radstudio.cbproj.project_types[prj.kind])
				_p(2,'<Multithreaded>true</Multithreaded>') -- always enabled. follow Visual Studio behaviour
				_p(2,'<RunBCCOutOfProcess>true</RunBCCOutOfProcess>') -- fix 'bcc32 exeited with code 1' error on low memory machine
				_p(2,'<TLIB_PageSize>512</TLIB_PageSize>') -- fix 'bcc32 exited with code 1' error on low memory machine
				--
				_p(2,'<_TCHARMapping>char</_TCHARMapping>') -- 
				_p(2,'<BCC_StackFrames>true</BCC_StackFrames>') -- standard stack frame: ON

				if (prj.kind == "ConsoleApp") and rs2010x.need_novcl() then
					_p(2,'<NoVCL>true</NoVCL>') -- this is required to 
				end
--				_p(2,'<OutputExt>lib</OutputExt>')
--				_p(2,'<DCC_CBuilderOutput>JPHNE</DCC_CBuilderOutput>')		-- Required ?
--				_p(2,'<DynamicRTL>true</DynamicRTL>')						-- Required ?
			end

			local cfg;
 			if rs2010x.supports_multiple_platform() then
				cfg = premake.getconfig(prj, radconf, platform)
			else
				cfg = premake.getconfig(prj, radconf, 'x32') -- only supports 'Win32'
			end
		
			if cfg and
				((rs2010x.supports_multiple_platform() and (rad_platform ~= 'Base'))
				or
				 (not rs2010x.supports_multiple_platform()))
			then
				if cfg.buildtarget.directory ~= '' then
					_p(2,'<FinalOutputDir>%s</FinalOutputDir>', premake.esc(cfg.buildtarget.directory))
				end
				if cfg.objectsdir ~= '' then
					_p(2,'<BRCC_OutputDir>%s</BRCC_OutputDir>', premake.esc(cfg.objectsdir))
					_p(2,'<IntermediateOutputDir>%s</IntermediateOutputDir>', premake.esc(cfg.objectsdir))
				end

				if #cfg.includedirs > 0 then
					_p(2,'<IncludePath>%s;$(IncludePath)</IncludePath>', premake.esc(path.translate(table.concat(cfg.includedirs, ";"), '\\')))
				end
				
				if #cfg.libdirs > 0 then
					_p(2,'<ILINK_LibraryPath>%s;$(ILINK_LibraryPath)</ILINK_LibraryPath>', premake.esc(path.translate(table.concat(cfg.libdirs, ';'), '\\')))
				end
				
				if #cfg.defines > 0 then
					_p(2, '<Defines>%s;$(Defines)</Defines>', table.concat(premake.esc(cfg.defines), ";"))
				end

				if (platform == 'x32') and (not cfg.flags.BccUseNewCompiler) and (#cfg.bcc_disable_warnings > 0) then	
					for _, item in ipairs(cfg.bcc_disable_warnings) do
						_p(2,'<BCC_%s>false</BCC_%s>', item, item)
					end
				end	

				if (((platform == 'x32') and (not cfg.flags.BccUseNewCompiler)) or (platform ~= 'x32')) and (#cfg.bcc_clang_options > 0) then
					_p(2,'<BCC_UserSuppliedOptions>%s</BCC_UserSuppliedOptions>', table.concat(cfg.bcc_clang_options, ' '))
				end
			end
		
			bcc_options(cfg)
		
		_p(1,'</PropertyGroup>')		   		
	end

	function rs2010x.config_blocks(prj, platforms)
		for i, radconf in ipairs(radstudio.rstudio_configs()) do
			if rs2010x.supports_multiple_platform() then
				-- multi platform
				for _, platform in ipairs(array_concat('_Base', platforms)) do
					rs2010x.config_block(prj, platform, radconf, i)
				end
			else
				-- single platform (x32=Win32) only
				rs2010x.config_block(prj, '_Base', radconf, i)
			end
		end
	end
	
	function rs2010x.get_file_extension(file)
		local ext_start,ext_end = string.find(file,"%.[%w_%-]+$")
		if ext_start then
			return  string.sub(file,ext_start+1,ext_end)
		end
	end


	local types = 
	{	
		h	= "_CppInclude",
		hpp	= "_CppInclude",
		hxx	= "_CppInclude",
		c	= "CppCompile",
		cpp	= "CppCompile",
		cxx	= "CppCompile",
		cc	= "CppCompile",
		lib = "LibFiles",
		a   = "LibFiles",
		rc  = "ResourceCompile",
	}
	
	local function action_type(filename)
		local ext = rs2010x.get_file_extension(filename)
		if ext then
			local _type = types[ext]
			if _type == "_CppInclude" then _type = 'None' end
			if _type == nil then _type = 'None' end
			return _type
		else
			return 'None'
		end
	end
	
	local function classify_input_files(files)
		local classified =
		{
			_CppInclude = {},
			CppCompile = {},
			LibFiles = {},
			None = {},
			All = {},
			ResourceCompile = {}
		}
		
		for _, current_file in ipairs(files) do
			local translated_path = path.translate(current_file, '\\')
			local ext = rs2010x.get_file_extension(translated_path)
			if ext then
				local type = types[ext]
				if type then
					table.insert(classified[type], translated_path)
				else
					table.insert(classified.None, translated_path)
				end
				table.insert(classified.All, translated_path)
			end
			table.sort(classified.All)
		end
		return classified
	end

	local function set_build_order(build_order, next_idx, files)
		local idx = next_idx
		for _, file in ipairs(files) do
			build_order[file] = idx
			idx = idx + 1
		end
		return idx
	end

	local function determine_build_order(classified)
		build_order = {}
		next_idx = 0
		next_idx = set_build_order(build_order, next_idx, classified._CppInclude)
		next_idx = set_build_order(build_order, next_idx, classified.CppCompile)
		next_idx = set_build_order(build_order, next_idx, classified.LibFiles)
		next_idx = set_build_order(build_order, next_idx, classified.ResourceCompile)
		next_idx = set_build_order(build_order, next_idx, classified.None)
--		next_idx = set_build_order(build_order, next_idx, classified.All)
	end

	local function write_all_blocks(files, build_order)
		for _, file in ipairs(files) do
			action = action_type(file)
			if not action then
				print ('unknown action: ' .. file)
			end
			if action == 'LibFiles' then
				_p(2, '<%s Include="%s">', action, path.getbasename(file))
			else
				_p(2, '<%s Include="%s">', action, file)
			end
				if not build_order[file] then
					print("error! not found: " .. file)
				end
				if action == 'ResourceCompile' then
					_p(3, '<ModuleName>%s</ModuleName>', file)
					_p(3, '<Form>%s</Form>', path.getbasename(file) .. '.res')
				end
				_p(3, '<BuildOrder>%d</BuildOrder>', build_order[file])
--				_p(3, '<IgnorePath>%s</IgnorePath>', iif(ignore_path[file], 'true', 'false'))
			_p(2, '</%s>', action)
		end
	end

-- http://stackoverflow.com/questions/1410862/concatenation-of-tables-in-lua
function array_concat(...)
    local t = {}

    for i = 1, arg.n do
        local array = arg[i]
        if (type(array) == "table") then
            for j = 1, #array do
                t[#t+1] = array[j]
            end
        else
            t[#t+1] = array
        end
    end

    return t
end

--[[
function array_print(items, label)
	if (label ~= nil) then print('<' .. label .. '>')  end
	for _, item in ipairs(items) do
		print(item)
	end
	if (label ~= nil) then print('</' .. label .. '>') end
	print("")
end
--]]

	function rs2010x.files(prj)
		cfg = premake.getconfig(prj)
		local files = cfg.files
--		array_print(files, 'files')

		local sibl = premake.getlinks(cfg, "siblings", "name")
		local sysl = premake.getlinks(cfg, "system", "fullpath")
		local links = array_concat( sibl, sysl )
--		array_print(sysl, 'sysl')
--		array_print(sibl, 'sibl')

		if #links > 0 then
			files = array_concat(files, links)
--			array_print(links, 'links')
--		else
--			print("no links")			
		end
		local classified = classify_input_files(files)
		determine_build_order(classified)
		write_all_blocks(classified.All, build_order)
	end
	
	function rs2010x.build_configs()
		for i, radconf in ipairs(radstudio.rstudio_configs()) do
			_p(2,'<BuildConfiguration Include="%s">', radconf)
				_p(3,'<Key>%s</Key>', _config_symbol(i))
				if (radconf ~= 'Base') then
					_p(3,'<CfgParent>%s</CfgParent>', 'Base')
				end
			_p(2,'</BuildConfiguration>')
		end
	end

	function rs2010x.project_extentions(prj, platforms)
		_p(1, '<ProjectExtensions>')
			_p(2, '<Borland.Personality>CPlusPlusBuilder.Personality.12</Borland.Personality>')
			_p(2, '<Borland.ProjectType>%s</Borland.ProjectType>', radstudio.cbproj.project_types[prj.kind])
			_p(2, '<BorlandProject>')
				_p(3, '<CPlusPlusBuilder.Personality/>')
				if rs2010x.listup_platforms() then
					_p(3, '<Platforms>')
						for _, pf in ipairs(platforms) do
							rpf = radstudio.supported_platforms()[pf]
							if rpf and (rpf ~= 'Base') then
								_p(4, '<Platform value="%s">True</Platform>', rpf)
							end
						end
					_p(3, '</Platforms>')
				end
			_p(2, '</BorlandProject>')
			_p(2, '<ProjectFileVersion>12</ProjectFileVersion>')
		_p(1, '</ProjectExtensions>')
	end

	function rs2010x.write_imports()
		if _ACTION == "rs2010" then
			_p(1, [[<Import Project="$(BDS)\Bin\CodeGear.Cpp.Targets" Condition="Exists('$(BDS)\Bin\CodeGear.Cpp.Targets')"/>]])
		elseif _ACTION == "rsxe" then
			_p(1, [[<Import Condition="Exists('$(BDS)\Bin\CodeGear.Cpp.Targets')" Project="$(BDS)\Bin\CodeGear.Cpp.Targets"/>]])
			_p(1, [[<Import Condition="Exists('$(APPDATA)\Embarcadero\$(BDSAPPDATABASEDIR)\$(PRODUCTVERSION)\UserTools.proj')" Project="$(APPDATA)\Embarcadero\$(BDSAPPDATABASEDIR)\$(PRODUCTVERSION)\UserTools.proj"/>]])
		elseif _ACTION == "rsxe2" then
			_p(1, [[<Import Condition="Exists('$(BDS)\Bin\CodeGear.Cpp.Targets')" Project="$(BDS)\Bin\CodeGear.Cpp.Targets"/>]])
			_p(1, [[<Import Condition="Exists('$(APPDATA)\Embarcadero\$(BDSAPPDATABASEDIR)\$(PRODUCTVERSION)\UserTools.proj')" Project="$(APPDATA)\Embarcadero\$(BDSAPPDATABASEDIR)\$(PRODUCTVERSION)\UserTools.proj"/>]])
		elseif _ACTION >= "rsxe3" then
			_p(1, [[<Import Project="$(BDS)\Bin\CodeGear.Cpp.Targets" Condition="Exists('$(BDS)\Bin\CodeGear.Cpp.Targets')"/>]])
			_p(1, [[<Import Project="$(APPDATA)\Embarcadero\$(BDSAPPDATABASEDIR)\$(PRODUCTVERSION)\UserTools.proj" Condition="Exists('$(APPDATA)\Embarcadero\$(BDSAPPDATABASEDIR)\$(PRODUCTVERSION)\UserTools.proj')"/>]])
		elseif _ACTION >= "rs100" then
			_p(1, [[<Import Project="$(BDS)\Bin\CodeGear.Cpp.Targets" Condition="Exists('$(BDS)\Bin\CodeGear.Cpp.Targets')"/>]])
			_p(1, [[<Import Project="$(APPDATA)\Embarcadero\$(BDSAPPDATABASEDIR)\$(PRODUCTVERSION)\UserTools.proj" Condition="Exists('$(APPDATA)\Embarcadero\$(BDSAPPDATABASEDIR)\$(PRODUCTVERSION)\UserTools.proj')"/>]])
		end
	end
--
-- The main function: write the project file.
--
	function rs2010x.generate(prj)
		io.eol = '\r\n'
		io.indent = '    '
		radstudio.write_utf8_bom()

 		-- filter platforms in sln and return as tables (e.g. x86 etc.)
 		local platforms = premake.filterplatforms(prj.solution, radstudio.supported_platforms(), "Native")
		
	   _p('<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">')

		_p(1,'<PropertyGroup>')
			_p(2,'<ProjectGuid>{%s}</ProjectGuid>', prj.uuid)		
			_p(2,'<ProjectVersion>%s</ProjectVersion>', rs2010x.project_version())
			if false then
				_p(2,'<FrameworkType>%s</FrameworkType>', 'None') -- TODO: make configurable
				_p(2,'<Base>true</Base>')				
			end		
			_p(2,"<Config Condition=\"'$(Config)'==''\">%s</Config>", radstudio.rstudio_configs()[2]);		-- 1..Base, 2..first config
			if false then
				_p(2,"<Platform Condition=\"'$(Platform)'==''\">%s</Platform>", radstudio.supported_platforms()[platforms[2]]); -- 1..Base, 2..first platform
				_p(2,"<TargetedPlatforms>%d</TargetedPlatforms>", 1); 				-- TODO: make configurable
				_p(2,'<AppType>%s</AppType>', radstudio.app_types[prj.kind])
			end
		_p(1,'</PropertyGroup>')

--[[ ---- <debug> ------------------------------
--		for i, radconf in ipairs(radstudio.config_tree) do
--			printf(i .. " conf_name:" .. radconf.name .. ", parent:" .. (radconf.parent or ''))
--		end

		for _, pf in ipairs(prj.solution.platforms) do
			print("prj.sln.plat:" .. pf)
		end
		
		for _, pf in ipairs(platforms) do		
			print("platform:" .. pf)
		end
--]]  ---- </debug> ------------------------------

	   -- PropertyGroup(s) --
		-- configuration definition blocks --
		rs2010x.config_definition_blocks(prj, platforms)
		-- actual configuration blocks --
		rs2010x.config_blocks(prj, platforms)

		-- ItemGroup --
		_p(1, '<ItemGroup>')
			-- files --
			rs2010x.files(prj)
			-- buildconfigs --
			rs2010x.build_configs()
		_p(1, '</ItemGroup>')

		if rs2010x.import_first() then
			rs2010x.write_imports()
			rs2010x.project_extentions(prj, platforms) 
		else
			rs2010x.project_extentions(prj, platforms)
			rs2010x.write_imports()		
		end
		
	  _p('</Project>')
	end
	

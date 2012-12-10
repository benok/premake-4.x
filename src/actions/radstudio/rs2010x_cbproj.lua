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
	
	function rs2010x.project_version()
		if _ACTION == "rs2010" then
			return "12.0"
		elseif _ACTION == "rsxe" then
			return "12.3"
		elseif _ACTION == "rsxe2" then
			return "13.4"
		elseif _ACTION == "rsxe3" then
			return "14.3"
		end
	end

--
-- Return supports multiple platform or not
--
	function radstudio.supported_platforms()
		return radstudio[_ACTION].platforms
	end

	function rs2010x.supports_multiple_platform()
		return not((_ACTION <= "rs2010") or (_ACTION == "rsxe"))
	end
	
	function rs2010x.listup_platforms()
		return (not (_ACTION <= "rs2010")) and (_ACTION >= "rsxe")
	end

	function rs2010x.import_first()
		return (_ACTION <= "rs2010") or (_ACTION == "rsxe")
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
		local rad_platform = radstudio.supported_platforms()[platform]
--		print('**config_definition_block('..rad_platform..','..radconf.name..','..idx..')')		
		_p(1,'<PropertyGroup Condition="%s">', _config_cond_expr_on_define(radconf.name, idx, rad_platform))
		    local sym = _config_symbol(idx, rad_platform)
			if sym ~= 'Base' then
				_p(2,'<%s>true</%s>', sym, sym) -- put self defined
			end
			if radconf.parent ~= nil then
				-- have parent
				if (rad_platform == nil) or (rad_platform == 'Base') then
--					printf('HaveParent&Base', radconf.parent)
--					printf('<CfgParent>%s</CfgParent>', radconf.parent)				   
					_p(2,'<CfgParent>%s</CfgParent>', radconf.parent)
				else
					local parent_sym = _config_symbol(idx)
--					printf('HaveParent&NotBasePlatform. rad_plat='..rad_platform..',idx='.. idx ..',parent=' .. radconf.parent .. ',parent_sym='..parent_sym)
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
		for i, radconf in ipairs(radstudio.config_tree) do
			if rs2010x.supports_multiple_platform() then
				-- multi platform
				for _, platform in ipairs(platforms) do
					rs2010x.config_definition_block(platform, radconf, i)
				end
			else
				-- single platform (x32=Win32) only
				rs2010x.config_definition_block('Base', radconf, i)
			end
		end
	end

	function rs2010x.bcc_options(cfg)
--		cfg.flags.Optimize
		
	end
	
	function rs2010x.config_block(prj, platform, radconf, idx)
--		print("platform:"..platform)
		local rad_platform = radstudio.supported_platforms()[platform]
		local conf_symbol = _config_symbol(idx, rad_platform)
--		print('**config_definition_block('..rad_platform..','..radconf.name..','..idx..')')

		_p(1,'<PropertyGroup Condition="%s">', _config_cond_expr_on_use(radconf.name, idx, rad_platform))
			if conf_symbol == 'Base' then
				_p(2,'<ProjectType>%s</ProjectType>', radstudio.cbproj.project_types[prj.kind])
--				_p(2,'<OutputExt>lib</OutputExt>')
--				_p(2,'<DCC_CBuilderOutput>JPHNE</DCC_CBuilderOutput>')		-- Required ?
--				_p(2,'<DynamicRTL>true</DynamicRTL>')						-- Required ?
			end

			local cfg = premake.getconfig(prj, radconf.name, platform)
		
			if cfg and
				((rs2010x.supports_multiple_platform() and (rad_platform ~= 'Base'))
				or
				 (not rs2010x.supports_multiple_platform()))
			then
				if #cfg.includedirs > 0 then
					_p(2,'<IncludePath>%s;$(IncludePath)</IncludePath>', premake.esc(path.translate(table.concat(cfg.includedirs, ";"), '\\')))
				end
				
				if #cfg.libdirs > 0 then
					_p(2,'<ILINK_LibraryPath>%s;$(ILINK_LibraryPath)</ILINK_LibraryPath>', table.concat(premake.esc(path.translate(cfg.libdirs, '\\')) , ";"))
				end
				
				if #cfg.defines > 0 then
					_p(2, '<Defines>%s;$(Defines)</Defines>', table.concat(premake.esc(cfg.defines), ";"))
				end
			end
--			_p(2,'<BCC_wpar>true</BCC_wpar>')						-- TODO: Support Option Config
			_p(2,'<BCC_whid>false</BCC_whid>')						-- W8022 '関数1' が仮想関数 '関数2' を隠蔽する (-whid)
			_p(2,'<BCC_wccc>false</BCC_wccc>')						-- W8008 条件が常に真 (-wccc)
			_p(2,'<BCC_wpch>false</BCC_wpch>')						-- W8058 プリコンパイルヘッダーを作成できない (-wpch)
			_p(2,'<BCC_wpar>false</BCC_wpar>')						-- W8057 パラメータは一度も使用されない (-wpar)
			_p(2,'<BCC_wrch>false</BCC_wrch>')						-- W8066 実行されないコード (-wrch)
			_p(2,'<BCC_wpia>false</BCC_wpia>')						-- W8060 おそらく不正な代入 (-wpia)

--			_p(2,'<BCC_OptimizeForSpeed>true</BCC_OptimizeForSpeed>')
--			_p(2,'<BCC_ExtendedErrorInfo>true</BCC_ExtendedErrorInfo>')
		_p(1,'</PropertyGroup>')		   		
	end

	function rs2010x.config_blocks(prj, platforms)
		for i, radconf in ipairs(radstudio.config_tree) do
			if rs2010x.supports_multiple_platform() then
				-- multi platform
				for _, platform in ipairs(platforms) do
					rs2010x.config_block(prj, platform, radconf, i)
				end
			else
				-- single platform (x32=Win32) only
				rs2010x.config_block(prj, 'Generic', radconf, i)
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
		--		rc  = "ResourceCompile"
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
			None = {},
			All = {},
--			ResourceCompile = {}
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
		next_idx = set_build_order(build_order, next_idx, classified.None)
--		next_idx = set_build_order(build_order, next_idx, classified.All)
	end

	local function write_all_blocks(files, build_order)
		for _, file in ipairs(files) do
			action = action_type(file)
			if not action then
				print ('unknown action: ' .. file)
			end
			_p(2, '<%s Include="%s">', action, file)
				if not build_order[file] then
					print("error! not found: " .. file)
				end
				_p(3, '<BuildOrder>%d</BuildOrder>', build_order[file])
			_p(2, '</%s>', action)
		end
	end

	function rs2010x.files(prj)
		cfg = premake.getconfig(prj)
		local classified = classify_input_files(cfg.files)
		determine_build_order(classified)
		write_all_blocks(classified.All, build_order)
	end
	
	function rs2010x.build_configs()
		for i, radconf in ipairs(radstudio.config_tree) do
			_p(2,'<BuildConfiguration Include="%s">', radconf.name)
				_p(3,'<Key>%s</Key>', _config_symbol(i))
				if (radconf.parent) then
					_p(3,'<CfgParent>%s</CfgParent>', radconf.parent)
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
		end
	end
--
-- The main function: write the project file.
--
	function rs2010x.generate(prj)
		io.eol = '\r\n'
		radstudio.write_utf8_bom()

 		-- sln中のplatformから、radstudioでサポートされているものをtableで返す。中身はx86など。premake側の表現
 		local platforms = premake.filterplatforms(prj.solution, radstudio.supported_platforms(), "Native")
		
	   _p('<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">')

		_p(1,'<PropertyGroup>')
			_p(2,'<ProjectGuid>{%s}</ProjectGuid>', prj.uuid)		
			_p(2,'<ProjectVersion>%s</ProjectVersion>', rs2010x.project_version())
			if false then
				_p(2,'<FrameworkType>%s</FrameworkType>', 'None') -- TODO: make configurable
				_p(2,'<Base>true</Base>')				
			end		
			_p(2,"<Config Condition=\"'$(Config)'==''\">%s</Config>", 'Debug');		-- TODO: make configurable
			if false then
				_p(2,"<Platform Condition=\"'$(Platform)'==''\">%s</Platform>", 'Win32'); -- TODO: make configurable
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
	
--
-- rs2010_groupproj.lua
-- Generate a RAD Studio 2010-XE* groupproj.
-- Copyright (c) 2009-2011 Jason Perkins and the Premake project
--

	premake.radstudio.gproj2010 = { }
	local radstudio = premake.radstudio
	local gproj2010 = premake.radstudio.gproj2010
	
	function gproj2010.generate(sln)

		-- Precompute RAD Studio configurations(plaform & Release/Debug combinations)
		--sln.radstudio_configs = premake.radstudio.buildconfigs(sln)
		
		-- Mark the file as Unicode
		io.eol = '\r\n'
		io.indent = '    '
		radstudio.write_utf8_bom()
		
		_p('<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">')

			_p(1, '<PropertyGroup>')
				_p(2, '<ProjectGuid>{%s}</ProjectGuid>', sln.uuid)
			_p(1, '</PropertyGroup>')

			_p(1, '<ItemGroup>')
				for prj in premake.solution.eachproject(sln) do
					gproj2010.project(2, prj)
				end
			_p(1, '</ItemGroup>')

			
			_p(1, '<ProjectExtensions>')
				_p(2, '<Borland.Personality>Default.Personality.12</Borland.Personality>')
				_p(2, '<Borland.ProjectType/>')
				_p(2, '<Borland.Project>')
					_p(3, '<Borland.Project>')
						_p(4, '<Default.Personality/>')
					_p(3, '</Borland.Project>')
				_p(2, '</Borland.Project>')
			_p(1, '</ProjectExtensions>')

			-- Expand Project Targets --
			for prj in premake.solution.eachproject(sln) do
				gproj2010.target(1, prj)
			end

			-- Global Targets --
			_p(1, '<Target Name="Build">')
				_p(2, '<CallTarget Targets="%s"/>', gproj2010.expand_targets(sln, ';', ''))
			_p(1, '</Target>')
			_p(1, '<Target Name="Clean">')
				_p(2, '<CallTarget Targets="%s"/>', gproj2010.expand_targets(sln, ';', ':Clean'))
			_p(1, '</Target>')
			_p(1, '<Target Name="Make">')
				_p(2, '<CallTarget Targets="%s"/>', gproj2010.expand_targets(sln, ';', ':Make'))
			_p(1, '</Target>')

			_p(1, "<Import Project=\"$(BDS)\\Bin\\CodeGear.Group.Targets\" Condition=\"Exists('$(BDS)\\Bin\\CodeGear.Group.Targets')\"/>")
		_p('</Project>')
	end

--
-- Write out an entry for a project
--

	function gproj2010.project(lv, prj)
		-- Build a relative path from the solution file to the project file
		local projpath = path.translate(path.getrelative(prj.solution.location, radstudio.projectfile(prj)), "\\")

		_p(lv, "<Projects Include=\"%s\">", projpath)
		gproj2010.projectdependencies(lv+1, prj)
		_p(lv, "</Projects>")
	end

	function gproj2010.target(lv, prj)
		-- Build a relative path from the solution file to the project file
		local projpath = path.translate(path.getrelative(prj.solution.location, radstudio.projectfile(prj)), "\\")

		-- None
		_p(lv, '<Target Name="%s">', prj.name)
			_p(lv+1, "<MSBuild Projects=\"%s\"/>", projpath)
		_p(lv, "</Target>")
		
		-- Clean
		_p(lv, "<Target Name=\"%s:Clean\">", prj.name)
			_p(lv+1, "<MSBuild Targets=\"Clean\" Projects=\"%s\"/>", projpath)
		_p(lv, "</Target>")
		
		-- Make
		_p(lv, "<Target Name=\"%s:Make\">", prj.name)
			_p(lv+1, "<MSBuild Targets=\"Make\" Projects=\"%s\"/>", projpath)
		_p(lv, "</Target>")		
	end

	function gproj2010.projectdependencies(lv, prj)
		local deps = premake.getdependencies(prj)
		if #deps > 0 then
			_p('\tProjectSection(ProjectDependencies) = postProject')
			for _, dep in ipairs(deps) do
				_p(lv, '<Dependencies>%s</Dependencies>', dep.name)
			end
			_p('\tEndProjectSection')		
		else
			_p(lv+1, "<Dependencies/>" )
		end
	end
	
	function gproj2010.expand_targets(sln, separator, postfix)
		local result = '';
		for prj in premake.solution.eachproject(sln) do
			result = result .. prj.name .. postfix .. separator 
		end
		return result
	end;

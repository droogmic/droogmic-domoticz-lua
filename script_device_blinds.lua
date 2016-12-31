-- device blind script
-- script names have three name components: script_trigger_name.lua
-- trigger can be 'time' or 'device', name can be any string
-- domoticz will execute all time and device triggers when the relevant trigger occurs
--
-- copy this script and change the "name" part, all scripts named "demo" are ignored.
--
-- Make sure the encoding is UTF8 of the file
--
-- ingests tables: devicechanged, otherdevices,otherdevices_svalues
--
-- device changed contains state and svalues for the device that changed.
--   devicechanged['yourdevicename']=state
--   devicechanged['svalues']=svalues string
--
-- otherdevices and otherdevices_svalues are arrays for all devices:
--   otherdevices['yourotherdevicename']="On"
--	otherdevices_svalues['yourotherthermometer'] = string of svalues
--
-- Based on your logic, fill the commandArray with device commands. Device name is case sensitive.
--
-- Always, and I repeat ALWAYS start by checking for the state of the changed device.
-- If you would only specify commandArray['AnotherDevice']='On', every device trigger will switch AnotherDevice on, which will trigger a device event, which will switch AnotherDevice on, etc.
--
-- The print command will output lua print statements to the domoticz log for debugging.
-- List all otherdevices states for debugging:
--   for i, v in pairs(otherdevices) do print(i, v) end
-- List all otherdevices svalues for debugging:
--   for i, v in pairs(otherdevices_svalues) do print(i, v) end
--
-- TBD: nice time example, for instance get temp from svalue string, if time is past 22.00 and before 00:00 and temp is bloody hot turn on fan.

-- print('Lua Script - Blinds')

commandArray = {}

blindslaves = {
	['Blind F4']={'Blind Verbier', 'Blind Verbier Shower'},
	['Blind Sejour']={'Blind Sejour Main', 'Blind Sejour Left', 'Blind Sejour Right', 'Blind Sejour Stairs'},
	['Blind Dining']={'Blind Cuisine', 'Blind Dining Side', 'Blind Dining Main'},
	['Blind F3']={'Blind Entry', 'Blind WC', 'Blind Office', 'Blind Sejour', 'Blind Dining'},
	['Blind F2']={'Blind Moscow', 'Blind Moscow Shower', 'Blind London', 'Blind London Shower', 'Blind Munich', 'Blind Bath', 'Blind Chicago', 'Blind Bedroom Stairs'},
	['Blind F1']={'Blind Cinema', 'Blind Jeux'},
	['Blind All']={'Blind F1', 'Blind F2', 'Blind F3', 'Blind F4'},
	--['Blind All']={'Blind Office'},

	['Blind East']={'Blind Cuisine', 'Blind Dining Side'},
	['Blind Stairs']={'Blind Bedroom Stairs', 'Blind Sejour Stairs'},

	-- Blinds
	--Group1 = partial range + group2
	--Group2 = full range
	--Group3 = privacy
	--Group4 =
	--GroupSolar
	['Blind Group1']={'Blind Stairs', 'Blind Entry'},
	['Blind Group2']={'Blind Bath', 'Blind WC'},
	['Blind Group3']={'Blind Sejour Main', 'Blind Dining'},

	['Blind GroupSolar']={'Blind Dining Main'},
	['Blind GroupSolarProtect']={'Blind Sejour Main'}
}

for cdevice, cvalue in pairs(devicechanged) do
	if (true) then
		if (string.find(cdevice, 'Blind') == 1) then

			print('Lua Script - DeviceBlinds')
			print(cdevice .. ' set to ' .. cvalue)

			file, e1 = io.open("device_blind.log", "a+")
			o2, e2 = io.output(file)
			t2 = os.date("*t")
			m2 = t2.min + t2.hour * 60
			--o3, e3 = io.write(os.date('%F %T') .. '\t' .. m2 .. '  \t' ..  cdevice .. ' set to ' .. cvalue .. '\n')

			--blinds
			if blindslaves[cdevice] then
				o3, e3 = io.write(os.date('%F %T') .. '\t' .. m2 .. '  \t' ..  cdevice .. ' set to ' .. cvalue .. '\n')
				for index,device in ipairs(blindslaves[cdevice]) do
					--Cannot guarantee position is accurate
					--if ((cvalue ~= otherdevices[device]) or (cvalue == 'Stop')) then
						commandArray[device]=cvalue
						print(device .. ' inherited ' .. cvalue)
						io.write('\t\t\t\t\t\t\t\t' .. device .. ' inherited ' .. cvalue .. '\n')
					--end
				end
				o4, e4 = io.write('\n')
			end

			--o4, e4 = io.write('\n')
			o5, e5 = io.close(file)

		end
	end

	--testing
	if (false) then
		if (cdevice == 'Blind Test') then
			print('Blind Test')
			print(cvalue)
			--commandArray[1]={['Variable:TimeBlindTest']='0'}
			--commandArray[1]={['Blind Office']='Stop'}
			--commandArray[2]={['Blind Office']='Off AFTER 40'}
			--commandArray[3]={['Blind Office']='Stop AFTER 43'}
		end
	end

end

return commandArray

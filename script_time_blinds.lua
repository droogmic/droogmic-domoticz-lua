-- blind time script
-- script names have three name components: script_trigger_name.lua
-- trigger can be 'time' or 'device', name can be any string
-- domoticz will execute all time and device triggers when the relevant trigger occurs
--
-- copy this script and change the "name" part, all scripts named "demo" are ignored.
--
-- Make sure the encoding is UTF8 of the file
--
-- ingests tables: otherdevices,otherdevices_svalues
--
-- otherdevices and otherdevices_svalues are two item array for all devices:
--   otherdevices['yourotherdevicename']="On"
--	otherdevices_svalues['yourotherthermometer'] = string of svalues
--
-- Based on your logic, fill the commandArray with device commands. Device name is case sensitive.
--
-- Always, and I repeat ALWAYS start by checking for a state.
-- If you would only specify commandArray['AnotherDevice']='On', every time trigger (e.g. every minute) will switch AnotherDevice on.
--
-- The print command will output lua print statements to the domoticz log for debugging.
-- List all otherdevices states for debugging:
--   for i, v in pairs(otherdevices) do print(i, v) end
-- List all otherdevices svalues for debugging:
--   for i, v in pairs(otherdevices_svalues) do print(i, v) end

-- print('Lua Script - Timing Blinds')
-- print(_VERSION)

commandArray = {}

t1 = os.date("*t")
m1 = t1.min + t1.hour * 60
--print(m1)

--TimeBlindTest
if (false) then
	if (uservariables['TimeBlindTest'] < -3000)  then
		m1 = timeofday['SunriseInMinutes'] + uservariables['TimeBlindTest'] + 4000
		commandArray[1]={['Variable:TimeBlindTest']='0'}
		print('Testing mode ' .. m1)
	end
	if (uservariables['TimeBlindTest'] > -3000) and (uservariables['TimeBlindTest'] < 0) then
		m1 = timeofday['SunsetInMinutes'] + uservariables['TimeBlindTest'] + 2000
		commandArray[1]={['Variable:TimeBlindTest']='0'}
		print('Testing mode ' .. m1)
	end
	if (uservariables['TimeBlindTest'] > 0) then
		m1 = uservariables['TimeBlindTest']
		commandArray[1]={['Variable:TimeBlindTest']='0'}
		print('Testing mode ' .. m1)
	end
end

-- Blinds
--Group1 = partial range + group2
--Group2 = full range
--Group3 = privacy
--Group4 =
--GroupSolar
if (true) then
	--print(otherdevices['Autoblind'])
	if (otherdevices['Autoblind'] == 'On') then

		--8am
		if (m1 == 480) then
			commandArray[2]={['Blind Group1']='Stop'}
		end

		--8:20am
		if (m1 == 500) then
			commandArray[2]={['Blind Group1']='Off'}
			commandArray[3]={['Blind Group1']='Stop AFTER 3'}
		end

		--Sunrise + 30 if after 8:20am otherwise 8:40am
		if (((m1 == timeofday['SunriseInMinutes'] + 30) and (m1 > 500)) or ((m1 == 520) and (timeofday['SunriseInMinutes'] + 30 <= 500))) then
			commandArray[2]={['Blind Group2']='Off'}
			commandArray[3]={['Blind Group3']='Stop'}
		end

		if (m1 == timeofday['SunriseInMinutes'] + 30) then
		end

		--Sunrise + 60 if after 8:40am otherwise 9:00am
		if (((m1 == timeofday['SunriseInMinutes'] + 60) and (m1 > 520)) or ((m1 == 540) and (timeofday['SunriseInMinutes'] + 30 <= 520))) then
			--commandArray[2]={['Blind Group3']='Off'}
			--commandArray[3]={['Blind Group3']='Stop AFTER 3'}
		end
		if (m1 == timeofday['SunsetInMinutes'] - 60) then
			--commandArray[2]={['Blind Group3']='Stop'}
		end
		if (m1 == timeofday['SunsetInMinutes'] - 30) then
		end
		if (m1 == timeofday['SunsetInMinutes'] + 0) then
			commandArray[2]={['Blind Group2']='Stop'}
			commandArray[3]={['Blind Group2']='Off AFTER 52'}
			commandArray[4]={['Blind Group2']='Stop AFTER 55'}
			commandArray[5]={['Blind Group3']='On'}
		end
		if (m1 == timeofday['SunsetInMinutes'] + 30) then
			commandArray[2]={['Blind Group1']='Stop'}
		end
		if (m1 == timeofday['SunsetInMinutes'] + 60) then
			commandArray[2]={['Blind Group1']='On'}
		end
		if (#commandArray>0) then
			print('Lua Script - TimeBlinds')
			print('Blinds Activated: m1 = ' .. m1)
		end
	end
end

--Checks if 10 minutes
if (true) then
	if (m1 % 5 == 0) then

		http = require('socket.http')
		ltn12 = require('ltn12')

		--http://192.168.1.31/solar_api/v1/GetInverterRealtimeData.fcgi?Scope=System
		--http://192.168.1.31/solar_api/GetAPIVersion.cgi
		base_url = uservariables['FroniusBaseURL']

		t = {}
		req_body = ''
		local headers = {
	            ["Content-Type"] = "application/json";
	            ["Content-Length"] = #req_body;
			}
		client, code, headers, status = http.request{url=base_url, headers=headers, source=ltn12.source.string(req_body), sink = ltn12.sink.table(t), method='GET'}

		--Check if page exists
		-- print(#t)
		if (#t~=0) then
			print('Lua Script - Power updated')

			json = require('json')

			s = table.concat(t)
			j = '['..s..']'
			--j=j:gsub('\n','')
			--j=j:gsub('\t','')
			--print(j)
			obj = json.decode(j)
			--print(obj[1].Body.Data.PAC.Values["1"])
			power = obj[1].Body.Data.PAC.Values["1"]
			energy = obj[1].Body.Data.TOTAL_ENERGY.Values["1"]

			commandArray[10] = {['UpdateDevice'] = "55|0|"..power..";".. energy}
			commandArray[11] = {['UpdateDevice'] = "56|0|"..power}

			if (otherdevices['Solarblind'] == 'On') then
				temp = otherdevices_temperature['Living Room']
				if (temp < 18) then
					if (otherdevices['Blind GroupSolar'] ~= 'Stop') then
						midday = (timeofday['SunriseInMinutes']+timeofday['SunsetInMinutes'])/2
						if ((power > 2500) or (power == 0 and((m1 - midday)<1 and (m1 - midday)>0))) then
							commandArray[12]={['Blind GroupSolar']='Off'}
							commandArray[13]={['Blind GroupSolar']='Stop AFTER 3'}
							file = io.open("device_time.log", "a+")
							io.output(file)
							io.write(os.date('%F %T') .. '\t' .. m1 .. '  \tUP\nTemp: ' .. temp .. '\tPower: ' ..  power .. '\tSunrise+Sunset times: ' .. timeofday['SunriseInMinutes'] .. ' ' .. timeofday['SunsetInMinutes'] .. '\n\n')
							io.close(file)
						end
					end
				end
				if ((power < 1500 and power > 0) or (power == 0 and m1 == timeofday['SunsetInMinutes'] - 120)) then
					if (otherdevices['Blind GroupSolar'] == 'Stop') then
						commandArray[14]={['Blind GroupSolar']='On'}
						file = io.open("device_time.log", "a+")
						io.output(file)
						io.write(os.date('%F %T') .. '\t' .. m1 .. '  \tDOWN\nTemp: ' .. temp .. '\tPower: ' ..  power .. '\tSunrise+Sunset times: ' .. timeofday['SunriseInMinutes'] .. ' ' .. timeofday['SunsetInMinutes'] .. '\n\n')
						io.close(file)
					end
				end
			end
		end

	end
end

return commandArray

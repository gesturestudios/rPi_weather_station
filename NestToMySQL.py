#!/usr/bin/python

import nest
import MySQLdb
import time

client_id = '[client id]'
client_secret = '[clinet secret]'

access_token_cache_file = 'nest.json'
napi = nest.Nest(client_id=client_id, client_secret=client_secret, access_token_cache_file=access_token_cache_file)

if napi.authorization_required:
    print('Go to ' + napi.authorize_url + ' to authorize, then enter PIN below')
    pin = input("PIN: ")
    napi.request_token(pin)

## Access advanced structure properties:
for structure in napi.structures:
	# Access advanced device properties:
    for device in structure.thermostats:
        nest_temp = device.temperature
        nest_humid = device.humidity
        nest_target = device.target
        nest_ecohigh = device.eco_temperature.high
        nest_ecolow  = device.eco_temperature.low
        nest_mode = device.mode
        nest_fan = device.fan
        nest_emergency_heat = device.is_using_emergency_heat
        nest_away_status = structure.away


print nest_temp
print nest_humid
print nest_target
print nest_ecohigh
print nest_ecolow
print nest_mode
print nest_fan
print nest_emergency_heat
print nest_away_status

# make a database connection
conxtn = MySQLdb.connect(host = "192.168.1.134",
					 user = "[user]",
					 passwd = "[pwd]",
					 db = "arduino_data")
					 
# create cursor object to execute queries
cur = conxtn.cursor()
print "cursur connected..."

curr_t = time.strftime("%Y-%m-%d %H:%M:%S")
print curr_t
	
#cur.execute("""INSERT INTO PiStation (OUTSIDE_TEMP, OUTSIDE_HUMIDITY, OUTSIDE_PRESSURE, READ_TIME) VALUES (%s,%s,%s,%s)""",
	#(out_temp,out_humid,out_pres,curr_t) )
	
cur.execute("""INSERT INTO NEST_DATA (datetime, NEST_TEMP, NEST_HUMID, NEST_TARGET, NEST_ECOHIGH, NEST_ECOLOW, NEST_MODE, NEST_FAN, NEST_EMERGENCY, NEST_AWAY) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
	(curr_t, nest_temp, nest_humid, nest_target, nest_ecohigh, nest_ecolow, nest_mode, nest_fan, nest_emergency_heat, nest_away_status) )

print "closing connection"
conxtn.commit()			# commit changes to db
cur.close()				# close cursor
conxtn.close()			# close connection


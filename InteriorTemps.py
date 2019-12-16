#!/usr/bin/python
# python library from github.com/timofurrer/w1thermsensor


#sensor = W1ThermSensor()
#temperature_in_farenheit = sensor.get_temperature(W1ThermSensor.DEGREES_F)
#print temperature_in_farenheit
# location, id, flat side of sensor up, left to right wiring
# in                           		bluewhite,brown,blue
# phonebox =        000005b95416     flat side up
# master bed =     000006083df7		orangewhite, blue, orange
# by router = 
# by kitchen = 

from w1thermsensor import W1ThermSensor
import MySQLdb
import time
sensordict = {
	'000005b95416':'phonebox',
	'000006083df7':'master bedroom'}

def get_sensor_reading(sensor,sensordict):
	if sensor.id in sensordict:
		print('{0} found in dictiondary as {1}'.format(
			str(sensor.id),
			sensordict[sensor.id]))
		return [str(sensordict[sensor.id]),round(sensor.get_temperature(W1ThermSensor.DEGREES_F),2)]
	else:
		print('did not find sensor id {} in dictionary'.format(sensor.id))

readings = []
if len(W1ThermSensor.get_available_sensors()) > 0:
	for sensor in W1ThermSensor.get_available_sensors():
		reading = get_sensor_reading(sensor,sensordict)
		readings.append(['pi3','DS18B20',reading[0],'temperature',reading[1]])
		time.sleep(1)

# post the values to MySQL:

# make a database connection
conxtn = MySQLdb.connect(host = '192.168.1.20',
					 user = "arduinouser",
					 passwd = "arduino",
					 db = "arduino_data")

# create cursor object to execute queries
cur = conxtn.cursor()
print("cursur connected...")
for reading in readings:
	cur.execute("""INSERT INTO SINGLE_TEMPS (COMPUTER_NAME, SENSOR_TYPE, SENSOR_LOCATION, VALTYPE, VALUE) VALUES (%s,%s,%s,%s,%s)""",(reading[0],reading[1],reading[2],reading[3],reading[4]) )

print("closing connection")
conxtn.commit()			# commit changes to db
cur.close()				# close cursor
conxtn.close()			# close connection

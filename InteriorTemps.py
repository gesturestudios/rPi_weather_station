#!/usr/bin/python
# python library from github.com/timofurrer/w1thermsensor


#sensor = W1ThermSensor()
#temperature_in_farenheit = sensor.get_temperature(W1ThermSensor.DEGREES_F)
#print temperature_in_farenheit
# location, id, flat side of sensor up, left to right wiring
# in                           		bluewhite,brown,blue
# outside =        000005b95416     flat side up
# master bed =     000006083df7		orangewhite, blue, orange
# by router = 
# by kitchen = 

from w1thermsensor import W1ThermSensor
import MySQLdb
import time
sensordict = {
	'000005b95416':'outside 1wire',
	'000006083df7':'master bedroom 1wire'}

def get_sensor_reading(readings,sensor,sensordict):
	if sensor.id in sensordict:
		print('{0} found in dictiondary as {1}'.format(
			str(sensor.id),
			sensordict[sensor.id]))
		readings.append([
			'pi3 w1therm',
			str(sensordict[sensor.id]),
			'temperature',
			round(sensor.get_temperature(W1ThermSensor.DEGREES_F),1)
			#time.strftime("%Y-%m-%d %H:%M:%S")
			])
	else:
		print('did not find sensor id {} in dictionary'.format(sensor.id))
	
readings = []
if len(W1ThermSensor.get_available_sensors()) > 0:
	for sensor in W1ThermSensor.get_available_sensors():
		time.sleep(1)
		
		

# post the values to MySQL:

# make a database connection
conxtn = MySQLdb.connect(host = '192.168.1.20',
					 user = "arduinouser",
					 passwd = "arduino",
					 db = "arduino_data")

# create cursor object to execute queries
cur = conxtn.cursor()
print "cursur connected..."
for reading in readings:
	cur.execute("""INSERT INTO SINGLE_TEMPS (DATA_SOURCE, LOCATION, VALTYPE, VALUE) VALUES (%s,%s,%s,%s)""",(reading[0],reading[1],reading[2],reading[3]) )

print "closing connection"
conxtn.commit()			# commit changes to db
cur.close()				# close cursor
conxtn.close()			# close connection

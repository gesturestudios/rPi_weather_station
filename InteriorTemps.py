#!/usr/bin/python
from w1thermsensor import W1ThermSensor
import MySQLdb
import time
# python library from github.com/timofurrer/w1thermsensor


#sensor = W1ThermSensor()
#temperature_in_farenheit = sensor.get_temperature(W1ThermSensor.DEGREES_F)
#print temperature_in_farenheit
dining = 0
simi = 0
br = 0

# specify sensors for each table, otherwise it just goes with list order.  If sensor goes out,
# now way of telling which sensor it was, this way it is hard-coded to specific room/sensor pairs.
for sensor in W1ThermSensor.get_available_sensors():
	if sensor.id == '0000060a1c17':
		br = round(sensor.get_temperature(W1ThermSensor.DEGREES_F),1)
	elif sensor.id == '000005b8f713':
		simi = round(sensor.get_temperature(W1ThermSensor.DEGREES_F),1)
	elif sensor.id == '000005b8da01':
		dining = round(sensor.get_temperature(W1ThermSensor.DEGREES_F),1)

# post the values to MySQL:

# make a database connection
conxtn = MySQLdb.connect(host = "192.168.1.134",
					 user = "raspberry",
					 passwd = "raspberryPi",
					 db = "arduino_data")

# create cursor object to execute queries
cur = conxtn.cursor()
print "cursur connected..."

curr_t = time.strftime("%Y-%m-%d %H:%M:%S")
print curr_t
	
cur.execute("""INSERT INTO INDOOR_TEMPS (DININGROOM, BEDROOM, SIMIROOM, READ_TIME) VALUES (%s,%s,%s,%s)""",
	(dining,br,simi,curr_t) )

print "closing connection"
conxtn.commit()			# commit changes to db
cur.close()				# close cursor
conxtn.close()			# close connection

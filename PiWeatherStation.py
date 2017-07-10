
#!/usr/bin/python
import MySQLdb
import Adafruit_DHT
#from w1thermsensor import W1ThermSensor
import Adafruit_BMP.BMP085 as BMP085
import time

# this will get temp/humid and pressure readings from the BMP085 sensor and the DHT11 sensor,
# then write them to the MySQL database

# first, get the reading from the DHT11
DHT_sensor = Adafruit_DHT.DHT11
DHT_pin = 17
out_humid, temperature = Adafruit_DHT.read_retry(DHT_sensor, DHT_pin)


# next, get the reading from the BMP085
BMP_sensor = BMP085.BMP085()
out_temp = round((BMP_sensor.read_temperature()*1.8+32),1)
out_pres = BMP_sensor.read_pressure()

# finally, write it to the database

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
	
cur.execute("""INSERT INTO PiStation (OUTSIDE_TEMP, OUTSIDE_HUMIDITY, OUTSIDE_PRESSURE, READ_TIME) VALUES (%s,%s,%s,%s)""",
	(out_temp,out_humid,out_pres,curr_t) )

print "closing connection"
conxtn.commit()			# commit changes to db
cur.close()				# close cursor
conxtn.close()			# close connection

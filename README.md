# rPi_weather_station
A few of these scripts are run from a raspberry pi.  I've had issues with SD card corruption, so I'm documenting here how to re-load the necessary libraries.

download this repository with git:
git clone https://github.com/gesturestudios/rPi_weather_station

make sure python pip and dev are up to date:
sudo apt-get update
sudo apt-get upgrage
sudp apt-get install python-pip python-dev libmysqlclient-dev

now that all files are on the pi, we can install the necessary python libraries:
sudo apt-get install python-mysqldb
sudo pip install w1thermsensor python-nest

change directory into the downloaded git repository and unzip the .tar.gz files:
cd Documents/Python_projects/rPi_weather_station

adafruit DHT:
tar -xvzf Adafruit_Python_DHT.tar.gz
cd Adafruit_Python_DHT
sudo python setup.py install
cd ..

adafruit BMP085:
tar -xvzf Adafruit_Python_BMP.tar.gz
cd Adafruit_Python_DHT
sudo python setup.py install
cd ..

finally, open rpi preferences and enable i2c, then reboot.

test libraries- go back to home directory, then
sudo python
from w1thermsensor import W1ThermSensor
import Adafruit_BMP.BMP085 as BMP085
import MySQLdb
import Adafruit_DHT

then exit python and run the scripts from command line:

sudo python Documents/Python_projects/rPi_weather_station/InteriorTemps.py
sudo python Documents/Python_projects/rPi_weather_station/PiWeatherStation.py
sudo python Documents/Python_projects/rPi_weather_station/NestToMySQL.py - follow the directions to authorize

set up the crontab to run the script every 5 minutes

*/5 * * * * sudo python /home/pi/Documents/Python_projects/rPi_weather_station/InteriorTemps.py
*/5 * * * * sudo python /home/pi/Documents/Python_projects/rPi_weather_station/PiWeatherStation.py
*/5 * * * * sudo python /home/pi/Documents/Python_projects/rPi_weather_station/NestToMySQL.py

### Dashboard setup ###
The visualization for this and all data comes from a shiny dashboard (Home_shiny_dashboard.R).  The script has moved beyond just the data pulled from the sql database to include some google sheet data and other imported things.  On the to-do list is to reduce it back to a script only relating to the weather station, and make a separate version for the complete dashboard...


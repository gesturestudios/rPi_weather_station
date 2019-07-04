# rPi_weather_station
A few of these scripts are run from a raspberry pi.  I've had issues with SD card corruption, so I'm documenting here how to re-load the necessary libraries.

# setup ssh and vnc on the pi:
You can do this either after install of the python libraries and weather station stuff, or before, then install via vnc or ssh.\
Following steps from here: http://mitchtech.net/vnc-setup-on-raspberry-pi-from-ubuntu/  
ssh pi@[pi ip address]  (need to have ssh already enabled on the pi- do this from setup)\
from ssh/pi command line, run:\
sudo apt-get install tightvncserver\
vncserver :1 -geometry 1366x768 -depth 16 -pixelformat rgb565

# install the weather station stuff:
download this repository with git:\
git clone https://github.com/gesturestudios/rPi_weather_station

make sure python pip and dev are up to date:\
sudo apt-get update\
sudo apt-get upgrage\
sudp apt-get install python3-pip python3-dev libmariadbclient-dev

now that all files are on the pi, we can install the necessary python libraries:\
sudo apt-get install python3-mysqldb\
sudo pip3 install w1thermsensor python-nest\
sudo apt-get install python3-w1thermsensor

change directory into the downloaded git repository and unzip the .tar.gz files.  On fresh install, will need to make this directory first:\
cd Documents/Python_projects/rPi_weather_station

adafruit DHT:\
tar -xvzf Adafruit_Python_DHT.tar.gz\
cd Adafruit_Python_DHT\
sudo python3 setup.py install\
cd ..

adafruit BMP085:\
tar -xvzf Adafruit_Python_BMP.tar.gz\
cd Adafruit_Python_DHT\
sudo python3 setup.py install\
cd ..

finally, open rpi preferences and enable i2c, then reboot.

test libraries- go back to home directory, then\
sudo python3\
from w1thermsensor import W1ThermSensor\
import Adafruit_BMP.BMP085 as BMP085\
import MySQLdb\
import Adafruit_DHT

then exit python and run the scripts from command line:

sudo python3 Documents/Python_projects/rPi_weather_station/InteriorTemps.py\
sudo python3 Documents/Python_projects/rPi_weather_station/PiWeatherStation.py\
sudo python3 Documents/Python_projects/rPi_weather_station/NestToMySQL.py - follow the directions to authorize

set up the crontab to run the script every 5 minutes

*/5 * * * * sudo python3 /home/pi/Documents/Python_projects/rPi_weather_station/InteriorTemps.py\
*/5 * * * * sudo python3 /home/pi/Documents/Python_projects/rPi_weather_station/PiWeatherStation.py\
*/5 * * * * sudo python3 /home/pi/Documents/Python_projects/rPi_weather_station/NestToMySQL.py

### Dashboard setup ###
The visualization for this and all data comes from a shiny dashboard (Home_shiny_dashboard.R).  The script has moved beyond just the data pulled from the sql database to include some google sheet data and other imported things.  On the to-do list is to reduce it back to a script only relating to the weather station, and make a separate version for the complete dashboard...


#!/user/bin/python
import serial
import utm
import lcm
import time

from structgps import gpsdata_t
#from decimal import Decimal

port = serial.Serial( '/dev/ttyACM0', 4800, timeout = 5 ) #timeout=???
lc = lcm.LCM()
msg = gpsdata_t()

while True:
    line = port.readline()
    row = line.split(',')

    if row[0] == '$GPGGA':
	if row[2] == '':
		print 'poor gps signal'
	else:
        	msg.time = row[1]
        	msg.latitude = row[2]
        	msg.latDir = row[3]
        	msg.longitude = row[4]
        	msg.lonDir = row[5]
        	msg.altitude = row[9]
	#NMEA system. ddmm.mmmm ->degree as input of utm -> utm x,y
		#Utm = utm.from_latlon(float(str(msg.latitude)[0:2]) + (float(str(msg.latitude)[2:])) / 60, float(str(msg.longitude)[0:3]) + (float(str(msg.longitude)[3:])) / 60)
		Utm = utm.from_latlon(float(msg.latitude[0:2]) + float(msg.latitude[2:]) / 60, -(float(msg.longitude[1:3]) + float(msg.longitude[3:]) / 60))
		print float(msg.latitude[0:2]) + float(msg.latitude[2:]) / 60, float(msg.longitude[1:3]) + float(msg.longitude[3:]) / 60
		msg.utm_x = str(Utm[0])
		msg.utm_y = str(Utm[1])
		print msg.time, msg.latitude, msg.latDir, msg.longitude, msg.lonDir, msg.altitude, msg.utm_x, msg.utm_y, Utm[2], Utm[3]
        	lc.publish("gpsdata", msg.encode())

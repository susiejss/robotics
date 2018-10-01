#!/user/bin/python
import serial
import utm
import lcm
import time

from structgps import gpsdata_t
#from decimal import Decimal

port = serial.Serial( '/dev/ttyUSB1', 4800, timeout = 5 ) #timeout=???
lc = lcm.LCM()
msg = gpsdata_t()

while True:
    line = port.readline()
    row = line.split(',')

    if row[0] == '$GPGGA':
	if row[2] == '':
		print 'poor gps signal'
	else:
        	msg.time = float(row[1])
        	msg.lat = float(row[2])
		lat = row[2]
        	#msg.latDir = row[3]
        	msg.lon = float(row[4])
		lon = row[4]
        	#msg.lonDir = row[5]
        	msg.alt = float(row[9])
	#NMEA system. ddmm.mmmm ->degree as input of utm -> utm x,y
		#Utm = utm.from_latlon(float(str(msg.latitude)[0:2]) + (float(str(msg.latitude)[2:])) / 60, float(str(msg.longitude)[0:3]) + (float(str(msg.longitude)[3:])) / 60)
		Utm = utm.from_latlon(float(lat[0:2]) + float(lat[2:]) / 60, -(float(lon[1:3]) + float(lon[3:]) / 60))
		#print float(msg.latitude[0:2]) + float(msg.latitude[2:]) / 60, float(msg.longitude[1:3]) + float(msg.longitude[3:]) / 60
		msg.utm_x = float(Utm[0])
		msg.utm_y = float(Utm[1])
		print msg.time, msg.lat, msg.lon, msg.alt, msg.utm_x, msg.utm_y, Utm[2], Utm[3]
        	lc.publish("gpsdata", msg.encode())

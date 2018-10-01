#!/user/bin/python
import serial
import utm
import lcm
import time

from structgps import imu_t

port = serial.Serial( '/dev/ttyUSB0', 115200, timeout = 5 ) #timeout=???
#lc = lcm.LCM('udpm://239.255.76.67:7667?ttl=1')
lc = lcm.LCM()
msg = imu_t()

while True:
    line = port.readline()
    row = line.split(',')

    if row[0] == '$VNYMR':
	msg.yaw = float(row[1])
        msg.pitch = float(row[2])
        msg.roll = float(row[3])
        msg.mag_x = float(row[4])
        msg.mag_y = float(row[5])
        msg.mag_z = float(row[6])
	msg.accel_x = float(row[7])
	msg.accel_y = float(row[8])
	msg.accel_z = float(row[9])
	msg.gyro_x = float(row[10])
	msg.gyro_y = float(row[11])
	z = row[12].split('*')
	msg.gyro_z = float(z[0])

	print msg.yaw, msg.pitch, msg.roll, msg.mag_x, msg.mag_y, msg.mag_z, msg.accel_x, msg.accel_y, msg.accel_z, msg.gyro_x, msg.gyro_y, msg.gyro_z 
        lc.publish("imudata", msg.encode())

import lcm

#from exlcm import example_t
from structgps import gpsdata_t

def my_handler(channel, data):
    msg = gpsdata_t.decode(data)
    print("Received message on channel \"%s\"" % channel)
    print("   time = %s" % msg.time)
    print("   latitude = %s" % msg.latitude)
    print("   latDir = %s" % msg.latDir)
    print("   longitude = %s" % msg.longitude)
    print("   lonDir = '%s'" % msg.lonDir)
    print("   altitude = %s" % msg.altitude)
    print("")

lc = lcm.LCM()
subscription = lc.subscribe("gpsdata", my_handler)

try:
    while True:
        lc.handle()
except KeyboardInterrupt:
    pass

lc.unsubscribe(subscription)

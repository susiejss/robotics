clear all;
% add the lcm.jar file to the matlabpath - need to only do this once
javaaddpath /usr/local/share/java/lcm.jar
javaaddpath /home/susiejss/Lab1/examples/python/mygps_types.jar

% Let’s assume the logging file is lcm-l.02 in the dir below
% open log file for reading

log_file = lcm.logging.Log('/home/susiejss/Lab1/examples/python/data/lcm-log-2018-02-06-15:07:21', 'r'); 

% now read the file 
% here we are assuming that the channel we are interested in is RDI. Your channel 
% name will be different - something to do with GPS
% also RDI has fields altitude and ranges - GPS will probably have lat, lon, utmx,
% utmy etc

n=1;

while true
 %try
   ev = log_file.readNext();
   
   % channel name is in ev.channel
   % there may be multiple channels but in this case you are only interested in RDI channel
   if strcmp(ev.channel, 'gpsdata')
 
     % build gps object from data in this record
      logdata = structgps.gpsdata_t(ev.data);

     % now you can do things like depending upon the rdi_t struct that was defined
      timestamp(n) = str2double(logdata.time);  % (timestamp in microseconds since the epoch)
      lat(n) = str2double(logdata.latitude);
      latD(n)= logdata.latDir;
      lon(n) = str2double(logdata.longitude);
      lonD(n) = logdata.lonDir;
      alt(n) = str2double(logdata.altitude);
      utmx(n) = str2double(logdata.utm_x);
      utmy(n) = str2double(logdata.utm_y);
      %utm_x(n)=utmx(n)-329700;
      %utm_y(n)=utmy(n)-4700730;
      
      n=n+1
   end
 %catch err   % exception will be thrown when you hit end of file
 %   break;
 % end
end

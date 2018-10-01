% add the lcm.jar file to the matlabpath - need to only do this once
javaaddpath /usr/local/share/java/lcm.jar
javaaddpath /home/susiejss/my_robot/mygps_types.jar

% open log file for reading
log_file = lcm.logging.Log('/home/susiejss/my_robot/log/1000StationaryDataIMU', 'r'); 

% now read the file 
% here we are assuming that the channel we are interested in is RDI. Your channel 
% name will be different - something to do with GPS
% also RDI has fields altitude and ranges - GPS will probably have lat, lon, utmx,
% utmy etc

q=1;

while true && (q<1268)
 %try
   evsta = log_file.readNext();
   autotimeIMU(q) = evsta.utime;
   datetimeIMU(q) = datetime(autotimeIMU(q)/1e+6, 'ConvertFrom', 'posixtime'); % convert the timestamp to human readable format

 %catch err   % exception will be thrown when you hit end of file
 %   break;
 % end
   if strcmp(evsta.channel, 'imudata')
 
     % build gps object from data in this record
      logdataimuI = structgps.imu_t(evsta.data);

     % now you can do things like depending upon the rdi_t struct that was defined
      yawI(q) = logdataimuI.yaw;  % (timestamp in microseconds since the epoch)
      pitchI(q) = logdataimuI.pitch;
      rollI(q) = logdataimuI.roll;
      mag_xI(q) = logdataimuI.mag_x;
      mag_yI(q) = logdataimuI.mag_y;
      mag_zI(q) = logdataimuI.mag_z;
      accel_xI(q) = logdataimuI.accel_x;
      accel_yI(q) = logdataimuI.accel_y;
      accel_zI(q) = logdataimuI.accel_z; 
      gyro_xI(q) = logdataimuI.gyro_x;
      gyro_yI(q) = logdataimuI.gyro_y;
      gyro_zI(q) = logdataimuI.gyro_z;  
      
      q=q+1;
   end
end

dt = datetimeIMU - datetime(2018,2,23);
ddt = seconds(dt);
dddt = ddt-repmat(ddt(1),1,1267);%time series. 40HZ
%% plot time series of each 
figure(50);
scatter(dddt,gyro_zI,'+','DisplayName','gyro_z stationary data');
gyroznoise=mean(gyro_zI);
hold on;
scatter((max(dddt)-min(dddt))/2,gyroznoise,'DisplayName','mean point');
hold off;
legend('show');
xlabel('time(s)'); % x-axis label
ylabel('gyro_z (rad/s)'); % y-axis label
title('gyro_z versus time');

figure(51);
scatter(dddt,accel_xI,'+','DisplayName','accelx stationary data');
accelxnoise=mean(accel_xI);
hold on;
scatter((max(dddt)-min(dddt))/2,accelxnoise,'DisplayName','mean point');
hold off;
legend('show');

figure(51);
scatter(dddt,mag_xI,'+','DisplayName','magx stationary data');
magxnoise=mean(mag_xI);
hold on;
scatter((max(dddt)-min(dddt))/2,magxnoise,'DisplayName','mean point');
hold off;
legend('show');
xlabel('time(s)'); % x-axis label
ylabel('mag_x (G)'); % y-axis label
title('mag_x versus time');

figure(51);
scatter(dddt,yawI,'+','DisplayName','yaw stationary data');
yawnoise=mean(yawI);
hold on;
scatter((max(dddt)-min(dddt))/2,yawnoise,'DisplayName','mean point');
hold off;
legend('show');
xlabel('time(s)'); % x-axis label
ylabel('yaw (degree)'); % y-axis label
title('yaw versus time');


accelxnoise=mean(accel_xI);
accelynoise=mean(accel_yI);
accelznoise=mean(accel_zI);



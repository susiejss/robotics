clear all;
% add the lcm.jar file to the matlabpath - need to only do this once
javaaddpath /usr/local/share/java/lcm.jar
javaaddpath /home/susiejss/my_robot/mygps_types.jar

% open log file for reading
log_file = lcm.logging.Log('/home/susiejss/my_robot/lcm-log-run1', 'r'); 
n=1;
m=1;

while true && m<20645
 %try
   ev = log_file.readNext();
   autotime(m) = ev.utime;
   datetimee(m) = datetime(autotime(m)/1e+6, 'ConvertFrom', 'posixtime'); % convert the timestamp to human readable format
   
   % channel name is in ev.channel
   % there may be multiple channels but in this case you are only interested in RDI channel
   if strcmp(ev.channel, 'GPS')
 
     % build gps object from data in this record
      logdatagps = structgps.gpsdata_t(ev.data);

     % now you can do things like depending upon the rdi_t struct that was defined
      time(n) = logdatagps.time;  % (timestamp in microseconds since the epoch)
      lat(n) = logdatagps.lat;
      lon(n) = logdatagps.lon;
      alt(n) = logdatagps.alt;
      utmx(n) = logdatagps.utm_x;
      utmy(n) = logdatagps.utm_y;
      
      n=n+1;
   end
 %catch err   % exception will be thrown when you hit end of file
 %   break;
 % end
   if strcmp(ev.channel, 'IMU')
 
     % build gps object from data in this record
      logdataimu = structgps.imu_t(ev.data);

     % now you can do things like depending upon the rdi_t struct that was defined
      yaw(m) = logdataimu.yaw;  % (timestamp in microseconds since the epoch)
      pitch(m) = logdataimu.pitch;
      roll(m) = logdataimu.roll;
      mag_x(m) = logdataimu.mag_x;
      mag_y(m) = logdataimu.mag_y;
      mag_z(m) = logdataimu.mag_z;
      accel_x(m) = logdataimu.accel_x;
      accel_y(m) = logdataimu.accel_y;
      accel_z(m) = logdataimu.accel_z; 
      gyro_x(m) = logdataimu.gyro_x;
      gyro_y(m) = logdataimu.gyro_y;
      gyro_z(m) = logdataimu.gyro_z;
      
      m=m+1;
   end
end

%% fix time series data
alldt = seconds(datetimee - datetime(2018,2,21));
timeseries = alldt-repmat(alldt(1),1,20644);%time series. 40HZ

%% plot first 1 turns for calibration
selectmagx=mag_x(4117:4848); %only use 1 round data
selectmagy=mag_y(4117:4848);

%% update mag_x,mag_y(eliminate hard-iron effect)
a=(max(selectmagx)+min(selectmagx))/2;%current center of ellipse
b=(max(selectmagy)+min(selectmagy))/2;

[~,colsize]=size(mag_x);
mag_x=mag_x-repmat(a,1,colsize);
mag_y=mag_y-repmat(b,1,colsize);


%% correct soft-iron effect(fit an ellipse) and get yaw for all mag data
% 1.Fit allellipse to get phi, then rotate to get allellipsefix
allellipse=fit_ellipse(mag_x,mag_y);
w=-(allellipse.phi);
%R=[cos(w),sin(w);-sin(w),cos(w)];
for i=1:1:20644
  newx(i)= cos(w)*mag_x(i)+sin(w)*mag_y(i);
  newy(i)= -sin(w)*mag_x(i)+cos(w)*mag_y(i);
end
%check rotated circle
% figure(9);
% scatter(newx,newy,'+');
allellipsefix=fit_ellipse(newx,newy);
% title('rotated magnetometer readings');

% 2.correct allellipsefix to circle-allellipsefixult
A=allellipsefix.a;
B=allellipsefix.b;
ra=0.25;%self-regulated radius,set a similar value?
for j=1:1:20644
  ultmagX(j) = ra*newx(j)/A;
  ultmagY(j) = ra*newy(j)/B;
end
%check corrected circle
% figure(10);
% scatter(ultmagX,ultmagY,'+');
allellipsefixult=fit_ellipse(ultmagX,ultmagY);
% title('corrected magnetometer readings');

% %%plot yaw from mag measurement
% for z=1:1:20644
%   magyaw(z)=(atan(ultmagY(z)/ultmagX(z)))*180/pi;
% end
% figure(11);
% plot(1:20644,magyaw);

% 3.rotate back the phi to get original angle
v= allellipse.phi;
for l=1:1:20644
  newultx(l)= cos(v)*ultmagX(l)+sin(v)*ultmagY(l);
  newulty(l)= -sin(v)*ultmagX(l)+cos(v)*ultmagY(l);
end

%check back-rotated circle
figure(11);
scatter(newultx,newulty,'+');
allellipsefixnew=fit_ellipse(newultx,newulty);
title('back-rotated magnetometer readings');

%% delete noise from gyro-z data
gyroznoise = 7.227168755858916e-04;
gyro_znew =gyro_z-repmat(gyroznoise,1,20644);

%% plot yaw from back-rotated mag measurement & put into low-pass filter 
for zz=1:1:20644
  magyawnew(zz)=(atan2(-newulty(zz),newultx(zz)))*180/pi;%note must use atan2 beause atan only return -90~90 deg
end

%put mag yaw to low-pass filter
nn=1;
Wn=0.02;
ftype='low';
[bb,aa] = butter(nn,Wn,ftype);
dataIn = magyawnew;
magyawOut = filter(bb,aa,dataIn);
figure(12);
plot(timeseries,magyawnew,'DisplayName','mag yaw before');
hold on;
plot(timeseries,magyawOut,'DisplayName','mag yaw after');
hold off;
legend('show');
title('mag yaw before and after low-pass filter');

%% get yaw integrated from gyro-z
angle = cumtrapz(timeseries,gyro_znew);
yawangle(:) = angle(:)*180/pi;
initialMagYaw = mean(magyawnew(1:200));
yawangle = yawangle + repmat(initialMagYaw,1,20644);
yawangle = wrapTo180(yawangle);

%put gyro-z yaw to high-pass filter
nnn=1;
Wnn=0.02;
ftypee='high';
[bbb,aaa] = butter(nnn,Wnn,ftypee);
dataInn = yawangle;
gyroyawOut = filter(bbb,aaa,dataInn);
figure(13);
plot(timeseries,gyroyawOut,'DisplayName','gyro yaw after');
hold on;
plot(timeseries,yawangle,'DisplayName','gyro yaw before');
hold off;
legend('show');
title('yaw plot from gyro-z after high-pass filter');

%% complementary filter
alpha=0.98;
yawOut=alpha*(magyawOut)+(1-alpha)*(gyroyawOut);
%yawOut=yawOut+repmat(50,1,20644);
yawOut=wrapTo180(yawOut);%limit to -180~180

figure(16);
plot(timeseries,yawOut,'DisplayName','complementary yaw');
hold on;
plot(timeseries,yaw,'DisplayName','IMU yaw reading');
hold off;
legend('show');
xlabel('timeseries(s)'); % x-axis label
ylabel('yaw angle(degree)'); % y-axis label
title('IMU yaw reading & complementary yaw');

figure(17);
plot(timeseries,yawOut,'DisplayName','complementary yaw');
hold on;
plot(timeseries,yawangle,'DisplayName','gyro-z yaw');
hold on;
plot(timeseries,magyawnew,'DisplayName','mag yaw');
hold off;
legend('show');
title('before filter yaw & complementary yaw');
xlabel('timeseries(s)'); % x-axis label
ylabel('yaw angle(degree)'); % y-axis label

figure(18);
plot(timeseries,yawOut,'DisplayName','complementary yaw');
hold on;
plot(timeseries,gyroyawOut,'DisplayName','gyro-z yaw after high-pass filter');
hold on;
plot(timeseries,magyawOut,'DisplayName','mag yaw after low-pass filter');
hold off;
legend('show');
title('after filter yaw & complementary yaw');
xlabel('timeseries(s)'); % x-axis label
ylabel('yaw angle(degree)'); % y-axis label

%% integrate accel-x
%integrate accel
%eliminate accumulated g when stopping
meanave=mean(accel_x(1:120));
acc_x=accel_x-repmat(meanave,1,20644);
acc_x(160:20644)=acc_x(160:20644)-repmat(mean(acc_x(160:200)),1,20485);%4-5s not moving
acc_x(240:20644)=acc_x(240:20644)-repmat(mean(acc_x(240:440)),1,20405);%6-11s not moving
acc_x(480:20644)=acc_x(480:20644)-repmat(mean(acc_x(480:840)),1,20165);%4-5s not moving
acc_x(880:20644)=acc_x(880:20644)-repmat(mean(acc_x(880:1040)),1,19765);%4-5s not moving
acc_x(15760:20644)=acc_x(15760:20644)-repmat(mean(acc_x(15760:16760)),1,4885);%4-5s not moving

%eliminate constant accel during some period
ave1=mean(acc_x(6440:15760));
acc_x(6440:15760)=acc_x(6440:15760)-repmat(ave1,1,9321);

v_x=cumtrapz(timeseries,acc_x);

figure(19);
plot(timeseries,v_x);
title('v_x vs time');
xlabel('time(s)'); % x-axis label
ylabel('v_x(m/s)'); % y-axis label

for ij=1:1:20644
  wX(ij)=gyro_znew(ij) * v_x(ij);
end

%compare wX to yob..(accel_y)
figure(20);
plot(timeseries,wX,'DisplayName','wX vs time');
hold on;
plot(timeseries,acc_y,'DisplayName','yobs.. vs time');
hold off;
legend('show');
title('compare wX to yobs..');
xlabel('time(s)'); % x-axis label
ylabel('accel_y(m/s^2)'); % y-axis label

%% estimate trajectory
for mn=1:1:20644
  vn(mn)=v_x(mn) * cos((yawOutfix(mn) * pi)/180);
  ve(mn)=v_x(mn) * sin((yawOutfix(mn) * pi)/180);
end

Xn=cumtrapz(timeseries,vn);
Xe=cumtrapz(timeseries,ve);

% trying to correct v
time=1:1:514;
utmxfix=utmx-repmat(utmx(1),1,514);
utmyfix=utmy-repmat(utmy(1),1,514);

%inital angle of utm
Utmangle=atan2(utmyfix,utmxfix)*180/pi;
phidiff=-20;%initial angle difference between utm route and IMU 
yawOutfix=wrapTo180(yawOut+repmat(phidiff,1,20644));

%plot comparison route
figure(32);
plot(utmxfix*7/6,utmyfix,'DisplayName','driving route plot');
hold on;
plot((Xe*7)/(1.9*6),Xn/1.9,'DisplayName','estimated driving route plot');
hold off;
legend('show');
title('scaled estimated(x,y shrink by 1.9) and actual driving route plot');
xlabel('X direction displacement(m)'); % x-axis label
ylabel('y direction displacement(m)'); % y-axis label

% estimate xc=0.0752
for pq=1:1:20644
  xc(pq)=(acc_x(pq) * sin(yawOutfix(pq))-gyro_znew(pq) * vn(pq)-acc_x(pq))/(gyro_znew(pq)*gyro_znew(pq));
end
count=0;
total=0;
for gn=1:1:20644
  if ((xc(gn)<1) && (xc(gn)>-1))
    total=total+xc(gn);
    count=count+1;
  end
end
xcfinal=total/count;

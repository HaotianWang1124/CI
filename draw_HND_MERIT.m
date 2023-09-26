% clear;
% clc;

% define your own directory
PATH_DEF = '/Users/apple/Downloads/Project';

load('LSTM/DAT_OUT_HND.mat');

DAT_OUT_HND(DAT_OUT_HND==-9999)=nan;
DAT_OUT_HND(DAT_OUT_HND<-0.00001)=nan;



% mydir = pwd; idx = strfind(mydir,filesep); mydir = mydir(1:idx(end)-1);
%
% PATH_DEF = [mydir,'/Dataset'];
% clear mydir idx
% PATH_IN = [PATH_DEF,'/Water_Mask/JRC_GSW/Recurrence'];
% PATH_OUT = [PATH_DEF,'/CYGNSS/Gridded'];
load([PATH_DEF,'/Draw/Dataset/EASE2_Grid/EASE2_M03KM_GEO.mat'],'EASE2_LAT','EASE2_LON');

latlim = [-90 90];
lonlim = [-180 180];
study_area = 'Globe';

%Read files based on date
% DATE_RANGE = datenum('2017-03-18');
% iyr = datestr(DATE_RANGE,'yyyy');
% idoy = datevec2doy(DATE_RANGE);
% % fname_out = sprintf('%s\\CYGNSS_L1_V21_EASE2_3KM_%s_%03d.mat',PATH_DEF,iyr,idoy);
% fname_out = sprintf('%s/CYGNSS/CYGNSS_L1_V21_EASE2_3KM_%s_%03d.mat', PATH_DEF, iyr, idoy);


% CYGNSS reflectivity
% DAT_OUT_WMK = nan(size(EASE2_LON)); DAT_OUT_WMK(IDX_GRID) = DAT_REFLT;
range_DAT= 0:1:150;
myColor_DAT = 'Spectral'; % 'YlOrRd' '*Spectral', reverse, 'Spectral'
myYTickLabel = {'-90','-80','-70','-60','-50','-40','-30','-20','-10','0','10','20','30','40','50','60','70','80','90'};
myYTick = [0.5 20.5 40.5 60.5 80.5 100.5 120.5];
myYAxisLoc = 'bottom';
filename = 'HAND_1KM_MERIT.tif';
sub_title = 'HAND_3KM';
plot_map(EASE2_LON,EASE2_LAT,lonlim,latlim,DAT_OUT_HND,PATH_DEF,...
    range_DAT,myColor_DAT,filename,sub_title,myYTickLabel,myYTick,myYAxisLoc);

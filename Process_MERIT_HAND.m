clc;
clear;
close all;

mydir = pwd; idx = strfind(mydir,filesep); mydir = mydir(1:idx(end)-1);
PATH_DEF = [mydir,'/Dataset']; clear mydir idx

%% read MERIT HAND data and upscale to 1KM as package level
PATH_TILE = [PATH_DEF,'/MERIT'];
PATH_OUT = [PATH_DEF,'/MERIT/MERIT_1KM'];

% get package names and lat&lon from foldername
FPAC = func_subfoldername(PATH_TILE);

% set mosaic map for a package size, total package number is 60 (except 3
% nan)
for ii=1:length(FPAC)

    HND_PAC{ii,1} = nan(3600,3600);
    HND_PAC{ii,2} = 0;
    HND_PAC{ii,3} = 0;
    LAT_INFO_TOT{ii} = nan(3600,1);
    LON_INFO_TOT{ii} = nan(1,3600);

    LAT_STR=FPAC{ii}(5:7);
    LON_STR=FPAC{ii}(8:11);
    LAT_MIN=str2double(FPAC{ii}(6:7));
    LON_MIN=str2double(FPAC{ii}(9:11));
    if isnan(LAT_MIN); LAT_MIN=0; end
    if isnan(LON_MIN); LON_MIN=0; end

    if FPAC{ii}(5) == 's' ; LAT_MIN = -LAT_MIN; end
    if FPAC{ii}(8) == 'w' ; LON_MIN = -LON_MIN; end


    LAT_MAX = LAT_MIN+25;
    LON_MAX = LON_MIN+25;
    LAT_TILE = LAT_MIN:5:LAT_MAX;
    LON_TILE = LON_MIN:5:LON_MAX;
    [LON_TILE_INT,LAT_TILE_INT] = meshgrid(LON_TILE,LAT_TILE);
    LON_TILE = reshape(LON_TILE_INT,[],1);
    LAT_TILE = reshape(LAT_TILE_INT,[],1);
    NUM_TILE = length(LAT_TILE);

    HND_PAC{ii,2}=LAT_MIN;
    HND_PAC{ii,3}=LON_MIN;

    PATH_PAC = [PATH_TILE,'/',FPAC{ii},'/',FPAC{ii}];
    fname_tot = func_subfilename(PATH_PAC);


    for jj=1:length(fname_tot)
        temp_str=fname_tot{jj};
        disp([temp_str , ' is processing!']);

        lat_tile=temp_str(1:3);
        lon_tile=temp_str(4:7);
        lat_tile_num=str2double(temp_str(2:3));
        lon_tile_num=str2double(temp_str(5:7));
        if isnan(lat_tile_num); lat_tile_num=0; end
        if isnan(lon_tile_num); lon_tile_num=0; end

        if temp_str(1) == 's' ; lat_tile_num = -lat_tile_num; end
        if temp_str(4) == 'w' ; lon_tile_num = -lon_tile_num; end

        % upscaling MERIT to 1KM mid-scale using blocknanmean method
        [HND_TLE_90M,R] = readgeoraster([PATH_PAC,'/', fname_tot{jj}]);


        % obtain the boundary information
        LAT_LIM = R.LatitudeLimits;
        LAT_INT = R.CellExtentInLatitude;
        LON_LIM = R.LongitudeLimits;
        LON_INT = R.CellExtentInLongitude;

        % get the latitude and longitude information
        LAT_INFO = LAT_LIM(1):LAT_INT:LAT_LIM(2);
        LON_INFO = LON_LIM(1):LON_INT:LON_LIM(2);
        LAT_INFO = flipud(LAT_INFO);

        % upper left to center
        LAT_INFO = LAT_INFO - LAT_INT/2;
        LAT_INFO = LAT_INFO(1:end-1);
        LON_INFO = LON_INFO + LON_INT/2;
        LON_INFO = LON_INFO(1:end-1);

        LAT_INFO = LAT_INFO';

        % reduce size by averaging grids beforehand
        HND_TLE_1KM{jj} = BlockNaNMean(HND_TLE_90M,10,10);
        LAT_INFO_1KM{jj} = BlockMean(LAT_INFO,10,1);
        LON_INFO_1KM{jj} = BlockMean(LON_INFO,1,10);

        %         HND_TLE_1KM{jj} = reshape(HND_TLE_1KM{jj},[],1);
        %         LAT_INFO_1KM{jj} = LAT_INFO_1KM{jj}';

        % regridding index information
        HND_TLE_1KM{jj}=flip(HND_TLE_1KM{jj});
        col = ceil((lon_tile_num-LON_MIN)/5);
        row = ceil((lat_tile_num-LAT_MIN)/5);

        ROW_INT=size(HND_TLE_1KM{jj},1)*(row)+1;
        COL_INT=size(HND_TLE_1KM{jj},2)*(col)+1;
        HND_PAC{ii}(ROW_INT:ROW_INT+599,COL_INT:COL_INT+599) = HND_TLE_1KM{jj};
        HND_TLE_1KM{jj}=flip(HND_TLE_1KM{jj});

        LAT_INFO_TOT{ii}(ROW_INT:ROW_INT+599,1) = LAT_INFO_1KM{jj};
        LON_INFO_TOT{ii}(1,COL_INT:COL_INT+599) = LON_INFO_1KM{jj};

        disp([fname_tot{jj} , ' is finished!']);

    end

    HND_PAC{ii}=flip(HND_PAC{ii});

    disp(FPAC{ii});
end

disp('Upscaling is finished!');

% save mid-scale package MERIT data as tif files


%% Mosaic mid-scale package MERIT data to global data

HND_GLB = nan(18000,43200);
LAT_INFO_GLB = nan(18000,1);
LON_INFO_GLB = nan(1,43200);

for ii=1:size(HND_PAC,1)

    LAT_GLB_MIN = -60;
    LON_GLB_MIN = -180;
    LAT_GLB_MAX = 60;
    LON_GLB_MAX = 150;
    LAT_PAC = LAT_GLB_MIN:30:LAT_GLB_MAX;
    LON_PAC = LON_GLB_MIN:30:LON_GLB_MAX;
    [LON_PAC_INT,LAT_PAC_INT] = meshgrid(LON_PAC,LAT_PAC);
    LON_PAC = reshape(LON_PAC_INT,[],1);
    LAT_PAC = reshape(LAT_PAC_INT,[],1);
    NUM_PAC = length(LAT_PAC);

    disp(['hand ' , num2str(HND_PAC{ii,2}), ' ', num2str(HND_PAC{ii,3}), ' is processing!']);

    % regridding index information
    HND_PAC{ii,1}=flip(HND_PAC{ii,1});
    col = ceil((HND_PAC{ii,3}-LON_GLB_MIN)/30);
    row = ceil((HND_PAC{ii,2}-LAT_GLB_MIN)/30);

    ROW_INT=size(HND_PAC{ii,1},1)*(row)+1;
    COL_INT=size(HND_PAC{ii,1},2)*(col)+1;
    HND_GLB(ROW_INT:ROW_INT+3599,COL_INT:COL_INT+3599) = HND_PAC{ii,1};
    HND_PAC{ii,1}=flip(HND_PAC{ii,1});

    LAT_INFO_GLB(ROW_INT:ROW_INT+3599,1) = LAT_INFO_TOT{ii};
    LON_INFO_GLB(1,COL_INT:COL_INT+3599) = LON_INFO_TOT{ii};

    disp(['hand ' ,num2str(HND_PAC{ii,2}), ' ', num2str(HND_PAC{ii,3}), ' is finished!']);

end

HND_GLB=flip(HND_GLB);

save('HND_GLB.mat', 'HND_GLB', '-v7.3');


disp('Mosaic MERIT to global hand data is finished!');

save mid-scale tif data
HND_GLB=flipud(HND_GLB);

latlim = [min(EASE2_LAT_TEMP(:)), max(EASE2_LAT_TEMP(:))];
lonlim = [min(EASE2_LON_TEMP(:)), max(EASE2_LON_TEMP(:))];
R = georefcells(latlim, lonlim, size(hand));

outputFileName = fullfile(PATH_OUT,'HAND_1KM_MERIT.tif');

% set data and Ref as GeoTIFF
geotiffwrite(outputFileName, HND_GLB, R);

metadata = geotiffinfo(outputFileName);
metadata.GeoTIFFTags.GeoKeyDirectoryTag.GTModelTypeGeoKey = 2; % ModelType: Geographic (Lat/Long)
metadata.GeoTIFFTags.GeoKeyDirectoryTag.GTRasterTypeGeoKey = 1; % RasterType: PixelIsArea
metadata.GeoTIFFTags.GeoKeyDirectoryTag.GeographicTypeGeoKey = 4326; % GeographicCoordinateSystem: WGS 84

geotiffwrite(outputFileName, HND_GLB, R, 'GeoKeyDirectoryTag', metadata.GeoTIFFTags.GeoKeyDirectoryTag);


%% upscaling MERIT to 3KM using dropinbucket
disp('Dropinbucket upscaling start!');

load([PATH_DEF,'/MERIT/HND_GLB.mat']);
load([PATH_DEF,'/MERIT/HND_LOCA.mat']);

% load EASE2-Grid information
M = load([PATH_DEF,'/EASE2_Grid/EASE2_M03KM_GEO.mat']);
EASE2_LAT_TEMP = M.EASE2_LAT(:,1);
EASE2_LON_TEMP = M.EASE2_LON(1,:);
MASK_LOCI = M.MASK_LOCI; clear M %get x&y of MASK_LOCI, also the reseach area bonduary

%set lat&lon
LAT_TILE = 90:-10:-60;
LON_TILE = -180:10:180;
[LON_TILE,LAT_TILE] = meshgrid(LON_TILE,LAT_TILE);
LON_TILE = reshape(LON_TILE,[],1);
LAT_TILE = reshape(LAT_TILE,[],1);

% define the output DAT_Water_MASK of EASE2-Grid 3-km
DAT_OUT_HND = nan(size(MASK_LOCI));

DAT_OUT_HND = reshape(DAT_OUT_HND,[],1);

% get the latitude and longitude information of global hand data
idx_lat_tot = interp1(EASE2_LAT_TEMP, 1:length(EASE2_LAT_TEMP), LAT_INFO_GLB, 'nearest');
idx_lon_tot = interp1(EASE2_LON_TEMP, 1:length(EASE2_LON_TEMP), LON_INFO_GLB, 'nearest');
idx_lat_tot = repmat(idx_lat_tot,1,length(LON_INFO_GLB));
idx_lon_tot = repmat(idx_lon_tot,length(LAT_INFO_GLB),1);
IDX_GRID = (idx_lon_tot-1)*length(EASE2_LAT_TEMP) + idx_lat_tot;
IDX_GRID(isnan(IDX_GRID)) = 1;
IDX_GRID = reshape(IDX_GRID,[],1);

disp('Dropinbucket upscaling is starting!');
% average for unique grids
[idx_uniq,~,~] = unique(IDX_GRID);
meanVector = splitapply(@(x) nanmean(x), DAT_OUT_HND, findgroups(IDX_GRID));
DAT_OUT_HND(idx_uniq) = meanVector;

save('DAT_OUT_HND.mat', 'DAT_OUT_HND', '-v7.3');

disp('Dropinbucket upscaling finish!');

%% get easev2 tif
DAT_OUT_HND=flipud(DAT_OUT_HND);

latlim = [min(EASE2_LAT_TEMP(:)), max(EASE2_LAT_TEMP(:))];
lonlim = [min(EASE2_LON_TEMP(:)), max(EASE2_LON_TEMP(:))];
R = georefcells(latlim, lonlim, size(hand));

outputFileName = fullfile('HAND_1KM_MERIT.tif');

% set data and Ref as GeoTIFF
geotiffwrite(outputFileName, DAT_OUT_HND, R);

metadata = geotiffinfo(outputFileName);
metadata.GeoTIFFTags.GeoKeyDirectoryTag.GTModelTypeGeoKey = 2; % ModelType: Geographic (Lat/Long)
metadata.GeoTIFFTags.GeoKeyDirectoryTag.GTRasterTypeGeoKey = 1; % RasterType: PixelIsArea
metadata.GeoTIFFTags.GeoKeyDirectoryTag.GeographicTypeGeoKey = 4326; % GeographicCoordinateSystem: WGS 84

geotiffwrite(outputFileName, DAT_OUT_HND, R, 'GeoKeyDirectoryTag', metadata.GeoTIFFTags.GeoKeyDirectoryTag);



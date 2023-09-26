import asf_tools.hand.calculate
import numpy as np
from pysheds.grid import Grid
import rasterio
from asf_tools.hand.calculate import *

# get hydro data from https://www.hydrosheds.org/hydrosheds-core-downloads
output_HAND = r'C:\Users\haw23012\PycharmProjects\pythonProject\Data\pyshed_testdata/HAND_1KM_SRTM_preprocess_land.tif'

# input pre-processed SRTM data and get fdr and acc
dem_file = r'C:\Users\haw23012\PycharmProjects\pythonProject\Data\DEM\SRTM_1KM_EASE2_3KM_GRID_HGT.tif'
dem_file_out = r'C:\Users\haw23012\PycharmProjects\pythonProject\Data\DEM\Modiify_SRTM_1KM_EASE2_3KM_GRID_HGT_test.tif'
grid = Grid.from_raster(dem_file)

# input land and ocean mask data
landmask_file = r'C:\Users\haw23012\PycharmProjects\pythonProject\Data\Land Mask\EASE2_M03km.LOCImask_land50_coast0km.11568x4872.bin'
landmask_file_out = r'C:\Users\haw23012\PycharmProjects\pythonProject\Data\Land Mask\LMK_EASE2_3KM.tif'

with rasterio.open(dem_file) as src:
    profile = src.profile
    data = src.read(1)  # Assuming data is in the first band
    # Update nodata values in data to np.nan
    current_nodata = src.nodata
    data = data.astype('float32')  # Convert data to float32
    data[data == current_nodata] = np.nan
    # Update profile to reflect new nodata value and dtype
    profile.update(
        dtype=rasterio.float32,
        nodata=np.nan
    )

# Write the modified data back to a new raster file
with rasterio.open(dem_file_out, 'w', **profile) as dst:
    dst.write(data, 1)

# calculate fdr and acc using pysheds
dem = grid.read_raster(dem_file_out)
inflated_dem = grid.resolve_flats(dem)
fdr = grid.flowdir(inflated_dem)
acc = grid.accumulation(fdr)

# Compute HAND
# acc >= 48 is the empirical threshold for stream pixels, for 30s data.
hand = grid.compute_hand(fdr, dem, acc >= 48, inplace=False)

# deal with nodata
hand_filled = asf_tools.hand.calculate.fill_hand(hand, dem)

# remove the ocean pixel with land mask
with open(landmask_file, 'rb') as lmk:
    land_mask = lmk.read()

# turn binary_data to NumPy
land_mask = np.frombuffer(land_mask, dtype=np.uint8)

reshaped_land_mask = np.reshape(land_mask, (4872, 11568))

with rasterio.open(dem_file) as src:
    profile = src.profile
    with rasterio.open(landmask_file_out, 'w', **profile ) as dst:
        dst.write(reshaped_land_mask, 1)

# if the data is marked as ocean, then remove
hand_land = hand_filled
hand_land[reshaped_land_mask != 0] = np.nan

# set the proper nodata for hydroshed dem
with rasterio.open(dem_file) as src:
    profile = src.profile
    with rasterio.open(output_HAND, 'w', **profile ) as dst:
        dst.write(hand_land, 1)

import numpy as np
from pysheds.grid import Grid
import rasterio
from asf_tools.hand.calculate import *

# get hydro data from https://www.hydrosheds.org/hydrosheds-core-downloads
dem_file = r'C:\Users\haw23012\PycharmProjects\pythonProject\Data\pyshed_testdata/hyd_na_dem_30s.tif'
dem_file_out = r'C:\Users\haw23012\PycharmProjects\pythonProject\Data\pyshed_testdata/hyd_na_dem_30s_modify.tif'
fdr_file = r'C:\Users\haw23012\PycharmProjects\pythonProject\Data\pyshed_testdata/hyd_na_dir_30s.tif'
acc_file = r'C:\Users\haw23012\PycharmProjects\pythonProject\Data\pyshed_testdata/hyd_na_acc_30s.tif'
output_HAND = r'C:\Users\haw23012\PycharmProjects\pythonProject\Data\pyshed_testdata/HAND30s_hydroshed.tif'


# set the proper nodata for hydroshed dem
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

# similar for acc, in this case we just need array
with rasterio.open(acc_file) as src:
    acc_nodata = src.nodata

# Read data with pysheds
grid = Grid.from_raster(fdr_file)
dem = grid.read_raster(dem_file_out)
acc = grid.read_raster(acc_file)
# assign nodata to acc
acc = acc.astype('float32')
acc[acc == acc_nodata] = np.nan
fdir = grid.read_raster(fdr_file)

# Compute HAND
# acc >= 48 is the empirical threshold for stream pixels, for 30s data.
hand = grid.compute_hand(fdir, dem, acc >= 48, inplace=False)

with rasterio.open(output_HAND, 'w', **profile) as dst:
    dst.write(hand, 1)
import asf_tools.hand.calculate
import numpy as np
from pysheds.grid import Grid
import rasterio
from asf_tools.hand.calculate import *
from osgeo import gdal, osr


# input land and ocean mask data
landmask_file = r'C:\Users\haw23012\PycharmProjects\pythonProject\Data\Land Mask\EASE2_M03km.LOCImask_land50_coast0km.11568x4872.bin'
landmask_file_out = r'C:\Users\haw23012\PycharmProjects\pythonProject\Data\Land Mask\LMK_EASE2_3KM.tif'
dem_file = r'C:\Users\haw23012\PycharmProjects\pythonProject\Data\DEM\SRTM_1KM_EASE2_3KM_GRID_HGT.tif'


# remove the ocean pixel with land mask
with open(landmask_file, 'rb') as lmk:
    land_mask = lmk.read()

    # 将binary_data转换为NumPy数组
    # 假设数据类型为uint8，您可以根据实际情况更改数据类型
land_mask = np.frombuffer(land_mask, dtype=np.uint8)

reshaped_land_mask = np.reshape(land_mask, (4872, 11568))
uni = np.unique(reshaped_land_mask)

with rasterio.open(dem_file) as src:
    profile = src.profile
    with rasterio.open(landmask_file_out, 'w', **profile ) as dst:
        dst.write(reshaped_land_mask, 1)


import netCDF4 as nc

# get cdf file
with nc.Dataset(r'D:\HAND\Data\Land Mask\watermask.nc', 'r') as file:
    variable_names = file.variables.keys()


# print var name list
print("var：", variable_names)

### File to run whatever we want to

import data_utils
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

## Remove cahced_fname and give no arguments for a fresh data read
nyt_data = data_utils.load_nyt_data(cached_fname='cached_data/NYT_11-02-21.csv')
# jh_data = data_utils.load_jh_data()
ucla_data = data_utils.load_ucla_data(cached_fname='./cached_data/UCLA_11-02-21.csv')

# # Example of using the data utils functions for a specific facility for specific dates
bibb_df = pd.DataFrame(data_utils.select_facility(ucla_data, 'BIBB CORRECTIONAL FACILITY'))
bibb_df = pd.DataFrame(data_utils.select_date_range_UCLA(bibb_df, '04-01-2020', '10-01-2020'))
print(bibb_df.head(100))

print('Done')
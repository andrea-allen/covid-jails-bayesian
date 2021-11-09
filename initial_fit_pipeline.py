import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy.stats
import pystan
from data_utils import *

sample_facility = 'CALIFORNIA STATE PRISON LOS ANGELES'
sample_covid_data = load_ucla_data(cached_fname='./cached_data/UCLA_11-02-21.csv')
la_county = pd.DataFrame(select_county(sample_covid_data, 'LOS ANGELES', 'California'))
for facility in set(la_county['Name'].values):
    la_metro = pd.DataFrame(select_facility(la_county, facility))
    la_metro = pd.DataFrame(select_date_range_UCLA(la_metro, "05-01-2020", "02-01-2021"))
    la_metro.dropna()
    try:
        plt.scatter(la_metro[['Date']], la_metro[['Residents.Active']], label=facility)
        plt.legend()
        plt.show()
    except:
        continue
    # plt.scatter(la_metro[['Date']], la_metro[['Residents.Confirmed']])
plt.show()
print('done')
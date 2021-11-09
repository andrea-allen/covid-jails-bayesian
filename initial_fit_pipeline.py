import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy.stats
import pystan
from data_utils import *
import seaborn as sns
import pickle

sample_facility = 'CALIFORNIA STATE PRISON LOS ANGELES'
sample_covid_data = load_ucla_data(cached_fname='./cached_data/UCLA_11-02-21.csv')
la_county = pd.DataFrame(select_county(sample_covid_data, 'LOS ANGELES', 'California'))
# for facility in set(la_county['Name'].values):
#     la_metro = pd.DataFrame(select_facility(la_county, facility))
#     la_metro = pd.DataFrame(select_date_range_UCLA(la_metro, "05-01-2020", "02-01-2021"))
#     la_metro.dropna()
#     try:
#         plt.scatter(la_metro[['Date']], la_metro[['Residents.Active']], label=facility)
#         plt.legend()
#         plt.show()
#     except:
#         continue
#     # plt.scatter(la_metro[['Date']], la_metro[['Residents.Confirmed']])
# plt.show()

la_metro = pd.DataFrame(select_facility(la_county, sample_facility))
la_metro = pd.DataFrame(select_date_range_UCLA(la_metro, "05-01-2020", "02-01-2021"))
# plt.scatter(la_metro[['Date']], la_metro[['Residents.Active']], label=sample_facility)
# plt.scatter(la_metro[['Date']], la_metro[['Residents.TAdmin']])
# plt.legend()
# plt.show()

# sns.pairplot(data=[np.arange(5), np.arange(5)])
# plt.show()

cases = la_metro[['Residents.Active']]
cases = cases.dropna()
cases.to_csv('sample_facility_cases.csv')
x_days = np.arange(1, len(cases)) ## [0, 1, 2, 3, 4, 5...]

free_model = pystan.StanModel(file='stan-scripts/fit-sir-free.stan')
                              # , include_paths=['./stan-scripts/'])
fit = free_model.sampling(chains=1,
                          data={
                              'max_t':len(cases),
                              'ts': x_days,
                              'y': cases,
                              'inf_init': max(cases[1],1),
                              'alpha': 0.1
                          })
print(fit)

pickle.dump(fit, open('fit-sir-free.pkl', 'wb'))


print('done')
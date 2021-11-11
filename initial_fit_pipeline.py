import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy.stats
# import pystan
from data_utils import *
import seaborn as sns
# import pickle

jhu_data = load_jh_data(cached_fname='./cached_data/JHU_11-11-21.csv')
jhu_california = pd.DataFrame(select_state_JHU(jhu_data, 'California'))
start_date_col = jhu_california.columns.get_loc('5/1/20')
end_date_col = jhu_california.columns.get_loc('5/1/21')

## TODO commit, save and process the data tonight. and organize.


sample_facility = 'CALIFORNIA STATE PRISON LOS ANGELES'
sample_covid_data = load_ucla_data(cached_fname='./cached_data/UCLA_11-11-21.csv')
# la_county = pd.DataFrame(select_county(sample_covid_data, 'LOS ANGELES', 'California'))
la_county = pd.DataFrame(select_county(sample_covid_data, None, 'California'))
for facility in set(la_county['Name'].values):
    try:
        la_metro = pd.DataFrame(select_facility(la_county, facility))
        la_metro = pd.DataFrame(select_date_range_UCLA(la_metro, "05-01-2020", "05-01-2021"))
        # la_metro['Pop'] = la_metro['Residents.Pop'].bfill()
        la_cases = pd.DataFrame(la_metro[['Facility.ID', 'Name', 'Date', 'Residents.Active', 'Residents.Population', 'Population.Feb20']])
        la_cases = la_cases.dropna()

        fac_ID = la_metro[['Facility.ID']].dropna().head(1).values[0][0]

        county_name_lower = la_metro[['County']].dropna().head(1).values[0][0].lower()
        county_pop = get_county_pop(county_name_lower)
        jhu_county = pd.DataFrame(select_county_JHU(jhu_california, county_name_lower))
        jhu_county = jhu_county.iloc[:, start_date_col:end_date_col]
        jhu_county = jhu_county.T
        jhu_county['Date'] = pd.to_datetime(jhu_county.index)

        combined_df = la_cases.join(jhu_county.set_index('Date'), on='Date')
        combined_df = combined_df.rename(columns={int(combined_df.columns[6]): "County.cumul"})
        combined_df['County.Pop'] = [county_pop for i in range(len(combined_df))]
        combined_df['County'] = [county_name_lower for i in range(len(combined_df))]
        combined_df["County.new"] = combined_df["County.cumul"].diff()/county_pop
        combined_df['County.active'] = combined_df['County.cumul'].diff(periods=14)/county_pop
        combined_df['County.active'] = combined_df['County.active'].mask(pd.isnull, (combined_df['County.cumul'] - combined_df['County.cumul'].iloc[0]) / county_pop)

        combined_df.to_csv(f'./joined_datasets_california2/{county_name_lower.replace(" ", "-")}_{fac_ID}.csv')

        fig, axs = plt.subplots(2, 1)
        axs[0].scatter(combined_df['Date'], combined_df['Residents.Active']/combined_df['Residents.Population'], label=facility, s=2)
        axs[0].legend()
        axs[1].scatter(combined_df['Date'], combined_df['County.new'], label=f'{county_name_lower} daily new', s=2)
        axs[1].scatter(combined_df['Date'], combined_df['County.active'], label=f'{county_name_lower} 14-day diff', s=2)
        axs[1].set_ylim([-.01, .09])
        plt.legend()
        plt.ylabel('Percent of population')
        plt.savefig(f'./jointplots2/{county_name_lower.replace(" ", "-")}_{fac_ID}.png')
        plt.show()
    except:
        print(facility)
        continue
    # plt.scatter(la_metro[['Date']], la_metro[['Residents.Confirmed']])
# plt.show()

# la_metro = pd.DataFrame(select_facility(la_county, sample_facility))
# la_metro = pd.DataFrame(select_date_range_UCLA(la_metro, "05-01-2020", "02-01-2021"))
# plt.scatter(la_metro[['Date']], la_metro[['Residents.Active']], label=sample_facility)
# plt.scatter(la_metro[['Date']], la_metro[['Residents.TAdmin']])
# plt.legend()
# plt.show()

# sns.pairplot(data=[np.arange(5), np.arange(5)])
# plt.show()

# cases = la_metro[['Residents.Active']]
# cases = cases.dropna()
# cases.to_csv('sample_facility_cases.csv')
# x_days = np.arange(1, len(cases)) ## [0, 1, 2, 3, 4, 5...]

# free_model = pystan.StanModel(file='stan-scripts/fit-sir-free.stan'
#                               , include_paths=['./stan-scripts/'])
# fit = free_model.sampling(chains=1,
#                           data={
#                               'max_t':len(cases),
#                               'ts': x_days,
#                               'y': cases,
#                               'inf_init': max(cases[1],1),
#                               'alpha': 0.1
#                           })
# print(fit)

# pickle.dump(fit, open('fit-sir-free.pkl', 'wb'))

print('done')
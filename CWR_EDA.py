import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import rcParams
import datetime

rcParams['font.family'] = 'Helvetica'

FILENAME = './joined_datasets_california2/epi-timeseries-fed-agg-CA-partial.csv'

cwr_data = pd.read_csv(FILENAME)
cwr_data['Date'] = pd.to_datetime(cwr_data['Date'])
ca_pops = pd.read_csv('ca_county_pop.csv')
ca_total_pop = np.sum(ca_pops['pop2019'])

fig_pop, axs_pop = plt.subplots(3, 1, sharey=False, sharex=True)
fig_cases, axs_cases = plt.subplots(3, 1, sharex=True)
fig_vax, axs_vax = plt.subplots(3, 1, sharex=True)

axs_pop[0].scatter(cwr_data['Date'], np.full(len(cwr_data), ca_total_pop), label='CA', s=2)
axs_pop[1].scatter(cwr_data['Date'], cwr_data['Residents.Population'], label='Residents', s=2)
axs_pop[2].scatter(cwr_data['Date'], cwr_data['Staff.Population'], label='Workers', s=2)
axs_pop[2].tick_params(axis='x',rotation=45)
axs_pop[0].set_ylabel('CA Population')
axs_pop[1].set_ylabel('Resident Population')
axs_pop[2].set_ylabel('Staff Population')
axs_pop[0].set_xlabel('Dates')

axs_cases[0].scatter(cwr_data['Date'], cwr_data['Community.Active'], label='CA', s=2)
axs_cases[1].scatter(cwr_data['Date'], cwr_data['Residents.Active'], label='Residents', s=2)
axs_cases[2].scatter(cwr_data['Date'], cwr_data['Staff.Active'], label='Workers', s=2)
axs_cases[2].tick_params(axis='x',rotation=45)
axs_cases[0].set_ylabel('CA Active')
axs_cases[1].set_ylabel('Resident Active')
axs_cases[2].set_ylabel('Staff Active')
axs_cases[0].set_xlabel('Dates')

axs_vax[0].scatter(cwr_data['Date'], np.full(len(cwr_data), 0), label='CA', s=2)
axs_vax[1].scatter(cwr_data['Date'], cwr_data['Residents.Vaccinated'], label='Residents', s=2)
axs_vax[2].scatter(cwr_data['Date'], cwr_data['Staff.Vaccinated'], label='Workers', s=2)
axs_vax[2].tick_params(axis='x',rotation=45)
axs_vax[0].set_ylabel('CA Vax - NA')
axs_vax[1].set_ylabel('Resident Vax')
axs_vax[2].set_ylabel('Staff Vax')
axs_vax[0].set_xlabel('Dates')


plt.show()
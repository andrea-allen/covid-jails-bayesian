import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import rcParams
import datetime

rcParams['font.family'] = 'Helvetica'


def load_nyt_data(cached_fname=None, saveto=None):
    """
    New York Times COVID-19 County-level dataset
    :param saveto: File name to cache data to after read
    :param cached_fname: If data file is cached
    :return: Pandas data frame
    """
    nyt_url_counties = 'https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv'
    if cached_fname is not None:
        data = pd.read_csv(cached_fname)
        return data
    else:
        df = pd.read_csv(nyt_url_counties, na_filter=True)
        if saveto is not None:
            df.to_csv(saveto)
        return df


def load_jh_data(cached_fname=None, saveto=None):
    """
    Johns Hopkins COVID-19 county-level dataset
    :param cached_fname: If data file is cached
    :param saveto: File name to cache data to after read
    :return: Pandas data frame
    """
    if cached_fname is not None:
        data = pd.read_csv(cached_fname)
        return data
    else:
        data = pd.read_csv(
            'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv')
        if saveto is not None:
            data.to_csv(saveto)
        return data


def load_ucla_data(cached_fname=None, saveto=None):
    """
    UCLA COVID-19 Behind Bars Data Project, facility-level COVID-19 data
    :param cached_fname: If data file is cached
    :param saveto: File name to cache data to after read
    :return: Pandas data frame
    """
    if cached_fname is not None:
        data = pd.read_csv(cached_fname)
        return data
    else:
        data = pd.read_csv("http://104.131.72.50:3838/scraper_data/summary_data/scraped_time_series.csv")
        if saveto is not None:
            data.to_csv(saveto)
        return data


def select_ice_facilities(data):
    ice_data = data[data['Jurisdiction'].str.contains('immigration', na=False)]
    print(ice_data.head(10))
    return ice_data


def select_facility(data, facility_name):
    """
    Return data frame for specific facility name
    :param data: Pandas data frame
    :param facility_name: str
    :return: Pandas data frame
    """
    return data[data['Name'].str.contains(f'{facility_name}', na=False)]

def select_county(data, county_name, state_name):
    """
    Return data frame for specific county
    :param state_name: str
    :param data: Pandas Data frame
    :param county_name: str
    :return: Pandas dataframe
    """
    state_df = data[data['state'] == state_name]
    county_df = state_df[state_df['county'] == county_name]
    return county_df

def select_date_range_UCLA(data, start_date, end_date):
    """
    Returns a dataframe of given data for specified date range
    :param data: pandas dataframe
    :param start_date: str, fmt 'mm-dd-yyyy'
    :param end_date: str, fmt 'mm-dd-yyyy'
    :return: dataframe
    """
    start_date = datetime.datetime.strptime(start_date, '%m-%d-%Y')
    start_date = pd.to_datetime(start_date)
    end_date = datetime.datetime.strptime(end_date, '%m-%d-%Y')
    end_date = pd.to_datetime(end_date)
    data['Date'] = pd.to_datetime(data['Date'])
    date_mask = (data['Date'] > start_date) & (data['Date'] <= end_date)
    date_df = data.loc[date_mask]
    return date_df

def select_date_range_NYT(data, start_date, end_date):
    """
    Returns a dataframe of given data for specific date range
    :param data: pandas dataframe
    :param start_date: str, fmt 'mm-dd-yyyy'
    :param end_date: str, fmt 'mm-dd-yyyy'
    :return: dataframe
    """
    start_date = datetime.datetime.strptime(start_date, '%m-%d-%Y')
    start_date = pd.to_datetime(start_date)
    end_date = datetime.datetime.strptime(end_date, '%m-%d-%Y')
    end_date = pd.to_datetime(end_date)

    data['date'] = pd.to_datetime(data['date'])
    date_mask = (data['date'] > start_date) & (data['date'] <= end_date)
    date_df = data.loc[date_mask]

    return date_df

def select_date_range_JHU(data, start_date, end_date):
    """
    Returns a dataframe of given data for specific date range
    :param data: pandas dataframe
    :param start_date: str, fmt 'mm-dd-yyyy'
    :param end_date: str, fmt 'mm-dd-yyyy'
    :return: dataframe
    """
    ## TODO get specific parsing for JH data
    return data


def moving_average(a, n=7):
    ret = np.cumsum(a, dtype=float)
    ret[n:] = ret[n:] - ret[:-n]
    return ret[n - 1:] / n


def plot_jh_data(dataframe):
    ## TODO
    base_color = '#555526'
    scatter_color = '#92926C'
    more_colors = ["#D7790F", "#82CAA4", "#4C6788", "#84816F",
                   "#71A9C9", "#AE91A8"]
    plt.rcParams['text.color'] = base_color

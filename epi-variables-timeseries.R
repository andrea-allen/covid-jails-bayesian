### ----------------------------------------------------------------------------
### Plot and/or save a subset of data, with variables in a convenient timeseries
### ----------------------------------------------------------------------------
### DATA_SOURCE: either NULL for read entire scraper data, or file to saved data
### STATE_REGEX: filter source data by state------------------------------------
### STATE_EXCLUDE: setminus for state regex-------------------------------------
### COUNTY_REGEX: filter to particular counties---------------------------------
### FEDERAL: use federal or state prisons?--------------------------------------
### FACILITY_IDS: filter particular facilities----------------------------------
### AGG_BY_STATE: aggregate variables to state level? (may pull from Marshall project)
### VARS: variables (colnames) of interest--------------------------------------
### SAVE_CSV: save output? (will also drop NAs)---------------------------------
### ADD_COMMUNITY: "left_joins" in JHU cases by keys Date x (State|County)------

DATA_SOURCE <- 'cached_data/ucla-all-11-16'
STATE_REGEX <- '\\w+'
STATE_EXCLUDE <- 'Hawa|North|Not Ava|Utah|Virg' # exclude states not in report
COUNTY_REGEX <- '\\w+'
FEDERAL <- FALSE
FACILITY_IDS <- 1:10000 # i.e. don't filter by facility
AGG_BY_STATE <- FALSE
VARS <- c(
  'Residents.Active', 'Residents.Completed', 'Residents.Initiated', 'Residents.Population',
  'Staff.Active', 'Staff.Completed', 'Staff.Initiated', 'Staff.Population'
)
SAVE_CSV <- FALSE
ADD_COMMUNITY <- FALSE

### Load required packages------------------------------------------------------
library(tidyverse)
library(behindbarstools)

### Helper functions-----------------------------------------------------------------
total_vacc <- function(first_shot, second_shot) {
  map2_dbl(
    first_shot, second_shot, 
    ~if (is.na(.y)) NA else {if (is.na(.x)) .y else .x + .y}
  )
}

fill_staff_pop <- function(state, date, marshall_dat) {
  minfo <- filter(marshall_dat, name == state)
  if (all(is.na(minfo$pop))) {
    return(NA)
  }
  if (is.na(minfo$pop[2])) {
    return(minfo$pop[1])
  }
  if (date > minfo$as_of_date[2])
    minfo$pop[2]
  else
    minfo$pop[1]
}

approx_active <- function(case_count, inf_period = 14) {
  lag_idx <- pmax(1, seq_along(case_count) - inf_period)
  case_count - case_count[lag_idx]
}

### Load and filter data--------------------------------------------------------
if (is.null(DATA_SOURCE)) {
  dat_all <- read_scrape_data(all_dates = TRUE)
} else {
  dat_all <- read_csv(paste0(DATA_SOURCE, '.csv'))
}

dat_sub <- filter(
  dat_all, 
  Jurisdiction == if (FEDERAL) 'federal' else 'state', 
  str_detect(State, STATE_REGEX) & !str_detect(State, STATE_EXCLUDE),
  Facility.ID %in% FACILITY_IDS,
  str_detect(str_to_title(County), COUNTY_REGEX)
) |> 
  mutate(Facility.ID = as.factor(Facility.ID), County = str_to_title(County))

if (AGG_BY_STATE) {
  # borrow staff population from Marshall project
  staff_marshall <- read_csv('cached_data/staff-populations-marshall.csv') |> 
    mutate(as_of_date = as.Date(as_of_date, '%m/%d/%y'))
  
  dat_sub <- dat_sub |>
    group_by(State, Date) |> 
    summarise(across(matches('Resid|Staff'), ~sum(.x, na.rm = TRUE))) |> 
    ungroup() |> 
    mutate(Staff.Population = map2_dbl(State, Date, fill_staff_pop, staff_marshall))
}

### Process data for timeseries and plot----------------------------------------
mask <- if (AGG_BY_STATE) 'State' else 'Facility.ID' # controls grouping for ggplot

timeseries <- dat_sub |> 
  mutate(
    Residents.Vaccinated = total_vacc(Residents.Initiated, Residents.Completed),
    Staff.Vaccinated = total_vacc(Staff.Initiated, Staff.Completed)
  ) |> 
  select(!matches('Compl|Initi'))

timeseries_long <- timeseries |> 
  pivot_longer(c(any_of(VARS) & !matches('Compl|Initi'), contains('Vacc'))) |> 
  separate(name, c('Group', 'Metric'), remove = TRUE)

ggplot(timeseries_long, aes(Date, value, col = .data[[mask]], group = .data[[mask]])) +
  geom_line(alpha = 0.3, size = 1.5) +
  facet_wrap(Group ~ Metric, scales = 'free_y', nrow = 2) +
  theme_minimal()

### Add community if using------------------------------------------------------
if (ADD_COMMUNITY) {
  # pull latest timeseries
  jhu <- read_csv('https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv') |> 
    pivot_longer(matches('\\d+/\\d+/\\d+'), names_to = 'Date') |> 
    mutate(Date = as.Date(Date, '%m/%d/%y'), Admin2 = str_to_title(Admin2))
  if (AGG_BY_STATE) {
    jhu_act <- jhu |>
      group_by(Province_State, Date) |> 
      summarise(sum = sum(value)) |> 
      mutate(Community.Active = approx_active(sum)) |> 
      ungroup() |> 
      select(State = Province_State, Date, Community.Active)
  }
  else {
    jhu_act <- jhu |>
      group_by(Admin2) |> 
      mutate(Community.Active = approx_active(value)) |> 
      ungroup() |> 
      select(County = Admin2, Date, Community.Active)
  }
  timeseries <- left_join(timeseries, jhu_act)
}

### Save the data (change name if needed)---------------------------------------
if (SAVE_CSV) {
  timeseries |> 
    drop_na(c(any_of(VARS) & !matches('Compl|Initi'), contains('Vacc'), 'Community.Active')) |> 
    write_csv(paste0('epi-timeseries-', Sys.Date(), '.csv'))
}
  
  

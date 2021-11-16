### ----------------------------------------------------------------------------
### Plot and/or save a subset of data, with variables in a convenient timeseries
### ----------------------------------------------------------------------------
### DATA_SOURCE: either NULL for read entire scraper data, or file to saved data
### STATE_REGEX: filter source data by state------------------------------------
### STATE_EXCLUDE: setminus for state regex-------------------------------------
### FEDERAL: use federal or state prisons?--------------------------------------
### FACILITY_IDS: only check particular facilities?-----------------------------
### AGG_BY_STATE: aggregate variables to state level? (may pull from Marshall project)
### VARS: variables (colnames) of interest--------------------------------------
### SAVE_CSV: save output?------------------------------------------------------

DATA_SOURCE <- 'cached_data/ucla-all-11-16'
STATE_REGEX <- '\\w*'
STATE_EXCLUDE <- 'Hawa|North|Not Ava|Utah|Virg' # exclude states not in report
FEDERAL <- TRUE
FACILITY_IDS <- 1:10000 # i.e. don't filter by facility
AGG_BY_STATE <- FALSE
VARS <- c(
  'Residents.Active', 'Residents.Completed', 'Residents.Initiated', 'Residents.Population',
  'Staff.Active', 'Staff.Completed', 'Staff.Initiated', 'Staff.Population'
)
SAVE_CSV <- FALSE

### Load required packages------------------------------------------------------
require(tidyverse)
require(behindbarstools)

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
  Facility.ID %in% FACILITY_IDS
) |> 
  mutate(Facility.ID = as.factor(Facility.ID))

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

timeseries_long <- dat_sub |> 
  mutate(
    Residents.Vaccinated = total_vacc(Residents.Initiated, Residents.Completed),
    Staff.Vaccinated = total_vacc(Staff.Initiated, Staff.Completed)
  ) |> 
  select(!matches('Comf|Initi')) |> 
  pivot_longer(c(any_of(VARS) & !matches('Compl|Initi'), contains('Vacc'))) |> 
  separate(name, c('Group', 'Metric'), remove = TRUE)

ggplot(timeseries_long, aes(Date, value, col = .data[[mask]], group = .data[[mask]])) +
  geom_line(alpha = 0.3, size = 1.5) +
  facet_wrap(Group ~ Metric, scales = 'free_y', nrow = 2) +
  theme_minimal()

### Save the data (change name if needed)---------------------------------------
if (SAVE_CSV)
  write_csv(timeseries_long, paste0('epi-timeseries-', Sys.Date(), '.csv'))
  
  

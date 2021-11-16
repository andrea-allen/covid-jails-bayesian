### ----------------------------------------------------------------------------
### Check availability of variables necessary for analysis----------------------
### ----------------------------------------------------------------------------
### DATA_SOURCE: either NULL for read entire scraper data, or file to saved data
### STATE_REGEX: filter source data by state------------------------------------
### FEDERAL: use federal or state prisons?--------------------------------------
### FACILITY_IDS: only check particular facilities?-----------------------------
### VARS: variables (colnames) of interest--------------------------------------

DATA_SOURCE <- 'cached_data/ucla-all-11-16'
STATE_REGEX <- 'Cali'
STATE_EXCLUDE <- 'Hawa|North|Not Ava|Utah|Virg' # exclude states not in report
FEDERAL <- FALSE
FACILITY_IDS <- 1:10000 # i.e. don't filter by facility
VARS <- c(
  'Residents.Active', 'Residents.Completed', 'Residents.Initiated', 'Residents.Population',
  'Staff.Active', 'Staff.Completed', 'Staff.Initiated', 'Staff.Population'
)

### Load required packages------------------------------------------------------
require(tidyverse)
require(behindbarstools)

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

###  Count number of days with info on each of VARS-----------------------------
non_na_counts <- dat_sub |> 
  group_by(Name) |> 
  summarise(across(all_of(VARS), ~sum(!is.na(.x))))

ggplot(pivot_longer(non_na_counts, -Name), aes(name, Name, fill = value)) +
  geom_tile() +
  scale_fill_viridis_c() +
  scale_x_discrete(expand = expansion(), guide = guide_axis(angle = 35)) +
  labs(y = 'Facility Name', x = 'Metric', fill = 'Non-NA Count')

### Check which dates/facilities have all VARS available------------------------
var_complete <- dat_sub |> 
  rowwise() |> 
  mutate(complete = any(is.na(c_across(all_of(VARS)))))

ggplot(var_complete, aes(as.character(Date), Name)) +
  geom_tile(aes(fill = complete)) +
  scale_fill_manual(values = c(`FALSE` = 'firebrick3', `TRUE` = 'forestgreen')) +
  labs(y = NULL, x = NULL, fill = 'Complete data?') +
  theme_minimal() +
  geom_stripes(odd = "#33333333", even = "#00000000") +
  theme(
    legend.position = 'bottom', axis.text.x = element_blank(), panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(linetype = 'dotted', color = 'grey60'), panel.ontop = TRUE
  )

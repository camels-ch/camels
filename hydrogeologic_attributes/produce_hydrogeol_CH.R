###===============================###===============================###
### CAMELS-CH: computation of hydrogeological attributes
### 14.02.2023
### University of Zürich, daniel.viviroli@geo.uzh.ch
### EAWAG, ursula.schoenenberger@eawag.ch
### University of Bern, martina.kauzlaric@giub.unibe.ch
### martina.kauzlaric@giub.unibe.ch and kauzlaric.martina@gmail.com
###===============================###===============================###
###===============================###===============================###
### (1) Read in catchment shapes
### (2) Compute hydrogeological attributes
###===============================###===============================###
###===============================###===============================###
### load packages
###===============================###===============================###
### loading shape files
library(sf)
library(dplyr)

dir_data <- Sys.getenv('CAMELS_DIR_DATA')
dir_results <- Sys.getenv('CAMELS_DIR_RESULTS')

###===============================###===============================###
### (1) Read in catchment shapes
###===============================###===============================###
### read in CAMELS-CH catchment shapes
setwd(paste(dir_data, 'Catchments', 'CAMELS_CH_EZG_7.6', sep = '/'))
catch <- st_read('CAMELS_CH_EZG_76.shp')

###===============================###===============================###
### (2) Compute hydrogeological attributes
###===============================###===============================###
### read in hydrogeological data for hydrological Switzerland (prepared in the previous step)
hydrogeo.HydroCH <- st_read(
  paste(dir_data, 'Hydrogeology', 'hydrogeoHydroCH.shp', sep = '/'),
  stringsAsFactors = FALSE)

### Intersect data with catchmet shapes
hydrogeo.HydroCH.int <- st_intersection(hydrogeo.HydroCH, catch)

hydrogeo.HydroCH.int <- hydrogeo.HydroCH.int %>%
  mutate(Area_hg = as.numeric(st_area(hydrogeo.HydroCH.int)), .before = Shape_Area)

hydrogeo.HydroCH.int <- hydrogeo.HydroCH.int %>%
  mutate(hygeol_perc = round(Area_hg / Shape_Area, 4) * 100, .after = CAMELS_)

df.hydrogeo.HydroCH.int <- st_drop_geometry(hydrogeo.HydroCH.int)
df.hydrogeo.HydroCH.int <- df.hydrogeo.HydroCH.int %>% select(CAMELS_, hygeol_perc, gauge_id)

### set attribute names
#Note: there is an additional class hygeol_NA
#      in case no data at all are covering the area
#      i.e. neither the swiss not the german hydrogeological data
attr.nm <- c('hygeol_null_perc',
             'hygeol_unconsol_coarse_perc',
             'hygeol_unconsol_medium_perc',
             'hygeol_unconsol_fine_perc',
             'hygeol_unconsol_imperm_perc',
             'hygeol_karst_perc',
             'hygeol_hardrock_perc',
             'hygeol_hardrock_imperm_perc',
             'hygeol_water_perc',
             'hygeol_NA_perc')

### preallocate data frame to store soil attributes
df_hygeoattr <- as.data.frame(matrix(0, dim(catch)[1], 1 + length(attr.nm)),
                              stringsAsFactors = FALSE)
df_hygeoattr[, 1] <- catch$gauge_id
colnames(df_hygeoattr) <- c('gauge_id', attr.nm)


for (catch.i in 1:dim(catch)[1]) {

  gauge <- df_hygeoattr[catch.i, 'gauge_id']

  print(paste0("#", catch.i, ": ", gauge))

  CAMELS_hygeo <- df.hydrogeo.HydroCH.int[
    which(df.hydrogeo.HydroCH.int$gauge_id == gauge), 'CAMELS_']

  CAMELS_hygeo <- CAMELS_hygeo[!is.na(CAMELS_hygeo)]

  hygeo_perc <- df.hydrogeo.HydroCH.int[
    which(df.hydrogeo.HydroCH.int$gauge_id == gauge), 'hygeol_perc']

  df_hygeoattr[catch.i, match(paste0(CAMELS_hygeo, '_perc'), colnames(df_hygeoattr))] <- hygeo_perc

  if (sum(df_hygeoattr[catch.i, 2:dim(df_hygeoattr)[2]]) < 100) {
    df_hygeoattr$hygeol_NA_perc[catch.i] <- 100 -
      sum(df_hygeoattr[catch.i, 2:dim(df_hygeoattr)[2]])
  }

  ### Correct for rounding errors 
  if (sum(df_hygeoattr[catch.i, 2:dim(df_hygeoattr)[2]]) != 100) {
    df_hygeoattr[catch.i, 2:dim(df_hygeoattr)[2]] <-
      df_hygeoattr[catch.i, 2:dim(df_hygeoattr)[2]] * (100 /
        sum(df_hygeoattr[catch.i, 2:dim(df_hygeoattr)[2]]))
  }

  rm(CAMELS_hygeo); rm(hygeo_perc)
}

### Check all percentages sum up to 100%
test <- rowSums(df_hygeoattr[, attr.nm]); test
any(round(rowSums(df_hygeoattr[, attr.nm]), 0) != 100)
rm(test)

### save extracted attributes
setwd(dir_results)
save(file = 'hydrogeol_attributes.RData', df_hygeoattr)

### write to file, use semicolon for separation
write.table(file = 'CAMELS_CH_hydrogeol_attributes.csv',
            round(df_hygeoattr, 3),
            sep = ';', quote = FALSE, row.names = FALSE, fileEncoding = "UTF-8")


### clear workspace
rm(list = ls())

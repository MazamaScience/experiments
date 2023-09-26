# import required modules
import pandas as pd
  
# URLs
data_url = "https://airfire-data-exports.s3.us-west-2.amazonaws.com/monitoring/v2/airnow/2023/data/airnow_PM2.5_2023_data.csv.gz"
meta_url = "https://airfire-data-exports.s3.us-west-2.amazonaws.com/monitoring/v2/airnow/2023/data/airnow_PM2.5_2023_meta.csv.gz"

# read the dataset using the compression zip
meta = pd.read_csv(meta_url)
data = pd.read_csv(data_url)
  
# display dataset
print(meta.head())
print(data.head())


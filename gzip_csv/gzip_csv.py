# import required modules
import pandas as pd
  
# read the dataset using the compression zip
meta = pd.read_csv('meta.csv.gz')
data = pd.read_csv('data.csv.gz')
  
# display dataset
print(meta.head())
print(data.head())


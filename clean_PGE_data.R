# This script can be used to read in a PGE hourly week-long energy usage summary, and export it to MySQL database.
# the purpose of this script is to create data for use in graphing home energy use.
rm(list = ls()) # clear workspace
library(RMySQL)

filelist = list.files("/home/rajput/Documents/RStudio/PGE_energy_usage/To_add")
data = read.table(paste("/home/rajput/Documents/RStudio/PGE_energy_usage/To_add",filelist[2],sep="/"),header=TRUE,sep=",",skip=13)
colnames(data) = c("str_date",paste("x",c(00:23),sep=""))
data$usage_date = as.Date(data$str_date,"%m/%d/%Y")
exp_data = data[c(ncol(data),2:(ncol(data)-1))]

# now connect to MySQL db and insert the data:
mydb = dbConnect(MySQL(), user='[user]', password='[pwd]', dbname='arduino_data', host='127.0.0.1')
#dbListTables(mydb)
dbWriteTable(mydb,"PGE_usage",exp_data,append=TRUE, row.names=FALSE)

using Pkg
using CSV, DataFrames
#se till att beräkna average capacity factor för wind och pv
#Labels

data=CSV.read("TimeSeries.csv",DataFrame)
array_data=Matrix(data)
time=array_data[:,1]
wind_DE=array_data[:,2]
PV_DE=array_data[:,3]
wind_SE=array_data[:,4]
PV_SE=array_data[:,5]
Wind_DK=array_data[:,6]
PV_dk=array_data[:,7]
Load_DE=array_data[:,8]
Load_DK=array_data[:,9]
Load_SE=array_data[:,10]
hydro_inflow=array_data[:,11]

# Sets
I = 1:9 # 9 energy types
J = 1:3 # Set of countries
S=1:length(time) # set of hours

inv_cost=[1100,600,550,0,150,2500,7700]
run_cost=[0.1,0.1,2,0.1,0.1,0,4]
fuel_cost=[0,0,22,0,0,0,3.2]
lifetime=[25,25,30,80,10,50,50]
efficiency=[1,1,0.4,1,0.9,0.98,0.4]
emiss_factor=[0,0,0.202,0,0,0,0]
cap_swe=[280,75,1,14,1,1,1]
cap_dk=[90,60,1,0,1,1,1]
cap_de=[180,460,1,0,1,1,1]




foods = ["hamburger", "chicken", "hot dog", "fries", "macaroni", "pizza", "salad", "milk", "ice cream"] # for i in I
nutrients  = ["calories", "protein", "fat", "sodium"]

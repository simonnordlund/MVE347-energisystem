function build_energy_model(data_file::String)
    include(data_file)  
    #name the model
    m = Model()
    r=0.05
    @variable(m, x[I,J,S] >= 0) #Variable hour, amount of MWH for technology i for country j for a certian hour.
    @variable(m,z[I,J]>=0) #The capacity, amount of kw for technology i for country j
    @variable(m,volume[S]>=0)
    #minimize the cost
    @objective(m, Min,run_cost[1]*sum(x[1,1,s] for s in S)+ run_cost[2]*sum(x[2,1,s] for s in S)+run_cost[1]*sum(x[1,2,s] for s in S)+run_cost[2]*sum(x[2,2,s] for s in S)+run_cost[1]*sum(x[1,3,s] for s in S)+run_cost[2]*sum(x[2,3,s] for s in S)
+ run_cost[3]*sum(x[3,1,s] for s in S)+ run_cost[3]*sum(x[3,2,s] for s in S) + run_cost[3]*sum(x[3,3,s] for s in S)+run_cost[4]*sum(x[4,1,s] for s in S)+run_cost[4]*sum(x[4,2,s] for s in S)+run_cost[4]*sum(x[4,3,s] for s in S)
+  sum(inv_cost[i]*r/(1-1/(1+r)^lifetime[i])*(sum(z[i,j] for j in J)) for i in I)-fuel_cost[3]*sum(x[3,j,s] for j in J for s in S ))
  

@constraint(m,max_cap_de[1,2,4],z[i,1]*10^6<=cap_de[i]) #maximun capacitets for Germany
@constraint(m,max_cap_swe[1,2,4],z[i,2]*10^6<=cap_swe[i]) #maximun capacitets for Sweden
@constraint(m,max_cap_dk[1,2,4],z[i,3]*10^6<=cap_dk[i]) #maximun capacitets for Denmark
@constraint(m,loadse,sum(x[i,2,s] for i in I)==load_SE) #Load balance for Sweden
@constraint(m,loaddk,sum(x[i,3,s] for i in I)==load_DK) #Load balance for Denmark
@constraint(m,loadde,sum(x[i,1,s] for i in I)==load_DE) #Load balance for Germany

@constraint(m,z[1,1]*10^3*wind_DE>=x[1,1,s]) #Maximum possible production
@constraint(m,z[1,2]*10^3*wind_SE>=x[1,2,s]) #Maximum possible production
@constraint(m,z[1,3]*10^3*wind_DK>=x[1,3,s]) #Maximum possible production
@constraint(m,z[2,1]*10^3*PV_DE>=x[2,1,s]) #Maximum possible production
@constraint(m,z[2,2]*10^3*PV_SE>=x[2,2,s]) #Maximum possible production
@constraint(m,z[2,3]*10^3*PV_DK>=x[2,3,s]) #Maximum possible production
@constraint(m,x[3,1,s] <= z[3,1]*10^3*efficiency[3]) #Efficiency for gas
@constraint(m,x[3,2,s] <= z[3,2]*10^3*efficiency[3]) #Efficiency for gas
@constraint(m,x[3,3,s] <= z[3,3]*10^3*efficiency[3]) #Efficiency for gas


@constraint(m,volume[1]==14*10^3) #first hour of water
#Reservoir >=0 and >=max for every hour
for hour in 2:length(time)-1
    @constraint(m,volume[hour]==volume[hour-1]-sum(x[4,j,hour-1] for j in J)+hydro_inflow[hour-1])
end

@constraint(m,volume<=33*10^6)
@constraint(m,volume[1]==volume[end])
    return m, x
end
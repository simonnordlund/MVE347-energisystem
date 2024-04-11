function build_energy_model(data_file::String)
    include(data_file)
    
  
    #name the model
    m = Model()
    r=0.05
    @variable(m, x[I,J,S] >= 0) # amount of invested KW for technology i for country j for a certian hour.

    #minimize the cost
    @objective(m, Min,run_cost[3]* run_cost[1]*sum(wind_DE[s]*x[1,1,s] for s in S)+ run_cost[2]*sum(PV_DE[s]*x[2,1,s] for s in S)+run_cost[1]*sum(wind_SE[s]*x[1,2,s] for s in S)+run_cost[2]*sum(PV_SE[s]*x[2,2,s] for s in S)+run_cost[1]*sum(wind_DK[s]*x[3,2,s] for s in S)+run_cost[2]*sum(PV_DK[s]*x[3,3,s] for s in S)
+ run_cost[3]*sum(x[3,1,s] for s in S)+ run_cost[3]*sum(x[3,2,s] for s in S) + run_cost[3]*sum(x[3,3,s] for s in S)+run_cost[4]*sum(x[4,1,s] for s in S)+run_cost[4]*sum(x[4,2,s] for s in S)+run_cost[4]*sum(x[4,3,s] for s in S)
+  sum(inv_cost[i]*r/(1-1/(1+r)^lifetime[i])*(sum(x[i,j,s] for j in J for s in S)) for i in I)-fuel_cost[3]*sum(x[3,j,s] for j in J for s in S ))
  

@constraint(m,max_cap_de[1,2,4],sum(x[i,1,s] for s in S)<=cap_de[i]*1000)
@constraint(m,max_cap_swe[1,2,4],sum(x[i,2,s] for s in S)<=cap_swe[i]*1000)
@constraint(m,max_cap_swe[1,2,4],sum(x[i,3,s] for s in S)<=cap_dk[i]*1000)
@constraint(m,hydro[1],0>=)
    return m, x
  end
  
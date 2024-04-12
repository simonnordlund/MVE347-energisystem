function build_energy_model(data_file::String)
    include(data_file)  
    #name the model
    m = Model()

    
    r=0.05
    @variable(m, x[I,J,S] >= 0) #Variable hour, amount of MWH for technology i for country j for a certian hour s.
    @variable(m,z[I,J] >= 0) #The capacity, amount of kw for technology i for country j
    @variable(m,volume[S] >= 0)
    @variable(m,batterystorage[J,S] >= 0) # amount of MWH for a battery in country j during an hour s.
    @variable(m,batterycap[J] >= 0)
    #minimize the cost
   
    @objective(m, Min, sum(run_cost[i] * sum(x[i,j,s] / efficiency[i] for s in S) for j in J for i in I)
    + sum(inv_cost[i]/1000 * r/(1-1/(1+r)^lifetime[i]) * sum(z[i,j] for j in J) for i in I)
    +fuel_cost[3]*sum(x[3,j,s] for j in J for s in S ))
  
    @constraint(m,[i in [1,2,4]], z[i,1]*10^6 <= cap_de[i]) #maximun capacitets for Germany
    @constraint(m,[i in [1,2,4]], z[i,2]*10^6 <= cap_swe[i]) #maximun capacitets for Sweden
    @constraint(m,[i in [1,2,4]], z[i,3]*10^6 <= cap_dk[i]) #maximun capacitets for Denmark

    @constraint(m,[s in S],z[1,1]*10^3*Wind_DE[s] >= x[1,1,s]) #Maximum possible production
    @constraint(m,[s in S],z[1,2]*10^3*Wind_SE[s] >= x[1,2,s]) #Maximum possible production
    @constraint(m,[s in S],z[1,3]*10^3*Wind_DK[s] >= x[1,3,s]) #Maximum possible production
    @constraint(m,[s in S],z[2,1]*10^3*PV_DE[s] >= x[2,1,s]) #Maximum possible production
    @constraint(m,[s in S],z[2,2]*10^3*PV_SE[s]>=x[2,2,s]) #Maximum possible production
    @constraint(m,[s in S],z[2,3]*10^3*PV_DK[s]>=x[2,3,s]) #Maximum possible production

    @constraint(m,[s in S],x[3,1,s] <= z[3,1]*10^3*efficiency[3]) #Efficiency for gas
    @constraint(m,[s in S],x[3,2,s] <= z[3,2]*10^3*efficiency[3]) #Efficiency for gas
    @constraint(m,[s in S],x[3,3,s] <= z[3,3]*10^3*efficiency[3]) #Efficiency for gas


    @constraint(m,volume[1]==14*10^3) #first hour of water
    #Reservoir >=0 and >=max for every hour
    for hour in 2:length(time_arr)-1
        @constraint(m,volume[hour] == volume[hour-1] - sum(x[4,j,hour-1] for j in J) + Hydro_inflow[hour-1]) 
    end
    @constraint(m,volume[1] == volume[end] - sum(x[4,j,end] for j in J) + Hydro_inflow[end])

    @constraint(m,[s in S], 0 <= volume[s] <= 33*10^6)
   

    @constraint(m,[s in S], sum(x[i,2,s] for  i in I) == Load_SE[s]) #Load balance for Sweden
    @constraint(m,[s in S], sum(x[i,3,s] for i in I) == Load_DK[s]) #Load balance for Denmark
    @constraint(m,[s in S], sum(x[i,1,s] for i in I) == Load_DE[s]) #Load balance for Germany

    
    @constraint(m,(1/0.4)*sum(x[3,j,s] for s in S for j in J)<=0.1*1.98*10^9) #CO2


    #Constraints for batteries
    @constraint(m, [j in J, s in S],batterystorage[j,s] <= batterycap[j] ) #Make sure that the charge does not exceed maximum capacity.

    for hour in 2:length(time_arr)-1
        @constraint(m,batterystorage[1,hour] == batterystorage[1,hour-1] + sum(x[i,1,hour] for i in I) - Load_DE[hour]/1000 ) #Battery charge flow DE
    end

    for hour in 2:length(time_arr)-1
        @constraint(m,batterystorage[2,hour] == batterystorage[2,hour-1] + sum(x[i,2,hour] for i in I) - Load_SE[hour]/1000 ) #Battery charge flow SE
    end

    for hour in 2:length(time_arr)-1
        @constraint(m,batterystorage[3,hour] == batterystorage[3,hour-1] + sum(x[i,3,hour] for i in I) - Load_DK[hour]/1000 ) #Battery charge flow DK
    end



    @constraint(m,batterystorage[1,1] == batterystorage[1,end] + sum(x[i,3,end] for i in I) - Load_DK[end]/1000 ) #Constraint the first hour == last hour
    @constraint(m,batterystorage[2,1] == batterystorage[2,end] + sum(x[i,3,end] for i in I) - Load_DK[end]/1000 ) #Constraint the first hour == last hour
    @constraint(m,batterystorage[3,1] == batterystorage[3,end] + sum(x[i,3,end] for i in I) - Load_DK[end]/1000 ) #Constraint the first hour == last hour

    

    return m,x,z
end
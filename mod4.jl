function build_energy_model(data_file::String)
    include(data_file)  
    #name the model
    m = Model()
    r=0.05
    @variable(m, x[I,J,S] >= 0) #Variable hour, amount of MWH for technology i for country j for a certian hour s.
    @variable(m,z[I,J] >= 0) #The capacity, amount of MW for technology i for country j
    @variable(m,volume[S] >= 0)
    @variable(m, Annualized_Investment[i in I, j in J] >= 0)
    @variable(m,Fuel_Cost[i in I, j in J] >= 0)
    @variable(m, Running_Cost[i in I, j in J] >= 0)
    @variable(m, Fuel[i in I, j in J, s in S] >= 0 )
    @variable(m, Emission[i in I, j in J] >= 0 )
    @variable(m,batterystorage[j in J,s in S] >= 0) # amount of MWH for a battery in country j during an hour s.
    @variable(m, Battery_Flow[j in J,s in S] >= 0) #Batter discharge
    @variable(m, Trans_Flow[j1 in J , j2 in J,s in S] >= 0 ) #Transmission flow between two countries during an hour
    @variable(m, Trans_Cap[j1 in J,j2 in J]>=0 ) #The maximum capacity for a transmission line between country A and B





    #minimize the cost
   
    @objective(m, Min, sum(Running_Cost) + sum(Annualized_Investment) + sum(Fuel_Cost)+ 
    inv_cost[6]/2*sum(r/(1-1/(1+r)^lifetime[6]) * Trans_Cap[j1,j2] for j1 in J for j2 in J))

    @constraint(m, ENERGY_CAP[i in I, j in J,s in S], x[i,j,s]<=z[i,j]) # for each energy type we cant produce more than built for each hour


    @constraint(m, ANNUALIZED_INVESTMENT[i in I, j in J], Annualized_Investment[i,j] >= inv_cost[i] * r/(1-1/(1+r)^lifetime[i]) * z[i,j])
    @constraint(m, FUEL_COST[i in I, j in J], Fuel_Cost[i,j] >= fuel_cost[i]/efficiency[i]*sum(x[i,j,s] for s in S ) )
    @constraint(m, RUNNING_COST[i in I, j in J], Running_Cost[i,j] >= run_cost[i] * sum(x[i,j,s] / efficiency[i] for s in S) )

    @constraint(m, EFFICIENCY[i in I, j in J, s in S], Fuel[i,j,s] == x[i,j,s]/efficiency[i] )#Amount of fuel used.
    @constraint(m, EMISSION[i in I, j in J], Emission[i,j] == emiss_factor[i] * sum(Fuel[i,j,s] for s in S))

    @constraint(m,[i in [1,2,4]], z[i,1] <= cap_de[i]) #maximum capacity for Germany
    @constraint(m,[i in [1,2,4]], z[i,2] <= cap_swe[i]) #maximum capacity for Sweden
    @constraint(m,[i in [1,2,4]], z[i,3] <= cap_dk[i]) #maximum capacity for Denmark

    @constraint(m,[s in S],z[1,1]*Wind_DE[s] >= x[1,1,s]) #Maximum possible production wind DE
    @constraint(m,[s in S],z[1,2]*Wind_SE[s] >= x[1,2,s]) #Maximum possible production wind SE
    @constraint(m,[s in S],z[1,3]*Wind_DK[s] >= x[1,3,s]) #Maximum possible production wind DK

    @constraint(m,[s in S],z[2,1]*PV_DE[s] >= x[2,1,s]) #Maximum possible production solar DE
    @constraint(m,[s in S],z[2,2]*PV_SE[s] >= x[2,2,s]) #Maximum possible production solar SE
    @constraint(m,[s in S],z[2,3]*PV_DK[s] >= x[2,3,s]) #Maximum possible production solar DK


    #@constraint(m,volume[1]==14*10^3) #first hour of water
    #Reservoir >=0 and >=max for every hour

    for hour in 2:length(time_arr)
        @constraint(m,volume[hour] == volume[hour-1] - x[4,2,hour-1] + Hydro_inflow[hour-1]) #Waterflow each hour
    end
    @constraint(m,[i in [1,3],s in S], x[4,i,s] == 0) #No water in DK & DE
    @constraint(m,volume[1] == volume[end] - sum(x[4,j,end] for j in J) + Hydro_inflow[end]) #Circular flow
    
    @constraint(m,[s in S], 0 <= volume[s] <= 33*10^6) #Reservoir limits
    @constraint(m, Max_Hydro[s in S], x[4,2,s]<= volume[s])
    @constraint(m,[s in S], sum(x[i,1,s] for i in I) - Battery_Flow[1,s] + sum(Trans_Flow[j,1,s] for j in J)*efficiency[6]-sum(Trans_Flow[1,j,s] for j in J) >= Load_DE[s]) #Load balance for Germany with battery and transmission
    @constraint(m,[s in S], sum(x[i,2,s] for  i in I) - Battery_Flow[2,s] + sum(Trans_Flow[j,2,s] for j in J)-sum(Trans_Flow[2,j,s] for j in J) >= Load_SE[s]) #Load balance for Sweden with battery and transmission
    @constraint(m,[s in S], sum(x[i,3,s] for i in I) - Battery_Flow[3,s] + + sum(Trans_Flow[j,3,s] for j in J)-sum(Trans_Flow[3,j,s] for j in J) >= Load_DK[s]) #Load balance for Denmark with battery and transmission
    
    
    @constraint(m,(0.202/0.4)*sum(x[3,j,s] for s in S for j in J)<=0.1*1.341*10^8) #CO2


    #Constraints for batteries
    @constraint(m, Battery_Inflow_Cap[j in J,s in S], Battery_Flow[j,s] <= z[5,j] )
    #@constraint(m, [j in J, s in S],batterystorage[j,s] <= z[5,j] ) #Make sure that the charge does not exceed maximum capacity.

    for hour in 2:length(time_arr)
        @constraint(m,batterystorage[1,hour] == batterystorage[1,hour-1] +Battery_Flow[1,hour]*efficiency[5] - x[5,1,hour] ) #Battery charge flow DE
    end

    for hour in 2:length(time_arr)
        @constraint(m,batterystorage[2,hour] == batterystorage[2,hour-1] + Battery_Flow[2,hour]*efficiency[5] - x[5,2,hour] ) #Battery charge flow SE
    end

    for hour in 2:length(time_arr)
        @constraint(m,batterystorage[3,hour] == batterystorage[3,hour-1] + Battery_Flow[3,hour]*efficiency[5] - x[5,3,hour] ) #Battery charge flow DK
    end



    @constraint(m,batterystorage[1,1] == batterystorage[1,end] + Battery_Flow[1,end]*efficiency[5] - x[5,1,end] ) #Constraint the first hour == last hour
    @constraint(m,batterystorage[2,1] == batterystorage[2,end] + Battery_Flow[2,end]*efficiency[5] - x[5,2,end] ) #Constraint the first hour == last hour
    @constraint(m,batterystorage[3,1] == batterystorage[3,end] + Battery_Flow[3,end]*efficiency[5] - x[5,3,end] ) #Constraint the first hour == last hour
    @constraint(m, STORAGE_INITIAL[j in J], batterystorage[j,1] == 0) #Battery empty at start
    @constraint(m, BATTERY_POWER[j in J, s in S], x[5,j,s] * efficiency[5] <= batterystorage[j,s]) 
   
    #Transmission Constraints

    @constraint(m,Trans_every_hour_not_max[j1 in J, j2 in J, s in S], Trans_Flow[j1,j2,s]<=Trans_Cap[j1,j2])
    @constraint(m,Trans_left_right_cap[j1 in J, j2 in J], Trans_Cap[j1,j2]==Trans_Cap[j2,j1])

    #@constraint(m, TRANSMISSION_NET[j1 in J, s in S], -sum( Trans_Flow[j1,j2,s] for j2 in J)+sum(Trans_Flow[j2,j1,s] for j2 in J)  == Trans_Net[j1,s]*efficiency[6] ) 
    #@constraint(m, TRANSMISSION_FRAC[j in J, s in S], x[6, j, s] == sum(Trans_Flow[j2, j, s] for j2 in J) ) #How much electricity comes from transmission from other countries.
    
    for hour in S, j in J
        @constraint(m, Trans_Flow[j,j,hour] == 0)
    end
    @constraint(m,[j in J],Trans_Cap[j,j]==0)

    #@constraint(m, TRANSMISSION_CAP1[j1 in J, j2 in J,s in S], Trans_Flow[j1, j2,s]-Trans_Flow[j2,j1,s]  <= z[6,j1] )
    #@constraint(m, TRANSMISSION_CAP2[j1 in J, j2 in J,s in S], Trans_Flow[j2, j1,s]-Trans_Flow[j1,j2,s]  <= z[6,j1] )
    
    #@constraint(m, TRANSMISSION_MAX[j1 in J, s in S], sum(Trans_Flow[j1,j2,s] for j2 in J ) <= z[6,j1])
    #@constraint(m, TRANSMISSION_EXCHANGE[j1 in J, j2 in J, s in S], Trans_Flow[j1,j2,s] == -Trans_Flow[j2,j1,s])
    #@constraint(m,NETTO_NOLL[s in S],sum(Trans_Net[j,s] for j in J)==0)
    return m,x,z,Trans_Cap,Trans_Flow
end
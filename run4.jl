using JuMP      #load the package JuMP
using Clp       #load the package Clp (an open linear-programming solver)
using Gurobi   #The commercial optimizer Gurobi requires installation
include("mod4.jl")
m, e, z,Trans_Cap,Trans_Flow = build_energy_model("dat4.jl")
#print(m) # prints the model instance
#set_optimizer(m, clp.Optimizer)
set_optimizer_attributes(m, "MIPGap" => 2e-2, "TimeLimit" => 120)
set_optimizer(m, Gurobi.Optimizer) 
optimize!(m)

println("z =  ", objective_value(m))   		# display the optimal solution
println("x=",(0.202/0.4)*sum(value.(e[3,j,s]) for s in S for j in J),"co2")
println("transmission production =", " DE-SE ",value.(Trans_Cap[1,2])," DK-DE ", value.(Trans_Cap[3,1]), " SE-Dk ", value.(Trans_Cap[2,3]) )
println("Transmission flow ","DE-SE  ", value.(sum(Trans_Flow[1,2,s] for s in S) ), "--DE-DK--- ", value.( sum(Trans_Flow[1,3,s] for s in S) ), "---SE-DK--- ", value.( sum(Trans_Flow[2,3,s] for s in S) ) )



power=zeros(7,length(J))

for i in I, j in J
    power[i,j]=value.(sum(e[i,j,s] for s in S))
end


imported=zeros(length(J),length(S))
for j in J, s in S
    imported[j,s]=value.(sum(Trans_Flow[j2,j,s] for j2 in J))
end



Power_per_hour=zeros(7,length(J),length(S))
#
for s in S, i in I, j in J
    Power_per_hour[i,j,s]=value.(e[i,j,s])
end 

Avg_cap_PV_Wind=zeros(1:2,J)

for i in 1:2,j in J
    Avg_cap_PV_Wind[i,j]=sum(Power_per_hour[i,j,s] for s in S)/length(S)
end

#

#Power_per_hour=zeros(I,j,S)
#
#for s in s, i in i, j in J
#    Power_per_hour[i,j,s]=value.(x[i,j,s])
#end 
#
#Avg_cap_PV_Wind=zeros(1:2,J)
#
#for i in 1:2,j in J
#    Avg_cap_PV_Wind[i,j]=sum(Power_per_hour[i,j,s] for s in S)/length(S)
#end


using Plots
using PlotlyJS

hours = 147:651

using Plots
using PlotlyJS

hours = 147:651

plot1 = PlotlyJS.plot([
    PlotlyJS.scatter(
        hours = hours, y = value.(e[1,1,hours]),
        stackgroup="one", mode="lines", hoverinfo="x+y",
        line=attr(width=0.5, color="rgb(248, 3, 252)"),
        name="Wind"  # Add name attribute here
    ),
    PlotlyJS.scatter(
        hours = hours, y = value.(e[2,1,hours]),
        stackgroup="one", mode="lines", hoverinfo="x+y",
        line=attr(width=0.5, color="rgb(245, 236, 66)"),
        name="PV"  # Add name attribute here
    ),
    PlotlyJS.scatter(
        hours = hours, y = value.(e[3,1,hours]),
        stackgroup="one", mode="lines", hoverinfo="x+y",
        line=attr(width=0.5, color="rgb(245, 66, 66)"),
        name="Gas"  # Add name attribute here
    ),
    PlotlyJS.scatter(
        hours = hours, y = value.(e[4,1,hours]),
        stackgroup="one", mode="lines", hoverinfo="x+y",
        line=attr(width=0.5, color="rgb(66, 108, 245)"),
        name="Hydro"  # Add name attribute here
    ),
    PlotlyJS.scatter(
        hours = hours, y = value.(e[5,1,hours]),
        stackgroup="one", mode="lines", hoverinfo="x+y",
        line=attr(width=0.5, color="rgb(32, 58, 95)"),
        name="Battery"  # Add name attribute here
    ),
    PlotlyJS.scatter(
        hours = hours, y = value.(e[7,1,hours]),
        stackgroup="one", mode="lines", hoverinfo="x+y",
        line=attr(width=0.5, color="rgb(52, 254, 123)"),
        name="Nuclear"  # Add name attribute here
    ),
    PlotlyJS.scatter(
        hours = hours, y =imported[1,hours],
        stackgroup="one", mode="lines", hoverinfo="x+y",
        line=attr(width=0.5, color="rgb(0, 255, 217)"),
        name=" Imported Transmission"  # Add name attribute here
    ),
    PlotlyJS.scatter(hours=hours,y=Load_DE[hours], line=attr(width=3,color="black"),
    name="load")
], Layout(
    xaxis_title = "Hours",
    yaxis_title = "MWh",
    title = "Energy production in Germany between hour 147 and 651"
))
using StatsPlots

ticklabel = ["Germany","Sweden", "Denmark"]
plot2=StatsPlots.groupedbar([power[1,:] power[2, :] power[3, :] power[4,:] power[5,:] power[7,:]],
    bar_position = :stack,
    bar_width = 0.7,
    xticks = (1:3, ticklabel),
    label = ["Wind" "PV" "Gas" "Hydro" "Battery" "Nuclear"],
    bar_color=[":white" ":yellow" ":red" ":blue"])


ticklabel = ["Germany","Sweden", "Denmark"]
plot3=StatsPlots.groupedbar([value.(z[1,:]) value.(z[2, :]) value.(z[3, :]) value.(z[4,:]) value.(z[5,:]) value.(z[7,:])],
    bar_position = :stack,
    bar_width = 0.7,
    xticks = (1:3, ticklabel),
    label = ["Wind" "PV" "Gas" "Hydro" "Battery" "Nuclear"],
    bar_color=[":white" ":yellow" ":red" ":blue"])

ticklabel=["Germany_Sweden","Germany_Denmark", "Sweden_Denmark"]
plot4=Plots.bar(ticklabel,[value.(Trans_Cap[1,2]), value.(Trans_Cap[1,3]), value.(Trans_Cap[2,3])],xlabel="countries",ylabel="Transmission Capacities (MW)", title="Transmission Capacities by\n Country to country", legend=false)


plot5=Plots.plot(S, cumsum(imported[1,S]),label="Germany")
Plots.plot!(S, cumsum(imported[2,S]),label="Swedem")
Plots.plot!(S, cumsum(imported[3,S]),label="Denmark")
xlabel!("hours")
ylabel!("MWh")
title!("The imported cumulative transmission")

PlotlyJS.savefig(plot1, "germany_4.svg")
Plots.savefig(plot2, "annaual_4.svg")
Plots.savefig(plot3, "capacity_4.svg")
Plots.savefig(plot4, "Transmission_capacity_4.svg")
Plots.savefig(plot5, "Transmission_flows_4.svg")
println("Average cap ", Avg_cap_PV_Wind)

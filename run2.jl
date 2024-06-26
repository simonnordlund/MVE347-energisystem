using JuMP      #load the package JuMP
using Clp       #load the package Clp (an open linear-programming solver)
using Gurobi   #The commercial optimizer Gurobi requires installation
include("mod2.jl")
m, e, z = build_energy_model("dat2.jl")
#print(m) # prints the model instance
#set_optimizer(m, clp.Optimizer)
set_optimizer_attribute(m, "LogLevel", 1)
set_optimizer(m, Gurobi.Optimizer)
optimize!(m)

println("z =  ", objective_value(m))   		# display the optimal solution
println("x=",(0.202/0.4)*sum(value.(e[3,j,s]) for s in S for j in J),"co2")


power=zeros(length(I),length(J))

for i in I, j in J
    power[i,j]=value.(sum(e[i,j,s] for s in S))
end

Power_per_hour=zeros(length(I),length(J),length(S))
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
        name="battery"  # Add name attribute here
    ),
    PlotlyJS.scatter(hours=hours,y=Load_DE[hours], line=attr(width=1,color="black"),
    name="load")
], Layout(
    xaxis_title = "Hours",
    yaxis_title = "MWh",
    title = "Energy production in Germany between hour 147 and 651"
))
using StatsPlots

ticklabel = ["Germany","Sweden", "Denmark"]
plot2=StatsPlots.groupedbar([power[1,:] power[2, :] power[3, :] power[4,:] power[5,:]],
    bar_position = :stack,
    bar_width = 0.7,
    xticks = (1:3, ticklabel),
    label = ["Wind" "PV" "Gas" "Hydro" "battery"],
    bar_color=[":white" ":yellow" ":red" ":blue"])


ticklabel = ["Germany","Sweden", "Denmark"]
plot3=StatsPlots.groupedbar([value.(z[1,:]) value.(z[2, :]) value.(z[3, :]) value.(z[4,:]) value.(z[5,:])],
    bar_position = :stack,
    bar_width = 0.7,
    xticks = (1:3, ticklabel),
    label = ["Wind" "PV" "Gas" "Hydro" "Battery"],
    bar_color=[":white" ":yellow" ":red" ":blue" "Green"])


PlotlyJS.savefig(plot1, "germany_2.svg")
Plots.savefig(plot2, "annaual_2.svg")
Plots.savefig(plot3, "capacity_2.svg")
println("Average cap ", Avg_cap_PV_Wind)

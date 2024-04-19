using JuMP      #load the package JuMP
using Clp       #load the package Clp (an open linear-programming solver)
using Gurobi   #The commercial optimizer Gurobi requires installation
include("mod.jl")
m, e, z = build_energy_model("dat.jl")
#print(m) # prints the model instance
#set_optimizer(m, clp.Optimizer)
set_optimizer_attribute(m, "LogLevel", 1)
set_optimizer(m, Gurobi.Optimizer)
optimize!(m)

println("z =  ", objective_value(m))   		# display the optimal solution
println("x=",(0.202/0.4)*sum(value.(e[3,j,s]) for s in S for j in J),"co2")

#power=zeros(I,J)

#for i in I, j in J
#    power[i,j]=value.sum(x[i,j,s] for s in S)
#end
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
        line=attr(width=0.5, color="rgb(255, 255, 255)"),
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
    PlotlyJS.plot(hours=hours,y=Load_DE[hours])
], Layout(
    xaxis_title = "Hours",
    yaxis_title = "MWh",
    title = "Energy production in Germany between hour 147 and 651"
))

PlotlyJS.savefig(plot1, "germany_1.svg")

PlotlyJS.savefig(plot1,"germany_1.svg")
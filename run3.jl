using JuMP      #load the package JuMP
using Clp       #load the package Clp (an open linear-programming solver)
using Gurobi   #The commercial optimizer Gurobi requires installation
include("mod3.jl")
m, e, z,Trans_Cap,Trans_Flow = build_energy_model("dat3.jl")
#print(m) # prints the model instance
#set_optimizer(m, clp.Optimizer)
set_optimizer_attribute(m, "LogLevel", 1)
set_optimizer(m, Gurobi.Optimizer)
optimize!(m)

println("z =  ", objective_value(m))   		# display the optimal solution
println("x=",(0.202/0.4)*sum(value.(e[3,j,s]) for s in S for j in J),"co2")
println("transmission production =", " DE ",value.(Trans_Cap[1,2])," SE ", value.(Trans_Cap[3,1]), " DK ", value.(Trans_Cap[2,3]) )
println("Transmission net ","DE  ", value.(sum(Trans_Flow[1,2,s] for s in S) ), "--SE--- ", value.( sum(Trans_Flow[1,3,s] for s in S) ), "---DK--- ", value.( sum(Trans_Flow[2,3,s] for s in S) ) )


power=zeros(length(I),length(J))

for i in I, j in J
    power[i,j]=value.(sum(e[i,j,s] for s in S))
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
        name="hydro"  # Add name attribute here
    ),
    PlotlyJS.scatter(
        hours = hours, y = value.(e[5,1,hours]),
        stackgroup="one", mode="lines", hoverinfo="x+y",
        line=attr(width=0.5, color="rgb(66, 108, 245)"),
        name="battery"  # Add name attribute here
    ),
    PlotlyJS.scatter(hours=hours,y=Load_DE[hours], line=attr(width=3,color="black"),
    name="load")
], Layout(
    xaxis_title = "Hours",
    yaxis_title = "MWh",
    title = "Energy production in Germany between hour 147 and 651"
))
using StatsPlots

ticklabel = ["Sweden", "Germany", "Denmark"]
plot2=StatsPlots.groupedbar([power[1,:] power[2, :] power[3, :] power[4,:] power[5,:]],
    bar_position = :stack,
    bar_width = 0.7,
    xticks = (1:3, ticklabel),
    label = ["Wind" "PV" "Gas" "Hydro" "Batterattery"],
    bar_color=[":white" ":yellow" ":red" ":blue"])


ticklabel = ["Sweden", "Germany", "Denmark"]
plot3=StatsPlots.groupedbar([value.(z[1,:]) value.(z[2, :]) value.(z[3, :]) value.(z[4,:]) value.(z[5,:]) [value.(Trans_Cap[1,2]), value.(Trans_Cap[1,3]), value.(Trans_Cap[2,3])]],
    bar_position = :stack,
    bar_width = 0.7,
    xticks = (1:3, ticklabel),
    label = ["Wind" "PV" "Gas" "Hydro" "Battery" "Transmission" ],
    bar_color=[":white" ":yellow" ":red" ":blue"])



PlotlyJS.savefig(plot1, "germany_3.svg")
Plots.savefig(plot2, "annaual_3.svg")
Plots.savefig(plot3, "capacity_3.svg")
    
#PlotlyJS.savefig(plot1,"germany_1.svg")
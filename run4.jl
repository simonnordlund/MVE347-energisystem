using JuMP      #load the package JuMP
using Clp       #load the package Clp (an open linear-programming solver)
using Gurobi   #The commercial optimizer Gurobi requires installation
include("mod4.jl")
m, x, z,Trans_Cap,Trans_Flow = build_energy_model("dat4.jl")
#print(m) # prints the model instance
#set_optimizer(m, clp.Optimizer)
set_optimizer_attribute(m, "LogLevel", 1)
set_optimizer(m, Gurobi.Optimizer)
optimize!(m)

println("z =  ", objective_value(m))   		# display the optimal solution
println("x=",(0.202/0.4)*sum(value.(x[3,j,s]) for s in S for j in J),"co2")
println("transmission production =", " DE-SE ",value.(Trans_Cap[1,2])," DK-DE ", value.(Trans_Cap[3,1]), " SE-Dk ", value.(Trans_Cap[2,3]) )
println("Transmission flow ","DE-SE  ", value.(sum(Trans_Flow[1,2,s] for s in S) ), "--DE-DK--- ", value.( sum(Trans_Flow[1,3,s] for s in S) ), "---SE-DK--- ", value.( sum(Trans_Flow[2,3,s] for s in S) ) )

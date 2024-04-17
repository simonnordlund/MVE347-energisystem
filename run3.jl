using JuMP      #load the package JuMP
using Clp       #load the package Clp (an open linear-programming solver)
using Gurobi   #The commercial optimizer Gurobi requires installation
include("mod3.jl")
m, x, z,Trans_Net = build_energy_model("dat3.jl")
#print(m) # prints the model instance
#set_optimizer(m, clp.Optimizer)
set_optimizer_attribute(m, "LogLevel", 1)
set_optimizer(m, Gurobi.Optimizer)
optimize!(m)

println("z =  ", objective_value(m))   		# display the optimal solution
println("x=",(0.202/0.4)*sum(value.(x[3,j,s]) for s in S for j in J),"co2")
println("transmission production =", "DE",value.(z[6,1]),"SE", value.(z[6,2]), "DK", value.(z[6,3]) )
println("Transmission net ","DE  ", value.(sum(Trans_Net[1,s] for s in S) ), "--SE--- ", value.( sum(Trans_Net[2,s] for s in S) ), "---DK--- ", value.( sum(Trans_Net[3,s] for s in S) ) )
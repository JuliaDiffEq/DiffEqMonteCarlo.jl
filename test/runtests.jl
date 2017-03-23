using DiffEqMonteCarlo, StochasticDiffEq, DiffEqBase, DiffEqProblemLibrary, OrdinaryDiffEq
using Base.Test


prob = prob_sde_2Dlinear
sim = monte_carlo_simulation(prob,SRIW1(),dt=1//2^(3),max_samples=10)
calculate_sim_errors(sim)

prob = prob_sde_additivesystem
output_func = function (sol)
  sol.u[end]
end
end_condition = function (solution_data)
  std(solution_data[1])/length(solution_data[1])<1.
end
experiment = MonteCarloExperiment(prob,output_func,identity,end_condition,SRA1())
sim = monte_carlo_simulation(experiment,SerialCrude(),dt=1//2^(3),max_samples=50)

#prob = prob_sde_lorenz
#sim = monte_carlo_simulation(prob,SRIW1(),dt=1//2^(3),max_samples=10)
#
prob = prob_ode_linear
prob_func = function (prob)
  prob.u0 = rand()*prob.u0
  prob
end
end_condition = function (solution_data)
  false
end
experiment = MonteCarloExperiment(prob,output_func,prob_func,end_condition,Tsit5())
sim = monte_carlo_simulation(experiment,SerialCrude(),dt=1//2^(3),max_samples=10)

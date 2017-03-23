__precompile__()

module DiffEqMonteCarlo

using DiffEqBase, RecipesBase

include("experiment.jl")
include("estimators.jl")
include("montecarlo.jl")

@recipe function f(sim::AbstractMonteCarloSimulation)

  for sol in sim
    @series begin
      legend := false
      sol
    end
  end
end

export monte_carlo_simulation, calculate_sim_errors

export MonteCarloSimulation, MonteCarloTestSimulation

export MonteCarloEstimator, ParallelCrude, SerialCrude

export MonteCarloExperiment

end # module

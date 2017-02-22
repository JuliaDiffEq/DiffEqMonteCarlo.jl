type MonteCarloTestSimulation{S,T} <: AbstractMonteCarloSimulation
  experiment::MonteCarloExperiment
  solution_data::S
  errors::Dict{Symbol,Vector{T}}
  error_means::Dict{Symbol,T}
  error_medians::Dict{Symbol,T}
  elapsedTime::Float64
  converged::Bool
end

type MonteCarloSimulation{T} <: AbstractMonteCarloSimulation
  experiment::MonteCarloExperiment
  solution_data::Vector{T}
  elapsedTime::Float64
  converged::Bool
end


"""
`monte_carlo_simulation(prob::DEProblem,alg)`

Performs a parallel Monte-Carlo simulation to solve the DEProblem numMonte times.
Returns a vector of solution objects.

### Keyword Arguments
* `numMonte` - Number of Monte-Carlo simulations to run. Default is 10000
* `save_timeseries` - Denotes whether save_timeseries should be turned on in each run. Default is false.
* `kwargs...` - These are common solver arguments which are then passed to the solve method
"""
function calculate_sim_errors(sim::MonteCarloSimulation)
  solution_data = sim.solution_data
  errors = Dict{Symbol,Vector{eltype(solution_data[1].u[1])}}() #Should add type information
  error_means  = Dict{Symbol,eltype(solution_data[1].u[1])}()
  error_medians= Dict{Symbol,eltype(solution_data[1].u[1])}()
  for k in keys(solution_data[1].errors)
    errors[k] = [sol.errors[k] for sol in solution_data]
    error_means[k] = mean(errors[k])
    error_medians[k]=median(errors[k])
  end
  return MonteCarloTestSimulation(sim.experiment,solution_data,errors,error_means,error_medians,sim.elapsedTime,sim.converged)
end


function monte_carlo_simulation(experiment::MonteCarloExperiment,estimator::ParallelCrude; start_check = 10,max_samples=10000,kwargs ...)
  prob = experiment.prob
  prob_func = experiment.prob_func
  output_func = experiment.output_func
  alg = experiment.path_alg
  elapsedTime = @elapsed solution_data = pmap((i)-> begin
    new_prob = prob_func(deepcopy(prob))
    output_func(solve(new_prob,alg;kwargs...))
  end,1:max_samples)
  solution_data = convert(Array{typeof(solution_data[1])},solution_data)
  return(MonteCarloSimulation(experiment,solution_data,elapsedTime,false))
end

function monte_carlo_simulation(experiment::MonteCarloExperiment,estimator::SerialCrude;start_check = 10,max_samples=10000,kwargs ...)
  prob = experiment.prob
  alg = experiment.path_alg
  prob_func = experiment.prob_func
  output_func = experiment.output_func
  end_condition = experiment.end_condition
  # generate one sample so that we know type of solution_data
  solution_data = []
  new_prob = prob_func(deepcopy(prob))
  push!(solution_data,output_func(solve(new_prob,alg;kwargs...)))
  solution_data = convert(Array{typeof(solution_data[1])},solution_data)
  # perform monte carlo sims
  converged = false
  elapsedTime = @elapsed for i=1:max_samples
    new_prob = prob_func(deepcopy(prob))
    push!(solution_data,output_func(solve(new_prob,alg;kwargs...)))
    if end_condition(solution_data) && i>start_check
      converged = true
      break
    end
  end
  return(MonteCarloSimulation(experiment,solution_data,elapsedTime,converged))
end

function monte_carlo_simulation(prob::DEProblem,alg;output_func = identity,prob_func=identity,start_check=10,max_samples=10000,kwargs...)
  end_condition =  (x)->false
  experiment  = MonteCarloExperiment(prob,output_func,prob_func,end_condition,alg)
  monte_carlo_simulation(experiment,ParallelCrude(),max_samples = 10000;kwargs ...)
end

Base.length(sim::AbstractMonteCarloSimulation) = length(sim.solution_data)
Base.endof( sim::AbstractMonteCarloSimulation) = length(sim)
Base.getindex(sim::AbstractMonteCarloSimulation,i::Int) = sim.solution_data[i]
Base.getindex(sim::AbstractMonteCarloSimulation,i::Int,I::Int...) = sim.solution_data[i][I...]
Base.size(sim::AbstractMonteCarloSimulation) = (length(sim),)
Base.start(sim::AbstractMonteCarloSimulation) = 1
function Base.next(sim::AbstractMonteCarloSimulation,state)
  state += 1
  (sim[state],state)
end
Base.done(sim::AbstractMonteCarloSimulation,state) = state >= length(sim)

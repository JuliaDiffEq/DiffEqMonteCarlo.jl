type MonteCarloExperiment{S,F1,F2,F3,J}
  prob::S
  output_func::F1
  prob_func::F2
  end_condition::F3
  path_alg::J
end

function MonteCarloExperiment(prob::DEProblem,output_func,prob_func,end_condition,path_alg)
   MonteCarloExperiment{typeof(prob),typeof(output_func),
   typeof(prob_func),typeof(end_condition),typeof(path_alg)}(prob,output_func,prob_func,end_condition,path_alg)
end

# MonteCarloExperiment(prob::DEProblem,estimator::MonteCarloEstimator) =  MonteCarloExperiment(prob,estimator,
#      identity,identity,(solution_data)->false,1000)
#
# MonteCarloExperiment(prob::DEProblem,estimator::MonteCarloEstimator) =  MonteCarloExperiment(prob,estimator,
#         identity,identity,(solution_data)->false,1000)

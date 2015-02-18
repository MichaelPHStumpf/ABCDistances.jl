#####################################
##General ABC code
##i.e. type definitions and utilities
#####################################

##################
##TYPE DEFINITIONS
#################
##Input for an ABC analysis
type ABCInput
    rprior::Function
    dprior::Function
    ##rdata::Function
    ##data2sumstats::Function
    sample_sumstats::Function
    abcnorm::ABCNorm
    sobs::Array{Float64, 1}
    nparameters::Int32
    nsumstats::Int32    
end

##Full results of an ABC analysis
abstract ABCOutput

##Rejection sampling output
type ABCRejOutput <: ABCOutput
    nsims::Int32
    parameters::Array{Float64, 2}
    sumstats::Array{Float64, 2}
    distances::Array{Float64, 1}
    weights::Array{Float64, 1}
    abcnorm::ABCNorm
end

##TO DO
##ABC SMC output
##type ABCSMCOutput <: ABCOutput
##end

#################
##CONSTRUCTORS
#################
##Semi-sensible defaults
function ABCInput()
    ABCInput(()->rand(1),  ##rprior U(0,1) prior on 1 parameter
             (x)->1.0,      ##dprior is improper uniform prior
             (x)->rand(1), ##sample_sumstats draws from U(0,1) independent of parameters
             Euclidean(),  ##abcnorm
             [1.0],         ##sobs
             1,             ##nparameters
             1)             ##nsumstats
end

#################
##UTILITY METHODS
#################
function show(io::IO, out::ABCRejOutput)
    (p,k) = size(out.parameters)
    means = Array(Float64, p)
    CI_lower = Array(Float64, p)
    CI_upper = Array(Float64, p)
    for i in 1:p
        y = squeeze(out.parameters[i,:], 1)
        means[i] = sum(y.*out.weights)/sum(out.weights)
        if (maximum(out.weights)==minimum(out.weights)) 
          (CI_lower[i], CI_upper[i]) = quantile(y, [0.025,0.975])
        else
          ##Crude way to approximate weighted quantiles
          z = sample(y, WeightVec(out.weights), 1000)
          (CI_lower[i], CI_upper[i]) = quantile(z, [0.025,0.975])
        end
    end
    print("ABC output, $k accepted values from $(out.nsims) simulations\n")
    print("Means and rough 95% credible intervals:\n")
    for (i in 1:p)
        @printf("Parameter %d: %.2e (%.2e,%.2e)\n", i, means[i], CI_lower[i], CI_upper[i])
    end
end

function copy(out::ABCRejOutput)
    ABCRejOutput(out.nsims, out.parameters, out.sumstats, out.distances, out.weights, out.abcnorm)
end

##Sort output into distance order
function sortABCOutput!(out::ABCRejOutput)
    ##Sort results into closeness order
    closenessorder = sortperm(out.distances)
    out.parameters = out.parameters[:,closenessorder]
    out.sumstats = out.sumstats[:,closenessorder]
    out.distances = out.distances[closenessorder]
    out.weights = out.weights[closenessorder]
    return
end

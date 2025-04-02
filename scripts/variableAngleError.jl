using Pkg
Pkg.activate(@__DIR__)

# add MPMtools
include(joinpath(@__DIR__, "external", "MPMtools.jl", "src", "MPMtools.jl"))
using .MPMtools.MRIutils: dR1, ernst, ernstd, optimalDFAparameters
using .MPMtools.MRImaps: calculateR1
using .MPMtools.MRItypes: WeightedContrast

using Statistics
using Plots

R1 = 0.82    # 1/s; in vivo WM 7T value in Rooney, et al. (2007)
TR = 31.6e-3 # s;   TR used for in vivo experiments

σ = 1/100
ninst = 1000
nrep = 200

# function to simulate ninst noise instantiations 
# to estimate standard deviation of R1 estimate 
function dR1sim(R1,fa1,fa2,TR1,TR2,σ,ninst)
    S1 = ernst(fa1,TR1,R1)
    S2 = ernst(fa2,TR2,R1)

    r = randn(2,ninst)*σ
    S1n = WeightedContrast.((S1.signal .+ r[1,:]), S1.flipangle, S1.TR)
    S2n = WeightedContrast.((S2.signal .+ r[2,:]), S2.flipangle, S2.TR)

    R1est = calculateR1.(S1n,S2n)

    return std(R1est)
end

# optimal parameters and propagated error for estimating R1 without angle restriction
trueopt = optimalDFAparameters(2*TR, R1; PDorR1="R1")
σmin = dR1(R1,1.0,1.0,trueopt...)
σminm = dR1sim(R1,trueopt...,σ,100*ninst)

# optimal parameters and propagated errors with maximum flip angle restriction
FAmax = range(5,rad2deg(maximum(trueopt[1:2])),length=20)
opt = [optimalDFAparameters(2*TR, R1; PDorR1="R1", FAmax=FAmax) for FAmax in deg2rad.(FAmax)]
σR1 = [dR1(R1,1.0,1.0,fa1,fa2,TR1,TR2) for (fa1,fa2,TR1,TR2) in opt]
σR1m = [[dR1sim(R1,fa1,fa2,TR1,TR2,σ,ninst) for (fa1,fa2,TR1,TR2) in opt] for n in 1:nrep]

# plot relative increase in error due to flip angle restriction
p = plot()
for σR1 in σR1m
    plot!(FAmax,100*(σR1 .- σminm)/σminm, label="", color=:grey, alpha=0.1)
end
plot!(FAmax,100*(σR1 .- σmin)/σmin, label="", color=:black)
ylims!(0,20)
xlabel!("maximum allowed flip angle (°)")
ylabel!("relative increase in error (%)")

savefig(p, joinpath(dirname(@__DIR__),"figures","variableangleerror.png"))

return p
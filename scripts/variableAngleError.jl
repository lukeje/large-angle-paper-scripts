using Pkg
Pkg.activate(@__DIR__)

# add MPMtools
include(joinpath(@__DIR__, "external", "MPMtools.jl", "src", "MPMtools.jl"))
using .MPMtools.MRIutils: dR1, ernst, optimalDFAparameters

using Statistics
using Plots

R1 = 0.82    # 1/s; in vivo WM 7T value in Rooney, et al. (2007)
TR = 31.6e-3 # s;   TR used for in vivo experiments
σ = 1.0 # only matters for absolute scaling of error, not relative scaling

# optimal parameters and propagated error for estimating R1 without angle restriction
trueopt = optimalDFAparameters(2*TR, R1; PDorR1="R1")
σR1min = dR1(R1,σ,σ,trueopt...)

# optimal parameters and propagated errors with maximum flip angle restriction
FAmax = range(5,rad2deg(maximum(trueopt[1:2])),length=50)
opt = [optimalDFAparameters(2*TR, R1; PDorR1="R1", FAmax=FAmax) for FAmax in deg2rad.(FAmax)]
σR1 = [dR1(R1,σ,σ,fa1,fa2,TR1,TR2) for (fa1,fa2,TR1,TR2) in opt]

# plot relative increase in error due to flip angle restriction
p = plot(FAmax,100*(σR1 .- σR1min)/σR1min, label="", linewidth=2)
ylims!(0,20)
xlabel!("maximum allowed flip angle (°)")
ylabel!("relative increase in R1 error (%)")

savefig(p, joinpath(dirname(@__DIR__),"figures","variableangleerror.png"))

return p
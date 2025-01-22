using Pkg
Pkg.activate(@__DIR__)

# add MPMtools
include(joinpath(@__DIR__, "external", "MPMtools.jl", "src", "MPMtools.jl"))
using .MPMtools.MRIutils: optimalDFAparameters

using Plots

outdir = joinpath(dirname(@__DIR__),"figures")

# input parameters
R1     = 0.82         # 1/s; 1e3/1220, the T1 for WM in Rooney, et al. (2007)
TR     = 31.6 .* 1e-3 # s

# find optimal TR/α pairs for different weightings of parameters
param_weightings = range(0.0, 1.0, length=7)
params = [optimalDFAparameters(2TR, R1, PDorR1=w, TRmin=0.0, FAmax=3π/2) for w in param_weightings]

# sort and convert parameters to be useable units
α1  = [rad2deg(p[1]) for p in params] # degrees
α2  = [rad2deg(p[2]) for p in params] # degrees
TR1 = [1e3p[3] for p in params]       # ms
TR2 = [1e3p[4] for p in params]       # ms

# sort contrasts by α to separate into PDw (α1, TR1) and T1w (α2, TR2)
for (i,α) in pairs(α1)
    if α>α2[i]
        TR2[i], TR1[i] = TR1[i], TR2[i]
        α2[i],  α1[i]  = α1[i],  α2[i]
    end
end

# plot TR as a function of parameter weighting
f = scatter(param_weightings, [TR1 TR2], label=["PD-weighted" "T1-weighted"], markershape=[:square :diamond])
xlims!(-0.1,1.1)
xticks!([0, 0.5, 1], ["σ²(PD)/PD²", "0.5[σ²(PD)/PD²] + 0.5[σ²(R1)/R1²]", "σ²(R1)/R1²"])
xlabel!("relative weighting of parameter errors in optimisation")
ylims!(0,2TR*1e3)
ylabel!("TR (ms)")

# label points with flip angles
annotate!(param_weightings, TR1 .+ 5, string.(round.(α1,digits=1)) .* "°")
annotate!(param_weightings, TR2 .- 5, string.(round.(α2,digits=1)) .* "°")

# save figure
plot!(dpi=300, xflip=true, legend_position=:topleft)
savefig(f, joinpath(outdir,"TRoptimalangle.png"))

return f

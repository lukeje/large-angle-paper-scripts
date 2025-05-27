using Pkg
Pkg.activate(@__DIR__)

# add MPMtools
include(joinpath(@__DIR__, "external", "MPMtools.jl", "src", "MPMtools.jl"))
using .MPMtools.MRIutils
using .MPMtools.MRImaps

using Plots
using LaTeXStrings

# same parameters as used for the in vivo simulation in smallAngleSim.jl
R1     = 0.82 
TR     = 31.6e-3
fa1 = 5
fa2 = 27

# Define the different functions
function pade(fa, R1TR)
    return sin(fa) * R1TR /(1 - cos(fa) + R1TR*(1+cos(fa))/2)
end

function taylorratio(fa, R1TR)
    return sin(fa) * R1TR /(1-cos(fa)*(1-R1TR))
end
taylorratiod(fa, R1TR) = taylorratio(deg2rad(fa), R1TR)

# solution of taylorratiod for two datasets measured at different fa and/or tr
function R1esttaylorratiod(fa1,fa2,tr1,tr2,S1,S2)
    s1,c1 = sincosd(fa1)
    s2,c2 = sincosd(fa2)
    return ( (S1/S2)*(1 - c1) - (s1/s2)*(tr1/tr2)*(1 - c2) ) / ( (c2*(s1/s2) - (S1/S2)*c1)*tr1 )
end

# relative error in percent for plotting
relerror(a,b) = 100*(a-b)/b

# Plot differences in signal from different methods
fa = range(0,π/2,length=100)
S = [MRIutils.ernst(a, TR, R1).signal for a in fa]

p1 = plot(legend_position=:right, dpi=300, size=(400,300))
plot!(rad2deg.(fa),relerror.(taylorratio.(fa, R1*TR), S), label="Approx. without small angle assumption from Ref. 7")
plot!(rad2deg.(fa),relerror.(pade.(fa, R1*TR), S), label="Approx. from this manuscript")
xlabel!("flip angle (°)")
ylabel!("relative error\nin signal (%)")
ylims!(-0.35,1.3)

# Plot differences in R1 estimates with different methods
R1s = range(0.3,1.3,length=100)

# check that solution of Taylor ratio approximation consistent
S1t = taylorratiod.(fa1,R1s*TR)
S2t = taylorratiod.(fa2,R1s*TR)
R1estconsistent = R1esttaylorratiod.(fa1,fa2,TR,TR,S1t,S2t)
@assert all(isapprox.(R1estconsistent,R1s))

# bias in R1 due to using Taylor ratio approximation
S1 = MRIutils.ernstd.(fa1, TR, R1s)
S2 = MRIutils.ernstd.(fa2, TR, R1s)
R1taylorratio = R1esttaylorratiod.(fa1,fa2,TR,TR,[s.signal for s in S1],[s.signal for s in S2])
R1pade = MRImaps.calculateR1.(S1,S2)

p2 = plot()
plot!(R1s,relerror.(R1taylorratio,R1s),label="")
plot!(R1s,relerror.(R1pade,R1s),label="")
ylabel!("relative error in\nR1 estimate (%)")
xlabel!(L"ground truth R1 (s$^{-1}$)")

p = plot(p1,p2,layout=[1;1],dpi=300)
savefig(p, joinpath(dirname(@__DIR__),"figures","differentapprox.png"))

return p
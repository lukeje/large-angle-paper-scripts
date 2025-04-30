using Pkg
Pkg.activate(@__DIR__)

using Glob: glob
using NIfTI
using Plots
using Statistics

inroot = joinpath(dirname(@__DIR__), "phantom", "derived")
maskfile = joinpath(inroot, "spm", "sub-phantom", "mask.nii")
indir = joinpath(inroot, "hmri", "sub-phantom")
outdir = joinpath(dirname(@__DIR__), "figures")

# R1 maps
R1PDopt = niread(glob("*R1.nii", joinpath(indir,"anat","seste","PDopt","nosa","Results"))[])
R1R1opt = niread(glob("*R1.nii", joinpath(indir,"anat","seste","R1opt","nosa","Results"))[])

# phantom mask
mask = niread(maskfile) .> 0

m = (R1PDopt[mask] .+ R1R1opt[mask])/2
d =  R1PDopt[mask] .- R1R1opt[mask]

h = histogram2d(m,d)
x = [xlims()...]
plot!(x,              mean(d)*[1,1], color=:blue, label="")
plot!(x,(mean(d)+1.96*std(d))*[1,1], color=:red,  label="")
plot!(x,(mean(d)-1.96*std(d))*[1,1], color=:red,  label="")
xlims!(x...)
xlabel!("mean R1 (1/s)")
ylabel!("R1 difference (1/s)")

savefig(h, joinpath(outdir,"phantom_R1baplot.png"))

using Pkg
Pkg.activate(@__DIR__)

using Glob: glob
using NIfTI
using Images, ImageTransformations, ImageMorphology
using CoordinateTransformations, Interpolations
using Plots
using Statistics
using JSON

inroot = joinpath(dirname(@__DIR__), "phantom", "derived")
maskfile = joinpath(inroot, "spm", "sub-phantom", "mask.nii")
indir = joinpath(inroot, "hmri", "sub-phantom")
outdir = joinpath(dirname(@__DIR__), "figures")

# R1 maps
R1PDopt = niread(glob("*R1.nii", joinpath(indir,"anat","seste","PDopt","nosa","Results"))[])
R1R1opt = niread(glob("*R1.nii", joinpath(indir,"anat","seste","R1opt","nosa","Results"))[])

# convert affine matrix from NIfTI header to format for `warp`; last term converts between 1- and 0-based indexing
convertToMap(a) = Translation(a[1:3,4]) ∘ LinearMap(a[1:3,1:3]) ∘ Translation([-1, -1, -1])

# B1 map
b1_lowres = niread(glob("*B1map.nii", joinpath(indir,"fmap","seste","Results"))[])

# interpolate B1 map to target (ni) space
target = niread(glob("*R1.nii", joinpath(indir,"anat","seste","PDopt","nosa","Results"))[])
transNI = convertToMap(NIfTI.getaffine(target))
b1 = 0.01*warp(b1_lowres, inv(convertToMap(NIfTI.getaffine(b1_lowres))) ∘ transNI, axes(target), method=BSpline(Linear()))

# phantom mask
mask = niread(maskfile) .> 0

m = (R1PDopt[mask] .+ R1R1opt[mask])/2
d =  R1PDopt[mask] .- R1R1opt[mask]

h = histogram2d(m,d, colorbar=false)
x = [xlims()...]
y = [ylims()...]
plot!(x,              mean(d)*[1,1], color=:blue, label="")
plot!(x,(mean(d)+1.96*std(d))*[1,1], color=:red,  label="")
plot!(x,(mean(d)-1.96*std(d))*[1,1], color=:red,  label="")
xlims!(x...)
ylims!(y...)
xlabel!("mean R1 (1/s)")
ylabel!("R1 difference (1/s)")
title!("raw R1 estimates")

function read_imperfect_spoiling_coeff(file)
    j = JSON.parse(read(file, String))["Output"]
    return Float64.(j["P2_a"]), Float64.(j["P2_b"])
end

function correctR1(R1,fT,a,b)
    A_ISC = (a[1]*fT^2 + a[2]*fT + a[3])*1e-3 # a defined in ms, but our R1 is in 1/s
    B_ISC = b[1]*fT^2 + b[2]*fT + b[3]
    return R1 / ( A_ISC*R1 + B_ISC)
end

imp_sp_file = Dict(o => joinpath(@__DIR__, "Phantom_$(o)opt.json") for o in ["PD","R1"])

(aR1,bR1) = read_imperfect_spoiling_coeff(imp_sp_file["R1"])
(aPD,bPD) = read_imperfect_spoiling_coeff(imp_sp_file["PD"])

m = (correctR1.(R1PDopt[mask],b1[mask],[aPD],[bPD]) .+ correctR1.(R1R1opt[mask],b1[mask],[aR1],[bR1]))/2
d =  correctR1.(R1PDopt[mask],b1[mask],[aPD],[bPD]) .- correctR1.(R1R1opt[mask],b1[mask],[aR1],[bR1])

skipnan(x) = Iterators.filter(isfinite,x)

μ = mean(skipnan(d))
σ = std(skipnan(d))

h2 = histogram2d(m,d, colorbar=false)
plot!(x, μ        *[1,1], color=:blue, label="")
plot!(x,(μ+1.96*σ)*[1,1], color=:red,  label="")
plot!(x,(μ-1.96*σ)*[1,1], color=:red,  label="")
xlims!(x...)
ylims!(y...)
xlabel!("mean R1 (1/s)")
ylabel!("R1 difference (1/s)")
title!("R1 estimates corrected for imperfect spoiling")

p = plot(h,h2,layout=[1,1], dpi=300, size=(800,800), margin=5Plots.mm)

savefig(p, joinpath(outdir,"phantom_R1baplot.png"))

return p

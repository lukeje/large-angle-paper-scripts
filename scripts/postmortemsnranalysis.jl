using Pkg
Pkg.activate(@__DIR__) 

using Glob: glob
using NIfTI
using Images, ImageTransformations, ImageMorphology
using CoordinateTransformations, Interpolations
using Plots
using Polynomials
using Statistics

# input directories
mpmroot = joinpath(dirname(@__DIR__), "postmortem", "processed")
brainmaskfile = joinpath(dirname(mpmroot), "raw", "brainmask.nii")
outdir  = joinpath(dirname(@__DIR__), "figures")

# visualisation options
# lower (upper) bounds slightly different from zero so that zero ytick appears on plot
b1lims  = (60, 110) # p.u.
snrlims = ( 0, 100) # a.u.

# convert affine matrix from NIfTI header to format for `warp`; last term converts between 1- and 0-based indexing
convertToMap(a) = Translation(a[1:3,4]) ∘ LinearMap(a[1:3,1:3]) ∘ Translation([-1, -1, -1])

sub = 1
ses = 1

indir = joinpath(mpmroot, "sub-$sub", "ses-$ses")

# SNR data
ni = niread(joinpath(indir,"pdw_snr","PDw0SNR.nii"))

# B1 map
b1_lowres = niread(glob("*B1map.nii", joinpath(indir,"sa","Results","Supplementary"))[])

# interpolate B1 map to target (ni) space
target = ni
transNI = convertToMap(NIfTI.getaffine(target))
transB1 = convertToMap(NIfTI.getaffine(b1_lowres))
b1 = warp(b1_lowres, inv(transB1) ∘ transNI, axes(target), method=BSpline(Linear()))

# brain mask
histmask = niread(brainmaskfile) .> 0

# restrict analysis to B1 in b1lims
histmask .&= (b1lims[1] .≤ b1 .≤ b1lims[2])

# fit quadratic polynomial to SNR
pfit = fit(b1[histmask], ni[histmask], 2)

# plot SNR
p = histogram2d(b1[histmask], ni[histmask], bins=(range(b1lims...,length=100),range(snrlims...,length=100)), colorbar=:none, background_colour=:white)
plot!(pfit,label="",color=:white)
xlims!(b1lims)
xlabel!("B1 (p.u.)")
ylims!(snrlims)
ylabel!("SNR (a.u.)")

snr100 = pfit(100)

open(joinpath(outdir,"postmortemmeansnrpdw0.txt"), "w") do f
    print(f, mean(snr100))
end

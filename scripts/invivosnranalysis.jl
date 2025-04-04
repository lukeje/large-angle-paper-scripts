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
mpmroot = joinpath(dirname(@__DIR__), "invivo", "processed")
outdir  = joinpath(dirname(@__DIR__), "figures")

# visualisation options
# lower (upper) bounds slightly different from zero so that zero ytick appears on plot
b1lims = (45, 135) # p.u.
snrlims = (0,  40) # a.u.

# convert affine matrix from NIfTI header to format for `warp`; last term converts between 1- and 0-based indexing
convertToMap(a) = Translation(a[1:3,4]) ∘ LinearMap(a[1:3,1:3]) ∘ Translation([-1, -1, -1])

nsub = 6
nses = 2
global p = Matrix{Any}(undef,nsub,nses)
global snr100 = Matrix{Float32}(undef,nsub,nses)
for sub in 1:nsub, ses in 1:nses

    indir = joinpath(mpmroot, "sub-$sub", "ses-$ses")

    # SNR data
    ni = niread(joinpath(indir,"pdw_snr","PDw0SNR.nii"))

    # B1 map
    b1_lowres = niread(glob("*B1map.nii", joinpath(indir,"sa","Results","Supplementary"))[])

    # interpolate B1 map to target (ni) space
    target = ni
    transNI = convertToMap(NIfTI.getaffine(target))
    transB1 = convertToMap(NIfTI.getaffine(b1_lowres))
    b1 = warp(b1_lowres, inv(transB1) ∘ transNI, axes(target), method=BSpline(Cubic()))

    # brain mask
    (gm, wm, csf)  = (niread(glob("c$(n)*PDw_OLSfit_TEzero.nii", joinpath(indir,"sa","Results","Supplementary"))[]) for n in 1:3)
    brain = (gm .+ wm .+ csf) .> 0.0 # mask for visualisation
    histmask = wm .> 0.99 # mask for histograms

    # restrict analysis to B1 in b1lims
    histmask .&= (b1lims[1] .≤ b1 .≤ b1lims[2])

    # fit quadratic polynomial to SNR
    pfit = fit(b1[histmask], ni[histmask], 2)

    # plot SNR
    p[sub,ses] = histogram2d(b1[histmask], ni[histmask], bins=(range(b1lims...,length=100),range(snrlims...,length=100)), colorbar=:none, background_colour=:white)
    plot!(pfit,label="",color=:white)
    xlims!(b1lims)
    xlabel!("B1 (p.u.)")
    ylims!(snrlims)
    ylabel!("SNR (a.u.)")

    snr100[sub,ses] = pfit(100)
end

open(joinpath(outdir,"invivomeansnrpdw0.txt"), "w") do f
    print(f, mean(snr100))
end

using Pkg
Pkg.activate(@__DIR__) 

using Glob: glob
using NIfTI
using Images, ImageTransformations
using CoordinateTransformations, Interpolations
using Plots, LaTeXStrings
using Statistics: mean, std
using DataFrames
using CSV

# input directories
mpmroot = joinpath(dirname(@__DIR__), "invivo", "processed")
outdir  = joinpath(dirname(@__DIR__), "figures")

# convert affine matrix from NIfTI header to format for `warp`; last term converts between 1- and 0-based indexing
convertToMap(a) = Translation(a[1:3,4]) ∘ LinearMap(a[1:3,1:3]) ∘ Translation([-1, -1, -1])

# reslice to new space
# assumes nifti images are all 3D
function reslice(img, tmov::AbstractAffineMap, niref::NIVolume)
    tref = convertToMap(NIfTI.getaffine(niref))
    
    return warp(img, inv(tmov) ∘ tref, axes(niref), method=BSpline(Constant()))
end
reslice(nimov::NIVolume, niref::NIVolume) = reslice(nimov[:,:,:], convertToMap(NIfTI.getaffine(nimov)), niref)

# within- and between-subject coefficients of variation from Aye, et al. (Neuroimage 2022 https://doi.org/10.1016/j.neuroimage.2022.119249)
skipnan(x) = Iterators.filter(!isnan,x)
logdiff(a,b) = log(mean(skipnan(a))) - log(mean(skipnan(b)))
logmean(a,b) = 0.5log(mean(skipnan(a)) * mean(skipnan(b)))
wcv(ld) = 100*(exp(std(100 .* skipnan(ld))/sqrt(2)/100) - 1)
bcv(lm) = 100abs(std(lm)/mean(lm))

# labels
mpms  = Dict("R1" => (name="R1", folder="Results", xlim=30 .* (-1,1), xlabel="R1 CoV (%)"),
             "PD" => (name="A",  folder="Results", xlim=30 .* (-1,1), xlabel="PD CoV (%)"))
conds = ["sa","nosa","exact"]
condnames = Dict("sa" => "small angle approximation", "nosa" => "Padé approximant", "exact" => "no approximation")

# restrict analysis to 98.75% intervals of B1
b1lims = (45, 135) # p.u.

nsub = 6
global logdiffs = Dict(m => Dict(a => Vector{Float64}(undef,nsub) for a in conds) for m in keys(mpms))
global logmeans = Dict(m => Dict(a => Vector{Float64}(undef,nsub) for a in conds) for m in keys(mpms))
for sub in 1:nsub

    indir = joinpath(mpmroot, "sub-$sub")

    meanparam = Vector{Dict}(undef,2)
    for ses in 1:2

        # MPM data
        ni = Dict(m => 
                    Dict(a => niread(glob("*$(v.name).nii", joinpath(indir,"ses-$ses",a,v.folder))[]) for a in conds)
                for (m,v) in mpms)
        
        # Reference data for transforms
        niref = ni["R1"]["sa"]

        # B1 map
        b1_lowres = niread(glob("*B1map.nii", joinpath(indir,"ses-$ses","sa","Results","Supplementary"))[])
        b1 = reslice(b1_lowres, niref)

        # brain mask
        (gm, wm, _)  = (niread(glob("c$(n)*PDw_OLSfit_TEzero.nii", joinpath(indir,"ses-$ses","sa","Results","Supplementary"))[]) for n in 1:3)
        wmmask = wm .> 0.99

        # only look at voxels where b1 is within 98.75% interval
        wmmask .&= (b1lims[1] .≤ b1 .≤ b1lims[2])

        meanparam[ses] = Dict(m => Dict(a => mean(skipnan(ni[m][a][wmmask])) for a in conds) for (m,v) in mpms)
    end

    # save mean values for plotting
    for (m,v) in first(meanparam), (a,mp1) in v
        global logdiffs[m][a][sub] = logdiff(mp1, last(meanparam)[m][a])
        global logmeans[m][a][sub] = logmean(mp1, last(meanparam)[m][a])
    end
end

w = DataFrame(((MPM=m, approx=a, wcv=wcv(c)) for (m,n) in logdiffs for (a,c) in n))
CSV.write(joinpath(outdir,"invivoretest_wcv.csv"), w)

b = DataFrame(((MPM=m, approx=a, bcv=bcv(c)) for (m,n) in logmeans for (a,c) in n))
CSV.write(joinpath(outdir,"invivoretest_bcv.csv"), b)

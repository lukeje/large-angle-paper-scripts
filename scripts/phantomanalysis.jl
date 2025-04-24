using Pkg
Pkg.activate(@__DIR__) 

using Glob: glob
using NIfTI
using Images, ImageTransformations
using CoordinateTransformations, Interpolations
using Plots, LaTeXStrings
using Statistics
using DataFrames, CSV

# input and output directories
inroot = joinpath(dirname(@__DIR__), "phantom", "derived")
maskfile = joinpath(inroot, "spm", "sub-phantom", "mask.nii")
indir = joinpath(inroot, "hmri", "sub-phantom")
outdir = joinpath(dirname(@__DIR__), "figures")

# should be based on values in data
b1lims = (60,120) # p.u.
difflims = Dict("R1" => (-5,   0.1), 
                "A" => ( -0.1, 1))

# chosen quartiles
q = 0.95

# which run of hMRI toolbox to use for testing. Choose "." to use first run or "Run_XX" to use a later run
run = "."

# convert affine matrix from NIfTI header to format for `warp`; last term converts between 1- and 0-based indexing
convertToMap(a) = Translation(a[1:3,4]) ∘ LinearMap(a[1:3,1:3]) ∘ Translation([-1, -1, -1])

# relative difference accounting for zeros
reldiff(a,b) = b!=0 ? 100 * (a - b)/b : (a==0 ? zero(a) : NaN)

skipnan(x) = Iterators.filter(isfinite,x)

quantilearg(q) = [0+0.5(1 - q), 1-0.5(1 - q)]


# MPM data labels
mpms  = Dict("R1" =>  "R1",
             "A"  => L"$A$")
conds = ["sa","nosa"]
b1maps = ["seste"]
opts = ["R1opt","PDopt"]

# B1 map
b1_lowres = Dict(b => niread(glob("*B1map.nii", joinpath(indir,"fmap",b,run,"Results"))[]) for b in b1maps)

# interpolate B1 map to target (ni) space
target = niread(glob("*R1.nii", joinpath(indir,"anat","afi","PDopt","sa",run,"Results"))[])
transNI = convertToMap(NIfTI.getaffine(target))
b1 = Dict(b => warp(b1_lowres[b], inv(convertToMap(NIfTI.getaffine(b1_lowres[b]))) ∘ transNI, axes(target), method=BSpline(Linear())) for b in b1maps)

# phantom mask
mask = niread(maskfile) .> 0

for b in b1maps
    
    # local mask
    histmask = deepcopy(mask) # mask for histograms

    # get distribution of all B1 values before masking by b1
    b1all = b1[b][histmask]

    # info about B1 values
    qB1 = 0.99
    CSV.write(joinpath(outdir,"phantom_b1-$(b)_b1stats.csv"), 
        DataFrame([skipnan(b1all)] .|> [median ((x) -> quantile(x,quantilearg(qB1))) maximum minimum], ["median", "q$(qB1*100)", "max", "min"]))

    # restrict analysis to B1 in b1lims
    histmask .&= (b1lims[1] .≤ b1[b] .≤ b1lims[2])
    b1local = b1[b][histmask]

    # convenience definitions for creating median plots
    b1vals = range(b1lims..., length=20)

    for o in opts
        ni = Dict((m,a) => niread(glob("*$(m).nii", joinpath(indir,"anat",b,o,a,run,"Results"))[]) for m in keys(mpms), a in conds)

        # plot differences
        global diff = Dict(m => reldiff.(ni[m,"sa"], ni[m,"nosa"]) for (m,_) = keys(ni))
        global p = Dict()
        global counts = Dict()
        global qrs = Dict()
        global n_nonfinite = DataFrame(sub=String[], MPM=String[], method=String[], comparand=String[], voxels=Int[], nonfinite=Int[])
        for comppair in (("sa","nosa"),)
            local diff = Dict(m => reldiff.(ni[m,first(comppair)], ni[m,last(comppair)]) for (m,_) = keys(ni))

            append!(n_nonfinite, DataFrame(((sub="phantom", MPM=m, method=first(comppair), comparand=last(comppair), 
                voxels=count(histmask), nonfinite=count(.!isfinite.(diff[m][histmask]))) for m in keys(diff))) )

            h1 = histogram2d(b1local, diff["R1"][histmask], bins=(range(b1lims...,length=100),range(difflims["R1"]...,length=100)), colorbar=:none, background_colour=:black)
            xlims!(h1, b1lims)
            ylabel!(h1, join(["relative R1", "difference (%)"],'\n'))
            h2 = histogram2d(b1local, diff["A"][histmask], bins=(range(b1lims...,length=100),range(difflims["A"]..., length=100)), colorbar=:none, background_colour=:black)
            xlims!(h2, xlims(h1))
            xlabel!(h2, L"$f_\mathrm{t}$ (%)")
            ylabel!(h2, join([L"relative $A$", "difference (%)"],'\n'))
            local l = @layout [a; b]
            p[comppair] = plot(h1, h2, layout=l)

            # medians of histograms
            counts[comppair] = Dict()
            qrs[comppair]    = Dict()
            for (m,_) in keys(ni)
                counts[comppair][m] = Vector{Float64}(undef,length(b1vals)-1)
                qrs[comppair][m]    = Matrix{Float64}(undef,length(b1vals)-1,2)
                for c = 1:length(b1vals)-1
                    vals = skipnan(diff[m][histmask][b1vals[c] .≤ b1local .< b1vals[c+1]])
                    counts[comppair][m][c] = !isempty(vals) ? median(vals)                   : NaN
                    qrs[comppair][m][c,:] .= !isempty(vals) ? quantile(vals, quantilearg(q)) : NaN
                end
            end
        end

        # example images
        slicedim = 3
        slice = Int(round(size(target,slicedim)/2))
        function hm(i,c,t,ct) # volume, clim, title, colorbar_title
            islice = selectdim(i[:,:,:],slicedim,slice)
            islice[.!selectdim(mask[:,:,:],slicedim,slice)] .= NaN

            h = heatmap(islice, clims=c, aspect_ratio=:equal, color=:grays, axis=false, grid=false, 
                size=(300,200), background_colour=:black, title=t, titlelocation=:left, colorbar_title=ct, yflip=true, xflip=true,
                xlim=(1,size(islice,2)), ylim=(1,size(islice,1)))

            return h
        end
        i1 = hm(ni["R1","nosa"], (0,2), "A: R1 map", L"s$^{-1}$")
        i2 = hm(ni["A","nosa"]./1000, (0,10000)./1000, L"B: $A$ map", L"$10^3$ a.u.")
        i3 = hm(abs.(diff["R1"]), reverse(.-(difflims["R1"])), "C: abs. relative R1 difference", "%")
        i4 = hm(diff["A"], difflims["A"], L"D: relative $A$ difference", "%")
        i5 = hm(b1[b], b1lims, L"E: $f_\mathrm{t}$ map", "%")
        l = @layout [a b; c d; e f]
        exim = plot(i1,i2,i3,i4,i5,plot!(p["sa","nosa"],title=[L"F: $f_\mathrm{t}$ dependence of differences" ""],titlelocation=:left), layout=l, dpi=300, size=(800,800), background_colour=:black)
        savefig(exim, joinpath(outdir,"phantom_b1-$(b)_opt-$(o)_Slices.png"))

        # info about non-finite values
        CSV.write(joinpath(outdir,"phantom_b1-$(b)_opt-$(o)_nonfinite.csv"), n_nonfinite)
    end

end
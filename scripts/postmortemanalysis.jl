using Pkg
Pkg.activate(@__DIR__) 

using Glob: glob
using NIfTI
using Images, ImageTransformations
using CoordinateTransformations, Interpolations
using Plots, LaTeXStrings
using Statistics
using DataFrames, CSV

# input directories
mpmroot = joinpath(dirname(@__DIR__), "postmortem", "processed")
brainmaskfile = joinpath(dirname(mpmroot), "raw", "brainmask.nii")
indir = joinpath(mpmroot, "sub-1", "ses-1")
outdir = joinpath(dirname(@__DIR__), "figures")

# convert affine matrix from NIfTI header to format for `warp`; last term converts between 1- and 0-based indexing
convertToMap(a) = Translation(a[1:3,4]) ∘ LinearMap(a[1:3,1:3]) ∘ Translation([-1, -1, -1])

# relative difference accounting for zeros
reldiff(a,b) = b!=0 ? 100 * (a - b)/b : (a==0 ? zero(a) : NaN)

# MPM data
mpms  = Dict("R1" => (name="R1", folder="Results"),
             "PD" => (name="A",  folder="Results"))
conds = ["sa","nosa","exact"]
ni = Dict((m,a) => niread(glob("*$(v.name).nii", joinpath(indir,a,v.folder))[]) for (m,v) in mpms, a in conds)

# B1 map
b1_lowres = niread(glob("*B1map.nii", joinpath(indir,"sa","Results","Supplementary"))[1])

# interpolate B1 map to target (ni) space
target = ni["R1","sa"]
transNI = convertToMap(NIfTI.getaffine(target))
transB1 = convertToMap(NIfTI.getaffine(b1_lowres))
b1 = warp(b1_lowres, inv(transB1) ∘ transNI, axes(target), method=BSpline(Cubic()))

# orientation labels
scannerorient = NIfTI.orientation(target) # brain scanned in non-standard orientation
brainorient = scannerorient[[3,1,2]] # permutation based on Ilona's scripts

# brain mask
brain = niread(brainmaskfile) .> 0
histmask = deepcopy(brain) # mask for histograms

# get distribution of all B1 values before masking by b1
b1all = b1[histmask]

# restrict analysis to B1 in b1lims
b1lims = (60,110) # p.u.
histmask .&= (b1lims[1] .≤ b1 .≤ b1lims[2])
b1local = b1[histmask]

# convenience definitions for creating median plots
skipnan(x) = Iterators.filter(isfinite,x)
b1vals = range(b1lims..., length=20)
q = 0.95
quantilearg(q) = [0+0.5(1 - q), 1-0.5(1 - q)]

# plot differences
difflims = Dict("R1" => (-60,    0.1), 
                "PD"  => ( -0.1, 50))
global diff = Dict(m => reldiff.(ni[m,"sa"], ni[m,"nosa"]) for (m,_) = keys(ni))
global p = Dict()
global counts = Dict()
global qrs = Dict()
global n_nonfinite = DataFrame(sub=Int[], ses=Int[], MPM=String[], method=String[], comparand=String[], voxels=Int[], nonfinite=Int[])
for comppair in (("sa","nosa"),("sa","exact"),("nosa","exact"))
    local diff = Dict(m => reldiff.(ni[m,first(comppair)], ni[m,last(comppair)]) for (m,_) = keys(ni))

    append!(n_nonfinite, DataFrame(((sub=1, ses=1, MPM=m, method=first(comppair), comparand=last(comppair), 
        voxels=count(histmask), nonfinite=count(.!isfinite.(diff[m][histmask]))) for m in keys(diff))) )

    h1 = histogram2d(b1local, diff["R1"][histmask], bins=(range(b1lims...,length=100),range(difflims["R1"]...,length=100)), colorbar=:none, background_colour=:black)
    xlims!(h1, b1lims)
    ylabel!(h1, join(["relative R1", "difference (%)"],'\n'))
    h2 = histogram2d(b1local, diff["PD"][histmask], bins=(range(b1lims...,length=100),range(difflims["PD"]..., length=100)), colorbar=:none, background_colour=:black)
    xlims!(h2, xlims(h1))
    xlabel!(h2, "B1 / p.u.")
    ylabel!(h2, join(["relative PD", "difference (%)"],'\n'))
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

# plot medians
p_med = Dict()
labelpos = Dict(("R1","nosa") => (:top,    :right),
                ("PD","nosa") => (:bottom, :right),
                ("R1","sa")   => (:top,    :right),
                ("PD","sa")   => (:bottom, :right))
for (m,_) in keys(ni)
    p_med[m] = plot()
    for (b,st,idx) in ((b1vals[1:end-1],:steppost,1:length(b1vals)-1), (last(b1vals,2),:steppre, length(b1vals) .- [2,1]))
        plot!(p_med[m], b, qrs["nosa","exact"][m][idx,1], fillrange=qrs["nosa","exact"][m][idx,2], 
            seriescolor=:blue, label=false, linewidth=0, seriestype=st, alpha=0.25)
        plot!(p_med[m], b, qrs["sa","exact"][m][idx,1], fillrange=qrs["sa","exact"][m][idx,2],
            seriescolor=:red, label=false, linewidth=0, seriestype=st, alpha=0.25)
        plot!(p_med[m], b, hcat((counts[s,"exact"][m][idx] for s in ("nosa","sa"))...), 
                            ylims=difflims[m], ylabel="relative $m error (%)", xticks=(50:25:150), 
                            seriescolor=[:blue :red], label=false, linewidth=2, seriestype=st)
    end
    annotate!(b1vals[end], last(skipnan(counts["nosa","exact"][m])), ("new method",  labelpos[m,"nosa"]..., :black))
    annotate!(b1vals[end], last(skipnan(counts["sa","exact"][m])),   ("small angle method", labelpos[m,"sa"]...,   :black))
end
xlabel!(p_med["PD"],"B1 (p.u.)")

f_med = plot(p_med["R1"],p_med["PD"], layout=(2,1), dpi=300, size=(600,600), plot_title="B: postmortem experiment")
savefig(f_med, joinpath(outdir,"postmortem_median.png"))

# example images
slicedim = 3
slice = Int(round(size(target,slicedim)/2))
function hm(i,c,t,ct) # volume, clim, title, colorbar_title
    islice = selectdim(i[:,:,:],slicedim,slice)
    islice[.!selectdim(brain[:,:,:],slicedim,slice)] .= NaN

    orient = reverse(brainorient[(1:3).≠slicedim]) # reverse as (row,col) => (y,x)

    h = heatmap(islice, clims=c, aspect_ratio=:equal, color=:grays, axis=false, grid=false, 
        size=(300,200), background_colour=:black, title=t, titlelocation=:left, colorbar_title=ct, yflip=true, xflip=true,
        xlim=(1,size(islice,2)), ylim=(1,size(islice,1)))

    #annotate!([0, Int(round(0.5size(islice,2)))], [Int(round(0.5size(islice,1))), 0], [uppercase.(first.(String.(orient)))...], :red) # original labels
    annotate!([last(xlims()), Int(round(0.5size(islice,2)))], [Int(round(0.5size(islice,1))), last(ylims())], 
        replace.(string.(uppercase.(first.(string.([orient...])))), 'A' => 'P','P' => 'A','L' => 'R','R' => 'L'), :red) # labels matching in vivo case

    return h
end
i1 = hm(ni["R1","nosa"], (0,3), "A: R1 map", L"s$^{-1}$")
i2 = hm(ni["PD","nosa"]./1000, (0,10000)./1000, "B: unnormalised PD map", L"$10^3$ a.u.")
i3 = hm(abs.(diff["R1"]), reverse(.-(difflims["R1"])), "C: abs. relative R1 difference", "%")
i4 = hm(diff["PD"], difflims["PD"], "D: relative PD difference", "%")
i5 = hm(b1, b1lims, "E: B1 map", "p.u.")
l = @layout [a b; c d; e f]
exim = plot(i1,i2,i3,i4,i5,plot!(p["sa","nosa"],title=["F: B1 dependence of differences" ""],titlelocation=:left), layout=l, dpi=300, size=(800,800), background_colour=:black)
savefig(exim, joinpath(outdir,"postmortemSlices.png"))

# info about B1 values
qB1 = 0.99
CSV.write(joinpath(outdir,"postmortem_b1stats.csv"), 
    DataFrame([b1all] .|> [median ((x) -> quantile(x,quantilearg(qB1))) maximum minimum], ["median", "q$(qB1*100)", "max", "min"]))

# info about non-finite values
CSV.write(joinpath(outdir,"postmortem_nonfinite.csv"), n_nonfinite)

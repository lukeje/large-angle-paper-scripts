using Pkg
Pkg.activate(@__DIR__) 

using Glob: glob
using NIfTI
using Images, ImageTransformations
using CoordinateTransformations, Interpolations
using Plots, LaTeXStrings
using Statistics
using DataFrames, CSV
using JSON

# input and output directories
mpmroot = joinpath(dirname(@__DIR__), "postmortem", "processed")
brainmaskfile = joinpath(dirname(mpmroot), "raw", "brainmask.nii")
indir = joinpath(mpmroot, "sub-1", "ses-1")
outdir = joinpath(dirname(@__DIR__), "figures")

# file containing imperfect spoiling correction coefficients
imp_sp_file = joinpath(@__DIR__, "Postmortem.json")

# convert affine matrix from NIfTI header to format for `warp`; last term converts between 1- and 0-based indexing
convertToMap(a) = Translation(a[1:3,4]) ∘ LinearMap(a[1:3,1:3]) ∘ Translation([-1, -1, -1])

# relative difference accounting for zeros
reldiff(a,b) = b!=0 ? 100 * (a - b)/b : (a==0 ? zero(a) : NaN)

# MPM data
mpms  = Dict("R1" => (name="R1", folder="Results"))
conds = ["sa","nosa","exact"]
ni = Dict((m,a) => niread(glob("*$m.nii", joinpath(indir,a,v.folder))[]) for (m,v) in mpms, a in conds)

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

function read_imperfect_spoiling_coeff(file)
    j = JSON.parse(read(file, String))["Output"]
    return Float64.(j["P2_a"]), Float64.(j["P2_b"])
end

(a,b) = read_imperfect_spoiling_coeff(imp_sp_file)

function correctR1forimperfectspoiling(R1,fT,a,b)
    A_ISC = (a[1]*fT^2 + a[2]*fT + a[3])*1e-3 # a defined in ms, but our R1 is in 1/s
    B_ISC = b[1]*fT^2 + b[2]*fT + b[3]
    return R1 / ( A_ISC*R1 + B_ISC)
end

# correct R1 for imperfect spoiling
R1 = Dict(k => correctR1forimperfectspoiling.(ni[k], b1*1e-2, [a], [b]) for k in keys(ni))

# plot differences
difflims = Dict("R1" => (-60,    0.1))
global diff = reldiff.(R1["R1","sa"], R1["R1","nosa"])
global p = Dict()
global counts = Dict()
global qrs = Dict()
for comppair in (("sa","nosa"),("sa","exact"),("nosa","exact"))
    local diff = reldiff.(R1["R1",first(comppair)], R1["R1",last(comppair)])

    h1 = histogram2d(b1local, diff[histmask], bins=(range(b1lims...,length=100),range(difflims["R1"]...,length=100)), colorbar=:none, background_colour=:black)
    xlims!(h1, b1lims)
    ylabel!(h1, join(["relative R1", "difference (%)"],'\n'))
    xlabel!(h1, L"$f_\mathrm{t}$ (%)")
    local l = @layout [a; b]
    p[comppair] = plot(h1)

    # medians of histograms
    counts[comppair] = Vector{Float64}(undef,length(b1vals)-1)
    qrs[comppair]    = Matrix{Float64}(undef,length(b1vals)-1,2)
    for c = 1:length(b1vals)-1
        vals = skipnan(diff[histmask][b1vals[c] .≤ b1local .< b1vals[c+1]])
        counts[comppair][c] = !isempty(vals) ? median(vals)                   : NaN
        qrs[comppair][c,:] .= !isempty(vals) ? quantile(vals, quantilearg(q)) : NaN
    end
end

# plot medians
p_med = Dict()
labelpos = Dict(("R1","nosa") => (:top,    :right),
                ("R1","sa")   => (:top,    :right))
p_med = plot()
for (b,st,idx) in ((b1vals[1:end-1],:steppost,1:length(b1vals)-1), (last(b1vals,2),:steppre, length(b1vals) .- [2,1]))
    plot!(p_med, b, qrs["nosa","exact"][idx,1], fillrange=qrs["nosa","exact"][idx,2], 
        seriescolor=:blue, label=false, linewidth=0, seriestype=st, alpha=0.25)
    plot!(p_med, b, qrs["sa","exact"][idx,1], fillrange=qrs["sa","exact"][idx,2],
        seriescolor=:red, label=false, linewidth=0, seriestype=st, alpha=0.25)
    plot!(p_med, b, hcat((counts[s,"exact"][idx] for s in ("nosa","sa"))...), 
                        ylims=difflims["R1"], ylabel="relative R1 error (%)", xticks=(50:25:150), 
                        seriescolor=[:blue :red], label=false, linewidth=2, seriestype=st)
    annotate!(b1vals[end], last(skipnan(counts["nosa","exact"])), ("new method",  labelpos["R1","nosa"]..., :black))
    annotate!(b1vals[end], last(skipnan(counts["sa","exact"])),   ("small angle method", labelpos["R1","sa"]...,   :black))
end
xlabel!(p_med,L"$f_\mathrm{t}$ (%)")

f_med = plot(p_med, dpi=300, size=(600,600), plot_title="B: postmortem experiment")
savefig(f_med, joinpath(outdir,"postmortemimpsp_median.png"))

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
i1 = hm(R1["R1","nosa"], (0,3), "A: R1 map", L"s$^{-1}$")
i3 = hm(abs.(diff), reverse(.-(difflims["R1"])), "C: abs. relative R1 difference", "%")
i5 = hm(b1, b1lims, L"D: $f_\mathrm{t}$ map", "%")
l = @layout [a b; c d]
exim = plot(i1, plot!(p["sa","nosa"],title=[L"B: $f_\mathrm{t}$ dependence of differences" ""],titlelocation=:left), i3, i5, layout=l, dpi=300, size=(800,800), background_colour=:black)
savefig(exim, joinpath(outdir,"postmortemimpspSlices.png"))


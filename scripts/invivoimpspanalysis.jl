using Pkg
Pkg.activate(@__DIR__) 

using Glob: glob
using NIfTI
using Images, ImageTransformations, ImageMorphology
using CoordinateTransformations, Interpolations
using Plots, LaTeXStrings
using Statistics
using DataFrames, CSV
using JSON

# input and output directories
mpmroot = joinpath(dirname(@__DIR__), "invivo", "processed")
outdir  = joinpath(dirname(@__DIR__), "figures")

# file containing imperfect spoiling correction coefficients
imp_sp_file = joinpath(@__DIR__, "InVivo.json")

# visualisation options
# lower (upper) bounds slightly different from zero so that zero ytick appears on plot
b1lims = (45,      135) # p.u.
r1lims = (-0.001,    2) # s^-1
difflims = Dict("R1" => (-8,   0.1)) # %
slicedim = 1

# convert affine matrix from NIfTI header to format for `warp`; last term converts between 1- and 0-based indexing
convertToMap(a) = Translation(a[1:3,4]) ∘ LinearMap(a[1:3,1:3]) ∘ Translation([-1, -1, -1])

# relative difference accounting for zeros
reldiff(a,b) = b!=0 ? 100 * (a - b)/b : (a==0 ? zero(a) : NaN)

# convenience definitions for creating median plots
skipnan(x) = Iterators.filter(isfinite,x)
b1vals = range(b1lims..., length=20)
q = 0.95
quantilearg(q) = [0+0.5(1 - q), 1-0.5(1 - q)]

function hm(i,m,s,c,t,ct,ni) # volume, mask, slice, clim, title, colorbar_title
    islice = selectdim(i[:,:,:],slicedim,s)
    islice[.!m] .= NaN

    # change view
    islice = transpose(islice)
    if isa(i,NIVolume)
        # does not need to be permuted as heatmap has (row,col) => (y,x)
        global orient = NIfTI.orientation(i)[(1:3).≠slicedim]
    else
        global orient = NIfTI.orientation(ni)[(1:3).≠slicedim]
    end

    h = heatmap(islice, clims=c, aspect_ratio=:equal, color=:grays, axis=false, grid=false, 
        size=(300,200), background_colour=:black, title=t, titlelocation=:left, colorbar_title=ct, yflip=false,
        xlim=(1,size(islice,2)), ylim=(1,size(islice,1)))
    annotate!([0, Int(round(0.5size(islice,2)))], [Int(round(0.5size(islice,1))), 0], [uppercase.(first.(String.(orient)))...], :red)
    return h
end

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

nsub = 6
nses = 2
global p = Matrix{Dict}(undef,nsub,nses)
for sub in 1:nsub, ses in 1:nses

    indir = joinpath(mpmroot, "sub-$sub", "ses-$ses")

    # MPM data
    mpms  = Dict("R1" => (name="R1", folder="Results"))
    conds = ["sa","nosa","exact"]
    ni = Dict(m => 
                Dict(a => niread(glob("*$(m).nii", joinpath(indir,a,v.folder))[]) for a in conds) 
              for (m,v) in mpms)

    # B1 map
    b1_lowres = niread(glob("*B1map.nii", joinpath(indir,"sa","Results","Supplementary"))[])

    # interpolate B1 map to target (ni) space
    target = ni["R1"]["sa"]
    transNI = convertToMap(NIfTI.getaffine(target))
    transB1 = convertToMap(NIfTI.getaffine(b1_lowres))
    b1 = warp(b1_lowres, inv(transB1) ∘ transNI, axes(target), method=BSpline(Cubic()))

    # try and find similar position in scanner space between sessions
    # underlying assumption that participants placed in same position each time
    if ses == 1
        slice = Int(round(0.25size(target,slicedim)))
        posvec = zeros(3)
        posvec[slicedim] = slice
        global slicepos = transNI(posvec)
    else
        slice = Int(round(inv(transNI)(slicepos)[slicedim]))
    end

    # correct R1 for imperfect spoiling
    R1 = Dict(k => correctR1forimperfectspoiling.(ni["R1"][k], b1*1e-2, [a], [b]) for k in keys(ni["R1"]))

    # brain mask
    (gm, wm, csf)  = (niread(glob("c$(n)*PDw_OLSfit_TEzero.nii", joinpath(indir,"sa","Results","Supplementary"))[]) for n in 1:3)
    brain = (gm .+ wm .+ csf) .> 0.0 # mask for visualisation
    histmask = wm .> 0.99 # mask for histograms

    # restrict analysis to B1 in b1lims
    histmask .&= (b1lims[1] .≤ b1 .≤ b1lims[2])

    global diff = reldiff.(R1["sa"], R1["nosa"])

    # plot differences
    global p[sub,ses] = Dict()
    global counts = Dict()
    global qrs = Dict()
    b1local = b1[histmask]
    for comppair in (("sa","nosa"),("sa","exact"),("nosa","exact"))
        local diff = reldiff.(R1[first(comppair)], R1[last(comppair)])

        h1 = histogram2d(b1local, diff[histmask], bins=(range(b1lims...,length=100),range(difflims["R1"]...,length=100)), colorbar=:none, background_colour=:black)
        xlims!(h1, b1lims)
        xlabel!(h1,L"$f_\mathrm{t}$ (%)")
        ylabel!(h1, join(["relative R1", "difference (%)"],'\n'))
        global p[sub,ses][comppair] = plot(h1, left_margin=10Plots.pt, background_colour=:black)

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
    labelpos = Dict(("R1","nosa") => (:top,    :right),
                    ("R1","sa")   => (:top, :right))
    p_med = plot()
    for (b,st,idx) in ((b1vals[1:end-1],:steppost,1:length(b1vals)-1), (last(b1vals,2),:steppre, length(b1vals) .- [2,1]))
        plot!(p_med, b, qrs["nosa","exact"][idx,1], fillrange=qrs["nosa","exact"][idx,2], 
            seriescolor=:blue, label=false, linewidth=0, seriestype=st, alpha=0.25)
        plot!(p_med, b, qrs["sa","exact"][idx,1], fillrange=qrs["sa","exact"][idx,2],
            seriescolor=:red, label=false, linewidth=0, seriestype=st, alpha=0.25)
        plot!(p_med, b, hcat((counts[s,"exact"][idx] for s in ("nosa","sa"))...), 
                            ylims=difflims["R1"], ylabel="relative R1 error (%)", xticks=(50:25:150), 
                            seriescolor=[:blue :red], label=false, linewidth=2, seriestype=st)
    end
    annotate!(b1vals[end], last(skipnan(counts["nosa","exact"])), ("new method",  labelpos["R1","nosa"]..., :black))
    annotate!(b1vals[end], last(skipnan(counts["sa","exact"])),   ("small angle method", labelpos["R1","sa"]...,   :black))
    xlabel!(p_med,L"$f_\mathrm{t}$ (%)")

    f_med = plot(p_med, dpi=300, size=(600,310), plot_title="A: in vivo experiment")
    savefig(f_med, joinpath(outdir,"invivoimpsp_median_sub-$(sub)_ses-$(ses).png"))

    # example images
    vismask = erode(dilate(selectdim(brain[:,:,:],slicedim,slice), r=25), r=15) # fill holes in brain mask
    i1 = hm(R1["nosa"], vismask, slice, r1lims, "A: R1 map", L"s$^{-1}$", ni["R1"]["sa"])
    i3 = hm(abs.(diff), vismask, slice, reverse(.-(difflims["R1"])), "C: abs. relative R1 difference", "%", ni["R1"]["sa"])
    i5 = hm(b1, vismask, slice, b1lims, L"D: $f_\mathrm{t}$ map", "%", ni["R1"]["sa"])
    l = @layout [a b; c d]
    exim = plot(i1, plot!(p[sub,ses]["sa","nosa"],title=[L"B: $f_\mathrm{t}$ dependence of differences" ""],titlelocation=:left), i3, i5, layout=l, dpi=300, size=(800,800), background_colour=:black)
    savefig(exim, joinpath(outdir,"invivoimpsp_sub-$(sub)_ses-$(ses).png"))
end


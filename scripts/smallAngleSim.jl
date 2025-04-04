using Pkg
Pkg.activate(@__DIR__)

# add MPMtools
include(joinpath(@__DIR__, "external", "MPMtools.jl", "src", "MPMtools.jl"))
using .MPMtools.MRIutils
using .MPMtools.MRImaps
using .MPMtools.MRItypes

using Plots
using LaTeXStrings

# Test MPM pipeline using synthetic data
names = ["A: in vivo protocol simulation", "B: postmortem protocol simulation"]

A      = 1.0
R1     = (0.82, 2.0) # from in vivo WM 7T value in Rooney, et al. (2007), and postmortem value from Lipp, et al. (2023)
B1     = (range(0.45, 1.35, length=100), range(0.6, 1.1, length=100))

TR     = (31.6, 70) .* 1e-3
faPDw  = (5, 18)
faT1w  = (27, 84)

Adifflim  = ((-0.5,2.5), ( -10, 50))
R1difflim = ((-8,  2),   (-60, 15))
for SNR in (18, 51, Inf) # in vivo, postmortem, no noise
    for N in (1, 2)
        # use novel method
        MRItypes.half_angle_tan(α) = 2tan(0.5α)
        PDw = MRIutils.ernstd.(B1[N].*faPDw[N], TR[N], R1[N], PD=A)
        T1w = MRIutils.ernstd.(B1[N].*faT1w[N], TR[N], R1[N], PD=A)

        A_est  = MRImaps.calculateA.(PDw, T1w)
        R1_est = MRImaps.calculateR1.(PDw, T1w)
        
        # compute first order error propagation
        σ = MRIutils.ernstd.(faPDw[N], TR[N], R1[N], PD=A).signal/SNR
        dA = MRIutils.dPD.(PDw,T1w,σ,σ)
        dR1 = MRIutils.dR1.(PDw,T1w,σ,σ)

        # use small angle approximation
        MRItypes.half_angle_tan(α) = α
        PDwFA = MRIutils.ernstd.(B1[N].*faPDw[N], TR[N], R1[N], PD=A)
        T1wFA = MRIutils.ernstd.(B1[N].*faT1w[N], TR[N], R1[N], PD=A)

        A_FA_est  = MRImaps.calculateA.(PDwFA, T1wFA)
        R1_FA_est = MRImaps.calculateR1.(PDwFA, T1wFA)

        # compute first order error propagation
        dAFA = MRIutils.dPD.(PDwFA,T1wFA,σ,σ)
        dR1FA = MRIutils.dR1.(PDwFA,T1wFA,σ,σ)

        local p1 = plot(100*B1[N], 100*(R1_est .- R1[N])./R1[N], label="", seriescolor=:blue, linewidth=2, ylims=R1difflim[N])
        plot!(100*B1[N], 100*(R1_est .- R1[N] .- dR1)./R1[N], fillrange=100*(R1_est .- R1[N] .+ dR1)./R1[N], 
                    seriescolor=:blue, label=false, linewidth=0, seriestype=:steppre, alpha=0.25)
        annotate!(100*(B1[N][end]), 100*(R1_est[end] - R1[N])/R1[N] - 0.01*-(ylims()...), ("new method", :bottom, :right, :black))
        xticks!(50:25:150)

        plot!(100*B1[N], 100*(R1_FA_est .- R1[N])./R1[N], label="", seriescolor=:red, linewidth=2, ylims=R1difflim[N])
        plot!(100*B1[N], 100*(R1_FA_est .- R1[N] .- dR1FA)./R1[N], fillrange=100*(R1_FA_est .- R1[N] .+ dR1FA)./R1[N], 
                    seriescolor=:red, label=false, linewidth=0, seriestype=:steppost, alpha=0.25)
        annotate!(100*(B1[N][end]), 100*(R1_FA_est[end] - R1[N])/R1[N] + 0.02*-(ylims()...), ("small angle method", :top, :right, :black))
        xticks!(50:25:150)

        # fudge factor for increase in axis needed to show errors
        ylims!((ylims() .+ 400 .* [-1,1]/SNR)...)

        ylabel!("relative R1 error (%)")

        local p2 = plot(100*B1[N], 100*(A_est .- A)./A, label="", seriescolor=:blue, linewidth=2, ylims=Adifflim[N])
        plot!(100*B1[N], 100*(A_est .- A .- dA)./A, fillrange=100*(A_est .- A .+ dA)./A, 
                    seriescolor=:blue, label=false, linewidth=0, seriestype=:steppre, alpha=0.25)
        annotate!(100*(B1[N][end]), 100*(A_est[end] - A)/A + 0.02*-(ylims()...), ("new method", :top, :right, :black))
        xticks!(50:25:150)

        plot!(100*B1[N], 100*(A_FA_est .- A)./A, label="", seriescolor=:red, linewidth=2, ylims=Adifflim[N])
        plot!(100*B1[N], 100*(A_FA_est .- A .- dAFA)./A, fillrange=100*(A_FA_est .- A .+ dAFA)./A, 
                    seriescolor=:red, label=false, linewidth=0, seriestype=:steppre, alpha=0.25)
        annotate!(100*(B1[N][end]), 100*(A_FA_est[end] - A)/A - 0.01*-(ylims()...), ("small angle method", :bottom, :right, :black))
        xticks!(50:25:150)

        # fudge factor for increase in axis needed to show errors
        ylims!((ylims() .+ 200 .* [-1,1]/SNR)...)

        xlabel!(L"$f_\mathrm{t}$ (%)")
        ylabel!(L"relative $A$ error (%)")

        if N==1
            global p = plot(p1, p2, layout = (2,1), title=[names[N] " "])
        else
            global p = hcat(p,plot(p1, p2, layout = (2,1), title=[names[N] " "]))
        end
    end

    pl = plot(p[1],p[2], layout=(1,2), dpi=300, size=(1200,600), margin=5Plots.mm, plot_title=" ")
    savefig(pl, joinpath(dirname(@__DIR__),"figures","simulation_SNR$(SNR).png"))
end
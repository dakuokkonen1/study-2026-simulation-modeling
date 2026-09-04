module Experiments
using DrWatson, CSV, DataFrames, Statistics, Plots
using project.SIRDES
default(left_margin=6*Plots.mm,bottom_margin=5*Plots.mm,
        top_margin=4*Plots.mm,right_margin=4*Plots.mm)
export simulate, save_table, figure_path, summarize, sample_step, BASE_U, BASE_P,
       plot_states, trajectory_metrics, PROJECT_ROOT

const PROJECT_ROOT = normpath(joinpath(@__DIR__, ".."))
const BASE_U = [990,10,0]
const BASE_P = [.05,10.0,.25]
safevalue(x) = replace(string(x), "."=>"p", "-"=>"m")

function simulate(; family="base", u0=BASE_U, p=BASE_P, T=40.0, seed=1234,
                  fixed_duration=false, sigma=Inf, mu=0.0, birth_rate=0.0,
                  vaccine_time=nothing, vaccine_fraction=0.0, save=true)
    m = MakeSIRModel(u0,p;seed,fixed_duration,sigma,mu,birth_rate)
    activate(m;vaccine_time,vaccine_fraction)
    sir_run(m,T)
    settings = (;N=sum(u0),I0=u0[2],beta=p[1],c=p[2],gamma=p[3],T,seed,
                fixed=fixed_duration,sigma,mu,birth_rate,
                vaccine_time=isnothing(vaccine_time) ? -1.0 : Float64(vaccine_time),
                vaccine_fraction)
    file = family * "_" * join(["$(k)=$(safevalue(v))" for (k,v) in pairs(settings)],"_") * ".csv"
    # Complete parameter names exceed some filesystems' 255-byte component limit.
    file = replace(file,"vaccine_fraction"=>"vf","vaccine_time"=>"vt","birth_rate"=>"br")
    path = joinpath(PROJECT_ROOT,"data","sims",file)
    if save
        mkpath(dirname(path)); CSV.write(path,out(m))
    end
    row = merge((;family),settings,metrics(m),(;csv=relpath(path,PROJECT_ROOT)))
    m,row
end

function save_table(name,table)
    path=joinpath(PROJECT_ROOT,"data","analysis",name*".csv")
    mkpath(dirname(path)); CSV.write(path,table); table
end

function figure_path(name)
    folder=normpath(joinpath(PROJECT_ROOT,"..","image"))
    mkpath(folder); joinpath(folder,name*".png")
end

function summarize(df,groups)
    combine(groupby(df,groups),nrow=>:replicates,
        :peak_I=>mean=>:peak_mean,:peak_I=>std=>:peak_sd,
        :peak_time=>mean=>:peak_time_mean,
        :R_fraction=>mean=>:R_fraction_mean,
        :ever_infected=>mean=>:infected_mean,:I_T=>mean=>:I_T_mean,
        :extinct=>mean=>:extinction_fraction)
end

function sample_step(df,grid,column=:I)
    [df[max(1,searchsortedlast(df.t,t)),column] for t in grid]
end

function plot_states(df;title="SIR DES", exposed=false)
    fig=plot(df.t,df.S;label="S",color=:royalblue,lw=2,
        xlabel="Time",ylabel="Individuals",title,size=(1000,600),legend=:right)
    exposed && plot!(fig,df.t,df.E;label="E",color=:orange,lw=2)
    plot!(fig,df.t,df.I;label="I",color=:firebrick,lw=2)
    plot!(fig,df.t,df.R;label="R",color=:seagreen,lw=2)
    fig
end

function trajectory_metrics(df)
    k=argmax(df.I)
    N0=df.S[1]+df.E[1]+df.I[1]+df.R[1]
    (;peak_I=df.I[k],peak_time=df.t[k],S_T=last(df.S),E_T=last(df.E),
      I_T=last(df.I),R_T=last(df.R),R_fraction=last(df.R)/N0,
      ever_infected=df.I[1]+last(df.infections))
end
end

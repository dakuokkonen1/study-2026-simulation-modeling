using DrWatson
@quickactivate "project"
using Test, project.SIRDES, CSV, DataFrames, Statistics
include(srcdir("experiments.jl"))
using .Experiments

function check_model(m)
    df=out(m)
    @test issorted(df.t)
    @test all(Matrix(df[:,[:S,:E,:I,:R]]) .>= 0)
    @test all(df.S+df.E+df.I+df.R .== sum(m.initial) .+ df.births .- df.deaths)
    @test m.counts == [count(p->p.status==s,m.allIndividuals) for s in (:S,:E,:I,:R)]
    @test all(m.positions[p.id]==i for (i,p) in enumerate(m.allIndividuals))
    @test length(m.positions)==length(m.allIndividuals)
    @test last(df.infections)==count(==("infection"),df.event)
    @test last(df.births)==count(==("birth"),df.event)
    @test last(df.deaths)==count(==("death"),df.event)
    @test last(df.vaccinated)==count(==("vaccination"),df.event)
    # No dead or recovered agent can acquire a later clinical event.
    for group in groupby(filter(r->r.person>0,df),:person)
        ev=group.event
        death=findfirst(==("death"),ev)
        @test isnothing(death) || death==length(ev)
        vaccination=findfirst(==("vaccination"),ev)
        @test isnothing(vaccination) || all(==("death"),ev[vaccination+1:end])
    end
end

@testset "Validation and lifecycle" begin
    @test_throws ArgumentError MakeSIRModel([0,0,0],BASE_P)
    @test_throws ArgumentError MakeSIRModel([-1,1,0],BASE_P)
    @test_throws ArgumentError MakeSIRModel([1,0],BASE_P)
    @test_throws ArgumentError MakeSIRModel([10,1,0],[1.1,1,.2])
    @test_throws ArgumentError MakeSIRModel([10,1,0],[.1,-1,.2])
    @test_throws ArgumentError MakeSIRModel([10,1,0],[.1,1,0])
    @test_throws ArgumentError MakeSIRModel([10,1,0],BASE_P;mu=-1)
    @test_throws ArgumentError MakeSIRModel([10,1,0],BASE_P;sigma=0)
    m=MakeSIRModel([1,0,0],BASE_P)
    @test_throws ArgumentError sir_run(m,1)
    activate(m)
    @test_throws ArgumentError activate(m)
    sir_run(m,10)
    @test m.counts==[1,0,0,0]
    @test_throws ArgumentError sir_run(m,10)
    check_model(m)
end

@testset "Baseline, reproducibility and zero transmission" begin
    a,_=simulate(save=false)
    b,_=simulate(save=false)
    @test out(a)==out(b)
    @test metrics(a).peak_I==174
    @test metrics(a).S_T==226
    @test metrics(a).I_T==23
    @test metrics(a).R_T==751
    check_model(a)
    for p in ([0.,10.,.25],[.05,0.,.25])
        m,_=simulate(p=p,save=false)
        @test m.infections==0
        @test last(m.Sa)==990
        check_model(m)
    end
end

@testset "Fixed duration, vaccination and independent deaths" begin
    m,_=simulate(fixed_duration=true,save=false)
    @test all(isapprox.(m.disease_durations,4.;atol=1e-10))
    check_model(m)
    vaccinated,_=simulate(vaccine_time=0.,vaccine_fraction=1.,save=false)
    @test vaccinated.vaccinations==990
    @test vaccinated.infections==0
    @test last(vaccinated.Sa)==0
    check_model(vaccinated)
    baseline,_=simulate(save=false)
    placebo,_=simulate(vaccine_time=0.,vaccine_fraction=0.,save=false)
    @test out(baseline)==out(placebo)
    # Death need not wait for the deterministic 1000-day recovery.
    dying,_=simulate(u0=[0,100,0],p=[.05,10.,.001],mu=2.,fixed_duration=true,T=10.,save=false)
    @test dying.deaths==100
    @test isempty(dying.allIndividuals)
    @test count(==(:recovery),dying.events)==0
    check_model(dying)
    for seed in 1:3
        demographic,_=simulate(u0=[90,10,0],mu=.1,birth_rate=10.,T=40.,seed=seed,save=false)
        @test demographic.births>0 && demographic.deaths>0
        check_model(demographic)
    end
end

@testset "SEIR and event order" begin
    m,_=simulate(sigma=.5,save=false)
    @test maximum(m.Ea)>0
    df=out(m)
    for group in groupby(filter(r->r.person>0,df),:person)
        ev=group.event
        infection=findfirst(==("infection"),ev)
        infectious=findfirst(==("infectious"),ev)
        @test isnothing(infectious) || (!isnothing(infection) && infectious>infection)
        if !isnothing(infectious)
            @test group.t[infectious]>group.t[infection]
        end
    end
    check_model(m)
end

@testset "Mean-field numerical checks" begin
    a=ode_sir(BASE_U,BASE_P,40.;dt=.02)
    b=ode_sir(BASE_U,BASE_P,40.;dt=.01)
    @test maximum(abs.(Matrix(a[:,2:4])-Matrix(b[1:2:end,2:4])))<1e-4
    @test maximum(abs.(b.S+b.I+b.R .-1000))<1e-8
    @test all(Matrix(b[:,2:4]) .>=0)
    # Analytic SIR invariant with k=beta*c/(N-1).
    k=BASE_P[1]*BASE_P[2]/999
    invariant=b.I+b.S-(BASE_P[3]/k).*log.(b.S)
    @test maximum(abs.(invariant .- invariant[1]))<1e-7
    @test_throws ArgumentError ode_sir(BASE_U,BASE_P,40.;dt=0.)
end

@testset "Saved results" begin
    base=CSV.read(datadir("analysis","baseline.csv"),DataFrame)
    df=CSV.read(projectdir(base.csv[1]),DataFrame)
    for key in keys(trajectory_metrics(df))
        @test isapprox(trajectory_metrics(df)[key],base[1,key])
    end
    for (name,count) in [("sensitivity-runs",270),("duration-runs",40),
        ("demography-runs",15),("vaccination-runs",100),("seir-runs",40),("ode-comparison-runs",20)]
        index=CSV.read(datadir("analysis",name*".csv"),DataFrame)
        @test nrow(index)==count
        @test length(unique(index.csv))==count
        for row in eachrow(index)
            data=CSV.read(projectdir(row.csv),DataFrame)
            @test last(data.t)==row.T
            @test all(data.S+data.E+data.I+data.R .== row.N .+ data.births .- data.deaths)
            @test maximum(data.I)==row.peak_I
            @test isapprox(data.t[argmax(data.I)],row.peak_time)
        end
    end
    benchmark=CSV.read(datadir("analysis","benchmark-summary.csv"),DataFrame)
    @test benchmark.N==[1000,10000]
    @test benchmark.samples==[10,10]
    @test all(benchmark.median_ms .>0)
end

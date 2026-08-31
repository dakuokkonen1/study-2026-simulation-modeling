using DrWatson, CSV, DataFrames, Plots, Statistics, Distributions

const IMAGE_DIR = normpath(projectdir("..", "image"))
mkpath(IMAGE_DIR)
mkpath(datadir())
default(size=(1100, 650), dpi=120, fontfamily="DejaVu Sans", titlefontsize=14,
    guidefontsize=12, tickfontsize=10, legendfontsize=10, linewidth=2,
    margin=6Plots.mm, legend=:best)
imagepath(name) = joinpath(IMAGE_DIR, name)
save_table(name, table) = CSV.write(datadir(name), table)

function sampled_queue(events, end_time; points=1001)
    times = collect(range(0, end_time; length=points))
    indices = searchsortedlast.(Ref(events.time), times)
    DataFrame(time=times, queue=events.queue[indices], busy=events.busy[indices])
end

function queue_plot(events; title="M/M/c: event history")
    p1 = plot(events.time, events.queue; seriestype=:steppost, color=:royalblue,
        ylabel="Customers waiting", label=false, title=title)
    p2 = plot(events.time, events.busy; seriestype=:steppost, color=:seagreen,
        xlabel="Time", ylabel="Busy servers", label=false)
    plot(p1, p2; layout=(2,1), size=(1100,720))
end

function customer_timeline(clients)
    p = plot(; xlabel="Time", ylabel="Customer", title="Arrival, waiting and service",
        yticks=clients.id, ylim=(0,nrow(clients)+1), legend=:topleft)
    for row in eachrow(clients)
        plot!(p, [row.arrival,row.start], [row.id,row.id]; linewidth=7,
            color=:darkorange, label=row.id==1 ? "Waiting" : false)
        plot!(p, [row.start,row.departure], [row.id,row.id]; linewidth=7,
            color=:royalblue, label=row.id==1 ? "Service" : false)
        scatter!(p, [row.arrival], [row.id]; color=:black, markersize=3,
            label=row.id==1 ? "Arrival" : false)
    end
    p
end

function repair_plot(events, N; title="Ross model: first run")
    p1 = plot(events.time, events.healthy; seriestype=:steppost, color=:royalblue,
        ylabel="Healthy machines", label=false, title=title)
    hline!(p1, [N]; color=:firebrick, linestyle=:dash, label="N working required")
    p2 = plot(events.time, events.spares; seriestype=:steppost, color=:seagreen,
        ylabel="Cold spares", label=false)
    p3 = plot(events.time, events.queue; seriestype=:steppost, color=:darkorange,
        ylabel="Repair facility", label="Queue", xlabel="Time (h)")
    plot!(p3, events.time, events.busy; seriestype=:steppost, color=:purple, label="Busy repairers")
    plot(p1,p2,p3; layout=(3,1), size=(1100,900))
end

function mean_interval(values)
    n=length(values)
    n > 1 || throw(ArgumentError("at least two independent observations required"))
    estimate = mean(values)
    se = std(values)/sqrt(n)
    halfwidth = quantile(TDist(n-1), .975)*se
    (mean=estimate, se=se, ci_low=max(0.0,estimate-halfwidth), ci_high=estimate+halfwidth)
end

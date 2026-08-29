"""Правая часть уравнения экспоненциального роста `du/dt = αu`."""
function exponential_growth!(du, u, p, t)
    alpha = p isa NamedTuple ? p.alpha : p
    du[1] = alpha * u[1]
    return nothing
end

"""Аналитическое решение модели в момент времени `t`."""
analytic_solution(u0, alpha, t) = u0 * exp(alpha * t)

"""Время удвоения при положительной скорости роста."""
function doubling_time(alpha)
    alpha > 0 || throw(ArgumentError("alpha must be positive"))
    return log(2) / alpha
end

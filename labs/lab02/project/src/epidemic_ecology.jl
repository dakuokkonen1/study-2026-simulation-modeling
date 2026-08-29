module EpidemicEcology

export sir!, lotka_volterra!, basic_reproduction_number,
       effective_reproduction_number, lotka_equilibrium, lotka_invariant

function sir!(du, u, p, t)
    susceptible, infected, recovered = u
    beta, contacts, gamma = p
    population = susceptible + infected + recovered
    incidence = beta * contacts * susceptible * infected / population
    du[1] = -incidence
    du[2] = incidence - gamma * infected
    du[3] = gamma * infected
    return nothing
end

basic_reproduction_number(beta, contacts, gamma) = beta * contacts / gamma

effective_reproduction_number(susceptible, population, reproduction_number) =
    reproduction_number * susceptible / population

function lotka_volterra!(du, u, p, t)
    prey, predator = u
    alpha, beta, delta, gamma = p
    du[1] = alpha * prey - beta * prey * predator
    du[2] = delta * prey * predator - gamma * predator
    return nothing
end

lotka_equilibrium(alpha, beta, delta, gamma) = (gamma / delta, alpha / beta)

function lotka_invariant(prey, predator, alpha, beta, delta, gamma)
    return delta * prey - gamma * log(prey) + beta * predator - alpha * log(predator)
end

end

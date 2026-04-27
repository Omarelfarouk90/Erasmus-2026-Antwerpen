# ============================================================
# TP: Introduction to Metaheuristics with Julia on the TSP
# Teacher version (complete solutions)
# ============================================================

using Random
using LinearAlgebra
using Plots

# ------------------------------------------------------------
# Visualization utilities (provided to students)
# ------------------------------------------------------------

function plot_tour(cities, sol; title_str="Tour", show_order=true)
    x = cities[:, 1]
    y = cities[:, 2]
    closed = vcat(sol, sol[1])

    p = plot(x[closed], y[closed],
        seriestype = :path,
        marker = :circle,
        legend = false,
        aspect_ratio = :equal,
        title = title_str,
        xlabel = "x",
        ylabel = "y")

    if show_order
        for (k, city) in enumerate(sol)
            annotate!(x[city], y[city]-2, text(string(city), 8, :black))
        end
    end
    return p
end

function compare_tours(cities, sol1, sol2; labels=("Before", "After"))
    p1 = plot_tour(cities, sol1, title_str=labels[1])
    p2 = plot_tour(cities, sol2, title_str=labels[2])
    return plot(p1, p2, layout=(1, 2), size=(1000, 400))
end

# ------------------------------------------------------------
# Exercise 0.1 — Generate cities
# ------------------------------------------------------------

function generate_cities(n)
    return rand(0:100,n, 2)
end

# Generate a fixed set of cities for testing
CITIES = generate_cities(15)

# ------------------------------------------------------------
# Exercise 0.2 — Distance matrix
# ------------------------------------------------------------

function compute_distance_matrix(cities)
    n = size(cities, 1)
    D = zeros(n, n)
    for i in 1:n
        for j in 1:n
            D[i, j] = norm(cities[i, :] .- cities[j, :])
        end
    end
    return D
end

# Compute the distance matrix for the generated cities
D = compute_distance_matrix(CITIES)

# ------------------------------------------------------------
# Exercise 1.1 — Random solution
# ------------------------------------------------------------

function random_solution(n)
    return shuffle(1:n)
    # return randperm(n) # alternative using built-in function
end

# Apply random solution to the generated cities
sol = random_solution(size(CITIES, 1))

# ------------------------------------------------------------
# Exercise 1.2 — Cost function
# ------------------------------------------------------------

function tour_cost(sol, D)
    n = length(sol)
    cost = 0.0
    for i in 1:n-1
        cost += D[sol[i], sol[i + 1]]
    end
    cost += D[sol[n], sol[1]]
    return cost
end

# Calculate cost of the random tour
cost = round(tour_cost(sol, D), digits=2)
println("Cost of random tour: ", cost)

# Visualize tour
plot_tour(CITIES, sol, title_str="Random tour: $cost")

# ------------------------------------------------------------
# Exercise 1.3 — Nearest neighbor solution
# ------------------------------------------------------------

function nearest_neighbor_solution(D; start=1)
    n = size(D, 1) # number of cities
    unvisited = collect(1:n) # list of unvisited cities

    current = start # current city
    sol = [current] # tour being constructed
    deleteat!(unvisited, findfirst(==(current), unvisited)) # mark current city as visited
    
    while !isempty(unvisited)
        # find nearest unvisited city
        distances = [D[current, j] for j in unvisited] # distances to unvisited cities
        idx = argmin(distances) # index of nearest unvisited city in the unvisited list
        
        next_city = unvisited[idx] # actual city index of the nearest unvisited city
        push!(sol, next_city) # add next city to the tour
        
        deleteat!(unvisited, idx) # mark next city as visited
        current = next_city # move to the next city
    end
    
    return sol
end

# Calculate nearest neighbor solution and its cost
nn_sol = nearest_neighbor_solution(D)

nn_cost = round(tour_cost(nn_sol, D), digits=2)

# Compare Random and nearest neighbor tours side by side
compare_tours(CITIES, sol, nn_sol, labels=("Random tour: $cost", 
              "Nearest neighbor tour: $nn_cost"))

# ------------------------------------------------------------
# Exercise 2.1 — Swap move
# ------------------------------------------------------------

function swap_move(sol, i, j)
    new_sol = copy(sol)
    new_sol[i], new_sol[j] = new_sol[j], new_sol[i]
    return new_sol
end

# Apply swap move to the random solution
println("Original solution: ", sol)
new_sol = swap_move(sol, 1, 2)
println("New solution after swap: ", new_sol)
new_cost = round(tour_cost(new_sol, D), digits=2)
println("Cost after swap move: ", new_cost)

# Visualize the effect of the swap move
compare_tours(CITIES, sol, new_sol, labels=("Before swap: $cost", "After swap: $new_cost"))

# ------------------------------------------------------------
# Exercise 2.2 — Random swap neighbor
# ------------------------------------------------------------

function random_swap_neighbor(sol)
    n = length(sol)
    i, j = rand(1:n, 2)
    return swap_move(sol, i, j)
end

# Example of generating a random swap neighbor
println("Current solution: ", sol)
random_neighbor = random_swap_neighbor(sol)
println("Random swap neighbor: ", random_neighbor) 
neighbor_cost = round(tour_cost(random_neighbor, D), digits=2)
println("Random swap neighbor: ", random_neighbor)
println("Cost of random swap neighbor: ", neighbor_cost)

# Visualize the random swap neighbor
compare_tours(CITIES, sol, random_neighbor, labels=("Current solution: $cost", "Random swap neighbor: $neighbor_cost"))

# ------------------------------------------------------------
# Exercise 2.3 — Insert move
# ------------------------------------------------------------

function insert_move(sol, i, j)
    new_sol = copy(sol)
    city = new_sol[i]
    deleteat!(new_sol, i)
    insert!(new_sol, j, city)
    return new_sol
end

# Example of generating an insert move
println("Current solution: ", sol)
inserted_sol = insert_move(sol, 2, 4)
println("Solution after insert move: ", inserted_sol)
inserted_cost = round(tour_cost(inserted_sol, D), digits=2)
println("Cost after insert move: ", inserted_cost)

# Visualize the insert move
compare_tours(CITIES, sol, inserted_sol, labels=("Current solution: $cost", "After insert move: $inserted_cost"))

# ------------------------------------------------------------
# Exercise 2.4 — 2-opt move
# ------------------------------------------------------------

function two_opt_move(sol, i, j)
    new_sol = copy(sol)
    new_sol[i:j] = reverse(new_sol[i:j])
    return new_sol
end

# Example of generating a 2-opt move
println("Current solution: ", sol)
two_opt_sol = two_opt_move(sol, 2, 5)
println("Solution after 2-opt move: ", two_opt_sol)
two_opt_cost = round(tour_cost(two_opt_sol, D), digits=2)
println("Cost after 2-opt move: ", two_opt_cost)

# Visualize the 2-opt move
compare_tours(CITIES, sol, two_opt_sol, labels=("Current solution: $cost", "After 2-opt move: $two_opt_cost"))


# ------------------------------------------------------------
# Helper functions for best neighbors
# ------------------------------------------------------------

function best_swap_neighbor(sol, D)
    current_cost = tour_cost(sol, D)
    best_sol = copy(sol)
    best_cost = current_cost
    improved = false
    n = length(sol)

    for i in 1:n-1
        for j in i+1:n
            candidate = swap_move(sol, i, j)
            candidate_cost = tour_cost(candidate, D)
            if candidate_cost < best_cost
                best_sol = candidate
                best_cost = candidate_cost
                improved = true
            end
        end
    end

    return best_sol, best_cost, improved
end

# Apply best swap neighbor to the random solution
best_swap_sol, best_swap_cost, improved = best_swap_neighbor(sol, D)
println("Best swap neighbor: ", best_swap_sol)
println("Cost of best swap neighbor: ", round(best_swap_cost, digits=2))
println("Improvement found: ", improved)

# Visualize the best swap neighbor
compare_tours(CITIES, sol, best_swap_sol, labels=("Current solution: $cost", "Best swap neighbor: $(round(best_swap_cost, digits=2))"))

function best_insert_neighbor(sol, D)
    current_cost = tour_cost(sol, D)
    best_sol = copy(sol)
    best_cost = current_cost
    improved = false
    n = length(sol)

    for i in 1:n
        for j in 1:n
            if i == j
                continue
            end
            candidate = insert_move(sol, i, j)
            candidate_cost = tour_cost(candidate, D)
            if candidate_cost < best_cost
                best_sol = candidate
                best_cost = candidate_cost
                improved = true
            end
        end
    end

    return best_sol, best_cost, improved
end

function best_two_opt_neighbor(sol, D)
    current_cost = tour_cost(sol, D)
    best_sol = copy(sol)
    best_cost = current_cost
    improved = false
    n = length(sol)

    for i in 1:n-1
        for j in i+1:n
            candidate = two_opt_move(sol, i, j)
            candidate_cost = tour_cost(candidate, D)
            if candidate_cost < best_cost
                best_sol = candidate
                best_cost = candidate_cost
                improved = true
            end
        end
    end

    return best_sol, best_cost, improved
end

# ------------------------------------------------------------
# Exercise 3.2 — Local search (descent)
# ------------------------------------------------------------

function local_search(sol, D; max_iter=1000)
    current = copy(sol)
    current_cost = tour_cost(current, D)
    history = [current_cost]

    for _ in 1:max_iter
        neighbor, neighbor_cost, improved = best_swap_neighbor(current, D)
        if !improved
            break
        end
        current = neighbor
        current_cost = neighbor_cost
        push!(history, current_cost)
    end

    return current, current_cost, history
end

# Apply local search to the random solution
local_sol, local_cost, history = local_search(sol, D)
println("Local search solution: ", local_sol)
println("Cost of local search solution: ", round(local_cost, digits=2))

# Visualize the local search solution
compare_tours(CITIES, sol, local_sol, labels=("Current solution: $cost", "Local search solution: $(round(local_cost, digits=2))"))

# Plot the cost history of local search
plot(history, title="Local Search Cost History", xlabel="Iteration", ylabel="Cost", legend=false)

# ------------------------------------------------------------
# Exercise 4.1 — Acceptance rule
# ------------------------------------------------------------

function accept_move(delta, T)
    if delta < 0
        return true
    else
        return rand() < exp(-delta / T)
    end
end

# ------------------------------------------------------------
# Exercise 4.2 — Simulated annealing
# ------------------------------------------------------------

function simulated_annealing(sol, D; T0=1.0, alpha=0.995, max_iter=10_000)
    current = copy(sol)
    current_cost = tour_cost(current, D)
    best = copy(current)
    best_cost = current_cost
    T = T0
    history = [best_cost]

    for _ in 1:max_iter
        neighbor = random_swap_neighbor(current)
        neighbor_cost = tour_cost(neighbor, D)
        delta = neighbor_cost - current_cost

        if accept_move(delta, T)
            current = neighbor
            current_cost = neighbor_cost
            if current_cost < best_cost
                best = copy(current)
                best_cost = current_cost
            end
        end

        push!(history, best_cost)
        T *= alpha
    end

    return best, best_cost, history
end

# Apply simulated annealing to the random solution
Random.seed!(4) # for reproducibility
sa_sol, sa_cost, sa_history = simulated_annealing(sol, D; T0=1.0, alpha=0.99, max_iter=200)
println("Simulated annealing solution: ", sa_sol)
println("Cost of simulated annealing solution: ", round(sa_cost, digits=2))

# Visualize the simulated annealing solution
compare_tours(CITIES, sol, sa_sol, labels=("Current solution: $cost", "Simulated annealing solution: $(round(sa_cost, digits=2))"))

# Plot the cost history of simulated annealing
plot(sa_history, title="Simulated Annealing Cost History", xlabel="Iteration", ylabel="Cost", legend=false)

# ------------------------------------------------------------
# Exercise 5.1 — Shake function for VND/VNS
# ------------------------------------------------------------

function shake(sol, k)
    n = length(sol)
    i, j = sort(rand(1:n, 2))
    if k == 1
        return swap_move(sol, i, j)
    elseif k == 2
        return insert_move(sol, i, j)
    elseif k == 3
        return two_opt_move(sol, i, j)
    else
        error("Unknown neighborhood k = $k")
    end
end

# ------------------------------------------------------------
# Exercise 5.2 — VND
# ------------------------------------------------------------

function VND(sol, D)
    current = copy(sol)
    current_cost = tour_cost(current, D)
    history = [current_cost]
    k = 1

    while k <= 3
        if k == 1
            candidate, candidate_cost, improved = best_swap_neighbor(current, D)
        elseif k == 2
            candidate, candidate_cost, improved = best_insert_neighbor(current, D)
        else
            candidate, candidate_cost, improved = best_two_opt_neighbor(current, D)
        end

        if improved
            current = candidate
            current_cost = candidate_cost
            push!(history, current_cost)
            k = 1
        else
            k += 1
        end
    end

    return current, current_cost, history
end

# Apply VND to the random solution
vnd_sol, vnd_cost, vnd_history = VND(sol, D)
println("VND solution: ", vnd_sol)
println("Cost of VND solution: ", round(vnd_cost, digits=2))    

# Visualize the VND solution
compare_tours(CITIES, sol, vnd_sol, labels=("Current solution: $cost", "VND solution: $(round(vnd_cost, digits=2))"))

# ------------------------------------------------------------
# Exercise 5.3 — VNS
# ------------------------------------------------------------

function VNS(sol, D; max_iter=200)
    current = copy(sol)
    current_cost = tour_cost(current, D)
    history = [current_cost]

    iter = 1
    while iter <= max_iter
        k = 1
        while k <= 3
            shaken = shake(current, k)
            local_sol, local_cost, _ = VND(shaken, D)
            if local_cost < current_cost
                current = local_sol
                current_cost = local_cost
                push!(history, current_cost)
                k = 1
            else
                k += 1
            end
        end
        iter += 1
    end

    return current, current_cost, history
end

# Apply VNS to the random solution
Random.seed!(5) # for reproducibility
vns_sol, vns_cost, vns_history = VNS(sol, D; max_iter=200)
println("VNS solution: ", vns_sol)
println("Cost of VNS solution: ", round(vns_cost, digits=2))    

# Visualize the VNS solution
compare_tours(CITIES, sol, vns_sol, labels=("Current solution: $cost", "VNS solution: $(round(vns_cost, digits=2))"))

# ------------------------------------------------------------
# Small demo instance (optional)
# ------------------------------------------------------------

function demo_instance(n=20; seed=1234)
    Random.seed!(seed)
    cities = generate_cities(n)
    D = compute_distance_matrix(cities)
    sol = random_solution(n)
    return cities, D, sol
end


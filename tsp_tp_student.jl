# ============================================================
# TP: Introduction to Metaheuristics with Julia on the TSP
# Student version
# ============================================================
# This file is intentionally progressive. Complete the TODOs
# section by section, then run the associated unit tests.
#
# Suggested workflow:
#   include("tsp_tp_student.jl")
#   include("tsp_tp_tests.jl")
#   runtests_tp(:ex01)
# ============================================================

using Random
using LinearAlgebra
using Plots

# ------------------------------------------------------------
# Visualization utilities (provided by the teacher)
# Students are NOT asked to implement this part.
# ------------------------------------------------------------

"""
    plot_tour(cities, sol; title_str="Tour", show_order=true)

Plot a TSP tour. `cities` is an n×2 matrix, `sol` is a permutation.
The tour is closed automatically by returning to the first city.
"""
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
            annotate!(x[city], y[city]-3, text(string(city), 8, :black))
        end
    end
    return p
end

"""
    compare_tours(cities, sol1, sol2; labels=("Before", "After"))

Display two tours side by side.
"""
function compare_tours(cities, sol1, sol2; labels=("Before", "After"))
    p1 = plot_tour(cities, sol1, title_str=labels[1])
    p2 = plot_tour(cities, sol2, title_str=labels[2])
    return plot(p1, p2, layout=(1, 2), size=(1000, 400))
end

# ------------------------------------------------------------
# Exercise 0.1 — Generate cities
# ------------------------------------------------------------

"""
    generate_cities(n)

Return an n×2 matrix of random points in [0,100]×[0,100].
"""
function generate_cities(n)
    # TODO
    return rand(0:100, n, 2)
end


# Generate a fixed set of cities for testing
CITIES = generate_cities(10)

# ------------------------------------------------------------
# Exercise 0.2 — Distance matrix
# ------------------------------------------------------------

"""
    compute_distance_matrix(cities)

Return the Euclidean distance matrix associated with `cities`.
"""
function compute_distance_matrix(cities)
    n = size(cities, 1)
    D = zeros(n, n)

    for i in 1:n 
        for j in 1:n
            D[i, j] = D[j, i] = norm(cities[i, :] - cities[j, :])
        end
    end

    return D
end

# Compute the distance matrix for the generated cities
D = compute_distance_matrix(CITIES)

# ------------------------------------------------------------
# Exercise 1.1 — Random solution
# ------------------------------------------------------------

"""
    random_solution(n)

Return a random permutation of 1:n.
"""
function random_solution(n)
    return randperm(n)
end

# Apply random solution to the generated cities
sol = random_solution(size(CITIES, 1))

# ------------------------------------------------------------
# Exercise 1.2 — Cost function
# ------------------------------------------------------------

"""
    tour_cost(sol, D)

Return the total length of the Hamiltonian cycle represented by `sol`.
"""
function tour_cost(sol, D)
    n = length(sol)
    cost = 0.0

    for i in 1:n
        cost += D[sol[i], sol[mod1(i + 1, n)]]
    end

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

"""
    nearest_neighbor_solution(D; start=1)

Return a tour constructed by the nearest neighbor heuristic.
"""
function nearest_neighbor_solution(D; start=1)
    n = size(D, 1) # number of cities
    unvisited = collect(1:n) # list of unvisited cities
    sol = Int[] # tour being constructed
    current = start # current city
    push!(sol, current) # add current city to the tour
    deleteat!(unvisited, findfirst(==(current), unvisited)) # mark current city as visited

    while !isempty(unvisited)
        nearest = unvisited[argmin(D[current, unvisited])]
        push!(sol, nearest)
        deleteat!(unvisited, findfirst(==(nearest), unvisited))
        current = nearest
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

"""
    swap_move(sol, i, j)

Return a NEW solution where positions i and j are swapped.
Do not modify the input solution.
"""
function swap_move(sol, i, j)
    new_sol = copy(sol)
    new_sol[i], new_sol[j] = new_sol[j], new_sol[i]
    return new_sol
end

# Apply swap move to the random solution on position 1 and 2
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

"""
    random_swap_neighbor(sol)

Pick two indices at random and return the swapped solution.
"""
function random_swap_neighbor(sol)
    n = length(sol)
    i, j = sort(randperm(n)[1:2])
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

"""
    insert_move(sol, i, j)

Remove the element at position i and insert it at position j.
Return a NEW solution.
"""
function insert_move(sol, i, j)
    new_sol = copy(sol)
    city = splice!(new_sol, i)
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

"""
    two_opt_move(sol, i, j)

Reverse the subsequence from i to j included.
Assume 1 <= i <= j <= n.
"""
function two_opt_move(sol, i, j)
    new_sol = copy(sol)
    reverse!(new_sol, i, j)
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
# Exercise 3.1 — Best neighbor with swap
# ------------------------------------------------------------

"""
    best_swap_neighbor(sol, D)

Explore all swap neighbors and return
    (best_sol, best_cost, improved)
where `improved` is true iff a better neighbor was found.
"""
function best_swap_neighbor(sol, D)
    current_cost = tour_cost(sol, D)
    best_sol = copy(sol)
    best_cost = current_cost
    improved = false
    n = length(sol)

    for i in 1:n-1, j in i+1:n
        neighbor = swap_move(sol, i, j)
        c = tour_cost(neighbor, D)
        if c < best_cost
            best_sol = neighbor
            best_cost = c
            improved = true
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

# - best_two_opt_neighbor 
function best_two_opt_neighbor(sol, D)
    current_cost = tour_cost(sol, D)
    best_sol = copy(sol)
    best_cost = current_cost
    improved = false
    n = length(sol)
    
    for i in 1:n
        for j in 1:n
            
            neighbor = two_opt_move(sol, i, j)
            c = tour_cost(neighbor, D)
            if c < best_cost
                best_sol = neighbor
                best_cost = c
                improved = true
            end
        end
    end
    
    return best_sol, best_cost, improved
end
# will be directly provided
best_two_opt_sol, best_two_opt_cost, improved = best_two_opt_neighbor(sol, D)
println("Best two-opt neighbor: ", best_two_opt_sol)
println("Cost of best two-opt neighbor: ", round(best_two_opt_cost, digits=2))
println("Improvement found: ", improved)

# Visualize the best two-opt neighbor
compare_tours(CITIES, sol, best_two_opt_sol, labels=("Current solution: $cost", "Best two-opt neighbor: $(round(best_two_opt_cost, digits=2))"))

# Other functions for 
# - best_insert_neighbor and 
# - best_two_opt_neighbor 
# will be directly provided
# Other functions for 
# - best_insert_neighbor 
function best_insert_neighbor(sol, D)
    current_cost = tour_cost(sol, D)
    best_sol = copy(sol)
    best_cost = current_cost
    improved = false
    n = length(sol)
    
    for i in 1:n
        for j in 1:n
            if i ≠ j
                neighbor = insert_move(sol, i, j)
                c = tour_cost(neighbor, D)
                if c < best_cost
                    best_sol = neighbor
                    best_cost = c
                    improved = true
                end
            end
        end
    end
    
    return best_sol, best_cost, improved
end

# Apply best swap neighbor to the random solution
#best_swap_sol, best_swap_cost, improved = best_insert_neighbor(sol, D)
best_insert_sol, best_insert_cost, improved = best_insert_neighbor(sol, D)
println("Best insert neighbor: ", best_insert_sol)
println("Cost of best insert neighbor: ", round(best_insert_cost, digits=2))
println("Improvement found: ", improved)

# Visualize the best insert neighbor
compare_tours(CITIES, sol, best_insert_sol, labels=("Current solution: $cost", "Best insert neighbor: $(round(best_insert_cost, digits=2))"))

# ------------------------------------------------------------
# Exercise 3.2 — Local search (descent)
# ------------------------------------------------------------

"""
    local_search(sol, D; max_iter=1000)

Repeatedly move to the best improving insert neighbor.
Return:
    (best_sol, best_cost, history)
where history contains the sequence of objective values.
"""
function local_search(sol, D; max_iter=1000)
    current = copy(sol)
    current_cost = tour_cost(current, D)
    history = [current_cost]

    for _ in 1:max_iter
        new_sol, new_cost, improved = best_insert_neighbor(current, D)
        if !improved
            break
        end
        current, current_cost = new_sol, new_cost
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
# Exercise 4.1 — Acceptance rule for simulated annealing
# ------------------------------------------------------------

"""
    accept_move(delta, T)

If delta < 0, accept.
Otherwise accept with probability exp(-delta / T).
"""
function accept_move(delta, T)
    return delta < 0 || rand() < exp(-delta / T)
end

# ------------------------------------------------------------
# Exercise 4.2 — Simulated annealing
# ------------------------------------------------------------

"""
    simulated_annealing(sol, D; T0=1.0, alpha=0.995, max_iter=10_000)

Use random swap neighbors and geometric cooling.
Return:
    (best_sol, best_cost, history, chistory)
where history stores the best cost seen so far and chistory stores the current cost at each iteration.

"""
function simulated_annealing(sol, D; T0=1.0, alpha=0.995, max_iter=10_000)
    current = copy(sol)
    current_cost = tour_cost(current, D)
    best = copy(current)
    best_cost = current_cost
    T = T0
    history = [best_cost]
    chistory = [current_cost]
    for _ in 1:max_iter
        neighbor = random_swap_neighbor(current)
        neighbor_cost = tour_cost(neighbor, D)
        push!(chistory, neighbor_cost)
        delta = neighbor_cost - current_cost
            
        if accept_move(delta, T)
            current, current_cost = neighbor, neighbor_cost
            if current_cost < best_cost
                best, best_cost = copy(current), current_cost
            end
        end
        
        
        push!(history, best_cost)
        T *= alpha
        
    end

    return best, best_cost, history, chistory
end

# Apply simulated annealing to the random solution
Random.seed!(4) # for reproducibility
sa_sol, sa_cost, sa_history, sa_chistory = simulated_annealing(sol, D; T0=1.0, alpha=0.99, max_iter=200)
println("Simulated annealing solution: ", sa_sol)
println("Cost of simulated annealing solution: ", round(sa_cost, digits=2))

# Visualize the simulated annealing solution
compare_tours(CITIES, sol, sa_sol, labels=("Current solution: $cost", "Simulated annealing solution: $(round(sa_cost, digits=2))"))

# Plot the cost history of simulated annealing
plot(sa_history, title="Simulated Annealing Cost History", xlabel="Iteration", ylabel="Best Cost", legend=false)
plot!(sa_chistory, title="All costs", xlabel="Iteration", ylabel="Current Cost",color =:red, legend=false)
#Exclamation mark to plot both histories on the same graph, with different colors.
# ------------------------------------------------------------
# Exercise 5.1 — Shake function for VND/VNS
# ------------------------------------------------------------

"""
    shake(sol, k)

Apply a random move according to neighborhood k:
  k = 1 -> swap
  k = 2 -> insert
  k = 3 -> 2-opt
Return the perturbed solution.
"""
function shake(sol, k)
    n = length(sol)
    i, j = sort(randperm(n)[1:2])
    if k == 1
        return swap_move(sol, i, j)
    elseif k == 2
        return insert_move(sol, i, j)
    else
        return two_opt_move(sol, i, j)
    end
end

# ------------------------------------------------------------
# Exercise 5.2 — Variable Neighborhood Descent (VND)
# ------------------------------------------------------------

"""
    VND(sol, D)

Neighborhood order:
  1. swap
  2. insert
  3. 2-opt

When an improvement is found, restart from the first neighborhood.
Return:
    (best_sol, best_cost, history)
"""
function VND(sol, D)
    current = copy(sol)
    current_cost = tour_cost(current, D)
    history = [current_cost]

    k = 1
    while k <= 3
        if k == 1
            new_sol, new_cost, improved = best_swap_neighbor(current, D)
        elseif k == 2
            new_sol, new_cost, improved = best_insert_neighbor(current, D)
        else
            new_sol, new_cost, improved = best_two_opt_neighbor(current, D)
        end
        if improved
            current, current_cost = new_sol, new_cost
            push!(history, current_cost)
            k = 1  # restart from first neighborhood
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
# Exercise 5.3 — Variable Neighborhood Search (VNS)
# ------------------------------------------------------------

"""
    VNS(sol, D; max_iter=200)

At each iteration:
  1. shake in neighborhood k
  2. apply VND
  3. if improved, restart with k = 1
     otherwise move to the next neighborhood

Return:
    (best_sol, best_cost, history)
"""
function VNS(sol, D; max_iter=200)
    current = copy(sol)
    current_cost = tour_cost(current, D)
    history = [current_cost]

    k = 1
    iter = 0
    while iter < max_iter
        perturbed = shake(current, k)
        new_sol, new_cost, _ = VND(perturbed, D)
        iter += 1
        if new_cost < current_cost
            current, current_cost = new_sol, new_cost
            push!(history, current_cost)
            k = 1
        else
            k = k < 3 ? k + 1 : 1
        end
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


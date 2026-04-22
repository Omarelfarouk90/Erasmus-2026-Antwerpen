# ============================================================
# Unit tests for the TSP TP
# Works with either the student or teacher file, once included.
# ============================================================

using Test
using Random
using LinearAlgebra

# A small deterministic instance used in multiple tests
const TEST_CITIES = [
    0 0
    1 0
    1 1
    0 1
]
const TEST_D = [
    0.0 1.0 sqrt(2.0) 1.0
    1.0 0.0 1.0 sqrt(2.0)
    sqrt(2.0) 1.0 0.0 1.0
    1.0 sqrt(2.0) 1.0 0.0
]

is_permutation(sol, n) = sort(sol) == collect(1:n)

function runtests_tp(which=:all)
    if which in (:all, :ex01)
        @testset "Exercise 0.1 — generate_cities          " begin
            Random.seed!(1)
            cities = generate_cities(10)
            @test size(cities) == (10, 2)
            @test all(0 .<= cities .<= 100)
        end
    end

    if which in (:all, :ex02)
        @testset "Exercise 0.2 — compute_distance_matrix  " begin
            D = compute_distance_matrix(TEST_CITIES)
            @test size(D) == (4, 4)
            @test isapprox(D[1, 2], 1.0, atol=1e-10)
            @test isapprox(D[1, 3], sqrt(2.0), atol=1e-10)
            @test issymmetric(D)
            @test all(isapprox.(diag(D), 0.0, atol=1e-10))
        end
    end

    if which in (:all, :ex11)
        @testset "Exercise 1.1 — random_solution          " begin
            Random.seed!(2)
            sol = random_solution(8)
            @test length(sol) == 8
            @test is_permutation(sol, 8)
        end
    end

    if which in (:all, :ex12)
        @testset "Exercise 1.2 — tour_cost                " begin
            sol = [1, 2, 3, 4]
            @test isapprox(tour_cost(sol, TEST_D), 4.0, atol=1e-10)

            sol2 = [1, 3, 2, 4]
            expected = sqrt(2.0) + 1.0 + sqrt(2.0) + 1.0
            @test isapprox(tour_cost(sol2, TEST_D), expected, atol=1e-10)
        end
    end

    if which in (:all, :ex21)
        @testset "Exercise 2.1 — swap_move                " begin
            sol = [1, 2, 3, 4]
            new_sol = swap_move(sol, 2, 4)
            @test new_sol == [1, 4, 3, 2]
            @test sol == [1, 2, 3, 4]   # input not modified
        end
    end

    if which in (:all, :ex22)
        @testset "Exercise 2.2 — random_swap_neighbor     " begin
            Random.seed!(3)
            sol = [1, 2, 3, 4, 5]
            neighbor = random_swap_neighbor(sol)
            @test length(neighbor) == 5
            @test is_permutation(neighbor, 5)
        end
    end

    if which in (:all, :ex23)
        @testset "Exercise 2.3 — insert_move              " begin
            sol = [1, 2, 3, 4, 5]
            @test insert_move(sol, 2, 4) == [1, 3, 4, 2, 5]
            @test insert_move(sol, 5, 1) == [5, 1, 2, 3, 4]
            @test sol == [1, 2, 3, 4, 5]
        end
    end

    if which in (:all, :ex24)
        @testset "Exercise 2.4 — two_opt_move             " begin
            sol = [1, 2, 3, 4, 5]
            @test two_opt_move(sol, 2, 4) == [1, 4, 3, 2, 5]
            @test sol == [1, 2, 3, 4, 5]
        end
    end

    if which in (:all, :ex31)
        @testset "Exercise 3.1 — best_swap_neighbor       " begin
            sol = [1, 3, 2, 4]
            best_sol, best_cost, improved = best_swap_neighbor(sol, TEST_D)
            @test improved == true
            @test is_permutation(best_sol, 4)
            @test best_cost <= tour_cost(sol, TEST_D) + 1e-10
            @test isapprox(best_cost, 4.0, atol=1e-10)
        end
    end

    if which in (:all, :ex32)
        @testset "Exercise 3.2 — local_search             " begin
            sol = [1, 3, 2, 4]
            best_sol, best_cost, history = local_search(sol, TEST_D)
            @test is_permutation(best_sol, 4)
            @test isapprox(best_cost, 4.0, atol=1e-10)
            @test history[end] == best_cost
            @test all(diff(history) .<= 1e-10)
        end
    end

    if which in (:all, :ex41)
        @testset "Exercise 4.1 — accept_move              " begin
            @test accept_move(-1.0, 1.0) == true
            @test accept_move(-0.001, 0.1) == true

            Random.seed!(0)
            accepted = sum(accept_move(1.0, 10.0) for _ in 1:1000)
            @test accepted > 700

            Random.seed!(0)
            accepted_lowT = sum(accept_move(1.0, 0.01) for _ in 1:1000)
            @test accepted_lowT < 5
        end
    end

    if which in (:all, :ex42)
        @testset "Exercise 4.2 — simulated_annealing      " begin
            Random.seed!(4)
            sol = [1, 3, 2, 4]
            best_sol, best_cost, history = simulated_annealing(sol, TEST_D; T0=1.0, alpha=0.99, max_iter=200)
            @test is_permutation(best_sol, 4)
            @test best_cost <= tour_cost(sol, TEST_D) + 1e-10
            @test history[end] == best_cost
            @test all(diff(history) .<= 1e-10)
        end
    end

    if which in (:all, :ex51)
        @testset "Exercise 5.1 — shake                    " begin
            Random.seed!(5)
            sol = [1, 2, 3, 4, 5, 6]
            for k in 1:3
                s = shake(sol, k)
                @test length(s) == 6
                @test is_permutation(s, 6)
            end
        end
    end

    if which in (:all, :ex52)
        @testset "Exercise 5.2 — VND                      " begin
            sol = [1, 3, 2, 4]
            best_sol, best_cost, history = VND(sol, TEST_D)
            @test is_permutation(best_sol, 4)
            @test best_cost <= tour_cost(sol, TEST_D) + 1e-10
            @test history[end] == best_cost
            @test all(diff(history) .<= 1e-10)
        end
    end

    if which in (:all, :ex53)
        @testset "Exercise 5.3 — VNS                      " begin
            Random.seed!(6)
            sol = [1, 3, 2, 4]
            best_sol, best_cost, history = VNS(sol, TEST_D; max_iter=20)
            @test is_permutation(best_sol, 4)
            @test best_cost <= tour_cost(sol, TEST_D) + 1e-10
            @test history[end] == best_cost
            @test all(diff(history) .<= 1e-10)
        end
    end

    println("All requested tests executed.")
end


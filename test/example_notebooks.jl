using JSON
using JuMP
using Test
using LinearAlgebra
import MathOptInterface as MOI

const REPOSITORY_ROOT = dirname(@__DIR__)

# Render notebook plots without a display server in automated checks.
ENV["GKSwstype"] = "100"

function execute_code_cells(module_, path;
    source_replacements = Pair{String,String}[],
    after_cell = (example, source) -> nothing,
)
    notebook = JSON.parsefile(path)
    @test notebook["nbformat"] == 4
    @test notebook["nbformat_minor"] == 5
    @test notebook["metadata"]["kernelspec"]["name"] == "julia-1.12"
    @test all(cell -> haskey(cell, "id"), notebook["cells"])

    code = join(
        join(cell["source"]) for cell in notebook["cells"]
        if get(cell, "cell_type", nothing) == "code"
    )
    @test !occursin(r"Pkg\.(add|update)\s*\(", code)

    serialized = JSON.json(notebook)
    @test occursin("HiGHS", serialized)
    @test !occursin("SCS", serialized)
    @test !occursin("Clp", serialized)

    for cell in notebook["cells"]
        get(cell, "cell_type", nothing) == "code" || continue
        source = join(cell["source"])
        for replacement in source_replacements
            source = replace(source, replacement)
        end
        Base.include_string(module_, source, path)
        # Notebook cells introduce module bindings dynamically on Julia 1.12.
        Base.invokelatest(after_cell, module_, source)
    end
    return module_
end

function check_network_flow(example, nodes, arcs; lower_bounds = nothing)
    @test is_solved_and_feasible(example.m)
    @test termination_status(example.m) == MOI.OPTIMAL
    for (i, j) in arcs
        flow = value(example.x[(i, j)])
        lower = isnothing(lower_bounds) ? 0 : lower_bounds[i, j]
        @test lower - 1e-8 <= flow <= example.u[i, j] + 1e-8
        @test flow ≈ round(flow) atol = 1e-8
    end
    for i in nodes
        outflow = sum((value(example.x[(i, j)]) for j in nodes if (i, j) in arcs); init = 0.0)
        inflow = sum((value(example.x[(j, i)]) for j in nodes if (j, i) in arcs); init = 0.0)
        @test outflow - inflow ≈ example.b[i] atol = 1e-8
    end
    cost = sum(example.c[i, j] * value(example.x[(i, j)]) for (i, j) in arcs)
    @test cost ≈ objective_value(example.m) atol = 1e-8
end

module MCNFExample end
module MillcoExample end
module SwimRelayExample end
module HouseMCNFExample end
module PicnicExample end

@testset "Network flow class examples" begin
    @testset "Eight-node minimum-cost flow" begin
        path = joinpath(REPOSITORY_ROOT, "notebooks", "12-mcnf.ipynb")
        example = execute_code_cells(MCNFExample, path)
        check_network_flow(example, example.nodes, example.arcs; lower_bounds = example.ℓ)
        @test objective_value(example.m) ≈ 21.0 atol = 1e-8
        @test value(example.x[(3, 6)]) ≈ 4.0 atol = 1e-8
    end

    @testset "Millco equivalent formulations" begin
        path = joinpath(REPOSITORY_ROOT, "notebooks", "13-Millco.ipynb")
        costs = Float64[]
        example = execute_code_cells(MillcoExample, path; after_cell = (example, source) -> begin
            if occursin("optimize!(m)", source)
                @test is_solved_and_feasible(example.m)
                push!(costs, objective_value(example.m))
            end
        end)
        @test costs ≈ fill(5760.0, 3) atol = 1e-8
        check_network_flow(example, example.N, example.E; lower_bounds = example.ℓ)
    end

    @testset "Swim relay and dummy assignment" begin
        path = joinpath(REPOSITORY_ROOT, "notebooks", "14-SwimRelay.ipynb")
        relay_times = Float64[]
        example = execute_code_cells(SwimRelayExample, path; after_cell = (example, source) -> begin
            if occursin("optimize!(m)", source)
                @test is_solved_and_feasible(example.m)
                push!(relay_times, objective_value(example.m))
            end
        end)
        # Independently enumerate all choices of four distinct swimmers.
        best_time = minimum(
            sum(example.raw[i, swimmers[i]] for i in 1:4)
            for swimmers in Iterators.product(ntuple(_ -> 1:5, 4)...)
            if length(unique(swimmers)) == 4
        )
        @test relay_times ≈ fill(best_time, 2) atol = 1e-8
        check_network_flow(example, example.nodes, example.arcs; lower_bounds = example.ℓ)
        @test sum(value(example.x[(i, :unused)]) for i in example.names) ≈ 1.0 atol = 1e-8
    end

    @testset "House critical path as flow" begin
        path = joinpath(REPOSITORY_ROOT, "notebooks", "15-House-mcnf.ipynb")
        example = execute_code_cells(HouseMCNFExample, path)
        check_network_flow(example, example.nodes, example.arcs; lower_bounds = example.ℓ)
        @test -objective_value(example.m) ≈ 34.0 atol = 1e-8
        @test all(example.c[i, j] == -example.duration[j] for (i, j) in example.arcs)
    end

    @testset "Picnic seating capacity" begin
        path = joinpath(REPOSITORY_ROOT, "notebooks", "16-Picnic.ipynb")
        example = execute_code_cells(PicnicExample, path)
        check_network_flow(example, example.N, example.A)
        @test -objective_value(example.m) ≈ 14.0 atol = 1e-8
        @test value(example.x[(:sink, :source)]) ≈ 14.0 atol = 1e-8
        @test all(value(example.x[(i, j)]) <= 2.0 + 1e-8
            for i in example.families, j in example.cars)
        @test all(isapprox(value(example.x[(j, :sink)]), example.u[j, :sink]; atol = 1e-8)
            for j in example.cars)
    end
end

module KnapsackExample end
module ClothCoExample end
module UFLExample end
module BranchAndBoundExample end

@testset "Integer programming class examples" begin
    @testset "Knapsack formulations" begin
        objectives = Float64[]
        selections = Vector{Float64}[]
        example = execute_code_cells(KnapsackExample,
            joinpath(REPOSITORY_ROOT, "notebooks", "17-Knapsack.ipynb");
            after_cell = (example, source) -> begin
                if occursin("optimize!(m)", source)
                    @test is_solved_and_feasible(example.m; allow_local = false)
                    push!(objectives, objective_value(example.m))
                    push!(selections, value.(example.z))
                end
            end,
        )
        # Enumerate every subset independently of the JuMP formulations.
        best = maximum(
            dot(example.v, collect(items))
            for items in Iterators.product(ntuple(_ -> 0:1, example.n)...)
            if dot(example.w, collect(items)) <= example.W
        )
        @test objectives ≈ fill(best, 2) atol = 1e-8
        for selected in selections
            @test all(x -> isapprox(x, 0; atol = 1e-8) ||
                           isapprox(x, 1; atol = 1e-8), selected)
            @test dot(example.w, selected) <= example.W + 1e-8
        end
    end

    @testset "ClothCo fixed machine rentals" begin
        example = execute_code_cells(ClothCoExample,
            joinpath(REPOSITORY_ROOT, "notebooks", "18-ClothCo.ipynb"))
        @test is_solved_and_feasible(example.m; allow_local = false)
        @test value.(example.x) ≈ [0, 0, 25] atol = 1e-8
        @test value.(example.z) ≈ [0, 0, 1] atol = 1e-8
        @test objective_value(example.m) ≈ 75.0 atol = 1e-8
        @test dot([3, 2, 6], value.(example.x)) <= 150 + 1e-8
        @test dot([4, 3, 4], value.(example.x)) <= 160 + 1e-8
        @test all(value.(example.x) .<= 54 .* value.(example.z) .+ 1e-8)
    end

    @testset "Knapsack branch and bound" begin
        path = joinpath(REPOSITORY_ROOT, "notebooks", "23-BranchAndBound.ipynb")
        bounds = Tuple{Float64,Float64}[]
        example = execute_code_cells(BranchAndBoundExample, path;
            after_cell = (example, source) -> begin
                if occursin("U = show_bounds", source)
                    push!(bounds, (example.L, example.U))
                end
            end,
        )
        # Enumerate binary selections independently of the LP relaxations.
        feasible = [collect(items)
            for items in Iterators.product(ntuple(_ -> 0:1, 4)...)
            if dot([8, 5, 3, 2], collect(items)) <= 10]
        best = maximum(dot([15, 12, 4, 2], items) for items in feasible)
        @test example.L ≈ best atol = 1e-8
        @test example.U ≈ best atol = 1e-8
        @test example.incumbent ≈ [0, 1, 1, 1] atol = 1e-8
        @test isempty(example.active_bounds)
        @test example.node1.bound ≈ 171 / 8 atol = 1e-8
        @test example.node2.bound ≈ 18 atol = 1e-8
        @test example.node3.bound ≈ 99 / 5 atol = 1e-8
        @test example.node4.bound ≈ 53 / 3 atol = 1e-8
        @test example.node5 === nothing
        @test termination_status(example.m) == MOI.INFEASIBLE
        @test all(!is_binary(x) && !is_integer(x) for x in example.x)
        # Unsolved children retain their parent's bound; pruning node 4 alone
        # cannot lower the global bound while node 5 is still active.
        expected_bounds = [(0.0, 21.375), (0.0, 21.375), (18.0, 21.375),
            (18.0, 19.8), (18.0, 19.8), (18.0, 19.8), (18.0, 18.0)]
        @test length(bounds) == length(expected_bounds)
        for ((lower, upper), (expected_lower, expected_upper)) in zip(bounds, expected_bounds)
            @test lower ≈ expected_lower atol = 1e-8
            @test upper ≈ expected_upper atol = 1e-8
            @test lower <= best + 1e-8 <= upper + 1e-8
        end
        # Restarting at setup must reset the incumbent and active tree.
        execute_code_cells(BranchAndBoundExample, path)
        @test BranchAndBoundExample.L ≈ best atol = 1e-8
        @test BranchAndBoundExample.U ≈ best atol = 1e-8
        @test isempty(BranchAndBoundExample.active_bounds)
    end

    @testset "UFL model and optional solver comparison" begin
        # CI has no commercial license. Use HiGHS for the same model there;
        # opt into actual Gurobi execution on a licensed maintainer machine.
        replacements = [
            "nI = 100" => "nI = 6",
            "nJ = 100" => "nJ = 5",
            "run_benchmarks = false" => "run_benchmarks = true",
            "nvals = [5,10,15,20,25,30,35,40,45,50]" => "nvals = [3, 5]",
            "ntrials = 10" => "ntrials = 2",
        ]
        if get(ENV, "ISYE524_TEST_GUROBI", "false") != "true"
            append!(replacements, [
                "using JuMP, Gurobi, HiGHS" => "using JuMP, HiGHS",
                "gurobi_env = Gurobi.Env(; output_flag = 0)" => "gurobi_env = nothing",
                "gurobi_optimizer = () -> Gurobi.Optimizer(gurobi_env)" => "gurobi_optimizer = HiGHS.Optimizer",
            ])
        end
        example = execute_code_cells(UFLExample,
            joinpath(REPOSITORY_ROOT, "notebooks", "19-UFL.ipynb");
            source_replacements = replacements)
        @test is_solved_and_feasible(example.license_check; allow_local = false)
        @test objective_value(example.license_check) ≈ 1.0 atol = 1e-8
        @test is_solved_and_feasible(example.m; allow_local = false)
        z, y = value.(example.z), value.(example.y)
        @test all(isapprox.(sum(y; dims = 1), 1; atol = 1e-8))
        @test all(y .<= z .+ 1e-8)
        @test all(x -> isapprox(x, round(x); atol = 1e-8), z)
        @test all(x -> isapprox(x, round(x); atol = 1e-8), y)
        # Enumerate open-facility subsets and assign each customer to the cheapest.
        best = minimum(
            sum(example.f[i] for i in 1:example.nI if (mask >> (i - 1)) & 1 == 1) +
            sum(minimum(example.c[i, j] for i in 1:example.nI
                        if (mask >> (i - 1)) & 1 == 1) for j in 1:example.nJ)
            for mask in 1:(2^example.nI - 1)
        )
        @test objective_value(example.m) ≈ best atol = 1e-8
        @test size(example.tt_highs) == size(example.tt_gurobi) == (2, 2)
        @test all(>(0), example.tt_highs)
        @test all(>(0), example.tt_gurobi)
        @test example.tt_highs_mean ≈ vec(sum(example.tt_highs; dims = 2)) ./ 2
        @test example.tt_gurobi_mean ≈ vec(sum(example.tt_gurobi; dims = 2)) ./ 2
        @test length(example.comparison_plot.series_list) == 2
    end
end

module SudokuExample end
module CuttingPipeExample end
module TSPExample end

# Independent subset dynamic program, without JuMP or subtour constraints.
function shortest_tour_length(distances)
    n = size(distances, 1)
    states = 1 << (n - 1)
    best = fill(Inf, states, n)
    best[1, 1] = 0.0
    for mask in 0:(states - 1), last in 1:n
        isfinite(best[mask + 1, last]) || continue
        for next in 2:n
            bit = 1 << (next - 2)
            mask & bit == 0 || continue
            updated = mask | bit
            best[updated + 1, next] = min(
                best[updated + 1, next],
                best[mask + 1, last] + distances[last, next],
            )
        end
    end
    return minimum(best[end, last] + distances[last, 1] for last in 2:n)
end

@testset "Sudoku, pipe cutting, and TSP class examples" begin
    @testset "Sudoku completion" begin
        example = execute_code_cells(SudokuExample,
            joinpath(REPOSITORY_ROOT, "notebooks", "20-Sudoku.ipynb"))
        @test is_solved_and_feasible(example.m; allow_local = false)
        @test size(example.solution) == (9, 9)
        for i in 1:9
            @test sort(example.solution[i, :]) == collect(1:9)
            @test sort(example.solution[:, i]) == collect(1:9)
        end
        for i in 1:3:9, j in 1:3:9
            @test sort(vec(example.solution[i:i+2, j:j+2])) == collect(1:9)
        end
        for i in 1:9, j in 1:9
            if example.given[i, j] != 0
                @test example.solution[i, j] == example.given[i, j]
            end
        end
        @test all(v -> isapprox(v, round(v); atol = 1e-8), value.(example.x))
    end

    @testset "Equivalent pipe-cutting models" begin
        objectives = Float64[]
        example = execute_code_cells(CuttingPipeExample,
            joinpath(REPOSITORY_ROOT, "notebooks", "21-CuttingPipe.ipynb");
            after_cell = (example, source) -> begin
                occursin("optimize!(m)", source) || return
                @test is_solved_and_feasible(example.m; allow_local = false)
                push!(objectives, objective_value(example.m))
                counts = value.(example.x)
                @test all(v -> v >= -1e-8 &&
                    isapprox(v, round(v); atol = 1e-8), counts)
                if ndims(counts) == 2
                    used = value.(example.z)
                    @test all(v -> isapprox(v, 0; atol = 1e-8) ||
                        isapprox(v, 1; atol = 1e-8), used)
                    @test all([4, 5, 6]' * counts .<= 19 .+ 1e-8)
                    @test all(vec(sum(counts; dims = 2)) .>=
                        [12, 15, 22] .* example.scale .- 1e-8)
                    @test all(counts .<= [4, 3, 3] * used' .+ 1e-8)
                    @test sum(used) ≈ objective_value(example.m) atol = 1e-8
                else
                    @test all(example.A * counts .>=
                        [12, 15, 22] .* example.scale .- 1e-8)
                    @test sum(counts) ≈ objective_value(example.m) atol = 1e-8
                end
            end,
        )
        # Total requested length provides a lower bound attained by both models.
        lower_bound = cld(4 * 12 + 5 * 15 + 6 * 22, 19)
        @test objectives ≈ fill(lower_bound, 2) atol = 1e-8
        # Independently enumerate every maximal feasible cutting pattern.
        maximal = Set(
            (a, b, c) for a in 0:4, b in 0:3, c in 0:3
            if 15 < 4a + 5b + 6c <= 19
        )
        @test Set(Tuple(column) for column in eachcol(example.A)) == maximal
        @test size(example.A, 2) == length(maximal)
    end

    @testset "TSP lower bound and exact tours" begin
        objectives = Float64[]
        arc_sets = Matrix{Float64}[]
        example = execute_code_cells(TSPExample,
            joinpath(REPOSITORY_ROOT, "notebooks", "22-TSP.ipynb");
            after_cell = (example, source) -> begin
                occursin("optimize!(m)", source) || return
                @test is_solved_and_feasible(example.m; allow_local = false)
                push!(objectives, objective_value(example.m))
                push!(arc_sets, [value(example.x[i, j])
                    for i in example.cities, j in example.cities])
            end,
        )
        best = shortest_tour_length(example.distances)
        @test length(objectives) == 3
        @test objectives[1] < best
        @test objectives[2:3] ≈ fill(best, 2) atol = 1e-8
        for (index, arcs) in enumerate(arc_sets)
            @test all(v -> isapprox(v, 0; atol = 1e-8) ||
                isapprox(v, 1; atol = 1e-8), arcs)
            @test all(isapprox.(sum(arcs; dims = 1), 1; atol = 1e-8))
            @test all(isapprox.(sum(arcs; dims = 2), 1; atol = 1e-8))
            @test all(abs.(diag(arcs)) .<= 1e-8)
            @test sum(arcs .* example.distances) ≈ objectives[index] atol = 1e-8
            named = example.NamedArray(arcs, (example.cities, example.cities))
            cycles = Base.invokelatest(example.getAllSubtours, named)
            if index == 1
                @test length(cycles) > 1
            else
                @test length(cycles) == 1
                @test length(only(cycles)) == example.N + 1
                @test Set(only(cycles)) == Set(example.cities)
                @test first(only(cycles)) == last(only(cycles))
            end
        end
        @test length(example.sols) > 1
        for city in example.cities
            @test 1 - 1e-8 <= value(example.u[city]) <= example.N + 1e-8
        end
        @test value(example.u[first(example.cities)]) ≈ 1.0 atol = 1e-8
        # Traversal must reject fractional or malformed cycle covers.
        fractional = example.NamedArray(fill(0.5, example.N, example.N),
            (example.cities, example.cities))
        @test_throws ErrorException Base.invokelatest(example.getAllSubtours, fractional)
        invalid = example.NamedArray(zeros(example.N, example.N),
            (example.cities, example.cities))
        @test_throws ErrorException Base.invokelatest(example.getAllSubtours, invalid)
    end
end

module TopBrassExample end

@testset "Top Brass class example" begin
    path = joinpath(REPOSITORY_ROOT, "notebooks", "01-TopBrass-Intro.ipynb")
    execute_code_cells(TopBrassExample, path)

    @test TopBrassExample.status == MOI.OPTIMAL
    @test TopBrassExample.football_value ≈ 650.0 atol = 1e-8
    @test TopBrassExample.soccer_value ≈ 1100.0 atol = 1e-8
    @test TopBrassExample.profit_value ≈ 17_700.0 atol = 1e-8
end

module TopBrassFullExample end

@testset "Top Brass indexed class example" begin
    path = joinpath(REPOSITORY_ROOT, "notebooks", "02-TopBrass-Full.ipynb")
    execute_code_cells(TopBrassFullExample, path)

    for model in (
        TopBrassFullExample.literal_model,
        TopBrassFullExample.bounded_model,
        TopBrassFullExample.indexed_model,
        TopBrassFullExample.resource_model,
    )
        @test termination_status(model) == MOI.OPTIMAL
        @test objective_value(model) ≈ 17_700.0 atol = 1e-8
    end
    @test termination_status(TopBrassFullExample.scenario_model) == MOI.OPTIMAL
    @test TopBrassFullExample.scenario_profit ≈ 18_000.0 atol = 1e-8
end

module McDonaldsDietExample end

@testset "McDonald's diet class example" begin
    path = joinpath(REPOSITORY_ROOT, "notebooks", "03-McDonaldsDiet.ipynb")
    example = execute_code_cells(McDonaldsDietExample, path)

    @test example.named_status == MOI.OPTIMAL
    @test example.indexed_status == MOI.OPTIMAL
    @test is_solved_and_feasible(example.named_model)
    @test is_solved_and_feasible(example.indexed_model)
    @test example.named_cost ≈ 14.855737704918 atol = 1e-8
    @test example.named_cost ≈ example.indexed_cost atol = 1e-8

    for servings in (
        [value(example.x_named[j]) for j in example.foods],
        value.(example.x_indexed),
    )
        @test all(servings .>= -1e-8)
        @test all(example.A * servings .>= example.required_vector .- 1e-8)
        @test sum(example.cost_vector .* servings) ≈ example.named_cost atol = 1e-8
    end
end

module CSVDietExample end

module SyntheticDietData
include(joinpath(@__DIR__, "..", "scripts", "generate_synthetic_diet.jl"))
end

@testset "CSV diet class example" begin
    path = joinpath(REPOSITORY_ROOT, "notebooks", "04-McDonaldsDiet-CSV.ipynb")
    # Simulate editing the filename and rerunning all cells in the same kernel.
    # Use both common working directories to check project-relative data paths.
    for (filename, food_count, nutrient_count, directory) in (
        ("mcdonalds.csv", 9, 7, REPOSITORY_ROOT),
        ("diet-synthetic.csv", 100, 20, joinpath(REPOSITORY_ROOT, "notebooks")),
    )
        @testset "$(filename)" begin
            replacements = [
                "dataset_filename = \"mcdonalds.csv\"" =>
                    "dataset_filename = \"$(filename)\"",
            ]
            example = cd(directory) do
                execute_code_cells(
                    CSVDietExample, path; source_replacements = replacements,
                )
            end

            @test example.dataset_filename == filename
            @test example.data_path == joinpath(REPOSITORY_ROOT, "data", filename)
            @test length(example.foods) == food_count
            @test length(example.nutrients) == nutrient_count
            @test size(example.A) == (nutrient_count, food_count)
            @test num_variables(example.model) == food_count
            @test num_constraints(
                example.model; count_variable_in_set_constraints = false,
            ) == nutrient_count
            @test example.status == MOI.OPTIMAL
            @test is_solved_and_feasible(example.model)

            servings = [value(example.x[j]) for j in example.foods]
            costs = [example.cost[j] for j in example.foods]
            minimums = [example.required[i] for i in example.nutrients]
            totals = example.A * servings
            @test all(isfinite, example.A)
            @test all(example.A .>= 0)
            @test all(isfinite, costs)
            @test all(costs .> 0)
            @test all(minimums .> 0)
            @test all(servings .>= -1e-8)
            @test all(totals .>= minimums .- 1e-8)
            @test sum(costs .* servings) ≈ example.minimum_cost atol = 1e-8
            @test example.nutrient_report.total ≈ totals atol = 1e-8
            @test example.nutrient_report.surplus ≈ totals - minimums atol = 1e-8

            if filename == "mcdonalds.csv"
                @test example.minimum_cost ≈ 14.855737704918 atol = 1e-8
                @test example.A == McDonaldsDietExample.A
                @test costs == McDonaldsDietExample.cost_vector
                @test minimums == McDonaldsDietExample.required_vector
            else
                # Check both the published generation recipe and its feasible menu.
                @test isequal(example.df, SyntheticDietData.generate_synthetic_diet())
                reference_totals = vec(sum(example.A[:, 1:20]; dims = 2))
                @test all(reference_totals .>= minimums)
                @test 0 < example.minimum_cost <= sum(costs[1:20]) + 1e-8
            end
        end
    end
end

module DietLPCasesExample end

@testset "Diet LP solution cases" begin
    path = joinpath(REPOSITORY_ROOT, "notebooks", "05-McDonaldsDiet-LPCases.ipynb")
    # Run All must rebuild the models before deleting the drink constraint again.
    for run in 1:2
        @testset "Run All $(run)" begin
            example = execute_code_cells(DietLPCasesExample, path)
            minimums = [example.required[i] for i in example.nutrients]

            @test example.A == McDonaldsDietExample.A
            @test example.unbounded_status in (
                MOI.DUAL_INFEASIBLE, MOI.INFEASIBLE_OR_UNBOUNDED,
            )
            @test !is_solved_and_feasible(example.unbounded_model)
            # Validate the feasible menu and improving direction used in the text.
            @test all(example.A * fill(10.0, length(example.foods)) .>= minimums)
            @test all(example.A_NA[:, :QP] .>= 0)
            @test :QP in example.burgers

            @test example.bounded_status == MOI.OPTIMAL
            @test is_solved_and_feasible(example.bounded_model)
            @test example.maximum_burgers ≈ 30.0 atol = 1e-8
            bounded_servings = [value(example.x_bounded[j]) for j in example.foods]
            @test all(bounded_servings .>= -1e-8)
            @test all(bounded_servings .<= 10.0 + 1e-8)
            @test all(example.A * bounded_servings .>= minimums .- 1e-8)

            # This status was saved before the same model's drink limit changed.
            @test example.infeasible_status == MOI.INFEASIBLE
            @test example.relaxed_status == MOI.OPTIMAL
            @test is_solved_and_feasible(example.limited_model)
            @test example.extra_drinks ≈ 16.9 atol = 1e-8
            @test value(example.s) ≈ example.extra_drinks atol = 1e-8
            @test example.total_drinks ≈ 3.0 + example.extra_drinks atol = 1e-8

            relaxed_servings = [value(example.x_limited[j]) for j in example.foods]
            @test all(relaxed_servings .>= -1e-8)
            @test all(example.A * relaxed_servings .>= minimums .- 1e-8)
            @test sum(value(example.x_limited[j]) for j in example.sandwiches) <= 3.0 + 1e-8
            @test value(example.x_limited[:FR]) <= 2.0 + 1e-8
        end
    end
end

module AlloyExample end

@testset "Alloy blending class example" begin
    path = joinpath(REPOSITORY_ROOT, "notebooks", "06-Alloy.ipynb")
    example = execute_code_cells(AlloyExample, path)

    @test example.status == MOI.OPTIMAL
    @test is_solved_and_feasible(example.model)
    @test example.total_production ≈ 500.0 atol = 1e-8
    @test example.minimum_cost ≈ 98_121.63579168124 atol = 1e-6

    amounts = [value(example.x[r]) for r in example.raw]
    stock = [example.availability[r] for r in example.raw]
    costs = [example.cost[r] for r in example.raw]
    @test all(amounts .>= -1e-8)
    @test all(amounts .<= stock .+ 1e-8)
    @test sum(amounts) >= example.demand - 1e-8
    @test sum(amounts) ≈ example.total_production atol = 1e-8
    @test sum(costs .* amounts) ≈ example.minimum_cost atol = 1e-6
    @test [example.remaining_stock[r] for r in example.raw] ≈ stock - amounts atol = 1e-8

    # Recompute weighted percentages from the numerical matrix, including both limits.
    grades = transpose(example.composition) * amounts / sum(amounts)
    minimums = [example.minimum_grade[e] for e in example.elements]
    maximums = [example.maximum_grade[e] for e in example.elements]
    @test all(grades .>= minimums .- 1e-8)
    @test all(grades .<= maximums .+ 1e-8)
    @test [example.final_grade[e] for e in example.elements] ≈ grades atol = 1e-8
    # The original upper-bound typo incorrectly forced copper to its minimum.
    @test example.final_grade[:Cu] ≈ 0.6 atol = 1e-8
    @test example.final_grade[:Cu] > example.minimum_grade[:Cu] + 1e-8
end

module BlendingExample end

@testset "Gasoline blending class example" begin
    path = joinpath(REPOSITORY_ROOT, "notebooks", "07-Blending.ipynb")
    example = execute_code_cells(BlendingExample, path)

    @test example.status == MOI.OPTIMAL
    @test is_solved_and_feasible(example.model)
    @test example.maximum_profit ≈ 318_100.0 atol = 1e-6

    allocations = [value(example.x[i, j]) for i in example.crudes, j in example.gases]
    purchases = [value(example.y[i]) for i in example.crudes]
    sales = [value(example.z[j]) for j in example.gases]
    advertising = [value(example.a[j]) for j in example.gases]
    @test all(allocations .>= -1e-8)
    @test all(purchases .>= -1e-8)
    @test all(sales .>= -1e-8)
    @test all(advertising .>= -1e-8)
    @test vec(sum(allocations; dims = 2)) ≈ purchases atol = 1e-8
    @test vec(sum(allocations; dims = 1)) ≈ sales atol = 1e-8
    @test all(purchases .<= example.max_crude_available + 1e-8)
    @test sum(purchases) <= example.max_crude_processed + 1e-8
    @test example.total_processed ≈ sum(purchases) atol = 1e-8

    nominal_demand = [example.gas_nom_demand[j] for j in example.gases]
    @test all(sales .<= nominal_demand .+ example.advertising_inc .* advertising .+ 1e-8)
    @test advertising ≈ max.(sales - nominal_demand, 0) / example.advertising_inc atol = 1e-8

    revenue = sum(example.gas_price[j] * value(example.z[j]) for j in example.gases)
    crude_cost = sum(example.crude_price[i] * value(example.y[i]) for i in example.crudes)
    processing_cost = example.processing_cost_per_barrel * sum(purchases)
    @test example.daily_revenue ≈ revenue atol = 1e-6
    @test example.daily_crude_cost ≈ crude_cost atol = 1e-6
    @test example.daily_processing_cost ≈ processing_cost atol = 1e-6
    @test example.daily_advertising_cost ≈ sum(advertising) atol = 1e-8
    @test example.maximum_profit ≈ revenue - crude_cost - processing_cost - sum(advertising) atol = 1e-6

    for j in example.gases
        volume = value(example.z[j])
        octane_total = sum(example.octane[i] * value(example.x[i, j]) for i in example.crudes)
        sulfur_total = sum(example.sulfur[i] * value(example.x[i, j]) for i in example.crudes)
        @test octane_total >= example.min_octane[j] * volume - 1e-8
        @test sulfur_total <= example.max_sulfur[j] * volume + 1e-8
        if volume > 1e-6
            @test example.blend_octane[j] ≈ octane_total / volume atol = 1e-8
            @test example.blend_sulfur[j] ≈ sulfur_total / volume atol = 1e-8
        else
            @test !haskey(example.blend_octane, j)
            @test !haskey(example.blend_sulfur, j)
        end
    end

    @testset "Higher processing charge and zero production" begin
        # Changing the input must affect the objective when Run All rebuilds the model.
        example = execute_code_cells(BlendingExample, path; source_replacements = [
            "processing_cost_per_barrel = 4" => "processing_cost_per_barrel = 100",
        ])
        @test example.status == MOI.OPTIMAL
        @test is_solved_and_feasible(example.model)
        @test example.maximum_profit ≈ 0.0 atol = 1e-8
        @test example.total_processed ≈ 0.0 atol = 1e-8
        @test all(abs(value(example.z[j])) <= 1e-8 for j in example.gases)
        @test all(abs(value(example.a[j])) <= 1e-8 for j in example.gases)
        @test isempty(example.produced_gases)
        @test isempty(example.blend_octane)
        @test isempty(example.blend_sulfur)
    end
end

function check_shoeco_plan(example; backlog = false)
    @test example.status == MOI.OPTIMAL
    @test is_solved_and_feasible(example.model)
    plan = example.plan
    @test plan.month == collect(example.months)
    @test plan.demand == example.d
    for (column, variables) in (
        (plan.produced, example.x), (plan.workers, example.w),
        (plan.hired, example.h), (plan.fired, example.f),
        (plan.overtime_hours, example.o),
    )
        @test column ≈ value.(variables) atol = 1e-8
        @test all(column .>= -1e-8)
    end

    # Cumulative production and staffing changes must explain each month's state.
    net_inventory = example.initial_inventory .+ cumsum(plan.produced - plan.demand)
    @test value.(example.i) ≈ net_inventory atol = 1e-8
    @test plan.workers ≈ example.initial_workforce .+ cumsum(plan.hired - plan.fired) atol = 1e-8
    @test all(example.labor_hours_per_pair .* plan.produced .<=
        example.regular_hours_per_worker .* plan.workers .+ plan.overtime_hours .+ 1e-8)
    @test all(plan.overtime_hours .<=
        example.overtime_hours_per_worker .* plan.workers .+ 1e-8)
    @test all(plan.inventory .>= -1e-8)

    costs = [
        example.material_cost * sum(plan.produced),
        example.wage_cost * sum(plan.workers),
        example.overtime_cost * sum(plan.overtime_hours),
        example.hiring_cost * sum(plan.hired),
        example.firing_cost * sum(plan.fired),
        example.holding_cost * sum(plan.inventory),
    ]
    if backlog
        @test plan.net_inventory ≈ net_inventory atol = 1e-8
        @test plan.inventory ≈ value.(example.L) atol = 1e-8
        @test plan.backlog ≈ value.(example.S) atol = 1e-8
        @test all(plan.backlog .>= -1e-8)
        @test plan.inventory ≈ max.(net_inventory, 0) atol = 1e-8
        @test plan.backlog ≈ max.(-net_inventory, 0) atol = 1e-8
        @test last(plan.backlog) ≈ 0.0 atol = 1e-8
        push!(costs, example.backlog_cost * sum(plan.backlog))
    else
        @test plan.inventory ≈ net_inventory atol = 1e-8
    end
    @test last(net_inventory) >= -1e-8
    @test example.cost_report.dollars ≈ costs atol = 1e-6
    @test sum(costs) ≈ example.minimum_cost atol = 1e-6
end

module ShoeCoExample end

@testset "ShoeCo production planning class example" begin
    path = joinpath(REPOSITORY_ROOT, "notebooks", "08-ShoeCo.ipynb")
    example = execute_code_cells(ShoeCoExample, path)
    check_shoeco_plan(example)
    @test example.minimum_cost ≈ 692_500.0 atol = 1e-6
    @test sum(example.plan.produced) ≈ 10_500.0 atol = 1e-8
    @test last(example.plan.inventory) ≈ 0.0 atol = 1e-8

    @testset "Lower overtime rate" begin
        # The default plan uses no overtime. Exercise its cost and capacity here,
        # also checking that Run All rebuilds the model in the same kernel.
        example = execute_code_cells(ShoeCoExample, path; source_replacements = [
            "overtime_cost = 13" => "overtime_cost = 1",
        ])
        check_shoeco_plan(example)
        @test sum(example.plan.overtime_hours) > 1e-8
        @test example.minimum_cost < 692_500.0
    end
end

module ShoeCoBacklogExample end

@testset "ShoeCo backlog class example" begin
    path = joinpath(REPOSITORY_ROOT, "notebooks", "09-ShoeCo-backlog.ipynb")
    example = execute_code_cells(ShoeCoBacklogExample, path)
    check_shoeco_plan(example; backlog = true)
    @test example.minimum_cost ≈ 690_000.0 atol = 1e-6
    @test example.plan.backlog ≈ [0.0, 0.0, 500.0, 0.0] atol = 1e-8
    @test sum(example.plan.produced) ≈ 10_500.0 atol = 1e-8
    @test last(example.plan.inventory) ≈ 0.0 atol = 1e-8

    @testset "Backlog penalty $(penalty)" for penalty in (100, 0)
        example = execute_code_cells(ShoeCoBacklogExample, path; source_replacements = [
            "backlog_cost = 20" => "backlog_cost = $(penalty)",
        ])
        check_shoeco_plan(example; backlog = true)
        if penalty == 100
            # An expensive backlog recovers the cost of the on-time plan.
            @test example.minimum_cost ≈ 692_500.0 atol = 1e-6
            @test all(abs.(example.plan.backlog) .<= 1e-8)
        else
            # Even free backlog must be cleared by the end of the horizon.
            @test example.minimum_cost <= 690_000.0 + 1e-6
            @test sum(example.plan.produced) ≈ 10_500.0 atol = 1e-8
        end
    end
end

module ChebyshevExample end

@testset "Chebyshev center class example" begin
    path = joinpath(REPOSITORY_ROOT, "notebooks", "10-Chebyshev.ipynb")
    example = execute_code_cells(ChebyshevExample, path)
    @test termination_status(example.m) == MOI.OPTIMAL
    @test is_solved_and_feasible(example.m)
    # Twice row 1 plus row 3, with x1 >= r and x3 >= r, gives 16r <= 12.
    @test example.radius ≈ 0.75 atol = 1e-8
    @test example.center ≈ [0.75, 3.25, 0.75] atol = 1e-8
    distances = (example.b - example.A * example.center) ./
        [norm(row) for row in eachrow(example.A)]
    @test all(distances .>= example.radius - 1e-8)
    @test length(example.vertices) == 8
    @test length(example.edges) == 12
    @test all(all(example.A * vertex .<= example.b .+ 1e-8)
        for vertex in example.vertices)
    # Exercise the plotting backend as well as construction of all four views.
    mktempdir() do directory
        for (index, plot) in enumerate((example.chebyshev_plot,
            example.side_view, example.high_view, example.low_view))
            output = joinpath(directory, "chebyshev-$(index).png")
            example.savefig(plot, output)
            @test filesize(output) > 0
        end
    end
end

module HouseExample end

@testset "House construction class example" begin
    path = joinpath(REPOSITORY_ROOT, "notebooks", "11-House.ipynb")
    example = execute_code_cells(HouseExample, path)
    @test termination_status(example.m) == MOI.OPTIMAL
    @test is_solved_and_feasible(example.m)
    @test example.makespan ≈ 34.0 atol = 1e-8
    @test value(example.tstart[:a]) ≈ 0.0 atol = 1e-8
    @test example.earliest[:x] ≈ example.makespan atol = 1e-8
    @test Set(example.critical) == Set([:a, :b, :c, :d, :j, :k, :l, :n, :s, :t, :x])
    @test example.total_float[:m] ≈ 1.0 atol = 1e-8
    for i in example.tasks
        @test example.total_float[i] >= -1e-8
        @test example.earliest[i] - 1e-8 <= value(example.tstart[i]) <= example.latest[i] + 1e-8
        @test example.latest[i] + example.duration[i] <= example.makespan + 1e-8
        for j in example.pred[i]
            @test value(example.tstart[i]) >= value(example.tstart[j]) + example.duration[j] - 1e-8
            @test example.earliest[i] >= example.earliest[j] + example.duration[j] - 1e-8
            @test example.latest[i] >= example.latest[j] + example.duration[j] - 1e-8
        end
    end
    mktempdir() do directory
        output = joinpath(directory, "house-gantt.png")
        example.savefig(example.gantt_plot, output)
        @test filesize(output) > 0
    end
end

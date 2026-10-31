using JSON
using JuMP
# Notebook kernels load REPL, which enables formatted documentation from @doc.
using REPL
using Test
import MathOptInterface as MOI

const REPOSITORY_ROOT = dirname(@__DIR__)

module AssignmentWorkspace
include(joinpath(@__DIR__, "..", "scripts", "start_assignment.jl"))
end

function read_notebook(path)
    notebook = JSON.parsefile(path)
    @test notebook["nbformat"] == 4
    @test notebook["nbformat_minor"] == 5
    @test notebook["metadata"]["kernelspec"]["name"] == "julia-1.12"
    @test all(cell -> haskey(cell, "id"), notebook["cells"])
    return notebook
end

function execute_code_cells(module_, path; cell_filename = path)
    notebook = read_notebook(path)
    code = join(
        join(cell["source"])
        for cell in notebook["cells"]
        if get(cell, "cell_type", nothing) == "code"
    )
    @test !occursin(r"Pkg\.(add|update)\s*\(", code)
    for cell in notebook["cells"]
        get(cell, "cell_type", nothing) == "code" || continue
        Base.include_string(module_, join(cell["source"]), cell_filename)
    end
    return module_
end

module JuliaTutorial end
module HomeworkZero end

@testset "Homework 0 starter notebooks" begin
    tutorial_path = joinpath(
        REPOSITORY_ROOT,
        "assignments",
        "hw00",
        "julia-tutorial.ipynb",
    )
    homework_path = joinpath(
        REPOSITORY_ROOT,
        "assignments",
        "hw00",
        "hw00.ipynb",
    )

    execute_code_cells(JuliaTutorial, tutorial_path)
    execute_code_cells(HomeworkZero, homework_path)

    @test HomeworkZero.termination_status(HomeworkZero.nonlinear_model) ==
          MOI.LOCALLY_SOLVED
    @test HomeworkZero.x_value ≈ π / 2 atol = 1e-6
    @test HomeworkZero.obj_value ≈ 0.0 atol = 1e-10

    mktempdir() do repository
        mkpath(joinpath(repository, "assignments"))
        cp(
            joinpath(REPOSITORY_ROOT, "assignments", "hw00"),
            joinpath(repository, "assignments", "hw00"),
        )
        destination = AssignmentWorkspace.start_assignment(repository, "hw00")
        @test isfile(joinpath(destination, "README.md"))
        @test isfile(joinpath(destination, "hw00.ipynb"))
        @test isfile(joinpath(destination, "julia-tutorial.ipynb"))
    end
end

module HomeworkTwo end

module HomeworkThree end

module HomeworkFour end

module HomeworkFive end

module HomeworkSix end

module HomeworkSeven end

module HomeworkEight end

function check_homework_eight_data(example)
    @test example.I == 1:6
    @test example.V == 0:6
    @test Set(keys(example.q)) == Set(example.I)
    @test all(i -> 0 < example.q[i] <= example.Q, example.I)
    @test Set(keys(example.T)) == Set((i, j) for i in example.V, j in example.V)
    @test all(i -> example.T[i, i] == 0, example.V)
    @test all(pair -> example.T[pair] == example.T[reverse(pair)], keys(example.T))
    @test example.route_time([1, 3]) == example.T[0, 1] + example.T[1, 3] + example.T[3, 0]
    @test example.n == length(example.J) == 5

    @test length(example.N) == 10
    @test length(unique(example.A)) == 16
    @test Set(keys(example.b)) == Set(example.N)
    @test sum(values(example.b)) == 0
    @test Set(keys(example.c)) == Set(keys(example.u)) == Set(keys(example.f_HW04)) == Set(example.A)
    @test all(a -> all(i -> i in example.N, a), example.A)
    @test all(a -> example.c[a] > 0 && example.u[a] >= 4, example.A)
    @test all(a -> 0 <= example.f_HW04[a] <= example.u[a], example.A)
    @test all(example.N) do i
        sum(example.f_HW04[a] for a in example.A if a[1] == i; init = 0) -
        sum(example.f_HW04[a] for a in example.A if a[2] == i; init = 0) == example.b[i]
    end
    @test sum(example.c[a] * example.f_HW04[a] for a in example.A) == 242
    @test example.K == 1:3
    @test Set(keys(example.B)) == Set((a, k) for a in example.A, k in 0:3)
    @test all(a -> [example.B[a, k] for k in 0:3] == [0, 2, 4, example.u[a]], example.A)
end

@testset "Homework 8 starter notebook and student copy" begin
    source = joinpath(REPOSITORY_ROOT, "assignments", "hw08")
    mktempdir() do repository
        mkpath(joinpath(repository, "assignments"))
        cp(source, joinpath(repository, "assignments", "hw08"))
        @test "hw08" in AssignmentWorkspace.available_assignments(repository)
        destination = AssignmentWorkspace.start_assignment(repository, "hw08")
        notebook = joinpath(destination, "hw08.ipynb")
        for file in ("hw08.ipynb", "README.md", "README.html")
            @test read(joinpath(destination, file)) == read(joinpath(source, file))
        end
        # The copied starter must work both beside the notebook and from the root.
        for directory in (destination, repository)
            cd(directory) do
                execute_code_cells(HomeworkEight, notebook; cell_filename = "In[1]")
            end
            Base.invokelatest(check_homework_eight_data, HomeworkEight)
        end
        @test_throws ErrorException AssignmentWorkspace.start_assignment(repository, "hw08")
        @test read(notebook) == read(joinpath(source, "hw08.ipynb"))
    end
end

function check_homework_seven_data(example)
    for (devices, lower, upper, cost) in (
        (example.B, example.L, example.U, example.c),
        (example.T, example.ell, example.u, example.k),
    )
        @test length(devices) == 3
        @test Set(keys(lower)) == Set(keys(upper)) == Set(keys(cost)) == Set(devices)
        @test all(i -> 0 < lower[i] <= upper[i], devices)
        @test all(i -> isfinite(cost[i]) && cost[i] > 0, devices)
    end
    @test Set(keys(example.q)) == Set(example.T)
    @test all(j -> isfinite(example.q[j]) && example.q[j] > 0, example.T)
    @test length(unique(example.P)) == 8
    for data in (example.c_project, example.b_project, example.h_project)
        @test Set(keys(data)) == Set(example.P)
        @test all(value -> value isa Integer && value > 0, values(data))
    end
    @test example.budget > 0
    @test length(example.I) == length(example.J) == 8
    @test Set(keys(example.N)) == Set(example.I)
    @test all(i -> i in example.N[i], example.I)
    @test all(i -> all(j -> j in example.J, example.N[i]), example.I)
end

@testset "Homework 7 starter notebook and student copy" begin
    source = joinpath(REPOSITORY_ROOT, "assignments", "hw07")
    mktempdir() do repository
        mkpath(joinpath(repository, "assignments"))
        cp(source, joinpath(repository, "assignments", "hw07"))
        @test "hw07" in AssignmentWorkspace.available_assignments(repository)
        destination = AssignmentWorkspace.start_assignment(repository, "hw07")
        notebook = joinpath(destination, "hw07.ipynb")
        for file in ("hw07.ipynb", "README.md", "README.html")
            @test read(joinpath(destination, file)) == read(joinpath(source, file))
        end
        # The copied starter must work both beside the notebook and from the root.
        for directory in (destination, repository)
            cd(directory) do
                execute_code_cells(HomeworkSeven, notebook; cell_filename = "In[1]")
            end
            Base.invokelatest(check_homework_seven_data, HomeworkSeven)
        end
    end
end

function check_homework_six_data(example)
    @test Set(keys(example.c_path)) == Set(example.arcs_path)
    @test sum(values(example.b_path)) == 0
    @test Set(keys(example.u_flow)) == Set(example.arcs_flow)
    @test Set(keys(example.x_given)) == Set(example.arcs_flow)
    @test all(a -> 0 <= example.x_given[a] <= example.u_flow[a], example.arcs_flow)
end

@testset "Homework 6 starter notebook and student copy" begin
    source = joinpath(REPOSITORY_ROOT, "assignments", "hw06")
    template = read_notebook(joinpath(source, "hw06.ipynb"))
    figure = only(filter(cell -> haskey(cell, "attachments"), template["cells"]))
    @test !isempty(figure["attachments"]["maxflow.png"]["image/png"])
    @test occursin("attachment:maxflow.png", join(figure["source"]))

    mktempdir() do repository
        mkpath(joinpath(repository, "assignments"))
        cp(source, joinpath(repository, "assignments", "hw06"))
        @test "hw06" in AssignmentWorkspace.available_assignments(repository)
        destination = AssignmentWorkspace.start_assignment(repository, "hw06")
        notebook = joinpath(destination, "hw06.ipynb")
        for file in ("hw06.ipynb", "README.md", "README.html")
            @test read(joinpath(destination, file)) == read(joinpath(source, file))
        end
        # The copied starter must work both beside the notebook and from the root.
        for directory in (destination, repository)
            cd(directory) do
                execute_code_cells(HomeworkSix, notebook; cell_filename = "In[1]")
            end
            Base.invokelatest(check_homework_six_data, HomeworkSix)
        end
    end
end

function check_homework_five_data(example, destination)
    @test example.road_file == joinpath(destination, "data", "roads.csv")
    @test length(example.nodes_small) == 7
    @test length(unique(example.arcs_small)) == 12
    @test Set(keys(example.c_small)) == Set(example.arcs_small)
    @test example.s_small == :S && example.t_small == :A
    @test length(example.nodes_large) == 900
    @test length(unique(example.arcs_large)) == 2914
    @test Set(keys(example.c_large)) == Set(example.arcs_large)
    @test all(arc -> all(node -> node in example.nodes_large, arc), example.arcs_large)
    @test all(arc -> reverse(arc) in example.arcs_large, example.arcs_large)
    @test all(cost -> isfinite(cost) && cost > 0, values(example.c_large))
    @test example.s_large == 1 && example.t_large == 900
    @test length(example.nodes_flow) == 6
    @test length(unique(example.arcs_flow)) == 8
    @test Set(keys(example.u_flow)) == Set(example.arcs_flow)
    @test all(capacity -> isfinite(capacity) && capacity >= 0, values(example.u_flow))
    @test example.s_flow == "s" && example.t_flow == "t"
end

@testset "Homework 5 starter notebook and student copy" begin
    source = joinpath(REPOSITORY_ROOT, "assignments", "hw05")
    mktempdir() do repository
        mkpath(joinpath(repository, "assignments"))
        cp(source, joinpath(repository, "assignments", "hw05"))
        @test "hw05" in AssignmentWorkspace.available_assignments(repository)
        template = joinpath(repository, "assignments", "hw05", "hw05.ipynb")
        cd(repository) do
            execute_code_cells(HomeworkFive, template; cell_filename = "In[1]")
        end
        Base.invokelatest(check_homework_five_data, HomeworkFive, dirname(template))

        destination = AssignmentWorkspace.start_assignment(repository, "hw05")
        notebook = joinpath(destination, "hw05.ipynb")
        for file in ("hw05.ipynb", "README.md", "README.html", joinpath("data", "roads.csv"))
            @test read(joinpath(destination, file)) == read(joinpath(source, file))
        end
        for directory in (destination, repository)
            cd(directory) do
                execute_code_cells(HomeworkFive, notebook; cell_filename = "In[1]")
            end
            Base.invokelatest(check_homework_five_data, HomeworkFive, destination)
        end

        # Course updates and repeated copy attempts must preserve student answers.
        write(notebook, read(notebook, String) * "\n")
        student_work = read(notebook)
        write(joinpath(dirname(template), "README.md"), "Updated instructions\n")
        @test_throws ErrorException AssignmentWorkspace.start_assignment(repository, "hw05")
        @test read(notebook) == student_work
        @test read(joinpath(destination, "README.md")) == read(joinpath(source, "README.md"))

        # Missing personal data must fail rather than load the template's CSV.
        rm(joinpath(destination, "data", "roads.csv"))
        for directory in (destination, repository)
            cd(directory) do
                @test_throws LoadError execute_code_cells(
                    HomeworkFive, notebook; cell_filename = "In[1]",
                )
            end
        end
    end
end

function check_homework_four_data(example, destination)
    @test example.data_dir == joinpath(destination, "data")
    @test size(example.A_small) == (8, 4)
    @test length(example.b_small) == 8
    @test size(example.A_large) == (1200, 60)
    @test length(example.b_large) == 1200
    @test example.equation_ids == collect(1:1200)
    @test example.coefficient_columns == ["a" * lpad(i, 2, '0') for i in 1:60]
    @test all(isfinite, example.A_large)
    @test all(isfinite, example.b_large)
    @test length(example.N) == 10
    @test length(unique(example.A)) == 16
    @test sum(values(example.b)) == 0
    @test Set(keys(example.c)) == Set(keys(example.u)) == Set(example.A)
    @test all(arc -> all(node -> node in example.N, arc), example.A)
    @test all(capacity -> capacity >= 0, values(example.u))
    @test length(example.T) == length(example.d) == length(example.pred) == 18
    @test all(pair -> all(task -> task in example.T, pair), example.P)
end

@testset "Homework 4 starter notebook and student copy" begin
    source = joinpath(REPOSITORY_ROOT, "assignments", "hw04")
    mktempdir() do repository
        mkpath(joinpath(repository, "assignments"))
        cp(source, joinpath(repository, "assignments", "hw04"))
        @test "hw04" in AssignmentWorkspace.available_assignments(repository)
        template = joinpath(repository, "assignments", "hw04", "hw04.ipynb")
        cd(repository) do
            execute_code_cells(HomeworkFour, template; cell_filename = "In[1]")
        end
        Base.invokelatest(check_homework_four_data, HomeworkFour, dirname(template))

        destination = AssignmentWorkspace.start_assignment(repository, "hw04")
        notebook = joinpath(destination, "hw04.ipynb")
        for file in ("hw04.ipynb", "README.md", "README.html",
            joinpath("data", "regression-large.csv"))
            @test read(joinpath(destination, file)) == read(joinpath(source, file))
        end
        for directory in (destination, repository)
            cd(directory) do
                execute_code_cells(HomeworkFour, notebook; cell_filename = "In[1]")
            end
            Base.invokelatest(check_homework_four_data, HomeworkFour, destination)
        end

        # Preserve saved student work when a template is updated and copied again.
        write(notebook, read(notebook, String) * "\n")
        student_work = read(notebook)
        write(joinpath(dirname(template), "README.md"), "Updated instructions\n")
        @test_throws ErrorException AssignmentWorkspace.start_assignment(repository, "hw04")
        @test read(notebook) == student_work
        @test read(joinpath(destination, "README.md")) == read(joinpath(source, "README.md"))

        # Missing student data must fail instead of loading the template's CSV.
        rm(joinpath(destination, "data", "regression-large.csv"))
        for directory in (destination, repository)
            cd(directory) do
                @test_throws LoadError execute_code_cells(
                    HomeworkFour, notebook; cell_filename = "In[1]",
                )
            end
        end
    end
end

@testset "Homework 3 starter notebook and student copy" begin
    source = joinpath(REPOSITORY_ROOT, "assignments", "hw03")
    mktempdir() do repository
        mkpath(joinpath(repository, "assignments"))
        cp(source, joinpath(repository, "assignments", "hw03"))
        @test "hw03" in AssignmentWorkspace.available_assignments(repository)
        destination = AssignmentWorkspace.start_assignment(repository, "hw03")
        notebook = joinpath(destination, "hw03.ipynb")
        for file in ("hw03.ipynb", "README.md")
            @test read(joinpath(destination, file)) == read(joinpath(source, file))
        end
        for directory in (destination, repository)
            cd(directory) do
                execute_code_cells(HomeworkThree, notebook; cell_filename = "In[1]")
            end
        end

        # Updating the template must preserve an existing student's work.
        write(notebook, read(notebook, String) * "\n")
        student_work = read(notebook)
        write(joinpath(repository, "assignments", "hw03", "README.md"), "Updated instructions\n")
        @test_throws ErrorException AssignmentWorkspace.start_assignment(repository, "hw03")
        @test read(notebook) == student_work
        @test read(joinpath(destination, "README.md")) == read(joinpath(source, "README.md"))
    end
end

function check_homework_two_data(example, destination)
    @test example.data_dir == joinpath(destination, "data")
    @test length(example.P) == 5
    @test length(example.C) == 5
    @test length(example.h) == 25
    @test Set(keys(example.h)) ==
          Set((p, c) for p in example.P for c in example.C)
    @test all(example.products.availability .>= 0)
    @test all(example.methods.capacity .>= 0)
    @test all(example.methods.cost .>= 0)
    @test all(isfinite, values(example.h))

    @test example.b == Dict(row.product => row.availability for row in eachrow(example.products))
    @test example.u == Dict(row.method => row.capacity for row in eachrow(example.methods))
    @test example.q == Dict(row.method => row.cost for row in eachrow(example.methods))
end

@testset "Homework 2 starter notebook and student copy" begin
    source = joinpath(REPOSITORY_ROOT, "assignments", "hw02")
    mktempdir() do repository
        mkpath(joinpath(repository, "assignments"))
        cp(source, joinpath(repository, "assignments", "hw02"))
        template = joinpath(repository, "assignments", "hw02", "hw02.ipynb")

        # A kernel at the repository root can also run the published template.
        cd(repository) do
            execute_code_cells(HomeworkTwo, template; cell_filename = "In[1]")
        end
        @test Base.invokelatest(getproperty, HomeworkTwo, :data_dir) ==
              joinpath(dirname(template), "data")

        destination = AssignmentWorkspace.start_assignment(repository, "hw02")
        notebook = joinpath(destination, "hw02.ipynb")
        for file in (
            "hw02.ipynb", "README.md", joinpath("data", "products.csv"),
            joinpath("data", "methods.csv"), joinpath("data", "revenues.csv"),
        )
            @test read(joinpath(destination, file)) == read(joinpath(source, file))
        end
        @test_throws ErrorException AssignmentWorkspace.start_assignment(repository, "hw02")

        for directory in (destination, repository)
            cd(directory) do
                execute_code_cells(HomeworkTwo, notebook; cell_filename = "In[1]")
            end
            # Julia 1.12 notebook evaluation introduces bindings in a new world age.
            Base.invokelatest(check_homework_two_data, HomeworkTwo, destination)
        end

        # Missing student data must not silently fall back to the template.
        rm(joinpath(destination, "data", "products.csv"))
        cd(repository) do
            @test_throws LoadError execute_code_cells(
                HomeworkTwo, notebook; cell_filename = "In[1]",
            )
        end
    end
end

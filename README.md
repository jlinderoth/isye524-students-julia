# ISyE 524: Julia Student Environment

This repository provides the supported Julia environment for ISyE 524. It is
intended to give every student the same Julia, JuMP, solver, data, plotting,
notebook, and PDF-export workflow.

The Julia environment, VS Code integration, installation checks, Gradescope PDF
export, and Homework 0 starter material are ready. The class examples develop
the Top Brass, McDonald's diet, alloy blending, gasoline blending, and ShoeCo
production-planning linear programs, the Chebyshev center problem, house
construction scheduling, and network flow applications.
Additional course notebooks and assignments
will be published throughout the semester, so students must update the repository
regularly.

## Students: start here

1. For your first setup, follow
   [Start Here with Julia and JuMP](docs/canvas-start-here.md).
2. For Homework 0 and every later assignment, follow
   [Assignments and PDF Submission](docs/canvas-assignment-workflow.md).

## Installation

Before running any VS Code task, follow the complete
[installation instructions](docs/installation.md). They cover Git, Julia 1.12,
VS Code, native Windows versus WSL, Quarto, PDF support, and verification in
the order students should perform them. Existing local Git, Julia, and LaTeX
installations are supported when their command-line checks pass inside VS Code.

The installation guide is a Markdown document, not Julia code. Do not execute
the guide in a Julia REPL. Run its boxed commands in a VS Code terminal, and use
the named VS Code tasks for course setup and checks.

## Supported Julia version

Use Julia 1.12, preferably installed with
[Juliaup](https://julialang.org/downloads/). An existing Julia installation is
also supported when its `julia` command is on `PATH`. The environment accepts
Julia 1.12 patch releases and was initially generated with Julia 1.12.7.

After completing the installation guide, open the repository root in VS Code.
The repository recommends the Julia, Jupyter, and Quarto extensions.

Open the Command Palette, select `Tasks: Run Task`, and run:

```text
ISyE 524: Set up / refresh Julia environment
```

The equivalent terminal command is:

```text
julia --startup-file=no --project=. scripts/setup.jl
```

In addition to installing the Julia packages, setup creates two local folders:

- `student-work/` for personal assignment copies
- `submissions/` for generated Gradescope PDFs

Both folders are excluded from Git. Course updates therefore do not overwrite
student answers, but students must keep a separate backup of `student-work/`.

`Project.toml` lists the course's direct dependencies. `Manifest.toml` records
the complete, tested dependency graph. Do not use `Pkg.add` from an individual
course notebook.

## Checking the installation

Open [notebooks/00-check-installation.ipynb](notebooks/00-check-installation.ipynb)
in VS Code. If prompted for a notebook kernel, select Julia 1.12, then choose
**Run All**. A successful run displays:

- the active Julia version and course project
- the optimal solution `(x, y) = (3.6, 2.8)` and objective value `22.0`
- a two-row results table
- a plot of the feasible region and optimal solution

The notebook also contains Markdown mathematics so students can confirm that
equations render in VS Code. Its outputs are intentionally cleared in Git; your
local outputs do not need to be committed.

For a quicker command-line check, run this VS Code task:

```text
ISyE 524: Run environment check
```

The equivalent terminal command is:

```text
julia --startup-file=no --project=. test/smoke.jl
```

## Class examples

After the installation check, open
[notebooks/01-TopBrass-Intro.ipynb](notebooks/01-TopBrass-Intro.ipynb) and select
**Run All**. The notebook formulates the Top Brass production-planning LP in
JuMP, solves it with HiGHS, checks for an optimal termination status, and
interprets the solution.

Continue with
[notebooks/02-TopBrass-Full.ipynb](notebooks/02-TopBrass-Full.ipynb) to develop
the same model using variable bounds, dictionaries, and a NamedArray.
[notebooks/03-McDonaldsDiet.ipynb](notebooks/03-McDonaldsDiet.ipynb) minimizes
the cost of a menu subject to nutrient minimums, using both named and integer
indices.
[notebooks/04-McDonaldsDiet-CSV.ipynb](notebooks/04-McDonaldsDiet-CSV.ipynb)
reads the diet model's data from CSV. Change `dataset_filename` in its first
code cell to select `mcdonalds.csv` (9 foods, 7 nutrients) or
`diet-synthetic.csv` (100 fictional foods, 20 fictional nutrients), then choose
**Run All**. Both CSV files are included under `data/`; see the
[dataset descriptions and format](data/README.md).
[notebooks/05-McDonaldsDiet-LPCases.ipynb](notebooks/05-McDonaldsDiet-LPCases.ipynb)
explores unbounded, optimal, and infeasible diet LPs, then restores feasibility
by relaxing the drink limit. Its unbounded and infeasible outcomes are
intentional; choose **Run All** to work through every case.
[notebooks/06-Alloy.ipynb](notebooks/06-Alloy.ipynb) minimizes the cost of a
500-tonne steel order subject to raw-material availability and minimum and
maximum element percentages.
[notebooks/07-Blending.ipynb](notebooks/07-Blending.ipynb) maximizes daily
gasoline profit by choosing crude purchases, blends, sales, and advertising,
subject to capacity, demand, octane, and sulfur limits.
[notebooks/08-ShoeCo.ipynb](notebooks/08-ShoeCo.ipynb) minimizes four months of
production, workforce, overtime, and inventory costs while meeting demand on
time.
[notebooks/09-ShoeCo-backlog.ipynb](notebooks/09-ShoeCo-backlog.ipynb) extends
that model to allow late deliveries with monthly backlog penalties, requiring
all orders to be filled by the end of month 4. Both ShoeCo examples treat
workforce decisions as continuous LP variables.
[notebooks/10-Chebyshev.ipynb](notebooks/10-Chebyshev.ipynb) finds the center
and radius of the largest ball inside a polyhedron using an LP, then visualizes
the solution from four viewing angles.
[notebooks/11-House.ipynb](notebooks/11-House.ipynb) minimizes house construction
time subject to task precedence, identifies critical tasks and total float,
and displays an earliest-start Gantt chart.
[notebooks/12-mcnf.ipynb](notebooks/12-mcnf.ipynb) introduces minimum-cost
network flow with an eight-node shipping network and arc capacities.
[notebooks/13-Millco.ipynb](notebooks/13-Millco.ipynb) solves a lumber
transportation problem using indexed, matrix, and network-flow formulations.
[notebooks/14-SwimRelay.ipynb](notebooks/14-SwimRelay.ipynb) assigns swimmers
to relay strokes, then balances the network with a dummy unused-swimmer stroke.
[notebooks/15-House-mcnf.ipynb](notebooks/15-House-mcnf.ipynb) finds a critical
path for the house project using minimum-cost flow with negative task durations
as arc costs.
[notebooks/16-Picnic.ipynb](notebooks/16-Picnic.ipynb) maximizes the number of
family members transported in four cars using a minimum-cost circulation.
[notebooks/17-Knapsack.ipynb](notebooks/17-Knapsack.ipynb) chooses items with
binary variables, first with a literal model and then an indexed formulation.
[notebooks/18-ClothCo.ipynb](notebooks/18-ClothCo.ipynb) links continuous clothing
production to binary machine-rental decisions and maximizes net profit.
[notebooks/19-UFL.ipynb](notebooks/19-UFL.ipynb) solves uncapacitated facility
location with Gurobi and includes an optional HiGHS/Gurobi timing comparison.
[notebooks/20-BranchAndBound.ipynb](notebooks/20-BranchAndBound.ipynb) walks
through a five-node knapsack branch-and-bound tree using HiGHS LP relaxations,
tracking global bounds and pruning by integrality, bound, and infeasibility.
All class examples use packages included in the course environment. UFL also
requires a Gurobi license; its opening section explains academic license setup.

Files under `notebooks/` are read-only course examples. Students should run and
study them but should not save personal work in those tracked files.

## Included Julia packages

The course environment includes:

- JuMP with the open-source HiGHS and Ipopt solvers
- Gurobi's Julia interface for the UFL example (a separate solver license is required)
- CSV, DataFrames, NamedArrays, and XLSX for course data
- Plots for visualization
- Distributions and MathOptInterface for selected course material
- Printf from Julia's standard library for formatted output

JSON is also included for the repository's notebook-cleaning tools; students do
not need to use it in course notebooks.

Gurobi is used only by the UFL example; the other examples and environment check
use the open-source solvers. Follow the license instructions at the top of
[UFL](notebooks/19-UFL.ipynb) before running it. Mosek is not included.

## Starting an assignment

Instructor templates are published in a separate folder for each assignment,
such as `assignments/hw00/`. Do not edit the tracked template directly. After
pulling the latest course files, run this VS Code task:

```text
ISyE 524: Start an assignment from its template
```

Enter the assignment name supplied by the instructor, such as `hw00`. The task
copies the complete template to `student-work/hw00/` and refuses to overwrite
an existing student copy. Work only in the new `student-work/` folder.

The equivalent terminal command is:

```text
julia --startup-file=no --project=. scripts/start_assignment.jl hw00
```

Available assignment templates are:

- [HW00: Julia and JuMP setup](assignments/hw00/README.md), including the Julia
  tutorial and installation exercises.
- [HW01: Convexity and introductory linear programming](assignments/hw01/README.md).
- [HW02: LP reformulation, solution cases, and indexed models](assignments/hw02/README.md),
  including the three CSV files used in Problem 3(d). Enter `hw02` in the
  assignment-copy task to copy the notebook and its data together.
- [HW03: Blending and multiperiod planning](assignments/hw03/README.md),
  with all data included in the notebook. Enter `hw03` in the assignment-copy task.
- [HW04: Fitting, network flow, and project scheduling](assignments/hw04/README.md),
  including the regression CSV for Problem 1(c). Enter `hw04` in the
  assignment-copy task to copy the notebook and its data together.
- [HW05: Shortest paths, maximum flow, and duality](assignments/hw05/README.md),
  including the road-network CSV for Problem 1(c). Enter `hw05` in the
  assignment-copy task to copy the notebook and its data together.
- [HW06: Network duality and integer production](assignments/hw06/README.md),
  with all network data and the figure included in the notebook. Enter `hw06`
  in the assignment-copy task.

See [Assignments and PDF Submission](docs/canvas-assignment-workflow.md) for the
complete recurring workflow. See
[Assignment files, images, and backups](docs/assignments.md) for additional
details about handwritten work and protecting student files.

## Keeping course files current

As new course material is published, open `Tasks: Run Task` and run:

```text
ISyE 524: Update course repository
```

This task performs a fast-forward-only Git pull and then refreshes the Julia
environment.
The pull also downloads newly published class examples into `notebooks/` and
their shared CSV files into `data/`, including the Top Brass and McDonald's
diet examples linked above. Running
**Set up / refresh Julia environment** alone installs packages from the local
course files; use **Update course repository** to receive new notebooks.

Work under `student-work/` is ignored by Git and is unaffected.
If a student edits a tracked course file and an update changes the same file,
Git stops instead of overwriting it. The task never resets or automatically
stashes student files.

If notebook outputs or local edits block an update, save and close your
notebooks, then run **ISyE 524: Reset course files to latest (with backup)**.
This separate recovery task backs up saved course files and Git history in a
dated folder beside the repository, replaces tracked files with the latest
published versions, and refreshes Julia packages. Personal work in
`student-work/`, generated `submissions/`, and local VS Code settings are
preserved. See [reset and backup instructions](docs/course-updates.md#reset-course-files-with-an-automatic-backup).

Personal VS Code settings in `.vscode/settings.json` are ignored by Git.
Shared tasks and extension recommendations remain tracked. Optional course
settings are supplied in `.vscode/settings.example.json`; copy it to
`.vscode/settings.json` if you want those defaults.

If an update stops, follow [Help with course updates](docs/course-updates.md).
Older clones may need the one-time settings migration described there before
they can receive the change that stops tracking `.vscode/settings.json`.

When an announcement adds Julia packages or solvers, follow
[Updating course packages and solvers](docs/package-updates.md) to install the
update, check the environment, and restart your notebook kernels.

## Exporting assignments to PDF

Assignments are exported from saved Jupyter notebooks with Quarto. Install
[Quarto](https://quarto.org/docs/download/), then use the repository's VS Code
tasks to check the PDF tools and export the active notebook. Generated PDFs are
placed in `submissions/` for review before uploading to Gradescope.

Students without TeX can explicitly install Quarto-managed TinyTeX without
adding it to the system `PATH`. Students who already maintain TeX Live, MacTeX,
or MiKTeX can select the separate system-TeX export task. The system-TeX task
disables Quarto's TinyTeX selection and automatic package installation.

Follow [Assignments and PDF Submission](docs/canvas-assignment-workflow.md) for
the normal submission sequence. See
[Exporting a notebook to PDF](docs/pdf-export.md) for installation details,
system-TeX guidance, and troubleshooting.

## Repository layout

```text
assignments/   Instructor-published assignment templates
data/          Shared data files used by notebooks
docs/          Student and maintainer instructions
notebooks/     Course notebooks and installation checks
scripts/       Setup, assignment, update, and export helpers
student-work/  Personal assignment copies; generated and ignored by Git
submissions/   Generated Gradescope PDFs; ignored by Git
test/          Environment and notebook smoke tests
```

## For course maintainers

Changes to `Project.toml` must be made through Julia's package manager. Commit
the corresponding `Manifest.toml` change and verify the environment before
publishing it to students.

See [Assignment templates](assignments/README.md) before publishing a new
starter notebook. See [Maintainer workflow](docs/maintainers.md) to enable the
notebook-cleaning hook and run the same checks enforced by GitHub Actions.

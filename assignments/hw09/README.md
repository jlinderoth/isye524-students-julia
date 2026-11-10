# Homework 09: Quadratic assignment, IP algorithms, and least squares

Due **Monday, November 16, 2026, at 11:59 p.m. (Madison time)**.

## Files and getting started

- `hw09.ipynb`: the assignment, all numerical data, an LP-solving helper, and response areas. No separate data files are required.
- `README.md`: this overview; `README.html` contains the same instructions for Canvas.

Follow [Assignments and PDF Submission](https://github.com/jlinderoth/isye524-students-julia/blob/main/docs/canvas-assignment-workflow.md) for updating, copying, exporting, and backing up your work.

In VS Code, use **Tasks: Run Task** to run **ISyE 524: Update course repository**, then **ISyE 524: Start an assignment from its template**, entering **`hw09`**. Open **`student-work/hw09/hw09.ipynb`** and select the Julia 1.12 kernel. An existing working copy will not be overwritten. Later course updates do not automatically update your personal copy.

## Complete HW09

Complete all three problems:

1. **Peeps production:** formulate a quadratic assignment problem for four factories and seven cities, linearize the binary products, and solve the resulting MILP. Report factory locations and monthly transportation cost.
2. **Branch-and-bound and cuts:** use continuous LP relaxations to construct a search tree using the specified branching rule and any open-node order you choose. Record the order in which you solve the node LPs. Explain pruning and global bounds, prove two valid inequalities, and compare the search after adding them. Use the supplied LP helper; you do not need to program a branch-and-bound solver.
3. **Road measurements:** formulate a least-squares fit to five measurements of three road segments. Identify the quadratic matrix, prove it is PSD and determine whether it is positive definite, then solve the QP and report the fitted lengths, distances, residuals, and minimum squared error with units.

Write each requested mathematical formulation before its implementation. Use the supplied decision-variable definitions and Julia/JuMP with HiGHS from the course environment. Check solver status and solution availability before reading values, and report results with units. For Problem 2, make the branching and pruning decisions yourself; a direct binary-optimizer call alone does not supply the required work.

For every written part, type LaTeX mathematics in Markdown or insert a clear photograph/scan of handwritten work, including the search tree. Keep each answer and its reasoning together, label subparts, and do not duplicate handwritten work in typed form. Implementations belong in code cells. The notebook explains image attachments and relative paths; see [Images and handwritten work](https://github.com/jlinderoth/isye524-students-julia/blob/main/docs/assignments.md#images-and-handwritten-work).

AI tools may help debug your own code, explain syntax or error messages, and critique your work. They should not replace constructing your formulation, implementation, or written solution. End with the required **collaboration and LLM-use statement**: name collaborators and tools/models, identify the specific assistance, explain how it helped you learn, and describe how you checked it. Explicitly state if you worked alone or used no LLM.

## Submit

Run the notebook from top to bottom, check for errors, and save it with results visible. Export with the course PDF task appropriate to your TeX installation. Inspect **`submissions/hw09.pdf`**, including mathematics, tables, outputs, and handwritten images. Upload that **single PDF to Gradescope** and mark which PDF pages belong to each problem. **You will not receive full marks unless you do.**

Keep a separate backup of `student-work/hw09/`, including the notebook and any external images. Git does not back up that folder.

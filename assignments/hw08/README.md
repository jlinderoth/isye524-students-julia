# Homework 08: Set covering, tours, and piecewise-linear costs

Due **Monday, November 9, 2026, at 11:59 p.m. (Madison time)**.

## Files and getting started

- `hw08.ipynb`: the assignment, all numerical data, and response areas. No separate data files are required.
- `README.md`: this overview; `README.html` contains the same instructions for Canvas.

Follow [Assignments and PDF Submission](https://github.com/jlinderoth/isye524-students-julia/blob/main/docs/canvas-assignment-workflow.md) for updating, copying, exporting, and backing up your work.

In VS Code, use **Tasks: Run Task** to run **ISyE 524: Update course repository**, then **ISyE 524: Start an assignment from its template**, entering **`hw08`**. Open **`student-work/hw08/hw08.ipynb`** and select the Julia 1.12 kernel. An existing working copy will not be overwritten. Later course updates do not automatically update your personal copy.

## Complete HW08

Complete all three problems:

1. **Apple deliveries:** enumerate all capacity-feasible customer groups and a shortest route for each. Formulate and solve a route-based set-covering model, then enforce exactly one delivery to each customer.
2. **Paint production:** formulate and solve a repeating production cycle using Miller–Tucker–Zemlin (MTZ). Report cleaning, blending, and total time, then demonstrate what fails without subtour elimination.
3. **Revisiting HW04 with shipping discounts:** return to the same ten-node, sixteen-arc distribution problem from HW04, Problem 2. Derive incremental piecewise-linear shipping costs, extend the earlier network model using lecture 17's multiple-choice formulation, and compare with the supplied HW04 shipment plan. All network data and the old plan are repeated in this notebook.

Write each mathematical formulation before its implementation. Use the supplied decision-variable definitions and Julia/JuMP with HiGHS from the course environment. Check solver status and solution availability before reading values, and report the requested results with units. Column generation, solver callbacks, and dynamic subtour cuts are not required.

For every written part, type LaTeX mathematics in Markdown or insert a clear photograph/scan of handwritten work. Keep each answer and its reasoning together, label subparts, and do not duplicate handwritten work in typed form. Implementations belong in code cells. The notebook explains image attachments and relative paths; see [Images and handwritten work](https://github.com/jlinderoth/isye524-students-julia/blob/main/docs/assignments.md#images-and-handwritten-work).

AI tools may help debug your own code, explain syntax or error messages, and critique your work. They should not replace constructing your formulation, implementation, or written solution. End with the required **collaboration and LLM-use statement**: name collaborators and tools/models, identify the specific assistance, explain how it helped you learn, and describe how you checked it. Explicitly state if you worked alone or used no LLM.

## Submit

Run the notebook from top to bottom, check for errors, and save it with results visible. Export with the course PDF task appropriate to your TeX installation. Inspect **`submissions/hw08.pdf`**, including mathematics, tables, outputs, and handwritten images. Upload that **single PDF to Gradescope** and mark which PDF pages belong to each problem. **You will not receive full marks unless you do.**

Keep a separate backup of `student-work/hw08/`, including the notebook and any external images. Git does not back up that folder.

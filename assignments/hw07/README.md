# Homework 07: Integer programming models and logic

Due **Monday, November 2, 2026, at 11:59 p.m. (Madison time)**.

## Files and getting started

- `hw07.ipynb`: the assignment, all numerical data, and response areas.
  No separate data files are required.
- `README.md`: this overview; `README.html` contains the same instructions for Canvas.

Follow [Assignments and PDF Submission](https://github.com/jlinderoth/isye524-students-julia/blob/main/docs/canvas-assignment-workflow.md) for updating, copying, exporting, and backing up your work.

In VS Code, use **Tasks: Run Task** to run **ISyE 524: Update course repository**, then **ISyE 524: Start an assignment from its template**, entering **`hw07`**. Open **`student-work/hw07/hw07.ipynb`** and select the Julia 1.12 kernel. An existing working copy will not be overwritten. Later course updates do not automatically update your personal copy.

## Complete HW07

Complete all three problems:

1. **Steam power with operating minimums:** formulate and solve a mixed-integer model with on/off operating ranges. Compare high- and low-demand plans, then assess what changes if the operating minimums are removed.
2. **Community projects with logical commitments:** maximize impact subject to a budget, prerequisites, incompatibilities, projects undertaken together, and a joint-program bonus. Extend the model with a supervisor fee triggered by an integer workload threshold.
3. **Auror posts and minimum set covering:** use the supplied coverage sets to minimize the number of posts protecting eight districts. Report locations and verify every district is protected.

Write each mathematical formulation before its implementation. Use the supplied decision-variable definitions and Julia/JuMP with HiGHS from the course environment. Check solver status and solution availability before reading values, and report the requested results with units. Problem 3 uses introductory set covering; no column generation or routing algorithm is required.

For every written part, type LaTeX mathematics in Markdown or insert a clear photograph/scan of handwritten work. Keep each answer and its reasoning together, label subparts, and do not duplicate handwritten work in typed form. Implementations belong in code cells. The notebook explains image attachments and relative paths; see [Images and handwritten work](https://github.com/jlinderoth/isye524-students-julia/blob/main/docs/assignments.md#images-and-handwritten-work).

AI tools may help debug your own code, explain syntax or error messages, and critique your work. They should not replace constructing your formulation, implementation, or written solution. End with the required **collaboration and LLM-use statement**: name collaborators and tools/models, identify the specific assistance, explain how it helped you learn, and describe how you checked it. Explicitly state if you worked alone or used no LLM.

## Submit

Run the notebook from top to bottom, check for errors, and save it with results visible. Export with the course PDF task appropriate to your TeX installation. Inspect **`submissions/hw07.pdf`**, including mathematics, tables, outputs, and handwritten images. Upload that **single PDF to Gradescope** and mark which PDF pages belong to each problem. **You will not receive full marks unless you do.**

Keep a separate backup of `student-work/hw07/`, including the notebook and any external images. Git does not back up that folder.

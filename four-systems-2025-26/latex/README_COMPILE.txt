PDF export (Technical Documentation)
=====================================

Prerequisites: A LaTeX distribution with pdflatex (TeX Live or MiKTeX).

From the project root (folder containing /latex):

  cd latex
  pdflatex -interaction=nonstopmode TECHNICAL_DOCUMENTATION.tex
  pdflatex -interaction=nonstopmode TECHNICAL_DOCUMENTATION.tex

The second run resolves the table of contents and cross-references.

Output: TECHNICAL_DOCUMENTATION.pdf in the same latex/ folder.

Optional (latexmk):
  cd latex
  latexmk -pdf -interaction=nonstopmode TECHNICAL_DOCUMENTATION.tex

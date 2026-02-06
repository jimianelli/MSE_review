.PHONY: help all pdf html clean preview

help:
	@echo "MSE Review - Alaska Groundfish Management"
	@echo "=========================================="
	@echo ""
	@echo "Available targets:"
	@echo "  make pdf      - Render PDF document"
	@echo "  make html     - Render HTML document"
	@echo "  make all      - Render both PDF and HTML"
	@echo "  make preview  - Open HTML preview in browser"
	@echo "  make clean    - Remove generated files"
	@echo ""

all: pdf html
	@echo "✓ Both PDF and HTML documents created!"

pdf:
	@echo "Rendering PDF..."
	quarto render MSE_Review_Alaska_Groundfish.qmd --to pdf
	@echo "✓ PDF created: ../docs/MSE_Review_Alaska_Groundfish.pdf"

html:
	@echo "Rendering HTML..."
	quarto render MSE_Review_Alaska_Groundfish.qmd --to html
	@echo "✓ HTML created: ../docs/MSE_Review_Alaska_Groundfish.html"

preview: html
	@echo "Opening preview..."
	open ../docs/MSE_Review_Alaska_Groundfish.html

clean:
	@echo "Cleaning up..."
	# Quarto project output goes to ../docs; clean the known outputs there.
	rm -f ../docs/MSE_Review_Alaska_Groundfish.html
	rm -f ../docs/MSE_Review_Alaska_Groundfish.pdf
	rm -rf .quarto/
	rm -rf *_files/
	@echo "✓ Clean complete"

watch:
	@echo "Watching for changes..."
	quarto preview MSE_Review_Alaska_Groundfish.qmd

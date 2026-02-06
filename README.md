# MSE Review: Alaska Groundfish Management

A Quarto-based research review examining Management Strategy Evaluation (MSE) applications in Alaska groundfish fisheries under the NPFMC management framework.

## Project Structure

```
MSE_review/
├── README.md                         # Repo overview (this file)
├── doc/                              # Source + build tooling
│   ├── MSE_Review_Alaska_Groundfish.qmd   # Main review document (Quarto)
│   ├── _quarto.yml                        # Quarto config (outputs → ../docs)
│   ├── Makefile                           # Build automation
│   ├── MSE_Bibliography.bib               # Main BibTeX bibliography (~33 entries)
│   ├── MSE_Bibliography_README.txt        # Bibliography documentation
│   ├── MSE_Bibliography_Summary.txt       # Literature summary
│   ├── MSE_Papers_Complete_List.txt       # Complete paper metadata
│   ├── figures/                           # Figures/scripts
│   └── (additional notes + supporting .qmd/.md)
├── docs/                             # Rendered outputs (HTML/PDF)
└── walters/                          # Related materials
```

## Quick Start

### 1. Render the Document

```bash
cd ~/_mymods/MSE_review/doc

# Render both PDF and HTML
make all

# Or render individually
make pdf    # Creates PDF
make html   # Creates HTML
```

### 2. Preview HTML Version

```bash
make preview    # Opens HTML in your default browser
```

### 3. Watch for Changes (Development)

```bash
make watch      # Continuously renders as you edit
```

## Document Overview

### Current Content (Draft)

The document is organized as a discussion/perspective piece (10-20 pages) covering:

1. **Introduction**
   - Background on Alaska groundfish management
   - Definition and rationale for MSE
   - Review objectives

2. **MSE Theory and Practice**
   - Conceptual framework
   - Operating models and Stock Synthesis
   - Harvest control rules
   - Global examples (Jack Mackerel, Tuna, Data-Limited)

3. **Alaska Groundfish Management Framework**
   - Current management structure and objectives
   - Current challenges (multiple stocks, environmental variability, balancing objectives)

4. **MSE Alignment with Alaska Management**
   - Potential benefits (HCR robustness, ecosystem considerations, uncertainty, planning)
   - Compatibility with existing management
   - Precedent and experience

5. **Barriers and Enabling Factors**
   - Resource requirements
   - Stakeholder communication
   - Institutional change
   - Successful applications and available tools

6. **Implementation Recommendations**
   - Phase 1 (Pilot, Years 1-2): Single stock application
   - Phase 2 (Expansion, Years 3-5): Multi-stock and ecosystem integration
   - Phase 3 (Integration, Years 5+): Operational integration

7. **Conclusions**

8. **Appendices**
   - Glossary of terms

## Building the Document

### Prerequisites

You'll need the following installed:

1. **Quarto** (latest version)
   ```bash
   # Install via Homebrew
   brew install quarto
   ```

2. **Pandoc** (usually comes with Quarto)
   ```bash
   quarto install tinytex  # For PDF rendering
   ```

3. **R** (for some Quarto features)
   ```bash
   # Already installed if you have R environment
   ```

### Build Commands

```bash
# Full build (both formats)
make all

# Just PDF
make pdf

# Just HTML
make html

# Clean generated files
make clean

# Watch for changes during editing
make watch

# Show available commands
make help
```

### Output Files

After building, outputs are written to the repo-level `docs/` directory (Quarto `output-dir: ../docs`):

```
docs/
├── MSE_Review_Alaska_Groundfish.pdf     # PDF version
└── MSE_Review_Alaska_Groundfish.html    # HTML version (self-contained)
```

## Customization

### Changing Output Formats

Edit `_quarto.yml` or the YAML header in `MSE_Review_Alaska_Groundfish.qmd` to adjust:

- PDF margins and spacing
- HTML theme and styling
- Citation format and style

### Adding Content Sections

The document uses standard Markdown:

```markdown
## Section Title
### Subsection
Regular paragraph text.

Citation example: [@Author2020]
```

### Bibliography Management

The document uses BibTeX citations through `MSE_Bibliography.bib`:

- ~33 entries covering MSE papers from 1989-2025
- Includes peer-reviewed articles, RFMO reports, and technical documents
- All papers located with full file paths in bibliography

To add papers:
1. Add entry to `MSE_Bibliography.bib`
2. Cite with `[@BibtexKey]` in document
3. Rebuild document

## References and Resources

### Key Papers in Bibliography

**Foundational:**
- @Punt2010 - Developing Management Procedures
- @Methot2013 - Stock Synthesis framework

**Recent Applications:**
- @Carruthers2019 - Using MSE to establish indicators (7 papers in 2019 CJFAS special issue)
- @Goethel2019 - MSE recent advances

### External Resources

- [NPFMC FMPs](https://www.npfmc.org/library/fmps-feps/)
- [Stock Synthesis Documentation](https://nmfs-stock-synthesis.github.io/doc/)
- [DLMtool MSE Package](https://dlmtool.github.io/dlmtool/)

### Supporting Documents in Project

1. **MSE_Bibliography_README.txt**
   - How to use the BibTeX file
   - Reference manager integration instructions

2. **MSE_Bibliography_Summary.txt**
   - Research landscape analysis
   - Temporal trends and key researchers
   - Paper organization by research area

3. **MSE_Papers_Complete_List.txt**
   - Detailed metadata for each paper
   - Full file paths to all 29 papers
   - Organized reference guide

## Writing Tips

### Quarto Markdown Syntax

```markdown
# Heading 1
## Heading 2
### Heading 3

**Bold text** and *italic text*

- Bullet list
  - Nested item

1. Numbered list
2. Second item

[Link text](https://example.com)

![Image caption](path/to/image.png)

`inline code`

> Block quote

[@CitationKey]  # Citation
```

### Code Blocks (if adding analyses)

```{r}
# R code block
data <- read.csv("data.csv")
summary(data)
```

```{python}
# Python code block
import pandas as pd
df = pd.read_csv("data.csv")
print(df.head())
```

## Troubleshooting

### PDF rendering fails

```bash
# Install TinyTeX
quarto install tinytex
```

### Bibliography not appearing

- Ensure `MSE_Bibliography.bib` is in the same directory as `.qmd`
- Check that bibliography file name matches in YAML header
- Rebuild with `make clean && make pdf`

### HTML won't open in browser

```bash
# Manually open the file
open ../docs/MSE_Review_Alaska_Groundfish.html
```

### Quarto not found

```bash
# Check installation
quarto --version

# If not installed
brew install quarto
```

## Next Steps

### Suggested Edits and Expansion

1. **Add Alaska-specific context**
   - Details from NPFMC FMPs
   - Current stock assessment practices
   - Specific management challenges

2. **Expand MSE examples**
   - More detail on successful applications
   - Alaska-specific case studies
   - Economic impact analyses

3. **Add figures and tables**
   - Management decision timeline
   - Example harvest control rule curves
   - Comparison of different HCRs
   - Alaska stock status summary

4. **Stakeholder engagement section**
   - How to communicate MSE results
   - Council decision-making process
   - Industry and community considerations

5. **Implementation timeline**
   - Detailed resource requirements
   - Specific actions for each phase
   - Key decision points

### Publishing Considerations

For submission to journals or policy documents:
- Verify all citations are formatted correctly
- Add references to specific FMP documents
- Include NPFMC council meeting references
- Consider adding acknowledgments
- Review for consistency with NOAA style guides

## Version Control

This project is suitable for version control with Git:

```bash
git init
git add .
git commit -m "Initial MSE review draft"

# Useful to exclude from Git
# Add to .gitignore:
_output/
.quarto/
*_files/
*.pdf
*.html
```

## Contact and Questions

For questions about:
- **MSE concepts**: See MSE_Bibliography_README.txt
- **Quarto syntax**: Visit [quarto.org](https://quarto.org)
- **Alaska groundfish management**: See NPFMC resources at npfmc.org

---

**Document Status**: Draft - In Progress
**Last Updated**: February 5, 2026
**Author**: Jim Ianelli
**Project Location**: ~/_mymods/MSE_review/doc/

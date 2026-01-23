# Quick Start Guide - MSE Review Document

## 30-Second Setup

```bash
cd ~/._mymods/MSE_review/doc

# Build PDF and HTML
make all

# View HTML version
make preview
```

## What You Have

✅ **Complete Research Document Template**
- Main Quarto file: `MSE_Review_Alaska_Groundfish.qmd`
- Structured 10-20 page discussion/perspective piece
- Ready to render as PDF or HTML
- Integrated with your MSE bibliography (29 papers)

✅ **Build Tools**
- `Makefile` - Simple `make` commands for building
- `_quarto.yml` - Configuration for PDF and HTML output
- `README.md` - Comprehensive documentation

✅ **Bibliography**
- `MSE_Bibliography.bib` - 29 BibTeX entries
- All papers cited and ready to use
- Full file paths included

## Your Next Steps

### 1. Build the Draft (2 minutes)
```bash
cd ~/._mymods/MSE_review/doc
make all
```

### 2. Review What You Have
- Open `_output/MSE_Review_Alaska_Groundfish.html` in browser
- Or `_output/MSE_Review_Alaska_Groundfish.pdf` on your computer

### 3. Edit and Customize
Edit `MSE_Review_Alaska_Groundfish.qmd` to:
- Add Alaska-specific FMP details
- Expand with more examples
- Add figures and tables
- Personalize with your insights

### 4. Rebuild as You Edit
```bash
make watch    # Watches for changes and auto-renders
```

Or rebuild after edits:
```bash
make pdf      # Just PDF
make html     # Just HTML
make all      # Both
```

## Key Files

| File | Purpose |
|------|---------|
| `MSE_Review_Alaska_Groundfish.qmd` | Main document (edit this!) |
| `MSE_Bibliography.bib` | Bibliography citations |
| `_quarto.yml` | Render configuration |
| `Makefile` | Build automation |
| `README.md` | Full documentation |
| `_output/` | Generated PDF and HTML |

## Common Tasks

### Add a new section
```markdown
## Your New Section Title

Your content here. Citation example: [@Author2020]
```

### Cite a paper
In text: `[@Punt2010]`

### Add a figure
```markdown
![Figure caption](path/to/figure.png)
```

### Add a table
```markdown
| Column 1 | Column 2 |
|----------|----------|
| Data 1   | Data 2   |
```

## Requirements

Make sure you have these installed:

```bash
# Check Quarto
quarto --version

# If not installed
brew install quarto
```

That's it! Quarto handles everything else.

## Troubleshooting

**"Command not found: quarto"**
```bash
brew install quarto
```

**PDF won't render**
```bash
quarto install tinytex
make pdf
```

**Want to see changes live?**
```bash
make watch    # Renders as you type
```

## Document Structure

Your document has these sections:

1. **Introduction** - Alaska groundfish management background
2. **MSE Theory** - What is MSE and how it works
3. **Alaska Framework** - Current management system
4. **Alignment** - How MSE fits with Alaska
5. **Barriers & Factors** - Challenges and opportunities
6. **Recommendations** - Phased implementation plan
7. **Conclusions** - Summary and next steps

## Where to Add Content

**Easy additions:**
- Edit existing sections (Introduction, Conclusions)
- Add more examples in MSE Theory section
- Expand Recommendations with details

**Need research?**
- Check `MSE_Bibliography_Summary.txt` for paper summaries
- Review `MSE_Papers_Complete_List.txt` for full metadata
- Find papers in `MSE_Bibliography_README.txt`

## Output Formats

After `make all`, you'll have:

- **PDF**: `_output/MSE_Review_Alaska_Groundfish.pdf`
  - Professional formatting
  - Ready for printing or submission
  - All citations properly formatted

- **HTML**: `_output/MSE_Review_Alaska_Groundfish.html`
  - Interactive and web-friendly
  - Navigation sidebar
  - Self-contained (includes all resources)

## Tips

📝 **Writing**: Focus on content first, formatting is automatic
🔗 **Citations**: Use `[@BibtexKey]` format - Quarto handles the rest
💻 **Testing**: Use `make preview` to see how it looks in HTML
📊 **Data**: Can embed R/Python code if you want to add analyses
📱 **Responsive**: HTML automatically adapts to different screen sizes

## Getting Help

- **Quarto docs**: https://quarto.org
- **Bibliography issues**: See `MSE_Bibliography_README.txt`
- **Alaska groundfish**: Visit https://www.npfmc.org
- **Markdown syntax**: https://quarto.org/docs/authoring/markdown-basics.html

---

**Ready to start?**

```bash
cd ~/._mymods/MSE_review/doc
make all
open _output/MSE_Review_Alaska_Groundfish.html
```

Then edit `MSE_Review_Alaska_Groundfish.qmd` and rebuild with `make all`!

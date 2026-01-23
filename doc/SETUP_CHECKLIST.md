# Setup and First-Time Build Checklist

## ✅ Project Setup Complete

Your MSE review project has been created with all necessary files. Here's what to check:

### Files Created

- [x] `MSE_Review_Alaska_Groundfish.qmd` - Main Quarto document
- [x] `_quarto.yml` - Build configuration
- [x] `Makefile` - Build automation
- [x] `MSE_Bibliography.bib` - Bibliography (29 papers)
- [x] `README.md` - Full documentation
- [x] `QUICKSTART.md` - Quick start guide
- [x] `SETUP_CHECKLIST.md` - This file

### Bibliography Files
- [x] `MSE_Bibliography_README.txt` - How to use the bibliography
- [x] `MSE_Bibliography_Summary.txt` - Literature summary
- [x] `MSE_Papers_Complete_List.txt` - Complete paper metadata

---

## 🚀 First-Time Build (Do This First!)

### Step 1: Install Prerequisites

Check if you have Quarto installed:

```bash
quarto --version
```

If not installed:

```bash
brew install quarto
```

### Step 2: Navigate to Project

```bash
cd ~/._mymods/MSE_review/doc
```

### Step 3: Build the Document

```bash
make all
```

Expected output:
```
Rendering PDF...
Rendering HTML...
✓ PDF created: _output/MSE_Review_Alaska_Groundfish.pdf
✓ HTML created: _output/MSE_Review_Alaska_Groundfish.html
```

### Step 4: View the Results

```bash
# View HTML in browser
make preview

# Or manually open
open _output/MSE_Review_Alaska_Groundfish.html

# Or view PDF
open _output/MSE_Review_Alaska_Groundfish.pdf
```

---

## 📝 Now You Can:

### Review the Draft
- [ ] Read through the entire document
- [ ] Check that all sections are present
- [ ] Verify bibliography is properly formatted
- [ ] Note sections you want to expand

### Start Editing
- [ ] Open `MSE_Review_Alaska_Groundfish.qmd` in your text editor
- [ ] Make a small edit to test the workflow
- [ ] Save the file
- [ ] Run `make all` to rebuild
- [ ] Verify your changes appear in the output

### Expand Content
- [ ] Add Alaska-specific FMP details
- [ ] Add case studies from your research
- [ ] Insert figures and tables
- [ ] Add more examples from the bibliography
- [ ] Expand implementation recommendations

---

## 🔄 Workflow for Editing

### Quick Edit Cycle

```bash
# Option 1: Quick rebuild after edits
vim MSE_Review_Alaska_Groundfish.qmd    # Edit
make all                                  # Rebuild
open _output/MSE_Review_Alaska_Groundfish.html  # View

# Option 2: Live preview while editing
make watch    # Terminal 1: Watches for changes
# In Terminal 2: Edit the .qmd file
# Changes auto-render as you save!
```

### Testing Changes

After making edits, verify:
- [ ] Document builds without errors (`make all`)
- [ ] PDF renders correctly
- [ ] HTML displays properly
- [ ] Citations are working (check bibliography)
- [ ] Formatting looks professional

---

## 📚 Using Your Bibliography

### How to Cite Papers

In your document, use this syntax:

```markdown
As shown by recent research [@Punt2010], MSE frameworks...

Multiple citations [@Carruthers2019; @Methot2013] demonstrate...

Narrative citation: @Goethel2019 provides examples...
```

### All Available Papers

Your bibliography includes 29 papers. Check `MSE_Papers_Complete_List.txt` for:
- Full author names
- Complete titles
- Publication years
- Journal names
- Subject matter

### Adding New Papers

To add papers to your bibliography:

1. Add a BibTeX entry to `MSE_Bibliography.bib`
2. Use format from existing entries
3. Cite with `[@NewKey]`
4. Rebuild with `make all`

---

## 🎯 Suggested First Edits

### Easy Wins (Start Here)

1. **Introduction**
   - Add specific NPFMC FMP references
   - Include current stock assessment details
   - Add Alaska-specific examples

2. **Examples**
   - Expand the Alaska groundfish section
   - Add details about Pollock, Cod, Halibut management
   - Reference specific SAFE reports

3. **Implementation Section**
   - Make it more specific to Alaska
   - Add real budget estimates
   - Include specific council meetings/timelines

### Medium Effort

4. **Add Figures**
   - Harvest control rule curves
   - Stock status timeline
   - Alaska groundfish distribution map

5. **Expand Case Studies**
   - Jack Mackerel example (already in doc)
   - Add Alaska-specific case study
   - Include economic impact analysis

### Challenging But Valuable

6. **Add Data Analysis**
   - Embed R code to analyze papers
   - Create comparison matrices
   - Show research trends

7. **Stakeholder Perspectives**
   - Interview or survey results
   - Industry viewpoints
   - Community considerations

---

## 🛠️ Common Commands

```bash
# Build everything
make all

# Build just PDF
make pdf

# Build just HTML
make html

# Watch for changes (live editing)
make watch

# Preview HTML in browser
make preview

# Clean up generated files
make clean

# Show available commands
make help
```

---

## 📋 Recommended Reading Order

Before editing, read these in order:

1. **QUICKSTART.md** (2 minutes)
   - Get overview of what you have

2. **Your Draft Document** (10 minutes)
   - Read the rendered HTML or PDF
   - Get sense of structure

3. **MSE_Bibliography_Summary.txt** (5 minutes)
   - Understand the research landscape
   - See which papers are most relevant

4. **README.md** (5 minutes)
   - Learn customization options
   - Check troubleshooting section

5. **MSE_Papers_Complete_List.txt** (as needed)
   - Reference specific papers
   - Get metadata for expanded sections

---

## ✅ Quality Checklist Before Finalizing

When you're ready to finalize your document:

- [ ] All sections are written and reviewed
- [ ] Citations are complete and accurate
- [ ] Figures and tables are included
- [ ] PDF renders correctly
- [ ] HTML displays properly
- [ ] No broken links or references
- [ ] Spelling and grammar checked
- [ ] Formatting is consistent
- [ ] Bibliography is complete

---

## 🐛 Troubleshooting

### Build Fails

**Error: "Command not found: quarto"**
```bash
brew install quarto
```

**Error: "Can't find bibliography"**
- Verify `MSE_Bibliography.bib` is in same folder as `.qmd`
- Check filename in YAML header matches exactly

**Error about PDF rendering**
```bash
quarto install tinytex
make pdf
```

### Citation Issues

**Citation not appearing in output**
- Check spelling of citation key matches `[@Key]`
- Verify entry exists in `MSE_Bibliography.bib`
- Rebuild with `make clean && make all`

**Bibliography not showing**
- Ensure `bibliography: MSE_Bibliography.bib` in YAML
- Verify file exists in same directory
- Check that references are cited in text

### Display Issues

**HTML looks wrong**
- Try clearing browser cache (Cmd+Shift+R)
- Rebuild HTML: `make clean && make html`
- Try different browser

**PDF layout is off**
- Edit margin settings in `_quarto.yml`
- Adjust font size in YAML header
- Check for long code blocks or tables causing wrapping

---

## 📞 When You Need Help

### Quick Help
- Run `make help` for command reference
- Check README.md section matching your need
- See QUICKSTART.md for common tasks

### Quarto Questions
- Visit https://quarto.org
- Check https://quarto.org/docs/authoring/markdown-basics.html

### Content Questions
- Review MSE_Bibliography_Summary.txt
- Check MSE_Papers_Complete_List.txt for paper details
- Visit https://www.npfmc.org for Alaska groundfish info

---

## ✨ You're All Set!

Everything you need is ready. Now:

1. **Run your first build**: `make all`
2. **View the results**: `make preview`
3. **Start editing**: Open the `.qmd` file
4. **Rebuild as you edit**: `make all`

Good luck with your research! 🎉

---

**Project Path**: `~/._mymods/MSE_review/doc/`
**Main Document**: `MSE_Review_Alaska_Groundfish.qmd`
**Bibliography**: `MSE_Bibliography.bib` (29 papers)
**Build Tool**: `make` (run `make help` for commands)

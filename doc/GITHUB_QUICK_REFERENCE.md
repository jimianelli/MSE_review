# GitHub Repository - Quick Reference Commands

## One-Time Setup: Push to GitHub

### Option 1: Using GitHub CLI (Recommended - One Command)

```bash
cd ~/_mymods/MSE_review/doc

gh repo create MSE_repo \
  --public \
  --source=. \
  --remote=origin \
  --push \
  --description "Management Strategy Evaluation for Alaska Groundfish Fisheries"
```

**Result:** Repository created and pushed in one command!

### Option 2: Manual GitHub Web + Git

```bash
# 1. Create repo on GitHub at github.com/new
# 2. Set name to: MSE_review
# 3. Make it Public
# 4. Create repository

# 4. In terminal, add remote and push
cd ~/_mymods/MSE_review/doc
git branch -M main
git remote add origin https://github.com/jimianelli/MSE_review.git
git push -u origin main
```

---

## Daily Workflow: Make Changes & Push

### Step 1: Edit Your Document
```bash
cd ~/_mymods/MSE_review/doc
nano MSE_Review_Alaska_Groundfish.qmd
# Make your changes...
```

### Step 2: Build Locally (Optional - to test first)
```bash
make html
# or
quarto render MSE_Review_Alaska_Groundfish.qmd --to html
```

### Step 3: Preview (Optional)
```bash
quarto preview
```

### Step 4: Commit Changes
```bash
git add MSE_Review_Alaska_Groundfish.qmd
git commit -m "Update: Added climate adaptation section"
```

### Step 5: Push to GitHub
```bash
git push origin main
```

**That's it!** GitHub automatically rebuilds and deploys to:
🌐 **https://jimianelli.github.io/MSE_review**

---

## Common Commands

### Check Status
```bash
git status                    # See what's changed
git log --oneline            # See recent commits
```

### Commit & Push
```bash
# Single file
git add filename.qmd
git commit -m "Update: Description of changes"
git push

# Multiple files
git add .
git commit -m "Update: Description of changes"
git push

# Or all in one
git add . && git commit -m "Update: Changes" && git push
```

### Update Bibliography
```bash
# Add entries to MSE_Bibliography_EXPANDED.bib
nano MSE_Bibliography_EXPANDED.bib

# Commit and push
git add MSE_Bibliography_EXPANDED.bib
git commit -m "Add: New MSE papers from 2025"
git push
```

---

## For Colleagues: Contributing

### Fork & Contribute
```bash
# Colleague does this:
# 1. Click "Fork" on GitHub
# 2. Clone their fork
git clone https://github.com/their-username/MSE_review.git
cd MSE_review

# 3. Create a feature branch
git checkout -b add-climate-section

# 4. Make changes
nano MSE_Review_Alaska_Groundfish.qmd

# 5. Commit
git add .
git commit -m "Add: Climate adaptation section"

# 6. Push to their fork
git push origin add-climate-section

# 7. Open Pull Request on GitHub
# → You review and merge!
```

### Direct Collaboration
```bash
# If colleague has push access:

# Pull latest changes
git pull origin main

# Make changes
nano MSE_Review_Alaska_Groundfish.qmd

# Commit
git add .
git commit -m "Update: New content"

# Push
git push origin main
```

---

## Verify Deployment

### Check Build Status
1. Go to: https://github.com/jimianelli/MSE_review/actions
2. Click latest workflow run
3. See "build-and-deploy" status

### Check Live Site
- Main document: https://jimianelli.github.io/MSE_review
- Bibliography: https://jimianelli.github.io/MSE_review/bibliography.html

---

## Build Commands (Local)

```bash
cd ~/_mymods/MSE_review/doc

make pdf                     # Build PDF only
make html                    # Build HTML only
make all                     # Build both PDF & HTML
make preview                 # Open in browser
make clean                   # Delete outputs
make watch                   # Auto-rebuild on changes
```

---

## File Changes Quick Reference

### Editing Main Document
```bash
# Edit
nano MSE_Review_Alaska_Groundfish.qmd

# Push
git add MSE_Review_Alaska_Groundfish.qmd
git commit -m "Update: Your changes"
git push
```

### Adding Bibliography Entries
```bash
# Edit
nano MSE_Bibliography_EXPANDED.bib

# Push
git add MSE_Bibliography_EXPANDED.bib
git commit -m "Add: New papers"
git push
```

### All Edits at Once
```bash
git add .
git commit -m "Update: Multiple sections"
git push
```

---

## Troubleshooting

### Push Rejected
```bash
# Pull first if someone else pushed
git pull origin main
# Fix any conflicts
git add .
git commit -m "Merge: Resolve conflicts"
git push
```

### Check What's Uncommitted
```bash
git status
git diff                     # See exact changes
```

### Undo Last Commit (Before Push)
```bash
git reset --soft HEAD~1      # Keep changes
git reset --hard HEAD~1      # Discard changes
```

### See Commit History
```bash
git log --oneline -10        # Last 10 commits
git log --oneline --graph    # Visual graph
```

---

## Important Files

```
~/_mymods/MSE_review/doc/
├── .git/                    # Don't touch - Git history
├── MSE_Review_*.qmd         # Main documents (EDIT THESE)
├── MSE_Bibliography_EXPANDED.bib    # Bibliography (EDIT THIS)
├── .gitignore              # Don't edit
├── .github/workflows/*.yml # Don't edit (unless you know what you're doing)
└── _output/                # Build outputs (don't commit these)
```

---

## Share with Colleagues

**Live Document:** https://jimianelli.github.io/MSE_review

**Repository:** https://github.com/jimianelli/MSE_review

**To Contribute:** Fork the repo, make changes, open Pull Request

---

## One-Minute Summary

1. **First time:** `gh repo create MSE_review --public --source=. --remote=origin --push`
2. **Every update:** `git add . && git commit -m "Update: description" && git push`
3. **View live:** https://jimianelli.github.io/MSE_review
4. **GitHub deploys automatically** - no extra steps needed!

---

**That's it!** Your repository is ready for collaboration. 🚀


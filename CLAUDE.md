# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an academic research project repository for the CoMPhy Lab (Computational Physics Lab) containing LaTeX documents for various fluid dynamics research project proposals. The repository is structured as a collection of independent research projects, each with its own directory containing LaTeX source files, figures, and supporting materials.

## Key Commands

### Compilation
- **Compile all projects**: `./compile_all_recursive.sh` - Recursively finds and compiles all .tex files in subdirectories with proper bibliography processing
- **Clean temporary files**: `./compile_all_recursive.sh --clean` - Removes LaTeX auxiliary files while preserving PDFs and synctex files
- **Manual compilation**: In any project directory, run standard LaTeX workflow:
  ```bash
  pdflatex -synctex=1 filename.tex
  bibtex filename  # if bibliography present
  pdflatex -synctex=1 filename.tex
  pdflatex -synctex=1 filename.tex
  ```

### Bibliography Management
- **Centralized bibliography**: All projects use `_logosAndRef/references.bib` as the master bibliography file
- **Bibliography reference**: All .tex files should reference `../_logosAndRef/references.bib` using `\addbibresource{}`

## Architecture & File Structure

### Project Organization
The repository follows a **modular project-based structure** where each research topic has its own directory:

- **Individual project directories** (e.g., `BubbleBursting_NonNewtonian/`, `DropImpact/`, etc.)
- **Shared resources** in `_logosAndRef/` (logos, master bibliography)
- **Template system** in `_Template/` for creating new projects

### File Naming Conventions
Each project directory contains:
- **Main proposal files**: `ProjectName.tex` (detailed academic proposal with logos/headers)
- **Physics of Fluids submissions**: `YYYY_ProjectName-pof.tex` (simplified format for journal submissions)
- **Supporting files**: figures, images, and project-specific assets
- **Generated files**: PDFs, synctex files, and LaTeX auxiliary files

### Document Templates & Structure

**Template hierarchy**:
1. `_Template/template.tex` - Master template with full CoMPhy Lab branding
2. Project-specific `.tex` files inherit the template structure
3. Two document styles:
   - **Full proposal** (ProjectName.tex): Complete branding with Durham University/CoMPhy Lab logos
   - **Journal format** (*-pof.tex): Simplified format for Physics of Fluids submissions

**Document components**:
- **Standardized headers**: Durham University and CoMPhy Lab logos positioned using `textpos`
- **Contact tables**: "Collaborators" section with consistent formatting (`\textbf{Collaborators}`, `\textbf{E-mail}`, `\textbf{Based at}`)
- **Bibliography integration**: All documents use biblatex with authoryear-comp style

### Centralized Resource Management

**Master bibliography** (`_logosAndRef/references.bib`):
- Consolidated from 8+ individual project bibliography files
- Contains standardized journal string definitions (@string entries)
- Single source of truth for all citations across projects
- All .tex files reference via relative path: `../_logosAndRef/references.bib`

**Shared assets** (`_logosAndRef/`):
- `Durham-University.pdf` - University logo
- `CoMPhy-Lab.png` - Lab logo  
- `references.bib` - Master bibliography

### LaTeX Configuration Standards

**Package setup across projects**:
- **biblatex** with bibtex backend, authoryear-comp style, natbib compatibility
- **Hyperlinks** with MyBlue color scheme (rgb: 0,0.3,0.6)
- **Graphics** support via graphicx, subfig, wrapfig
- **Typography**: Sans-serif font family, single spacing, full page layout
- **Math/Science**: amsmath family, SIunits for scientific notation
- **Document structure**: Float placement, custom headers, absolute positioning

## Working with Projects

### Creating New Projects
1. Copy the `_Template/` directory structure
2. Modify template.tex with project-specific content
3. Update the collaborator table with appropriate team members
4. Add project-specific figures to the directory
5. Reference master bibliography: `\addbibresource{../_logosAndRef/references.bib}`

### Modifying Existing Projects
- **Bibliography**: Add new references to `_logosAndRef/references.bib` (never to individual project bib files)
- **Collaborator tables**: Follow the established format with "Collaborators", "E-mail", "Based at" columns
- **Dr. Vatsal Sanjay**: Should be listed first as primary contact with email `vatsal.sanjay@comphy-lab.org` and location `Ph255 (Rochester building)`

### Compilation Workflow
The `compile_all_recursive.sh` script handles the complete LaTeX workflow:
1. **Discovery**: Recursively finds all .tex files
2. **Directory-aware compilation**: Changes to each project directory for compilation
3. **Bibliography processing**: Automatically runs bibtex when .bib files are present
4. **Multi-pass compilation**: Three pdflatex passes for proper cross-references
5. **Cleanup**: Removes auxiliary files while preserving PDFs and synctex files
6. **Synchronization support**: Preserves .synctex.gz files for PDF-TeX editor sync

### Document Type Distinctions
- **Proposal documents** (e.g., `BubbleBursting.tex`): Full academic proposals with complete branding and detailed collaborator information
- **Journal submissions** (e.g., `2025_BubbleBursting-pof.tex`): Streamlined format suitable for Physics of Fluids journal submissions
- Both document types share the same master bibliography and maintain consistent citation formatting

## Research Context

This repository represents computational fluid dynamics research proposals focusing on:
- **Bubble dynamics**: Bursting, spreading, and interaction with surfaces
- **Drop impact**: Bouncing behavior, surface interactions, viscous effects  
- **Non-Newtonian flows**: Viscoelastic effects, yield-stress fluids
- **Industrial applications**: Inkjet printing, disease transmission, atomization
- **Numerical methods**: Direct numerical simulations using Basilisk C framework

The projects bridge fundamental physics research with practical applications, emphasizing open-source computational approaches and collaborative research methodologies.
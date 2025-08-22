#!/bin/bash

# Recursive LaTeX Compilation Script
# Finds and compiles all .tex files in subdirectories
# Preserves synctex files for PDF-TeX synchronization in editors

set -e  # Exit on any error

# Color codes for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Global variables
TOTAL_TEX_FILES=0
COMPILE_COUNT=0
SUCCESS_COUNT=0
FAILED_FILES=()
START_DIR=""

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print script header
print_header() {
    echo "========================================"
    print_status "$BLUE" "   Recursive LaTeX Compilation Script"
    print_status "$BLUE" "   Preserves synctex for PDF sync"
    echo "========================================"
    echo
}

# Function to find all .tex files recursively
find_tex_files() {
    print_status "$CYAN" "🔍 Scanning for .tex files..."
    
    # Use find to get all .tex files, excluding hidden directories
    local tex_files=()
    while IFS= read -r -d '' file; do
        tex_files+=("$file")
    done < <(find . -name "*.tex" -type f -not -path "*/.*" -print0)
    
    TOTAL_TEX_FILES=${#tex_files[@]}
    
    if [ $TOTAL_TEX_FILES -eq 0 ]; then
        print_status "$RED" "❌ No .tex files found in current directory or subdirectories"
        exit 1
    fi
    
    print_status "$GREEN" "📁 Found $TOTAL_TEX_FILES .tex file(s):"
    for file in "${tex_files[@]}"; do
        print_status "$YELLOW" "   → $file"
    done
    echo
}

# Function to compile a tex file in its directory
compile_tex_in_dir() {
    local tex_file_path="$1"
    local dir_path="$(dirname "$tex_file_path")"
    local tex_filename="$(basename "$tex_file_path")"
    local basename="${tex_filename%.tex}"
    
    print_status "$PURPLE" "📂 Entering directory: $dir_path"
    print_status "$BLUE" "📄 Compiling $tex_filename..."
    ((COMPILE_COUNT++))
    
    # Change to the directory containing the tex file
    local original_dir="$PWD"
    if ! cd "$dir_path"; then
        print_status "$RED" "❌ Error: Cannot change to directory $dir_path"
        FAILED_FILES+=("$tex_file_path")
        return 1
    fi
    
    # Check if tex file exists (should exist since we found it, but double-check)
    if [ ! -f "$tex_filename" ]; then
        print_status "$RED" "❌ Error: $tex_filename not found in $dir_path"
        FAILED_FILES+=("$tex_file_path")
        cd "$original_dir"
        return 1
    fi
    
    # First pdflatex run with synctex
    print_status "$YELLOW" "   → Running pdflatex (1/3)..."
    if ! pdflatex -synctex=1 -interaction=nonstopmode "$tex_filename" > /dev/null 2>&1; then
        print_status "$RED" "❌ Error: First pdflatex run failed for $tex_filename"
        FAILED_FILES+=("$tex_file_path")
        cd "$original_dir"
        return 1
    fi
    
    # Run bibtex if .bib files exist in current directory
    if ls ./*.bib >/dev/null 2>&1; then
        print_status "$YELLOW" "   → Running bibtex..."
        if ! bibtex "$basename" > /dev/null 2>&1; then
            print_status "$YELLOW" "⚠️  Warning: bibtex failed for $basename (may be expected if no citations)"
        fi
    fi
    
    # Second pdflatex run
    print_status "$YELLOW" "   → Running pdflatex (2/3)..."
    if ! pdflatex -synctex=1 -interaction=nonstopmode "$tex_filename" > /dev/null 2>&1; then
        print_status "$RED" "❌ Error: Second pdflatex run failed for $tex_filename"
        FAILED_FILES+=("$tex_file_path")
        cd "$original_dir"
        return 1
    fi
    
    # Third pdflatex run for final references
    print_status "$YELLOW" "   → Running pdflatex (3/3)..."
    if ! pdflatex -synctex=1 -interaction=nonstopmode "$tex_filename" > /dev/null 2>&1; then
        print_status "$RED" "❌ Error: Final pdflatex run failed for $tex_filename"
        FAILED_FILES+=("$tex_file_path")
        cd "$original_dir"
        return 1
    fi
    
    # Check if PDF was generated
    if [ -f "${basename}.pdf" ]; then
        print_status "$GREEN" "✅ Successfully compiled $tex_filename → ${basename}.pdf"
        ((SUCCESS_COUNT++))
        
        # Clean temporary files
        clean_temp_files "$basename"
        
        cd "$original_dir"
        return 0
    else
        print_status "$RED" "❌ Error: PDF not generated for $tex_filename"
        FAILED_FILES+=("$tex_file_path")
        cd "$original_dir"
        return 1
    fi
}

# Function to clean temporary files (preserving synctex and PDF)
clean_temp_files() {
    local basename="$1"
    
    print_status "$YELLOW" "🧹 Cleaning temporary files for $basename..."
    
    # Array of extensions to remove
    local temp_extensions=(
        "aux" "log" "out" "toc" "lof" "lot" "bbl" "blg" 
        "nav" "snm" "vrb" "dvi" "fdb_latexmk" "fls" 
        "ps" "eps" "eepic" "figlist" "makefile" "idx" 
        "ind" "ilg" "glo" "gls" "glg" "acn" "acr" "alg"
        "run.xml"  # Added for biblatex
    )
    
    local removed_count=0
    for ext in "${temp_extensions[@]}"; do
        if [ -f "${basename}.${ext}" ]; then
            rm -f "${basename}.${ext}"
            ((removed_count++))
        fi
    done
    
    # Also clean .blx.bib files (biblatex auxiliary files)
    if [ -f "${basename}-blx.bib" ]; then
        rm -f "${basename}-blx.bib"
        ((removed_count++))
    fi
    
    if [ $removed_count -gt 0 ]; then
        print_status "$GREEN" "   ✓ Removed $removed_count temporary file(s)"
    else
        print_status "$YELLOW" "   → No temporary files to clean"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Recursively finds and compiles all .tex files in subdirectories."
    echo
    echo "OPTIONS:"
    echo "  -h, --help     Show this help message"
    echo "  -c, --clean    Clean temporary files only (no compilation)"
    echo "  -v, --verbose  Show detailed compilation output (not implemented)"
    echo
    echo "EXAMPLES:"
    echo "  $0                    # Compile all .tex files recursively"
    echo "  $0 --clean           # Clean temporary files in all subdirectories"
}

# Function to clean all temporary files recursively
clean_all_temp_recursive() {
    print_status "$YELLOW" "🧹 Cleaning all temporary files recursively..."
    
    local cleaned_dirs=0
    
    # Find all directories containing .tex files
    while IFS= read -r -d '' tex_file; do
        local dir_path="$(dirname "$tex_file")"
        local tex_filename="$(basename "$tex_file")"
        local basename="${tex_filename%.tex}"
        
        print_status "$CYAN" "📂 Cleaning in: $dir_path"
        
        # Change to directory and clean
        local original_dir="$PWD"
        if cd "$dir_path"; then
            clean_temp_files "$basename"
            ((cleaned_dirs++))
            cd "$original_dir"
        else
            print_status "$RED" "❌ Error: Cannot access directory $dir_path"
        fi
    done < <(find . -name "*.tex" -type f -not -path "*/.*" -print0)
    
    if [ $cleaned_dirs -eq 0 ]; then
        print_status "$YELLOW" "No .tex files found to clean"
    else
        print_status "$GREEN" "✅ Cleaned temporary files in $cleaned_dirs location(s)"
    fi
}

# Function to print final summary
print_summary() {
    echo
    echo "========================================"
    print_status "$BLUE" "           COMPILATION SUMMARY"
    echo "========================================"
    
    if [ $COMPILE_COUNT -eq 0 ]; then
        print_status "$YELLOW" "No files were compiled"
        return
    fi
    
    print_status "$GREEN" "✅ Successfully compiled: $SUCCESS_COUNT/$TOTAL_TEX_FILES files"
    
    if [ ${#FAILED_FILES[@]} -gt 0 ]; then
        print_status "$RED" "❌ Failed files:"
        for file in "${FAILED_FILES[@]}"; do
            print_status "$RED" "   - $file"
        done
    fi
    
    echo
    print_status "$BLUE" "📁 Preserved files in each directory:"
    print_status "$BLUE" "   • PDF files (compiled output)"
    print_status "$BLUE" "   • .synctex.gz files (for editor sync)"
    print_status "$BLUE" "   • .tex and .bib files (source)"
    
    if [ $SUCCESS_COUNT -gt 0 ]; then
        echo
        print_status "$GREEN" "🔗 PDF-TeX synchronization enabled for:"
        print_status "$GREEN" "   VS Code, Cursor, and other compatible editors"
    fi
    
    # Return to original directory
    if [ -n "$START_DIR" ] && [ "$START_DIR" != "$PWD" ]; then
        cd "$START_DIR"
        print_status "$CYAN" "📂 Returned to starting directory: $START_DIR"
    fi
}

# Main function
main() {
    local clean_only=false
    
    # Store starting directory
    START_DIR="$PWD"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--clean)
                clean_only=true
                shift
                ;;
            -v|--verbose)
                # Placeholder for future verbose mode
                print_status "$YELLOW" "⚠️  Verbose mode not yet implemented"
                shift
                ;;
            *)
                print_status "$RED" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_header
    
    # If clean only mode
    if [ "$clean_only" = true ]; then
        clean_all_temp_recursive
        exit 0
    fi
    
    # Find all .tex files
    find_tex_files
    
    local tex_files=()
    while IFS= read -r -d '' file; do
        tex_files+=("$file")
    done < <(find . -name "*.tex" -type f -not -path "*/.*" -print0)
    
    if [ ${#tex_files[@]} -eq 0 ]; then
        print_status "$RED" "❌ No .tex files found"
        exit 1
    fi
    
    # Compile each file in its directory
    local file_counter=0
    for tex_file in "${tex_files[@]}"; do
        ((file_counter++))
        echo
        print_status "$PURPLE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_status "$PURPLE" "Processing file $file_counter/$TOTAL_TEX_FILES"
        print_status "$PURPLE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        compile_tex_in_dir "$tex_file"
    done
    
    print_summary
    
    # Exit with error code if any compilation failed
    if [ ${#FAILED_FILES[@]} -gt 0 ]; then
        exit 1
    fi
    
    exit 0
}

# Run main function with all arguments
main "$@"
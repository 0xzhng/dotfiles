#!/bin/bash

# Debug mode - set to true to see detailed output
DEBUG=${DEBUG:-false}

# Only exit on undefined variables and pipe failures, handle errors manually
set -uo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Unicode symbols
CHECK="✓"
CROSS="✗"
ARROW="→"
STAR="★"
GEAR="⚙"

# Function to run commands with proper error handling
run_command() {
    local description="$1"
    shift
    
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "${CYAN}Running: $*${NC}"
        if "$@"; then
            echo -e "${GREEN}✓ Success${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed with exit code $?${NC}"
            return 1
        fi
    else
        if "$@" > /dev/null 2>&1; then
            return 0
        else
            local exit_code=$?
            print_error "$description failed (exit code: $exit_code)"
            echo "Command: $*"
            echo "Try running with DEBUG=true ./install.sh to see detailed output"
            return 1
        fi
    fi
}

print_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                        DOTFILES INSTALLER                           ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║                                                                      ║${NC}"
    echo -e "${CYAN}║${YELLOW}  Setting up your development environment with all the tools you need  ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}                                                                      ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}  Tip: Run with ${YELLOW}DEBUG=true ./install.sh${WHITE} for detailed output       ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${PURPLE}${BOLD}${GEAR} $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

print_info() {
    echo -e "${CYAN}${ARROW} $1${NC}"
}

print_progress() {
    local current=$1
    local total=$2
    local task=$3
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 5))
    local empty=$((20 - filled))
    
    printf "\r${BLUE}Progress: [${GREEN}"
    printf "%*s" $filled | tr ' ' '█'
    printf "${WHITE}"
    printf "%*s" $empty | tr ' ' '░'
    printf "${BLUE}] ${percentage}%% - ${task}${NC}"
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux"* ]]; then
        if command -v lsb_release &> /dev/null; then
            local distro=$(lsb_release -si 2>/dev/null || echo "unknown")
            if [[ "$distro" == "Ubuntu" ]]; then
                echo "ubuntu"
            else
                print_warning "Detected Linux distribution: $distro, treating as Ubuntu"
                echo "ubuntu"
            fi
        else
            print_warning "Cannot detect Linux distribution, defaulting to Ubuntu"
            echo "ubuntu"
        fi
    else
        print_warning "Unknown operating system: $OSTYPE, defaulting to Ubuntu"
        echo "ubuntu"
    fi
}

refresh_shell_env() {
    # Source bashrc if it exists
    if [[ -f ~/.bashrc ]]; then
        set +u
        source ~/.bashrc &> /dev/null || true
        set -u
    fi
    
    # Source profile if it exists
    if [[ -f ~/.profile ]]; then
        set +u
        source ~/.profile &> /dev/null || true
        set -u
    fi
    
    # Refresh Homebrew environment if on macOS
    if [[ "$1" == "macos" ]]; then
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)" &> /dev/null || true
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)" &> /dev/null || true
        fi
    fi
    
    # Source Cargo environment and add to PATH
    if [[ -f ~/.cargo/env ]]; then
        set +u
        source ~/.cargo/env &> /dev/null || true
        set -u
    fi
    
    # Add Cargo to PATH if directory exists
    if [[ -d ~/.cargo/bin ]]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    
    # Add Bun to PATH if directory exists
    if [[ -d ~/.bun/bin ]]; then
        export PATH="$HOME/.bun/bin:$PATH"
    fi
}

check_homebrew() {
    if [[ "$1" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            print_success "Homebrew is installed"
            return 0
        else
            print_info "Homebrew not found - will install"
            return 1
        fi
    fi
    return 0
}

install_homebrew() {
    print_info "Installing Homebrew..."
    if ! run_command "Homebrew installation" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        print_error "Homebrew installation failed"
        return 1
    fi
    
    # Set up Homebrew environment for both Intel and Apple Silicon
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        print_error "Homebrew installation failed - brew command not found"
        return 1
    fi
    
    print_success "Homebrew installed successfully"
}

check_essential_tools() {
    local missing_tools=()
    
    if [[ "$1" != "macos" ]]; then
        if ! command -v curl &> /dev/null; then
            missing_tools+=("curl")
        fi
        if ! command -v unzip &> /dev/null; then
            missing_tools+=("unzip")
        fi
        if ! command -v git &> /dev/null; then
            missing_tools+=("git")
        fi
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_info "Essential tools missing: ${missing_tools[*]} - will install"
        return 1
    fi
    
    print_success "Essential tools (curl, unzip, git) are installed"
    return 0
}

install_essential_tools() {
    print_info "Installing essential tools..."
    if [[ "$1" == "macos" ]]; then
        if ! command -v curl &> /dev/null; then
            print_error "curl not found on macOS - please install Xcode Command Line Tools"
            exit 1
        fi
    else
        sudo apt update > /dev/null 2>&1
        sudo apt install -y curl unzip git > /dev/null 2>&1
    fi
    print_success "Essential tools installed"
}

check_stow() {
    if command -v stow &> /dev/null; then
        print_success "GNU Stow is installed"
        return 0
    else
        print_info "GNU Stow not found - will install"
        return 1
    fi
}

install_stow() {
    print_info "Installing GNU Stow..."
    if [[ "$1" == "macos" ]]; then
        brew install stow > /dev/null 2>&1
    else
        sudo apt update > /dev/null 2>&1
        sudo apt install -y stow > /dev/null 2>&1
    fi
    
    refresh_shell_env "$1"
    
    if ! command -v stow &> /dev/null; then
        print_error "GNU Stow installation failed"
        exit 1
    fi
    
    print_success "GNU Stow installed"
}

check_python() {
    if ! command -v python3 &> /dev/null; then
        print_info "Python3 not found - will install"
        return 1
    fi
    
    if ! command -v pip3 &> /dev/null; then
        print_info "Python3 found, but pip3 missing - will install pip"
        return 2
    fi
    
    print_success "Python3 and pip3 are installed"
    return 0
}

install_python() {
    print_info "Installing Python..."
    if [[ "$1" == "macos" ]]; then
        brew install python > /dev/null 2>&1
    else
        sudo apt update > /dev/null 2>&1
        sudo apt install -y python3 python3-pip > /dev/null 2>&1
    fi
    
    refresh_shell_env "$1"
    
    if ! command -v python3 &> /dev/null; then
        print_error "Python installation failed"
        exit 1
    fi
    
    print_success "Python installed"
}

install_pip() {
    print_info "Installing pip..."
    if [[ "$1" == "macos" ]]; then
        python3 -m ensurepip --upgrade > /dev/null 2>&1
    else
        sudo apt update > /dev/null 2>&1
        sudo apt install -y python3-pip > /dev/null 2>&1
    fi
    
    refresh_shell_env "$1"
    
    if ! command -v pip3 &> /dev/null; then
        print_error "pip installation failed"
        exit 1
    fi
    
    print_success "pip installed"
}

check_node() {
    if ! command -v node &> /dev/null; then
        print_info "Node.js not found - will install"
        return 1
    fi
    
    if ! command -v npm &> /dev/null; then
        print_info "Node.js found, but npm missing - will install"
        return 2
    fi
    
    print_success "Node.js and npm are installed"
    return 0
}

install_node() {
    print_info "Installing Node.js and npm..."
    if [[ "$1" == "macos" ]]; then
        brew install node > /dev/null 2>&1
    else
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - > /dev/null 2>&1
        sudo apt install -y nodejs > /dev/null 2>&1
    fi
    
    refresh_shell_env "$1"
    
    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
        print_error "Node.js installation failed"
        exit 1
    fi
    
    print_success "Node.js and npm installed"
}

check_build_tools() {
    if [[ "$1" == "macos" ]]; then
        if ! xcode-select -p &> /dev/null; then
            print_info "Xcode Command Line Tools not found - will install"
            return 1
        fi
        print_success "Xcode Command Line Tools are installed"
    else
        if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
            print_info "Build tools not found - will install build-essential"
            return 1
        fi
        print_success "Build tools are installed"
    fi
    return 0
}

install_build_tools() {
    if [[ "$1" == "macos" ]]; then
        print_info "Installing Xcode command line tools..."
        xcode-select --install
        print_warning "Please wait for Xcode Command Line Tools installation to complete, then re-run this script"
        exit 0
    else
        print_info "Installing build tools..."
        sudo apt update > /dev/null 2>&1
        sudo apt install -y build-essential > /dev/null 2>&1
        
        if ! command -v gcc &> /dev/null; then
            print_error "Build tools installation failed"
            exit 1
        fi
        
        print_success "Build tools installed"
    fi
}

check_rust() {
    if ! command -v rustc &> /dev/null; then
        print_info "Rust not found - will install"
        return 1
    fi
    
    if ! command -v cargo &> /dev/null; then
        print_info "Rust found, but Cargo missing - will install"
        return 2
    fi
    
    print_success "Rust and Cargo are installed"
    return 0
}

install_rust() {
    print_info "Installing Rust and Cargo..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y > /dev/null 2>&1
    
    # Immediately refresh environment to make Rust available
    refresh_shell_env "$1"
    
    # Verify installation
    if command -v rustc &> /dev/null && command -v cargo &> /dev/null; then
        print_success "Rust and Cargo installed ($(rustc --version | cut -d' ' -f2))"
    else
        print_error "Rust installation failed - commands not available after environment refresh"
        exit 1
    fi
}

check_bun() {
    if ! command -v bun &> /dev/null; then
        print_info "Bun not found - will install"
        return 1
    fi
    
    print_success "Bun is installed"
    return 0
}

install_bun() {
    print_info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash > /dev/null 2>&1
    
    # Immediately refresh environment to make Bun available
    refresh_shell_env "$1"
    
    # Verify installation
    if command -v bun &> /dev/null; then
        print_success "Bun installed ($(bun --version))"
    else
        print_error "Bun installation failed - command not available after environment refresh"
        exit 1
    fi
}

check_tmux() {
    if ! command -v tmux &> /dev/null; then
        print_info "tmux not found - will install"
        return 1
    fi
    
    print_success "tmux is installed"
    return 0
}

install_tmux() {
    print_info "Installing tmux..."
    if [[ "$1" == "macos" ]]; then
        brew install tmux > /dev/null 2>&1
    else
        sudo apt update > /dev/null 2>&1
        sudo apt install -y tmux > /dev/null 2>&1
    fi
    
    refresh_shell_env "$1"
    
    if ! command -v tmux &> /dev/null; then
        print_error "tmux installation failed"
        exit 1
    fi
    
    print_success "tmux installed"
}

fix_tmux_symlinks() {
    print_info "Fixing tmux configuration symlinks..."
    
    # Check if ~/.tmux.conf is a symlink or regular file
    if [[ -L ~/.tmux.conf ]]; then
        local current_target=$(readlink ~/.tmux.conf 2>/dev/null || echo "")
        local expected_target="$HOME/dotfiles/common/.config/tmux/tmux.conf"
        
        if [[ "$current_target" == "$expected_target" ]] || [[ "$current_target" == *"dotfiles/common/.config/tmux/tmux.conf" ]]; then
            print_success "tmux config symlink already correct"
            return 0
        else
            print_warning "tmux config symlink points to wrong location: $current_target"
            rm -f ~/.tmux.conf
        fi
    elif [[ -f ~/.tmux.conf ]]; then
        print_warning "~/.tmux.conf is a regular file, backing up and replacing with symlink"
        mv ~/.tmux.conf ~/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # Create proper symlink
    if [[ -f "$PWD/common/.config/tmux/tmux.conf" ]]; then
        ln -sf "$PWD/common/.config/tmux/tmux.conf" ~/.tmux.conf
        print_success "Created tmux config symlink"
    else
        print_error "tmux.conf not found in dotfiles"
        return 1
    fi
}

clean_plugin_conflicts() {
    print_info "Cleaning plugin conflicts..."
    
    # Remove plugins from dotfiles if they exist (TPM should manage these)
    if [[ -d "$PWD/common/.config/tmux/plugins" ]]; then
        print_warning "Removing plugins from dotfiles (TPM will manage these)"
        rm -rf "$PWD/common/.config/tmux/plugins"
    fi
    
    # Remove any conflicting stowed plugins
    if [[ -d ~/.config/tmux/plugins ]]; then
        print_warning "Removing conflicting stowed plugins"
        rm -rf ~/.config/tmux/plugins
    fi
    
    # Clean up any broken symlinks in plugin directory
    if [[ -d ~/.tmux/plugins ]]; then
        find ~/.tmux/plugins -type l ! -exec test -e {} \; -delete 2>/dev/null || true
    fi
}

setup_tmux_plugins() {
    print_info "Setting up tmux plugins..."
    
    # Clean any plugin conflicts first
    clean_plugin_conflicts
    
    # Ensure .tmux directory exists
    mkdir -p ~/.tmux/plugins
    
    # Install or update TPM
    if [[ -d ~/.tmux/plugins/tpm ]]; then
        print_info "Removing existing TPM for clean install..."
        rm -rf ~/.tmux/plugins/tpm
    fi
    
    print_info "Installing TPM (Tmux Plugin Manager)..."
    if ! run_command "TPM installation" git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm; then
        print_error "Failed to install TPM"
        return 1
    fi
    
    # Make sure TPM scripts are executable
    chmod +x ~/.tmux/plugins/tpm/scripts/* 2>/dev/null || true
    print_success "TPM installed"
    
    # Kill any existing tmux sessions to avoid conflicts
    tmux kill-server 2>/dev/null || true
    sleep 2
    
    # Install plugins using TPM
    print_info "Installing tmux plugins..."
    
    # Method 1: Try using TPM's install script directly
    if [[ -x ~/.tmux/plugins/tpm/scripts/install_plugins.sh ]]; then
        if ~/.tmux/plugins/tpm/scripts/install_plugins.sh; then
            print_success "Plugins installed via TPM script"
        else
            print_warning "Direct TPM script failed, trying tmux session method..."
            # Method 2: Use tmux session
            if tmux new-session -d -s plugin_install 2>/dev/null; then
                sleep 3
                tmux send-keys -t plugin_install "tmux source-file ~/.tmux.conf" Enter 2>/dev/null
                sleep 2
                tmux send-keys -t plugin_install "~/.tmux/plugins/tpm/scripts/install_plugins.sh" Enter 2>/dev/null
                sleep 10
                tmux kill-session -t plugin_install 2>/dev/null
                print_success "Plugins installed via tmux session"
            else
                print_warning "Could not install plugins automatically"
                print_info "You can manually install plugins later by pressing prefix + I in tmux"
            fi
        fi
    else
        print_error "TPM install script not found or not executable"
        return 1
    fi
    
    # Verify critical plugins are installed
    local expected_plugins=("tpm" "tmux-resurrect" "tmux-continuum" "tmux-yank" "tmux-copycat" "tmux-sensible" "vim-tmux-navigator")
    local missing_plugins=()
    
    for plugin in "${expected_plugins[@]}"; do
        if [[ -d ~/.tmux/plugins/$plugin ]] && [[ -n "$(ls -A ~/.tmux/plugins/$plugin 2>/dev/null)" ]]; then
            print_success "$plugin installed"
        else
            missing_plugins+=("$plugin")
        fi
    done
    
    if [[ ${#missing_plugins[@]} -gt 0 ]]; then
        print_warning "Missing plugins: ${missing_plugins[*]}"
        print_info "These will be installed when you first run tmux and press prefix + I"
    fi
    
    # Create resurrect directory for tmux-resurrect
    mkdir -p ~/.tmux/resurrect
    
    print_success "tmux plugin setup complete"
}

validate_dotfiles_structure() {
    local required_dirs=("common" "shell")
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        print_error "Missing required directories: ${missing_dirs[*]}"
        print_error "Please run this script from your dotfiles directory"
        exit 1
    fi
    
    print_success "Dotfiles directory structure validated"
}

check_stow_conflicts() {
    local package="$1"
    local stow_output
    stow_output=$(stow --dry-run --verbose "$package" 2>&1)
    local stow_exit_code=$?
    
    if echo "$stow_output" | grep -q "WARNING\|ERROR\|would cause conflicts"; then
        return 1
    fi
    
    if [[ $stow_exit_code -ne 0 ]]; then
        return 1
    fi
    
    return 0
}

backup_conflicting_files() {
    local package="$1"
    local backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    local stow_output
    stow_output=$(stow --dry-run --verbose "$package" 2>&1)
    
    local conflicting_files=($(echo "$stow_output" | grep "existing target" | sed 's/.*: //' | tr -d ':' || true))
    local more_files=($(echo "$stow_output" | grep -A 10 "would cause conflicts" | grep "^\s*\*" | sed 's/^\s*\* existing target is[^:]*: //' || true))
    
    local all_files=("${conflicting_files[@]}" "${more_files[@]}")
    
    local backed_up_count=0
    for file in "${all_files[@]}"; do
        if [[ -n "$file" && -e "$HOME/$file" && ! -L "$HOME/$file" ]]; then
            mkdir -p "$(dirname "$backup_dir/$file")"
            if mv "$HOME/$file" "$backup_dir/$file" 2>/dev/null; then
                ((backed_up_count++))
            fi
        fi
    done
    
    if [[ $backed_up_count -gt 0 ]]; then
        print_success "Backed up $backed_up_count files to: ${backup_dir##*/}"
    else
        rmdir "$backup_dir" 2>/dev/null || true
    fi
}

safe_stow() {
    local package="$1"
    
    if [[ ! -d "$package" ]]; then
        print_warning "Directory $package not found, skipping"
        return 0
    fi
    
    # Check if already stowed
    local already_stowed=false
    if [[ -d "$package" ]]; then
        local test_file=$(find "$package" -type f | head -1 2>/dev/null)
        if [[ -n "$test_file" ]]; then
            local relative_path="${test_file#$package/}"
            if [[ -L "$HOME/$relative_path" ]]; then
                local link_target=$(readlink "$HOME/$relative_path" 2>/dev/null || echo "")
                if [[ "$link_target" == *"$PWD/$package"* ]]; then
                    already_stowed=true
                fi
            fi
        fi
    fi
    
    if [[ "$already_stowed" == "true" ]]; then
        print_success "$package configurations already stowed"
        return 0
    fi
    
    # Check for conflicts
    if ! check_stow_conflicts "$package"; then
        echo ""
        print_warning "Stow conflicts detected for $package"
        print_info "Existing config files need to be backed up before creating symlinks"
        echo ""
        read -p "$(echo -e ${YELLOW}Backup conflicting files and continue? ${NC}${BOLD}[y/N]:${NC} )" -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            backup_conflicting_files "$package"
        else
            print_warning "Skipping $package due to conflicts"
            return 0
        fi
    fi
    
    # Attempt to stow
    if stow "$package" 2>/dev/null; then
        print_success "$package configurations stowed"
    else
        print_error "Failed to stow $package configurations"
        return 1
    fi
}

install_dotfiles() {
    local os="$1"
    
    print_step "Installing Configuration Files"
    
    # Install OS-specific configurations
    if [[ "$os" == "macos" ]]; then
        if [[ -d "macos" ]]; then
            safe_stow "macos"
        else
            print_warning "No macOS-specific directory found"
        fi
    else
        if [[ -d "ubuntu" ]]; then
            safe_stow "ubuntu"
        else
            print_warning "No Ubuntu-specific directory found"
        fi
    fi
    
    # Install common configurations (but handle tmux separately)
    print_info "Installing common configurations..."
    safe_stow "common"
    
    # Install shell configurations
    safe_stow "shell"
    
    echo ""
}

print_installation_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                       INSTALLATION COMPLETE                         ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    print_step "Tool Verification"
    
    if command -v python3 &> /dev/null; then
        print_success "Python: $(python3 --version | cut -d' ' -f2)"
    else
        print_error "Python: Not available"
    fi
    
    if command -v node &> /dev/null; then
        print_success "Node.js: $(node --version)"
    else
        print_error "Node.js: Not available"
    fi
    
    if command -v npm &> /dev/null; then
        print_success "npm: $(npm --version)"
    else
        print_error "npm: Not available"
    fi
    
    if command -v rustc &> /dev/null; then
        print_success "Rust: $(rustc --version | cut -d' ' -f2)"
    else
        print_error "Rust: Not available"
    fi
    
    if command -v cargo &> /dev/null; then
        print_success "Cargo: $(cargo --version | cut -d' ' -f2)"
    else
        print_error "Cargo: Not available"
    fi
    
    if command -v bun &> /dev/null; then
        print_success "Bun: $(bun --version)"
    else
        print_error "Bun: Not available"
    fi
    
    if command -v gcc &> /dev/null; then
        print_success "GCC: $(gcc --version | head -1 | cut -d')' -f2 | cut -d' ' -f2)"
    else
        print_error "GCC: Not available"
    fi
    
    if command -v tmux &> /dev/null; then
        print_success "tmux: $(tmux -V | cut -d' ' -f2)"
        
        # Check tmux configuration
        if [[ -L ~/.tmux.conf ]]; then
            print_success "tmux config: Properly symlinked"
        elif [[ -f ~/.tmux.conf ]]; then
            print_warning "tmux config: File exists but not symlinked"
        else
            print_error "tmux config: Not found"
        fi
        
        # Check tmux plugins
        local plugin_count=0
        if [[ -d ~/.tmux/plugins ]]; then
            plugin_count=$(find ~/.tmux/plugins -maxdepth 1 -type d | wc -l)
            plugin_count=$((plugin_count - 1)) # Subtract 1 for the plugins directory itself
        fi
        
        if [[ $plugin_count -gt 0 ]]; then
            print_success "tmux plugins: $plugin_count installed"
        else
            print_warning "tmux plugins: None found"
        fi
    else
        print_error "tmux: Not available"
    fi
    
    echo ""
    echo -e "${GREEN}${STAR} All development tools are ready to use!${NC}"
    echo ""
    
    # Tmux usage instructions
    print_step "tmux Usage Tips"
    echo -e "${CYAN}• Start tmux: ${WHITE}tmux${NC}"
    echo -e "${CYAN}• Prefix key: ${WHITE}Ctrl-b${NC}"
    echo -e "${CYAN}• Install missing plugins: ${WHITE}prefix + I${NC}"
    echo -e "${CYAN}• Save session: ${WHITE}prefix + Ctrl-s${NC}"
    echo -e "${CYAN}• Restore session: ${WHITE}prefix + Ctrl-r${NC}"
    echo -e "${CYAN}• Split pane horizontally: ${WHITE}Ctrl-t${NC}"
    echo -e "${CYAN}• Split pane vertically: ${WHITE}Ctrl-y${NC}"
    echo -e "${CYAN}• Navigate panes: ${WHITE}Ctrl-h/j/k/l${NC}"
    echo ""
}

prompt_nvim_launch() {
    read -p "$(echo -e ${PURPLE}Launch Neovim now? ${NC}${BOLD}[y/N]:${NC} )" -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Launching Neovim..."
        if command -v nvim &> /dev/null; then
            nvim
        else
            print_warning "Neovim not found - you may need to install it separately"
        fi
    fi
}

main() {
    print_banner
    
    # Show debug mode status
    if [[ "$DEBUG" == "true" ]]; then
        print_warning "Debug mode enabled - showing detailed output"
        echo ""
    fi
    
    # Detect operating system
    OS=$(detect_os)
    print_info "Detected operating system: $OS"
    echo ""
    
    # Validate we're in the right directory
    validate_dotfiles_structure
    echo ""
    
    # Progress tracking
    local total_steps=9
    local current_step=1
    
    # Install essential tools
    print_progress $current_step $total_steps "Essential tools"
    if ! check_essential_tools "$OS"; then
        if ! install_essential_tools "$OS"; then
            print_error "Failed to install essential tools. Exiting."
            exit 1
        fi
    fi
    ((current_step++))
    
    # Install Homebrew (macOS only)
    print_progress $current_step $total_steps "Package manager"
    if [[ "$OS" == "macos" ]]; then
        if ! check_homebrew "$OS"; then
            if ! install_homebrew; then
                print_error "Failed to install Homebrew. Exiting."
                exit 1
            fi
        fi
    fi
    ((current_step++))
    
    # Install GNU Stow
    print_progress $current_step $total_steps "GNU Stow"
    if ! check_stow; then
        if ! install_stow "$OS"; then
            print_error "Failed to install GNU Stow. Exiting."
            exit 1
        fi
    fi
    ((current_step++))
    
    # Install Python
    print_progress $current_step $total_steps "Python"
    check_python
    python_result=$?
    case $python_result in
        1) 
            if ! install_python "$OS"; then
                print_error "Failed to install Python. Exiting."
                exit 1
            fi
            ;;
        2) 
            if ! install_pip "$OS"; then
                print_error "Failed to install pip. Exiting."
                exit 1
            fi
            ;;
        0) ;;
    esac
    ((current_step++))
    
    # Install Node.js
    print_progress $current_step $total_steps "Node.js"
    check_node
    node_result=$?
    case $node_result in
        1|2) 
            if ! install_node "$OS"; then
                print_error "Failed to install Node.js. Exiting."
                exit 1
            fi
            ;;
        0) ;;
    esac
    ((current_step++))
    
    # Install build tools
    print_progress $current_step $total_steps "Build tools"
    if ! check_build_tools "$OS"; then
        if ! install_build_tools "$OS"; then
            print_error "Failed to install build tools. Exiting."
            exit 1
        fi
    fi
    ((current_step++))
    
    # Install Rust
    print_progress $current_step $total_steps "Rust"
    if ! check_rust; then
        if ! install_rust "$OS"; then
            print_error "Failed to install Rust. Exiting."
            exit 1
        fi
    fi
    ((current_step++))
    
    # Install tmux
    print_progress $current_step $total_steps "tmux"
    if ! check_tmux; then
        if ! install_tmux "$OS"; then
            print_error "Failed to install tmux. Exiting."
            exit 1
        fi
    fi
    ((current_step++))
    
    # Install Bun
    print_progress $current_step $total_steps "Bun"
    if ! check_bun; then
        if ! install_bun "$OS"; then
            print_error "Failed to install Bun. Exiting."
            exit 1
        fi
    fi
    ((current_step++))
    
    echo ""
    
    # Install dotfiles
    install_dotfiles "$OS"
    
    # Fix tmux configuration symlinks
    echo ""
    print_step "Fixing tmux configuration"
    fix_tmux_symlinks
    
    # Setup tmux plugins
    echo ""
    print_step "Setting up tmux plugins"
    setup_tmux_plugins
    
    # Final comprehensive environment refresh
    refresh_shell_env "$OS"
    
    # Show installation summary
    print_installation_summary
    
    # Optional Neovim launch
    prompt_nvim_launch
}

# Run main function
main "$@"

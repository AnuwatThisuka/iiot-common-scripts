#!/bin/bash

# ============================
# Enable UFW Firewall Script
# ============================
# เปิดใช้งาน UFW และกำหนดเฉพาะพอร์ตที่อนุญาต

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# --- CONFIG ---
readonly ALLOWED_PORTS=(22 80 443 1883 9000)  # SSH, HTTP, HTTPS, MQTT, Node-RED
readonly DEFAULT_POLICY="deny"

# --- FUNCTIONS ---
log_info() {
    echo "ℹ️  $1"
}

log_success() {
    echo "✅ $1"
}

log_error() {
    echo "❌ $1" >&2
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

install_ufw() {
    if ! command -v ufw &> /dev/null; then
        log_info "Installing UFW..."
        apt update && apt install ufw -y
        log_success "UFW installed successfully"
    else
        log_info "UFW is already installed"
    fi
}

reset_ufw() {
    log_info "Resetting UFW configuration..."
    ufw disable
    ufw --force reset
    log_success "UFW reset completed"
}

configure_defaults() {
    log_info "Setting default policy to $DEFAULT_POLICY"
    ufw default "$DEFAULT_POLICY" incoming
    ufw default allow outgoing
    log_success "Default policies configured"
}

allow_ports() {
    log_info "Configuring allowed ports..."
    for port in "${ALLOWED_PORTS[@]}"; do
        if ufw allow "$port"; then
            log_success "Port $port allowed"
        else
            log_error "Failed to allow port $port"
            return 1
        fi
    done
}

enable_firewall() {
    log_info "Enabling UFW firewall..."
    if ufw --force enable; then
        log_success "Firewall enabled successfully"
    else
        log_error "Failed to enable firewall"
        return 1
    fi
}

show_status() {
    echo ""
    echo "📋 Firewall Status:"
    echo "==================="
    ufw status verbose
}

# --- MAIN ---
main() {
    log_info "Starting UFW Firewall configuration..."
    
    check_root
    install_ufw
    reset_ufw
    configure_defaults
    allow_ports
    enable_firewall
    show_status
    
    log_success "Firewall configuration completed!"
}

# Execute main function
main "$@"

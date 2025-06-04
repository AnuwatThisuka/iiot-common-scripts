#!/bin/bash

# ===============================
# Backup IIoT Config Files Script
# ===============================
# สำรองไฟล์ config จากระบบไปยังโฟลเดอร์ปลายทาง
# เหมาะกับการตั้ง cron สำรองอัตโนมัติ

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# --- CONFIGURATION ---
readonly SCRIPT_NAME="$(basename "$0")"
readonly BACKUP_DATE=$(date +'%Y-%m-%d_%H-%M-%S')
readonly BACKUP_BASE_DIR="/backup"
readonly BACKUP_DIR="$BACKUP_BASE_DIR/iiot-configs/$BACKUP_DATE"
readonly ARCHIVE_NAME="iiot-configs-$BACKUP_DATE.tar.gz"
readonly ARCHIVE_PATH="$BACKUP_BASE_DIR/$ARCHIVE_NAME"

readonly SOURCE_PATHS=(
    "/etc/mosquitto"
    "/etc/nodered"
    "/etc/docker"
    "/home/iiot-user/app/config"
)

# --- FUNCTIONS ---
log_info() {
    echo "ℹ️ [$SCRIPT_NAME] $1"
}

log_success() {
    echo "✅ [$SCRIPT_NAME] $1"
}

log_warning() {
    echo "⚠️ [$SCRIPT_NAME] $1"
}

log_error() {
    echo "❌ [$SCRIPT_NAME] $1" >&2
}

cleanup() {
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "กำลังลบโฟลเดอร์ชั่วคราว..."
        rm -rf "$BACKUP_DIR"
    fi
}

create_backup_directory() {
    log_info "สร้างโฟลเดอร์สำรอง: $BACKUP_DIR"
    if ! mkdir -p "$BACKUP_DIR"; then
        log_error "ไม่สามารถสร้างโฟลเดอร์สำรองได้"
        exit 1
    fi
}

backup_files() {
    log_info "กำลังสำรองไฟล์ config..."
    local backup_count=0
    
    for path in "${SOURCE_PATHS[@]}"; do
        if [[ -d "$path" ]] || [[ -f "$path" ]]; then
            log_success "สำรอง: $path"
            if ! cp -r "$path" "$BACKUP_DIR/"; then
                log_error "ไม่สามารถสำรอง $path ได้"
                return 1
            fi
            ((backup_count++))
        else
            log_warning "ไม่พบ: $path (ข้าม)"
        fi
    done
    
    if [[ $backup_count -eq 0 ]]; then
        log_error "ไม่พบไฟล์ใดๆ ที่จะสำรอง"
        return 1
    fi
    
    log_info "สำรองไฟล์สำเร็จ $backup_count รายการ"
}

create_archive() {
    log_info "กำลังบีบอัดไฟล์สำรองเป็น .tar.gz..."
    if ! tar -czf "$ARCHIVE_PATH" -C "$BACKUP_BASE_DIR/iiot-configs" "$BACKUP_DATE"; then
        log_error "ไม่สามารถสร้างไฟล์บีบอัดได้"
        return 1
    fi
    
    # Verify archive was created and has content
    if [[ ! -f "$ARCHIVE_PATH" ]] || [[ ! -s "$ARCHIVE_PATH" ]]; then
        log_error "ไฟล์บีบอัดไม่ถูกต้องหรือเป็นไฟล์เปล่า"
        return 1
    fi
}

# --- MAIN EXECUTION ---
main() {
    log_info "เริ่มต้นการสำรอง IIoT Config Files..."
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Execute backup steps
    create_backup_directory
    backup_files
    create_archive
    
    # Success message
    local archive_size
    archive_size=$(du -h "$ARCHIVE_PATH" | cut -f1)
    log_success "เสร็จสิ้น! ไฟล์สำรอง: $ARCHIVE_PATH ($archive_size)"
}

# Check if running as root for system directories
if [[ $EUID -ne 0 ]] && [[ -d "/etc/mosquitto" || -d "/etc/nodered" || -d "/etc/docker" ]]; then
    log_warning "แนะนำให้รันด้วย sudo สำหรับการเข้าถึงไฟล์ระบบ"
fi

# Execute main function
main "$@"

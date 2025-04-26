#!/bin/bash

# กำหนด path สำหรับไฟล์ log
LOG_FILE="/var/log/autostart_setup.log"

# ฟังก์ชั่นสำหรับบันทึก log
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# เช็กและติดตั้ง zenity หากยังไม่มี
log_message "เริ่มการติดตั้ง Zenity ถ้าจำเป็น..."
if ! command -v zenity &> /dev/null; then
    log_message "กำลังติดตั้ง Zenity..."
    sudo apt update >> "$LOG_FILE" 2>&1
    sudo apt install zenity -y >> "$LOG_FILE" 2>&1
else
    log_message "Zenity ติดตั้งแล้ว"
fi

# ขอ URL จากผู้ใช้ผ่าน GUI
URL=$(zenity --entry --title="ตั้งค่า Auto Startup (Global)" --text="กรอก URL ที่ต้องการให้เปิดอัตโนมัติแบบเต็มจอ:")

# ถ้าผู้ใช้กดยกเลิก
if [ -z "$URL" ]; then
    log_message "ผู้ใช้ยกเลิกการตั้งค่า"
    zenity --info --text="ยกเลิกการตั้งค่าแล้ว"
    exit 0
fi

log_message "ได้รับ URL: $URL"

# ตรวจสอบสิทธิ์ sudo
if [ "$EUID" -ne 0 ]; then
    log_message "ผู้ใช้ไม่ได้รันสคริปต์ด้วยสิทธิ์ sudo"
    zenity --error --text="โปรดเรียกสคริปต์นี้ด้วยสิทธิ์ sudo:\nsudo ./ชื่อสคริปต์.sh"
    exit 1
fi

# เขียน autostart ไปที่ /etc/xdg/lxsession/LXDE-pi/autostart
AUTOSTART_FILE="/etc/xdg/lxsession/LXDE-pi/autostart"
log_message "เริ่มเขียนไฟล์ autostart ไปที่ $AUTOSTART_FILE"
cat > "$AUTOSTART_FILE" <<EOL
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
@xscreensaver -no-splash
@xset s off
@xset -dpms
@xset s noblank
@sh -c "sleep 10 && chromium-browser --noerrdialogs --disable-infobars --kiosk --incognito --no-first-run --disable-session-crashed-bubble --disable-features=TranslateUI --disable-contextual-search --disable-pinch --overscroll-history-navigation=0 --user-data-dir=/tmp $URL"
@sh /usr/local/bin/xinput-config.sh
EOL

log_message "เขียนไฟล์ autostart เรียบร้อยแล้ว"

# (Optional) สร้าง xinput-config.sh ถ้ายังไม่มี
XINPUT_SCRIPT="/usr/local/bin/xinput-config.sh"
if [ ! -f "$XINPUT_SCRIPT" ]; then
    log_message "สร้างสคริปต์ xinput-config.sh เนื่องจากยังไม่มี"
    cat > "$XINPUT_SCRIPT" <<'EOS'
#!/bin/bash

DEVICE=$(xinput list --name-only | grep -i -E "touchpad|synaptics|ft5406" | head -n 1)

if [ -n "$DEVICE" ]; then
    ID=$(xinput list --id-only "$DEVICE")
    echo "กำลังตั้งค่า $DEVICE [$ID]"
    xinput --set-prop "$ID" "Evdev Middle Button Emulation" 0 2>/dev/null
    xinput --set-prop "$ID" "Evdev Right Button Emulation" 0 2>/dev/null
    xinput --set-prop "$ID" "Drag Lock Buttons" 0 2>/dev/null
    xinput --set-prop "$ID" "Synaptics Tap Action" 0 0 0 0 0 0 0 2>/dev/null
fi
EOS
    chmod +x "$XINPUT_SCRIPT"
    log_message "สร้างไฟล์ xinput-config.sh เสร็จเรียบร้อย"
fi

# แจ้งผลสำเร็จ
log_message "ตั้งค่าเสร็จสิ้นแล้ว"
zenity --info --text="✅ ตั้งค่าเรียบร้อยแล้ว!\nจะเปิด $URL แบบเต็มจอเมื่อบูตเครื่อง"

#!/bin/bash

# เช็กและติดตั้ง zenity หากยังไม่มี
if ! command -v zenity &> /dev/null; then
    echo "กำลังติดตั้ง Zenity..."
    sudo apt update
    sudo apt install zenity -y
fi

# ตรวจสอบสิทธิ์ sudo
if [ "$EUID" -ne 0 ]; then
    zenity --error --text="โปรดเรียกสคริปต์นี้ด้วยสิทธิ์ sudo:\nsudo ./setup-autostart.sh"
    exit 1
fi

# ขอ URL จากผู้ใช้ (ใช้ default หากไม่กรอก)
DEFAULT_URL="http://172.16.1.125:30216"
URL=$(zenity --entry --title="ตั้งค่า Auto Startup (Global)" \
    --text="กรอก URL ที่ต้องการให้เปิดอัตโนมัติแบบเต็มจอ:" \
    --entry-text="$DEFAULT_URL")

if [ -z "$URL" ]; then
    URL="$DEFAULT_URL"
fi

# Path สำหรับ autostart และ log
AUTOSTART_FILE="/etc/xdg/lxsession/LXDE-pi/autostart"
XINPUT_SCRIPT="/usr/local/bin/xinput-config.sh"
LOG_FILE="/var/log/autostart_setup.log"

# เขียน autostart file ใหม่
cat > "$AUTOSTART_FILE" <<EOL
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
@xscreensaver -no-splash
@xset s off
@xset -dpms
@xset s noblank
@sh -c "echo '[\$(date)] เริ่ม autostart' >> $LOG_FILE"
@sh -c "sleep 10 && chromium-browser --noerrdialogs --disable-infobars --kiosk --incognito --no-first-run --disable-session-crashed-bubble --disable-features=TranslateUI --disable-contextual-search --disable-pinch --overscroll-history-navigation=0 --user-data-dir=/tmp $URL >> $LOG_FILE 2>&1"
@sh -c "$XINPUT_SCRIPT >> $LOG_FILE 2>&1"
EOL

# สร้างสคริปต์ xinput-config.sh
cat > "$XINPUT_SCRIPT" <<'EOS'
#!/bin/bash
DEVICE=$(xinput list --name-only | grep -i -E "touchpad|synaptics|ft5406" | head -n 1)

if [ -n "$DEVICE" ]; then
    ID=$(xinput list --id-only "$DEVICE")
    echo "กำลังตั้งค่า $DEVICE [ID $ID]"
    xinput --set-prop "$ID" "Evdev Middle Button Emulation" 0 2>/dev/null
    xinput --set-prop "$ID" "Evdev Right Button Emulation" 0 2>/dev/null
    xinput --set-prop "$ID" "Drag Lock Buttons" 0 2>/dev/null
    xinput --set-prop "$ID" "Synaptics Tap Action" 0 0 0 0 0 0 0 2>/dev/null
fi
EOS

chmod +x "$XINPUT_SCRIPT"

# แจ้งผู้ใช้
zenity --info --text="✅ ตั้งค่าเรียบร้อยแล้ว!\nจะเปิด $URL แบบเต็มจอเมื่อบูตเครื่อง\n\nLog อยู่ที่: $LOG_FILE"

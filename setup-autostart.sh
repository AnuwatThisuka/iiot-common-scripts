#!/bin/bash

# เช็กและติดตั้ง zenity หากยังไม่มี
if ! command -v zenity &> /dev/null; then
    echo "กำลังติดตั้ง Zenity..."
    sudo apt update
    sudo apt install zenity -y
fi

# ขอ URL จากผู้ใช้ผ่าน GUI
URL=$(zenity --entry --title="ตั้งค่า Auto Startup (Global)" --text="กรอก URL ที่ต้องการให้เปิดอัตโนมัติแบบเต็มจอ:")

# ถ้าผู้ใช้กดยกเลิก
if [ -z "$URL" ]; then
    zenity --info --text="ยกเลิกการตั้งค่าแล้ว"
    exit 0
fi

# ตรวจสอบสิทธิ์ sudo
if [ "$EUID" -ne 0 ]; then
    zenity --error --text="โปรดเรียกสคริปต์นี้ด้วยสิทธิ์ sudo:\nsudo ./ชื่อสคริปต์.sh"
    exit 1
fi

# เขียน autostart ไปที่ /etc/xdg/lxsession/LXDE-pi/autostart
AUTOSTART_FILE="/etc/xdg/lxsession/LXDE-pi/autostart"

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

# (Optional) สร้าง xinput-config.sh ถ้ายังไม่มี
XINPUT_SCRIPT="/usr/local/bin/xinput-config.sh"
if [ ! -f "$XINPUT_SCRIPT" ]; then
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
fi

zenity --info --text="✅ ตั้งค่าเรียบร้อยแล้ว!\nจะเปิด $URL แบบเต็มจอเมื่อบูตเครื่อง"

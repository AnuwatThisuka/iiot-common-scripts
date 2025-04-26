#!/bin/bash

# เช็กและติดตั้ง zenity หากยังไม่มี
if ! command -v zenity &> /dev/null; then
    echo "กำลังติดตั้ง Zenity..."
    sudo apt update
    sudo apt install zenity -y
fi

# ขอ URL จากผู้ใช้ผ่าน GUI (มี default)
URL=$(zenity --entry --title="ตั้งค่า Auto Startup" --text="กรอก URL ที่ต้องการเปิดอัตโนมัติแบบเต็มจอ:" --entry-text="http://172.16.1.125:30216")

# ถ้าผู้ใช้กดยกเลิก
if [ -z "$URL" ]; then
    zenity --info --text="❌ ยกเลิกการตั้งค่าแล้ว"
    exit 0
fi

# เตรียม path autostart ของ user
AUTOSTART_DIR="/home/pi/.config/lxsession/LXDE-pi"
AUTOSTART_FILE="$AUTOSTART_DIR/autostart"

mkdir -p "$AUTOSTART_DIR"

# เขียน autostart ใหม่
cat > "$AUTOSTART_FILE" <<EOL
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
@xscreensaver -no-splash
@xset s off
@xset -dpms
@xset s noblank
@bash -c "sleep 10; /usr/bin/chromium-browser --noerrdialogs --disable-infobars --kiosk --incognito --no-first-run --disable-session-crashed-bubble --disable-features=TranslateUI --disable-contextual-search --disable-pinch --overscroll-history-navigation=0 --user-data-dir=/tmp $URL"
@bash /home/pi/xinput-config.sh
EOL

# สร้าง xinput-config.sh ถ้ายังไม่มี
XINPUT_SCRIPT="/home/pi/xinput-config.sh"
if [ ! -f "$XINPUT_SCRIPT" ]; then
cat > "$XINPUT_SCRIPT" <<'EOS'
#!/bin/bash
DEVICE=$(xinput list --name-only | grep -i -E "touchpad|synaptics|ft5406" | head -n 1)
if [ -n "$DEVICE" ]; then
    ID=$(xinput list --id-only "$DEVICE")
    echo "กำลังตั้งค่าอุปกรณ์: $DEVICE [$ID]" >> /home/pi/xinput.log
    xinput --set-prop "$ID" "Evdev Middle Button Emulation" 0 2>/dev/null
    xinput --set-prop "$ID" "Evdev Right Button Emulation" 0 2>/dev/null
    xinput --set-prop "$ID" "Drag Lock Buttons" 0 2>/dev/null
    xinput --set-prop "$ID" "Synaptics Tap Action" 0 0 0 0 0 0 0 2>/dev/null
else
    echo "ไม่พบอุปกรณ์ Touchpad" >> /home/pi/xinput.log
fi
EOS
chmod +x "$XINPUT_SCRIPT"
fi

# แจ้งผล
zenity --info --text="✅ ตั้งค่าเรียบร้อยแล้ว!\nบูตเครื่องแล้วจะเปิด:\n$URL\nแบบเต็มจอ"

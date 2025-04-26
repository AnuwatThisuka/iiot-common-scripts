#!/bin/bash

# ติดตั้ง Zenity หากยังไม่มี
if ! command -v zenity &> /dev/null; then
    echo "กำลังติดตั้ง Zenity..."
    sudo apt update
    sudo apt install zenity -y
fi

# ขอ URL จากผู้ใช้ผ่าน GUI
URL=$(zenity --entry --title="ตั้งค่า Auto Startup" --text="กรอก URL ที่ต้องการให้เปิดอัตโนมัติแบบเต็มจอ:")

# ถ้าผู้ใช้กดยกเลิก จะไม่ทำอะไร
if [ -z "$URL" ]; then
    zenity --info --text="ยกเลิกการตั้งค่าแล้ว"
    exit 0
fi

# สร้าง path autostart ถ้ายังไม่มี
AUTOSTART_PATH="/home/pi/.config/lxsession/LXDE-pi"
mkdir -p "$AUTOSTART_PATH"

# เขียน autostart ใหม่
cat > "$AUTOSTART_PATH/autostart" <<EOL
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
@xscreensaver -no-splash
@xset s off
@xset -dpms
@xset s noblank
@sleep 10 && chromium-browser --noerrdialogs --disable-infobars --kiosk --incognito --no-first-run --disable-session-crashed-bubble --disable-features=TranslateUI --disable-contextual-search --disable-pinch --overscroll-history-navigation=0 --user-data-dir=/tmp $URL
EOL

zenity --info --text="ตั้งค่าเรียบร้อยแล้ว! จะเปิด $URL แบบเต็มจอเมื่อบูต"

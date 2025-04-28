#!/bin/bash

# เช็กและติดตั้ง zenity หากยังไม่มี
if ! command -v zenity &> /dev/null; then
    echo "กำลังติดตั้ง Zenity..."
    sudo apt update
    sudo apt install zenity -y
fi

# ถาม URL ผ่าน GUI (ตั้งค่าเริ่มต้น)
DEFAULT_URL="http://172.16.1.125:30216"
URL=$(zenity --entry \
    --title="Setup Auto Startup for Chromium" \
    --text="Type URL for auto open in fullscreen:" \
    --entry-text="$DEFAULT_URL")

# ถ้าผู้ใช้กดยกเลิก
if [ -z "$URL" ]; then
    zenity --info --text="❌ cancelled"
    exit 0
fi

# เตรียม path .desktop
AUTOSTART_DIR="/home/pi/.config/autostart"
DESKTOP_FILE="$AUTOSTART_DIR/chromium-kiosk.desktop"

mkdir -p "$AUTOSTART_DIR"

# เขียน .desktop file
cat > "$DESKTOP_FILE" <<EOL
[Desktop Entry]
Type=Application
Name=Chromium Kiosk
Exec=sh -c "sleep 5 && chromium-browser --noerrdialogs --disable-infobars --disable-session-crashed-bubble --kiosk --incognito --disable-translate --disable-features=TranslateUI --disable-contextual-search --disable-pinch --overscroll-history-navigation=0 --user-data-dir=/tmp $URL"
X-GNOME-Autostart-enabled=true
EOL

chmod +x "$DESKTOP_FILE"

zenity --info --text="✅ Setup succeed full!\nจะเปิด\n<b>$URL</b>\n auto open after login"

#!/bin/bash

# --- ตั้งค่าพื้นฐาน ---
DEFAULT_URL="http://172.16.1.125:30216"
AUTOSTART_DIR="/home/pi/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/chromium-kiosk.desktop"
XINPUT_SCRIPT="/usr/local/bin/xinput-config.sh"
EXIT_KIOSK_SCRIPT="/home/pi/exit-kiosk.sh"
HOTKEY_CONFIG_FILE="/home/pi/.config/openbox/lxde-pi-rc.xml"
LOG_FILE="/var/log/autostart_setup.log"

mkdir -p "$AUTOSTART_DIR"
mkdir -p "$(dirname "$HOTKEY_CONFIG_FILE")"

# --- ติดตั้ง zenity ถ้ายังไม่มี ---
if ! command -v zenity &> /dev/null; then
    echo "Installing zenity..." | tee -a "$LOG_FILE"
    sudo apt update
    sudo apt install zenity -y
fi

# --- ขอ URL จากผู้ใช้ ---
URL=$(zenity --entry \
    --title="ตั้งค่า Auto Startup สำหรับ Chromium" \
    --text="กรอก URL ที่ต้องการให้เปิดอัตโนมัติแบบเต็มจอ:" \
    --entry-text="$DEFAULT_URL")

if [ -z "$URL" ]; then
    zenity --info --text="❌ ยกเลิกการตั้งค่าแล้ว"
    exit 0
fi

echo "เลือก URL: $URL" | tee -a "$LOG_FILE"

# --- เขียนไฟล์ Autostart (.desktop) ---
cat > "$AUTOSTART_FILE" <<EOL
[Desktop Entry]
Type=Application
Name=Chromium Kiosk
Exec=sh -c "sleep 5 && chromium-browser --noerrdialogs --disable-infobars --disable-session-crashed-bubble --kiosk --incognito --disable-translate --disable-features=TranslateUI --disable-contextual-search --disable-pinch --overscroll-history-navigation=0 --user-data-dir=/tmp $URL"
X-GNOME-Autostart-enabled=true
EOL

chmod +x "$AUTOSTART_FILE"
echo "สร้าง autostart ที่: $AUTOSTART_FILE" | tee -a "$LOG_FILE"

# --- ถามว่าต้องการตั้งค่า xinput ไหม ---
zenity --question \
    --title="ตั้งค่า Touchpad (xinput) หรือไม่?" \
    --text="คุณต้องการปิด gesture/คลิกเสริมบน Touchpad หรือไม่?\n(ใช้ได้กับอุปกรณ์เช่น Synaptics, FT5406 ฯลฯ)" \
    --ok-label="ตั้งค่าเลย" \
    --cancel-label="ไม่ต้องการ"

if [ $? -eq 0 ]; then
    # ตอบ YES
    cat > "$XINPUT_SCRIPT" <<'EOS'
#!/bin/bash
DEVICE=$(xinput list --name-only | grep -i -E "touchpad|synaptics|ft5406" | head -n 1)
if [ -n "$DEVICE" ]; then
    ID=$(xinput list --id-only "$DEVICE")
    xinput --set-prop "$ID" "Evdev Middle Button Emulation" 0 2>/dev/null
    xinput --set-prop "$ID" "Evdev Right Button Emulation" 0 2>/dev/null
    xinput --set-prop "$ID" "Drag Lock Buttons" 0 2>/dev/null
    xinput --set-prop "$ID" "Synaptics Tap Action" 0 0 0 0 0 0 0 2>/dev/null
fi
EOS

    chmod +x "$XINPUT_SCRIPT"
    echo "สร้าง xinput-config.sh แล้ว" | tee -a "$LOG_FILE"

    # เพิ่ม autostart เรียก xinput-config.sh ด้วย
    echo "@sh /usr/local/bin/xinput-config.sh" >> "$AUTOSTART_FILE"
else
    echo "ข้ามการตั้งค่า xinput" | tee -a "$LOG_FILE"
fi

# --- สร้างไฟล์ exit-kiosk.sh ---
cat > "$EXIT_KIOSK_SCRIPT" <<'EOS'
#!/bin/bash
pkill -f "chromium-browser.*--kiosk"
sleep 2
chromium-browser --noerrdialogs --disable-infobars --incognito http://172.16.1.125:30216 &
EOS

chmod +x "$EXIT_KIOSK_SCRIPT"
echo "สร้าง exit-kiosk.sh แล้ว" | tee -a "$LOG_FILE"

# --- ติดตั้ง lxhotkey และตั้งปุ่ม Ctrl+Alt+E ---
if ! command -v lxhotkey &> /dev/null; then
    sudo apt install lxhotkey -y
fi

# เพิ่ม keybind ใน lxde-pi-rc.xml ถ้ายังไม่มี
if ! grep -q "exit-kiosk.sh" "$HOTKEY_CONFIG_FILE"; then
    sed -i '/<\/keyboard>/i \
<keybind key="C-A-e">\
  <action name="Execute">\
    <command>/home/pi/exit-kiosk.sh</command>\
  </action>\
</keybind>' "$HOTKEY_CONFIG_FILE"
    echo "เพิ่มปุ่ม Ctrl+Alt+E สำหรับออก Kiosk แล้ว" | tee -a "$LOG_FILE"
else
    echo "Hotkey มีอยู่แล้ว ไม่เพิ่มซ้ำ" | tee -a "$LOG_FILE"
fi

# Reload Openbox เพื่อให้ keybind ใช้งานได้ทันที
openbox --reconfigure

zenity --info --text="✅ ตั้งค่าเสร็จสมบูรณ์!\n\nเปิด $URL อัตโนมัติหลัง login\n\nกด Ctrl+Alt+E เพื่อ Exit Kiosk Mode"

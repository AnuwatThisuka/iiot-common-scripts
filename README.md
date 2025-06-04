# iiot-common-scripts

## Overview

**iiot-common-scripts** คือชุดรวมของ Shell Scripts และไฟล์ configuration ที่ใช้ในการติดตั้งระบบ, ดูแลรักษา, และจัดการโครงสร้างพื้นฐานของระบบ IIoT (Industrial Internet of Things) ทั้งในระดับ Development, Testing และ Production

Repo นี้ถูกออกแบบมาเพื่อให้สามารถใช้งานซ้ำได้ และช่วยลดเวลาในการตั้งค่าระบบ โดยรวมถึงสคริปต์ที่ใช้บ่อย เช่น:

- การติดตั้ง environment พื้นฐาน
- การ config ระบบ Network, Firewall หรือ Docker
- การจัดการ service และ log
- การตรวจสอบสถานะระบบ

## Directory Structure

```bash

iiot-common-scripts/
├── setup/   # สคริปต์ติดตั้ง environment และ dependencies
├── services/ # การจัดการ service เช่น start, stop, restart
├── configs/  # Template สำหรับ config ต่างๆ เช่น Docker, systemd
├── monitor/  # สคริปต์ตรวจสอบสถานะระบบหรือ service
├── utils/    # เครื่องมือเสริม เช่น backup, log rotate, etc.
└── README.md
```

## Example Scripts

### 1. Setup Docker Environment

```bash
./setup/install-docker.sh
```

### 2. Restart All IIoT Services

```bash
./services/restart-iiot-services.sh
```

### 3. Check Service Health

```bash
./monitor/check-services.sh
```

## Prerequisites

- Linux-based system (Ubuntu / Debian / CentOS)
- สิทธิ์ในการใช้งาน sudo
- bash, curl, systemd

## Usage

Clone repository:

```bash
git clone https://github.com/AnuwatThisuka/iiot-common-scripts.git
cd iiot-common-scripts
```

เลือกสคริปต์ที่ต้องการใช้งาน และให้สิทธิ์รัน:

```bash
chmod +x ./setup/install-docker.sh
./setup/install-docker.sh
```

## Contribution

หากคุณมีสคริปต์ที่ใช้บ่อยในงาน IIoT และต้องการแบ่งปัน สามารถส่ง Pull Request หรือเปิด Issue เพื่อแนะนำได้

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Author

Maintained by Anuwat Thisuka

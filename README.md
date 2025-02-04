
# Chromium x VPS
The easy lazy way to install chromium on VPS with 1 command

# Chromium Installer Script

Script ini digunakan untuk menginstall Chromium di VPS menggunakan Docker.


## Cara Penggunaan

**The FAST WAY (RANDOM USER/PASSWORD)**

```bash
curl -s https://raw.githubusercontent.com/GlgApr/chromium/main/chromium.sh | sudo bash -s
```

**The SAFE WAY (CUSTOM USER/PASS)**
```bash
curl -O https://raw.githubusercontent.com/GlgApr/chromium/main/chromium.sh
chmod +x chromium.sh
sudo ./chromium.sh
```
**VIDEO TUTORIAL**

[🔥 EASY LAZY CHROMIUM ON VPS 🔥](https://www.youtube.com/@glgapr)
## Fitur
- Install Docker dan Docker Compose otomatis
- Generate username dan password acak
- Konfigurasi timezone otomatis
- Bisa custom username dan password

## CHANGE USER/PASSWORD
```bash
docker stop chromium
nano /opt/chromium-browser/docker-compose.yml
```
- Ubah bagian
  environment:
    - CUSTOM_USER=your_new_user
    - PASSWORD=your_new_password
- CTRL+X, Y, Click Enter.
- Running
  ```bash
  docker compose up -d
  ```
## DANGER ZONE
**DELETING CHROMIUM**
```bash
docker stop chromium
docker rm chromium
docker rmi lscr.io/linuxserver/chromium:latest
```
## Kontribusi
Pull request dipersilakan! 😊

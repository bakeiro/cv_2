# Crear directorio y todos los scripts de una vez
mkdir -p ~/distro_setup && cd ~/distro_setup && {

# Script 1: Setup Termux
cat > setup_termux.sh << 'EOF'
#!/bin/bash

echo "=== Actualizando Termux ==="
pkg update && pkg upgrade -y

echo "=== Instalando dependencias necesarias ==="
pkg install -y wget curl proot-distro git

echo "=== Creando directorio de trabajo ==="
mkdir -p ~/distro_setup
cd ~/distro_setup

echo "=== Instalación básica completada ==="
EOF

# Script 2: Instalar Ubuntu
cat > install_ubuntu.sh << 'EOF'
#!/bin/bash

echo "=== Instalando Ubuntu 22.04 LTS ==="

# Instalar Ubuntu
proot-distro install ubuntu

if [ $? -eq 0 ]; then
    echo "=== Ubuntu instalado correctamente ==="
    
    # Crear script de configuración dentro de Ubuntu
    cat > ~/configure_ubuntu.sh << 'EOFINNER'
#!/bin/bash
echo "=== Actualizando Ubuntu ==="
apt update && apt upgrade -y

echo "=== Instalando dependencias básicas ==="
apt install -y sudo curl wget git vim nano

echo "=== Instalando librerías gráficas y audio ==="
apt install -y \
    xorg \
    xserver-xorg \
    x11-apps \
    pulseaudio \
    pavucontrol \
    fonts-noto \
    fonts-liberation

echo "=== Instalando mesa drivers para ARM ==="
apt install -y \
    mesa-utils \
    mesa-vulkan-drivers \
    libgl1-mesa-dri \
    libglu1-mesa

echo "=== Configurando usuario ==="
if ! id "gamer" &>/dev/null; then
    useradd -m -s /bin/bash gamer
    echo "gamer:gamer" | chpasswd
    usermod -aG sudo gamer
fi

echo "=== Instalando Steam dependencies ==="
apt install -y \
    libc6 \
    libegl1 \
    libgbm1 \
    libgl1 \
    libvulkan1 \
    libx11-6 \
    libxcb1 \
    libxext6 \
    libxss1 \
    libxtst6

echo "=== Configuración de Ubuntu completada ==="
EOFINNER

    chmod +x ~/configure_ubuntu.sh
    
    echo "Ejecuta: proot-distro login ubuntu"
    echo "Luego dentro de Ubuntu ejecuta: /root/configure_ubuntu.sh"
else
    echo "Error en la instalación de Ubuntu"
fi
EOF

# Script 3: Instalar Steam
cat > install_steam.sh << 'EOF'
#!/bin/bash

echo "=== Script de instalación de Steam ==="

# Verificar que estamos en la distro
if [ ! -f /etc/os-release ]; then
    echo "Este script debe ejecutarse dentro de la distro Linux"
    exit 1
fi

echo "=== Instalando dependencias necesarias ==="
apt update
apt install -y wget curl libc6 libx11-6 libxcb1 libxext6 libxss1 libxtst6 libudev1 libinput10 libevent-2.1-7

echo "=== Descargando e instalando Steam ==="

# Crear directorio para Steam
mkdir -p ~/steam
cd ~/steam

# MÉTODO 1: Steam oficial
echo "Método 1: Descargando Steam oficial..."
if wget -O steam.deb "https://cdn.akamai.steamstatic.com/client/installer/steam.deb"; then
    echo "Steam oficial descargado, instalando..."
    apt install -f -y ./steam.deb
    echo "=== Steam oficial instalado ==="
    
# MÉTODO 2: Steam desde repositorio Debian
elif wget -O steam.deb "http://ftp.us.debian.org/debian/pool/non-free/s/steam/steam_1.0.0.78+ds.2-1_arm64.deb"; then
    echo "Steam Debian descargado, instalando..."
    apt install -f -y ./steam.deb
    echo "=== Steam Debian instalado ==="

# MÉTODO 3: Steam flatpak
else
    echo "Instalando Steam via Flatpak..."
    apt install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub com.valvesoftware.Steam
    echo "=== Steam Flatpak instalado ==="
fi

# Crear script de lanzamiento
cat > ~/launch_steam.sh << 'EOFINNER'
#!/bin/bash
export PULSE_RUNTIME_PATH=/run/user/$(id -u)/pulse
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DISPLAY=:0
export STEAM_RUNTIME=1
export DBUS_FATAL_WARNINGS=0

if ! pgrep -x "Xorg" > /dev/null; then
    echo "Iniciando X server..."
    startx &
    sleep 5
fi

if ! pgrep -x "pulseaudio" > /dev/null; then
    echo "Iniciando PulseAudio..."
    pulseaudio --start &
    sleep 2
fi

echo "Iniciando Steam..."
if command -v steam &> /dev/null; then
    steam
elif command -v flatpak &> /dev/null && flatpak list | grep -q com.valvesoftware.Steam; then
    flatpak run com.valvesoftware.Steam
else
    echo "Steam no encontrado."
fi
EOFINNER

chmod +x ~/launch_steam.sh

echo "=== Steam instalado correctamente ==="
echo "Para ejecutar Steam usa: ~/launch_steam.sh"
EOF

# Script 4: Setup GUI
cat > setup_gui.sh << 'EOF'
#!/bin/bash

echo "=== Configuración de entorno gráfico ==="

# Instalar entorno de escritorio ligero
apt install -y \
    xfce4 \
    xfce4-goodies \
    firefox-esr \
    file-manager

echo "=== Instalando y configurando VNC ==="
apt install -y tigervnc-standalone-server

# Configurar VNC
mkdir -p ~/.vnc
cat > ~/.vnc/xstartup << 'EOFINNER'
#!/bin/bash
export XDG_SESSION_TYPE=x11
export DISPLAY=:1
exec startxfce4
EOFINNER

chmod +x ~/.vnc/xstartup

# Crear script de inicio VNC
cat > ~/start_vnc.sh << 'EOFINNER'
#!/bin/bash
export DISPLAY=:1
vncserver :1 -geometry 1280x720 -depth 24
echo "VNC corriendo en localhost:5901"
EOFINNER

chmod +x ~/start_vnc.sh

echo "=== Instalando herramientas adicionales ==="
apt install -y \
    htop \
    neofetch \
    filezilla

echo "=== Configuración gráfica completada ==="
echo "Para iniciar VNC: ~/start_vnc.sh"
EOF

# Script 5: Optimizaciones Odin 2
cat > odin_optimizations.sh << 'EOF'
#!/bin/bash

echo "=== Optimizaciones específicas para Odin 2 ==="

# Crear configuración de performance
cat > ~/.bashrc_optimizations << 'EOFINNER'
# Optimizaciones para gaming
export MESA_GL_VERSION_OVERRIDE=4.5
export MESA_GLSL_VERSION_OVERRIDE=450
export __GL_THREADED_OPTIMIZATIONS=1
export GPU_MAX_HEAP_SIZE=100
export GPU_MAX_ALLOC_PERCENT=100

# Optimizaciones generales
export SDL_AUDIODRIVER=pulse
export PULSE_LATENCY_MSEC=60

# Para Steam específicamente
export STEAM_RUNTIME=0
export STEAM_RUNTIME_PREFER_HOST_LIBRARIES=0
EOFINNER

# Añadir al bashrc
echo "source ~/.bashrc_optimizations" >> ~/.bashrc

echo "=== Creando script de monitoreo ==="
cat > ~/system_monitor.sh << 'EOFINNER'
#!/bin/bash
echo "=== Información del sistema Odin 2 ==="
echo "CPU: $(grep -c ^processor /proc/cpuinfo) cores"
echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
echo "GPU: $(lspci | grep -i vga | head -n1)"
echo "OpenGL: $(glxinfo | grep "OpenGL version" | head -n1)"
echo "Vulkan: $(vulkaninfo --summary 2>/dev/null | grep "apiVersion" | head -n1 || echo "No disponible")"
EOFINNER

chmod +x ~/system_monitor.sh

echo "=== Optimizaciones aplicadas ==="
EOF

# Script maestro
cat > full_setup.sh << 'EOF'
#!/bin/bash

echo "=== INSTALACIÓN COMPLETA STEAM ODIN 2 ==="

# Paso 1: Setup Termux
echo "Paso 1: Configurando Termux..."
chmod +x setup_termux.sh
./setup_termux.sh

# Paso 2: Instalar Ubuntu
echo "Paso 2: Instalando Ubuntu..."
chmod +x install_ubuntu.sh
./install_ubuntu.sh

echo ""
echo "=== PRÓXIMOS PASOS MANUALES ==="
echo "1. Ejecuta: proot-distro login ubuntu"
echo "2. Dentro de Ubuntu, ejecuta el script de configuración"
echo "3. Luego instala Steam con el script correspondiente"
echo ""
echo "Los scripts se encuentran en: ~/distro_setup/"
EOF

# Hacer todos los scripts ejecutables
chmod +x *.sh

echo "=== TODOS LOS SCRIPTS CREADOS CORRECTAMENTE ==="
echo "Scripts creados en: ~/distro_setup/"
ls -la

echo ""
echo "=== PARA COMENZAR EJECUTA: ==="
echo "cd ~/distro_setup && ./full_setup.sh"
}

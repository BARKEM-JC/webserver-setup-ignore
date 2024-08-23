#!/bin/bash

# Prompt user for installation choices
echo "Install ffmpeg? (y/n)"
read install_ffmpeg
echo "Install Nginx? (y/n)"
read install_nginx
echo "Install OpenCV? (y/n)"
read install_ope

sudo ufw enable
sudo ufw allow 1935/tcp
sudo ufw allow 4952/tcp

# Update package list
sudo apt-get update
sudo apt-get upgrade

sudo apt-get install -y build-essential
sudo apt-get install -y make
sudo apt-get install -y libpcre2-dev
sudo apt-get install -y openssl

# Install common dependencies
sudo apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring make git \
    libpcre3 libpcre3-dev libssl-dev zlib1g-dev yasm libtool autoconf automake \
    nvidia-cuda-toolkit libx264-dev libx265-dev libvpx-dev libfdk-aac-dev libass-dev \
    libfreetype6-dev ubuntu-drivers-common nasm cmake libgtk2.0-dev pkg-config libavcodec-dev \
    libavformat-dev libswscale-dev libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev \
    libcanberra-gtk* libatlas-base-dev gfortran python3-dev python3-pip python3-numpy luajit2 yasm

# Auto-install drivers
#sudo ubuntu-drivers autoinstall

# Install ffmpeg if the user chose to
if [ "$install_ffmpeg" == "y" ]; then
    # Check if ffmpeg is installed
    if command -v ffmpeg >/dev/null 2>&1; then
        echo "ffmpeg is already installed"
    else
        # Install ffmpeg with CUDA support
        cd ~/Downloads

        # Remove existing ffmpeg directory if it exists
        if [ -d "ffmpeg" ]; then
            echo "Removing existing ffmpeg directory..."
            rm -rf ffmpeg
        fi

        git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
        cd ffmpeg

        ./configure --enable-nonfree --enable-cuda --enable-cuvid --enable-nvenc --enable-libnpp
        make
        sudo make install
        cd ~
    fi
fi

# Install Nginx if the user chose to
if [ "$install_nginx" == "y" ]; then
    # Check if Nginx is installed
    if [ -d "/usr/local/nginx" ]; then
        echo "nginx already installed"
    else
        # Add the Nginx repository and set up keyring
        echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
#http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" \
        | sudo tee /etc/apt/sources.list.d/nginx.list

        # Set up repository preferences
	echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
	| sudo tee /etc/apt/preferences.d/99nginx

        # Update package list
        sudo apt-get update

        # Clone the necessary modules
        git clone https://github.com/arut/nginx-rtmp-module.git ~/projects/nginx-rtmp-module
		cd projects
		wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz
		tar -xvf openssl-1.1.1w.tar.gz
        #git clone https://github.com/openresty/lua-nginx-module.git ~/projects/lua-nginx-module
        #git clone https://github.com/vision5/ngx_devel_kit.git ~/projects/ngx_devel_kit
        #git clone https://github.com/openresty/lua-resty-core.git ~/projects/lua-resty-core
        #git clone https://github.com/openresty/lua-resty-lrucache.git ~/projects/lua-resty-lrucache
        #git clone https://luajit.org/git/luajit.git ~/projects/luajit
        #cd ~/projects/luajit
        #make
        #sudo make install

        # Download and install Nginx
        cd ~
        wget https://nginx.org/download/nginx-1.22.1.tar.gz
        tar -zxvf nginx-1.22.1.tar.gz
        cd nginx-1.22.1

        # Set up LuaJIT paths
        #export LUAJIT_LIB=/usr/local/lib/
        #export LUAJIT_INC=/usr/local/include/luajit-2.1
        #export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

	#sudo chown -R $(whoami):$(whoami) /opt
	
        # Configure Nginx with RTMP module
        ./configure \
        --add-module=$HOME/projects/nginx-rtmp-module \
        #--add-module=/home/$(whoami)/projects/lua-nginx-module \
        #--with-ld-opt="-Wl,-rpath,/usr/local/lib" \
        #--add-module=/home/$(whoami)/projects/ngx_devel_kit \
		--with-openssl=$HOME/projects/openssl-1.1.1w
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_stub_status_module
        make
        sudo make install

        # Install additional modules
        #cd ~/projects/lua-resty-core
        #make install PREFIX=/opt/nginx
        #cd ~/projects/lua-resty-lrucache
        #make install PREFIX=/opt/nginx
        cd ~
        
        #!/bin/bash

	# Define the path to the nginx configuration file
	NGINX_CONF="/usr/local/nginx/conf/nginx.conf"

	# Define the lua_package_path directive to be added
	#LUA_PACKAGE_PATH='    lua_package_path "/opt/nginx/lib/lua/?.lua;;";'

	# Backup the existing nginx.conf file
	#if [ -f "$NGINX_CONF" ]; then
	#    cp "$NGINX_CONF" "$NGINX_CONF.bak"
	#    echo "Backup of nginx.conf created at $NGINX_CONF.bak"
	#else
	#    echo "nginx.conf file not found at $NGINX_CONF"
	#    exit 1
	#fi

	# Check if the lua_package_path directive is already present
	#if grep -q 'lua_package_path' "$NGINX_CONF"; then
	#    echo "lua_package_path directive already exists in nginx.conf"
	#else
	    # Add the lua_package_path directive to the http context
	#    sed -i "/http {/a\\$LUA_PACKAGE_PATH" "$NGINX_CONF"
	#    echo "Added lua_package_path directive to nginx.conf"
	#fi
    fi
fi

# Install OpenCV if the user chose to
if [ "$install_opencv" == "y" ]; then
    if python3 -c "import cv2" &> /dev/null; then
        echo "OpenCV is already installed."
    else
        mkdir -p ~/opencv_build
        cd ~/opencv_build
        git clone https://github.com/opencv/opencv.git
        git clone https://github.com/opencv/opencv_contrib.git

        cd ~/opencv_build/opencv
        mkdir build
        cd build
        cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D OPENCV_EXTRA_MODULES_PATH=~/opencv_build/opencv_contrib/modules \
          -D WITH_CUDA=ON \
          -D CUDA_ARCH_BIN="6.1" \  # Adjust for your GPU architecture
          -D WITH_CUDNN=ON \
          -D OPENCV_DNN_CUDA=ON \
          -D WITH_TBB=ON \
          -D BUILD_EXAMPLES=ON ..
        make -j"$(nproc)"
        sudo make install
        sudo ldconfig
    fi
fi

# WSL Auto Proxy Configuration Script

This repository contains the `proxy_toggle.sh` script designed to help users quickly toggle proxy settings on and off in a Windows Subsystem for Linux (WSL) environment. This script adjusts proxy settings for various development tools and system settings, ensuring easy switching between different networking environments like home and office.

## Features

- **Toggle Proxy Settings:** Easily enable or disable proxy settings for the entire system environment and individual applications.
- **Support Multiple Tools:** Configures proxy settings for the shell environment, Docker, Maven, and apt package manager.
- **Check Proxy Availability:** Automatically checks if the proxy is accessible before attempting to apply proxy settings.
- **Safety and Persistence:** Safely modifies configuration files and ensures settings are retained after a reboot.

## Installation

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/reevelau-emsd/ubuntu_proxy_toggle
   ```
2. **Navigate to the Repository Directory:**
   ```bash
   cd ubuntu_proxy_toggle
   ```
3. **Make the Script Executable:**
   ```bash
   chmod +x proxy_toggle.sh
   ```

## Usage

To **enable** proxy settings:
```bash
source ./proxy_toggle.sh enable [proxy_host] [proxy_port] [proxy_user] [proxy_password] [no_proxy]
```

To **disable** proxy settings:
```bash
source ./proxy_toggle.sh disable
```

Replace `[proxy_host]`, `[proxy_port]`, `[proxy_user]`, `[proxy_password]`, and `[no_proxy]` with your actual proxy configuration details.

### Example
Enable proxy:
```bash
source ./proxy_toggle.sh enable proxy.example.com 8080 user password "localhost,127.0.0.1"
```

Disable proxy:
```bash
source ./proxy_toggle.sh disable
```

## Requirements

- **WSL (Windows Subsystem for Linux)**
- **Required Tools:**
  - `nc` (netcat) for checking proxy connectivity.
  - `jq` for JSON manipulations.
  - `xmlstarlet` for XML manipulations.
  - `sponge` for config file inline editing. 
  - `tee` for config file inline editing.
  - `sed` for config file inline editing.
- **Optional Tools:**
  - Docker
  - apt package manager
  - maven

Please ensure all required tools are installed on your system to use the script effectively. Here is an example of installing the dependencies in Ubuntu 20.04.

```bash
sudo apt update \
   && sudo apt install -y netcat jq xmlstarlet moreutils coreutils sed
```

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


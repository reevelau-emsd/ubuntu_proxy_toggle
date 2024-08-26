#!/bin/bash

# Usage:
#   ./proxy_toggle.sh enable [proxy_host] [proxy_port] [proxy_user] [proxy_password] [no_proxy]
#   ./proxy_toggle.sh disable

# Requirements:
#   - nc (netcat) for checking proxy availability
#   - jq for JSON processing (Docker configurations)
#   - xmlstarlet for XML processing (Maven configurations)
#   - sponge for inline editing of config files (/etc/environement)
#   - tee for piping text content to config files
#   - sed for editing config file (/etc/environment)
#   - Optional tools depending on the system: docker, apt

# Quick command to install dependencies
# sudo apt update \
#   && sudo apt install -y netcat jq xmlstarlet moreutils coreutils sed


# Default values for proxy settings
PROXY_HOST="${2:-proxy.example.com}"
PROXY_PORT="${3:-8080}"
PROXY_USER="${4:-<your domain login>}"
PROXY_PASSWORD="${5:-<your domain password>}"
NO_PROXY="${6:-localhost,127.0.0.1}"

# File paths for configurations
APT_PROXY_FILE="/etc/apt/apt.conf.d/95proxy.conf"
DOCKER_CLI_CONFIG="$HOME/.docker/config.json"
DOCKER_DAEMON_CONFIG="/etc/docker/daemon.json"
MAVEN_CONFIG="$HOME/.m2/settings.xml"

# Helper functions
check_proxy() {
    nc -z "$PROXY_HOST" "$PROXY_PORT" &> /dev/null
    echo $?
}

configure_apt() {
    if [ -f "$APT_PROXY_FILE" ]; then
        if [ "$1" == "enable" ]; then
            echo "Acquire::http::Proxy \"http://$PROXY_USER:$PROXY_PASSWORD@$PROXY_HOST:$PROXY_PORT/\";" | sudo tee -a  "$APT_PROXY_FILE"
            echo "Acquire::https::Proxy \"http://$PROXY_USER:$PROXY_PASSWORD@$PROXY_HOST:$PROXY_PORT/\";" | sudo tee -a  "$APT_PROXY_FILE"
        else
            rm "$APT_PROXY_FILE"
        fi
    fi
}

configure_docker_cli() {
    if [ -f "$DOCKER_CLI_CONFIG" ]; then
        if [ "$1" == "enable" ]; then
            jq --arg http_proxy "$HTTP_PROXY" \
                --arg https_proxy "$HTTPS_PROXY" \
                --arg no_proxy "$NO_PROXY" \
                '.proxies.default = {"httpProxy": $http_proxy, "httpsProxy": $https_proxy, "noProxy": $no_proxy}' "$DOCKER_CLI_CONFIG" | sponge "$DOCKER_CLI_CONFIG"
        else
            jq 'del(.proxies)' "$DOCKER_CLI_CONFIG" | sponge "$DOCKER_CLI_CONFIG"
        fi
    fi
}

configure_docker_daemon() {
    if [ -f "$DOCKER_DAEMON_CONFIG" ]; then
        if [ "$1" == "enable" ]; then
            jq --arg http_proxy "$HTTP_PROXY" \
                --arg https_proxy "$HTTPS_PROXY" \
                --arg no_proxy "$NO_PROXY" \
                '.proxies.default = {"http-proxy": $http_proxy, "https-proxy": $https_proxy, "no-proxy": $no_proxy}' "$DOCKER_DAEMON_CONFIG" | sudo sponge "$DOCKER_DAEMON_CONFIG"

            sudo systemctl restart docker
        else
            jq 'del(.proxies)' "$DOCKER_DAEMON_CONFIG" > tmp.json | sudo sponge "$DOCKER_DAEMON_CONFIG"
            sudo systemctl restart docker
        fi
    fi
}

configure_maven() {
    if [ -f "$MAVEN_CONFIG" ]; then
        if [ "$1" == "enable" ]; then
            cp $MAVEN_CONFIG "$MAVEN_CONFIG".bak

            xmlstarlet ed -N x="http://maven.apache.org/SETTINGS/1.0.0" \
                -s "/x:settings" -t elem -n "proxies" -v "" \
                -s "/x:settings/x:proxies" -t elem -n "proxy" -v "" "$MAVEN_CONFIG" | sponge "$MAVEN_CONFIG"

            xmlstarlet ed -N x="http://maven.apache.org/SETTINGS/1.0.0" \
                -s "/x:settings/x:proxies/x:proxy" -t elem -n "id" -v "http_proxy" \
                -s "/x:settings/x:proxies/x:proxy" -t elem -n "active" -v "true" \
                -s "/x:settings/x:proxies/x:proxy" -t elem -n "protocol" -v "http" \
                -s "/x:settings/x:proxies/x:proxy" -t elem -n "host" -v "$PROXY_HOST" \
                -s "/x:settings/x:proxies/x:proxy" -t elem -n "port" -v "$PROXY_PORT" \
                -s "/x:settings/x:proxies/x:proxy" -t elem -n "username" -v "$PROXY_USER" \
                -s "/x:settings/x:proxies/x:proxy" -t elem -n "password" -v "$PROXY_PASSWORD" \
                -s "/x:settings/x:proxies/x:proxy" -t elem -n "nonProxyHosts" -v "$NO_PROXY" \
                "$MAVEN_CONFIG" | sponge "$MAVEN_CONFIG"
        else
            cp $MAVEN_CONFIG "$MAVEN_CONFIG".bak
            xmlstarlet ed -N x="http://maven.apache.org/SETTINGS/1.0.0" -d "/x:settings/x:proxies" "$MAVEN_CONFIG" | sponge "$MAVEN_CONFIG"
        fi
    fi
}

# Remove proxy variables from /etc/environment
remove_env_vars() {
    sudo sed -i '/PROXY/Id' /etc/environment
}

# Toggle proxy based on command line argument
case "$1" in
    enable)
        if [ $(check_proxy) -eq 0 ]; then
            export HTTP_PROXY="http://$PROXY_USER:$PROXY_PASSWORD@$PROXY_HOST:$PROXY_PORT/"
            export HTTPS_PROXY="http://$PROXY_USER:$PROXY_PASSWORD@$PROXY_HOST:$PROXY_PORT/"
            export NO_PROXY="$NO_PROXY"
            export http_proxy="http://$PROXY_USER:$PROXY_PASSWORD@$PROXY_HOST:$PROXY_PORT/"
            export https_proxy="http://$PROXY_USER:$PROXY_PASSWORD@$PROXY_HOST:$PROXY_PORT/"
            export no_proxy="$NO_PROXY"
            
            echo -e "\nHTTP_PROXY=\"$HTTP_PROXY\"\nHTTPS_PROXY=\"$HTTPS_PROXY\"\nNO_PROXY=\"$NO_PROXY\"" | sudo tee -a /etc/environment
            echo -e "\nhttp_proxy=\"$HTTP_PROXY\"\nhttps_proxy=\"$HTTPS_PROXY\"\nno_proxy=\"$NO_PROXY\"\n" | sudo tee -a /etc/environment
            sudo sed -i '/^\s*$/d' /etc/environment

             # Export these variables in shell profiles for interactive shells
            echo 'export http_proxy='$HTTP_PROXY | sudo tee -a /etc/profile.d/proxy.sh
            echo 'export https_proxy='$HTTPS_PROXY | sudo tee -a /etc/profile.d/proxy.sh
            echo 'export no_proxy='$NO_PROXY | sudo tee -a /etc/profile.d/proxy.sh
            echo 'export HTTP_PROXY='$HTTP_PROXY | sudo tee -a /etc/profile.d/proxy.sh
            echo 'export HTTPS_PROXY='$HTTPS_PROXY | sudo tee -a /etc/profile.d/proxy.sh
            echo 'export NO_PROXY='$NO_PROXY | sudo tee -a /etc/profile.d/proxy.sh

            configure_apt "enable"
            configure_docker_cli "enable"
            configure_docker_daemon "enable"
            configure_maven "enable"

            echo "Proxy settings have been enabled."
        else
            echo "Proxy server is not reachable. Aborting."
        fi
        ;;
    disable)
        unset HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy
        remove_env_vars
        sudo sed -i '/^\s*$/d' /etc/environment

        sudo rm -f /etc/profile.d/proxy.sh

        configure_apt "disable"
        configure_docker_cli "disable"
        configure_docker_daemon "disable"
        configure_maven "disable"

        echo "Proxy settings have been disabled."
        ;;
    *)
        echo "Usage: $0 [enable|disable] [proxy_host] [proxy_port] [proxy_user] [proxy_password] [no_proxy]"
        ;;
esac


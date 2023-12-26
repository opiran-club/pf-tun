#!/usr/bin/env bash
set -e

color () {
    local color=$1
    local text=$2
    
    case $color in
        "red")
        printf "\e[91m${text}\e[0m\n";;
        "green")
        printf "\e[92m${text}\e[0m\n";;
        "yellow")
        printf "\e[93m${text}\e[0m\n";;
        "blue")
        printf "\e[94m${text}\e[0m\n";;
        "magenta")
        printf "\e[95m${text}\e[0m\n";;
        "cyan")
        printf "\e[96m${text}\e[0m\n";;
        *)
            echo "${text}"
        ;;
    esac
}

check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}

CYAN="\e[96m"
MAGENTA="\e[95m"
GREEN="\e[92m"
YELLOW="\e[93m"
RED="\e[91m"
NC="\e[0m"
BOLD=$(tput bold)

press_enter() {
    color red "\nPress Enter to continue... "
    read
}

root() {
if [ "$(id -u)" != "0" ]; then
    color red "This command must be run as root."
    exit 1
fi
}
root

frps() {
if ! command -v docker &> /dev/null
then
clear
  title="Configure FRP server side"
    logo
    echo ""
    echo -e "${BLUE}$title ${NC}"
    echo ""
    printf "+---------------------------------------------+\n" 
  echo ""
    echo -e "${YELLOW}Docker is not installed. Installing Docker now...${NC}"
    echo ""
    echo -e "${RED}Please wait, it might takes a while...${NC}"
    apt-get install docker -y > /dev/null 2>&1
    apt-get install docker-compose -y > /dev/null 2>&1
            display_fancy_progress 20
fi
echo ""
echo -ne "${YELLOW}Port for the frps service? ${RED}[Enter blank for default port : 7000] ${GREEN}[Enter 'r' to generate a random port] ${YELLOW}[or enter a port]: "
read port_choice
if [[ "$port_choice" == "r" ]]; then
    port=$(shuf -i 7001-9000 -n 1)
elif [[ -z "$port_choice" ]]; then
    port=7000
else
    port=$port_choice
fi
echo ""
echo -ne "${YELLOW}Port for the HTTP service? ${RED}[Press enter for default port of 80] ${YELLOW}[or enter a port]: "
read http_choice
if [[ -z "$http_choice" ]]; then
    http=80
else
    http=$http_choice
fi
echo ""
echo -ne "${YELLOW}Port for the HTTPS service? ${RED}[Press enter for default port of 443] ${YELLOW}[or enter a port]: "
read https_choice
if [[ -z "$https_choice" ]]; then
    https=443
else
    https=$https_choice
fi
echo ""
echo -ne "${YELLOW}Generate a random token or enter a password for the frps service? ${RED}[Press enter to generate a random token] ${YELLOW}or enter a password: "
read token_choice
if [[ -z "$token_choice" ]]; then
    token=$(openssl rand -hex 16)
else
    token=$token_choice
fi
if [ ! -d "./frps/tmp" ]; then
    mkdir -p "./frps/tmp"
else
    rm -rf "./frps" && mkdir -p "./frps/tmp"
fi
cat >> "./frps/frps.ini" << EOF
[common]
bind_addr = 0.0.0.0
bind_port = $port
vhost_http_port = $http
vhost_https_port = $https
dashboard_tls_mode = false
enable_prometheus = true
log_file = /tmp/frps.log
log_level = info
log_max_days = 3
disable_log_color = false
detailed_errors_to_client = true
authentication_method = token
authenticate_heartbeats = false
authenticate_new_work_conns = false
token = $token
max_pool_count = 5
max_ports_per_client = 0
tls_only = false
EOF
cat >> "./frps/docker-compose.yml" << EOF
version: '3'
services:
    frps:
        image: snowdreamtech/frps:latest
        container_name: frps
        network_mode: "host"
        restart: always
        volumes:
            - "$PWD/frps/frps.ini:/etc/frp/frps.ini"
            - "$PWD/frps/tmp:/tmp:rw"
EOF
echo ""
echo -e "${YELLOW}Starting FRP server...${NC}"
docker-compose -f "./frps/docker-compose.yml" up -d
sleep 3
if [ -f "./frps/tmp/frps.log" ]; then
    echo -e "${GREEN}FRP server started successfully.${NC}"
    sudo cat "./frps/tmp/frps.log"
else
    echo -e "${RED}Error: FRP server failed to start. Log file not found.${NC}"
fi
press_enter
clear
title="Configure FRP server side"
    logo
    echo ""
    echo -e "${BLUE}$title ${NC}"
    echo ""
    printf "+---------------------------------------------+\n" 
  echo ""
echo -e "${MAGENTA}Please save below information to to use on your client server.${NC}"
echo ""
echo -e "${YELLOW}The address FRPS: ${GREEN}$(curl -s ifconfig.co)${NC}"
echo -e "${YELLOW}Service Port: ${GREEN}$port${NC}"
echo -e "${YELLOW}Token: ${GREEN}$token${NC}"
echo -e "${YELLOW}HTTP Port: ${GREEN}$http${NC}"
echo -e "${YELLOW}HTTPS Port: ${GREEN}$https${NC}"
echo ""
press_enter
    }

    frpc() {
    rm -rf /etc/resolv.conf
touch /etc/resolv.conf
echo 'nameserver 178.22.122.100' >> /etc/resolv.conf
echo 'nameserver 78.157.42.101' >> /etc/resolv.conf
if ! command -v docker &> /dev/null
then
clear
title="Configure FRP client side on IRAN"
    logo
    echo ""
    echo -e "${BLUE}$title ${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n" 
  echo ""
    echo -e "${YELLOW}Docker is not installed. Installing Docker now...${NC}"
    echo ""
    echo -e "${RED}Please wait, it might takes a while...${NC}"
    rm -rf /etc/resolv.conf
    touch /etc/resolv.conf
    echo 'nameserver 178.22.122.100' >> /etc/resolv.conf
    echo 'nameserver 78.157.42.101' >> /etc/resolv.conf
    sleep 3
    secs=3
    while [ $secs -gt 0 ]; do
        echo -ne "Continuing in $secs seconds\033[0K\r"
        sleep 1
        : $((secs--))
    done
    apt-get install docker -y > /dev/null 2>&1
    apt-get install docker-compose -y > /dev/null 2>&1
            display_fancy_progress 20
fi
    echo -ne "\e[33mEnter the remote Server (Kharej) ip address or domain: ${NC}: "
    read frpsip
    echo ""
    echo -ne "\e[33mEnter the FRP(S) Service port ${RED}[Enter blank for default port : 7000]${YELLOW}[or enter a port]: ${NC} "
    read port
        if [[ -z "$port" ]]; then
        port=7000
        else
        port=$port
        fi
        echo ""
    echo -ne "${YELLOW}Enter the FRP(S) Service token (Password):  ${NC}"
    read token
    echo ""
    echo -ne "${YELLOW}Enter the port of FRP(C) admin console ${RED}[press Enter for default **7400** or manual to input a port]: ${NC}"  
    read cport
        if [ -z "$cport" ]; then
            cport=7400
        else
            Cport=$Cport
        fi
        echo ""
    echo -ne "${YELLOW}Enter the username of FRP(C) console ${RED}[press Enter for default **admin** or manual to input a name]: ${NC}"  
    read cname
        if [ -z "$cname" ]; then
            cname=admin
        else
            cname=$cname
        fi
        echo ""
    echo -ne "${YELLOW}Enter the Console Password ${RED}[Press Enter for generate a random password] :  ${NC}"  
    read cpasswd
        if [ -z "$cpasswd" ]; then
            ctoken=$(openssl rand -hex 12)
        else
            ctoken=$cpasswd
        fi
        if [ ! -d "./frpc/tmp" ]; then
            mkdir -p ./frpc/tmp
        else
            rm -rf ./frpc && mkdir -p ./frpc/tmp
        fi
cat >> frpc/frpc.ini << EOF
[common]
server_addr = $frpsip
server_port = $port
token = $token
log_file = /tmp/frpc.log
log_level = info
log_max_days = 3
disable_log_color = false
admin_addr = 0.0.0.0
admin_port = $cport
admin_user = $cname
admin_pwd = $ctoken
EOF
cat >> frpc/docker-compose.yml << EOF
version: '3'
services:
    frpc:
        image: snowdreamtech/frpc:latest
        container_name: frpc
        network_mode: "host"
        restart: always
        volumes:
            - ./frpc.ini:/etc/frp/frpc.ini
            - ./tmp:/tmp:rw
EOF
docker-compose -f ./frpc/docker-compose.yml up -d
sleep 3
sudo cat ./frpc/tmp/frpc.log
press_enter
clear
rm -rf /etc/resolv.conf
touch /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
echo 'nameserver 1.1.1.1' >> /etc/resolv.conf
title="FRP Console Panel"
    logo
    echo ""
    echo -e "${BLUE}$title ${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n" 
  echo ""
echo -e "${MAGENTA}Please use below information to Login console to monitor your services.${NC}"
echo ""
echo -e "${YELLOW}The address of console: ${GREEN}http://$frpsip:$cport${NC}"
echo -e "${YELLOW}The username of console: ${GREEN}$cname${NC}"
echo -e "${YELLOW}The password of console: ${GREEN}$ctoken${NC}"
echo ""
press_enter
    }

    uninstall_frp() {
    clear
    echo ""
    echo -e "${YELLOW}Uninstalling FRP service, please wait...${NC}"
    if docker ps -a --format '{{.Names}}' | grep -q "^frps$"; then
        docker stop frps
        docker rm frps
    fi
    if docker ps -a --format '{{.Names}}' | grep -q "^frpc$"; then
        docker stop frpc
        docker rm frpc
    fi
    rm -rf ./frpc
    docker rmi snowdreamtech/frpc:latest
    docker rmi snowdreamtech/frps:latest
    rm -f ./frps/frps.ini
    rm -f ./frpc/frpc.ini
    echo ""
    echo -e "${GREEN}FRP has been uninstalled.${NC}"
}

display_frp_config() {
    echo -e "${YELLOW}Displaying FRP Configuration...${NC}"
    if [ -f "./frps/frps.ini" ]; then
        echo -e "${GREEN}FRP Server Configuration:${NC}"
        cat "./frps/frps.ini"
    fi
    if [ -f "./frpc/frpc.ini" ]; then
        echo -e "${GREEN}FRP Client Configuration:${NC}"
        cat "./frpc/frpc.ini"
    fi

    if [ -f "./frpc/tmp/frpc.log" ]; then
        echo -e "${GREEN}FRP Client Log:${NC}"
        cat "./frpc/tmp/frpc.log"
    fi

    if [ -f "./frps/tmp/frps.log" ]; then
        echo -e "${GREEN}FRP Server Log:${NC}"
        cat "./frps/tmp/frps.log"
    fi
}

while true; do
clear
title_text="OPIran FRP Tunnel"
clear
echo -e "              ${MAGENTA}${title_text}${NC}"
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN}  1. ${YELLOW}Configure FRP(s) - (Kharej) or server${NC}"
echo -e "${CYAN}  2. ${YELLOW}Configure FRP(c) - (Iran) or client${NC}"
echo -e "${CYAN}  3. ${YELLOW}Uninstall FRP - client and server${NC}"
echo -e "${CYAN}  4. ${YELLOW}Display FRP Configuration${NC}"
echo ""
echo -e "${CYAN}  0. ${RED}Back${NC}"
echo ""
echo -ne "${GREEN}Enter your choice: ${NC}"
read choice
case $choice in
    1)
    frps
    ;;
    2)
    frpc
    ;;
    3)
    uninstall_frp
    ;;
    4)
    display_frp_config
    ;;
    0)
    echo -e "${YELLOW}Main Menu.${NC}"
    break
    ;;
    *)
    echo -e "${RED}Invalid option.${NC}"
    press_enter
    ;;
esac
done

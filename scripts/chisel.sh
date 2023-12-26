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

preparation_chisel() {
    clear
    if [ ! -f "/usr/local/bin/chisel" ]; then
        color red "Chisel is not installed, let's install it"
        apt-get update
        wget https://i.jpillora.com/chisel! > /dev/null
        bash chisel! > /dev/null
        color green "Latest chisel release was installed successfully"
    else
        color green "Chisel is already installed, let's move on to the next step"
    fi
}

chisel_key() {
    key_path="/root/chisel_server.key"
    chisel server --keygen ${key_path} &
    color green "Key was generated successfully at $key_path"
}

chisel server --keygen /root/chisel_server.key
    chisel_direct_kharej() {
        clear
        echo -e "${MAGENTA}Direct chisel tunnel (Server part) ${NC}"
        echo && echo
        preparation_chisel
        echo -ne "${YELLOW}Enter Kharej (remote) port: ${NC}"
        read port
        key_path="/root/chisel_server.key"
        service_name="direct_server_$port"
        service_file="/etc/systemd/system/${service_name}.service"
        chisel_command="chisel server --keyfile $key_path --port $port --host $host --keepalive 25s"
        description="Direct chisel tunnel server"
        
    while true; do
    echo 
    echo -e "$MAGENTA$BOLD             IP version ${NC}"
    printf "+---------------------------------------------+\n"
    echo && echo
    echo -e "$MAGENTA$BOLD  supported private and public ipv4 and ipv6 ${NC}"
    echo && echo
    color red "!!TIP!!"
    color magenta "If you want to use IPv6, both servers should support IPv6."
    echo && echo
    echo -e "${CYAN}  1${NC}) ${YELLOW}IPV4${NC}"
    echo -e "${CYAN}  2${NC}) ${YELLOW}IPV6${NC}"
    echo
    echo -e "${CYAN}  0${NC}) ${RED}Back${NC}"
    echo
    echo -ne "${GREEN}Select an option ${RED}[1-0]: ${NC}"
    read version

        case $version in
            1)
                color green "You picked IPV4"
                host="0.0.0.0"
                chisel_key
                echo "[Unit]
                Description=$description
                After=network.target

                [Service]
                ExecStart=$chisel_command
                Restart=always
                RestartSec=21600
                User=root

                [Install]
                WantedBy=multi-user.target" > "$service_file"
                systemctl daemon-reload
                systemctl enable "$service_name"
                systemctl start "$service_name"
                create_cronjob "$service_name"
                color green "Chisel server was successfully run. Let's go to your IRAN (local) server."
                echo && echo
                color green "Server IP: $host"
                echo && echo
                color green "Server Port: $port"                
                press_enter
                break
                ;;
            2)
                color green "You picked IPV6"
                echo -ne "${YELLOW}Enter IPv6 address of Kharej (remote): ${NC}"
                read host_kharej
                echo ""
                host="[$host_kharej]"
                chisel_key
                echo "[Unit]
                Description=$description
                After=network.target

                [Service]
                ExecStart=$chisel_command
                Restart=always
                RestartSec=21600
                User=root

                [Install]
                WantedBy=multi-user.target" > "$service_file"
                systemctl daemon-reload
                systemctl enable "$service_name"
                systemctl start "$service_name"
                create_cronjob "$service_name"
                color green "Chisel server was successfully run. Let's go to your IRAN (local) server."
                echo && echo
                color green "Server IP: $host"
                echo && echo
                color green "Server Port: $port"
                press_enter
                break
                ;;
            0)
                color red "Exiting..."
                break
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                return
                ;;
        esac
    done
    }

    chisel_direct_iran() {
        clear
        echo -e "${MAGENTA}Direct chisel tunnel (Client part) ${NC}"
        echo && echo
        preparation_chisel
        echo && echo
        color red "!!TIP!!"
        color magenta "Paste the port that you copied from Kharej (remote)."
        echo && echo
        echo -ne "${YELLOW}Enter Kharej port (remote server): ${NC}"
        read port
        echo ""
        echo -ne "${YELLOW}Enter Host address that you copied from Kharej (remote): ${NC}"
        read host
        echo ""
        echo -ne "${YELLOW}Select your IP version [${RED}1-${GREEN}IPv4 , ${RED}2-${GREEN}IPv6]: ${NC}"
        read version
        echo ""
        case $version in
            1)
                local_ip="0.0.0.0"
                remote_ip="$host"
                ;;
            2)
                echo -e "${YELLOW}Enter IPv6 address of Iran (local): ${NC}"
                read -r local_ip
                remote_ip="[$host]"
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                return
                ;;
        esac

        echo ""
        echo -ne "${YELLOW}Select your desired protocol [${RED}1-${GREEN}TCP , ${RED}2-${GREEN}UDP]: ${NC}"
        read protocol
        echo ""
        case $protocol in
            1)
                protocol="tcp"
                ;;
            2)
                protocol="udp"
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                return
                ;;
        esac
        echo && echo
        color red "!!TIP!!"
        color magenta "Its good idea to use same port with kharej"
        echo
        echo -ne "${YELLOW}Enter Iran (local) port: ${NC}"
        read local_port

        service_name="direct_client_$local_port"
        service_file="/etc/systemd/system/${service_name}.service"
        chisel_command="chisel client --keepalive 25s $remote_ip:$port $local_ip:$local_port/$protocol"
        description="Direct chisel tunnel client"

                echo "[Unit]
                Description=$description
                After=network.target

                [Service]
                ExecStart=$chisel_command
                Restart=always
                RestartSec=21600
                User=root

                [Install]
                WantedBy=multi-user.target" > "$service_file"
                systemctl daemon-reload
                systemctl enable "$service_name"
                systemctl start "$service_name"
                create_cronjob "$service_name"
        create_cronjob "$service_name"
        clear
        color green "Chisel tunnel was successfully established"
        echo ""
        press_enter
    }

    chisel_reverse_kharej() {
        preparation_chisel
        echo -e "${MAGENTA}Reverse chisel tunnel (Client part) ${NC}"
        echo ""
        color red "!!TIP!!"
        color magenta "Paste the port that you copied from Iran."
        echo ""
        color magenta "Both servers should support IPv6 if you select IPv6."
        color magenta "Supported private and public IP."
        echo ""
        echo -ne "${YELLOW}Enter Iran port:${RED}(recommended: 443) ${NC}"
        read port
        echo ""
        echo -ne "${YELLOW}Enter Host (IP) address that you copied from Iran: ${NC}"
        read host
        echo ""
        echo -ne "${YELLOW}Select your IP version [${RED}1-${GREEN}IPv4 , ${RED}2-${GREEN}IPv6]: ${NC}"
        read version
        echo ""
        case $version in
            1)
                remote_ip="$host"
                ;;
            2)
                remote_ip="[$host]"
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                return
                ;;
        esac

        echo ""
        echo -ne "${YELLOW}Select your desired protocol [${RED}1-${GREEN}TCP , ${RED}2-${GREEN}UDP] ${RED} (recommended: TCP) : ${NC}"
        read protocol
        echo ""
        case $protocol in
            1)
                protocol="tcp"
                ;;
            2)
                protocol="udp"
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                return
                ;;
        esac

        echo -ne "${YELLOW}Enter Kharej port:${RED}(recommended: same Iran port) ${NC}"
        read remote_port
        echo ""

        service_name="reverse_client_$remote_port"
        service_file="/etc/systemd/system/${service_name}.service"
        chisel_command="chisel client --keepalive 25s $remote_ip:$port R:localhost:$remote_port/$protocol"
        description="Reverse chisel service client"

                echo "[Unit]
                Description=$description
                After=network.target

                [Service]
                ExecStart=$chisel_command
                Restart=always
                RestartSec=21600
                User=root

                [Install]
                WantedBy=multi-user.target" > "$service_file"
                systemctl daemon-reload
                systemctl enable "$service_name"
                systemctl start "$service_name"
                create_cronjob "$service_name"
        create_cronjob "$service_name"
        clear
        color green "Reverse chisel tunnel was successfully established"
        echo ""
        press_enter
    }

    chisel_reverse_iran() {
        clear
        echo -e "${MAGENTA}Reverse chisel tunnel (Server part) ${NC}"
        echo ""
        preparation_chisel
        echo ""
        echo -ne "${YELLOW}Enter Iran (tunnel) port: ${NC}"
        read port
        echo ""
        key_path="/root/chisel_server.key"
        service_name="reverse_server_$port"
        service_file="/etc/systemd/system/${service_name}.service"
        chisel_command="chisel server --keyfile $key_path --reverse --port $port --host $host --keepalive 25s"
        description="Chisel reverse Service server"
        while true; do
    echo 
    echo -e "$MAGENTA$BOLD             IP version ${NC}"
    printf "+---------------------------------------------+\n"
    echo && echo
    echo -e "$MAGENTA$BOLD  supported private and public ipv4 and ipv6 ${NC}"
    echo && echo
    color red "!!TIP!!"
    color magenta "If you want to use IPv6, both servers should support IPv6."
    echo && echo
    echo -e "${CYAN}  1${NC}) ${YELLOW}IPV4${NC}"
    echo -e "${CYAN}  2${NC}) ${YELLOW}IPV6${NC}"
    echo
    echo -e "${CYAN}  0${NC}) ${RED}Back${NC}"
    echo
    echo -ne "${GREEN}Select an option ${RED}[1-0]: ${NC}"
    read version

        case $version in
            1)
                color green "You picked IPV4"
                host="0.0.0.0"
                chisel_key
                echo "[Unit]
                Description=$description
                After=network.target

                [Service]
                ExecStart=$chisel_command
                Restart=always
                RestartSec=21600
                User=root

                [Install]
                WantedBy=multi-user.target" > "$service_file"
                systemctl daemon-reload
                systemctl enable "$service_name"
                systemctl start "$service_name"
                create_cronjob "$service_name"
                color green "Chisel server was successfully run. Let's go to your Kharej server."
                echo && echo
                color green "Server IP: $host"
                echo && echo
                color green "Server Port: $port"                
                press_enter
                break
                ;;
            2)
                color green "You picked IPV6"
                echo -ne "${YELLOW}Enter IPv6 address of IRAN: ${NC}"
                read host_kharej
                echo ""
                host="[$host_kharej]"
                chisel_key
                echo "[Unit]
                Description=$description
                After=network.target

                [Service]
                ExecStart=$chisel_command
                Restart=always
                RestartSec=21600
                User=root

                [Install]
                WantedBy=multi-user.target" > "$service_file"
                systemctl daemon-reload
                systemctl enable "$service_name"
                systemctl start "$service_name"
                create_cronjob "$service_name"
                color green "Chisel server was successfully run. Let's go to your Kharej server."
                echo && echo
                color green "Server IP: $host"
                echo && echo
                color green "Server Port: $port"
                press_enter
                break
                ;;
            0)
                color red "Exiting..."
                break
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                return
                ;;
        esac
    done
    }

create_cronjob() {
    local cron_schedule="@reboot"
    local service_name="$1"
    (crontab -l ; echo "$cron_schedule systemctl restart $service_name") | crontab -
    color green "Cron job created successfully, restart service after every reboot"
}

    clear
    while true; do
    title_text="Chisel Tunnel"
    echo ""
    echo ""
    echo -e "$MAGENTA$BOLD             ${title_text} ${NC}"
    printf "+---------------------------------------------+\n"
    echo ""
    echo -e "$MAGENTA$BOLD  supported private and public ipv4 and ipv6 ${NC}"
    echo ""
    echo -e "${CYAN}  1${NC}) ${YELLOW}Chisel direct${NC}"
    echo -e "${CYAN}  2${NC}) ${YELLOW}Chisel reverse${NC}"
    echo ""
    echo -e "${CYAN}  0${NC}) ${RED}Back${NC}"
    echo ""
    echo -ne "${GREEN}Select an option ${RED}[1-2]: ${NC}"
    read choice1

    case $choice1 in

    1)
            clear
            while true; do
                title_text="Chisel Direct"
                echo ""
                echo ""
                echo -e "$MAGENTA$BOLD             ${title_text} ${NC}"
                printf "+---------------------------------------------+\n"
                echo ""
                echo -e "$MAGENTA$BOLD  In this method config kharej at first ${NC}"
                echo ""
                echo -e "${CYAN}  1${NC}) ${YELLOW}Kharej (remote)${NC}"
                echo -e "${CYAN}  2${NC}) ${YELLOW}Iran (local)${NC}"
                echo ""
                echo -e "${CYAN}  0${NC}) ${RED}Back${NC}"
                echo ""
                echo -ne "${GREEN}Select an option ${RED}[1-2]: ${NC}"
                read choice1

                case $choice1 in

                1)
                    chisel_direct_kharej
                    ;;
                2)
                    chisel_direct_iran
                    ;;
                0)
                    echo "Exiting..."
                    break
                    ;;
                *)
                    echo "Invalid option"
                    ;;
                esac
            done
        ;;
    2)
        clear
        while true; do
        title_text="Chisel Reverse"
        echo ""
        echo ""
        echo -e "$MAGENTA$BOLD             ${title_text} ${NC}"
        printf "+---------------------------------------------+\n"
        echo ""
        echo -e "$MAGENTA$BOLD  In this method config Iran at first ${NC}"
        echo ""
        echo -e "${CYAN}  1${NC}) ${YELLOW}Kharej (remote)${NC}"
        echo -e "${CYAN}  2${NC}) ${YELLOW}Iran (local)${NC}"
        echo ""
        echo -e "${CYAN}  0${NC}) ${RED}Back${NC}"
        echo ""
        echo -ne "${GREEN}Select an option ${RED}[1-2]: ${NC}"
        read choice1

        case $choice1 in

                1)
                chisel_reverse_kharej
                    ;;
                2)
                chisel_reverse_iran
                    ;;
                0)
                    echo "Exiting..."
                    break
                    ;;
                *)
                    echo "Invalid option"
                    ;;
                esac
            done
        ;;
    0)
        echo "Exiting..."
        break
        ;;
    *)
        echo "Invalid option"
        ;;
    esac
done

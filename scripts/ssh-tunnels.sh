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

    ssh_tunnel() {
        clear
        sshd_config="/etc/ssh/sshd_config"
        sed -i '/^#AllowTcpForwarding/c\AllowTcpForwarding yes' "$sshd_config"
        sed -i '/^#GatewayPorts/c\GatewayPorts yes' "$sshd_config"
        service ssh restart

        echo ""
        echo -e "${GREEN}Starting a New SSH tunnel...${NC}"
        echo ""
        echo -e "${GREEN}Creating this on local server (Iran)${NC}"
        echo ""
        echo -ne "${YELLOW}Enter the local port to forward ${GREEN}(default: 22): ${NC}"
        read local_port
        local_port=${local_port:-22}

        echo ""
        echo -ne "${YELLOW}Enter the destination IP address (Kharej) (v4 / v6 supported): ${NC}"
        read ip_kharej

        echo ""
        echo -ne "${YELLOW}Enter the destination port on Kharej ${GREEN}(default: 22): ${NC}"
        read port_remote
        port_remote=${port_remote:-22}

            echo ""
            echo -e "${YELLOW}cronjob to restart the tunnel ${GREEN}[1-4]${NC}"
            echo -e "  ${GREEN}1. Reboot${NC}"
            echo -e "  ${GREEN}2. Daily${NC}"
            echo -e "  ${GREEN}3. Weekly${NC}"
            echo -e "  ${GREEN}4. Hourly${NC}"
            echo -ne "${YELLOW}your choice ${GREEN}[1-4] (default: Reboot): ${NC}"
            read choice
            choice=${choice:-1}

            case "$choice" in
                1)
                    cron_schedule="@reboot"
                    ;;
                2)
                    cron_schedule="@daily"
                    ;;
                3)
                    cron_schedule="@weekly"
                    ;;
                4)
                    cron_schedule="@hourly"
                    ;;
                *)
                    cron_schedule="@reboot"
                    ;;
            esac


            ssh_tunnel_command="ssh -L $local_port:localhost:$port_remote root@$ip_kharej"
            echo ""
            echo ""
            cron_command="${cron_schedule} ssh -L $local_port:localhost:$port_remote root@$ip_kharej"
            (crontab -l ; echo "$cron_command") | crontab -
            
            echo ""
            echo -e "${GREEN}SSH tunnel set up and added to cron job @${time}.${NC}"
            echo ""
            echo -e "         ${NC}Now The SSH tunnel will be established on system startup as a system file${NC}"
            echo -e "\n                  ${RED}to move on press ENTER...${NC}"
            read

            echo "[Unit]
            Description=OPIran SSH Tunnel
            After=network.target

            [Service]
            ExecStart=/usr/bin/ssh -n -L $local_port:localhost:$port_remote root@$ip_kharej
            Restart=on-failure
            RestartSec=10

            [Install]
            WantedBy=multi-user.target" > /etc/systemd/system/ssh-tunnel-$local_port.service

            systemctl daemon-reload
            systemctl start ssh-tunnel-$local_port
            systemctl enable ssh-tunnel-$local_port
            sleep 3
            systemctl restart ssh-tunnel-$local_port
            echo ""
            echo ""
            echo -e "${GREEN}ALL TASK WERE SUCCESFULLY DONE, SO KEEP ENJOYING THE TUNNEL${NC}"
            echo ""
            echo -e "         ${YELLOW}THANKS TO CHOOSING ME, OPIRAN :D ${NC}"

        echo ""
        echo -e "${GREEN}SSH tunnel set up successfully${NC}"
    }

    Reverse_ssh() {
            clear
            echo ""
            echo -e "${GREEN}Starting a New Reverse SSH tunnel...${NC}"
            echo ""
            echo -e "${GREEN}Lets create this on Remote server (Kharej)${NC}"
            echo ""
            echo -ne "${YELLOW}Enter the local port to forward ${GREEN}(default: 22): ${NC}"
            read local_port
            local_port=${local_port:-22}

            echo ""
            echo -ne "${YELLOW}Enter the destination IP address (Iran): ${NC}"
            read ip_iran

            echo ""
            echo -ne "${YELLOW}Enter the destination port on Iran ${GREEN}(default: 22): ${NC}"
            read port_remote
            port_remote=${port_remote:-22}

            echo ""
            echo -ne "${YELLOW}Enter the SSH port of Iran ${GREEN}(default: 22): ${NC}"
            read ssh_port
            ssh_port=${ssh_port:-22}

            echo ""
            if [ ! -f ~/.ssh/id_rsa ]; then
                ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
            fi

            echo
            echo -e "${RED}Attention!!${NC}"
            echo
            echo -e "${GREEN}copy and paste below command in your local (IRAN) terminal${NC}"
            echo -e "${MAGENTA}sed -i '/^#AllowTcpForwarding/c\AllowTcpForwarding yes' "/etc/ssh/sshd_config" && sed -i '/^#GatewayPorts/c\GatewayPorts yes' "/etc/ssh/sshd_config" && service ssh restart ${NC}"
            echo ""
            echo -e "${GREEN}your kharej public key saved at =>>  ${MAGENTA}/root/.ssh/id_rsa ${NC}" 
            echo    
            echo -e "${GREEN}save your public key to Iran server at =>> ${MAGENTA}/root/.ssh/ ${NC}"

            ssh_tunnel_command="ssh -N -R *:$local_port:localhost:$port_remote root@$ip_iran"

            echo ""
            echo -e "${GREEN}Reverse SSH tunnel has been established.${NC}"
            echo ""
            echo -e "${YELLOW}cronjob to restart the tunnel ${GREEN}[1-4]${NC}"
            echo -e "  ${GREEN}1. Reboot${NC}"
            echo -e "  ${GREEN}2. Daily${NC}"
            echo -e "  ${GREEN}3. Weekly${NC}"
            echo -e "  ${GREEN}4. Hourly${NC}"
            echo -ne "${YELLOW}your choice ${GREEN}[1-4] (default: Reboot): ${NC}"
            read choice
            choice=${choice:-1}

            case "$choice" in
                1)
                    cron_schedule="@reboot"
                    ;;
                2)
                    cron_schedule="@daily"
                    ;;
                3)
                    cron_schedule="@weekly"
                    ;;
                4)
                    cron_schedule="@hourly"
                    ;;
                *)
                    cron_schedule="@reboot"
                    ;;
            esac

            cron_command="${cron_schedule} ssh -N -R *:$local_port:localhost:$port_remote root@$ip_iran"
            (crontab -l ; echo "$cron_command") | crontab -

            echo ""
            echo -e "${GREEN}SSH tunnel set up and added to cron job @${time}.${NC}"
            echo ""
            echo -e "         ${NC}Now The SSH tunnel will be established on system startup as a system file${NC}"
            echo -e "\n                  ${RED}to move on press ENTER...${NC}"
            read

            echo "[Unit]
            Description=OPIran Reverse SSH Tunnel
            After=network.target

            [Service]
            ExecStart=ssh -N -R *:$local_port:localhost:$port_remote root@$ip_iran
            Restart=on-failure
            RestartSec=10

            [Install]
            WantedBy=multi-user.target" > /etc/systemd/system/reverse-tunnel-$local_port.service

            systemctl daemon-reload
            systemctl start reverse-tunnel-$local_port
            systemctl enable reverse-tunnel-$local_port
            sleep 3
            systemctl restart reverse-tunnel-$local_port
            echo ""
            echo ""
            echo -e "${GREEN}ALL TASK WERE SUCCESFULLY DONE, SO KEEP ENJOYING THE TUNNEL${NC}"
            echo ""
            echo -e "         ${YELLOW}THANKS TO CHOOSING ME, OPIRAN :D ${NC}"
    }

delete_tunnel() {
    clear
echo ""
printf "+---------------------------------------------+\n"
printf "\e[93m|          Deleting Tunnels                   |\e[0m\n"
printf "+---------------------------------------------+\n"     
echo ""
printf "${CYAN}  1${NC}) ${YELLOW} Direct SSH Tunnels \e[0m\n"
printf "${CYAN}  2${NC}) ${YELLOW} Reverse SSH Tunnels \e[0m\n"
echo
printf "${CYAN}  0${NC}) ${YELLOW} Exit \e[0m\n"
echo ""
echo -e "${GREEN}Select an option ${RED}[1-2]: ${NC}   "
read option

case $option in
    1)
        echo ""
        echo -e "${MAGENTA}Execute this in (IRAN) Server ${NC}"
        echo
        echo -ne "${YELLOW}Enter the Tunnel port of Iran: ${NC}"
        read local_port

        if crontab -l | grep -q "ssh.*$local_port.*root*"; then
            crontab -l | grep -v "ssh.*$local_port.*root*" | crontab -
            echo -e "${GREEN}Crontab entry for the tunnel deleted.${NC}"
        else
            echo -e "${YELLOW}No crontab entry found for the specified tunnel.${NC}"
        fi

        systemctl disable ssh-tunnel-$local_port
        systemctl stop ssh-tunnel-$local_port
        echo -e "${GREEN}Tunnels deleted successfully, please ${MAGENTA}reboot servers.${NC}"
        press_enter
        break
        ;;
    2)
        echo ""
        echo -e "${MAGENTA}Execute this in (kharej) Server ${NC}"
        echo
        echo -ne "${YELLOW}Enter the Tunnel port of KHAREJ: ${NC}"
        read local_port

        if crontab -l | grep -q "ssh.*$local_port.*root*"; then
            crontab -l | grep -v "ssh.*$local_port.*root*" | crontab -
            echo -e "${GREEN}Crontab entry for the tunnel deleted.${NC}"
        else
            echo -e "${YELLOW}No crontab entry found for the specified tunnel.${NC}"
        fi

        systemctl disable reverse-tunnel-$local_port
        systemctl stop reverse-tunnel-$local_port
        echo -e "${GREEN}Tunnels deleted successfully, please ${MAGENTA}reboot servers.${NC}"
        press_enter
        break
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
}

restart_tunnel() {
echo -e "${GREEN}To restart ssh-tunnel simply type ${MAGENTA}reboot ${GREEN}in both servers. :) ${NC}"
}

while true; do
clear
printf "+---------------------------------------------+\n"
printf "\e[93m|               SSH TUNNELS                   |\e[0m\n"
printf "+---------------------------------------------+\n"
echo ""
printf "${CYAN}  1${NC}) ${YELLOW} SSH Tunnels \e[0m\n"
printf "${CYAN}  2${NC}) ${YELLOW} Reverse SSH Tunnels \e[0m\n"
printf "${CYAN}  3${NC}) ${YELLOW} Delete Tunnels \e[0m\n"
printf "${CYAN}  42${NC}) ${YELLOW} Restart Tunnels \e[0m\n"
echo
printf "${CYAN}  0${NC}) ${YELLOW} Main Menu \e[0m\n"
echo ""
echo -e "${GREEN}Select an option ${RED}[1-2]: ${NC}   "
read option

case $option in
    1)
        ssh_tunnel
        ;;
    2)
        Reverse_ssh
        ;;
    3)
        delete_tunnel
        ;;
    4)
        restart_tunnel
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

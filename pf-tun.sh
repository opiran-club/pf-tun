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

prepration() {
    root
    clear
    apt-get update
    apt-get -y install iptables socat curl jq openssl wget ca-certificates unzip
}

ssh() {
    clear
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
            echo -e "${GREEN}copy and paste below command in your local (IRAN) terminal${NC}"
            echo -e "${MAGENTA}sed -i '/^#AllowTcpForwarding/c\AllowTcpForwarding yes' "/etc/ssh/sshd_config" && sed -i '/^#GatewayPorts/c\GatewayPorts yes' "/etc/ssh/sshd_config" && service ssh restart ${NC}"
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

            echo ""
            ssh-copy-id -i ~/.ssh/id_rsa.pub -p $ssh_port root@$ip_iran
            echo -e "${GREEN}SSH public key saved to Iran successfully${NC}"

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

while true; do
clear
printf "+---------------------------------------------+\n"
printf "\e[93m|               SSH TUNNELS                   |\e[0m\n"
printf "+---------------------------------------------+\n"
echo ""
printf "${CYAN}  1${NC}) ${YELLOW} SSH Tunnels \e[0m\n"
printf "${CYAN}  2${NC}) ${YELLOW} Reverse SSH Tunnels \e[0m\n"
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

}
iptables() {
    clear
        iptables_setup() {
            prepration
            if ! command -v iptables &> /dev/null; then
                echo -e "\e[91mError: iptables not installed. Installing...\e[0m"
                if [[ "${release}" == "centos" ]]; then
                    yum update
                    yum install -y iptables
                else
                    apt-get update
                    apt-get install -y iptables
                fi

                if ! command -v iptables &> /dev/null; then
                    echo -e "\e[91mError: Failed to install iptables. Exiting.\e[0m"
                    exit 1
                else
                    echo -e "\e[92miptables installation complete!\e[0m"
                fi
            else
                echo -e "\e[92miptables has been installed, continuing...\e[0m"
            fi

            echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
            echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
            sysctl --system

            if [[ "${release}" == "centos" ]]; then
                service iptables save
                chkconfig --level 2345 iptables on
                service ip6tables save
                chkconfig --level 2345 ip6tables on
            else
                iptables-save > /etc/iptables.up.rules
                echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
                chmod +x /etc/network/if-pre-up.d/iptables
                ip6tables-save > /etc/ip6tables.up.rules
                echo -e '#!/bin/bash\n/sbin/ip6tables-restore < /etc/ip6tables.up.rules' > /etc/network/if-pre-up.d/ip6tables
                chmod +x /etc/network/if-pre-up.d/ip6tables
            fi
        }

        iptables_forwarding() {
            iptables_setup
            clear
            echo ""
            echo -ne "${YELLOW}Enter the remote port [1-65535] (Kharej) ${GREEN}[support port range e.g. 2333-2355]: ${NC}   "
            read forwarding_port
            [[ -z "${forwarding_port}" ]] && echo "Cancel..." && exit 1

            echo ""
            echo -ne "${YELLOW}Enter the remote IP (Kharej) : ${NC}  "
            read forwarding_ip
            [[ -z "${forwarding_ip}" ]] && echo "Cancel..." && exit 1

            echo ""
            echo -ne "${YELLOW}Enter the local (Iran) port [support port range e.g. 2333-2355] ${GREEN}[Default: ${forwarding_port}] : ${NC}  "
            read local_port
            [[ -z "${local_port}" ]] && local_port="${forwarding_port}"

            echo ""
            echo -ne "${YELLOW}Enter local IP of this server ${GREEN}[press Enter to use the public IP] : ${NC}  "
            read local_ip
            [[ -z "${local_ip}" ]] && local_ip=$(ip -4 addr show | grep "scope global" | awk '{print $2}' | cut -d'/' -f1)
            [[ -z "${local_ip}" ]] && read -e -p "Cant find it, please enter local IP of this server: " local_ip
            [[ -z "${local_ip}" ]] && echo "Cancel..." && exit 1

             echo ""
            echo -ne "${YELLOW}Select iptables forwarding type (1-TCP, 2-UDP, 3-TCP+UDP) [Default: 3]: ${GREEN}[1-TCP, 2-UDP, 3-TCP+UDP] : ${NC}  "
            read forwarding_type_num
            [[ -z "${forwarding_type_num}" ]] && forwarding_type_num="3"
            case "${forwarding_type_num}" in
                1) forwarding_type="TCP";;
                2) forwarding_type="UDP";;
                3) forwarding_type="TCP+UDP";;
                *) forwarding_type="TCP+UDP";;
            esac

            echo -e "\n\e[92mConfiguration Summary:\e[0m"
            echo -e "  Forwarding Ports: \e[91m${forwarding_port}\e[0m"
            echo -e "  Forwarded IP: \e[91m${forwarding_ip}\e[0m"
            echo -e "  Local Listening Port: \e[91m${local_port}\e[0m"
            echo -e "  Local Server IP: \e[91m${local_ip}\e[0m"
            echo -e "  Forwarding Type: \e[91m${forwarding_type}\e[0m\n"

            read -e -p "Press any key to continue, or use Ctrl+C to exit if there is a configuration error."

            if [[ ${forwarding_type} == "TCP" ]]; then
                iptables -t nat -A PREROUTING -p tcp --dport "${local_port}" -j DNAT --to-destination "${forwarding_ip}:${forwarding_port}"
                iptables -t nat -A POSTROUTING -p tcp -d "${forwarding_ip}" --dport "${forwarding_port}" -j SNAT --to-source "${local_ip}"
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport "${local_port}" -j ACCEPT
            elif [[ ${forwarding_type} == "UDP" ]]; then
                iptables -t nat -A PREROUTING -p udp --dport "${local_port}" -j DNAT --to-destination "${forwarding_ip}:${forwarding_port}"
                iptables -t nat -A POSTROUTING -p udp -d "${forwarding_ip}" --dport "${forwarding_port}" -j SNAT --to-source "${local_ip}"
                iptables -I INPUT -m state --state NEW -m udp -p udp --dport "${local_port}" -j ACCEPT
            elif [[ ${forwarding_type} == "TCP+UDP" ]]; then
                iptables -t nat -A PREROUTING -p tcp --dport "${local_port}" -j DNAT --to-destination "${forwarding_ip}:${forwarding_port}"
                iptables -t nat -A POSTROUTING -p tcp -d "${forwarding_ip}" --dport "${forwarding_port}" -j SNAT --to-source "${local_ip}"
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport "${local_port}" -j ACCEPT

                iptables -t nat -A PREROUTING -p udp --dport "${local_port}" -j DNAT --to-destination "${forwarding_ip}:${forwarding_port}"
                iptables -t nat -A POSTROUTING -p udp -d "${forwarding_ip}" --dport "${forwarding_port}" -j SNAT --to-source "${local_ip}"
                iptables -I INPUT -m state --state NEW -m udp -p udp --dport "${local_port}" -j ACCEPT
            else
                echo -e "\e[91mInvalid forwarding type selected. Exiting...\e[0m"
                exit 1
            fi
            if [[ "${release}" == "centos" ]]; then
                service iptables save
            else
                iptables-save > /etc/iptables.up.rules
            fi

            echo -e "\e[92mIptables forwarding rules configured successfully!\e[0m"
        }

        ip6tables_forwarding() {
            iptables_setup
            clear
            echo ""
            echo -ne "${YELLOW}Enter the remote port [1-65535] (Kharej) ${GREEN}[support port range e.g. 2333-2355]: ${NC}   "
            read forwarding_port_ipv6
            [[ -z "${forwarding_port_ipv6}" ]] && echo "Cancel..." && exit 1

            echo ""
            echo -ne "${YELLOW}Enter the remote (Kharej) IPV6: ${NC}   "
            read forwarding_ip_ipv6
            [[ -z "${forwarding_ip_ipv6}" ]] && echo "Cancel..." && exit 1

            echo ""
            echo -ne "${YELLOW}Enter the local (Iran) port [support port range e.g. 2333-2355] ${GREEN}[Default: ${forwarding_port}] : ${NC}  "
            read local_port_ipv6
            [[ -z "${local_port_ipv6}" ]] && local_port_ipv6="${forwarding_port_ipv6}"

            echo ""
            echo -ne "${YELLOW}Enter the local (Iran) IPV6 ${GREEN}[press Enter to use the public IPv6] : ${NC}  "
            read local_ip_ipv6
            [[ -z "${local_ip_ipv6}" ]] && local_ip_ipv6=$(ip -6 addr show | grep "scope global" | awk '{print $2}' | cut -d'/' -f1)
            [[ -z "${local_ip_ipv6}" ]] && read -e -p "Cant find it, please enter local IPv6 of this server: " local_ip_ipv6
            [[ -z "${local_ip_ipv6}" ]] && echo "Cancel..." && exit 1

            echo ""
            echo -ne "${YELLOW}Select iptables forwarding type (1-TCP, 2-UDP, 3-TCP+UDP) [Default: 3]: ${GREEN}[1-TCP, 2-UDP, 3-TCP+UDP] : ${NC}  "
            read forwarding_type_ipv6_num
            [[ -z "${forwarding_type_ipv6_num}" ]] && forwarding_type_ipv6_num="3"
            case "${forwarding_type_ipv6_num}" in
                1) forwarding_type_ipv6="TCP";;
                2) forwarding_type_ipv6="UDP";;
                3) forwarding_type_ipv6="TCP+UDP";;
                *) forwarding_type_ipv6="TCP+UDP";;
            esac

            echo -e "\n\e[92mIPv6 Configuration Summary:\e[0m"
            echo -e "  Forwarding Ports: \e[91m${forwarding_port_ipv6}\e[0m"
            echo -e "  Forwarded IPv6: \e[91m${forwarding_ip_ipv6}\e[0m"
            echo -e "  Local Listening Port: \e[91m${local_port_ipv6}\e[0m"
            echo -e "  Local Server IPv6: \e[91m${local_ip_ipv6}\e[0m"
            echo -e "  Forwarding Type: \e[91m${forwarding_type_ipv6}\e[0m\n"

            read -e -p "Press any key to continue, or use Ctrl+C to exit if there is a configuration error."

            if [[ ${forwarding_type_ipv6} == "TCP" ]]; then
                sysctl -w net.ipv6.conf.all.forwarding=1
                ip6tables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
                ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport "${local_port_ipv6}" -j ACCEPT
                ip6tables -A FORWARD -p tcp --dport "${forwarding_port_ipv6}" -m state --state NEW -j ACCEPT
            elif [[ ${forwarding_type_ipv6} == "UDP" ]]; then
                sysctl -w net.ipv6.conf.all.forwarding=1
                ip6tables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
                ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport "${local_port_ipv6}" -j ACCEPT
                ip6tables -A FORWARD -p udp --dport "${forwarding_port_ipv6}" -m state --state NEW -j ACCEPT
            elif [[ ${forwarding_type_ipv6} == "TCP+UDP" ]]; then
                sysctl -w net.ipv6.conf.all.forwarding=1
                ip6tables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
                ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport "${local_port_ipv6}" -j ACCEPT
                ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport "${local_port_ipv6}" -j ACCEPT
                ip6tables -A FORWARD -p tcp --dport "${forwarding_port_ipv6}" -m state --state NEW -j ACCEPT
                ip6tables -A FORWARD -p udp --dport "${forwarding_port_ipv6}" -m state --state NEW -j ACCEPT
            else
                echo -e "\e[91mInvalid forwarding type selected. Exiting...\e[0m"
                exit 1
            fi

            if [[ "${release}" == "centos" ]]; then
                service ip6tables save
            else
                ip6tables-save > /etc/ip6tables.up.rules
            fi

            echo -e "\e[92mIPv6 forwarding rules configured successfully!\e[0m"
        }

while true; do
clear
printf "+---------------------------------------------+\n"
printf "\e[93m|                IP(4/6)tables                |\e[0m\n"
printf "+---------------------------------------------+\n"
echo ""
printf "${CYAN}  1${NC}) ${YELLOW} IPtables (IPV4) \e[0m\n"
printf "${CYAN}  2${NC}) ${YELLOW} IP6tables (IPV6) ${RED} (recommended)\e[0m\n"
printf "${CYAN}  0${NC}) ${YELLOW} Main Menu \e[0m\n"
echo ""
echo -e "${GREEN}Select an option ${RED}[1-2]: ${NC}   "
read option

case $option in
    1)
        iptables_forwarding
        ;;
    2)
        ip6tables_forwarding
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
}
socat() {
    clear
    Socat_install() {
        prepration
        if [[ "${release}" == "centos" ]]; then
                    yum update
                    yum install -y socat
                else
                    apt-get update
                    apt-get install -y socat
                fi

    }

    Socat_v4() {
        Socat_install
        clear
        echo ""
        echo -e "${GREEN}Starting Socat direct port forwarding over IPv4...${NC}"
        echo ""
        
        while true; do
            echo -ne "${YELLOW}Enter the local port to forward [1-65535]: ${NC}"
            read local_port
            if [[ $local_port =~ ^[0-9]+$ && $local_port -ge 1 && $local_port -le 65535 ]]; then
                break
            else
                echo -e "${RED}Invalid input. Please enter a valid port number.${NC}"
            fi
        done

        echo ""
        echo -ne "${YELLOW}Enter the destination IP address (Kharej): ${NC}"
        read destination_ip
        echo ""
        while true; do
            echo -ne "${YELLOW}Enter the destination port on Kharej (config port) [1-65535]: ${NC}"
            read destination_port
            if [[ $destination_port =~ ^[0-9]+$ && $destination_port -ge 1 && $destination_port -le 65535 ]]; then
                break
            else
                echo -e "${RED}Invalid input. Please enter a valid port number.${NC}"
            fi
        done

        socat_command="/usr/bin/socat TCP4-LISTEN:$local_port,fork,su=nobody TCP4:$destination_ip:$destination_port"

        echo ""
        echo -e "${YELLOW}Choose the cronjob schedule:${NC}"
        echo -e "  ${GREEN}1. Reboot${NC}"
        echo -e "  ${GREEN}2. Daily${NC}"
        echo -e "  ${GREEN}3. Weekly${NC}"
        echo -e "  ${GREEN}4. Hourly${NC}"
        echo -ne "${YELLOW}Your choice [1-4] (default: Reboot): ${NC}"
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

        cron_command="${cron_schedule} \"$socat_command\""
    (crontab -l || echo "") | grep -v "$socat_command" | (cat; echo "$cron_command") | crontab -

    echo "[Unit]
Description=socat $local_port

[Service]
ExecStart=/usr/bin/socat TCP4-LISTEN:$local_port,fork,su=nobody TCP4:$destination_ip:$destination_port
Restart=always

[Install]
WantedBy=multi-user.target
" > "/etc/systemd/system/socat-$local_port.service"

    systemctl daemon-reload
    systemctl start "socat-$local_port"
    systemctl enable "socat-$local_port"
    sleep 3
    systemctl restart "socat-$local_port"

    echo ""
    echo ""
    echo -e "${GREEN}ALL TASKS WERE SUCCESSFULLY DONE, SO KEEP ENJOYING THE TUNNEL${NC}"
    echo ""
    echo -e "         ${YELLOW}THANKS FOR CHOOSING ME, OPIRAN :D ${NC}"
}

    Socat_v6() {
        prepration
        Socat_install
    echo ""
    echo -e "${GREEN}Starting Socat direct port forwarding over IPv6...${NC}"
    echo ""

    while true; do
        echo -ne "${YELLOW}Enter the local port to forward [1-65535]: ${NC}"
        read local_port_ipv6
        if [[ $local_port_ipv6 =~ ^[0-9]+$ && $local_port_ipv6 -ge 1 && $local_port_ipv6 -le 65535 ]]; then
            break
        else
            echo -e "${RED}Invalid input. Please enter a valid port number.${NC}"
        fi
    done

    echo ""
    echo -ne "${YELLOW}Enter the destination IPv6 address (Kharej): ${NC}"
    read destination_ip_ipv6

    while true; do
        echo -ne "${YELLOW}Enter the destination port on Kharej (config port) [1-65535]: ${NC}"
        read destination_port_ipv6
        if [[ $destination_port_ipv6 =~ ^[0-9]+$ && $destination_port_ipv6 -ge 1 && $destination_port_ipv6 -le 65535 ]]; then
            break
        else
            echo -e "${RED}Invalid input. Please enter a valid port number.${NC}"
        fi
    done

    socat_command_ipv6="/usr/bin/socat TCP6-LISTEN:$local_port_ipv6,fork,su=nobody TCP6:[$destination_ip_ipv6]:$destination_port_ipv6"

    echo ""
    echo -e "${YELLOW}Choose the cronjob schedule:${NC}"
    echo -e "  ${GREEN}1. Reboot${NC}"
    echo -e "  ${GREEN}2. Daily${NC}"
    echo -e "  ${GREEN}3. Weekly${NC}"
    echo -e "  ${GREEN}4. Hourly${NC}"
    echo -ne "${YELLOW}Your choice [1-4] (default: Reboot): ${NC}"
    read choice_ipv6
    choice_ipv6=${choice_ipv6:-1}

    case "$choice_ipv6" in
        1)
            cron_schedule_ipv6="@reboot"
            ;;
        2)
            cron_schedule_ipv6="@daily"
            ;;
        3)
            cron_schedule_ipv6="@weekly"
            ;;
        4)
            cron_schedule_ipv6="@hourly"
            ;;
        *)
            cron_schedule_ipv6="@reboot"
            ;;
    esac

    cron_command_ipv6="${cron_schedule_ipv6} \"$socat_command_ipv6\""
    (crontab -l || echo "") | grep -v "$socat_command_ipv6" | (cat; echo "$cron_command_ipv6") | crontab -

    echo "[Unit]
Description=socat $local_port_ipv6 (IPv6)

[Service]
ExecStart=/usr/bin/socat TCP6-LISTEN:$local_port_ipv6,fork,su=nobody TCP6:[$destination_ip_ipv6]:$destination_port_ipv6
Restart=always

[Install]
WantedBy=multi-user.target
" > "/etc/systemd/system/socat-$local_port_ipv6.service"

    systemctl daemon-reload
    systemctl start "socat-$local_port_ipv6"
    systemctl enable "socat-$local_port_ipv6"
    sleep 3
    systemctl restart "socat-$local_port_ipv6"

    echo ""
    echo ""
    echo -e "${GREEN}ALL TASKS WERE SUCCESSFULLY DONE, SO KEEP ENJOYING THE IPv6 TUNNEL${NC}"
    echo ""
    echo -e "         ${YELLOW}THANKS FOR CHOOSING ME, OPIRAN :D ${NC}"
}

re_socat_v4() {
    Socat_install
    echo ""
    echo -e "${GREEN}Starting Socat reverse port forwarding over IPv4...${NC}"
    echo ""

    while true; do
        echo -ne "${YELLOW}Enter the local IP address (Iran): ${NC}"
        read local_ip

        if [[ $local_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        else
            echo -e "${RED}Invalid input. Please enter a valid IPv4 address.${NC}"
        fi
    done

    while true; do
        echo -ne "${YELLOW}Enter the destination port on Kharej (config port) [1-65535]: ${NC}"
        read destination_port

        if [[ $destination_port =~ ^[0-9]+$ && $destination_port -ge 1 && $destination_port -le 65535 ]]; then
            break
        else
            echo -e "${RED}Invalid input. Please enter a valid port number.${NC}"
        fi
    done

    socat_command="/usr/bin/socat TCP4-LISTEN:$destination_port,fork,reuseaddr TCP4:$local_ip:22"

    echo ""
    echo -e "${YELLOW}Choose the cronjob schedule:${NC}"
    echo -e "  ${GREEN}1. Reboot${NC}"
    echo -e "  ${GREEN}2. Daily${NC}"
    echo -e "  ${GREEN}3. Weekly${NC}"
    echo -e "  ${GREEN}4. Hourly${NC}"
    echo -ne "${YELLOW}Your choice [1-4] (default: Reboot): ${NC}"
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

    cron_command="${cron_schedule} \"$socat_command\""
    (crontab -l || echo "") | grep -v "$socat_command" | (cat; echo "$cron_command") | crontab -

    echo "[Unit]
Description=socat $destination_port

[Service]
ExecStart=/usr/bin/socat TCP4-LISTEN:$destination_port,fork,reuseaddr TCP4:$local_ip:22
Restart=always

[Install]
WantedBy=multi-user.target
" > "/etc/systemd/system/socat-$destination_port.service"

    systemctl daemon-reload
    systemctl start "socat-$destination_port"
    systemctl enable "socat-$destination_port"
    sleep 3
    systemctl restart "socat-$destination_port"


    echo ""
    echo ""
    echo -e "${GREEN}ALL TASKS WERE SUCCESSFULLY DONE, SO KEEP ENJOYING THE TUNNEL${NC}"
    echo ""
    echo -e "         ${YELLOW}THANKS FOR CHOOSING ME, OPIRAN :D ${NC}"
}

    re_socat_v6() {
        Socat_install
        clear
        echo ""
        echo -e "${GREEN}Starting Socat reverse port forwarding over IPv6...${NC}"
        echo ""
        echo ""
        echo -ne "${YELLOW}Enter the local IPv6 address (Iran): ${NC}"
        read local_ip_ipv6

        while true; do
            echo -ne "${YELLOW}Enter the port on Kharej (config port) [1-65535]: ${NC}"
            read destination_port_ipv6
            if [[ $destination_port_ipv6 =~ ^[0-9]+$ && $destination_port_ipv6 -ge 1 && $destination_port_ipv6 -le 65535 ]]; then
                break
            else
                echo -e "${RED}Invalid input. Please enter a valid port number.${NC}"
            fi
        done

        socat_command_ipv6="/usr/bin/socat TCP6-LISTEN:$destination_port_ipv6,fork,reuseaddr TCP6:[$local_ip_ipv6]:22"

        echo ""
        echo -e "${YELLOW}Choose the cronjob schedule:${NC}"
        echo -e "  ${GREEN}1. Reboot${NC}"
        echo -e "  ${GREEN}2. Daily${NC}"
        echo -e "  ${GREEN}3. Weekly${NC}"
        echo -e "  ${GREEN}4. Hourly${NC}"
        echo -ne "${YELLOW}Your choice [1-4] (default: Reboot): ${NC}"
        read choice_ipv6
        choice_ipv6=${choice_ipv6:-1}

        case "$choice_ipv6" in
            1)
                cron_schedule_ipv6="@reboot"
                ;;
            2)
                cron_schedule_ipv6="@daily"
                ;;
            3)
                cron_schedule_ipv6="@weekly"
                ;;
            4)
                cron_schedule_ipv6="@hourly"
                ;;
            *)
                cron_schedule_ipv6="@reboot"
                ;;
        esac

        cron_command_ipv6="${cron_schedule_ipv6} \"$socat_command_ipv6\""
        (crontab -l || echo "") | grep -v "$socat_command_ipv6" | (cat; echo "$cron_command_ipv6") | crontab -

    echo "[Unit]
Description=socat $destination_port_ipv6 (IPv6)

[Service]
ExecStart=/usr/bin/socat TCP6-LISTEN:$destination_port_ipv6,fork,reuseaddr TCP6:[$local_ip_ipv6]:22
Restart=always

[Install]
WantedBy=multi-user.target
" > "/etc/systemd/system/socat-$destination_port_ipv6.service"

    systemctl daemon-reload
    systemctl start "socat-$destination_port_ipv6"
    systemctl enable "socat-$destination_port_ipv6"
    sleep 3
    systemctl restart "socat-$destination_port_ipv6"

    echo ""
    echo ""
    echo -e "${GREEN}ALL TASKS WERE SUCCESSFULLY DONE, SO KEEP ENJOYING THE IPv6 TUNNEL${NC}"
    echo ""
    echo -e "         ${YELLOW}THANKS FOR CHOOSING ME, OPIRAN :D ${NC}"
}

while true; do
clear
printf "+---------------------------------------------+\n"
printf "\e[93m|                 Socat Menu                  |\e[0m\n"
printf "+---------------------------------------------+\n"
echo ""
printf "${CYAN}  1${NC}) ${YELLOW} Direct Socat ${RED}(recomended) \e[0m\n"
printf "${CYAN}  2${NC}) ${YELLOW} Reverse Socat \e[0m\n"
printf "${CYAN}  0${NC}) ${YELLOW} Back \e[0m\n"
echo ""
echo -e "${GREEN}Select an option ${RED}[1-2]: ${NC}   "
read option

case $option in
    1)
            while true; do
            clear
            printf "+---------------------------------------------+\n"
            printf "\e[93m|              Direct Socat Menu              |\e[0m\n"
            printf "+---------------------------------------------+\n"
            echo ""
            printf "${CYAN}  1${NC}) ${YELLOW} Direct Socat (IPV4) \e[0m\n"
            printf "${CYAN}  2${NC}) ${YELLOW} Direct Socat (IPV6) \e[0m\n"
            printf "${CYAN}  0${NC}) ${YELLOW} Back \e[0m\n"
            echo ""
            echo -e "${GREEN}Select an option ${RED}[1-2]: ${NC}   "
            read option

            case $option in
                1)
                    Socat_v4
                    ;;
                2)
                    Socat_v6
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
                    ;;
    2)
            while true; do
            clear
            printf "+---------------------------------------------+\n"
            printf "\e[93m|              Reverse Socat Menu             |\e[0m\n"
            printf "+---------------------------------------------+\n"
            echo ""
            printf "${CYAN}  1${NC}) ${YELLOW} Reverse Socat (IPV4) \e[0m\n"
            printf "${CYAN}  2${NC}) ${YELLOW} Reverse Socat (IPV6) \e[0m\n"
            printf "${CYAN}  0${NC}) ${YELLOW} Back \e[0m\n"
            echo ""
            echo -e "${GREEN}Select an option ${RED}[1-2]: ${NC}   "
            read option

            case $option in
                1)
                    re_socat_v4
                    ;;
                2)
                    re_socat_v6
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
}

frp() {
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
}

ipv6() {
    prepration_ipv6() {
    clear
    echo -e "${YELLOW}Lets check the system before proceeding...${NC}"
    apt-get update > /dev/null 2>&1

    if ! dpkg -l | grep -q iproute2; then
        echo -e "${YELLOW}iproute2 is not installed. Installing it now...${NC}"
        apt-get update
        apt-get install iproute2 -y > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}iproute2 has been installed.${NC}"
        else
            echo -e "${RED}Failed to install iproute2. Please install it manually.${NC}"
            return
        fi
    fi
        modprobe ipv6 > /dev/null 2>&1
        echo 1 > /proc/sys/net/ipv4/ip_forward > /dev/null 2>&1
        echo 1 > /proc/sys/net/ipv6/conf/all/forwarding > /dev/null 2>&1

    if [[ $(cat /proc/sys/net/ipv4/ip_forward) -eq 0 ]]; then
        echo -e "${RED}IPv4 forwarding is not enabled. Attempting to enable it...${NC}"
        echo 1 > /proc/sys/net/ipv4/ip_forward
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}IPv4 forwarding has been enabled.${NC}"
        else
            echo -e "${RED}Failed to enable IPv4 forwarding. Please enable it manually before configuring 6to4, just type below command into your terminal${NC}"
            echo ""
            echo -e "${YELLOW}echo 1 > /proc/sys/net/ipv4/ip_forward${NC}"
            return
        fi
    fi

    if [[ $(cat /proc/sys/net/ipv6/conf/all/forwarding) -eq 0 ]]; then
        echo -e "${RED}IPv6 forwarding is not enabled. Attempting to enable it...${NC}"
        for interface in /proc/sys/net/ipv6/conf/*/forwarding; do
            echo 1 > "$interface"
        done
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}IPv6 forwarding has been enabled.${NC}"
        else
            echo -e "${RED}Failed to enable IPv6 forwarding. Please enable it manually before configuring 6to4.${NC}"
            return
        fi
    fi
}

6to4_ipv6() {
    clear
    prepration_ipv6
    echo ""
    echo -e "       ${MAGENTA}Setting up 6to4 IPv6 addresses...${NC}"

    echo -ne "${YELLOW}Enter the IPv4 address${NC}   "
    read ipv4
    ipv6_address=$(printf "2002:%02x%02x:%02x%02x::1" `echo $ipv4 | tr "." " "`)
    echo -e "${YELLOW}IPv6to4 Address: ${GREEN}$ipv6_address ${YELLOW}was created but not configured yet for routing.${NC}"
    echo ""
    press_enter
    systemctl restart networking
    systemctl restart systemd-networkd
    sleep 2
    modprobe sit
    ip tunnel add tun6to4 mode sit ttl 255 remote any local "$ipv4"
    ip -6 link set dev tun6to4 mtu 1280
    ip link set dev tun6to4 up
    ip -6 addr add "$ipv6_address/16" dev tun6to4
    ip -6 route add 2000::/3 via ::192.88.99.1 dev tun6to4 metric 1
    sleep 1
    echo -e "    ${GREEN} [$ipv6_address] was added and routed successfully, please${RED} reboot ${NC}"
    systemctl restart systemd-networkd
    systemctl restart networking

    opiran_6to4_dir="/root/opiran-6to4"
    opiran_6to4_script="$opiran_6to4_dir/6to4"

    if [ ! -d "$opiran_6to4_dir" ]; then
        mkdir "$opiran_6to4_dir"
    else
        rm -f "$opiran_6to4_script"
    fi

cat << EOF | tee -a "$opiran_6to4_script" > /dev/null
#!/bin/bash
systemctl restart systemd-networkd
systemctl restart networking
modprobe sit
ip tunnel add tun6to4 mode sit ttl 255 remote any local "$ipv4"
ip -6 link set dev tun6to4 mtu 1280
ip link set dev tun6to4 up
ip -6 addr add "$ipv6_address/16" dev tun6to4
ip -6 route add 2000::/3 via ::192.88.99.1 dev tun6to4 metric 1
EOF

    chmod +x "$opiran_6to4_script"

    (crontab -l || echo "") | grep -v "/root/opiran-6to4/6to4" | (cat; echo "@reboot /root/opiran-6to4/6to4") | crontab -

    echo ""
    echo -e "${GREEN} Everythings were successfully done.${NC}"
    echo ""
    echo -e "${YELLOW} Your 6to4 IP: ${GREEN} [$ipv6_address]${NC}"
    press_enter
}

uninstall_6to4_ipv6() {
    clear
    systemctl restart systemd-networkd
    sleep 1
    echo ""
    echo -e "     ${MAGENTA}List of 6to4 IPv6 addresses:${NC}"
    
    ipv6_list=$(ip -6 addr show dev tun6to4 | grep -oP "(?<=inet6 )[0-9a-f:]+")
    
    if [ -z "$ipv6_list" ]; then
        echo "No 6to4 IPv6 addresses found on the tun6to4 interface."
        return
    fi
    
    ipv6_array=($ipv6_list)
    
    for ((i = 0; i < ${#ipv6_array[@]}; i++)); do
        echo "[$i]: ${ipv6_array[$i]}"
    done
    
    echo ""
    echo -ne "Enter the number of the IPv6 address to uninstall: "
    read choice

    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a valid number."
        return
    fi
    
    if ((choice < 0 || choice >= ${#ipv6_array[@]})); then
        echo "Invalid number. Please enter a valid number within the range."
        return
    fi
    
    selected_ipv6="${ipv6_array[$choice]}"

    systemctl restart networking
    sleep 3
    /sbin/ip -6 addr del "$selected_ipv6" dev tun6to4
    echo ""
    echo -e " ${YELLOW}IPv6 address $selected_ipv6 has been deleted please${RED} reboot ${YELLOW}to take action."
}

list_6to4_ipv6() {
    clear
    systemctl restart networking
    sleep 1
    echo ""
    echo -e "     ${MAGENTA}List of 6to4 IPv6 addresses:${NC}"

    ipv6_list=$(ip -6 addr show dev tun6to4 | grep -oP "(?<=inet6 )[0-9a-f:]+")
    
    if [ -z "$ipv6_list" ]; then
        echo "No 6to4 IPv6 addresses found on the tun6to4 interface."
        return
    fi
    
    ipv6_array=($ipv6_list)
    
    for ((i = 0; i < ${#ipv6_array[@]}; i++)); do
        echo "[$i]: ${ipv6_array[$i]}"
    done
}

status_6to4_ipv6() {
    clear
    systemctl restart systemd-networkd
    systemctl restart networking
        echo -e "${MAGENTA}List of 6to4 IPv6 addresses:${NC}"
    
    ipv6_list=$(ip -6 addr show dev tun6to4 | grep -oP "(?<=inet6 )[0-9a-f:]+")
    
    if [ -z "$ipv6_list" ]; then
        echo "No 6to4 IPv6 addresses found on the tun6to4 interface."
        return
    fi
    
    ipv6_array=($ipv6_list)
    
    for ipv6_address in "${ipv6_array[@]}"; do
        if ping6 -c 1 "$ipv6_address" &> /dev/null; then
            echo -e "${GREEN}Live${NC}: $ipv6_address"
        else
            echo -e "${RED}Dead${NC}: $ipv6_address"
        fi
    done

    color yellow "crtl+c to back the menu"
}

add_extra_ipv6() {
    clear
    systemctl restart systemd-networkd
    systemctl restart networking
    prepration_ipv6
    main_interface=$(ip route | awk '/default/ {print $5}')
ipv6_subnets=($(ip -6 addr show dev "$main_interface" | awk '/inet6/ {print $2}' | grep -oP '[0-9a-fA-F:]+/64' | grep -v "^fe80"))
    
    if [ ${#ipv6_subnets[@]} -eq 0 ]; then
        echo -e "${RED}No IPv6 subnets found on the $main_interface.${NC}"
        return
    fi
    echo ""
    echo -e "        ${MAGENTA}List of all available IPv6 subnets on $main_interface:${NC}"

    for ((i=0; i<${#ipv6_subnets[@]}; i++)); do
        echo ""
        echo -e "${CYAN}$((i+1))${NC}) ${ipv6_subnets[i]}"
    done
    echo ""
    echo -ne "${YELLOW}Choose the subnet to create IPv6 addresses from: ${NC}"
    read selection

    if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
        echo ""
        echo -e "${RED}Invalid selection. Exiting.${NC}"
        return
    fi

if ((selection >= 1 && selection <= ${#ipv6_subnets[@]})); then
    local selected_subnet="${ipv6_subnets[selection-1]}"
    ipv6_address="${selected_subnet%/*}"

        last_ipv6=$(ip -6 addr show dev "$main_interface" | grep "$ipv6_prefix" | awk -F'/' '{print $1}' | tail -n 1)
        last_number=${last_ipv6##*::}

        echo ""
        echo ""
        echo -ne "${YELLOW}Enter the quantity of IPv6 addresses to create: ${NC}"
        read quantity

        if [[ ! "$quantity" =~ ^[0-9]+$ ]]; then
            echo ""
            echo -e "${RED}Invalid quantity. Exiting.${NC}"
            return
        fi

        max_quantity=10

        if ((quantity > max_quantity)); then
            echo ""
            echo "${RED}Quantity exceeds the maximum limit of $max_quantity. Exiting.${NC}"
            return
        fi
        
        systemctl restart systemd-networkd
        systemctl restart networking

    opiran_n6_dir="/root/opiran-n6"
    opiran_n6_script="$opiran_n6_dir/add_extra_ipv6"
    ipv6_file="/root/opiran-n6/ipv6-list.txt"

    if [ ! -d "$opiran_n6_dir" ]; then
        mkdir "$opiran_n6_dir"
    else
        rm -f "$opiran_n6_script"
    fi
        
        ipv6_file="/root/opiran-n6/ipv6-list.txt"
        > "$ipv6_file"

        for ((i=last_number+1; i<=last_number+quantity; i++)); do
            local ipv6_address="$ipv6_address::$i/64"
            echo "$ipv6_address" >> "$ipv6_file"
            if ip -6 addr add "$ipv6_address" dev "$main_interface"; then
                echo ""
                echo -e "${NC}IPv6 Address ${GREEN}$i${NC}: ${GREEN}$ipv6_address${NC} Interface (dev): ${GREEN}$main_interface${NC}"
            else
                echo ""
                echo -e "${RED}Error creating IPv6 address: $ipv6_address${NC}"
            fi
        done
ip -6 addr add 2a0e:0:1:3015::210/128 dev ens3

cat << EOF | tee -a "$opiran_n6_script" > /dev/null
#!/bin/bash
systemctl restart systemd-networkd
systemctl restart networking
main_interface=$(ip route | awk '/default/ {print $5}')
while IFS= read -r ipv6_address; do
    ip -6 addr add "$ipv6_address" dev "$main_interface"
done < "$ipv6_file"
EOF

    chmod +x "$opiran_n6_script"

    (crontab -l || echo "") | grep -v "$opiran_n6_script" | { cat; echo "@reboot $opiran_n6_script"; } | crontab -

        echo ""
        echo ""
        echo -e "IPv6 Addresses $((last_number+1))-$((last_number+quantity)) have been created successfully."
        echo -e "The IPv6 addresses will be applied on startup."
    else
        echo -e "${RED}Invalid selection. No IPv6 addresses created.${NC}"
    fi

    echo ""
    echo -e "${GREEN}IPv6 extra has been added successfully.${NC}"
    echo -e "${GREEN}To run the service, Please reboot VPS to take action.${NC}"
}


delete_extra_ipv6() {
    clear
    systemctl restart systemd-networkd
    systemctl restart networking
    main_interface=$(ip route | awk '/default/ {print $5}')
    ipv6_file="/root/opiran-n6/ipv6-list.txt"

    if [ ! -f "$ipv6_file" ]; then
        echo -e "${RED}IPv6 file not found. No IPv6 addresses to delete.${NC}"
        return
    fi

    local ipv6_addresses=($(cat "$ipv6_file"))

    if [ ${#ipv6_addresses[@]} -eq 0 ]; then
        echo -e "${RED}No IPv6 addresses found in the file.${NC}"
        return
    fi

    echo -e "${MAGENTA}List of IPv6 addresses:${NC}"

    for ((i=0; i<${#ipv6_addresses[@]}; i++)); do
        echo -e "${CYAN}$((i+1))${NC}) ${ipv6_addresses[i]}"
    done

    echo -ne "${YELLOW}Enter the number to delete: ${NC}"
    read selection

    if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
        echo ""
        echo -e "${RED}Invalid selection. Exiting.${NC}"
        return
    fi

    if ((selection >= 1 && selection <= ${#ipv6_addresses[@]})); then
        local ipv6_address="${ipv6_addresses[selection-1]}"
        if ip -6 addr del "$ipv6_address" dev "$main_interface"; then
            sleep 1
            echo -e "${NC}Deleted IPv6 address: ${GREEN}$ipv6_address${RED}"
            sed -i "${selection}d" "$ipv6_file"
        else
            echo -e "${RED}Error deleting IPv6 address: $ipv6_address${NC}"
        fi
    else
        echo -e "${RED}Invalid selection. No IPv6 address deleted.${NC}"
    fi
}

list_extra_ipv6() {
    clear
    ipv6_file="/root/opiran-n6/ipv6-list.txt"

    if [ ! -f "$ipv6_file" ]; then
        echo -e "${RED}IPv6 file not found. No IPv6 addresses to list.${NC}"
        return
    fi

    local ipv6_addresses=($(cat "$ipv6_file"))

    if [ ${#ipv6_addresses[@]} -eq 0 ]; then
        echo -e "${RED}No IPv6 addresses found in the file.${NC}"
        return
    fi

    echo -e "${MAGENTA}List of all IPv6 addresses:${NC}"

    for ((i=0; i<${#ipv6_addresses[@]}; i++)); do
        echo -e "${CYAN}$((i+1))${NC}) ${ipv6_addresses[i]}"
    done
}

status_extra_ipv6() {
    clear
    ipv6_file="/root/opiran-n6/ipv6-list.txt"

    if [ ! -f "$ipv6_file" ]; then
        echo -e "${RED}IPv6 file not found. No IPv6 addresses to check.${NC}"
        return
    fi

    local ipv6_addresses=($(cat "$ipv6_file"))

    if [ ${#ipv6_addresses[@]} -eq 0 ]; then
        echo -e "${RED}No IPv6 addresses found in the file.${NC}"
        return
    fi

    for ipv6_address in "${ipv6_addresses[@]}"; do
        if ping6 -c 1 "$ipv6_address" &> /dev/null; then
            echo -e "${GREEN}Live${NC}: $ipv6_address"
        else
            echo -e "${RED}Dead${NC}: $ipv6_address"
        fi
    done
}

del_private() {
    del_v4() {
    clear
    color green "Deleting Private IPv4 Configuration"
    echo ""

    main_interface=$(ip route | awk '/default/ {print $5}')
    config="/root/private_ipv4"

    if [ ! -f "$config" ]; then
        color red "Private IP configuration file not found. Exiting..."
        exit 1
    fi

    private_interfaces=$(grep -Eo '^[[:space:]]+[a-zA-Z0-9_-]+:' "$config" | sed 's/:$//')

    if [ -z "$private_interfaces" ]; then
        color red "No private interfaces found in the configuration file."
        exit 1
    fi

    echo -e "${YELLOW}List of Private Interfaces:${NC}"
    echo "$private_interfaces" | nl -w2 -s') '

    echo ""
    echo -ne "${YELLOW}Enter the number of the private interface to delete: ${NC}"
    read selected_number

    selected_interface=$(echo "$private_interfaces" | sed -n "${selected_number}p")

    if [ -n "$selected_interface" ]; then
        sed -i "/$selected_interface:/,/addresses:/d" "$config"
        route del -net $privateipv4 netmask 255.255.255.0 dev $selected_interface

        color green "Private IP configuration for $selected_interface has been deleted successfully."
    else
        color red "Invalid selection. Exiting..."
        exit 1
    fi

    press_enter
}

del_v6() {
    clear
    color green "Deleting Private IPv4 Configuration"
    echo ""

    main_interface=$(ip route | awk '/default/ {print $5}')
    config="/root/private_ipv6"

    if [ ! -f "$config" ]; then
        color red "Private IP configuration file not found. Exiting..."
        exit 1
    fi

    private_interfaces=$(grep -Eo '^[[:space:]]+[a-zA-Z0-9_-]+:' "$config" | sed 's/:$//')

    if [ -z "$private_interfaces" ]; then
        color red "No private interfaces found in the configuration file."
        exit 1
    fi

    echo -e "${YELLOW}List of Private Interfaces:${NC}"
    echo "$private_interfaces" | nl -w2 -s') '

    echo ""
    echo -ne "${YELLOW}Enter the number of the private interface to delete: ${NC}"
    read selected_number

    selected_interface=$(echo "$private_interfaces" | sed -n "${selected_number}p")

    if [ -n "$selected_interface" ]; then
        sed -i "/$selected_interface:/,/addresses:/d" "$config"
        
        ip -6 addr del $privateipv6 dev $selected_interface

        systemctl restart networking

        sleep 1

        color green "Private IP configuration for $selected_interface has been deleted successfully."
    else
        color red "Invalid selection. Exiting..."
        exit 1
    fi

    press_enter
}

while true; do
title_text="Private IPV4"
printf "+---------------------------------------------+\n" 
echo -e "$MAGENTA$BOLD             ${title_text} ${NC}"
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN}  1${NC}) ${YELLOW}Delete private IPV4${NC}"
echo -e "${CYAN}  2${NC}) ${YELLOW}Delete private IPV6${NC}"
echo ""
echo -e "${CYAN} 0${NC}) ${RED}Back${NC}"
echo ""
echo ""
echo -e "${GREEN}Select an option ${RED}[1-4]: ${NC}   "
read option

    case $option in
        1)
        del_v4
        ;;
        2)
        del_v6
        ;;
        0)
        color red "Exiting..."
        break
        ;;
        *)
        color red "Invalid option. Exiting..."
        press_enter
        ;;
    esac
done
}

find_next_private_interface_number() {
    main_interface=$(ip route | awk '/default/ {print $5}')
    local interface_number=0
    while ip link show | grep -q "${main_interface}:${interface_number}"; do
        ((interface_number++))
    done
    echo $interface_number
}

    ipv4() {
    clear
    color green "Creating Private IPV4 and Configuration"
    echo ""
title_text="Private IPV4"
while true; do
printf "+---------------------------------------------+\n" 
echo -e "$MAGENTA$BOLD             ${title_text} ${NC}"
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN}  1${NC}) ${YELLOW}range IP ${NC}[10.0.0.0 to 10.255.255.255] ${RED}(recommended)${NC}"
echo -e "${CYAN}  2${NC}) ${YELLOW}range IP ${NC}[172.16.0.0 to 172.31.255.255]${NC}"
echo -e "${CYAN}  3${NC}) ${YELLOW}range IP ${NC}[192.168.0.0 to 192.168.255.255]${NC}"
echo -e "${CYAN}  4${NC}) ${YELLOW}Enter custom private IPv4${NC}"
echo ""
echo -e "${CYAN} 0${NC}) ${RED}Back${NC}"
echo ""
echo ""
echo -e "${GREEN}Select an option ${RED}[1-4]: ${NC}   "
read option

    case $option in
        1)
        echo ""
        echo ""
        color magenta "!!!WARNING!!!"
        color red "if you want tunnel 2 server together with private ip"
        color red "they should NOT be same IP4 address"
        color red "for example 10.1.2.3 and for 2nd server 10.1.2.4 and for 3rd server 10.1.2.5, ...."
        color green " my suggestion is: 10.0.0.1"
        echo ""
        echo ""
        echo -ne "${YELLOW}Enter your desire private ipv4 address (ex. 10.0.0.1, 2, 3, ...): ${NC}"
        read privateipv4
        echo ""
        ;;
        2)
        echo ""
        echo ""
        color magenta "!!!WARNING!!!"
        color red "if you want tunnel 2 server together with private ip"
        color red "they should NOT be same IP4 address"
        color red "for example 172.17.18.19 and for 2nd server 172.17.18.20 and for 3rd server 172.17.18.21, ...."
        color green " my suggestion is: 172.16.0.1"
        echo ""
        echo ""
        echo -ne "${YELLOW}Enter your desire private ipv4 address (ex. 172.16.0.1, 2, 3, ...): ${NC}"
        read privateipv4
        echo ""
        ;;
        3)
        echo ""
        echo ""
        color magenta "!!!WARNING!!!"
        color red "if you want tunnel 2 server together with private ip"
        color red "they should NOT be same IP4 address"
        color red "for example 192.168.42.42 and for 2nd server 192.168.42.43 and for 3rd server 192.168.42.44, ...."
        color green " my suggestion is: 192.168.0.1"
        echo ""
        echo ""
        echo -ne "${YELLOW}Enter your desire private ipv4 address (ex. 192.168.0.1 , 2, 3, ...): ${NC}"
        read privateipv4
        echo ""
        ;;
        4)
        echo ""
        echo ""
        echo -ne "${YELLOW}Enter your desire private ipv4 address (ex. 192.168.0.1 , 2, 3, ...): ${NC}"
        read privateipv4
        echo ""
        ;;
        0)
        color red "Exiting..."
        exit 1
        ;;
        *)
        color red "Invalid option. Exiting..."
        press_enter
        ;;
    esac

main_interface=$(ip route | awk '/default/ {print $5}')
next_interface_number=$(find_next_private_interface_number)
private_interface="${main_interface}:${next_interface_number}"
startup_private_ipv4="/root/private_ipv4"

ifconfig $private_interface $privateipv4 netmask 255.255.255.0
route add -net $privateipv4 netmask 255.255.255.0 dev $private_interface

    cat << EOF | tee -a "$startup_private_ipv4" > /dev/null
#!/bin/bash
systemctl restart systemd-networkd
systemctl restart networking
#$privateipv4
#$private_interface
ifconfig $private_interface $privateipv4 netmask 255.255.255.0
route add -net $privateipv4 netmask 255.255.255.0 dev $private_interface
EOF

    chmod +x "$startup_private_ipv4"

    (crontab -l || echo "") | grep -v "$startup_private_ipv4" | { cat; echo "@reboot $startup_private_ipv4"; } | crontab -

    color green "Private IPv4 was added successfully, your private IP is: $privateipv4"
    press_enter
    done
    }
    
    ipv6() {
    clear
    color green "Creating Private IPV6 and Configuration"
    echo ""
title_text="Private IPV6"
while true; do
printf "+---------------------------------------------+\n" 
echo -e "$MAGENTA$BOLD             ${title_text} ${NC}"
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN}  1${NC}) ${YELLOW}fc00::/8 ${NC}(similar to 10.0.0.0/8) (recommended)${NC}"
echo -e "${CYAN}  2${NC}) ${YELLOW}fd00::/8 ${NC}(similar to 192.168.0.0/16)${NC}"
echo -e "${CYAN}  3${NC}) ${YELLOW}Enter custom IPv6 range${NC}"
echo ""
echo -e "${CYAN} 0${NC}) ${RED}Back${NC}"
echo ""
echo -e "${GREEN}Select an option ${RED}[1-4]: ${NC}   "
read option

case $option in
            1)
                echo ""
                echo ""
                color magenta "!!!WARNING!!!"
                color red "If you want tunnel 2 server together with private IPv6"
                color red "they should NOT be the same IPv6 address"
                color red "For example, fd1d:fc98:b73e:b481::1 and for the 2nd server fd1d:fc98:b73e:b481::2 and for the 3rd server fd1d:fc98:b73e:b481::3, ...."
                color green "My suggestion is: fd12:3456:789a:1"
                echo ""
                echo ""
                echo -ne "${YELLOW}Enter the last part of your desired private IPv6 address (e.g., 1, 2, 3, ...): ${NC}"
                read last_part_ipv6
                privateipv6="fd12:3456:789a:1::$last_part_ipv6"
                ;;
            2)
                echo ""
                echo ""
                color magenta "!!!WARNING!!!"
                color red "If you want tunnel 2 server together with private IPv6"
                color red "they should NOT be the same IPv6 address"
                color red "For example, fd55:9876:5432:1::1 and for the 2nd server fd55:9876:5432:1::2 and for the 3rd server fd55:9876:5432:1::3, ...."
                color green "My suggestion is: fd42:abcd:1234:[last_part_ipv6]"
                echo ""
                echo ""
                echo -ne "${YELLOW}Enter the last part of your desired private IPv6 address (e.g., 1, 2, 3, ...): ${NC}"
                read last_part_ipv6
                privateipv6="fd42:abcd:1234:1::$last_part_ipv6"
                ;;
            3)
                echo -ne "${YELLOW}Enter custom IPv6 address (e.g., fc12:3456:789a:1::1): ${NC}"
                read privateipv6
                ;;
            0)
                color red "Exiting..."
                break
                ;;
            *)
            color red "Invalid option. Exiting..."
            press_enter
                ;;
        esac

main_interface=$(ip route | awk '/default/ {print $5}')
next_interface_number=$(find_next_private_interface_number)
private_interface="${main_interface}:${next_interface_number}"
startup_private_ipv6="/root/private_ipv6"

ip -6 addr add $privateipv6/64 dev $private_interface
ip -6 route add $privateipv6/64 dev $private_interface

    cat << EOF | tee -a "$startup_private_ipv4" > /dev/null
#!/bin/bash
systemctl restart systemd-networkd
systemctl restart networking
#$privateipv6
#$private_interface
ip -6 addr add $privateipv6/64 dev $private_interface
ip -6 route add $privateipv6/64 dev $private_interface
EOF

    chmod +x "$startup_private_ipv6"

    (crontab -l || echo "") | grep -v "$startup_private_ipv6" | { cat; echo "@reboot $startup_private_ipv6"; } | crontab -

    color green "Private IPv6 was added successfully, your private IP is: $privateipv6"

    press_enter
    done
    }

while true; do
clear
title_text="Private / 6to4 / native IP(4/6)"
printf "+---------------------------------------------+\n" 
echo -e "$MAGENTA$BOLD          ${title_text}${NC}"
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN}  1${NC}) ${YELLOW}6to4 IPv6 ${NC}"
echo -e "${CYAN}  2${NC}) ${YELLOW}Add native IPV6 ${NC}"
echo -e "${CYAN}  3${NC}) ${YELLOW}Private IPV4 ${NC}"
echo -e "${CYAN}  4${NC}) ${YELLOW}Private IPV6 ${NC}"
echo ""
echo -e "${CYAN}  5${NC}) ${YELLOW}Delete private ipv4/6 ${NC}"
echo ""
echo -e "${CYAN} 0${NC}) ${RED}Back${NC}"
echo ""
echo ""
echo -e "${GREEN}Select an option ${RED}[1-4]: ${NC}   "
read option

    case $option in
        1)
        while true; do
            clear
            title_text="6to4 IPV6 Menu"
            clear
            echo ""
            printf "+---------------------------------------------+\n" 
            echo -e "              ${MAGENTA}${title_text}${NC}"
            printf "+---------------------------------------------+\n" 
            echo ""
            echo -e "${CYAN} 1.${NC}) ${YELLOW}Creating 6to4 IPV6${NC}"
            echo -e "${CYAN} 2.${NC}) ${YELLOW}Deleting 6to4 IPV6${NC}"
            echo -e "${CYAN} 3.${NC}) ${YELLOW}List of 6to4 IPV6${NC}"
            echo -e "${CYAN} 4.${NC}) ${YELLOW}Status of 6to4 IPV6${NC}"
            echo ""
            echo -e "${CYAN} 0.${NC}) ${RED}Back${NC}"
            echo ""
            echo -ne "${GREEN}Select an option ${RED}[1-4]: ${NC}"
            read choice

            case $choice in
                1)
                6to4_ipv6
                    ;;
                2)
                uninstall_6to4_ipv6
                    ;;
                3)
                list_6to4_ipv6
                    ;;
                4)
                status_6to4_ipv6
                    ;;
                0)
                color red "Exiting..."
                break
                    ;;
                *)
                color red "Invalid option. Exiting..."
                press_enter                   
            esac
        done
        ;;
        2)
        while true; do
            clear
            title_text="Extra IPV6 Menu"
            clear
            echo ""
            printf "+---------------------------------------------+\n" 
            echo -e "              ${MAGENTA}${title_text}${NC}"
            printf "+---------------------------------------------+\n" 
            echo ""
            echo -e "${CYAN} 1${NC}) ${YELLOW}Creating Extra IPV6${NC}"
            echo -e "${CYAN} 2${NC}) ${YELLOW}Deleting Extra IPV6${NC}"
            echo -e "${CYAN} 3${NC}) ${YELLOW}List of all IPV6${NC}"
            echo -e "${CYAN} 4${NC}) ${YELLOW}Status of all IPV6${NC}"
            echo ""
            echo -e "${CYAN} 0.${NC}) ${RED}Back${NC}"
            echo ""
            echo -ne "${GREEN}Select an option ${RED}[1-4]: ${NC}"
            read choice

            case $choice in
                1)
                add_extra_ipv6
                    ;;
                2)
                delete_extra_ipv6
                    ;;
                3)
                list_extra_ipv6
                    ;;
                4)
                status_extra_ipv6
                    ;;
                0)
                color red "Exiting..."
                break
                    ;;
                *)
                color red "Invalid option. Exiting..."
                press_enter
                    ;;                   
            esac
        done
        ;;
        3)
        ipv4
            ;;
        4)
        ipv6
            ;;
        5)
        del_private
            ;;
        0)
        color red "Exiting..."
        break
        ;;
        *)
        color red "Invalid option. Exiting..."
        exit 1
        ;;
    esac
done
}

tunnel_broker() {
    clear
    color green "Creating tunnelbroker IPV6"
    echo ""
    color yellow "at first visit tunnelbroker.ch and create your tunnel then comeback here"
    echo ""
    echo -ne "${YELLOW}Enter tunnel name (tunnel-id) for tunnelbroker: ${NC}"
    read tunnelname
    echo ""
    echo -ne "${YELLOW}Enter Server (website) IPV4 address: ${NC}"
    read serveripv4addr
    echo ""
    echo -ne "${YELLOW}Enter your IPV4 address: ${NC}"
    read clientipv4addr
    echo ""
    echo -ne "${YELLOW}Enter server (website) IPV6 address (without ::/64): ${NC}"
    read routed64
    echo ""
    echo -ne "${YELLOW}Enter Client (Routed) IPV6 address (without ::/64): ${NC}"
    read clientipv6addr

sudo ip tunnel add $tunnelname mode sit remote $serveripv4addr local $clientipv4addr ttl 255
sudo ip link set $tunnelname up
sudo ip -6 addr add $clientipv6addr dev $tunnelname

sleep 1

color green "Your tunnel $tunnelname has been created!, now lets permenant its up."

    if [ ! -f /etc/network/interfaces ]; then
        color red "File /etc/network/interfaces not found. Installing ifupdown..."
        apt-get update
        apt-get install -y ifupdown
    fi

interfaces="/etc/network/interfaces";
grep $TUNNELNAME $interfaces > /dev/null
if [ $? = 0 ]; then echo "You already have an entry for the tunnel $TUNNELNAME in your $interfaces file."; exit 1; fi

cat << EOF | sudo tee -a $interfaces > /dev/null
# IPv6 via HE tunnel...
auto $tunnelname
iface $tunnelname inet6 v4tunnel
    accept_ra 0
    address $clientipv6addr
    endpoint $serveripv4addr
    local $clientipv4addr
    ttl 255 
    gateway $serveripv6addr
EOF

netplan apply > /dev/null

color green "Your tunnel $tunnelname has been created!, your ipv6 is: $clientipv6addr"

press_enter
}

tunnelbroker_proxy() {
    clear
    if ping6 -c3 google.com &>/dev/null; then
  echo "Your server is ready to set up IPv6 proxies!"
else
  echo "Your server can't connect to IPv6 addresses."
  echo "Please, connect ipv6 interface to your server to continue."
  exit 1
fi

echo "↓ Routed /48 or /64 IPv6 prefix from tunnelbroker (*:*:*::/*):"
read PROXY_NETWORK

if [[ $PROXY_NETWORK == *"::/48"* ]]; then
  PROXY_NET_MASK=48
elif [[ $PROXY_NETWORK == *"::/64"* ]]; then
  PROXY_NET_MASK=64
else
  echo "● Unsupported IPv6 prefix format: $PROXY_NETWORK"
  exit 1
fi

echo "↓ Server IPv4 address from tunnelbroker:"
read TUNNEL_IPV4_ADDR
if [[ ! "$TUNNEL_IPV4_ADDR" ]]; then
  echo "● IPv4 address can't be emty"
  exit 1
fi

echo "↓ Proxies login (can be blank):"
read PROXY_LOGIN

if [[ "$PROXY_LOGIN" ]]; then
  echo "↓ Proxies password:"
  read PROXY_PASS
  if [[ ! "PROXY_PASS" ]]; then
    echo "● Proxies pass can't be emty"
    exit 1
  fi
fi

echo "↓ Port numbering start (default 1500):"
read PROXY_START_PORT
if [[ ! "$PROXY_START_PORT" ]]; then
  PROXY_START_PORT=1500
fi

echo "↓ Proxies count (default 1):"
read PROXY_COUNT
if [[ ! "$PROXY_COUNT" ]]; then
  PROXY_COUNT=1
fi

echo "↓ Proxies protocol (http, socks5; default http):"
read PROXY_PROTOCOL
if [[ PROXY_PROTOCOL != "socks5" ]]; then
  PROXY_PROTOCOL="http"
fi

clear
sleep 1
PROXY_NETWORK=$(echo $PROXY_NETWORK | awk -F:: '{print $1}')
echo "● Network: $PROXY_NETWORK"
echo "● Network Mask: $PROXY_NET_MASK"
HOST_IPV4_ADDR=$(hostname -I | awk '{print $1}')
echo "● Host IPv4 address: $HOST_IPV4_ADDR"
echo "● Tunnel IPv4 address: $TUNNEL_IPV4_ADDR"
echo "● Proxies count: $PROXY_COUNT, starting from port: $PROXY_START_PORT"
echo "● Proxies protocol: $PROXY_PROTOCOL"
if [[ "$PROXY_LOGIN" ]]; then
  echo "● Proxies login: $PROXY_LOGIN"
  echo "● Proxies password: $PROXY_PASS"
fi

echo "-------------------------------------------------"
echo ">-- Updating packages and installing dependencies"
apt-get update >/dev/null 2>&1
apt-get -y install gcc g++ make bc pwgen git >/dev/null 2>&1

echo ">-- Setting up sysctl.conf"
cat >>/etc/sysctl.conf <<END
net.ipv6.conf.eth0.proxy_ndp=1
net.ipv6.conf.all.proxy_ndp=1
net.ipv6.conf.default.forwarding=1
net.ipv6.conf.all.forwarding=1
net.ipv6.ip_nonlocal_bind=1
net.ipv4.ip_local_port_range=1024 64000
net.ipv6.route.max_size=409600
net.ipv4.tcp_max_syn_backlog=4096
net.ipv6.neigh.default.gc_thresh3=102400
kernel.threads-max=1200000
kernel.max_map_count=6000000
vm.max_map_count=6000000
kernel.pid_max=2000000
END

echo ">-- Setting up logind.conf"
echo "UserTasksMax=1000000" >>/etc/systemd/logind.conf

echo ">-- Setting up system.conf"
cat >>/etc/systemd/system.conf <<END
UserTasksMax=1000000
DefaultMemoryAccounting=no
DefaultTasksAccounting=no
DefaultTasksMax=1000000
UserTasksMax=1000000
END

echo ">-- Setting up ndppd"
cd ~
git clone --quiet https://github.com/DanielAdolfsson/ndppd.git >/dev/null
cd ~/ndppd
make -k all >/dev/null 2>&1
make -k install >/dev/null 2>&1
cat >~/ndppd/ndppd.conf <<END
route-ttl 30000
proxy he-ipv6 {
   router no
   timeout 500
   ttl 30000
   rule ${PROXY_NETWORK}::/${PROXY_NET_MASK} {
      static
   }
}
END

echo ">-- Setting up 3proxy"
cd ~
wget -q https://github.com/z3APA3A/3proxy/archive/0.8.13.tar.gz
tar xzf 0.8.13.tar.gz
mv ~/3proxy-0.8.13 ~/3proxy
rm 0.8.13.tar.gz
cd ~/3proxy
chmod +x src/
touch src/define.txt
echo "#define ANONYMOUS 1" >src/define.txt
sed -i '31r src/define.txt' src/proxy.h
make -f Makefile.Linux >/dev/null 2>&1
cat >~/3proxy/3proxy.cfg <<END
#!/bin/bash

daemon
maxconn 100
nserver 1.1.1.1
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6000
flush
END

if [[ "$PROXY_LOGIN" ]]; then
  cat >>~/3proxy/3proxy.cfg <<END
auth strong
users ${PROXY_LOGIN}:CL:${PROXY_PASS}
allow ${PROXY_LOGIN}
END
else
  cat >>~/3proxy/3proxy.cfg <<END
auth none
END
fi

echo ">-- Generating IPv6 addresses"
touch ~/ip.list
touch ~/tunnels.txt

P_VALUES=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
PROXY_GENERATING_INDEX=1
GENERATED_PROXY=""

generate_proxy() {
  a=${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}
  b=${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}
  c=${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}
  d=${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}
  e=${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}${P_VALUES[$RANDOM % 16]}

  echo "$PROXY_NETWORK:$a:$b:$c:$d$([ $PROXY_NET_MASK == 48 ] && echo ":$e" || echo "")" >>~/ip.list

}

while [ "$PROXY_GENERATING_INDEX" -le $PROXY_COUNT ]; do
  generate_proxy
  let "PROXY_GENERATING_INDEX+=1"
done

CURRENT_PROXY_PORT=${PROXY_START_PORT}
for e in $(cat ~/ip.list); do
  echo "$([ $PROXY_PROTOCOL == "socks5" ] && echo "socks" || echo "proxy") -6 -s0 -n -a -p$CURRENT_PROXY_PORT -i$HOST_IPV4_ADDR -e$e" >>~/3proxy/3proxy.cfg
  echo "$PROXY_PROTOCOL://$([ "$PROXY_LOGIN" ] && echo "$PROXY_LOGIN:$PROXY_PASS@" || echo "")$HOST_IPV4_ADDR:$CURRENT_PROXY_PORT" >>~/tunnels.txt
  let "CURRENT_PROXY_PORT+=1"
done

echo ">-- Setting up rc.local"
cat >/etc/rc.local <<END
#!/bin/bash

ulimit -n 600000
ulimit -u 600000
ulimit -i 1200000
ulimit -s 1000000
ulimit -l 200000
/sbin/ip addr add ${PROXY_NETWORK}::/${PROXY_NET_MASK} dev he-ipv6
sleep 5
/sbin/ip -6 route add default via ${PROXY_NETWORK}::1
/sbin/ip -6 route add local ${PROXY_NETWORK}::/${PROXY_NET_MASK} dev lo
/sbin/ip tunnel add he-ipv6 mode sit remote ${TUNNEL_IPV4_ADDR} local ${HOST_IPV4_ADDR} ttl 255
/sbin/ip link set he-ipv6 up
/sbin/ip -6 route add 2000::/3 dev he-ipv6
~/ndppd/ndppd -d -c ~/ndppd/ndppd.conf
sleep 2
~/3proxy/src/3proxy ~/3proxy/3proxy.cfg
exit 0

END

/bin/chmod +x /etc/rc.local

press_enter
}

chisel() {
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
}

while true; do
clear
title_text="Direct / Reverse Tunnels"
tg_title="TG-Group @OPIranCluB"
yt_title="youtube.com/@opiran-inistitute"
echo ""
echo ""
echo -e "$MAGENTA$BOLD             ${title_text} ${NC}"
color blue "$tg_title"
color blue "$yt_title"
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN}  1${NC}) ${YELLOW}SSH Tunnel (v4/6)${NC}"
echo -e "${CYAN}  2${NC}) ${YELLOW}Iptables (v4/6) (UDP+TCP)${NC}"
echo -e "${CYAN}  3${NC}) ${YELLOW}Socat (v4/6)${NC}"
echo -e "${CYAN}  4${NC}) ${YELLOW}Fake tls Tunnel (v4/6)${NC}"
echo -e "${CYAN}  5${NC}) ${YELLOW}FRP (v4/6)${NC}"
echo -e "${CYAN}  6${NC}) ${YELLOW}Udp2raw (v4/6)${NC}"
echo -e "${CYAN}  7${NC}) ${YELLOW}Chisel Tunnel${NC}"
echo -e "${CYAN}  8${NC}) ${YELLOW}ICMP Tunnel ${RED}(soon)${NC}"
echo ""
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN}  9${NC}) ${YELLOW}Private-IP /6to4 / native ipv6 setup${NC}"
echo -e "${CYAN} 10${NC}) ${YELLOW}Tunnel broker setup${NC}"
echo -e "${CYAN} 11${NC}) ${YELLOW}Tunnel broker ipv6 Proxy setup${NC}"
echo ""
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN} 12${NC}) ${YELLOW}Block Iran domain and IP for all panels and nodes${NC}"
echo -e "${CYAN} 13${NC}) ${YELLOW}Softether VPN server autorun${NC}"
echo -e "${CYAN} 14${NC}) ${YELLOW}Marzban Panel autorun ${RED}(soon)${NC}"
echo -e "${CYAN} 15${NC}) ${YELLOW}Marzban Node autorun ${RED}(soon)${NC}"
echo -e "${CYAN} 16${NC}) ${YELLOW}Azumi methods [ICMP] ${RED}(soon)${NC}"
echo ""
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN}17${NC})     ${RED}OPIran OPtimizer${NC}"
echo -e "${CYAN}18${NC})     ${RED}XanMod kernel and BBRv3${NC}"
echo -e "${CYAN}19${NC})     ${RED}Badvpn (UDPGW)${NC}"
echo -e "${CYAN} 0${NC})     ${RED}Exit${NC}"
echo ""
echo ""
echo -e "${GREEN}Select an option ${RED}[1-4]: ${NC}   "
read option

    case $option in
        1)
        ssh
        ;;
        2)
        iptables
        ;;
        3)
        socat
        ;;
        4)
        bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/FakeTlsTunnel/master/FtTunnel.sh)
        ;;
        5)
        if [[ "${release}" == "centos" ]]; then
                    yum update
                    yum install -y curl
                else
                    apt-get update
                    apt-get install -y curl
                fi
        bash <(curl -Ls https://raw.githubusercontent.com/opiran-club/frp-tunnel/main/frp-installer.sh --ipv4)
        ;;
        6)
        if [[ "${release}" == "centos" ]]; then
                    yum update
                    yum install -y curl
                else
                    apt-get update
                    apt-get install -y curl
                fi
        bash <(curl -Ls https://raw.githubusercontent.com/opiran-club/wgtunnel/main/udp2raw.sh --ipv4)
        ;;
        7)
        chisel
        ;;
        9)
        ipv6
        ;;
        10)
        tunnel_broker
        ;;
        11)
        tunnelbroker_proxy
        ;;
        12)
        bash <(curl -s https://raw.githubusercontent.com/opiran-club/block-iran-ip/main/block-ip.sh --ipv4)
        ;;
        13)
        bash <(curl -s -L https://raw.githubusercontent.com/opiran-club/softether/main/opiran-seth)
        ;;
        16)
        sudo apt-get install python3 -y && apt-get install wget -y && apt-get install python3-pip -y && pip3 install color ama && pip3 install netifaces && apt-get install curl -y && python3 <(curl -Ls https://raw.githubusercontent.com/Azumi67/ICMP_tunnels/main/icmp.py --ipv4)
        ;;
        17)
        bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/optimizer.sh --ipv4)
        ;;
        18)
        bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/bbrv3.sh --ipv4)
        ;;
        19)
        wget -N https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/Install/udpgw.sh && bash udpgw.sh
        ;;
        0)
            echo -e "${YELLOW}Exiting.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            press_enter
            ;;
    esac
done

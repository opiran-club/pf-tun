#!/usr/bin/env bash
set -e

color() {
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
            ExecStart=ssh -L $local_port:localhost:$port_remote root@$ip_kharej
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

            cron_command="${cron_schedule} ssh -N -R *:$port_local:localhost:$port_remote root@$ip_iran"
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
            ExecStart=ssh -N -R *:$port_local:localhost:$port_remote root@$ip_iran
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
printf "\e[93m+---------------------------------------------+\e[0m\n"
printf "\e[93m|               SSH TUNNELS                   |\e[0m\n"
printf "\e[93m+---------------------------------------------+\e[0m\n"
echo ""
printf "${CYAN}  1${NC}) ${YELLOW} SSH Tunnels \e[0m\n"
printf "${CYAN}  2${NC}) ${YELLOW} Reverse SSH Tunnels \e[0m\n"
printf "${CYAN}  0${NC}) ${YELLOW} Main Menu \e[0m\n"
echo ""
printf "\e[93m+---------------------------------------------+\e[0m\n"

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
printf "\e[93m+---------------------------------------------+\e[0m\n"
printf "\e[93m|                IP(4/6)tables                |\e[0m\n"
printf "\e[93m+---------------------------------------------+\e[0m\n"
echo ""
printf "${CYAN}  1${NC}) ${YELLOW} IPtables (IPV4) \e[0m\n"
printf "${CYAN}  2${NC}) ${YELLOW} IP6tables (IPV6) \e[0m\n"
printf "${CYAN}  0${NC}) ${YELLOW} Main Menu \e[0m\n"
echo ""
printf "\e[93m+---------------------------------------------+\e[0m\n"

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
        prepration
        Socat_install
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

    cron_command="${cron_schedule} $socat_command"
    (crontab -l || echo "") | grep -v "$socat_command" | (cat; echo "$cron_command") | crontab -

    echo "[Unit]
Description=socat $local_port

[Service]
ExecStart=$socat_command
Restart=always

[Install]
WantedBy=multi-user.target
" > "/etc/systemd/system/socat-$local_port.service"

    systemctl daemon-reload
    systemctl start "socat-$local_port"
    systemctl enable "socat-$local_port"

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

    # Input validation for the local port
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

    # Input validation for the destination port
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

    cron_command_ipv6="${cron_schedule_ipv6} $socat_command_ipv6"
    (crontab -l || echo "") | grep -v "$socat_command_ipv6" | (cat; echo "$cron_command_ipv6") | crontab -

    echo "[Unit]
Description=socat $local_port_ipv6 (IPv6)

[Service]
ExecStart=$socat_command_ipv6
Restart=always

[Install]
WantedBy=multi-user.target
" > "/etc/systemd/system/socat-$local_port_ipv6.service"

    systemctl daemon-reload
    systemctl start "socat-$local_port_ipv6"
    systemctl enable "socat-$local_port_ipv6"

    echo ""
    echo ""
    echo -e "${GREEN}ALL TASKS WERE SUCCESSFULLY DONE, SO KEEP ENJOYING THE IPv6 TUNNEL${NC}"
    echo ""
    echo -e "         ${YELLOW}THANKS FOR CHOOSING ME, OPIRAN :D ${NC}"
}

re_socat_v4() {
    prepration
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

    cron_command="${cron_schedule} $socat_command"
    (crontab -l || echo "") | grep -v "$socat_command" | (cat; echo "$cron_command") | crontab -

    echo "[Unit]
Description=socat $destination_port

[Service]
ExecStart=$socat_command
Restart=always

[Install]
WantedBy=multi-user.target
" > "/etc/systemd/system/socat-$destination_port.service"

    systemctl daemon-reload
    systemctl start "socat-$destination_port"
    systemctl enable "socat-$destination_port"

    echo ""
    echo ""
    echo -e "${GREEN}ALL TASKS WERE SUCCESSFULLY DONE, SO KEEP ENJOYING THE TUNNEL${NC}"
    echo ""
    echo -e "         ${YELLOW}THANKS FOR CHOOSING ME, OPIRAN :D ${NC}"
}

    re_socat_v6() {
        prepration
        Socat_install
        clear
    echo ""
    echo -e "${GREEN}Starting Socat reverse port forwarding over IPv6...${NC}"
    echo ""
    echo ""
    echo -ne "${YELLOW}Enter the local IPv6 address (Iran): ${NC}"
    read local_ip_ipv6

    # Input validation for the destination port
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

    cron_command_ipv6="${cron_schedule_ipv6} $socat_command_ipv6"
    (crontab -l || echo "") | grep -v "$socat_command_ipv6" | (cat; echo "$cron_command_ipv6") | crontab -

    echo "[Unit]
Description=socat $destination_port_ipv6 (IPv6)

[Service]
ExecStart=$socat_command_ipv6
Restart=always

[Install]
WantedBy=multi-user.target
" > "/etc/systemd/system/socat-$destination_port_ipv6.service"

    systemctl daemon-reload
    systemctl start "socat-$destination_port_ipv6"
    systemctl enable "socat-$destination_port_ipv6"

    echo ""
    echo ""
    echo -e "${GREEN}ALL TASKS WERE SUCCESSFULLY DONE, SO KEEP ENJOYING THE IPv6 TUNNEL${NC}"
    echo ""
    echo -e "         ${YELLOW}THANKS FOR CHOOSING ME, OPIRAN :D ${NC}"
}

while true; do
clear
printf "\e[93m+---------------------------------------------+\e[0m\n"
printf "\e[93m|                 Socat Menu                  |\e[0m\n"
printf "\e[93m+---------------------------------------------+\e[0m\n"
echo ""
printf "${CYAN}  1${NC}) ${YELLOW} Direct Socat \e[0m\n"
printf "${CYAN}  2${NC}) ${YELLOW} Reverse Socat \e[0m\n"
printf "${CYAN}  0${NC}) ${YELLOW} Main Menu \e[0m\n"
echo ""
printf "\e[93m+---------------------------------------------+\e[0m\n"

echo ""
echo -e "${GREEN}Select an option ${RED}[1-2]: ${NC}   "
read option

case $option in
    1)
            while true; do
            clear
            printf "\e[93m+---------------------------------------------+\e[0m\n"
            printf "\e[93m|              Direct Socat Menu              |\e[0m\n"
            printf "\e[93m+---------------------------------------------+\e[0m\n"
            echo ""
            printf "${CYAN}  1${NC}) ${YELLOW} Direct Socat (IPV4) \e[0m\n"
            printf "${CYAN}  2${NC}) ${YELLOW} Direct Socat (IPV6) \e[0m\n"
            printf "${CYAN}  0${NC}) ${YELLOW} Main Menu \e[0m\n"
            echo ""
            printf "\e[93m+---------------------------------------------+\e[0m\n"

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
            printf "\e[93m+---------------------------------------------+\e[0m\n"
            printf "\e[93m|              Reverse Socat Menu             |\e[0m\n"
            printf "\e[93m+---------------------------------------------+\e[0m\n"
            echo ""
            printf "${CYAN}  1${NC}) ${YELLOW} Reverse Socat (IPV4) \e[0m\n"
            printf "${CYAN}  2${NC}) ${YELLOW} Reverse Socat (IPV6) \e[0m\n"
            printf "${CYAN}  0${NC}) ${YELLOW} Main Menu \e[0m\n"
            echo ""
            printf "\e[93m+---------------------------------------------+\e[0m\n"

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
    echo -e "${YELLOW}______________________________________________________${NC}"
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
    echo -e "${YELLOW}______________________________________________________${NC}"
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
tg_title="TG-Group @OPIranCluB"
yt_title="youtube.com/@opiran-inistitute"
clear
echo -e "              ${MAGENTA}${title_text}${NC}"
printf "\e[93m+---------------------------------------------+\e[0m\n" 
echo -e "${BLUE}$tg_title ${NC}"
echo -e "${BLUE}$yt_title  ${NC}"
printf "\e[93m+---------------------------------------------+\e[0m\n" 
echo ""
echo -e "${CYAN}  1. ${YELLOW}Configure FRP(s) - (Kharej) or server${NC}"
echo -e "${CYAN}  2. ${YELLOW}Configure FRP(c) - (Iran) or client${NC}"
echo -e "${CYAN}  3. ${YELLOW}Uninstall FRP - client and server${NC}"
echo -e "${CYAN}  4. ${YELLOW}Display FRP Configuration${NC}"
echo ""
echo -e "${CYAN}  0. ${RED}Main Menu${NC}"
echo ""
echo -ne "${YELLOW}Enter your choice: ${NC}"
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

while true; do
clear
title_text="Direct / Reverse Tunnels"
tg_title="TG-Group @OPIranCluB"
yt_title="youtube.com/@opiran-inistitute"
clear
color magenta"                 ${title_text}"
printf "\e[93m+---------------------------------------------+\e[0m\n" 
color blue "$tg_title"
color blue "$yt_title"
printf "\e[93m+---------------------------------------------+\e[0m\n" 
echo ""
echo -e "${CYAN}  1${NC}) ${YELLOW}SSH Tunnel (IPV4/6)${NC}"
echo -e "${CYAN}  2${NC}) ${YELLOW}Iptables (IPv4/6) (UDP+TCP)${NC}"
echo -e "${CYAN}  3${NC}) ${YELLOW}Socat (IPv4/6)${NC}"
echo -e "${CYAN}  4${NC}) ${YELLOW}Fake tls Tunnel (IPv4/6)${NC}"
echo -e "${CYAN}  5${NC}) ${YELLOW}FRP (IPv4/6)${NC}"
echo -e "${CYAN}  6${NC}) ${YELLOW}Udp2raw (IPv4/6)${NC}"
echo ""
echo -e "${CYAN} 0${NC}) ${RED}Exit${NC}"
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

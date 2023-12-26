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

prepration() {
    root
    clear
    apt-get update
    apt-get -y install iptables socat curl jq openssl wget ca-certificates unzip
}

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
                sysctl net.ipv4.ip_forward=1
                iptables -t nat -A PREROUTING -p tcp --dport "${local_port}" -j DNAT --to-destination "${forwarding_ip}:${forwarding_port}"
                iptables -t nat -A POSTROUTING -p tcp -d "${forwarding_ip}" --dport "${forwarding_port}" -j SNAT --to-source "${local_ip}"
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport "${local_port}" -j ACCEPT
            elif [[ ${forwarding_type} == "UDP" ]]; then
                sysctl net.ipv4.ip_forward=1
                iptables -t nat -A PREROUTING -p udp --dport "${local_port}" -j DNAT --to-destination "${forwarding_ip}:${forwarding_port}"
                iptables -t nat -A POSTROUTING -p udp -d "${forwarding_ip}" --dport "${forwarding_port}" -j SNAT --to-source "${local_ip}"
                iptables -I INPUT -m state --state NEW -m udp -p udp --dport "${local_port}" -j ACCEPT
            elif [[ ${forwarding_type} == "TCP+UDP" ]]; then
                sysctl net.ipv4.ip_forward=1
                iptables -t nat -A PREROUTING -p tcp --dport "${local_port}" -j DNAT --to-destination "${forwarding_ip}:${forwarding_port}"
                iptables -t nat -A POSTROUTING -p tcp -d "${forwarding_ip}" --dport "${forwarding_port}" -j SNAT --to-source "${local_ip}"
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport "${local_port}" -j ACCEPT

                sysctl net.ipv4.ip_forward=1
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

delete_port_forwarding() {
    root
    clear
    echo -ne "${YELLOW}Enter the port to delete forwarding rules: ${NC}"
    read local_port_delete

    if [[ -z "${local_port_delete}" ]]; then
        echo -e "${RED}Invalid input. Port is required.${NC}"
        press_enter
        return
    fi

    iptables -t nat -D PREROUTING -p tcp --dport "${local_port_delete}" -j DNAT --to-destination "${forwarding_ip}:${forwarding_port}" 2>/dev/null
    iptables -t nat -D POSTROUTING -p tcp -d "${forwarding_ip}" --dport "${forwarding_port}" -j SNAT --to-source "${local_ip}" 2>/dev/null
    iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport "${local_port_delete}" -j ACCEPT 2>/dev/null

    iptables -t nat -D PREROUTING -p udp --dport "${local_port_delete}" -j DNAT --to-destination "${forwarding_ip}:${forwarding_port}" 2>/dev/null
    iptables -t nat -D POSTROUTING -p udp -d "${forwarding_ip}" --dport "${forwarding_port}" -j SNAT --to-source "${local_ip}" 2>/dev/null
    iptables -D INPUT -m state --state NEW -m udp -p udp --dport "${local_port_delete}" -j ACCEPT 2>/dev/null

    if [[ "${release}" == "centos" ]]; then
        service iptables save
    else
        iptables-save > /etc/iptables.up.rules
    fi

    echo -e "${GREEN}Port forwarding rules for port ${local_port_delete} deleted successfully.${NC}"
    press_enter
}

check_port_forwarding() {
    clear
    echo -ne "${YELLOW}Enter the port to check forwarding rules: ${NC}"
    read local_port_check

    if [[ -z "${local_port_check}" ]]; then
        echo -e "${RED}Invalid input. Port is required.${NC}"
        press_enter
        return
    fi

    tcp_rules_exist=$(iptables -t nat -C PREROUTING -p tcp --dport "${local_port_check}" -j DNAT --to-destination "${forwarding_ip}:${forwarding_port}" 2>/dev/null && echo "yes" || echo "no")

    udp_rules_exist=$(iptables -t nat -C PREROUTING -p udp --dport "${local_port_check}" -j DNAT --to-destination "${forwarding_ip}:${forwarding_port}" 2>/dev/null && echo "yes" || echo "no")

    if [[ "${tcp_rules_exist}" == "yes" || "${udp_rules_exist}" == "yes" ]]; then
        echo -e "${GREEN}Forwarding rules exist for port ${local_port_check}.${NC}"
    else
        echo -e "${RED}No forwarding rules found for port ${local_port_check}.${NC}"
    fi

    press_enter
}


while true; do
clear
printf "+---------------------------------------------+\n"
printf "\e[93m|                IP(4/6)tables                |\e[0m\n"
printf "+---------------------------------------------+\n"
echo ""
printf "${CYAN}  1${NC}) ${YELLOW} IPtables (IPV4) \e[0m\n"
printf "${CYAN}  2${NC}) ${YELLOW} IP6tables (IPV6) ${RED} (recommended)\e[0m\n"
printf "${CYAN}  3${NC}) ${YELLOW} Delete port forwarding\e[0m\n"
printf "${CYAN}  4${NC}) ${YELLOW} Status / Check port forwarding tables\e[0m\n"
echo
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
    3)
        delete_port_forwarding
        ;;
    4)
        check_port_forwarding
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

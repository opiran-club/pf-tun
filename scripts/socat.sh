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
}

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

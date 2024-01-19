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
    
    sleep 2
    modprobe sit
    ip tunnel add tun6to4 mode sit ttl 255 remote any local "$ipv4"
    ip -6 link set dev tun6to4 mtu 1480
    ip link set dev tun6to4 up
    ip -6 addr add "$ipv6_address/16" dev tun6to4
    ip -6 route add 2000::/3 via ::192.88.99.1 dev tun6to4 metric 1
    sleep 1
    echo -e "    ${GREEN} [$ipv6_address] was added and routed successfully, please${RED} reboot ${NC}"

    opiran_6to4_dir="/root/opiran-6to4"
    opiran_6to4_script="$opiran_6to4_dir/6to4"

    if [ ! -d "$opiran_6to4_dir" ]; then
        mkdir "$opiran_6to4_dir"
    else
        rm -f "$opiran_6to4_script"
    fi

cat << EOF | tee -a "$opiran_6to4_script" > /dev/null
#!/bin/bash

modprobe sit
ip tunnel add tun6to4 mode sit ttl 255 remote any local "$ipv4"
ip -6 link set dev tun6to4 mtu 1480
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

    
    sleep 3
    /sbin/ip -6 addr del "$selected_ipv6" dev tun6to4
    echo ""
    echo -e " ${YELLOW}IPv6 address $selected_ipv6 has been deleted please${RED} reboot ${YELLOW}to take action."
}

list_6to4_ipv6() {
    clear
    
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

cat << EOF | tee -a "$opiran_n6_script" > /dev/null
#!/bin/bash
systemctl restart systemd-networkd

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
        echo -e "${CYAN}  1${NC}) ${YELLOW}Range IP ${NC}[10.0.0.0 to 10.255.255.255] ${RED}(recommended)${NC}"
        echo -e "${CYAN}  2${NC}) ${YELLOW}Range IP ${NC}[172.16.0.0 to 172.31.255.255]${NC}"
        echo -e "${CYAN}  3${NC}) ${YELLOW}Range IP ${NC}[192.168.0.0 to 192.168.255.255]${NC}"
        echo -e "${CYAN}  4${NC}) ${YELLOW}Enter custom private IPv4${NC}"
        echo -e "${CYAN}  0${NC}) ${RED}Back${NC}"
        echo -e "${GREEN}Select an option ${RED}[1-4]: ${NC}   "
        read option

        case $option in
            1)
                echo ""
                echo ""
                color magenta "!!!WARNING!!!"
                color red "If you want tunnel 2 server together with a private IP"
                color red "they should NOT have the same IPv4 address"
                color red "For example, 10.1.2.3 and for the 2nd server 10.1.2.4, and for the 3rd server 10.1.2.5, ...."
                color green "My suggestion is: 10.0.0.1"
                echo ""
                echo ""
                echo -ne "${YELLOW}Enter private IPv4 address (ex. 10.0.0.1, 2, 3, ...): ${NC}"
                read privateipv4
                echo ""
                ;;
            2)
                echo ""
                echo ""
                color magenta "!!!WARNING!!!"
                color red "If you want tunnel 2 server together with a private IP"
                color red "they should NOT have the same IPv4 address"
                color red "For example, 172.17.18.19 and for the 2nd server 172.17.18.20, and for the 3rd server 172.17.18.21, ...."
                color green "My suggestion is: 172.16.0.1"
                echo ""
                echo ""
                echo -ne "${YELLOW}Enter private IPv4 address  (ex. 172.16.0.1, 2, 3, ...): ${NC}"
                read privateipv4
                echo ""
                ;;
            3)
                echo ""
                echo ""
                color magenta "!!!WARNING!!!"
                color red "If you want tunnel 2 server together with a private IP"
                color red "they should NOT have the same IPv4 address"
                color red "For example, 192.168.42.42 and for the 2nd server 192.168.42.43, and for the 3rd server 192.168.42.44, ...."
                color green "My suggestion is: 192.168.42.42"
                echo ""
                echo ""
                echo -ne "${YELLOW}Enter private IPv4 address  (ex. 192.168.42.41, 2, 3, ...): ${NC}"
                read privateipv4
                echo ""
                ;;
            4)
                echo ""
                echo ""
                echo -ne "${YELLOW}Enter your desired private IPv4 address (ex. 192.168.0.1 , 172.17.18.19, 10.1.2.3, ...): ${NC}"
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

ip_command="ip address add $privateipv4/24 dev $private_interface"

# Check if the address already exists before adding it
if ! ip address show dev $private_interface | grep -q "$privateipv4"; then
    $ip_command
fi

cat << EOF | tee -a "$startup_private_ipv4" > /dev/null
#!/bin/bash
systemctl restart systemd-networkd
# $privateipv4
# $private_interface
$ip_command
EOF

        chmod +x "$startup_private_ipv4"

        # Add the cronjob
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
                color green "My suggestion is: fd12:3456:789a::[last_part_ipv6]"
                echo ""
                echo ""
                echo -ne "${YELLOW}Enter the [last_part_ipv6] of private IPv6 address (e.g., 1, 2, 3, ...): ${NC}"
                read last_part_ipv6
                privateipv6="fd12:3456:789a::$last_part_ipv6/64"
                ;;
            2)
                echo ""
                echo ""
                color magenta "!!!WARNING!!!"
                color red "If you want tunnel 2 server together with private IPv6"
                color red "they should NOT be the same IPv6 address"
                color red "For example, fd55:9876:5432:1::1 and for the 2nd server fd55:9876:5432:1::2 and for the 3rd server fd55:9876:5432:1::3, ...."
                color green "My suggestion is: fd42:abcd:1234::[last_part_ipv6]"
                echo ""
                echo ""
                echo -ne "${YELLOW}Enter the [last_part_ipv6] of private IPv6 address (e.g., 1, 2, 3, ...): ${NC}"
                read last_part_ipv6
                privateipv6="fd42:abcd:1234::$last_part_ipv6/64"
                ;;
            3)
                echo -ne "${YELLOW}Enter custom IPv6 address (e.g., fc12:3456:789a:1::1/64): ${NC}"
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
private_interface_ip6="${main_interface}:${next_interface_number}"
startup_private_ipv6="/root/private_ipv6"
ip_command="ip -6 addr add $privateipv6 dev $private_interface_ip6"
route_command="ip -6 route add $privateipv6 dev $main_interface"
if ! route -n | grep -q "$privateipv6"; then
    $ip_command
    $route_command
else
    color red "$privateipv6 is exist, try again"
break
fi

touch "$startup_private_ipv6"

cat << EOF | tee -a "$startup_private_ipv6" > /dev/null
#!/bin/bash
systemctl restart systemd-networkd
#$privateipv6
#$private_interface_ip6
$ip_command
$route_command
EOF

    chmod +x "$startup_private_ipv6"

    (crontab -l || echo "") | grep -v "$startup_private_ipv6" | { cat; echo "@reboot $startup_private_ipv6"; } | crontab -

    echo "Private IPv6 was added successfully, your private IP is: $privateipv6"
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

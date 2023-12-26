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

tunnel_broker() {
    clear
    color green "Creating tunnelbroker IPV6"
    echo ""
    color yellow "at first visit tunnelbroker websites and create your tunnel then comeback here"
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

color green "Your tunnel $tunnelname has been created!, your ipv6 is: $clientipv6addr, please reboot server."
press_enter
}

speedtest() {
    clear
while true; do
color blue "         Speedtest"
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN}  1. ${YELLOW}Original speedtest script${NC}"
echo -e "${CYAN}  2. ${YELLOW}Benchmark${NC}"
echo
echo -e "${CYAN}  0. ${YELLOW}Back${NC}"
echo
echo -e "${GREEN}Select an option ${RED}[0-2]: ${NC}"   
read option
case $option in
    1)
        apt-get install curl -y && curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash && apt-get install speedtest -y && speedtest
        ;;
    2)
        wget -qO- network-speed.xyz | bash -s -- -r eu
        ;;
    0)
        echo -e "${YELLOW}Exiting.${NC}"
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
title_text="All In One OPIran Script"
tg_title="TG-Group @OPIranCluB"
yt_title="youtube.com/@opiran-inistitute"
echo ""
echo ""
echo -e "$MAGENTA$BOLD             ${title_text} ${NC}"
echo
color blue "$tg_title"
color blue "$yt_title"
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN}  1. ${YELLOW}SSH Tunnel (v4/6)${NC}"
echo -e "${CYAN}  2. ${YELLOW}Iptables (v4/6) (UDP+TCP)${NC}"
echo -e "${CYAN}  3. ${YELLOW}Socat (v4/6)${NC}"
echo -e "${CYAN}  4. ${YELLOW}Fake tls Tunnel (v4/6)${NC}"
echo -e "${CYAN}  5. ${YELLOW}FRP (v4/6)${NC}"
echo -e "${CYAN}  6. ${YELLOW}Udp2raw (v4/6)${NC}"
echo -e "${CYAN}  7. ${YELLOW}Chisel Tunnel${NC}"
echo -e "${CYAN}  8. ${YELLOW}ICMP Tunnel ${RED}(soon)${NC}"
echo ""
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN}  9. ${YELLOW}Private-IP /6to4 / native ipv6 setup${NC}"
echo -e "${CYAN} 10. ${YELLOW}Tunnel broker setup${NC}"
echo ""
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN} 11. ${YELLOW}Block Iran domain and IP for all panels and nodes${NC}"
echo -e "${CYAN} 12. ${YELLOW}Softether VPN server autorun${NC}"
echo -e "${CYAN} 13. ${YELLOW}Marzban Panel autorun ${RED}(soon)${NC}"
echo -e "${CYAN} 14. ${YELLOW}Marzban Node autorun ${RED}(soon)${NC}"
echo -e "${CYAN} 15. ${YELLOW}Azumi methods [ICMP]${NC}"
echo ""
printf "+---------------------------------------------+\n" 
echo ""
echo -e "${CYAN} 16.    ${RED}OPIran OPtimizer${NC}"
echo -e "${CYAN} 17.    ${RED}XanMod kernel and BBRv3${NC}"
echo -e "${CYAN} 18.    ${RED}Badvpn (UDPGW)${NC}"
echo -e "${CYAN} 19.    ${RED}Speedtest${NC}"
echo
echo -e "${CYAN} 0.     ${RED}Exit${NC}"
echo ""
echo ""
echo -e "${GREEN}Select an option ${RED}[1-4]: ${NC}   "
read option

    case $option in
        1)
        bash <(curl -fsSL https://raw.githubusercontent.com/opiran-club/pf-tun/main/scripts/ssh-tunnels.sh --ipv4)
        ;;
        2)
        bash <(curl -fsSL https://raw.githubusercontent.com/opiran-club/pf-tun/main/scripts/iptables.sh --ipv4)
        ;;
        3)
        bash <(curl -fsSL https://raw.githubusercontent.com/opiran-club/pf-tun/main/scripts/socat.sh --ipv4)
        ;;
        4)
        bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/FakeTlsTunnel/master/FtTunnel.sh --ipv4)
        ;;
        5)
        bash <(curl -Ls https://raw.githubusercontent.com/opiran-club/pf-tun/main/scripts/frp.sh --ipv4)
        ;;
        6)
        bash <(curl -Ls https://raw.githubusercontent.com/opiran-club/wgtunnel/main/udp2raw.sh --ipv4)
        ;;
        7)
        bash <(curl -Ls https://raw.githubusercontent.com/opiran-club/pf-tun/main/scripts/chisel.sh --ipv4)
        ;;
        9)
        bash <(curl -Ls https://raw.githubusercontent.com/opiran-club/pf-tun/main/scripts/private-ips.sh --ipv4)
        ;;
        10)
        tunnel_broker
        ;;
        11)
        bash <(curl -s https://raw.githubusercontent.com/opiran-club/block-iran-ip/main/block-ip.sh --ipv4)
        ;;
        12)
        bash <(curl -s -L https://raw.githubusercontent.com/opiran-club/softether/main/opiran-seth)
        ;;
        15)
        sudo apt-get install python3 -y && apt-get install wget -y && apt-get install python3-pip -y && pip3 install colorama && pip3 install netifaces && apt-get install curl -y && python3 <(curl -Ls https://raw.githubusercontent.com/Azumi67/ICMP_tunnels/main/icmp.py --ipv4)
        ;;
        16)
        bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/optimizer.sh --ipv4)
        ;;
        17)
        bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/bbrv3.sh --ipv4)
        ;;
        18)
        wget -N https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/Install/udpgw.sh && bash udpgw.sh
        ;;
        19)
        speedtest
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

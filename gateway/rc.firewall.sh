#!/bin/sh

#################################################################################
#								            #
# rc.firewall - Initial SIMPLE IP Firewall script for Linux and iptables        #
#									    #
# 02/17/2020  Created by Dijiang Huang ASU SNAC Lab      			    #
# updated 05/12/2021							    #
#################################################################################
#                                                                               #
#                                                                               #
# Configuration options, these will speed you up getting this script to         #
# work with your own setup.                                                     #
#                                                                               #
# your LAN's IP range and localhost IP. /24 means to only use the first 24      #
# bits of the 32 bit IP address. the same as netmask 255.255.255.0              #
#                                                                               #
#                                                                               # 
#################################################################################
#
# 1. Configuration options.
# NOTE that you need to change the configuration based on your own network setup.
# The defined alias and variables allow you to manage and update the entire 
# configurations easily, and more readable :-)
#
# Lab Network Topology
#
# ---------              ----------------               
# |Client |__Client_NET__|Gateway/Server |
# ---------              ----------------              
#                            |
#                            |Internet           
#                            |              ________ 
#                        ----------        /        \
#                        |Host PC |________|Internet|
#                        ----------        \________/ 
#                        
#

####
# 1.1. Internet ip address
# 
#
Internet_IP="10.0.1.x"
Internet_IP_RANGE="10.0.1.0/24"
Internet_BCAST_ADRESS="10.0.1.255"
Internet_IFACE="enp0s8"

####
# 1.2 Client network configuration.
#
#

#
# IP addresses of the client-side network
#
Client_NET_IP="10.0.2.6"
Client_NET_IP_RANGE="10.0.2.0/24"
Client_NET_BCAST_ADRESS="10.0.2.255"
Client_NET_IFACE="enp0s3"


#
# IP aliases for the server (server's IP address)
#
LO_IFACE="lo"
LO_IP="127.0.0.1"
WEB_IP_ADDRESS="127.0.0.1"
#IP aliases for NATed services (this is the GW's ip on client network)
NAT_WEB_IP_ADDRESS="10.0.2.7"

####
# 1.4 IPTables Configuration.
#

IPTABLES="/sbin/iptables"


#######################################################
#                                                     #
# 2. Module loading.                                  #
#                                                     #
#######################################################
#
# Needed to initially load modules
#
/sbin/depmod -a	 

#
# flush iptables
#
$IPTABLES -F 
$IPTABLES -X 
$IPTABLES -F -t nat

#####
# 2.1 Required modules
#

/sbin/modprobe ip_tables
/sbin/modprobe ip_conntrack
/sbin/modprobe iptable_filter
/sbin/modprobe iptable_mangle
/sbin/modprobe iptable_nat
/sbin/modprobe ipt_LOG
/sbin/modprobe ipt_limit
/sbin/modprobe ipt_state

#####
# 2.2 Non-frequently used modules
#

#/sbin/modprobe ipt_owner
#/sbin/modprobe ipt_REJECT
#/sbin/modprobe ipt_MASQUERADE
#/sbin/modprobe ip_conntrack_ftp
#/sbin/modprobe ip_conntrack_irc
#/sbin/modprobe ip_nat_ftp

###########################################################################
#
# 3. /proc set up.
#

#
# 3.1 Required proc configuration
#

#
# Enable ip_forward, this is critical since it is turned off as defaul in 
# Linux.
#
echo "1" > /proc/sys/net/ipv4/ip_forward

#
# 3.2 Non-Required proc configuration
#

#
# Dynamic IP users:
#
#echo "1" > /proc/sys/net/ipv4/ip_dynaddr

###########################################################################
#
# 4. rules set up.
#

# The kernel starts with three lists of rules; these lists are called firewall
# chains or just chains. The three chains are called INPUT, OUTPUT and FORWARD.
#
# The chains are arranged like so:
#
#                     _____
#                    /     \
#  -->[Routing ]--->|FORWARD|------->
#     [Decision]     \_____/        ^
#          |                        |
#          v                       ____
#         ___                     /    \
#        /   \                   |OUTPUT|
#       |INPUT|                   \____/
#        \___/                      ^
#          |                        |
#           ----> Local Process ----
#
# 1. When a packet comes in (say, through the Ethernet card) the kernel first 
#    looks at the destination of the packet: this is called `routing'.
# 2. If it's destined for this box, the packet passes downwards in the diagram, 
#    to the INPUT chain. If it passes this, any processes waiting for that 
#    packet will receive it. 
# 3. Otherwise, if the kernel does not have forwarding enabled, or it doesn't 
#    know how to forward the packet, the packet is dropped. If forwarding is 
#    enabled, and the packet is destined for another network interface (if you 
#    have another one), then the packet goes rightwards on our diagram to the 
#    FORWARD chain. If it is ACCEPTed, it will be sent out. 
# 4. Finally, a program running on the box can send network packets. These 
#    packets pass through the OUTPUT chain immediately: if it says ACCEPT, then 
#    the packet continues out to whatever interface it is destined for. 
#

# Ravindranath Thiyagarajan
# This command is used to remove the default GW 10.0.2.1
# so that default gateway 10.0.1.1 via enp0s8 takes effect
sudo ip route del default via 10.0.2.1 dev enp0s3

#####
# 4.1 Filter table
#

#
# 4.1.1 Set policies
#

#
# Set default policies for the INPUT, FORWARD and OUTPUT chains
#

# Whitelist (Whitelist is preferred)
$IPTABLES -P INPUT DROP
$IPTABLES -P OUTPUT DROP
$IPTABLES -P FORWARD DROP

# Blacklist
#$IPTABLES -P INPUT ACCEPT
#$IPTABLES -P OUTPUT ACCEPT
#$IPTABLES -P FORWARD ACCEPT

#
# 4.1.2 Create user-specified chains
#

#
# Example of creating a chain for bad tcp packets
#

#$IPTABLES -N bad_tcp_packets

#
# Create separate chains for allowed (whitelist), ICMP, TCP and UDP to traverse
#

#$IPTABLES -N allowed
#$IPTABLES -N tcp_packets
#$IPTABLES -N udp_packets
#$IPTABLES -N icmp_packets

#
# In the following 4.1.x, you can provide individual user-specified rules


#
# 4.1.3 Example of create content in user-specified chains (bad_tcp_packets)
#

#
# bad_tcp_packets chain
#

#$IPTABLES -A bad_tcp_packets -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j REJECT --reject-with tcp-reset 
#$IPTABLES -A bad_tcp_packets -p tcp ! --syn -m state --state NEW -j LOG --log-prefix "New not syn:"
#$IPTABLES -A bad_tcp_packets -p tcp ! --syn -m state --state NEW -j DROP

#
# 4.1.4 Example of allowed chain (allow packets for initial TCP or already established TCP sessions)
#

#$IPTABLES -A allowed -p TCP --syn -j ACCEPT
#$IPTABLES -A allowed -p TCP -m state --state ESTABLISHED,RELATED -j ACCEPT
#$IPTABLES -A allowed -p TCP -j DROP


#####
# 4.2 FORWARD chain
#

#
# Provide your forwarding rules below
#

# example of checking bad tcp packets
#$IPTABLES -A FORWARD -p tcp -j bad_tcp_packets

# Allow http traffic from client network to server network
# Ravindranath Thiyagarajan
# Forward ICMP echo request packets with destination address 8.8.8.8 coming in from enp0s3 to enp0s8

$IPTABLES -A FORWARD -p icmp --icmp-type 8 -i enp0s3 -s $Client_NET_IP -d 8.8.8.8 -o enp0s8 -j ACCEPT
# Ravindranath Thiyagarajan
# Forward ICMP echo reply packets with source address 8.8.8.8 coming in from enp0s8 to enp0s3
$IPTABLES -A FORWARD -p icmp --icmp-type 0 -i enp0s8 -s 8.8.8.8 -d $Client_NET_IP -o enp0s3 -j ACCEPT


# example of using allowed
#$IPTABLES -A FORWARD -p tcp -j allowed


#####
# 4.3 INPUT chain
#

#
# Ravindranath Thiyagarajan : The below rule is added in order to accept HTTP 
# TCP packets from client IP address 10.0.2.6 destined to Webserver IP address 10.0.2.7 and destination port 80
#
$IPTABLES -A INPUT -p TCP -s $Client_NET_IP --dport 80 -i $Client_NET_IFACE -d $NAT_WEB_IP_ADDRESS -j ACCEPT
$IPTABLES -A INPUT -p TCP -s $LO_IP -d $LO_IP --dport 80 -j ACCEPT

#
# Example of checking bad TCP packets we don't want.
#

#$IPTABLES -A INPUT -p tcp -j bad_tcp_packets

#
# Ravindranath Thiyagarajan : The below rule is added in order to avoid client
# ping to server IP 10.0.2.7. The below rule will drop the ICMP packets with the destination
# IP address 10.0.2.7 on enp0s3 interface
#
$IPTABLES -A INPUT -p icmp -i enp0s3 -d $NAT_WEB_IP_ADDRESS -j DROP

# Allowed ping from client and server

#$IPTABLES -A INPUT -p icmp -j ACCEPT

#####
# 4.3 OUTPUT chain
#

#
# Provide your output rules below to allow web traffic (port 80) go back to client
#

# example Allowed ping message back to client 

# $IPTABLES -A OUTPUT -p icmp -j ACCEPT
#
# Ravindranath Thiyagarajan : The below rule is added in order to allow sending the HTTP response
# packet from the source IP address 10.0.2.7 and source port 80 to the client machine with IP address 10.0.2.6
#

$IPTABLES -A OUTPUT -p TCP -s $NAT_WEB_IP_ADDRESS --sport 80 -d $Client_NET_IP -j ACCEPT
$IPTABLES -A OUTPUT -p TCP -s $LO_IP -d $LO_IP --sport 80 -j ACCEPT

#####################################################################
#                                                                   #
# 5. NAT setup                                                      #
#                                                                   #
#####################################################################

#####
# 5.1  PREROUTING chain. (No used in this lab)
#
#
# Provide your NAT PREROUTING rules (packets come into your private domain)
#

#
# Example of enable http to internal web server behind the firewall (port forwarding)
#

# web 
# not used in this lab
#$IPTABLES -t nat -A PREROUTING -p tcp -d $NAT_WEB_IP_ADDRESS --dport 80 -j DNAT --to $WEB_IP_ADDRESS




#####
# 5.2 POSTROUTING chain.
#
#
# Provide your NAT PREROUTING rules (packets go to the internet domain)
# Add your own rule below to only allow ping from client to 8.8.8.8 on internet

# Example: Allow client node to access to all Internet using masquerade
# Ravindranath Thiyagarajan
# enable MASQUERADE over exit interface enp0s8
$IPTABLES -t nat -A POSTROUTING -o $Internet_IFACE -j MASQUERADE




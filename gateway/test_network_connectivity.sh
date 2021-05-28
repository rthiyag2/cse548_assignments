#!/bin/sh

# set iptables default policy to blacklist
sudo iptables -X
sudo iptables -F
sudo iptables -P INPUT ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -P FORWARD ACCEPT

# enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Remove the default GW 10.0.2.1 so that 10.0.1.1 takes effect
sudo ip route del default via 10.0.2.1 dev enp0s3

# Apply MASQUERADE over exit interface
sudo iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE



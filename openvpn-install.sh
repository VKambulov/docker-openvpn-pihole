#!/bin/bash

# Aurthor: Muhammad Asim
# CoAuthor mr-bolle
#Purpose: Setup OpenVPN in quick time. https://www.youtube.com/watch?v=NQpzIh7kSkY
set -euo pipefail

echo "Pull image kylemanna/openvpn..."
docker pull kylemanna/openvpn
sleep 1

echo -e "\nMake a directory at /openvpn_data\n"
mkdir -p $PWD/openvpn_data && OVPN_DATA=$PWD/openvpn_data
echo -e "OpenVPN Data Path is set to: $OVPN_DATA\n"

export OVPN_DATA

echo -e "\nGenerate OpenVPN config...\n"
# read IPv4 from Pi-Hole Container 
PIHOLE_IP=`grep 'ipv4' docker-compose.yml | awk ' NR==2 {print $2}'`
docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -e 'auth SHA512' -n $PIHOLE_IP -u udp://IP -T "AES-256-CBC"
# more Option: https://github.com/kylemanna/docker-openvpn/blob/master/bin/ovpn_genconfig

echo -e "\nAfter a Shortwhile You need to enter your Server Secure Password details please wait ...\n"

sleep 3
echo -e "\nInit CA...\n"
docker run --env-file=vars_easyrsa -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki

echo -e "\nCreate Client...\n"
sleep 1
read -p "Please Provide Your Client Name: " CLIENTNAME
docker run --env-file=vars_easyrsa -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full $CLIENTNAME nopass

echo -e "\nGenerate .ovpn file\n"
echo -e "\n$CLIENTNAME ok\n"
docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient $CLIENTNAME > $OVPN_DATA/$CLIENTNAME.ovpn

# Show all values
echo -e "\nAll done!"

#Note: If you remove the docker container by mistake, simply copy and paster 4TH Step, all will set as previously.

#END

#To revoke a client or user 
# docker run --volumes-from ovpn-data --rm -it kylemanna/openvpn ovpn_revokeclient 1234 remove

# *******************************************************************************************************************


# create a new sub-network (if not exist)
docker network inspect vpn-net &>/dev/null || 
    docker network create --driver=bridge --subnet=172.110.1.0/24 --gateway=172.110.1.1 network

# set DNSSEC=true to pihole/setupVars.conf 
mkdir -p pihole && echo "DNSSEC=true" >> pihole/setupVars.conf
echo "API_QUERY_LOG_SHOW=blockedonly" >> pihole/setupVars.conf

# run docker-compose
docker-compose up -d

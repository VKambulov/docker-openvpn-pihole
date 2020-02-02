#!/bin/bash
# Aurthor: Muhammad Asim
# CoAuthor mr-bolle

OVPN_DATA=$PWD/openvpn_data
export OVPN_DATA

echo -e "\nCreate Client...\n"
sleep 1
read -p "Please Provide Your Client Name: " CLIENTNAME
docker run --env-file=vars_easyrsa -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full $CLIENTNAME nopass

echo -e "\nGenerate Google Authentificator...\n"
sleep 1
docker run -v $OVPN_DATA:/etc/openvpn --rm -t kylemanna/openvpn ovpn_otp_user $CLIENTNAME

echo -e "\nGenerate .ovpn file...\n"
echo -e "\n$CLIENTNAME ok\n"
docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient $CLIENTNAME > $OVPN_DATA/$CLIENTNAME.ovpn

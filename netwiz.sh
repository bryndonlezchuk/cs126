#!/bin/bash

#Network Wizard		Feb 6, 2015
#Bryndon Lezchuk <bryndonlezchuk@gmail.com>

source library.sh
trap cleanup SIGINT SIGTERM



syntax () {
	message "Usage: netwiz.sh [-xvh] [-i ip_address] [-m network_mask] [-g default_gateway] [-n nameserver_address] interface\n"
	message "[-x]"
	message "	Runs in debug mode\n"
	message "[-v]"
	message "	Runs in verbose mode\n"
	message "[-h]"
	message "	Help\n"
	message "[-i ip_address]"
	message "	Disables interactive mode and sets the ip address\n"
	message "[-m network_mask]"
	message "	Disables interactive mode and sets the network mask\n"
	message "[-g default_gateway]"
	message "	Disables interactive mode and sets the default gateway\n"
	message "[-n nameserver_address]"
	message "	Disables interactive mode and sets the nameserver address\n"
	echo
}

editifcfg () {
	DIRECTIVE="$1"
	local ARG="$2"

	if grep -q "^${DIRECTIVE}=" "$DEVFILE"
	then
		sedreplace "$(grep ${DIRECTIVE}= $DEVFILE)" "${DIRECTIVE}=$ARG" "$DEVFILE"
		verbout "Changing $DIRECTIVE to $ARG in ifcfg-$DEVICE"
	else
		echo "${DIRECTIVE}=\"$ARG\"" >> "$DEVFILE"
		verbout "Adding ${DIRECTIVE}=$ARG to ifcfg-$DEVICE"
	fi
}

setip () {
	verbout "Changing the IP address on $DEVICE"
	ifconfig "$DEVICE" "$IP"
	editifcfg "IPADDR" "$IP"
}

setnetmask () {
	verbout "Changing the network mask on $DEVICE"
	ifconfig "$DEVICE" netmask "$NETMASK"
	editifcfg "NETMASK" "$NETMASK"
}

setgateway () {
	verbout "Changing the default gateway on $DEVICE"
	#route add default gw "$GATEWAY"
	editifcfg "GATEWAY" "$GATEWAY"
}

setnameserver () {
	verbout "Changing the nameserver on $DEVICE"
	local FILE="/etc/resolv.conf"
	local OLD=$(grep 'nameserver' "$FILE")
	local NEW="nameserver $NSADDR"
	sedreplace "$OLD" "$NEW" "$FILE"
	editifcfg "DNS1" "$NSADDR"
}

main () {
	if [[ -z ${ARGS[0]} ]]
	then
		errormessage "Device argument expected"
		syntax
	fi

	DEVICE=${ARGS[0]}
	DEVFILE="/etc/sysconfig/network-scripts/ifcfg-$DEVICE"


	#Comment this if statement out if interface eth0 is to be changed
	#Added so a VM couldn't be accidentally disconnected
	if [[ "$DEVICE" = "eth0" ]]
	then
		errormessage "Changes to eth0 are disabled by this statement in the code to prevent\nan accidental disconnect of the VM that this code was written on\n\nTo change this, comment out this section of the code"
		cleanup
	fi



	ifconfig "$DEVICE" &> /dev/null
	if [[ "$?" = 1 ]]; then
		errormessage "Interface not found"
		cleanup
	elif [[ ! -f "$DEVFILE" ]]; then
		#File needs to be created
		echo "DEVICE=\"$DEVICE\"" > "$DEVFILE"
		echo 'BOOTPROTO="none"' >> "$DEVFILE"
		echo 'IPV6INIT="yes"' >> "$DEVFILE"
		echo 'MTU="1500"' >> "$DEVFILE"
		echo 'NM_CONTROLLED="yes"' >> "$DEVFILE"
		echo 'ONBOOT="yes"' >> "$DEVFILE"
		echo 'TYPE="Ethernet"' >> "$DEVFILE"
		echo 'PEERDNS="no"' >> "$DEVFILE"

		verbout "Creating $DEVFILE:"
		verbout "$(cat $DEVFILE)"
	fi

	if [[ $INTERACTIVE = "ON" ]]
	then
		message "Welcome to the Network Configuration Wizard for $DEVICE"
		message "(Leave fields blank to skip)\n"
		
		#Get IP address
		message "Please enter a new IP address: "
		read IP

		#Get Network Mask
		message "Please enter a new Network Mask: "
		read NETMASK

		#Get the Default Gateway
		message "Please enter a new Default Gateway:"
		read GATEWAY

		#Get the Nameserver (DNS)
		message "Please enter a new Nameserver: "
		read NSADDR
	fi

	verbout "Here is the info you input:"
	verbout "IP address:            $IP"
	verbout "Network Mask:          $NETMASK"
	verbout "Default Gateway:       $GATEWAY"
	verbout "Nameserver:            $NSADDR\n"

	#verify input (to do?)

	#Set the values
	if [[ ! -z "$IP" ]]; then
		setip
	fi
	if [[ ! -z "$NETMASK" ]]; then
		setnetmask
	fi
	if [[ ! -z "$GATEWAY" ]]; then
		setgateway
	fi
	if [[ ! -z "$NSADDR" ]]; then
		setnameserver
	fi
}




#getopts
while getopts :xvhi:m:g:n: opt; do
	case $opt in
		#Debug
		x)	DEBUG="ON"
			set -x;;
		#Verbose
		v)	VERBOSE="ON";;

		#Help
		h)	syntax
			cleanup;;

		#IP
		i)	INTERACTIVE="OFF"
			IP="$OPTARG";;

		#Network Mask
		m)	INTERACTIVE="OFF"
			NETMASK="$OPTARG";;

		#Default Gateway
		g)	INTERACTIVE="OFF"
			GATEWAY="$OPTARG";;

		#Nameserver Address
		n)	INTERACTIVE="OFF"
			NSADDR="$OPTARG";;

		#Other
		\?)	errormessage "Unknown option"
			syntax
			cleanup 1;;
	esac
done
shift $(($OPTIND-1))


DEVICE=""

setup "$@"
main
cleanup

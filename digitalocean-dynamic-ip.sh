#!/bin/bash

# Version: 1.1.1
# Date: 2024/02/29
# Author: Steve Talley (Dusty Sun) <steve@dustysun.com>

# Requirements: Python and doctl package.

# Ubuntu:
# snap install doctl
usage=$(cat <<"EOF"
Usage:
    ./doctl-updatedns.sh [--help] --record=<record_set_name>
                        [--ttl=<ttl_seconds>] [--type=<record_type>]
                        --zone=<zone_id>
Update a Digital Ocean record with your external IP address. A log file is created in the same directory as this script.

OPTIONS
    --help
        Show this output

    --domain=<domain_name>
        The name of the domain where the A record lives that will be updated.

    --hostname=<record_set>
        The name of the hostname set to update without the domain.

    --accesstoken=<docker_api_key>
        Provide your docker API key here.

    --email=<email_address>
        Optional: Enter an email where the log will be delivered. If no email is provided, the script will not attempt to send an email.
    
    --doctlpath=<path_to_doctl>
        Optional: Enter the path where the doctl command is on your system. It defaults to /snap/bin.

EOF
)

SHOW_HELP=0
DOMAIN=""
HOSTNAME=""
ACCESSTOKEN=""
EMAIL=""
DOCTL_PATH="/snap/bin"

# Get current dir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGFILE="$DIR/digitalocean-dynamic-ip.log"

while [ $# -gt 0 ]; do
    case "$1" in
        --help)
            SHOW_HELP=1
            ;;
        --domain=*)
            DOMAIN="${1#*=}"
            ;;
        --hostname=*)
            HOSTNAME="${1#*=}"
            ;;
        --accesstoken=*)
            ACCESSTOKEN="${1#*=}"
            ;;
        --email=*)
            EMAIL="${1#*=}"
            ;;
        --doctlpath=*)
            DOCTL_PATH="${1#*=}"
            ;;
        *)
            SHOW_HELP=1
    esac
    shift
done

if [  -z "$DOMAIN" -o -z "$HOSTNAME" -o -z "$ACCESSTOKEN" ]; then
    SHOW_HELP=1
fi

if [ $SHOW_HELP -eq 1 ]; then
    echo "$usage"
    exit 0
fi

# Start logfile or continue 
echo '================================' >> "$LOGFILE"
echo $(date) >> "$LOGFILE"

# get the current ip
${DOCTL_PATH}/doctl --access-token ${ACCESSTOKEN} compute domain records list ${DOMAIN} --output json > /tmp/digitalocean.json

echo "import json" > /tmp/digitalocean.py
echo "import sys" >> /tmp/digitalocean.py
echo "from pprint import pprint" >> /tmp/digitalocean.py
echo "jdata = sys.stdin.read()" >> /tmp/digitalocean.py
echo "jsonObject = json.loads(jdata)" >> /tmp/digitalocean.py
echo "for x in jsonObject:" >> /tmp/digitalocean.py
echo "    if x[\"name\"]=='${HOSTNAME}':" >> /tmp/digitalocean.py
echo "        print(\"{}|{}\".format(x[\"data\"],x[\"id\"]))" >> /tmp/digitalocean.py

DIGITALOCEAN_INFO=`cat /tmp/digitalocean.json | python3 /tmp/digitalocean.py`

DIGITALOCEAN_IP=`echo $DIGITALOCEAN_INFO |cut -d '|' -f1`
DIGITALOCEAN_ID=`echo $DIGITALOCEAN_INFO |cut -d"|" -f2`

echo Digital Ocean Record ID: ${DIGITALOCEAN_ID} >> "$LOGFILE"
echo Digital Ocean Original IP: ${DIGITALOCEAN_IP} >> "$LOGFILE"
# Get the external IP address from OpenDNS (more reliable than other providers)
IP=`dig +short myip.opendns.com @resolver1.opendns.com`

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

if ! valid_ip $DIGITALOCEAN_IP; then
    echo "Unable to obtain valid IP address from Digital Ocean: $DIGITALOCEAN_IP" >> "$LOGFILE"
    exit 1
fi

if ! valid_ip $IP; then
    echo "Invalid IP address: $IP" >> "$LOGFILE"
    exit 1
fi

#compare local IP to dns record
if [ "$IP" ==  "$DIGITALOCEAN_IP" ]; then
    # code if found
    echo "IP for ${HOSTNAME}.${DOMAIN} is still $IP. No change was made to the record." >> "$LOGFILE"
    exit 0
else
    echo "IP has changed to $IP. Updating Digital Ocean record." >> "$LOGFILE"
    #update the IP record
    ${DOCTL_PATH}/doctl --access-token ${ACCESSTOKEN} compute domain records update ${DOMAIN} --record-name ${HOSTNAME} --record-data ${IP} --record-id ${DIGITALOCEAN_ID} --output json >> "$LOGFILE"
fi

if [ ! -z "$EMAIL" ]; then
    cat $LOGFILE | /usr/bin/mail -s "DOCTL: IP Address Update" -a "From: ${EMAIL}" $EMAIL 
fi

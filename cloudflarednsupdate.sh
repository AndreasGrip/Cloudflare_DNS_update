#!/bin/bash

CLOUDFLAREEMAIL="example@gmail.com"
CLOUDFLAREGLOBALKEY=""
DOMAINTOUPDATE="www.example.org"

# Check for ping
if ! which ping >/dev/null 2>&1; then
    echo "ping is not installed"
    exit 1
fi
# Check for jq
if ! which curl >/dev/null 2>&1; then
    echo "curl is not installed"
    exit 1
fi
# Check for jq
if ! which jq >/dev/null 2>&1; then
    echo "jq is not installed"
    exit 1
fi

DOMAINNAME=$(echo $DOMAINTOUPDATE | sed s/\.[0-9a-zA-Z\-]*\.[a-zA-Z]*$//g)
if [[ "$DOMAINNAME" == "" ]] ; then
        DOMAINNAME="$DOMAINTOUPDATE"
fi

# echo "DOMAINNAME: $DOMAINNAME"
DOMAINIP=$(ping -c 1 "$DOMAINTOUPDATE" | grep -oP '(\d{1,3}\.){3}\d{1,3}' | head -n 1)
#echo "DOMAINIP: $DOMAINIP"
MYIP=$(curl -Ss https://api.ipify.org)
#echo "MYIP: $MYIP"

if [[ "$DOMAINIP" == "$MYIP" ]] ; then
	echo "No update needed"
	exit 0
fi

exit 0

ZONE=$(curl -Ss --request GET --url https://api.cloudflare.com/client/v4/zones/ --header 'Content-Type: application/json' --header "X-Auth-Email: $CLOUDFLAREEMAIL" --header "X-Auth-Key: $CLOUDFLAREGLOBALKEY" | jq -r '.result[0].id')
# echo "Zone: $ZONE" 
DNSRECORDID=$(curl -Ss "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records/" --header 'Content-Type: application/json' --header "X-Auth-Email: $CLOUDFLAREEMAIL" --header "X-Auth-Key: $CLOUDFLAREGLOBALKEY" | jq -r --arg DOMAINTOUPDATE "$DOMAINTOUPDATE" '.result | map(select(.type == "A" and .name == $DOMAINTOUPDATE)) | .[].id')
# echo "DNSRECORDID: $DNSRECORDID"

DATA="{\"content\": \"$MYIP\",\"name\": \"$DOMAINNAME\",\"proxied\": false,\"type\": \"A\",\"ttl\": 600,\"id\": \"$DNSRECORDID\"}"
# echo "DATA $DATA"

SUCCESS=$(curl -sS -X PUT  --url https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records/$DNSRECORDID --header 'Content-Type: application/json' --header "X-Auth-Email: $CLOUDFLAREEMAIL" --header "X-Auth-Key: $CLOUDFLAREGLOBALKEY" -d "$DATA" | jq .success)
if "$SUCCESS" == "true" ; then 
	echo "Success"
	exit 0
else 
	echo "Failed"
	exit 1
fi
exit 0

#!/bin/bash

CLOUDFLAREEMAIL="example@gmail.com"
CLOUDFLAREGLOBALKEY=""
DOMAINTOUPDATE="www.example.org"

# Check for required tools
for tool in ping curl jq; do
    if ! which "$tool" >/dev/null 2>&1; then
        echo "$tool is not installed"
        exit 1
    fi
done

DOMAINNAME=$(echo $DOMAINTOUPDATE | sed s/\.[0-9a-zA-Z\-]*\.[a-zA-Z]*$//g)
if [[ "$DOMAINNAME" == "" ]] ; then
        DOMAINNAME="$DOMAINTOUPDATE"
fi

if [[ "$1" == "debug" ]] ; then 
    echo "DOMAINNAME: $DOMAINNAME"
fi

DOMAIN=$(echo $DOMAINTOUPDATE | sed 's/^[^.]*\.//')

if [[ "$1" == "debug" ]] ; then 
    echo "DOMAIN: $DOMAIN"
fi

DOMAINIP=$(ping -c 1 "$DOMAINTOUPDATE" | grep -oP '(\d{1,3}\.){3}\d{1,3}' | head -n 1)

if [[ "$1" == "debug" ]] ; then 
    echo "DOMAINIP: $DOMAINIP"
fi

MYIP=$(curl -Ss https://api.ipify.org)

if [[ "$1" == "debug" ]] ; then 
    echo "MYIP: $MYIP"
fi

if [[ "$DOMAINIP" == "$MYIP" ]] ; then
	echo "No update needed"
	exit 0
fi

ZONE=$(curl -Ss --request GET \
                    --url https://api.cloudflare.com/client/v4/zones/ \
                    --header 'Content-Type: application/json' \
                    --header "X-Auth-Email: $CLOUDFLAREEMAIL" \
                    --header "X-Auth-Key: $CLOUDFLAREGLOBALKEY" \
                    | jq -r ".result[] | select(.name == \"$DOMAIN\") | .id")

if [[ "$1" == "debug" ]] ; then 
    echo "Zone: $ZONE" 
fi

if [[ "$ZONE" == "" ]] ; then 
    echo "Failed to get zone for $DOMAIN"
    exit 1
fi

DNSRECORDID=$(curl -Ss "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records/" \
                    --header 'Content-Type: application/json' \
                    --header "X-Auth-Email: $CLOUDFLAREEMAIL" \
                    --header "X-Auth-Key: $CLOUDFLAREGLOBALKEY" \
                    | jq -r --arg DOMAINTOUPDATE "$DOMAINTOUPDATE" \
                    '.result | map(select(.type == "A" and .name == $DOMAINTOUPDATE)) | .[].id')

if [[ "$1" == "debug" ]] ; then 
    echo "DNSRECORDID: $DNSRECORDID"
fi

DATA="{\"content\": \"$MYIP\",\"name\": \"$DOMAINNAME\",\"proxied\": false,\"type\": \"A\",\"ttl\": 600,\"id\": \"$DNSRECORDID\"}"

if [[ "$1" == "debug" ]] ; then 
    echo "DATA $DATA"
fi

SUCCESS=$(curl -sS -X PUT  --url https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records/$DNSRECORDID \
                    --header 'Content-Type: application/json' \
                    --header "X-Auth-Email: $CLOUDFLAREEMAIL" \
                    --header "X-Auth-Key: $CLOUDFLAREGLOBALKEY" \
                    -d "$DATA" \
                    | jq .success)
if "$SUCCESS" == "true" ; then 
	echo "Success"
	exit 0
else 
	echo "Failed"
	exit 1
fi
exit 0

# Cloudflare_DNS_update  
Bought domain on cloudflare, now want a crontab top update it?  
  
SHAME on you cloudflare for not providing it!!  
  
The script needs ping, curl, and jq. Make sure they are installed.
  
Download the file, keep it somewhere, like a bin folder in your home directory. Then update it.  
  
You can find your global key on  
https://dash.cloudflare.com/profile/api-tokens  
  
You need to uppdate the following  
  
CLOUDFLAREEMAIL=  
CLOUDFLAREGLOBALKEY=  
DOMAINTOUPDATE=  
  
After this you can create a crontab to update for instance every 5th minute.  
*/5 * * * * /home/username/bin/cloudflare  

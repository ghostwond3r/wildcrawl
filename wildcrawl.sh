#!/bin/bash
export RED=$(tput setaf 1 :-"" 2>/dev/null)
export GREEN=$(tput setaf 2 :-"" 2>/dev/null)
export BLUE=$(tput setaf 3 :-"" 2>/dev/null)
export RESET=$(tput sgr0 :-"" 2>/dev/null)


# base directory output
output_base_dir="/home/scan"

if [ ! -d "$output_base_dir" ]; then
  mkdir "$output_base_dir"
fi

extract_domain() {
  local url=$1
  local domain
  domain=$(echo "$url" | awk -F[/:] '{print $4}')
  echo "$domain"
}

echo -e "\n $BLUE ____+_________________________/\___________________+______+____/\____" $RESET
echo -e " $BLUE ____+_______WELCOME_______+____________/\_________+_____/\___________" $RESET
echo -e " $BLUE __/\____+____________+_______TO_______________________+______/\______" $RESET
echo -e " $BLUE ___________+_____________/\________+_____WILDCRAWL_______/\__+_______" $RESET
echo -e " $BLUE ___+___________/\______________/\______________+__________/\___________\n\n" $RESET


echo -e "[x] Enter the URL to scan:"
read URL
domain=$(extract_domain "$URL")
counter=1
dir_name="$domain"
fod="${output_base_dir}/${dir_name}"

while [ -d "$fod" ]; do
  ((counter++))
  dir_name="${domain}_${counter}"
  fod="${output_base_dir}/${dir_name}"
done

mkdir "$fod"
cd "$fod"
echo "$URL" | hakrawler >> "${fod}/crawl.txt"

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Crawling the target URL.. $RESET

# extract all links
grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" "${fod}/crawl.txt" > "${fod}/urls.txt"

# remove duplicate
sort "${fod}/urls.txt" | uniq > "${fod}/unique_urls.txt"

# Extract all files and separate them from the test
touch "${fod}/files.txt"

for ext in js txt pdf xlsx doc docx csv zip jpg png rar apk; do
  grep -o "http.*\.$ext" "${fod}/unique_urls.txt" >> "${fod}/files.txt"
  sed -i "/\.$ext\b/d" "${fod}/unique_urls.txt"
done

echo -e "\n=======================" >> "${fod}/results.txt"
echo -e " == WILDCRAWL REPORT ==                    " >> "${fod}/results.txt"
echo -e "========================\n\n" >> "${fod}/results.txt"

echo -e "\n\n==================================================================" >> "${fod}/results.txt"
echo -e "   [x] UNIQUE URLs" >> "${fod}/results.txt"
echo -e "==================================================================\n" >> "${fod}/results.txt"
echo -e "$(cat "${fod}/unique_urls.txt")" >> "${fod}/results.txt"


echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracted files saved in files.txt.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Sorting domains and removing duplicate.. $RESET

touch "${fod}/domains.txt"

# Extract all domains, remove duplicates, and sort them
cat "${fod}/unique_urls.txt" | awk -F/ '{print $3}' | sort -u >> "${fod}/domains.txt"

grep -iEv 'wikipedia|waze|goo\.gl|wa\.me|tiktok|theme|unpkg|ups|UPS|vimeo|.*godaddy.*|.*akamaiedge\.net.*|pinterest|wechat|vk\.com|studiopress|whatsapp|trustseal\.enamad\.ir|akamai|icao\.int|bit\.ly|aparat\.com|jquery|android|euronews|forbes|foreignaffairs|france24|huffingtonpost|economist|theguardian|dailytimes|washingtonpost|theglobeandmail|creativecommons|foreignpolicy|reuters|maxcdn|thefrontierpost|theintercept|weibo|wordpress|aljazeera|amnesty|bloomberg|bbc|cnn|dailymail|businessinsider|facebook|meta|messenger|fbcdn|bulletin|googletagmanager|oculus|twitter|youtube|instagram|google|apple|microsoft|twimg|telegram|t\.me|cloudflare|jsdelivr|youtu|linkedin' "${fod}/domains.txt" > "${fod}/filtered_domains.txt"

echo -e "\n==================================================================" >> "${fod}/results.txt"
echo -e "   [x] DOMAINS LIST" >> "${fod}/results.txt"
echo -e "==================================================================\n" >> "${fod}/results.txt"
echo -e "$(cat "${fod}/filtered_domains.txt")" >> "${fod}/results.txt"

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracting records of domains.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

echo -e "\n==================================================================" >> "${fod}/results.txt"
echo -e "   [x] DOMAINS RECORDS" >> "${fod}/results.txt"
echo -e "==================================================================\n" >> "${fod}/results.txt"

domains_file="${fod}/filtered_domains.txt"
output_file="${fod}/results.txt"

while read domain; do
    echo -e "$BLUE Performing dig lookup for ${domain}..." $RESET
    dig_output="$(dig ${domain} +nocmd +nocomments +nostats)"
    echo "${dig_output}"
    echo "${dig_output}" >> "${output_file}"
done < "${domains_file}"

# extract DNS from certificates
domains_file="${fod}/filtered_domains.txt"
output_file="${fod}/results.txt"

while read domain; do
    echo -e "$BLUE DNS for ${domain}..." $RESET
    openssl s_client -connect "${domain}":443 | openssl x509 -text | grep "DNS:" | tee -a "${output_file}"
done < "${domains_file}"

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Retrieving IPs.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

echo -e "\n==================================================================" >> "${fod}/results.txt"
echo -e "   [x] IP ALIVE (without cloudflare)" >> "${fod}/results.txt"
echo -e "==================================================================\n" >> "${fod}/results.txt"

# get all ips
getips -v -d "${fod}/filtered_domains.txt" -o "${fod}/ips.txt"
grep -vE "^172\.|^104\." "${fod}/ips.txt" | sed '/^[[:space:]]*$/d' > "${fod}/filtered_ips.txt"
echo -e "$(cat "${fod}/filtered_ips.txt")" >> "${fod}/results.txt"

touch "${fod}/https_domains.txt" "${fod}/http_ips.txt"

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracting link from each website.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

while read domain; do
  echo "https://$domain" >> "${fod}/https_domains.txt"
done < "${fod}/filtered_domains.txt"

echo -e "\n==================================================================" >> "${fod}/results.txt"
echo -e "   [x] LINKS EXTRACTED" >> "${fod}/results.txt"
echo -e "==================================================================\n" >> "${fod}/results.txt"

# Extracting links
while read url; do
    echo -e "\n $BLUE [x] Extract from: $url\n" $RESET | tee -a "${fod}/results.txt"
    lynx -listonly -dump -unique_urls -nonumbers -force_secure -connect_timeout=15 -read_timeout=15 "$url" | tee -a "${fod}/results.txt"
done < "${fod}/https_domains.txt"

while read ip; do
  echo "http://$ip" >> "${fod}/http_ips.txt"
done < "${fod}/filtered_ips.txt"

# Extracting links
while read url; do
    echo -e "\n $BLUE [x] Extract from: $url\n" $RESET | tee -a "${fod}/results.txt"
    lynx -listonly -dump -unique_urls -nonumbers -force_secure -connect_timeout=15 -read_timeout=15 "$url" | tee -a "${fod}/results.txt"
done < "${fod}/http_ips.txt"

for ext in js txt pdf xlsx doc docx csv zip jpg png rar apk; do
  grep -o "http.*\.$ext" "${fod}/results.txt" >> "${fod}/files.txt"
  sed -i "/\.$ext\b/d" "${fod}/results.txt"
done

echo -e "\n==================================================================" >> "${fod}/results.txt"
echo -e "   [x] FILES" >> "${fod}/results.txt"
echo -e "==================================================================\n" >> "${fod}/results.txt"

echo -e "$(cat "${fod}/files.txt")" >> "${fod}/results.txt"

rm -f "${fod}/urls.txt" "${fod}/https_domains.txt" "${fod}/http_ips.txt" "${fod}/domains.txt" 
mv "${fod}/filtered_domains.txt" "${fod}/domains.txt"
mv "${fod}/filtered_ips.txt" "${fod}/ips.txt"

echo -e "\n==================================================================" >> "${fod}/results.txt"
echo -e "   [x] EMAILS RETRIEVED" >> "${fod}/results.txt"
echo -e "==================================================================\n" >> "${fod}/results.txt"

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Searching server banner and emails.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

while read -r domain; do
  echo -e "\n $BLUE [x] Domain: $domain\n" $RESET | tee -a "${fod}/results.txt"
  wget -q -T 4 --connect-timeout=5 --read-timeout=4 --no-check-certificate -O - "https://$domain" | grep -E -o "\b[a-zA-Z0-9.-]+@[a-zA-Z0-9.-]+\.[a-zA-Z0-9.-]+\b" | tee -a "${fod}/results.txt"
done < "${fod}/domains.txt"

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Saving possible injection point.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

grep "?" "${fod}/unique_urls.txt" > "${fod}/injection_point.txt"

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Retrieving banner.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

echo -e "\n==================================================================" >> "${fod}/results.txt"
echo -e "   [x] SERVER BANNER" >> "${fod}/results.txt"
echo -e "==================================================================\n" >> "${fod}/results.txt"

touch "${fod}/temp_banner.txt" 
    
while read -r domain; do
  echo -e "\n $BLUE [x] $domain\n" $RESET | tee -a "${fod}/temp_banner.txt"
    echo -ne "HEAD / HTTP/1.1\r\nHost: $domain \r\nConnection: close\r\n\r\n" | nc $domain 80 -w 5 -i 2 | tee -a "${fod}/temp_banner.txt"
done < "${fod}/domains.txt"

echo -e "$(cat "${fod}/temp_banner.txt")" >> "${fod}/results.txt"

grep -Eio "(https?://)?(www\.)?(twitter\.com|facebook\.com|instagram\.com|youtube\.com|t\.me)[^\"']*" results.txt | tee social_links.txt | xargs -I {} sed -i "\#{}#d" results.txt

uniq results.txt report.txt
rm -f results.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

while true; do
  # Show menu options
  echo -e "$RED Vulnerability detection:" $RESET
  echo $BLUE; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
  echo -e "$GREEN [1] Injection" $RESET
  echo -e "$GREEN [2] HTTP Enum" $RESET
  echo -e "$GREEN [3] Port Scan" $RESET
  echo -e "$GREEN [4] Fuzzing" $RESET
  echo -e "$GREEN [5] Nikto" $RESET
  echo -e "$GREEN [6] Access Control" $RESET
  echo -e "$GREEN [7] Exit" $RESET

  # Ask user for choice
  read -p "Enter your choice (1-7): " choice

  # Handle the choice
  case $choice in
    1)
      while read -r url; do
        echo "Testing forms on URLs using SQLmap..."
        sqlmap -v $url --batch --skip-static --level=5 --risk=3 --random-agent | tee -a "${fod}/sqlmap.txt"
      done < "${fod}/injection_point.txt"

      echo -e "\n==================================================================" >> "${fod}/report.txt"
      echo -e "   [x] SQLMAP" >> "${fod}/report.txt"
      echo -e "==================================================================\n" >> "${fod}/report.txt"
      echo -e "$(cat "${fod}/sqlmap.txt")" >> "${fod}/report.txt"
      ;;
    2)
      while read -r ip; do
        echo -e "\n[x] Scanning IP: $ip\n"
        nmap -Pn -T4 --script=http-enum --script-args={maxpagecount=50,maxchildren=10,maxdepth=3,maxtime=30} $ip| tee -a "${fod}/HTTP_enum.txt"
      done < "${fod}/ips.txt"

      echo -e "\n==================================================================" >> "${fod}/report.txt"
      echo -e "   [x] HTTP-enum" >> "${fod}/report.txt"
      echo -e "==================================================================\n" >> "${fod}/report.txt"
      echo -e "$(cat "${fod}/HTTP_enum.txt")" >> "${fod}/report.txt"
      ;;
    3)
      while read -r ip; do
        echo -e "\n[x] Scanning IP: $ip\n"
        open_ports=$(nmap -Pn -p 21,22,23,25,53,80,443,445,502,2000,2404,2405,3000,3006,3389,4911,5432,8000,8080,20000,44818 --open $ip | awk '/^ *[0-9]+\/(tcp|udp)/ {print $1}' | tee -a paste -sd "," -) | "${fod}/port.txt"
        if [[ -n "$open_ports" ]]; then
          echo "$ip: $open_ports"
        fi
      done < "${fod}/ips.txt"

      echo -e "\n==================================================================" >> "${fod}/report.txt"
      echo -e "   [x] Open Ports" >> "${fod}/report.txt"
      echo -e "==================================================================\n" >> "${fod}/report.txt"
      echo -e "$(cat "${fod}/port.txt")" >> "${fod}/report.txt"
      ;;
    4)      
      while read -r domain; do
        echo -e "\n[x] Scanning: $domain\n"
        ffuf -w /usr/share/wordlists/dirb/common.txt -u https://$domain/FUZZ -e .php,.html | tee -a "${fod}/ffuf.txt"
      done < "${fod}/domains.txt"
      
      echo -e "\n==================================================================" >> "${fod}/report.txt"
      echo -e "   [x] Fuzzing" >> "${fod}/report.txt"
      echo -e "==================================================================\n" >> "${fod}/report.txt"
      cat "${fod}/ffuf.txt" >> "${fod}/report.txt"
      ;;
    5)
      echo -e "\n==================================================================" >> "${fod}/report.txt"
      echo -e "   [x] Nikto" >> "${fod}/report.txt"
      echo -e "==================================================================\n" >> "${fod}/report.txt"

        while read -r domain; do
          echo -e "\n[+] Scanning ${domain}\n"
          nikto -h "${domain}" -o "${fod}/nikto.txt"
          cat "${fod}/nikto.txt" | tee -a "${fod}/report.txt"
        done < "${fod}/domains.txt"
      ;;
    6)
      echo -e "\n==================================================================" >> "${fod}/report.txt"
      echo -e "   [x] Access Control" >> "${fod}/report.txt"
      echo -e "==================================================================\n" >> "${fod}/report.txt"

        while read -r domain; do
          echo -e "\n[+] Scanning ${domain}\n"
                nmap -p 80,443 --script=http-auth,http-enum,http-vuln-cve2017-8917,http-vuln-cve2017-1001000,http-methods "${domain}" -oN "${fod}/nmap_access_control.txt"
                    cat "${fod}/nmap_access_control.txt" | tee -a "${fod}/report.txt"
        done < "${fod}/domains.txt"
      ;;
    7)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid choice, please enter a number from 1-7."
      ;;
  esac
done

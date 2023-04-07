#!/bin/bash
export RED=$(tput setaf 1 :-"" 2>/dev/null)
export GREEN=$(tput setaf 2 :-"" 2>/dev/null)
export BLUE=$(tput setaf 3 :-"" 2>/dev/null)
export RESET=$(tput sgr0 :-"" 2>/dev/null)

i=1
while [ -d "scan_$i" ]; do
  ((i++))
done

mkdir "scan_$i"
cd "scan_$i"

echo -e "$GREEN ++++++++++++++++++++++++++++++" $RESET
echo -e "   Welcome to WildCrawl"
echo -e "$GREEN  ++++++++++++++++++++++++++++++\n" $RESET

echo -e "[x] Enter the URL to scan:" 

read URL

echo "$URL" | hakrawler >> crawl.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Crawling the target URL.. $RESET

# extract all links
grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" crawl.txt > urls.txt

# remove duplicate
sort urls.txt | uniq > unique_urls.txt

# Extract all files and separate them from the test
touch files.txt

for ext in js txt pdf xlsx doc docx csv zip jpg png rar apk; do
  grep -o "http.*\.$ext" unique_urls.txt >> files.txt
  sed -i "/\.$ext\b/d" unique_urls.txt
done

echo  -e "\n=====================================================" >> results.txt
echo -e "# UNIQUE URLs" >> results.txt
echo  -e "=====================================================\n" >> results.txt
echo -e "$(cat unique_urls.txt)" >> results.txt


echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracted files and saved them in files.txt.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Sorting domains and removing duplicate.. $RESET

touch domains.txt

# Extract all domains, remove duplicates, and sort them
cat unique_urls.txt | awk -F/ '{print $3}' | sort -u >> domains.txt

grep -Ev 'wikipedia|waze|goo\.gl|tiktok|akamai|icao\.int|bit\.ly|aparat\.com|jquery|android|euronews|forbes|foreignaffairs|france24|huffingtonpost|economist|theguardian|dailytimes|washingtonpost|theglobeandmail|creativecommons|foreignpolicy|reuters|maxcdn|thefrontierpost|theintercept|weibo|wordpress|aljazeera|amnesty|bloomberg|bbc|cnn|dailymail|businessinsider|facebook|meta|messenger|fbcdn|bulletin|googletagmanager|oculus|twitter|youtube|instagram|google|apple|microsoft|twimg|telegram|t\.me|cloudflare|jsdelivr|youtu|linkedin' domains.txt > filtered_domains.txt

echo  -e "\n=====================================================" >> results.txt
echo -e "# DOMAINS LIST" >> results.txt
echo  -e "=====================================================\n" >> results.txt
echo -e "$(cat filtered_domains.txt)" >> results.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracting records of domains.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

echo  -e "\n=====================================================" >> results.txt
echo  -e "# DOMAINS RECORDS" >> results.txt
echo  -e "=====================================================\n" >> results.txt

domains_file="filtered_domains.txt"
output_file="results.txt"

while read domain; do
    echo -e "$BLUE Performing dig lookup for ${domain}..." $RESET
    dig_output="$(dig ${domain} +nocmd +nocomments +nostats)"
    echo "${dig_output}"
    echo "${dig_output}" >> "${output_file}"
done < "${domains_file}"

# extract DNS from certificates
domains_file="filtered_domains.txt"
output_file="results.txt"

while read domain; do
    echo -e "$BLUE DNS for ${domain}..." $RESET
    openssl s_client -connect "${domain}":443 | openssl x509 -text | grep "DNS:" | tee -a "${output_file}"
done < "${domains_file}"

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Retrieving IPs.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

echo  -e "\n=====================================================" >> results.txt
echo -e "# IP ALIVE" >> results.txt
echo  -e "=====================================================\n" >> results.txt

# get all ips
getips -v -d filtered_domains.txt -o ips.txt

grep -vE "^172\.|^104\." ips.txt | sed '/^[[:space:]]*$/d' > filtered_ips.txt

echo -e "$(cat filtered_ips.txt)" >> results.txt

touch https_domains.txt http_ips.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracting link from each website.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

while read domain; do
  echo "https://$domain" >> https_domains.txt
done < filtered_domains.txt

echo  -e "\n=====================================================" >> results.txt
echo -e "# LINKS EXTRACTED" >> results.txt
echo  -e "=====================================================\n" >> results.txt

# Extracting links
while read url; do
    echo -e "\n $BLUE [x] Extract from: $url\n" $RESET | tee -a results.txt
    lynx -listonly -dump -unique_urls -nonumbers -force_secure -connect_timeout=15 -read_timeout=15 "$url" | tee -a results.txt
done < https_domains.txt

while read ip; do
  echo "http://$ip" >> http_ips.txt
done < filtered_ips.txt

# Extracting links
while read url; do
    echo -e "\n $BLUE [x] Extract from: $url\n" $RESET | tee -a results.txt
    lynx -listonly -dump -unique_urls -nonumbers -force_secure -connect_timeout=15 -read_timeout=15 "$url" | tee -a results.txt
done < http_ips.txt

for ext in js txt pdf xlsx doc docx csv zip jpg png rar apk; do
  grep -o "http.*\.$ext" results.txt >> files.txt
  sed -i "/\.$ext\b/d" results.txt
done

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracting title of domain.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

echo  -e "\n=====================================================" >> results.txt
echo -e "# DOMAIN TITLE" >> results.txt
echo  -e "=====================================================\n" >> results.txt

# Extract the title of all domains
while read url; do
  echo "[x] Extracting title from $url"
  title=$(curl -s "$url" --connect-timeout 5 | grep -oP '<title>\K[^<]*')
  echo "$url - $title" >> results.txt
  sleep 2
done < <(sort -u https_domains.txt)

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracting title of IP.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

echo  -e "\n=====================================================" >> results.txt
echo -e "# IP TITLE" >> results.txt
echo  -e "=====================================================\n" >> results.txt

# Extract the title of all IPs
while read url; do
  echo "[x] Extracting title from $url"
  title=$(curl -s "$url" --connect-timeout 5 | grep -oP '<title>\K[^<]*')
  echo "$url - $title" >> results.txt
  sleep 2
done < <(sort -u http_ips.txt)

while read line
do
    title=$(echo "$line" | cut -d' ' -f3-)
    if [[ $title != "404"* ]]; then
        echo "$line" >> filtered_results.txt
    fi
done < results.txt

mv filtered_results.txt final_result.txt
rm urls.txt results.txt https_domains.txt http_ips.txt domains.txt 
mv filtered_domains.txt domains.txt
mv filtered_ips.txt ips.txt

echo  -e "\n\n=====================================================" >> final_result.txt
echo -e "# EMAILS RETRIEVED" >> final_result.txt
echo  -e "=====================================================\n" >> final_result.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Searching server banner and emails.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

while read -r domain; do
  echo -e "\n $BLUE [x] Domain: $domain\n" $RESET | tee -a final_result.txt
  wget -q -T 5 --connect-timeout=10 --read-timeout=10 -S --no-check-certificate -O - "https://$domain" | grep -E -o "\b[a-zA-Z0-9.-]+@[a-zA-Z0-9.-]+\.[a-zA-Z0-9.-]+\b" | tee -a final_result.txt
done < domains.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Saving possible injection point.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

grep "?" unique_urls.txt > injection_point.txt

while true; do
  # Show menu options
  echo -e "$RED [x] Choose an option:" $RESET
  echo -e "$GREEN 1. Injection" $RESET
  echo -e "$GREEN 2. HTTP Enum" $RESET
  echo -e "$GREEN 3. Port Scan" $RESET
  echo -e "$GREEN 4. Exit" $RESET

  # Ask user for choice
  read -p "Enter your choice (1-3): " choice

  # Handle the choice
  case $choice in
    1)
      # Ask the user if they want to test injection points using SQLmap
      read -p "Would you like to test injection on URLs? [y/n] " sqlmap

      if [[ $sqlmap == [Yy]* ]]; then
        # Test injection points using SQLmap
        echo "Testing forms on URLs using SQLmap..."
        sqlmap -v -m  injection_point.txt --batch --skip-static --level=5 --risk=3 --random-agent | tee -a sqlmap.txt
      else
        echo "No forms testing performed."
      fi
      ;;
    2)
      # Ask the user if they want to run Nmap on the IP addresses extracted
      read -p "Would you like to attempt HTTP enumeration? [y/n] " nmap

      if [[ $nmap == [Yy]* ]]; then
        echo "Running scan..."
        nmap -Pn -T4 --script=http-enum,http-spider --script-args maxpagecount=50,maxchildren=10,maxdepth=3,maxtime=30 -iL ips.txt | tee HTTP_enum.txt
      else
        echo "No Nmap scan performed."
      fi
      ;;
    3)
      while read -r ip; do
        echo -e "\n[x] Scanning IP: $ip\n"
        open_ports=$(nmap -Pn -p 21,22,23,25,53,80,443,445,502,2000,2404,2405,3000,3006,3389,4911,5432,8000,8080,20000,44818 --open $ip | awk '/^ *[0-9]+\/(tcp|udp)/ {print $1}' | paste -sd "," -)
        if [[ -n "$open_ports" ]]; then
          echo "$ip: $open_ports"
        fi
      done < ips.txt
      ;;
    4)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid choice, please enter a number from 1-3."
      ;;
  esac
done

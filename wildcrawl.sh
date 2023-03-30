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
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

# extract all links
grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" crawl.txt > urls.txt

# remove duplicate
sort urls.txt | uniq > unique_urls.txt

# Extract all files and separate them from the test
touch files.txt

for ext in js txt pdf doc docx csv zip jpg png rar apk; do
  grep -o "http.*\.$ext" unique_urls.txt >> files.txt
  sed -i "/\.$ext\b/d" unique_urls.txt
done

echo  -e "\n=====================================================" >> results.txt
echo -e "# Unique URLs" >> results.txt
echo  -e "=====================================================\n" >> results.txt
echo -e "$(cat unique_urls.txt)" >> results.txt


echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracted files and saved them in files.txt.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Sorting domains and removing duplicate.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

touch domains.txt

# Extract all domains, remove duplicates, and sort them
cat unique_urls.txt | awk -F/ '{print $3}' | sort -u >> domains.txt

grep -Ev 'wikipedia|waze|goo\.gl|tiktok|icao\.int|bit\.ly|aparat\.com|jquery|android|euronews|forbes|foreignaffairs|france24|huffingtonpost|economist|theguardian|dailytimes|washingtonpost|theglobeandmail|creativecommons|foreignpolicy|reuters|maxcdn|thefrontierpost|theintercept|weibo|wordpress|aljazeera|amnesty|bloomberg|bbc|cnn|dailymail|businessinsider|facebook|meta|messenger|fbcdn|bulletin|googletagmanager|oculus|twitter|youtube|instagram|google|apple|microsoft|twimg|telegram|t\.me|cloudflare|jsdelivr|youtu|linkedin' domains.txt > filtered_domains.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracting records of domains.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

echo  -e "\n=====================================================" >> results.txt
echo  -e "# Domains records" >> results.txt
echo  -e "=====================================================\n" >> results.txt

domains_file="filtered_domains.txt"
output_file="results.txt"

while read domain; do
    echo -e "$BLUE Performing dig lookup for ${domain}..." $RESET
    dig_output="$(dig ${domain} +nocmd +nocomments +nostats)"
    echo "${dig_output}"
    echo "${dig_output}" >> "${output_file}"
done < "${domains_file}"

# get all ips
getips  -v -d filtered_domains.txt -o ips.txt

echo  -e "\n=====================================================" >> results.txt
echo -e "# Unique Domains" >> results.txt
echo  -e "=====================================================\n" >> results.txt
echo -e "$(cat filtered_domains.txt)" >> results.txt

echo  -e "\n=====================================================" >> results.txt
echo -e "# IPs Alive" >> results.txt
echo  -e "=====================================================\n" >> results.txt
echo -e "$(cat ips.txt)" >> results.txt

touch https_domains.txt http_ips.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracting link from each website.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

while read domain; do
  echo "https://$domain" >> https_domains.txt
done < filtered_domains.txt

echo  -e "\n=====================================================" >> results.txt
echo -e "# Links extracted from all domains" >> results.txt
echo  -e "=====================================================\n" >> results.txt

# Extracting links
while read url; do
    echo -e "\n $BLUE [x] Extract from: $url\n" $RESET | tee -a results.txt
    lynx -listonly -dump -unique_urls -connect_timeout=10 -read_timeout=15 "$url" | tee -a results.txt
done < https_domains.txt

while read ip; do
  echo "http://$ip" >> http_ips.txt
done < ips.txt

# Extracting links
while read url; do
    echo -e "\n $BLUE [x] Extract from: $url\n" $RESET | tee -a results.txt
    lynx -listonly -dump -unique_urls -connect_timeout=10 -read_timeout=15 "$url" | tee -a results.txt
done < http_ips.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracting title of domain.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

echo  -e "\n=====================================================" >> results.txt
echo -e "# Domain Title" >> results.txt
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
echo -e "# IP Title" >> results.txt
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

echo  -e "\n\n=====================================================" >> final_result.txt
echo -e "# Server infos and emails" >> final_result.txt
echo  -e "=====================================================\n" >> final_result.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Searching server banner and emails.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

while read -r domain; do
  echo -e "\n $BLUE [x] Domain: $domain\n" $RESET | tee -a final_result.txt
  wget -q -T 5 --connect-timeout=5 --read-timeout=5 -S --no-check-certificate -O - "https://$domain" | grep -E -o "\b[a-zA-Z0-9.-]+@[a-zA-Z0-9.-]+\.[a-zA-Z0-9.-]+\b" | tee -a final_result.txt
done < domains.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Saving possible injection point.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

grep "?" unique_urls.txt > injection_point.txt

while true; do
  # Show menu options
  echo -e "$RED [x] Choose an option:" $RESET
  echo -e "$GREEN 1. SQLmap" $RESET
  echo -e "$GREEN 2. Nmap" $RESET
  echo -e "$GREEN 3. Exit" $RESET

  # Ask user for choice
  read -p "Enter your choice (1-3): " choice

  # Handle the choice
  case $choice in
    1)
      # Ask the user if they want to test injection points using SQLmap
      read -p "Would you like to test injection on URLs using SQLmap? [y/n] " sqlmap

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
      read -p "Would you like to run Nmap on the IP addresses extracted? [y/n] " nmap

      if [[ $nmap == [Yy]* ]]; then
        # Run Nmap on the IP addresses extracted
        echo "Running Nmap on the IP addresses extracted..."
        nmap -vv -Pn -T4 --script vuln -iL ips.txt | tee -a nmap.txt
      else
        echo "No Nmap scan performed."
      fi
      ;;
    3)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid choice, please enter a number from 1-3."
      ;;
  esac
done

#!/bin/bash
export RED=$(tput setaf 1 :-"" 2>/dev/null)
export GREEN=$(tput setaf 2 :-"" 2>/dev/null)
export RESET=$(tput sgr0 :-"" 2>/dev/null)

i=1
while [ -d "scan_$i" ]; do
  ((i++))
done

mkdir "scan_$i"
cd "scan_$i"

echo -e "\n $RED [x] Target URL:" 

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

# Loop through each file extension
for ext in js txt pdf doc docx csv zip jpg png rar apk; do
  # Find all links in the unique_urls.txt file with the current extension and save them to files.txt
  grep -o "http.*\.$ext" unique_urls.txt >> files.txt

  # Remove all links with the current extension from the unique_urls.txt file
  sed -i "/\.$ext\b/d" unique_urls.txt
done

echo -e "\n# Unique URLs\n$(cat unique_urls.txt)" >> results.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracted files and saved them in files.txt.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Sorting domains and removing duplicate.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

touch domains.txt

# Extract all domains from the unique_urls.txt file, remove duplicates, and sort them
cat unique_urls.txt | awk -F/ '{print $3}' | sort -u >> domains.txt

grep -Ev 'wikipedia|jquery|android|euronews|forbes|foreignaffairs|france24|huffingtonpost|economist|theguardian|dailytimes|washingtonpost|theglobeandmail|creativecommons|foreignpolicy|reuters|maxcdn|thefrontierpost|theintercept|weibo|wordpress|aljazeera|amnesty|bloomberg|bbc|cnn|dailymail|businessinsider|facebook|meta|messenger|fbcdn|bulletin|googletagmanager|oculus|twitter|youtube|instagram|google|apple|microsoft|twimg|telegram|t\.me|cloudflare|jsdelivr|youtu|linkedin' domains.txt > filtered_domains.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracting records of domains.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

echo  -e "\n# Domains records\n" >> results.txt

domains_file="filtered_domains.txt"
output_file="results.txt"

# Loop through each domain
while read domain; do
    echo "Performing dig lookup for ${domain}..."
    dig_output="$(dig ${domain} +nocmd +nocomments +nostats)"
    echo "${dig_output}"
    echo "${dig_output}" >> "${output_file}"
done < "${domains_file}"

# get all ips
getips  -v -d filtered_domains.txt -o ips.txt

echo -e "\n# Unique Domains\n$(cat filtered_domains.txt)" >> results.txt

echo -e "\n# IPs Alive\n$(cat ips.txt)" >> results.txt

touch https_domains.txt http_ips.txt

# Read the domains.txt file, append "https://" to each line, and save the results to https_domains.txt
while read domain; do
  echo "https://$domain" >> https_domains.txt
done < filtered_domains.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracting link from each website.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

echo -e "\n# Links extracted\n" >> results.txt

# Extracting links
while read url; do
    # Run dirsearch on the domain and append the output to results.txt
    echo -e "\n $RED [x] Extracting link from $url...\n" $RESET
    lynx -listonly -dump -unique_urls -connect_timeout=10 "$url" | tee -a results.txt
done < https_domains.txt

# Read the ips.txt file, append "http://" to each line, and save the results to http_ips.txt
while read ip; do
  echo "http://$ip" >> http_ips.txt
done < ips.txt

# Extracting links
while read url; do
    # Run dirsearch on the domain and append the output to results.txt
    echo -e "\n $RED [x] Extracting link from $url...\n" $RESET
    lynx -listonly -dump -unique_urls -connect_timeout=10 "$url" | tee -a results.txt
done < http_ips.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Extracting title of domain.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

echo -e "\n# Domain Title\n" >> results.txt

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

echo -e "\n# IP Title\n" >> results.txt

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

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Saving injection point.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

grep "?" unique_urls.txt > injection_point.txt

echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $GREEN [x] Searching forms in URLs.. $RESET
echo $RED; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET

# Ask the user if they want to test injection points using SQLmap
read -p "Would you like to test forms on URLs using SQLmap? [y/n] " sqlmap

if [[ $sqlmap == [Yy]* ]]; then
  # Test injection points using SQLmap
  echo "Testing injection points using SQLmap..."
  sqlmap -v -m unique_urls.txt --forms --batch --skip-static --level=5 --risk=3 --random-agent | tee -a sqlmap.txt
else
  # Ask the user if they want to run Nmap on the IP addresses extracted
  read -p "Would you like to run Nmap on the IP addresses extracted? [y/n] " nmap

  if [[ $nmap == [Yy]* ]]; then
    # Run Nmap on the IP addresses extracted
    echo "Running Nmap on the IP addresses extracted..."
    nmap -vv -Pn -T4 --script vuln -iL ips.txt | tee -a nmap.txt
  else
    echo "Scan completed, see final_result.txt."

  fi
fi

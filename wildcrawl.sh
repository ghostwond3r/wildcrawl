#!/bin/bash
export RED=$(tput setaf 1 :-"" 2>/dev/null)
export GREEN=$(tput setaf 2 :-"" 2>/dev/null)
export RESET=$(tput sgr0 :-"" 2>/dev/null)

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

echo -e "\n# Unique URLs\n$(cat unique_urls.txt)" >> results.txt

# Extract all files and separate them from the test
touch files.txt

# Loop through each file extension
for ext in pdf doc docx csv zip jpg png rar apk; do
  # Find all links in the unique_urls.txt file with the current extension and save them to files.txt
  grep -o "http.*\.$ext" unique_urls.txt >> files.txt

  # Remove all links with the current extension from the unique_urls.txt file
  sed -i "/\.$ext\b/d" unique_urls.txt
done

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

# Read the ips.txt file, append "http://" to each line, and save the results to http_ips.txt
while read ip; do
  echo "http://$ip" >> http_ips.txt
done < ips.txt

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

echo $GREEN; printf -- "-%.0s" $(seq $(tput cols)); echo $RESET
echo $RED [x] Scan completed, see final_result.txt. $RESET

# WildCrawl

> Bash script that crawls a target URL to get a better image of what is tied to a website.

Here's a summary of what the script does:

- Crawls the target URL using Hakrawler .
- Removes duplicate links.
- Extracts all files of certain types (e.g., PDF, DOC, ZIP, JPG) and saves them to a separate file.
- Extracts all domains, removes duplicates, and saves them.
- Filters out certain domains (e.g., Facebook, Twitter, LinkedIn) and saves the remaining domains.
- Gets all the IPs associated with the filtered domains using the "getips" tool and saves them.
- Extracts the title of each domain and IP using curl and saves the results to a file.
- Filters out any results that have a title starting with "404" and saves the remaining results.

At the end you will have;
```
results.txt = All tests results including title of domains and IPs
domains.txt = domains filtered
ips.txt = IPs alive from the domains.txt
unique_urls.txt = The URLs crawled (duplicate and files removed)
files.txt = Files extracted during the crawl
```

*This script can be useful for reconnaissance and information gathering during a penetration testing engagement.*

## Installation and Usage
```
apt install hakrawler -y
pip3 install getips
git clone https://github.com/NeverWonderLand/wildcrawl.git
cd wildcrawl
chmod +x wildcrawl.sh
./wildcrawl.sh
```

Then type URL target (with http:// or https://)
> e.g. https://example.com

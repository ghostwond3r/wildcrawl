<p align="center">
   <img width="500" height="100" src="https://user-images.githubusercontent.com/64184513/226793206-8a6e3449-d3da-4520-8561-923479048555.png"
</p>
<hr>

> Bash script that crawls a target URL to get a better image of what is tied to a website.

Here's a summary of what the script does:

- Crawls the target URL using Hakrawler .
- Removes duplicate links.
- Extracts all files of certain types (e.g., PDF, DOC, ZIP, JPG) and saves them to a separate file.
- Extracts all domains and removes duplicates.
- Filters out certain domains (e.g., Facebook, Twitter, LinkedIn).
- Extract records of each domain.
- Extract link from each domain.
- Gets all the IPs associated with the filtered domains.
- Extracts the title of each domain and IP.
- Filters out any results that have a title starting with "404".
- Search emails from each domain.

<br>

Then it gives you option to;
- Test forms on URLs with SQLMAP;

OR
- Test IPs vulnerabilities with NMAP.

<hr>

At the end you will have these files saved in "scan_1, scan_2, etc.";
```
final_result.txt = All tests results including title of domains and IPs
domains.txt = domains filtered
ips.txt = IPs alive from the domains.txt
unique_urls.txt = The URLs crawled (duplicate and files removed)
files.txt = Files extracted during the crawl
injections_point.txt = Every URLs containing "?"
sqlmap.txt = If you run sqlmap
nmap.txt = If you run Nmap
```

*This script can be useful for reconnaissance and information gathering during a penetration testing engagement.*

<hr>

## Installation and Usage
```
git clone https://github.com/NeverWonderLand/wildcrawl.git
cd wildcrawl
chmod +x install.sh
./install.sh
chmod +x wildcrawl.sh

Then start with:
./wildcrawl.sh
```

Then type URL target (with http:// or https://)
> e.g. https://example.com

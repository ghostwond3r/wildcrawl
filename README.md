<p align="center">
   <img width="500" height="100" src="https://user-images.githubusercontent.com/64184513/226793206-8a6e3449-d3da-4520-8561-923479048555.png"
</p>
<hr>

<p align="center">
Bash script that crawls a target URL and everything around it to get a better image of what is tied to a website.
</p>
<hr>

Here's a summary of what the script does:

- Crawls the target URL using Hakrawler .
- Removes duplicate links.
- Extracts all files of certain types (e.g., PDF, DOC, ZIP, JPG) and saves them to a separate file.
- Extracts each domain from the link crawled and removes duplicates.
- Filters out certain domains (e.g., Facebook, Twitter, LinkedIn).
- Extract records (AAAA, CNAME, NS, etc)
- Extract DNS by fetching the certificate.
- Crawl again but this time using Lynx on the domain tied to the main one.
- Gets main IPs of all domains.
- Extracts the title of each domain and IP.
- Filters out any results that have a title starting with "404".
- Search emails from each domain.
- Retrieves server banner.

At the end, the tool gives you 3 options;
- Injection
- HTTP-ENUM
- Port Scan

<hr><br>

**At the end you will have these files saved in /scan_1, /scan_2, etc.**

- crawl.txt  
- domains.txt  
- files.txt  
- final_result.txt  
- injection_point.txt  
- ips.txt  
- unique_urls.txt
- sqlmap.txt - If you run sqlmap
- nmap.txt - If you run Nmap

![image](https://user-images.githubusercontent.com/64184513/228380278-6bb75044-03e6-4172-b998-f404ae46f22e.png)

<hr><br>

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

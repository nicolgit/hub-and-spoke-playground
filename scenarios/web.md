# SOLUTION: 

# Install a web server on spoke-03-vm (Linux server)

```
sudo apt-get update
sudo apt-get upgrade
sudo apt install nginx -y

sudo rm /usr/share/nginx/html/index.html 
sudo git clone https://github.com/nicolgit/html-resume /usr/share/nginx/html
```


to check web server status

```
systemctl status nginx.service
```

## web test pages 

* http://**web-server-url**/
* http://**web-server-url**/resume/resume.html

or from the machine itself

```
wget spoke-03-vm -O /dev/stdout
```
cd 

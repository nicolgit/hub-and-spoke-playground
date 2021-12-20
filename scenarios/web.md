# SOLUTION: 

# Install a web server on spoke-03-vm

```
sudo apt-get update
sudo apt-get upgrade
sudo apt install nginx -y

git clone https://github.com/nicolgit/html-resume /
```




to check web server status

```
systemctl status nginx.service
```

## web test pages 

* http://**web-server-url**/
* http://**web-server-url**/resume/resume.html

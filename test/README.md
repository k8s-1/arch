Add arch linux iso to test dir: archlinux.iso

Ensure virtualbox + vbox manager is installed.

Start a local web server from project dir:
cd arch
python3 -m http.server 8000 --bind 127.0.0.1

Get the current host IP:
ip a

From the vm:
curl -O http://HOST_IP:8000/file.sh

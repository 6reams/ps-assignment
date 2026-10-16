#!/bin/bash
# Provision script: installs Java 8 and Apache Tomcat 9 on port 7070
set -euo pipefail

TOMCAT_VERSION=9.0.98

# Java 8
apt-get update
apt-get install -y openjdk-8-jdk-headless wget

# Tomcat user
id tomcat &>/dev/null || useradd -r -m -d /opt/tomcat -s /bin/false tomcat

# Download and extract Tomcat 9
if [ ! -f /opt/tomcat/bin/startup.sh ]; then
  wget -q "https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" -O /tmp/tomcat.tar.gz
  tar xzf /tmp/tomcat.tar.gz -C /opt/tomcat --strip-components=1
fi

# Tomcat listens on 7070 (forwarded to host 9090)
sed -i 's/Connector port="8080"/Connector port="7070"/' /opt/tomcat/conf/server.xml
chown -R tomcat:tomcat /opt/tomcat
chmod +x /opt/tomcat/bin/*.sh

# systemd service
cat > /etc/systemd/system/tomcat.service <<'EOF'
[Unit]
Description=Apache Tomcat 9
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment=JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now tomcat

java -version
echo "Tomcat 9 is running on port 7070 (host port 9090)"

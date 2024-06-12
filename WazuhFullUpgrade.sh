#!/bin/bash

# Read input parameters
read -p "Enter the Wazuh Indexer IP address: " WAZUH_INDEXER_IP_ADDRESS
read -p "Enter your Wazuh username: " USERNAME
read -s -p "Enter your Wazuh password: " PASSWORD
echo

# Import Wazuh GPG key
echo "[!] Preparing the upgrade ..."
rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH

# Configure Wazuh repository
echo -e "[wazuh]\ngpgcheck=1\ngpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-\$releasever - Wazuh\nbaseurl=https://packages.wazuh.com/4.x/yum/\nprotect=1" | tee /etc/yum.repos.d/wazuh.repo

# Stop services
systemctl stop filebeat
systemctl stop wazuh-dashboard

# Upgrade Wazuh Indexer
echo "[!] Upgrading Wazuh Indexer ..."
curl -X PUT "https://$WAZUH_INDEXER_IP_ADDRESS:9200/_cluster/settings"  -u $USERNAME:$PASSWORD -k -H 'Content-Type: application/json' -d'
{
  "persistent": {
    "cluster.routing.allocation.enable": "primaries"
  }
}
'

# Flush synced
curl -X POST "https://$WAZUH_INDEXER_IP_ADDRESS:9200/_flush/synced" -u $USERNAME:$PASSWORD -k

# Stop and upgrade wazuh-indexer
systemctl stop wazuh-indexer
yum upgrade wazuh-indexer -y
systemctl daemon-reload
systemctl enable wazuh-indexer
systemctl start wazuh-indexer

# Reset cluster settings
curl -X PUT "https://$WAZUH_INDEXER_IP_ADDRESS:9200/_cluster/settings" -u $USERNAME:$PASSWORD -k -H 'Content-Type: application/json' -d'
{
  "persistent": {
    "cluster.routing.allocation.enable": "all"
  }
}
'

# Upgrade Wazuh Server
yum upgrade wazuh-manager -y
curl -s https://packages.wazuh.com/4.x/filebeat/wazuh-filebeat-0.3.tar.gz | sudo tar -xvz -C /usr/share/filebeat/module
curl -so /etc/filebeat/wazuh-template.json https://raw.githubusercontent.com/wazuh/wazuh/v4.7.5/extensions/elasticsearch/7.x/wazuh-template.json
chmod go+r /etc/filebeat/wazuh-template.json
systemctl daemon-reload
systemctl enable filebeat
systemctl start filebeat
filebeat setup --index-management -E output.logstash.enabled=false

# Upgrade Wazuh Dashboard
yum upgrade wazuh-dashboard -y
systemctl daemon-reload
systemctl enable wazuh-dashboard
systemctl start wazuh-dashboard

# Upgrade Wazuh Agents
echo "[!] Upgrading Wazuh Agents ..."
for id in $(/var/ossec/bin/agent_upgrade -l | awk 'NR>1 && NR!=NF {print $1}' | grep -v "Total"); do /var/ossec/bin/agent_upgrade -a $id; done



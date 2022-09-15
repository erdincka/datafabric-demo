#!/usr/bin/env /usr/local/bin/bash

set -euo pipefail

# Ensure you have paswordless ssh to the cluster_ip
CLUSTER_NAME="demo.df.io"
CLUSTER_IP="cldb.host.ip"

echo "Install/Update packages"
/usr/local/bin/brew update
/usr/local/bin/brew install gnu-getopt openssl@1.1 openjdk@11
# [ -f /Library/Java/JavaVirtualMachines/openjdk-11.jdk ] || sudo ln -sfn /opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
[ -f /usr/local/lib/libssl.1.1.dylib ] || sudo ln -s /usr/local/Cellar/openssl@1.1/1.1.1q/lib/libssl.1.1.dylib /usr/local/lib/
[ -f /usr/local/lib/libcrypto.1.1.dylib ] || sudo ln -s /usr/local/Cellar/openssl@1.1/1.1.1q/lib/libcrypto.1.1.dylib /usr/local/lib/

echo "Install mapr-client"
[ -f /opt/mapr/bin/mapr ] || wget https://package.mapr.hpe.com/releases/v7.0.0/mac/mapr-client-7.0.0.0.20220209033907.GA-1.x86_64.tar.gz
[ -d /opt/mapr ] || sudo tar -C /opt -xzf mapr-client-7.0.0.0.20220209033907.GA-1.x86_64.tar.gz
rm -f mapr-client-7.0.0.0.20220209033907.GA-1.x86_64.tar.gz
sudo ln -s /opt/mapr/hadoop/hadoop-2.x.x/bin/hadoop /usr/local/bin/hadoop2
sudo ln -s /opt/mapr/bin/hadoop /usr/local/bin/hadoop

export PATH="/opt/mapr/bin:/opt/homebrew/opt/openjdk@11/bin:/usr/local/opt/openssl@1.1/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openjdk@11/include -I/opt/homebrew/opt/openssl@1.1/include"
export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}:/opt/mapr/lib"

echo "Get secure files"
for file in "ssl_truststore" "ssl-client.xml" "maprtrustcreds.jceks" "maprtrustcreds.conf" "ssl_truststore.pem"
do
  scp $CLUSTER_IP:~/$file .
  sudo mv $file /opt/mapr/conf/
done

echo "clean mapr-clusters.conf"
# Remove cluster from config
grep -v "${CLUSTER_NAME}" /opt/mapr/conf/mapr-clusters.conf | sudo tee /opt/mapr/conf/mapr-clusters.conf || true

echo "configure the cluster"
# Configure cluster
sudo /usr/local/bin/bash /opt/mapr/server/configure.sh -c -N "${CLUSTER_NAME}" -C "${CLUSTER_IP}:7222" -HS "${CLUSTER_IP}" -secure
echo mapr | sudo /usr/local/bin/bash /opt/mapr/bin/maprlogin password -user mapr -cluster "${CLUSTER_NAME}"
sudo cp /tmp/maprticket_0 /tmp/maprticket_$(id -u)
sudo chown $USER /tmp/maprticket_$(id -u)

sudo /usr/local/bin/pip3 install --global-option=build_ext --global-option="--library-dirs=/opt/mapr/lib" --global-option="--include-dirs=/opt/mapr/include/" mapr-streams-python
/usr/local/bin/pip3 install maprdb-python-client

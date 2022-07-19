### MAC client

sudo mkdir -p /opt

wget https://package.mapr.hpe.com/releases/v7.0.0/mac/mapr-client-7.0.0.0.20220209033907.GA-1.x86_64.tar.gz
sudo tar -C /opt -xzf mapr-client-7.0.0.0.20220209033907.GA-1.x86_64.tar.gz

# launch x86_64 shell
arch -x86_64 zsh
# install x86_64 variant of brew 
arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
/usr/local/bin/brew install bash gnu-getopt openssl@1.1 openjdk@11
# Create mapr user
sudo sysadminctl -addUser mapr -fullName 'DF Admin' -UID 5000 -GID 5000 -shell /usr/local/bin/bash -home /opt/mapr
# Update paths/
echo '[[ -f /opt/mapr/conf/env.sh ]] && export JAVA_HOME="$(/usr/libexec/java_home) . /opt/mapr/conf/env.sh"' >> /opt/mapr/.bashrc
echo 'export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"' >> /opt/mapr/.bashrc
echo 'export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"' >> /opt/mapr/.bashrc
sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
sudo ln -s /usr/local/Cellar/openssl@1.1/1.1.1p/lib/libssl.1.1.dylib /usr/local/lib/
sudo ln -s /usr/local/Cellar/openssl@1.1/1.1.1p/lib/libcrypto.1.1.dylib /usr/local/lib/ 

/usr/local/bin/brew install OpenSSL@1.1
OPENSSL_INSTALLED_LOCATION=`/usr/local/bin/brew --prefix openssl@1.1`
OPENSSL_LIBRARY_PATH=${OPENSSL_INSTALLED_LOCATION}/lib
OPENSSL_PATH=${OPENSSL_INSTALLED_LOCATION}/bin 
export PATH=${OPENSSL_PATH}:${PATH}
LD_LIBRARY_PATH=${OPENSSL_LIBRARY_PATH}:${LD_LIBRARY_PATH}
export JAVA_HOME=$(/usr/libexec/java_home)

# Collect certificate files
# ssl_truststore
# ssl-client.xml
# maprtrustcreds.jceks
# maprtrustcreds.conf

export MAPR_HOST_IP=10.1.0.48
export MAPR_CLUSTER=dfcore.datafabric.io
echo "${MAPR_HOST_IP} ${MAPR_CLUSTER}" | sudo tee -a /etc/hosts


### SECURE CLUSTER ONLY -- YOU WILL NEED TO ENTER PASSWORD HERE AT: "ssh-copy-id" line
  [ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa
  ssh-copy-id ${MAPR_USER}@${MAPR_HOST_IP}

  scp ${MAPR_USER}@${MAPR_HOST_IP}:/opt/mapr/conf/ssl_truststore ssl_truststore
  scp ${MAPR_USER}@${MAPR_HOST_IP}:/opt/mapr/conf/ssl-client.xml ssl-client.xml
  scp ${MAPR_USER}@${MAPR_HOST_IP}:/opt/mapr/conf/maprtrustcreds.jceks maprtrustcreds.jceks
  scp ${MAPR_USER}@${MAPR_HOST_IP}:/opt/mapr/conf/maprtrustcreds.conf maprtrustcreds.conf

  sudo mv ssl_truststore ssl-client.xml maprtrustcreds.jceks maprtrustcreds.conf /opt/mapr/conf/

  arch -x86_64 sudo /usr/local/bin/bash /opt/mapr/server/configure.sh -c -N ${MAPR_CLUSTER} -C ${MAPR_HOST_IP}:7222 -HS ${MAPR_HOST_IP} -u mapr -g mapr -secure
  arch -x86_64 sudo /usr/local/bin/bash /opt/mapr/bin/maprlogin password -user mapr -cluster ${MAPR_CLUSTER}
### SECURE CLUSTER ONLY

### NON-SECURE CLUSTER ONLY
  arch -x86_64 sudo /usr/local/bin/bash /opt/mapr/server/configure.sh -c -N ${MAPR_CLUSTER} -C ${MAPR_HOST_IP}:7222 -HS ${MAPR_HOST_IP} -u mapr -g mapr
  arch -x86_64 sudo /usr/local/bin/bash /opt/mapr/bin/maprlogin password -user mapr -cluster ${MAPR_CLUSTER}
### NON-SECURE CLUSTER ONLY

arch -x86_64 sudo /usr/local/bin/bash /opt/mapr/hadoop/hadoop-2.7.6/bin/configure.sh --unsecure -EC "-HS ${MAPR_HOST_IP} --client"

# ssl.server.keystore.password=uQFo9pzQ0lXjSAgz_8iZs2e4sBsIKuNL
# ssl.server.keystore.keypassword=uQFo9pzQ0lXjSAgz_8iZs2e4sBsIKuNL
# ssl.server.truststore.password=dJTqjifrz2JwuKSHE1H63LJitAihP6pk
# ssl.client.truststore.password=dJTqjifrz2JwuKSHE1H63LJitAihP6pk
# ssl.client.keystore.password=uQFo9pzQ0lXjSAgz_8iZs2e4sBsIKuNL
# ssl.client.keystore.keypassword=uQFo9pzQ0lXjSAgz_8iZs2e4sBsIKuNL
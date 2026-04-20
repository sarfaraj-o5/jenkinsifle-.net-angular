#!/bin/bash

set -x

function wait_for_jenkins()
{
    while (( 1 )); do
        echo "waiting for jenkins to launch on port [8080]..."

        nc -zv 127.0.0.1:8080
        if (( $? == 0 )); then
            break
        fi 

        sleep 10
    done

    echo "jenkins launched"
}

function updating_jenkins_master_password()
{
    cat > /tmp/jenkinsHash.py <<EOF
    import bcrypt
    import sys
    if not sys.argv[1]:
        sys.exit(10)
    plaintext_pwd=sys.argv[1]
    encrypted_pwd=bcrypt.hashpw(sys.argv[1],bcrypt.gensalt(rounds=10, prefix=b"2a"))
    isCorrect=bcrypt.checkpw(plaintext_pwd, encrypted_pwd)
    if not isCorrect:
        sys.exit(20);
    print "{}".format(encrypted_pwd)
EOF

chmod +x /tmp/jenkinsHash.py

# wait till /var/lib/jenkins/users/admin* folder gets created
sleep 10

cd /var/lib/jenkins/users/admin*
pwd 
while (( 1 )); do
    echo "Waiting for jenkins to generate admin user's config file..."

    if [[ -f "./config.xml" ]]; then
        break
    fi

    sleep 10
done

echo "Admin config file created"

admin_password=$(python /tmp/jenkinsHash.py ${jenkins_admin_password} 2<&1)

# please do not remove alter quote as it keeps the hash syntax intact or else while substitution, $<character> will be replaced by null
xmlstarlet -q ed --inplace -u "/user/properties/hudson.security.HudsonPrivateSecurityRealm_-Details/passwordHash" -v '#jbcrypt:'"$admin_password" config.xml

# restart
systemctl restart jenkins
sleep 10
}

function install_packages()
{
  wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
  rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
  yum install -y jenkins

  systemctl enable jenkins
  systemctl restart jenkins
  sleep 10
}

function configure_jenkins_server() 
{
    # jenkins cli
    echo "installing the Jenkins cli..."
    cp /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar /var/lib/jenkins/jenkins-cli.jar

    # getting initial password
    PASSWORD="${jenkins_admin_password}"
    sleep 10

    jenkins_dir="/var/lib/jenkins"
    plugins_dir="$jenkins_dir/plugins"

    cd $jenkins_dir

    # open JNLP port
    xmlstarlet -q ed --inplace -u "/hudson/slaveAgentPort" -v 33453 config.xml

    cd $plugins_dir || { echo "unable to chdir to [$plugins_dir]"; exit 1; }

    # list of plugins that are needed to be installed
    plugin_list="git-client git github-api github-oauth github MSBuild ssh-slaves workflow-aggregator ws-cleanup"

    # remove existing plugins, if any...
    rm -rvf $plugin_list

    for plugin in $plugin_list; do
        echo "installing plugin [$plugin] ..."
        java -jar $jenkins_dir/jenkins-cli.jar -s http://127.0.0.1:8080/ -auth admin:$PASSWORD install-plugin $plugin
    done

    # restart jenkins after installing plugins 
    java -jar $jenkins_dir/jenkins-cli.jar -s http://127.0.0.1:8080 -auth admin:$PASSWORD safe-restart
}

## script starts here ##

install_packages

wait_for_jenkins

updating_jenkins_master_password

wait_for_jenkins

configure_jenkins_server

echo "Done"
exit 0
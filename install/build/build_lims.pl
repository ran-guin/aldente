
svn co https://svn01.bcgsc.ca/svn/alDente/trunk alpha

## Install Apache ##
sudo yum install httpd

# update /etc/httpd/conf/httpd.conf
# ServerName: lims.domain.com
# Group: lims
# User:  limsweb


cp /opt/alDente/versions/alpha/conf/httpd.conf /etc/httpd/conf.d/aldente.conf file ## COPY ##

# restart apache #
sudo apachectl -k stop
sudo /etc/init.d/httpd start

# update cpan 
sudo cpan
o conf build_requires_install_policy yes
o conf prerequisites_policy follow
o conf auto_commit 1
o conf commit

install CPAN
reload cpan
install YAML
install Term::ReadKey
install Params::Util
install CGI::Session

sudo yum install perl-GDGraph.noarch  ## doesn't install correctly with cpan 

# update /etc/hosts #
<IP> lims.domain.com localhost

# setup filesystem directories #
# check for existence of filesystem directories #

# test default web pages (point to standard cgi-bin/test_page.pl, test_page.html) #

# Install mySQL ##

yum install mysql-server mysql

sudo cp /opt/alDente/versions/alpha/conf/my.cnf /etc/my.cnf

chkconfig mysqld on
service mysqld start ## or /etc/init.d/mysqld start
service mysqld stop
service mysqld restart

mysqladmin -u root password NEWPASSWORD
# create password for patch_installer 
# cp password to all root users... 
# change explicit host to '%.domain.ca' (localhost, IP, %.domain.ca)
# 

## Checkout LIMS ##

cd /opt
mkdir alDente

cd alDente
mkdir versions
mkdir www

cd versions


## setup DNS file to recognize URL ##

## run interface script: setup.pl ##

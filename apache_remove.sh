APACHE_PKGS=`sudo dpkg --get-selections | grep apache | cut -f 1`
# Make sure things are sane:
echo $APACHE_PKGS
# Example output: apache2 apache2-mpm-prefork apache2-utils apache2.2-common \
# libapache2-mod-php5 libapache2-mod-python libapache2-svn
# Likely if you have a Python application:
# libapache2-mod-python libapache2-mod-python-doc libapache2-mod-wsgi
# Or if you roll with the PHP: 
# libapache2-mod-php5
sudo apt-get remove --purge $APACHE_PKGS

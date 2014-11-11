#
# build config
#
PACKAGES="sys-apps/busybox"
KEEP_HEADERS=true
TIMEZONE="UTC"
GLIBC_LOCALES=("en_US ISO-8859-1" "en_US.UTF-8 UTF-8")

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    # -static to enable dns lookups
    echo "sys-apps/busybox -static" > /etc/portage/package.use/busybox
    # set locales
    mkdir -p $EMERGE_ROOT/etc
    for LOCALE in "${GLIBC_LOCALES[@]}"; do
        echo "$LOCALE" >> /etc/locale.gen
    done
    cp /etc/locale.gen $EMERGE_ROOT/etc/
    # set timezone
    echo "${TIMEZONE}" > /etc/timezone
    cp /etc/timezone $EMERGE_ROOT/etc/
    cp /usr/share/zoneinfo/$TIMEZONE $EMERGE_ROOT/etc/localtime
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    # fake portage install
    emerge -p sys-apps/portage | grep sys-apps/portage | grep -Eow "\[.*\] (.*) to" | awk '{print $(NF-1)}' >> /config/tmp/package.installed
    # log dir
    mkdir -p $EMERGE_ROOT/var/log
    # install entr
    wget http://entrproject.org/code/entr-2.9.tar.gz
    tar xzvf entr-2.9.tar.gz
    cd eradman* && ./configure && make && make install
    strip /usr/local/bin/entr
    cp /usr/local/bin/entr $EMERGE_ROOT/bin
    # busybox crond setup
    mkdir -p $EMERGE_ROOT/var/spool/cron/crontabs
    chmod 0600 $EMERGE_ROOT/var/spool/cron/crontabs
}

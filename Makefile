PREFIX ?= $(shell pwd)/output

BUILD = $(shell pwd)/build
ROOT = $(shell pwd)
SOURCE=$(ROOT)/src
TARTMP=$(ROOT)/tmpsrc
#LIBPATH=lib:/usr/lib64:/lib64:/usr/lib:/lib
LIBPATH=lib
EXTPATH=lib/php/extensions/no-debug-non-zts-20100525

PHPVER=5.4.25
NGINXVER=1.4.5
PCREVER=8.33
CURLVER=7.32.0
THRIFTVER=0.9.0
SNAPPYVER=1.0.0
APCVER=3.1.13
CHRPATHVER=0.13
YIIVER=1.1.14.f0fee9
LIBMEMCACHEDVER=1.0.16
MEMCACHEDVER=2.1.0
LOGROTATEVER=3.8.3
STOMPVER=1.0.5
ZLIBVER=1.2.7
OPENSSLVER=1.0.1e
MYSQLVER=5.1.68
XML2VER=2.9.0
POPTVER=1.16

RM=rm -rf
MV=mv -f
CP=cp -pd
MKDIR=mkdir -p
TAR=tar --owner=0 --group=0 -C $(TARTMP)
LN=ln -f
CHMOD=chmod

CHRPATH=$(BUILD)/bin/chrpath
MKINSTALL=$(MAKE) -j16 && $(MAKE) install
MKEXT=$(BUILD)/bin/phpize && ./configure \
			--with-php-config=$(BUILD)/bin/php-config \
			&& $(MKINSTALL)

.PHONY: all clean install untar nginx php curl logrotate phpredis memcached libmemcached thrift snappy stomp apc yii lnmp

all: clean lnmp install

lnmp: untar chrpath popt zlib libxml2 mysql openssl curl logrotate nginx php phpredis libmemcached memcached thrift snappy stomp apc yii

nginx:
	cd $(TARTMP)/nginx-$(NGINXVER) && ./configure --prefix=$(BUILD) \
		--with-pcre=$(TARTMP)/pcre-$(PCREVER) --with-zlib=$(TARTMP)/zlib-$(ZLIBVER) --with-openssl=$(TARTMP)/openssl-$(OPENSSLVER) --error-log-path=/dev/null \
		&& $(MKINSTALL)

php: 
	$(MKDIR) $(TARTMP)/php-$(PHPVER)/pear/
	$(CP) $(SOURCE)/install-pear-nozlib.phar $(TARTMP)/php-$(PHPVER)/pear/
	cd $(TARTMP)/php-$(PHPVER) && ./configure --prefix=$(BUILD) \
		--with-libxml-dir=$(BUILD)  --with-openssl=$(BUILD)  \
		--with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-zlib-dir=$(BUILD)  \
		--with-mysql=mysqlnd --with-curl=$(BUILD) \
		--enable-cgi --enable-fpm --enable-soap --enable-pcntl \
		--enable-sockets \
		--with-config-file-scan-dir=etc/php.d && $(MAKE)  && $(MAKE) install
	$(LN) -s phar.phar $(BUILD)/bin/phar
	$(MV) $(BUILD)/bin/php $(BUILD)/bin/php-cli
	$(CP) bin/php.script $(BUILD)/bin/php
	$(CHMOD) +x $(BUILD)/bin/php

logrotate:
	cd $(TARTMP)/logrotate-$(LOGROTATEVER) && EXTRA_CFLAGS=-I$(BUILD)/include && EXTRA_LDFLAGS=-L$(BUILD)/lib  && $(MAKE)
	$(MKDIR) $(BUILD)/bin
	$(CP) $(TARTMP)/logrotate-$(LOGROTATEVER)/logrotate $(BUILD)/bin

popt:
	cd $(TARTMP)/popt-$(POPTVER) && ./configure --prefix=$(BUILD) && $(MKINSTALL)

chrpath:
	cd $(TARTMP)/chrpath-$(CHRPATHVER) && ./configure --prefix=$(BUILD) && $(MKINSTALL)

libmemcached:
	cd $(TARTMP)/libmemcached-$(LIBMEMCACHEDVER) && patch -p1 < \
		$(SOURCE)/libmemcached-$(LIBMEMCACHEDVER).patch && \
		CXXFLAGS=-D__STDC_CONSTANT_MACROS ./configure --disable-sasl \
		--prefix=$(BUILD) && $(MKINSTALL)

memcached: 
	cd $(TARTMP)/memcached-$(MEMCACHEDVER) && patch -p1 < $(SOURCE)/memcached-$(MEMCACHEDVER).patch \
		&& $(BUILD)/bin/phpize && ./configure --prefix=$(BUILD) --with-php-config=$(BUILD)/bin/php-config \
		--with-libmemcached-dir=$(BUILD) && $(MKINSTALL)
	$(CHRPATH) -d  $(BUILD)/$(EXTPATH)/memcached.so

apc:
	cd $(TARTMP)/APC-$(APCVER) && $(MKEXT)

phpredis:
	cd $(TARTMP)/phpredis && $(MKEXT)

thrift:
	cd $(TARTMP)/thrift-$(THRIFTVER)/lib/php/src/ext/thrift_protocol && $(MKEXT)

snappy:
	cd $(TARTMP)/php-snappy-$(SNAPPYVER) && $(MKEXT)

stomp: 
	cd $(TARTMP)/stomp-$(STOMPVER) && $(MKEXT)

curl: 
	cd $(TARTMP)/curl-$(CURLVER) && ./configure --prefix=$(BUILD) --with-ssl=$(BUILD) --with-zlib=$(BUILD) && $(MKINSTALL)

yii:
	$(MKDIR) $(BUILD)/yiilite/framework $(BUILD)
	$(CP) $(TARTMP)/yii-$(YIIVER)/framework/yiilite.php $(BUILD)/yiilite/framework/yiilite.php
	$(CP) -r $(TARTMP)/yii-$(YIIVER) $(BUILD)/yii

zlib:
	cd $(TARTMP)/zlib-$(ZLIBVER)  && ./configure --prefix=$(BUILD) && $(MKINSTALL)

libxml2:
	cd $(TARTMP)/libxml2-$(XML2VER)  && ./configure --prefix=$(BUILD) --with-zlib=$(BUILD) && $(MKINSTALL)

openssl:
	cd $(TARTMP)/openssl-$(OPENSSLVER) && ./config -I$(BUILD)/include -L$(BUILD)/lib --prefix=$(BUILD) threads -fPIC zlib-dynamic shared no-krb5 && \
	make && make install

mysql:
	cd $(TARTMP)/mysql-$(MYSQLVER) && ./configure --prefix=$(BUILD) --with-zlib-dir=$(BUILD) --with-ssl=$(BUILD) --without-server && $(MKINSTALL)

untar:
	$(MKDIR) $(TARTMP)
	cd $(SOURCE) && \
		$(TAR) -zxf logrotate-$(LOGROTATEVER).tar.gz && \
		$(TAR) -zxf popt-$(POPTVER).tar.gz && \
		$(TAR) -zxf chrpath-$(CHRPATHVER).tar.gz && \
		$(TAR) -zxf nginx-$(NGINXVER).tar.gz && \
		$(TAR) -jxf php-$(PHPVER).tar.bz2 && \
		$(TAR) -zxf pcre-$(PCREVER).tar.gz && \
		$(TAR) -zxf phpredis.tar.gz && \
		$(TAR) -zxf curl-$(CURLVER).tar.gz && \
		$(TAR) -zxf APC-$(APCVER).tgz && \
		$(TAR) -zxf yii-$(YIIVER).tar.gz && \
		$(TAR) -zxf libmemcached-$(LIBMEMCACHEDVER).tar.gz && \
		$(TAR) -zxf memcached-$(MEMCACHEDVER).tgz && \
		$(TAR) -zxf thrift-$(THRIFTVER).tar.gz && \
		$(TAR) -zxf stomp-$(STOMPVER).tgz && \
		$(TAR) -zxf php-snappy-$(SNAPPYVER).tar.gz && \
		$(TAR) -xjf zlib-$(ZLIBVER).tar.bz2 && \
		$(TAR) -zxf libxml2-$(XML2VER).tar.gz && \
		$(TAR) -zxf mysql-$(MYSQLVER).tar.gz && \
		$(TAR) -zxf openssl-$(OPENSSLVER).tar.gz 


install:
	$(MKDIR) $(PREFIX)/run $(PREFIX)/log $(PREFIX)/bin
	$(CP) -r $(BUILD)/lib $(PREFIX)
	$(CP) -r $(BUILD)/bin/logrotate $(PREFIX)/bin/logrotate
	$(CP) -r $(BUILD)/bin/php-cgi   $(PREFIX)/bin/php-cgi
	$(CP) -r $(BUILD)/bin/php-cli   $(PREFIX)/bin/php-cli 
	$(CP) -r $(BUILD)/bin/php       $(PREFIX)/bin/php
	$(CP) -r $(BUILD)/include $(PREFIX)
	$(CP) -r $(BUILD)/sbin $(PREFIX)
	$(CP) -r $(BUILD)/php $(PREFIX)
	$(CP) -r $(BUILD)/yii $(PREFIX)
	$(CP) -r $(BUILD)/yiilite $(PREFIX)
	$(CP) -r $(ROOT)/etc $(PREFIX)/
	$(CP) -r $(ROOT)/bin $(PREFIX)
	$(CP) -r $(ROOT)/htdocs $(PREFIX)
	$(CHRPATH) -d $(PREFIX)/bin/php-cgi
	$(CHRPATH) -d $(PREFIX)/bin/php-cli
	$(CHRPATH) -d $(PREFIX)/sbin/php-fpm
	$(CHRPATH) -d $(PREFIX)/sbin/nginx
	$(CHRPATH) -d $(PREFIX)/$(EXTPATH)/memcached.so

clean:
	$(RM) -r $(TARTMP)
	$(RM) -r $(BUILD)


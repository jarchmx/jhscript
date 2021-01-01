FROM ubuntu:16.04
MAINTAINER Jarch Hu <jarch_hu@askey.com>

RUN echo echo 'PS1="[\u@\h \W]\$ "' | tee -a /root/.bashrc 1>/dev/null

RUN rm -rf /var/lib/apt/lists/* && apt autoclean

RUN apt-get update --fix-missing && apt-get install -y locales && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && export LANG=en_US.utf8

RUN apt-get install -y \
	git repo


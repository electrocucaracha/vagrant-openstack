#!/bin/bash

if [ -f /root/shared/proxyrc ]
then
  source /root/shared/proxyrc

  # Ubuntu
  if [ -f /etc/apt/apt.conf ]
  then
    echo "Acquire::http::Proxy \"${http_proxy}\";" >>  /etc/apt/apt.conf
    echo "Acquire::https::Proxy \"${https_proxy}\";" >>  /etc/apt/apt.conf
  fi

  if [ -d /etc/apt/apt.conf.d ]
  then
    echo "Acquire::http::Proxy \"${http_proxy}\";" >>  /etc/apt/apt.conf.d/70proxy.conf
    echo "Acquire::https::Proxy \"${https_proxy}\";" >>  /etc/apt/apt.conf.d/70proxy.conf
  fi

  # CentOS
  if [ -f /etc/yum.conf ]
  then
    echo "proxy=${http_proxy}" >> /etc/yum.conf
  fi

  if [ -f /etc/bashrc ]
  then
    echo "export http_proxy=${http_proxy}" >> /etc/bashrc
    echo "export https_proxy=${https_proxy}" >> /etc/bashrc
    echo "export no_proxy=${no_proxy}" >> /etc/bashrc
  fi

  if [ -f /etc/bash.bashrc ]
  then
    echo "export http_proxy=${http_proxy}" >> /etc/bash.bashrc
    echo "export https_proxy=${https_proxy}" >> /etc/bash.bashrc
    echo "export no_proxy=${no_proxy}" >> /etc/bash.bashrc
  fi

  echo "http_proxy=${http_proxy}" >> /etc/wgetrc
  echo "https_proxy=${https_proxy}" >> /etc/wgetrc
else
  # 0. Workaround for vagrant boxes
  sed -i "s/10.0.2.3/8.8.8.8/g" /etc/resolv.conf
fi

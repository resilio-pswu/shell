#!/bin/bash

#dbus fire onwanstart
#sleep 5
#sh /koolshare/scripts/ss_config.sh
#/usr/bin/plugin.sh start
#sh /tmp/mnt/home/root/Applications/scripts/entware-start


ShellFileDirPath=$(cd `dirname $0`; pwd)


fun_smb_mount(){
    source_addr=ac66u
    web1_doc_root=/home/wwwroot/icloud.ureepi.cc
    user_root=${web1_doc_root}/data/User
    username=admin
    password=meiyu2016

    src_dir_matt_home="ac66u:/tmp/mnt/home/matt"
    usr_dir_matt_home="${user_root}/matt/home"
    if [ `df | grep ${src_dir_matt_home} | grep -v grep | wc -l` -lt 1 ]
    then
            mount -t nfs ${src_dir_matt_home} ${usr_dir_matt_home} -o proto=tcp -o nolock
            echo "${usr_dir_matt_home}.... mounted!"
    fi
    sleep 2

    src_dir_sdb2="//ac66u/me (at sdb2)"
    if [ -x "${usr_dir_matt_home}/NMSC" ]; then
            if [ `df | grep "${src_dir_sdb2}" | grep -v grep | wc -l` -lt 1 ]; then
                    mount -t cifs "//ac66u/me (at sdb2)" "${usr_dir_matt_home}/NMSC" -o username="${username}",password="${password}"
                    echo "${src_dir_sdb2}.... mounted!"
            fi
    fi
}


fun_nfs_mount(){
    # 提供共享目录的目标机器IP地址
    #arr_host_dir=(ac66u:/tmp/mnt/home/matt home-sas:/NAS/NAS home-sas:/NMSC/NMSC)
    arr_host_dir=(home-sas:/NAS/NAS home-sas:/NMSC/NMSC nuc-sas:/NAS/NAS)
    #arr_local_dir=(das1 das2/NAS das2/NMSC)
    arr_local_dir=(netDrive/home-nas netDrive/nmsc netDrive/nuc-nas)  

    for ((i=0;i<${#arr_host_dir[@]};i++))
    #for item in ${arr[*]}
    do
        dir_src=${arr_host_dir[$i]}
        dir_dst=/home/wwwroot/icloud/data/User/benevo/home/${arr_local_dir[$i]}

        if [ $# -eq 0 ]; then
            if [ -z "$(df | grep $dir_dst)" ]; then
                if [ ! -d $dir_dst ]; then
                    mkdir -p $dir_dst
                fi
                mount -t nfs -o nosuid,noexec,nodev,rw,bg,soft,rsize=32768,wsize=32768 $dir_src $dir_dst
                echo "[$(date +%Y"."%m"."%d" "%k":"%M":"%S)]: $dir_src         mounted on: $dir_dst         ... ok" >> $basepath/$shname.log
                echo "$dir_src         mounted on: $dir_dst         ... ok"
            fi
        else
            case $1 in
                "-ua")
                if [ -n "$(df | grep $dir_dst)" ]; then
                    umount $dir_dst
                    #///rmdir $dir_dst
                    echo "[$(date +%Y"."%m"."%d" "%k":"%M":"%S)]: $dir_dst        umounted ... done." >> $basepath/$shname.log
                    echo "$dir_dst        umounted ... done."
                fi
                ;;
            esac
        fi
    done

    echo "--------------------------"
    df -h | grep ':'
}


#clear
#rootness

action=$1
[  -z $1 ]
case "$action" in
    nfs)
        fun_nfs_mount 2>&1 | tee ${ShellFileDirPath}/das-mount.log
    ;;
    nfs-ua)
        fun_nfs_mount -ua 2>&1 | tee ${ShellFileDirPath}/das-mount.log
    ;;
    *)
        #fun_clangcn
        echo "Arguments error! [${action} ]"
        echo "Usage: `basename $0` {nfs|nfs-ua|}"
    ;;
esac

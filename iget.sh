#!/bin/bash

# decriptions: 
#       主要是配合wget下载KE上浏览的文件
#       试用方法： 从KE上浏览文件，查看文件属性，复制"位置“内容
#               然后在终端命令中输入： iget [复制的内容]，即可开始下载。

# echo "#: $#"
# echo "@: $@"
# echo "0: $0"
# echo "1: $1"
# echo "2: $2"

pre_http_domain="http://pan.pswu.cc"
icloud_addr=$@

real_dl_addr_http="${pre_http_domain}${icloud_addr}"

echo $real_dl_addr_http

wget "${real_dl_addr_http}"

exit 0


pre_ftp_arg1="wget --ftp-user=admin --ftp-password=meiyu2016 "
pre_arg1="ftp://192.168.50.1/sdb2/me"
pre_arg2="ftp://192.168.50.1/home/matt"


# start parse..
input1=$@


type=0

[[ $input1 =~ "/NMSC/" ]] && {
	#echo "type: sdb2"
	type=1
}

real_local_dl_addr_ftp=""
if [ $type -eq 1 ]; then
	real_local_dl_addr_ftp=${input1/\/NMSC/$pre_arg1}
	real_local_dl_addr_ftp=${real_local_dl_addr_ftp// /\%20}
	echo "Real ftp addr: ${real_local_dl_addr_ftp}"	
else
	real_local_dl_addr_ftp=${pre_arg2}${input1}
	real_local_dl_addr_ftp=${real_local_dl_addr_ftp// /\%20}
fi

echo "Real ftp addr: ${real_local_dl_addr_ftp}"
wget --ftp-user=admin --ftp-password=meiyu2016 $real_local_dl_addr_ftp


exit 0

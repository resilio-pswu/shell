#!/bin/sh

#echo "1: $1"
#echo "2: $2"
#echo "3: $3"
#echo "4: $4"
#echo "5: $5"
#echo "6: $6"

fun_u3ur() {
    local clear_flag=""
    clear_flag=$1
    if [[ ${clear_flag} == "clear" ]]; then
        clear
    fi
    echo ""
    echo "+------------------------------------------------------------+"
    echo "|         VMWARE CLI for ESXI HOST, Written by U3UR          |"
    echo "+------------------------------------------------------------+"
    echo "|          A common line tool for VMware ESXI HOST           |"
    echo "+------------------------------------------------------------+"
    echo "|         Intro: http://im.u3ur.cn/vcli-72-1.html            |"
    echo "+------------------------------------------------------------+"
    echo ""
}

rootness(){
    if [[ $EUID -ne 0 ]]; then
        fun_clangcn
        echo "Error:This script must be run as root!" 1>&2
        exit 1
    fi
}

fun_esxcli_vm() {

    case $1 in
        rename)
            fun_esxcli_vm_rename $2 $3
        ;;
        disk)
            fun_esxcli_vm_disk $2 $3
        ;;
        copy)
            fun_esxcli_vm_copy $2 $3
        ;;
        tt)
            fun_esxcli_vm_tt $2
        ;;
        list)
            fun_esxcli_vm_list
        ;;
        power)
            fun_esxcli_vm_power $2 $3
        ;;
        *)
            echo "Usage: vcli vm {cmd} [cmd options]"
            echo ""
            echo "Available Namespaces:"
            echo "  disk                  Disk of vmdk alias commands"
            echo "  power                 Power operation for a(or more) virtual machine(s) alias commands"
            echo ""
            echo "Available Commands:"
            echo "  rename                Rename a virtual machine."
            echo "  copy                  copy a virtual machine."
            echo "  tt                    Convert a virtual machine from thick to thin."
            echo "  list                  List all virtual machines on this host"
        ;;
    esac
}


fun_esxcli_vm_list() {

    COL_FLD_VMID="Vmid"
    COL_FLD_NAME="Name"
    COL_FLD_FILE="File"
    COL_FLD_OS="Guest OS"
    COL_FLD_VERSION="Version"
    COL_FLD_STATE="PowerState"

    len1=${#COL_FLD_VMID}
    len2=${#COL_FLD_NAME}
    len3=${#COL_FLD_FILE}
    len4=${#COL_FLD_OS}
    len5=${#COL_FLD_VERSION}
    len6=${#COL_FLD_STATE}

    #COL_VMID=0
    printf '%s\t %-15s\t %-75s\t %-20s\t %-10s\t %s\n' "${COL_FLD_VMID}" "${COL_FLD_NAME}" "${COL_FLD_FILE}" "${COL_FLD_OS}" "${COL_FLD_VERSION}" "${COL_FLD_STATE}" 
    echo "-------------------------"
    vim-cmd vmsvc/getallvms | grep -v 'Vmid' | while read line
    do 
        #echo $line

        aa=`echo $line | sed 's/^[ \t]*//g' | sed 's/[ \t]*$//g'`
        bb=`echo $aa | sed 's/[ ][ ]*/,/g'`

        COL_VMID=`echo "$bb" | cut -d "," -f 1`

        expr $COL_VMID "+" 10 &> /dev/null
        if [ ! $? -eq 0 ];then  
            #echo "$COL_VMID not number"
            continue
        fi

        #COL_NAME=`echo "$bb" | cut -d "," -f 2`
        n0=${#COL_VMID}
        n1=`expr index "$aa" "["`
        count=`expr $n1 - $n0 - 1`
        #echo $n0 $n1 $count
        COL_NAME=`echo ${aa:$n0:$count} | sed 's/^[ \t]*//g' | sed 's/[ \t]*$//g'`
        #echo $COL_VMID
        #echo $COL_NAME

        n0=`expr index "$aa" "["`
        #n1=`expr index "$aa" "vmx"`
        n1=`echo | awk -v "STR=$aa" -v "SUB=vmx" '{print index(STR,SUB)}'`
        count=`expr $n1 - $n0`
        #echo $n0 $n1
        COL_FILE="["${aa:$n0:$count}"vmx"
        #echo $COL_FILE
        
        n3=`expr $n1 + 3`
        cc=`echo "${aa:$n3}" | sed 's/^[ \t]*//g' | sed 's/[ ][ ]*/,/g'`
        COL_OS=`echo "$cc" | cut -d "," -f 1`
        COL_VERSION=`echo "$cc" | cut -d "," -f 2`
        #echo $COL_OS
        #echo $COL_VERSION

        COL_POWER=`vim-cmd vmsvc/power.getstate ${COL_VMID}  | grep Powered`
        #echo $COL_POWER

        # display fields using f1, f2,..,f7
        printf '%s\t %-15s\t %-75s\t %-20s\t %-10s\t %s\n' "${COL_VMID}" "${COL_NAME}" "${COL_FILE}" "${COL_OS}" "${COL_VERSION}" "${COL_POWER}" 

        #break
    done
}

#IFS="|"

fun_esxcli_vm_rename() {
    if [ -z $1 ] || [ -z $2 ]; then
        echo "Error: Missing required parameter [srcName: $1] & [newName: $2]"
        echo ""
        echo "Usage: vcli vm rename [srcName] [newName]"
        echo ""
        echo "Description:"
        echo "  rename                Rename a virtual machine.(include its path & files alias"
        echo "                        e.g.: vcli vm rename /absolute/path/to/vm1 vm2"
        echo "                        e.g.: vcli vm rename /relative/path/to/vm1 vm2"
        echo ""
        echo "Cmd options:"
        echo "  srcName               origin name of a virtual machine. "
        echo "  newName               new name of a virtual machine."
        exit 0
    fi

    local vmName="$(basename $1)"
    local pathWorkingDir=`pwd`
    local pathVM="";
    if [ ${1:0:1} == "/" ]; then
        pathWorkingDir=""
        pathVM="$(dirname $1)/$vmName"
    else
        pathVM="$pathWorkingDir/$(dirname $1)/$vmName"
    fi
    local pathNewVM="$(dirname $pathVM)/$2"
    local vmNewName=$2

    if [ $pathVM == $pathNewVM ]; then
        echo "Cannot be the same name."
        exit 0
    fi

    if [ ! -x "$pathVM" ]; then
        echo "Error: virtual machine ($pathVM) not exsit."
        exit 0
    fi

    # change vmx file content include string 'vmName' 
    for file in `ls "$pathVM" | egrep ".vmx$|.vmx~$"`
    do
        #echo $pathVM/$file
        #echo $file
        #echo $vmName
        #echo $vmNewName
        sed -i "s/$vmName/$vmNewName/g" $pathVM/$file
    done

    # rename file exclude vmdk file
    for file in `ls "$pathVM" | grep "$vmName" | egrep -v ".vmdk$"`
    do
        local newfile=${file//$vmName/$vmNewName}
        #echo "$file   --->   $newfile"
        mv "$pathVM/$file" "$pathVM/$newfile"
    done

    # rename vmdk file
    for file in `ls "$pathVM" | grep ".vmdk$" | grep -v "\-flat.vmdk$"`
    do
        local newfile=${file//$vmName/$vmNewName}
        #echo $file"   --->   "$newfile
        vmkfstools -E "$pathVM/$file" "$pathVM/$newfile"
    done

    #echo $pathVM"   --->   "$pathNewVM
    mv "$pathVM" "$pathNewVM"  

    echo "-----------------------------------------------"
    echo "virtual machine path : $pathVM"
    echo "origin name          : $vmName"
    echo "rename to            : $vmNewName"
    echo "-----------------------------------------------"
    echo "file list:           : "
    ls -lh $pathNewVM
}

fun_check_vmdkfile() {
    filename=$1
    if [ ! -f $filename ]; then
        echo "File not exsit."
        exit 0
    elif [ -z `echo $filename | grep ".vmdk"` ]; then
        echo "not a valid vmdk file."
        exit 0
    fi
}

fun_esxcli_vm_disk() {
    local filename=$2
    
    case $1 in
        rename)
            fun_check_vmdkfile $filename

            vmkfstools -E $filename $3
        ;;
        tt)
            fun_check_vmdkfile $filename
            local tmpfile=`dirname $filename`"/tmp889.vmdk"

            vmkfstools -i $filename -d thin $tmpfile
            vmkfstools -U $filename
            vmkfstools -E $tmpfile $filename
            echo "Convert: Success."
        ;;
        del)
            fun_check_vmdkfile $filename

            vmkfstools -U $filename
        ;;
        info)
            echo "get info about a disk"
        ;;
        expand)
            echo "expand or narrowa space of a disk"
        ;;
        *)
            echo "Usage: vcli vm disk {cmd} [cmd options]"
            echo ""
            echo "Available Commands:"
            echo "  rename                Rename a disk vmdk."
            echo "                        e.g.: vcli vm disk rename /path/to/file.vmdk /newpath/to/newfile.vmdk"
            echo "  tt                    Convert a disk vmdk from thick to thin."
            echo "                        e.g.: vcli vm disk tt /path/to/file.vmdk"
            echo "  del                   Safe to delete a disk vmdk."
            echo "                        e.g.: vcli vm disk del /path/to/file.vmdk"
            echo "  info                  Get info of a disk vmdk."
            echo "                        e.g.: vcli vm disk info /path/to/file.vmdk"
            echo "  expand                Expand a disk space."
            echo "                        e.g.: vcli vm disk expand +10G /path/to/file.vmdk"
            echo "                        e.g.: vcli vm disk expand -10G /path/to/file.vmdk"
        ;;
    esac    
}

fun_esxcli_vm_power() {
    local vmid=$2
    
    case $1 in
        on)
            vim-cmd vmsvc/power.on $vmid
        ;;
        off)
            vim-cmd vmsvc/power.off $vmid
        ;;
        reboot)
            vim-cmd vmsvc/power.reboot $vmid
        ;;
        reset)
            vim-cmd vmsvc/power.reset $vmid
        ;;
        shutdown)
            vim-cmd vmsvc/power.shutdown $vmid
        ;;
        suspend)
            vim-cmd vmsvc/power.suspend $vmid
        ;;
        *)
            echo "Usage: vcli vm power {cmd} [cmd options]"
            echo ""
            echo "Available Commands:"
            echo "  on                    power on a virtual machine."
            echo "                        e.g.: vcli vm power on { vmid }"
            echo "  off                   power off a virtual machine."
            echo "                        e.g.: vcli vm power off { vmid }"
            echo "  reboot                power reboot a virtual machine."
            echo "                        e.g.: vcli vm power reboot { vmid }"
            echo "  reset                 power reset a virtual machine."
            echo "                        e.g.: vcli vm power reset { vmid }"
            echo "  shutdown              power shutdown a virtual machine."
            echo "                        e.g.: vcli vm power shutdown { vmid }"
            echo "  suspend               power suspend a virtual machine."
            echo "                        e.g.: vcli vm power suspend { vmid }"
        ;;
    esac    
}

fun_esxcli_vm_copy() {
    if [ -z $1 ] || [ -z $2 ]; then
        echo "Error: Missing required parameter [vmPathName: $1] & [desDirName: $2]"
        echo ""
        echo "Usage: vcli vm copy [vmPathName] [desDirName]"
        echo ""
        echo "Description:"
        echo "  copy                Copy a virtual machine.(include its path & files alias"
        echo "                        e.g.: vcli vm copy /absolute/path/to/vm1 /to/path/"
        echo "                        e.g.: vcli vm copy /relative/path/to/vm1 /to/path/"
        echo ""
        echo "Cmd options:"
        echo "  vmPathName            path name of a virtual machine. "
        echo "  desDirName            destination path for copying to."
        exit 0
    fi

    local vmName="$(basename $1)"
    local vmPathName="$(dirname $1)/$vmName"
    local desPath="$2"
    local desPathVM=""

    local n=`expr ${#desPath} - 1`
    if [ ${desPath:$n:1} == "/" ]; then
        desPathVM="${desPath}${vmName}"
    else
        desPathVM="${desPath}/$vmName"
    fi

    #echo $desPathVM
    if [ ! -d "$desPathVM" ]; then
        mkdir "$desPathVM"
    fi

    # copy files exclude vmdk file
    for file in `ls "$vmPathName" | egrep -v ".vmdk$"`
    do
        local newfile=${desPathVM}/${file}
        #echo "${vmPathName}/${file}   --->   $newfile"

        cp -r "${vmPathName}/${file}" "${newfile}"
    done    

    #exit 0

    # copy vmdk file
    for file in `ls "$vmPathName" | grep ".vmdk$" | grep -v "\-flat.vmdk$"`
    do
        local newfile=${desPathVM}/${file}
        echo "${vmPathName}/${file}   --->   $newfile"
        
        vmkfstools -i "${vmPathName}/${file}" -d thin "$newfile"
    done

    echo "-----------------------------------------------"
    echo "virtual machine      : $vmPathName"
    echo "copy to              : $desPathVM"
    echo "-----------------------------------------------"
    echo "file list:           : "
    ls -lh $desPathVM
}

fun_esxcli_vm_tt() {
    if [ -z $1 ]; then
        echo "Error: Missing required parameter [vmPathName: $1]"
        echo ""
        echo "Usage: vcli vm tt [vmPathName]"
        echo ""
        echo "Description:"
        echo "  tt                Convert a virtual machine from thick to thin"
        echo "                        e.g.: vcli vm tt /absolute/path/to/vm1"
        echo "                        e.g.: vcli vm tt /relative/path/to/vm1"
        echo ""
        echo "Cmd options:"
        echo "  vmPathName            path name of a virtual machine. "
        exit 0
    fi

    local vmName="$(basename $1)"
    local vmPathName="$(dirname $1)/$vmName"

    # convert vmdk file from thick to thin
    for file in `ls "$vmPathName" | grep ".vmdk$" | grep -v "\-flat.vmdk$"`
    do
        local tmpfile=${vmPathName}"/tmp889.vmdk"
        local filepath="${vmPathName}/$file"

        echo $filepath
        #echo $tmpfile

        vmkfstools -i $filepath -d thin $tmpfile
        vmkfstools -U $filepath
        vmkfstools -E $tmpfile $filepath
        
    done

    echo "done !"
    echo ""
}

clear
#rootness

action=$1
[  -z $1 ]
case "$action" in
    vm)
        fun_esxcli_vm $2 $3 $4
    ;;
    *)
        fun_u3ur
        echo "Usage: vcli [options] {namespace}+ {cmd} [cmd options]"
        echo ""
        echo "Options:"
        echo "  --debug               Enable debug or internal use options"
        echo "  --version             Display version information for the script"
        echo "  -?, --help            Display usage information for the script"
        echo ""
        echo "Available Namespaces:"
        echo "  vm                    Virtual machine commands"
        echo "  network               Network functionality"
    ;;
esac
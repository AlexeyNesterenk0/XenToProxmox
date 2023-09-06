#!/bin/bash
#Xen Migrate To Proxmox
#Version 1.0
#Author : Aleksey Nesterenko 2023
# example ./XenMigrateToProxmox.sh xen db83f273-ade0-1585-b1fa-b6197353c4df SHD-ZFS0-FC 
####################################↑#############↑############################↑#########################################################
#############################Имя сервера######UUID Виртуальной машины####Диск для размещения ВМ##########################################
#########################################################################################################################################
function ProgressBar { # автор функции Teddy Skarin https://github.com/fearside/ProgressBar
# Process data
	let _progress=(${1}*100/${2}*100)/100
	let _done=(${_progress}*4)/10
	let _left=40-$_done
# Build progressbar string lengths
	_done=$(printf "%${_done}s")
	_left=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1 Progress : [########################################] 100%
printf "\rProgress : [${_done// /#}${_left// /-}] ${_progress}%%"

}

function TimeStamp {
	end=`date +%s`
	runtime=$(($end-${1}))
	hours=$(($runtime / 3600))
	minutes=$(( ($runtime % 3600) / 60 ))
	seconds=$(( ($runtime % 3600) % 60 ))
	echo "$hours:$minutes:$seconds"
}
echo "Проверка наличия пакетов, необходимых для выполнения скрипта:"
set -e
if [ $(dpkg-query -W -f='${Status}' xml2 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  echo "Пакет XML2 не обнаружен в системе - инициализирована установка"
  apt install xml2 -y;
else
echo "Пакет XML2 обнаружен в системе "
fi
set +e
srv=$1                                                                                  #Переменная хранения имени сервера
echo ""
echo "	  Запуск скрипта миграции VM  с сервера $srv XCP-NG"
echo "в среду гипервизора $HOSTNAME Proxmox Virtual Environment"
disk=$3                                                                                 #Переменная хранения имени хранилища
let vmid=$(qm list | awk {'print $1'} | grep -v VMID | sort -rn | head -n 1)+100
vmid=200600
read -sp "Введите пароль для доступа к $srv: " password
echo " "
echo "Запуск процесса экспорта VM  UUID : $2"
set -o pipefail -e
start0=`date +%s`
wget --http-user=root --http-password=$password http://$srv/export?uuid=$2 -O - | tar vxf -
echo -n "Экспорт VM UUID : $2 завершен за " 
TimeStamp ${start0}
password="********"                                                                      #Очистка пароля
set +o pipefail +e
mv ova.xml $vmid.xml --force
echo ""
echo "Получение параметров экспортируемой виртуальной машины"
mac=$(xml2 < $vmid.xml | grep -oE "\w\w:\w\w:\w\w:\w\w:\w\w:\w\w" | head -n 1)
if  [[ $mac == $null ]]; 
	then
        mac=00:60:2F:$[RANDOM%10]$[RANDOM%10]:$[RANDOM%10]$[RANDOM%10]:$[RANDOM%10]$[RANDOM%10]
fi
cores=$(xml2 < $vmid.xml | grep -A 1 =VCPUs_max | grep -oE "[0-9]{1,}")
if  [[ $cores == $null ]]; 
	then
        cores=4;
fi
name=$(xml2 < $vmid.xml | grep -A 1 name_label | grep -v name_label  | grep -v $srv | grep value= |head -n 1 |grep -Po "(?<==).*$")
if  [[ $name == $null ]]; 
	then
        name=NewVMN;
fi
let memory=$(xml2 < $vmid.xml | grep -A 1 =memory_static_max | grep -v memory_static_max | grep -Po "(?<==).*$")/1000000
if  [[ $memory == $null ]]; 
	then
        cores=4096;
fi
VDIs=$(xml2 < $vmid.xml | grep -A 1 =VDIs | grep -v =VDIs | grep -Po "(?<==).*$")
if  [[ $VDIs == $null ]]; 
	then
        echo "Невозможно выполнить конвертацию. Работа скрипта завершена";
        exit;
fi
firmware=$(xml2 < $vmid.xml | grep -A 1 =firmware | grep -v =firmware | grep -Po "(?<==).*$")

echo " "
echo "ИМЯ : $name"
echo "ИД : $vmid"
echo "MAC : $mac"
echo "FIRM : $firmware"
echo "RAM : $memory"
echo "Ядра : $cores"
echo " "
echo "Запуск процесса конвертации"
start1=`date +%s`
cd $VDIs
dd if=/dev/zero of=blank bs=1024 count=1k
test -f $name.img && rm -f $name.img
touch $name.img

max=`ls ???????? | sort | tail -n1`
end=$(ls -l | grep -v $name | wc -l)
for i in `seq 0 $max`; do
        fn=`printf "%08d" $i`
        if [ -f "$fn" ]; then
                cat $fn >> $name.img
        else
                cat blank >> $name.img
        fi
		ProgressBar ${i} ${end}
done
rm -f blank
echo -n "Конвертация в IMG завершена за"
TimeStamp ${start1}
echo "Запуск процесса конвертации IMG в QCOW2."
start2=`date +%s`
set -e
qemu-img convert -f raw -O qcow2 $name.img $name.qcow2
set +e
end=`date +%s`
echo -n "Конвертация IMG в qcow2 завершена за"
TimeStamp ${start2}
echo "Создание VM $vmid $name."
set -e
if [[ $firmware == "bios" ]] || [[ $firmware == $null ]]; 
	then    
		bios=seabios; 
		qm create $vmid --name $name --net0 virtio=$mac --cores $cores --memory $memory --bios $bios
		did=0;
	else 
		bios=ovmf;
		qm create $vmid --name $name --net0 virtio=$mac --cores $cores --memory $memory --bios $bios --efidisk0 $disk:1;
		did=1;
fi
set +e
echo "BIOS : $bios"

echo "Создание VM $vmid $name завершено успешно"
start3=`date +%s`
echo "Загрузка диска VM $vmid $name на хранилище $disk"
set -e
qm importdisk $vmid $name.qcow2 $disk 
set +e
echo "Настройка VM $vmid $name"

qm set $vmid --agent enabled=1,fstrim_cloned_disks=1 --sata0 $disk:vm-$vmid-disk-$did,ssd=1 --boot order='sata0' -sata1 ISO-BACKUPSRV-SMB:iso/virtio-win-0.1.229.iso,media=cdrom
cd ..
end=`date +%s`
echo -n "Создание и настройка VM $vmid $name завершены успешно за"
TimeStamp ${start3}
echo "Удаление временных файлов"
rm -rf Ref*
rm -f $vmid.xml
echo "Работа скрипта завершена"
end=`date +%s`
echo -n "Общее время выполнения  ::  "
TimeStamp ${start0}

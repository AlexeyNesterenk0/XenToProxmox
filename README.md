# XenMigrateToProxmox
Данный скрипт, запускаемый на хостовой машине Proxmox 
позволяет экспортировать посредством ЛВС и преобразовать "на лету" 
файлы экспорта формата XVA в готовую QEMU виртуальную машину с автоматическим 
выделением ресурсов, аналогичным экспортируемой машине.

Обратите внимание - 

                    !экспортируемая машина должна быть остановлена!
                    
                    !в дирректории запуска скрипта должно быть достаточно свободного пространства чтобы вмеcтить 
                      удвоенный размер диска ВМ!

                    !имя экспортируемой машины не должно содержать кирилических символов!
                    

Запуск скрипта:

                    cmod +x XenMigrateToProxmox.sh                    
                    ./XenMigrateToProxmox.sh {$1} {$2} {$3} {$4}
                    
Примеры:



                    ./XenMigrateToProxmox.sh xen 847fb7ef-5d76-3e2c-e507-e17906b923c5 XXX-THINLVM-DEDUP-FC 100
                    ./XenMigrateToProxmox.sh xen 847fb7ef-5d76-3e2c-e507-e17906b923c5 XXX-THINLVM-DEDUP-FC --a
                    ./XenMigrateToProxmox.sh --m
                    ./XenMigrateToProxmox.sh --ma
                    

 Параметры скрипта:
 
                   
                     $1 - Имя сервера XCP-NG 
                         --m  вместо имени сервера включает GUI для запросов параметров
                         --ma  вместо имени сервера включает GUI для запросов параметров 
                           и автоматическое присвоение ИД виртуальной машине
                     $2 - UUID виртуальной машины на XEN
                     $3 - Имя хранилища, на котором будет размещен диск виртуальной машины на PVE
                     $4 - ИД виртуальной машины
                         --a  вместо ИД виртуальной машины включает автоматическое присвоение ИД виртуальной машине

После запуска скрипт запрашивает пароль доступа к консоли XEN

![image](https://github.com/AlexeyNesterenk0/XenToProxmox/assets/143705665/1d621751-f44a-4572-81a8-0e3088db2c10)



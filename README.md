# XenMigrateToProxmox
Данный скрипт, запускаемый на хостовой машине Proxmox 
позволяет экспортировать посредством ЛВС и преобразовать "на лету" 
файлы экспорта формата XVA в готовую QEMU виртуальную машину с автоматическим 
выделением ресурсов, аналогичным экспортируемой машине.

Обратите внимание - 

                    !экспортируемая машина должна быть остановлена!

                    !имя экспортируемой машины не должно содержать кирилических символов, пробелов, тире и любых иных спецсимволов!"
                    

Запуск скрипта:

                    cmod +x XenMigrateToProxmox.sh

                    ./XenMigrateToProxmox.sh xen 847fb7ef-5d76-3e2c-e507-e17906b923c5 XXX-THINLVM-DEDUP-FC

 Параметры скрипта:
 
                     $1 - Имя сервера XCP-NG
                     $2 - UUID виртуальной машины на XEN
                     $3 - Имя хранилища, на котором будет размещен диск виртуальной машины
                          на PVE

После запуска скрипт запрашивает пароль доступа к консоли XEN

![image](https://github.com/AlexeyNesterenk0/XenToProxmox/assets/143705665/1d621751-f44a-4572-81a8-0e3088db2c10)



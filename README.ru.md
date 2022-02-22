<!-- omit in toc -->
# consul formula

Формула для установки и настройки HashiCorp Consul.

* [Использование](#использование)
* [Доступные стейты](#доступные-стейты)
  * [consul](#consul)
  * [consul.repo](#consulrepo)
  * [consul.repo.clean](#consulrepoclean)
  * [consul.install](#consulinstall)
  * [consul.binary.install](#consulbinaryinstall)
  * [consul.binary.clean](#consulbinaryclean)
  * [consul.config](#consulconfig)
  * [consul.config.tls](#consulconfigtls)
  * [consul.service](#consulservice)
  * [consul.service.install](#consulserviceinstall)
  * [consul.service.clean](#consulserviceclean)
  * [consul.backup_helper](#consulbackup_helper)
  * [consul.shell_completion](#consulshell_completion)
  * [consul.shell_completion.clean](#consulshell_completionclean)
  * [consul.shell_completion.bash](#consulshell_completionbash)
  * [consul.shell_completion.bash.install](#consulshell_completionbashinstall)
  * [consul.shell_completion.bash.clean](#consulshell_completionbashclean)
  * [consul.acl_bootstrap](#consulacl_bootstrap)

## Использование

* Создаем pillar с данными, см. `pillar.example` для качестве примера, привязываем его к хосту в pillar top.sls.
* Применяем стейт на целевой хост `salt 'consul-01*' state.sls service.consul saltenv=base pillarenv=base`.
* Применить формулу к хосту в state top.sls, для выполнения оной при запуске `state.highstate`.

__ВНИМАНИЕ__  

С настройками по умолчанию запущенный consul agent не будет работать, т.к. он будет запущен в режиме клиента, но адреса для подключения к серверу у него не будет. Таким образом, для запуска сервиса __обязательно__ нужно создать pillar с корректными данными.

## Доступные стейты

### consul

Мета стейт, выполняет все необходимое для настройки сервиса на отдельном хосте.

### consul.repo

Стейт для настройки официального репозитория HashiCorp <https://www.hashicorp.com/blog/announcing-the-hashicorp-linux-repository>

### consul.repo.clean

Стейт для удаления репозитория, используйте с осторожностью, т.к. данный репозиторий используется для всех продуктов HashiCorp.

### consul.install

Вызывает стейт для установки Consul в зависимости от значения пиллара `use_upstream`:

* `binary` или `archive`: установка из архива `consul.binary.install`
* `package` или `repo`: установка из пакетов `consul.package.install`

### consul.binary.install

Установка Conusl из архива

### consul.binary.clean

Удаление Consul установленного из архива

### consul.config

Создает конфигурационный файл. Создает самоподписныой сертификат, или устанавливает готовый сертификат. Запускает сервис.

### consul.config.tls

Управление TLS сертификатами для Consul, при `tls:self_signed: true` будут сгенерированы ключ и самоподписной сертификат и сохранены по путям указаннымм в `consul.config.data.key_file`, `consul.config.data.cert_file`. При `tls:self_signed: false` и наличии данных в `tls:key_file_source`, `tls:cert_file_source` существующие ключ и сертификат будут скопированы по путям указаннымм `consul.config.data.key_file`, `consul.config.data.cert_file`.

### consul.service

Управляет состоянием сервиса consul, в зависимости от значений пилларов `consul.service.status`, `consul.service.on_boot_state`.

### consul.service.install

Устанавливает файл сервиса Consul, на данный момент поддерживается только одна система инициализации - `systemd`.

### consul.service.clean

Останавливает сервис, выключает запуск сервиса при старте ОС, удаляет юнит файл `systemd`.

### consul.backup_helper

При установке параметра `backup:helper:install: true` `consul.backup_helper.install` установит вспомогательный bash скрипт для выполнения резервного копирования. Скрипт устанавливается как `/usr/local/bin/consul_backup`, скрипт должен выполняться от имени пользователя Consul (обычно consul) или от имени суперпользователя, т.к. скрипт извлекает мастер токен из конфигурационного файла агента Counsul. Мастер токен необходим для выполнения команды `consul snapshot save`. На самом деле подойдет любой токен с правами management, но мастер токен проще всего извлечь.

Скрипт принимает два параметра:

* `--backup` - создать резервную копию, которая сохранится в директории `backup_dir` указанной в pillar, по умолчанию это `/var/lib/consul/backup`.
* `--clean` - удалить все файлы из директории `backup_dir`, проще говоря, очистка временного хранилища резервных копий, после их переноса в архивное хранилище.

Пример _sudoers_ правила, которое позволит пользователю выполняющему резервное копирование запустить скрипт:

```
backupuser ALL = (consul) NOPASSWD:/usr/local/bin/consul_backup
```

Пример pillar для использования совместно с [users-formula](https://github.com/saltstack-formulas/users-formula), в данном случае настраиваем для пользователя `backuppc` право выполнять `/usr/local/bin/consul_backup` от имени пользовател `consul`. Данный pillar может быть подключен к нужному хосту в дополнение к основному (общему) pillar для настройки пользователя `backuppc`, для того чтоб два pillar были слиты в один требуется чтоб был включен параметр `pillar_merge_lists: True` в конфигурации `salt-master`.

```yaml
users:
  backuppc:
    sudo_rules:
      - ALL = (consul) NOPASSWD:/usr/local/bin/consul_backup
```

### consul.shell_completion

Вызывает стейты `consul.shell_completion.*` на данный момент только `consul.shell_completion.bash`.

### consul.shell_completion.clean

Вызывает стейты `consul.shell_completion.*.clean` на данный момент только `consul.shell_completion.bash.clean`.

### consul.shell_completion.bash

Вызывает стейт `consul.shell_completion.bash.install`

### consul.shell_completion.bash.install

Устанавливает автодополнение для bash

### consul.shell_completion.bash.clean

Удаляет автодополнение для bash

### consul.acl_bootstrap

Позволяет инициализировать ACL подсистему: создать policy, а так же настроить анонимный и агентский токены.

__ВНИМАНИЕ__  

Данный стейт требует доработки в связи с изменениями в работе ACL начиная с версии 1.5.0

На данный момент при первом прогоне формулы невозможно полностью сформировать конфигурационный файл Consul, требуется запущенный Consul для генерации агентского токена (см. [consul issue #4977](https://github.com/hashicorp/consul/issues/4977)). Таким образом, для полной настройки сервера "с нуля" необходимо запустить формулу 2 раза:

* Первый запуск - создание политик, получение токена для агента, ручное сохранение полученного токена в конфигурации, путем добавления его в pillar
* Второй запуск - Consul использует агентский токен из конфигурации, достигнуто работоспосбное состояние.

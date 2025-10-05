# TP 05 : Synthèse

## Introduction

Ce TP a pour but de réutiliser l'ensemble des connaissances acquises au cours des TPs 01 à 04.

## Prérequis

Ce TP part du principe que vous venez de dérouler les TPs 01 à 04.

Vous devriez donc déjà avoir à disposition :
- un contrôleur avec Ansible
- deux hôtes distants sur lesquels la clé SSH du contrôleur a été copiée
- un inventaire configuré pour accéder aux hôtes distants, et structuré avec un groupe `frontend` et un groupe `backend`

## Déroulé

Ce TP est un TP de synthèse où rien n'est fourni.

L'objectif est d'écrire :
- un rôle pour installer une base de données MySQL
- un rôle pour installer un serveur web nginx
- un rôle pour installer PHP
- un rôle pour installer et configurer une instance de WordPress
- un playbook pour orchestrer ces quatre rôles

Voyez cela comme une mise en situation : un client vous demande d'automatiser l'installation d'un WordPress avec une base de données déportée. À vous donc d'écrire les rôles et le playbook susmentionnés.

Un ingénieur Dev(Sec)Ops doit souvent composer avec de multiples logiciels, dont certains lui seront imposés et initialement inconnus.

### Suggestions

Avant de vous lancer dans l'écriture de vos rôles, considérez les points suivants :
- Rendez vos rôles aussi agnostiques que possible : une interdépendance trop forte compliquera ou empêchera leur réutilisation tels quels.
- Utilisez les modules `community.mysql` pour interagir avec votre instance de MySQL.
- Le module `ansible.builtin.unarchive` sert à décompresser des archives, mais il est également capable de traiter une archive directement à partir d'une URL : n'hésitez pas à vous servir de cette capacité pour réduire le nombre de tâches.
- Idéalement, l'instance de WordPress doit être prête à l'emploi dès la fin du playbook, sans passer par le wizard de configuration. Pour faire cela, il faut fournir un fichier `wp-config.php` complet.
- Le fichier `wp-config.php` doit, notamment, fournir des `salts`. WordPress met à disposition une API pour récupérer des salts déjà correctement formatés : [https://api.wordpress.org/secret-key/1.1/salt/](https://api.wordpress.org/secret-key/1.1/salt/).
- Idéalement, le service devrait être accessible via HTTPS, et non via HTTP. Mais il s'agit d'une contrainte supplémentaire difficile à réaliser si on travaille en local : sur un vrai site web exposé à internet, l'utilisation du certbot de Letsencrypt facilite grandement les choses. Si vous vous en sentez capable, essayez de rajouter des tâches (débrayables) pour supporter ceci, même si vous serez potentiellement dans l'incapacité de les tester.

Si vous n'êtes pas familiers avec nginx, un fichier de configuration pour une utilisation avec PHP ressemble à ceci :
```
server {
    listen 80;
    server_name serveur_wordpress_local;

    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php-fpm;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

### Erreurs courantes

Les erreurs courantes que vous êtes susceptibles de rencontrer sont :
- `A MySQL module is required` : celle erreur est liée à une librairie Python manquante lorsqu'Ansible tente d'utiliser les modules MySQL. Vous pouvez retrouver la version minimale dans la partie `requirements` de la [documentation officielle](https://docs.ansible.com/ansible/latest/collections/community/mysql/mysql_info_module.html#requirements). Pour l'installer, une solution simple est d'ajouter le package `python3-pymysql`.

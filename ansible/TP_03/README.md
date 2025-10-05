# TP 03 : Différencier et contrôler l'exécution d'un playbook

## Introduction

Ce TP a pour but d'introduire les concepts suivants :
- les templates
- les magic variables
- les handlers
- les filters
- les register
- les conditionnelles
- les tags

## Prérequis

Ce TP part du principe que vous venez de dérouler les TPs 01 et 02.

Vous devriez donc déjà avoir à disposition :
- un contrôleur avec Ansible
- deux hôtes distants sur lesquels la clé SSH du contrôleur a été copiée
- un inventaire configuré pour accéder aux hôtes distants, et structuré avec un groupe `frontend` et un groupe `backend`

## Déroulé

Dans ce TP, nous allons installer une base de données PostgreSQL sur le backend, et tenter de la contacter à partir du frontend. Contrairement au TP précédent, il va donc falloir différencier les deux machines pour y jouer des tâches différentes.

### Réutilisation de l'inventaire

Si vous le souhaitez, vous pouvez restaurer un snapshot antérieur sur vos machines virtuelles, mais cela n'est pas critique : les actions de ce TP ne vont pas entrer en conflit avec celles du TP précédent.

Dans ce TP, c'est à vous de fournir l'inventaire. Si vous avez suivi le TP prédédent, l'inventaire se trouve dans le dossier `TP_02`. Vous avez alors deux choix :
- dupliquer l'inventaire en le copiant dans le répertoire du TP actuel `TP_03`, et supprimer les variables désormais inutiles pour que l'inventaire soit pleinement adapté au TP 03
- déplacer l'inventaire dans un dossier commun (par exemple le dossier parent `ansible`), et conserver les variables existantes de façon à pouvoir jouer plusieurs playbooks avec

> En fonction des cas d'usage, les deux solutions sont acceptables. Dans le cas de déploiements de taille modérée, on peut privilégier d'avoir un seul inventaire pour plusieurs playbooks/déploiements afin de limiter le risque d'actions concurrentes (dans le cas où des variables auraient des valeurs différentes entre plusieurs inventaires), même si cela implique d'avoir des variables "inutiles" pour un des déploiements. A contrario, sur des déploiements plus importants, avoir un seul inventaire par playbook/déploiement permet de ne pas surcharger les inventaires et de faciliter la lecture.

Dans les deux cas, il faudra bien entendu rajouter les nouvelles variables attendues par le playbook du TP 03, et adapter le chemin de l'inventaire dans la commande `ansible-playbook` en conséquence.

### Lire le playbook

Si vous allez lire le playbook, vous allez pouvoir y trouver de nombreuses nouvelles choses :
- la présence de plusieurs plays, le premier ciblant les hôtes du groupe `backend`, et le second les hôtes du groupe `frontend`
- de nouveaux modules : `ansible.builtin.lineinfile`, `ansible.builtin.template`, `ansible.builtin.service`, `ansible.posix.firewalld` et plusieurs modules préfixés `community.postgresql`
- une nouvelle catégorie `handler` au même niveau que les tasks
- une nouvelle variable `become_user` sur la tâche `Initialisation de PostgreSQL`
- une variable spéciale `groups['backend'][0]['ansible_host']`

Voyons chacun de ces éléments un à un.

Pour ce qui est de la présence de deux plays, il s'agit d'une méthode de segmentation parmi d'autres : il est tout à fait acceptable de n'avoir qu'un seul play par playbook pour mieux s'y repérer. Dans ce cas, soit on fera deux exécutions distinctes avec chaque playbook, soit on créera un playbook 'maître', qui va appeler les 'sous-playbooks' avec le module `ansible.builtin.import_playbook` ([lien vers la documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/import_playbook_module.html)).

Pour ce qui est des nouveaux modules :
- le module [`ansible.builtin.lineinfile`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/lineinfile_module.html) s'assure de la présence d'une ligne dans un fichier. Il est utilisé ici pour s'assurer que la configuration PostgreSQL est bien celle qui est souhaitée.
- le module [`ansible.builtin.template`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html) est une alternative à `ansible.builtin.copy`, avec la différence que le fichier n'est pas statique. Celui-ci peut en effet comporter des variables comme dans les tâches de façon à s'adapter au contexte. Il est utilisé ici pour copier un fichier `pg_hba.conf` correctement configuré.
- le module [`ansible.builtin.service`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/service_module.html) sert à gérer les services sur une machine. Il est utilisé ici pour démarrer PostgreSQL.
- le module [`ansible.posix.firewalld`](https://docs.ansible.com/ansible/latest/collections/ansible/posix/firewalld_module.html) sert à gérer l'ouverture et la fermeture de ports sur firewalld. Il est utilisé ici pour ouvrir le port de PostgreSQL (qui est fermé par défaut sur AlmaLinux 9).
- les modules préfixés [`community.postgresql`](https://docs.ansible.com/ansible/latest/collections/community/postgresql/index.html) sont, comme leur nom l'indique, des modules d'une collection développée par la communauté. Ils servent à manipuler plusieurs aspects PostgreSQL. Ils sont utilisés ici pour créer un utilisateur, une base de données, et pour collecter des informations sur la base de données (même si ces dernières ne sont pas utilisées : il s'agit surtout de tester la connexion entre le frontend et le backend).

Pour la nouvelle catégorie `handler`, ceux-ci sont des tâches spéciales qui sont liées au mot-clé `notify`. Si une tâche qui notify un handler est à l'état `ok`, rien ne se passera. En revanche, si la tâche est à l'état `changed`, alors le handler se déclenchera à la fin du playbook. Ici, nous avons un handler pour redémarrer PostgreSQL si sa configuration a été modifiée : il n'est en effet pas nécessaire de redémarrer systématiquement PostgreSQL, mais uniquement si sa configuration a changé. Plusieurs tâches peuvent notify un seul handler, mais celui-ci ne s'exécutera qu'une seule fois.

L'instruction `become_user` sert à préciser l'utilisateur que l'on veut devenir lors d'une élévation de privilège. Par défaut, cette valeur est `root`, mais ici PostgreSQL exige que ce soit son utilisateur dédié qui lance le binaire `initdb`. On précise alors, pour cette tâche uniquement, un utilisateur différent pour le `become`.

Et enfin, la variable spéciale `hostvars[groups['backend'][0]]['ansible_host'] | default(groups['backend'][0])` est une variable fournie par Ansible lui-même, un peu comme les variables préfixées `ansible_`. Ces variables sont appellées des `magic variables`, et leur liste exhaustive est disponible [dans la documentation officielle](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html#magic-variables). La variable est un peu complexe, nous allons donc la décomposer :
- `groups` est une variable qui référence les différents groupes de l'inventaire
- `groups['backend']` pointe sur le groupe `backend` de l'inventaire, qui est un tableau car il est suceptible de comporter plusieurs hôtes
- `groups['backend'][0]` pointe sur le premier hôte (et le seul dans notre cas) du groupe `backend`, soit la machine où PostgreSQL est installé
- `hostvars` est une variable qui permet d'accéder aux variables d'un hôte en dehors de son contexte. À ce moment, nous sommes dans le contexte d'un hôte du gorupe `frontend`, et nous n'avons donc pas accès aux variables d'autres hôtes.
- `hostvars[groups['backend'][0]]` permet donc d'accéder aux variables du premier hôte du groupe `backend`
- et pour finir la première partie de la variable, `hostvars[groups['backend'][0]]['ansible_host']` représente la valeur de la variable `ansible_host` du premier hôte du groupe `backend`, soit le FQDN ou l'IP de la machine où PostgreSQL est installé
- cependant, si vous souvenez du premier TP, il existe plusieurs méthodes de déclaration des hôtes, et `ansible_host` n'est pas toujours renseigné. Si vous avez déclaré vos hôtes sans, l'exécution de ce bout de code renverrait une erreur comme quoi `ansible_host` est indéfini. Pour pallier à cela, on va utiliser le filtre `default`, qui fonctionne comme un `pipe` en shell, et qui permet d'avoir une valeur de repli en cas d'erreur dans la première partie de la variable
- et donc, si la variable `ansible_host` n'est pas déclarée, `groups['backend'][0]` renverra le nom du premier hôte du groupe `backend`, soit son FQDN ou son IP
- l'ordre est important ici : `groups['backend'][0]` renvoie toujours une valeur, mais qui est parfois un nom fonctionnel. Si on l'avait mis en premier, on aurait pu avoir une valeur non-exploitable, et le filtre `default` n'aurait jamais été sollicité. Il faut toujours mettre en première partie une valeur susceptible de ne pas exister.

Sur le sujet des filtres, vous pouvez en connaître la liste exhaustive sur les documentations officielles d'[Ansible](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_filters.html) et de [Jinja2](https://jinja.palletsprojects.com/en/stable/templates/#list-of-builtin-filters).

### Lire le template

Si vous allez lire le fichier template `pg_hba.conf.j2`, vous allez voir au début un fichier statique classique, et seulement dans les dernières lignes des variables entourées de `{{ }}` comme dans un playbook. Quelques autres exemples qui, eux, n'ont pas d'équivalent dans un playbook, sont aussi présents, comme un commentaire ou une condition.

Comme dans le playbook, vous retrouvez une variable `hostvars`, à la différence que celle-ci référence le frontend.

### Compléter l'inventaire

Comme vous avez pu le constater dans le playbook, de nouvelles variables sont présentes : `nom_utilisateur_postgresql`, `mot_de_passe_utilisateur_postgresql`, `nom_base_de_donnees_postgresql`. Renseignez-les dans votre inventaire à l'endroit qui vous semble le plus adéquat. N'oubliez pas de chiffrer les secrets avec Ansible Vault !

### Jouer le playbook

Jouez le playbook une première fois. Tout devrait bien se passer, vous avez une dizaine de `changed` sur le backend, et un sur le frontend.

Testez maintenant l'idempotence en rejouant le playbook. Lors de la seconde exécution, vous devriez rencontrer une erreur fatale avec comme message `initdb: error: directory \"xxx\" exists but is not empty`. En effet, le module `ansible.builtin.command` ne gère pas l'idempotence nativement.

### Compléter le playbook

À des fins pédagogiques, nous allons adopter une approche qui n'est pas la meilleure, mais qui fonctionne tout de même, et qui est très utile dans de nombreux autres cas.

Il va falloir identifier si PostgreSQL est déjà initialisé ou non, et choisir de lancer ou non la commande `initdb` en fonction. La présence du fichier `/var/lib/pgsql/data/PG_VERSION` est un indicateur d'une base de données initialisée. Ajoutez une nouvelle tâche avant l'initialisation qui utilise le module [`ansible.builtin.stat`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/stat_module.html) pour récupérer des informations sur ce fichier.

La question maintenant est : comment utiliser les informations récupérées ? C'est là que le mot-clé `register` entre en scène. Cette instruction permet de sauvegarder le retour d'un module dans une variable. On l'utilse comme ceci :
```yaml
- name: Tâche
  ansible.builtin.module:
    parametre: valeur
  register: retour_du_module
```

Mais que contient cette variable ? Utilisons le module [`ansible.builtin.debug`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/debug_module.html) pour le savoir, comme suit :
```yaml
- name: Affichage du contenu de la variable retour_du_module
  ansible.builtin.debug:
    var: retour_du_module
```

> Contrairement à la plupart des autres modules, le paramètre `var` du module `ansible.builtin.debug` s'attend explicitement à avoir le nom d'une variable comme valeur, il n'est donc pas nécessaire de l'entourer de `{{ }}`.

En combinant `ansible.builtin.stat`, `register` et `ansible.builtin.debug`, vous devriez obtenir ce genre de retour :
```yaml
ok: [serveur_backend] => {
    "nom_de_la_variable": {
        "changed": false,
        "failed": false,
        "stat": {
            "atime": 1738004299.039636,
            "attr_flags": "",
            "attributes": [],
            "block_size": 4096,
            "blocks": 8,
            "charset": "us-ascii",
            "checksum": "feee44ad365b6b1ec75c5621a0ad067371102854",
            "ctime": 1738004299.032636,
            "dev": 64768,
            "device_type": 0,
            "executable": false,
            "exists": true,
            "gid": 26,
            "gr_name": "postgres",
            "inode": 33687259,
            "isblk": false,
            "ischr": false,
            "isdir": false,
            "isfifo": false,
            "isgid": false,
            "islnk": false,
            "isreg": true,
            "issock": false,
            "isuid": false,
            "mimetype": "text/plain",
            "mode": "0600",
            "mtime": 1738004299.032636,
            "nlink": 1,
            "path": "/var/lib/pgsql/data/PG_VERSION",
            "pw_name": "postgres",
            "readable": true,
            "rgrp": false,
            "roth": false,
            "rusr": true,
            "size": 3,
            "uid": 26,
            "version": "4179399850",
            "wgrp": false,
            "woth": false,
            "writeable": true,
            "wusr": true,
            "xgrp": false,
            "xoth": false,
            "xusr": false
        }
    }
}
```

En parcourant ces données, on peut constater que la clé `nom_de_la_variable.stat.exists` (qui est à `true`) semble répondre à notre problématique. Nous allons donc maintenant pouvoir procéder à la dernière étape en rajoutant une condition sur l'initialisation de PostgreSQL comme ceci :
```yaml
- name: Tâche
  ansible.builtin.module:
    parametre: valeur
  when: nom_de_la_variable.stat.exists
```

> Comme pour la plupart des langages de programmation, `nom_de_la_variable.stat.exists` est strictement équivalent à `nom_de_la_variable.stat.exists == true`.

> Comme pour le paramètre `var` du module `ansible.builtin.debug`, l'instruction `when` s'attend à traiter des variables, et n'a donc pas non plus besoin de les entourer de `{{ }}`.

Si vous rejouez le playbook, vous constaterez que la tâche d'initialisation qui nous posait problème est maintenant à l'état `skipped`, et que le playbook est enfin idempotent.

> Vous pouvez en apprendre plus sur les conditionnelles dans la [documentation officielle](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_conditionals.html).

### Ajouter des tags

Imaginons que l'on souhaite rendre optionnel certaines parties de notre playbook, comme par exemple l'utilisation de SCRAM-SHA-256 avec les mots de passe.

Dans l'état actuel de vos connaissances, vous pourriez définir une variable dans l'inventaire, couplée à une conditionnelle. Mais nous allons explorer un autre mécanisme.

Modifiez la tâche comme ceci:
```yaml
- name: Configuration de PostgreSQL pour utiliser SCRAM-SHA-256 avec les mots de passe
  become: true
  ansible.builtin.lineinfile:
    path: /var/lib/pgsql/data/postgresql.conf
    regexp: '^[# ]*password_encryption *='
    line: password_encryption = 'scram-sha-256'
  notify: Redémarrage de PostgreSQL
  tags:
    - securite
```

Rejouez ensuite le playbook avec la commande habituelle, vous ne devriez constater aucune différence.

Rejouez maintenant le playbook avec la commande suivante :
```bash
ansible-playbook playbook.yml --inventory <chemin_vers_l'inventaire> --ask-vault-pass --tags securite
```

Vous constatez que le playbook n'a joué qu'une seule tâche : celle qui comporte le tag `securite`.

> Ansible ne prend en compte les tags que si le paramètre `--tags` est utilisé.

Rejouez maintenant le playbook avec la commande suivante :
```bash
ansible-playbook playbook.yml --inventory <chemin_vers_l'inventaire> --ask-vault-pass --skip-tags securite
```

Nous avons enfin le comportement souhaité : la tâche de sécurisation n'est pas jouée. Mais si l'on oublie un instant la bonne pratique qui veut que l'on propose un système sécurisé par défaut, on pourrait désirer ce comportement par défaut, sans devoir rajouter le paramètre `--skip-tags`. C'est possible en utilisant deux tags spéciaux : `always` et `never`. Ceux-ci permettent de respectivement toujours et ne jamais jouer une tâche à moins qu'elle ne soit explicitement mentionnée dans `--skip-tags` ou `--tags`.

Pour cela, rajoutez le tag `always` à toutes les tâches :
```yaml
- name: Tâche
  ansible.builtin.module:
    parametre: valeur
  tags:
    - always
```

> Les handlers ne sont pas concernés par les tags

Et modifiez les tags de la tâche de sécurisation comme suit :
```yaml
- name: Configuration de PostgreSQL pour utiliser SCRAM-SHA-256 avec les mots de passe
  become: true
  ansible.builtin.lineinfile:
    path: /var/lib/pgsql/data/postgresql.conf
    regexp: '^[# ]*password_encryption *='
    line: password_encryption = 'scram-sha-256'
  notify: Redémarrage de PostgreSQL
  tags:
    - never
    - securite
```

Jouez à nouveau le playbook sans paramètre relatif aux tags :
```bash
ansible-playbook playbook.yml --inventory <chemin_vers_l'inventaire> --ask-vault-pass
```

Vous constatez que le comportement est le même qu'avec le paramètre `--skip-tags securite`.

Enfin, si vous jouez une dernière fois le playbook avec le paramètre `--tags securite` :
```bash
ansible-playbook playbook.yml --inventory <chemin_vers_l'inventaire> --ask-vault-pass --tags securite
```

Le playbook joue maintenant toutes les tâches, y compris celle de sécurisation.

> N'hésitez pas à consulter [la documentation officielle](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_tags.html) pour en apprendre plus sur les tags.

## Conclusion

Félicitations, vous avez maintenant appris à différencier et contrôler l'exécution d'un playbook en utilisant les templates et les magic variables, les handlers, les filters, le register, les conditionnelles et les tags.

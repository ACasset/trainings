# TP 04 : Utiliser un rôle

## Introduction

Ce TP a pour but d'introduire les concepts suivants :
- les roles
- les imports/includes
- les facts
- les loops
- les blocks

## Prérequis

Ce TP part du principe que vous venez de dérouler les TPs 01 à 03.

Vous devriez donc déjà avoir à disposition :
- un contrôleur avec Ansible
- deux hôtes distants sur lesquels la clé SSH du contrôleur a été copiée
- un inventaire configuré pour accéder aux hôtes distants, et structuré avec un groupe `frontend` et un groupe `backend`
- un playbook pour installer PostgreSQL

## Déroulé

Dans ce TP, nous allons capitaliser sur ce qui a été fait dans le TP 03, et le rendre réutilisable. Pour cela, nous allons convertir le playbook en `rôle`. Un rôle en Ansible est une manière de structurer et d'organiser les tâches, les variables, les fichiers, les templates et les handlers de manière modulaire et réutilisable. Les rôles permettent de diviser un playbook complexe en plusieurs composants plus petits et plus faciles à gérer. Cela permet de réutiliser facilement des configurations et des automatisations dans différents playbooks.

### Lire le playbook

Avant toute chose, allons rapidement voir le playbook. Vous allez voir que, grâce à l'utilisation d'un rôle, il est beaucoup plus compact que ceux que nous avons vus jusqu'ici.

Vous allez également y voir une instruction `vars_file` (que vous pouvez retrouver dans la [liste des précécences](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#understanding-variable-precedence) au 14ème rang) qui est une façon d'importer des valeurs sans dépendre d'un inventaire.

### Lire le rôle Apache

À titre d'exemple, vous trouverez dans le dossier `roles` de ce TP un premier rôle nommé `apache`. Celui-ci permet l'installation du serveur web Apache et est décomposé ainsi :
- un dossier `defaults`, qui est nouveau, et qui va contenir les variables "publiques", avec une précédence faible (au 21ème rang sur 22), que l'utilisateur va pouvoir/devoir fournir. Vous remarquerez que toutes les variables sont préfixées avec le nom du rôle : c'est pour éviter d'éventuelles collisions, car des noms trop génériques (par exemple `chemin_configuration`) pourraient être utilisés dans plusieurs rôles différents, et affecter leur comportement de façon négative.
- un dossier `files`, que vous connaissez déjà : il va contenir les fichiers statiques.
- un dossier `handlers`, dont vous devez probablement vous douter de l'utilité : il va contenir les handlers.
- un dossier `meta`, qui est nouveau, et qui va contenir différentes méta-données pour identifier et catégoriser le rôle. À noter que celles-ci ne sont pas indispensables tant que vous n'utilisez pas un outil de gestion de rôles/collections tel que `Ansible Galaxy`)
- un dossier `tasks`, dont vous devez probablement vous douter de l'utilité : il va contenir les tâches. Notez que la structure est légèrement différente d'un playbook, car on supprime le niveau qui contient les `hosts`.
- un dossier `templates`, que vous connaissez déjà : il va contenir les fichiers dynamiques.
- un dossier `vars`, qui est nouveau, et qui va contenir les variables "privées", avec une précédence élevée (au 7ème rang sur 22), et qui ne sont pas censées être modifiées par l'utilisateur (mais qu'il peut tout de même modifier si il le souhaite à travers le mécanisme des [`extra vars`](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#defining-variables-at-runtime)). Comme pour les `defaults`, toutes les variables ont un préfixe (`__` et le nom du rôle), à la fois pour éviter les collisions, mais également pour les distinguer des `defaults` dans les tâches du rôle.

> La précédence détermine l'ordre de priorité des variables. Plus la précédence d'une variable est élevée, plus elle sera prioritaire.

Vous remarquerez que plusieurs de ces dossiers (tous sauf `files` et `templates`, en réalité) ont le point commun de contenir un fichier `main.yml`. Comme en Python, il s'agit d'un mot-clé indiquant qu'en l'absence d'instruction contradictoire, c'est le point d'entrée par défaut du dossier. Ainsi, toutes les variables contenues dans `defaults/main.yml` et `vars/main.yml` seront accessibles lors de l'exécution du rôle, tout comme tous les handlers contenus dans `handlers/main.yml`, et le rôle commencera son exécution par le fichier `tasks/main.yml`.

Parcourez les différents fichiers et lisez les commentaires pour mieux comprendre la structure et le fonctionnement du rôle. Les nouveaux concepts que vous allez y découvrir (soit dans le fichier `tasks/main.yml`, soit dans les fichiers `tasks/configure-*.yml`) sont :
- le module `ansible.builtin.include_vars` : ce module sert à inclure un fichier de variables spécifiques (donc dans le dossier `vars`) pour utiliser les valeurs présentes en son sein. Cela permet utiliser d'autres fichiers de `vars` que `main.yml`. Le nom du fichier est dans notre exemple lui-même une variable afin d'importer uniquement les éléments relatifs à un OS.
- l'utilisation de la variable `ansible_os_family` : cette variable préfixée par `ansible_` ressemble à une `magic variable`, mais vous ne la trouverez pas dans la [liste](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html#magic-variables). Il s'agit en effet d'un concept différent : les `facts`. Ces derniers sont des informations collectées sur les machines lors de l'étape `Gathering facts` au début de chaque play, et qui permettent de mieux adapter le comportement des tâches. Ici, il s'agit de la famille de l'OS, c'est à dire par exemple `RedHat` ou `Debian`. Attention, ce fact est assez proche de `ansible_distribtion`, qui donnera l'OS exact, comme `AlmaLinux` ou `Ubuntu`. N'hésitez pas à vous référer à [la documentation officielle](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_vars_facts.html#ansible-facts).
- le module `ansible.builtin.set_fact` : ce module sert à affecter une valeur à une variable. Ici, il est utilisé pour remodeler des variables dans un format différent.
- le module `ansible.builtin.include_tasks` : ce module fonctionne un peu comme `ansible.builtin.include_vars`, mais pour des fichiers de tâches, qui vont donc être contenus dans le dossier `tasks`.
- le mot-clé `apply` : ce mot-clé, lié à un `ansible.builtin.include_tasks` sert à appliquer une propriété au code qui est inclus. Dans notre cas, l'ensemble des tâches du fichier a besoin d'une élévation de privilèges, on leur applique donc `become: true`.
- le mot-clé `loop` : ce mot-clé sert à boucler sur une liste. Contrairement à `when`, le mot-clé `loop` n'acceptera pas directement le nom d'une variable, il faut l'entourer de `{{ }}`, car il est possible de renseigner une liste ou un dictionnaire manuellement. Dans le cas où la variable n'est pas directement une liste, mais par exemple un dictionnaire, il faut appliquer des filtres comme `dict2items`.
- le mot-clé `no_log` : ce mot-clé sert à ne pas afficher le retour dans Ansible. Il est utile quand ce retour est susceptible de contenir des informations sensibles, mais il complique la tâche en cas d'erreur. C'est donc une bonne idée de le contrôler à l'aide d'une variable.

### Écrire un rôle PostgreSQL

Maintenant que vous avez lu le rôle fourni en exemple, vous allez pouvoir essayer de convertir le playbook du TP 03 en un rôle PostgreSQL. N'essayez pas absolument de reproduire l'ensemble des choses présentes dans le rôle Apache, elles ne sont pas forcément nécessaires dans le cas de PostgreSQL.

Dans les grandes lignes, vous allez au moins utiliser :
- les `defaults`, avec les différentes variables utilisées et des valeurs par défaut (idéalement en poursuivant le concept du "secure by default")
- les `tasks`, avec l'ensemble des tâches qui se trouvent dans le playbook du TP 03
- les `handlers`, avec le handler qui se trouve dans le playbook du TP 03
- et éventuellement les `vars` pour factoriser des valeurs utilisées à plusieurs endroits tel que le chemin vers le répertoire de données PostgreSQL (`/var/lib/pgsql/data`)

Pour finir tout cela, vous pourriez également rajouter des informations dans `meta` pour décrire votre rôle.

> Il ne serait pas choquant que votre rôle n'ait plus aucun tag une fois terminé, bien au contraire : ceux-ci ont plus leur place dans des plays complexes plutôt que dans des rôles.

### Compléter le playbook

Une fois votre rôle complété, ajustez le playbook du TP pour rajouter un play qui va exécuter le rôle PostgreSQL sur le groupe `backend`.

Il est possible, dans un play, d'avoir à la fois le mot-clé `roles`, et le mot-clé `tasks` : les rôles seront exécutés avant les tasks, et les handlers seront tous exécutés ensuite. Si vous avez besoin d'exécuter des tâches avant les rôles, utilisez le mot-clé `pre_tasks`.

> Pour connaître le déroulé exact d'un play, référez vous à la [documentation officielle](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html#using-roles-at-the-play-level)

En sachant cela, ajoutez des tâches sur le frontend, comme dans le TP 03, pour tester le bon fonctionnement de PostgreSQL à partir d'une autre machine.

### Jouer le playbook

Restaurez vos machines virtuelles dans un état vierge avec un snapshot, et lancez le playbook comme d'habitude une première fois, puis une deuxième pour vérifier l'idempotence.

Nous allons maintenant rajouter une étape assez simple, et finalement relativement courante dans la vie d'une machine : redémarrez-les (n'hésitez pas à utiliser une commande `ad-hoc` !).

Une fois le redémarrage terminé, rejouez le playbook par acquis de conscience, et vous allez constater que, sauf si vous avez été très rigoureux lors de son écriture (auquel cas bravo, vous avez anticipé cette partie du TP !), plusieurs tâches sont à l'état `changed` : le démarrage du service et l'ouverture du port sur le firewall.

C'est l'occasion parfaite pour aborder quelques bonnes pratiques et améliorer le rôle que vous venez de créer !

### Améliorer le rôle PostgreSQL

Pour pallier à ce premier problème suite au redémarrage, allez lire la documentation des deux modules impliqués pour trouver et rajouter les paramètres nécessaires à la persistance des configurations.

Ensuite, vous pouvez condenser les tâches qui altèrent la configuration de PostgreSQL en utilisant une loop. Il va vous falloir créer une liste ou un dictionnaire à cet effet.

Si vous vous souvenez, dans le TP 03, nous avons adopté une approche qui n'était pas la meilleure pour choisir d'initialiser ou non PostgreSQL. Il se trouve que le module `ansible.builtin.command` propose des fonctionnalités spécifiques pour faciliter son idempotence : `creates` ou `removes`. Ces mots-clés permettent de conditionner l'exécution de la tâche à la présence ou à l'absence d'un fichier, et de créer ou de supprimer ce dernier une fois la tâche effectuée avec succès. Remplacez la conditionnelle `when` par ce mécanisme.

Pour factoriser le code, il est possible de rassembler plusieurs tâches dans un `block` et d'avoir ainsi une seule condition pour gouverner son exécution, sans pour autant empêcher d'avoir des conditions supplémentaires pour chaque tâche, comme ceci :
```yaml
- name: Ceci est un block
  when: variable_block == 'valeur'
  block:
    - name: Première tâche du block
      ansible.builtin.module:
        parametre: valeur
      when: variable_tache_1 == 'valeur'

    - name: Seconde tâche du block
      ansible.builtin.module:
        parametre: valeur
      when: variable_tache_2 == 'valeur'

- name: Ceci est une autre tâche distincte
  ansible.builtin.module:
    parametre: valeur
  when: variable_block != 'valeur'
```

Vous pourriez ainsi rendre optionnel la création d'un utilisateur et d'une base de données, en fonction de la valeur d'une variable.

> L'utilisation de `block` permet aussi d'apporter une gestion d'erreurs à travers les mots-clés `rescue` et `always`. Vous pouvez en apprendre plus à ce sujet dans la [documentation officielle](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_blocks.html).

Enfin, une dernière astuce : si jamais vous voulez vérifier qu'une variable de `defaults` est définie dans un rôle, vous pourriez être tentés d'utiliser la condition `is defined`. Le problème est que, si cette variable est présente dans le fichier `defaults/main.yml`, y compris avec une valeur vide (par exemple `variable: ` ou `variable: ""`), `is defined` renverra toujours `true`. Privilégiez l'utilisation du filtre `length` comme ceci :
```yaml
- name: Tâche
  ansible.builtin.module:
    parametre: valeur
  when: variable | length > 0
```

### Rejouer le playbook

Comme toujours, rejouez le playbook pour tester et appliquer vos modifications, et une ultime fois pour en tester l'idempotence.

## Conclusion

Félicitations, vous avez maintenant appris à écrire un rôle, à inclure des variables et des tâches, à utiliser les facts, à parcourir des listes, et à factoriser votre code en blocks.

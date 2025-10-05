# TP 01 : Installation d'Ansible et premières commandes

## Introduction

Ce TP a pour but d'apprendre à :
- installer Ansible
- valider le prérequis des clés SSH
- configurer un inventaire
- exécuter des commandes ad-hoc

## Déroulé

### Installer Ansible sur le contrôleur

Afin d'éviter les conflits entre librairies, Python propose un mécanisme appellé `venv` (pour `virtual environment`). Cela permet de disposer d'un environnement relativement isolé que l'on peut altérer et supprimer à loisir.

Pour créer un tel `venv`, on va utiliser la commande suivante :
```bash
python3 -m venv ~/.venv_ansible
```

> Vous pouvez placer le `venv` où vous le voulez, mais adaptez la commande suivante en conséquence

Et pour accéder au `venv`, on va utiliser la commande suivante :
```bash
source ~/.venv_ansible/bin/activate
```

> Notez que le prompt shell change pour indiquer le `venv` dans lequel on se trouve : vérifiez toujours que vous êtes dans le `venv` pour éviter de rencontrer des erreurs telles que `ansible : commande introuvable`

> Vous pouvez rajouter la commande ci-dessous dans votre fichier `~/.bashrc` pour activer automatiquement le `venv` au lancement de votre session

> Si vous souhaitez sortir du `venv` pour une raison ou une autre, tapez simplement la commande `deactivate`

Pour installer Ansible, on va utiliser le gestionnaire de paquets `pip`, avec la commande suivante :
```bash
python3 -m pip install ansible
```

Et on testera la réussite de l'installation avec la commande suivante :
```bash
ansible --version
```

> Il est également possible d'utiliser Ansible avec des conteneurs, qu'on appelle `execution environments`, mais ce n'est pas le sujet de ces TPs. Pour plus d'informations, consultez le [site officiel](https://docs.ansible.com/ansible/latest/getting_started_ee/index.html)

### Copier les clés SSH

Ansible utilise des protocoles standards pour se connecter aux machines distantes. Dans notre cas, vu que l'on cible des machines Unix, c'est SSH qui sera utilisé.

Il est possible de se connecter aux machines avec un nom d'utilisateur et un mot de passe, auquel cas on renseignera la variable `ansible_pass`, mais la méthode privilégiée est d'utiliser des clés SSH.

#### Vérification de l'existence d'une clé

À moins que vous n'ayez créé la machine pour l'occasion, il est vraisemblable qu'une clé SSH existe déjà sur le contrôleur Ansible, ce qu'on peut vérifier avec la commande suivante :
```bash
# Affichage des clés SSH pour l'utilisateur courant
ls -al ~/.ssh
```

> Si plusieurs clés existent, privilégier la clé `id_ed25519`, qui est plus sécurisée que `id_rsa`

#### (optionnel) Création d'une clé

Si une clé n'existe pas déjà, il va falloir la créer avec la commande suivante :
```bash
# Génération d'une clé Ed25519
ssh-keygen -t ed25519 -C "un commentaire pour identifier la clé, par exemple une adresse email"

# Dans ce cas, le nom de la clé SSH pour l'étape de copie devrait être 'id_ed25519'
```

Si la génération de clé échoue, il est vraisemblable que le système d'exploitation du contrôleur soit trop ancien et ne supporte pas l'algorithme Ed25519, et on va donc se rabattre sur une autre commande :
```bash
# Génération d'une clé RSA
ssh-keygen -t rsa -b 4096 -C "un commentaire pour identifier la clé, par exemple une adresse email"

# Dans ce cas, le nom de la clé SSH pour l'étape de copie devrait être 'id_rsa'
```

#### Copie de la clé

Enfin, on va pouvoir copier la clé SSH sur le serveur distant avec la commande suivante :
```bash
# Copie de la clé sur le serveur distant
ssh-copy-id -i ~/.ssh/<NOM_DE_LA_CLÉ_SSH>.pub <NOM_D_UTILISATEUR_DU_SERVEUR_DISTANT>@<NOM_TECHNIQUE_DU_SERVEUR_DISTANT>
```

### Personnaliser l'inventaire

Vous trouverez dans le dossier de ce TP un fichier `inventory.yml`, qui est un exemple de fichier d'inventaire.

> Il est possible de rédiger les inventaires (et uniquement eux) au format INI, mais pour une question d'harmonie, nous n'aborderons ici que le format YAML. Si vous souhaitez plus d'informations, consultez la [documentation officielle](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html#defining-variables-in-ini-format).

Le fichier `inventory.yml` est déjà prérempli avec trois hôtes, pour montrer les différentes façons basiques de déclaration.

Aucune n'est strictement meilleure qu'une autre, cela dépend de votre contexte et de votre façon de faire : il est juste recommandé d'éviter de les mélanger, pour une question de cohérence.

Vous allez pouvoir choisir une de ces méthodes de déclaration et lister vos deux `hôtes` (ainsi que leur utilisateur local) en respectant les instructions des différents commentaires.

> Bien que rien ne l'empêche, l'utilisation de `root` pour établir une connexion à une machine distance est une très mauvaise pratique en général. Ansible propose des mécanismes si des droits administrateur sont nécessaires, que nous verrons dans les prochains TPs.

Supprimez ensuite les autres types de déclarations pour ne pas encombrer le fichier, ce qui risquerait de générer des erreurs à l'exécution.

### Lancer des commandes ad-hoc

Vous remarquerez peut-être que, contrairement à ce qui est évoqué dans la présentation d'Ansible, nous n'avons configuré qu'un inventaire et pas de playbook.

C'est normal, nous allons, pour ce premier TP, nous contenter de ce qu'on appelle les commandes `ad-hoc`. Ces commandes sont des moyens simples d'effectuer des actions unitaires sur les hosts d'un inventaire.

Ansible utilise des `modules` pour effectuer les différentes actions. Ces modules sont codés en Python et vont exécuter du code sur l'hôte distant pour remplir leur fonction. Dans leur grande majorité, ils sont `idempotents` : cela signifie qu'ils vont, avant d'agir, effectuer des vérifications et ne rien faire si le système est déjà dans l'état souhaité. L'idempotence permet ainsi de décrire l'état final à atteindre sur la machine distante, et d'exécuter de façon indiscriminée un playbook sans se soucier de l'état actuel, et de si le playbook a déjà été partiellement ou totalement joué contre cette même machine.

Le nommage complet de ces modules respecte la nomenclature suivante : `<namespace>.<collection>.<module>`. Le namespace représente généralement la société ou le groupe à l'origine de la collection. Les deux plus courants sont `ansible` et `community`. Les collections sont des regroupements thématiques. Il existe par exemple une collection dédiée à la plateforme Azure de Microsoft, une autre dédiée à Google Cloud Platform, et ainsi de suite. De même, les actions de base sur un système sont gérées par l'équipe d'Ansible elle-même, et sont proposées dans une collection spécifique `ansible.builtin`.

Toutes les actions `ad-hoc` que l'on va vouloir effectuer vont utiliser ces `modules` Ansible. Par souci de clarté, on va utiliser le nommage complet de ces modules, aussi appelé FQCN (Fully Qualified Collection Name). Ici, on va vouloir tester la connectivité des hôtes avec le module `ping`. Il s'agit d'un module natif, donc le FQCN commence par 'ansible.builtin.', et on rajoute le nom du module ensuite.

> Si vous voulez la consulter, la documentation du module est disponible sur [le site officiel](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ping_module.html)

On va donc lancer notre première commande ad-hoc comme suit :
```bash
ansible all --inventory inventory.yml --module-name ansible.builtin.ping
```

Et si tout fonctionne bien, on va avoir un retour comme ceci, indiquant que la commande a été un succès :
```bash
serveur_frontend | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": false,
    "ping": "pong"
}

serveur_backend | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": false,
    "ping": "pong"
}
```

Les commandes ad-hoc peuvent également accepter des arguments, avec le flag `--args`. On va lancer la commande `hostname` pour vérifier le nom d'hôte de nos machines :
```bash
ansible all --inventory inventory.yml --module-name ansible.builtin.command --args "hostname"
```

> Comme pour le module `ansible.builtin.ping`, la documentation du module `ansible.builtin.command` est disponible sur [le site officiel](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/command_module.html)

> Si vous ne spécifiez pas de module, c'est `ansible.builtin.command` qui sera utilisé par défaut. Cette instruction est donc strictement égale à `ansible all --inventory inventory.yml --args "hostname"`.

Le retour attendu est du format suivant :
```bash
serveur_frontend | CHANGED | rc=0 >>
frontend

serveur_backend | CHANGED | rc=0 >>
backend
```

Maintenant, nous allons essayer une commande un peu plus complète, qui va mettre en place un fichier sur nos machines :
```bash
ansible all --inventory inventory.yml --module-name ansible.builtin.copy --args "dest=~/fichier content=hello_world"
```

> Le module `ansible.builtin.copy` est un peu plus complexe, nous verrons sa documentation et nous le réutiliserons dans le TP suivant

> Notez que l'on sépare les arguments avec des espaces. Vous pouvez aussi utiliser une syntaxe JSON si vous préférez, mais attention à l'échappement des apostrophes et des guillemets dans ce cas.

Le résultat devrait ressembler à cela :
```bash
serveur_backend | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": true,
    "checksum": "e4ecd6fc11898565af24977e992cea0c9c7b7025",
    "dest": "/home/user/fichier",
    "gid": 1000,
    "group": "user",
    "md5sum": "99b1ff8f11781541f7f89f9bd41c4a17",
    "mode": "0644",
    "owner": "user",
    "secontext": "unconfined_u:object_r:user_home_t:s0",
    "size": 11,
    "src": "/home/user/.ansible/tmp/ansible-tmp-1737400615.981678-2605-56053141201323/.source",
    "state": "file",
    "uid": 1000
}

serveur_frontend | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": true,
    "checksum": "e4ecd6fc11898565af24977e992cea0c9c7b7025",
    "dest": "/home/user/fichier",
    "gid": 1000,
    "group": "user",
    "md5sum": "99b1ff8f11781541f7f89f9bd41c4a17",
    "mode": "0644",
    "owner": "user",
    "secontext": "unconfined_u:object_r:user_home_t:s0",
    "size": 11,
    "src": "/home/user/.ansible/tmp/ansible-tmp-1737400615.9774408-2604-258270598854155/.source",
    "state": "file",
    "uid": 1000
}
```

Vous pouvez vous rendre sur les hôtes et constater la présence du fichier et de son contenu :
```bash
cat ~/fichier
```

Ensuite, nous allons illustrer l'idempotence. Rejouez la dernière commande :
```bash
ansible all --inventory inventory.yml --module-name ansible.builtin.copy --args "dest=~/fichier content=hello_world"
```

Le retour est, assez logiquement, très proche de la première exécution :
```bash
serveur_frontend | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": false,
    "checksum": "e4ecd6fc11898565af24977e992cea0c9c7b7025",
    "dest": "/home/user/fichier",
    "gid": 1000,
    "group": "user",
    "mode": "0644",
    "owner": "user",
    "path": "/home/user/fichier",
    "secontext": "unconfined_u:object_r:user_home_t:s0",
    "size": 11,
    "state": "file",
    "uid": 1000
}

serveur_backend | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": false,
    "checksum": "e4ecd6fc11898565af24977e992cea0c9c7b7025",
    "dest": "/home/user/fichier",
    "gid": 1000,
    "group": "user",
    "mode": "0644",
    "owner": "user",
    "path": "/home/user/fichier",
    "secontext": "unconfined_u:object_r:user_home_t:s0",
    "size": 11,
    "state": "file",
    "uid": 1000
}
```

On peut voir que le résultat de la commande est passé de `CHANGED` à `SUCCESS`, ainsi que la valeur de la clé `changed` qui est passée de `true` à `false`. Cela signifie qu'Ansible n'a pas engagé d'action pour placer ce fichier, car ce dernier était déjà présent sur les hôtes.

> Vous aurez peut-être noté que le module `ansible.builtin.command` renvoyait toujours `CHANGED`, malgré l'absence de changement concret sur les hôtes. Cela est dû à sa conception, et nous verrons plus tard comment adresser ce comportement.

Enfin, par acquis de conscience, supprimons le fichier que nous venons de placer :
```bash
ansible all --inventory inventory.yml --module-name ansible.builtin.file --args "path=~/fichier state=absent"
```

Et le retour nous confirme la bonne suppression du fichier :
```bash
serveur_frontend | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": true,
    "path": "/home/user/fichier",
    "state": "absent"
}

serveur_backend | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": true,
    "path": "/home/user/fichier",
    "state": "absent"
}
```

Et comme après sa création, vous pourrez constater sur les hôtes qu'il a effectivement disparu.

## Conclusion

Félicitations, vous avez maintenant vu les bases d'Ansible, et vous disposez d'un contrôleur, d'un inventaire et de deux hôtes.

Vous savez également comment lancer des commandes ad-hoc simples, qui pourront toujours vous être utiles pour effectuer des actions unitaires simples, telles que récolter des informations (avec le module `ansible.builtin.gather_facts`), installer un package (avec le module `ansible.builtin.package`) ou redémarrer des serveurs (avec le module `ansible.builtin.reboot`). 

> Dans le cas de ces deux commandes, les droits administrateur sont nécessaires, donc il nous faudra faire une élévation de privilège (que nous verrons dans le TP suivant) à l'aide du flag `--become`, et éventuellement du flag `--ask-become-pass`.

Vous pouvez créer maintenant un snapshot de vos machines afin de revenir facilement à cet état stable et configuré au cours des TPs suivants.

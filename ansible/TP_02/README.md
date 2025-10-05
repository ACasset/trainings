# TP 02 : Utiliser un playbook

## Introduction

Ce TP a pour but d'introduire les concepts suivants :
- les variables
- Ansible Vault
- les playbooks
- les plays
- les tasks
- les fichiers statiques

## Prérequis

Ce TP part du principe que vous venez de dérouler le TP 01.

Vous devriez donc déjà avoir à disposition :
- un contrôleur avec Ansible
- deux hôtes distants sur lesquels la clé SSH du contrôleur a été copiée
- un inventaire configuré pour accéder aux hôtes distants

Un des éléments que nous allons utiliser dans ce playbook a besoin d'une librairie Python spécifique pour fonctionner. Vous pouvez l'installer avec votre gestionnaire de paquet favori (`python3-passlib`) ou bien directement avec pip (`passlib`).

## Déroulé

### Compléter l'inventaire

Une des grandes forces d'Ansible est de pouvoir adresser plusieurs machines en parallèle, tout en utilisant des valeurs spécifiques à chacune. Comme dans le TP 01, un inventaire est fourni dans le dossier, mais celui-ci est structuré différemment : lisez les quelques commentaires pour mieux comprendre cette nouvelle structure, mais ne renseignez aucune variable pour l'instant, nous allons le faire au fur et à mesure.

> N'hésitez pas à changer la méthode de déclaration des hôtes si vous le voulez. Comme évoqué dans le TP 01, il n'y a pas de mauvaise méthode.

Cet inventaire comporte quelques trous. Vous savez en principe déjà comment compléter les variables `ansible_user` à la ligne 8, et les FQDN/IPs aux lignes 20 et 30, alors faites-le.

Les variables `nom_utilisateur` aux lignes 17 et 27 sont pré-remplies, mais vous pouvez les modifier à votre convenance. Gardez juste à l'esprit que l'on va créer des utilisateurs Unix avec, donc évitez les caractères spéciaux.

Ensuite, les variables `mot_de_passe_utilisateur` aux lignes 23 et 33 sont un peu plus délicates : il nous faut absolument éviter de mettre en clair des éléments sensibles (des `secrets`) tels qu'un mot de passe dans un fichier YAML, car celui-ci va être typiquement versionné et publiquement accessible sur un dépôt de code.

> En terme de structure, il est légitime que le nom d'utilisateur soit propre à un usage donné (ici, le frontend ou le backend), et donc réutilisé sur plusieurs hôtes. En revanche, le mot de passe doit toujours être unique. Cela explique que le nom d'utilisateur soit placé au niveau du (sous-)groupe, et le mot de passe au niveau de l'hôte.

Heureusement, Ansible propose un outil adapté à l'écriture de secrets dans les inventaires : `ansible-vault`. Cet outil a normalement été installé avec le package d'Ansible. Pour s'en servir, on va pouvoir utiliser la commande suivante :
```bash
ansible-vault encrypt_string
New Vault password: # renseignez le mot de passe de déchiffrement du secret, puis appuyez sur entrée
Confirm New Vault password: # confirmez le mot de passe de déchiffrement du secret, puis appuyez sur entrée
Reading plaintext input from stdin. (ctrl-d to end input)
# renseignez la valeur que vous voulez chiffrer, puis appuyez sur Ctrl et D en même temps
```

`ansible-vault` va chiffrer la valeur avec le mot de passe, et vous restituer un bloc de texte de la forme suivante :
```yaml
!vault |
$ANSIBLE_VAULT;1.1;AES256
38633264363430373862326661383536643532313338303635353565663934393261653363373365
6438393738316466386562383963663866373531343730630a393034373363316639653839663036
37663133363234626235613733623765373662363534313864333761343435363431633334626137
3364633065383265370a333832373966383363353733653738326561663766643330373164653862
3066
```

Ce bloc est à insérer dans l'inventaire, tout en respectant l'indentation du YAML. Voici un exemple :
```yaml
groupe:
  hosts:
    hote:
      variable: !vault |
        $ANSIBLE_VAULT;1.1;AES256
        38633264363430373862326661383536643532313338303635353565663934393261653363373365
        6438393738316466386562383963663866373531343730630a393034373363316639653839663036
        37663133363234626235613733623765373662363534313864333761343435363431633334626137
        3364633065383265370a333832373966383363353733653738326561663766643330373164653862
        3066
```

> Le caractère `|` sert à indiquer que la valeur de la variable s'étale sur plusieurs lignes. Vous pouvez en apprendre plus sur le site [YAML multiline](https://yaml-multiline.info/)

`ansible-vault` possède d'autres capacités que `encrypt_string`. Vous pouvez en apprendre plus sur [le site officiel](https://docs.ansible.com/ansible/latest/vault_guide/index.html).

> Attention, si vous vous servez d'Ansible Vault pour chiffrer un fichier (avec la commande `ansible-vault encrypt`), l'ensemble du fichier est contenu dans le bloc de texte restitué, y compris les retours à la ligne en fin de fichier. Cela peut poser des problèmes dans certains cas. Si vous rencontrez des difficultés avec des valeurs chiffrées, essayez plutôt de les chiffrer avec `encrypt_string`.

Vous allez maintenant pouvoir renseigner la valeur de la variable `mot_de_passe_utilisateur` avec la valeur chiffrée par `ansible-vault`.

> Pour l'instant, utilisez la même clé de chiffrement Ansible Vault pour l'ensemble des secrets. Il est possible d'utiliser des mots de passe différents, mais il faudra utiliser ce qu'Ansible Vault appelle des `namespaces`, qui ne font pas partie du périmètre de ce TP.

Enfin, ce TP utilise également l'élévation de privilèges (via le mot-clé `become`) pour effectuer temporairement des actions avec les droits administrateur sur les hôtes. La condition nécessaire est que l'utilisateur avec lequel Ansible se connecte doit avoir les droits `sudo`. ll existe ensuite deux approches possibles pour l'authentification :
- appliquer le flag `NOPASSWD` à l'utilisateur, de façon à ce qu'il ne soit pas nécessaire de s'authentifier lors de l'élévation de privilèges
- rajouter une nouvelle variable `ansible_become_password` dans l'inventaire, qui correspond au mot de passe pour l'élévation de privilèges

En fonction de votre situation, la première solution sera peut-être satisfaisante, mais dans l'intérêt des bonnes pratiques en matière de sécurité, nous privilégierons la seconde approche.

Vous allez donc également pouvoir chiffrer le mot de passe pour l'élévation de privilèges avec Ansible Vault, et le renseigner dans les variables `ansible_become_password` aux lignes 22 et 32. Sauf exception, ce mot de passe est celui de l'utilisateur avec lequel Ansible se connecte aux machines, et ceci bien qu'Ansible utilise une clé SSH pour se connecter.

> Comme pour `mot_de_passe_utilisateur`, la bonne pratique étant que les mots de passe soient uniques par machine, cette variable est donc positionnée au niveau des hôtes.

### Jouer le playbook

Comme vu dans le TP 01, Ansible peut utiliser des commandes `ad-hoc` pour effectuer des actions unitaires. Mais si l'on veut enchaîner des actions avec une certaine logique, on va devoir écrire ce qu'on appelle des `playbooks`. Ces fichiers, écrits en YAML, peuvent contenir un ou plusieurs `plays`. Chaque `play` est un ensemble d'instructions, appelées des `tasks`, qui vont cibler une ou plusieurs machines en particulier.

Dans un premier temps, nous allons juste exécuter le playbook sans le modifier.

Lorsque l'on veut exécuter un playbook, on va utiliser la commande `ansible-playbook`, en spécifiant le chemin vers le playbook, et l'inventaire comme pour les commandes ad-hoc (avec l'argument `--inventory`). De plus, comme certaines variables sont chiffrées, il faut rajouter l'argument `--ask-vault-pass` pour qu'Ansible nous demande la clé de déchiffrement au lancement :
```bash
ansible-playbook playbook.yml --inventory inventory.yml --ask-vault-pass
Vault password: # renseignez le mot de passe de déchiffrement du secret, puis appuyez sur entrée
```

Le playbook va effectuer les actions suivantes :
- connexion à l'hôte distant avec la clé SSH préalablement copiée
- récupération des informations de l'hôte (ce qu'on verra sous le nom 'Gathering Facts')
- exécution des différentes tasks du playbook dans l'ordre :
  - création d'un utilisateur
  - dépot d'un fichier `.bash_aliases` dans le répertoire home de l'utilisateur

Le playbook utilise plusieurs variables. D'abord, de façon transparente, toutes les variables qui commencent par `ansible_`, telles que `ansible_user` et `ansible_become_password`; et également des variables définies explicitement dans les tâches : `nom_utilisateur` et `mot_de_passe_utilisateur`.

La valeur de chacune de ces variables va ainsi pouvoir varier en fonction de son contexte : `ansible_user` étant défini au niveau du groupe racine `all`, sa valeur sera la même pour toutes les machines. En revanche, `nom_utilisateur` sera différent selon que la machine fait partie du groupe `frontend` ou du groupe `backend`. Et, enfin, `ansible_become_password` et `mot_de_passe_utilisateur` seront unique pour chaque hôte.

> Des variables peuvent être déclarées plusieurs fois, et Ansible va appliquer une règle de précédence pour savoir laquelle utiliser. Vous pouvez retrouver cette règle dans la [documentation officielle](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#understanding-variable-precedence).

De plus, le playbook va, avec le module `ansible.builtin.copy`, chercher le fichier indiqué dans le paramètre `src` dans son répertoire `files`. Cela permet de stocker à part des fichiers statiques sans encombrer le code du playbook lui-même.

> Il n'y a pas vraiment de limite de lignes pour ces fichiers, il peuvent même être des archives ou des binaires. Cependant, gardez à l'esprit que votre code Ansible devrait être versionné sur Git, et que bien que Git supporte de stocker de gros fichiers binaires (notamment avec Git LFS), ce n'est pas un usage adapté à tous les environnements. Si vous en avez la possibilité, il vaut mieux utiliser un dépôt de binaires dédié et récupérer ces binaires à travers l'API du dépôt de binaires et avec le module `ansible.builtin.get_url`.

À la fin de l'exécution, Ansible affiche un résumé de son exécution : on peut alors savoir d'un coup d'œil le nombre de tasks exécutées/ignorées/échouées par hôte. Vous devriez en principe voir une mention `changed=3` pour chaque hôte : cela signifie que trois tâches ont modifié des éléments sur ces hôtes.

Une fois l'exécution terminée, connectez-vous sur un des deux hôtes avec l'utilisateur nouvellement créé (vérifiez dans l'inventaire quel utilisateur est associé à quel hôte) pour confirmer que ce dernier fonctionne et que le playbook s'est bien déroulé.

Si vous faites un `ls` (qui a été redéfini par le fichier d'aliases) pour constater la présence du fichier que le playbook a déposé, vous devriez vous rendre compte que le fichier `.bash_aliases` appartient à l'utilisateur et au groupe `root`. C'est l'élévation de privilège qui provoque cela, et c'est un mécanisme qu'il faudra garder à l'esprit lorsqu'on utilise le `become`. Cela n'est pas bloquant en soi, car le fichier a des droits `644` par défaut, donc notre utilisateur peut le lire, mais ce n'est pas très propre.

D'autre part, si vous tapêz l'alias `ports`, vous devriez avoir une erreur indiquant que la commande `netstat` n'a pas été trouvée.

Nous allons maintenant corriger ces deux problèmes.

### Compléter le playbook

#### Correction des droits du fichier d'aliases

Pour cette correction, il va falloir aller consulter la [documentation officielle pour le module `ansible.builtin.copy`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html), et ajouter les paramètres nécessaires pour spécifier la propriété du fichier `.bash_aliases` : `owner`, `group` et `mode`. Utilisez à nouveau la variable `nom_utilisateur` pour que la valeur soit adaptée à l'hôte sur lequel le playbook s'exécutera.

> Faites attention au format du paramètre `mode`, celui-ci est au format octal et est donc un peu particulier.

De façon générale, dès que vous rencontrez un nouveau module, rendez-vous sur sa page de documentation pour en comprendre le fonctionnement. N'hésitez pas à descendre tout en bas : la documentation contient presque toujours de multiples exemples très utiles à la compréhension.

#### Correction de l'absence du binaire netstat

Pour cette correction, il va falloir rajouter une nouvelle tâche toute entière, avec le module `ansible.builtin.package`. Consultez [sa documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/package_module.html), et rajoutez une tâche en faisant attention à l'indentation et en lui donnant un nom explicite.

> Le paquet qui contient `netstat` s'appelle `net-tools`

### Rejouer le playbook

Une fois le playbook complété, vous pouvez rejouer son exécution avec la même commande que précédemment. 

On a alors deux possibilités :
- si l'exécution est réussie, vous devriez voir un `changed=2`, indiquant que deux actions ont effectivement eu lieu (la correction des droits sur le fichier d'aliases, et l'installation de netstat). En remontant les logs de l'exécution, on va voir que la tâche `Création de l'utilisateur` et `Import du fichier d'aliases bash au login` sont en état `ok`. Cela signifie concrètement qu'aucune action n'a eu lieu pour ces deux tâches, car la machine étatit déjà dans l'état désiré. La copie du fichier et l'installation de netstat, en revanche, ont bien procédé à des modifications sur la machine.
- si l'exécution a échoué, on va voir un `failed=`. En remontant les logs de l'exécution, l'erreur va être détaillée. Corrigez-la et relancez une fois de plus le playbook. Les erreurs les plus probables sont :
  - `chown failed: failed to look up user nom_utilisateur` car vous avez vraisemblablement mal déclaré la valeur de `owner` ou `group` : il faut que ce soit une variable, donc entourer `nom_utilisateur` avec des accolades.
  - `ERROR! We were unable to read either as JSON nor YAML` car vous avez vraisemblablement oublié les guillemets autour d'une déclaration de variable. Si une valeur commence par `{{`, il faut impérativement mettre des guillemets autour.
  - `This command has to be run under the root user.` car vous avez oublié de préciser `become: true` sur l'installation de netstat
  - `Unsupported parameters for (xxx) module` car vous avez fait une faute de frappe sur un des paramètres que vous avez rajouté. Or, Ansible n'accepte pas les clés inconnues. Relisez la documentation du module pour identifier et corriger la faute de frappe.

> Les messages d'erreur Ansible sont présentés sous différentes formes en fonction de l'origine de l'erreur. Si l'erreur advient sur le contrôleur, elle est générée par Ansible lui-même, et on aura un message assez court et explicite (exemple: `FAILED! => {"changed": false, "msg": "dest is required"}`). Si l'erreur advient sur l'hôte distant, c'est souvent le système d'exploitation qui la remonte, et Ansible la restitue telle quelle, avec parfois beaucoup de contenu et une langue différente.

> Si l'exécution échoue avec une autre erreur, vous pouvez 1° essayer de comprendre et de résoudre l'erreur, si celle-ci est assez explicite (ce n'est pas toujours le cas avec Ansible) ; 2° restaurer les fichiers avec Git et recommencer à dérouler le TP, c'est peut-être une faute de frappe ou d'indentation ; ou 3° contacter un ingénieur DevOps autour de vous pour avoir de l'aide.

Il est également possible que le playbook se déroule correctement, mais que l'état final soit incorrect car vous avez renseigné des paramètres valides pour Ansible, mais incorrects pour le but recherché. Deux exemples typiques sont :
- déclarer le `mode` au format `644` lors de la copie d'un fichier : le fichier aura alors des droits incohérents comme `--w----r-T.`.
- oublier le filtre `password_hash` lors de la création d'un utilisateur : le mot de passe sera alors invalide et vous ne pourrez pas vous connecter
Lisez bien la documentation des modules et des paramètres que vous utilisez pour anticiper un format spécifique !

### Vérifier l'idempotence

Enfin, nous allons rejouer une toute dernière fois le playbook pour démontrer l'idempotence : vous devriez cette fois voir `changed=0` dans le résumé de l'exécution, indiquant que le système était déjà dans l'état désiré pour l'ensemble des tâches, et qu'aucune modification n'a donc eu lieu.

## Conclusion

Félicitations, vous avez maintenant exécuté et complété votre premier playbook, en utilisant un inventaire structuré en plusieurs groupes.

Vous avez également vu l'utilisation de fichiers statiques, des variables, et du chiffrement de ces dernières lorsqu'elles sont sensibles.

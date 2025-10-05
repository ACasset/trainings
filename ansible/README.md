# Introduction

L'ensemble de ces TPs a pour but d'initier un DevOps à Ansible.

## Qu'est ce qu'Ansible ?

Ansible est un outil d'automatisation de déploiement. Son but est d'effectuer des actions parallèlement sur plusieurs (dizaines ou centaines de) machines. Une de ses principales forces par rapport à ses concurrents est son côté 'agentless' : il n'a en effet besoin d'aucune installation préalable sur les machines que vous souhaitez adresser, il suffit simplement de pouvoir les contacter (par exemple en SSH pour les machines Unix).

Ansible se caractérise par la recherche d'un état final : contrairement à un script, on ne va pas écrire une commande d'installation qui sera systématiquement exécutée, mais plutôt déclarer que l'on veut que le package 'x' soit installé. Ansible vérifiera tout seul la présence du package : si celui-ci est déjà installé, rien ne se passera; et si au contraire il est absent, Ansible l'installera. Ce mécanisme s'appelle l'`idempotence`, et on cherchera idéalement à toujours l'atteindre.

Ansible va utiliser principalement deux types de fichiers, tous les deux pouvant être écrits en YAML :
- des `inventaires`, qui vont représenter les différentes machines de votre parc, et leur associer différentes variables
- des `playbooks`, qui vont lister l'ensemble des actions à effectuer sur les machines de l'inventaire, en utilisant les variables pour adapter le comportement des actions en question

> Si vous ne connaissez pas le YAML, il s'agit d'un langage descriptif. La principale règle à retenir est que, comme par exemple Python, les différents blocs sont identifiés via leur indentation. Cette indentation est EXCLUSIVEMENT composée d'espaces, jamais de tabulations. Peu importe que vous mettiez 2, 4 ou 8 espaces, tant que la structure du fichier est cohérente. Si vous avez besoin d'un guide, vous pourrez en trouver un dans [la documentation officielle](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html).

# Prérequis

Cette série de TPs va introduire progressivement les concepts d'Ansible, mais nous allons avoir besoin de plusieurs éléments pour cela.

## Le contrôleur

Le contrôleur est la machine sur laquelle Ansible va être installé et sur laquelle vont être stockés l'inventaire et le playbook.

Le contrôleur doit nécessairement être un système Unix. Si vous utilisez Windows, il vous faudra donc utiliser WSL ou installer une machine virtuelle (locale ou distante). Assurez-vous que le contrôleur est connecté soit à Internet, soit à un dépôt de binaires qui contient Ansible et toutes ses dépendances.

> Il n'y a pas réellement d'exigences de ressources, il faut juste que Python 3 soit installé (ce qui est le cas de la quasi-totalité des distributions Unix).

## Les hôtes

Ensuite, nous allons effectuer nos déploiements sur deux machines différentes (des `hôtes` ou `hosts` dans la terminologie Ansible). Là aussi, nous allons privilégier Unix. Vous êtes libres d'utiliser les machines que vous souhaitez (postes physiques, machines virtuelles, VPS, etc.) avec votre OS (Unix) préféré (Ubuntu, Debian, RHEL, etc.), mais par souci de simplicité, je vous suggère de privilégier des machines virtuelles locales (dont vous ferez un snapshot une fois l'installation terminée pour pouvoir revenir facilement à un état de base), avec un OS AlmaLinux 9 en version anglaise (les solutions des TPs seront faites pour cet OS spécifique).

> Les machines n'ont pas besoin d'être très puissantes : si on se contente d'un OS en version 'minimale' (comme si c'était un vrai serveur, donc), 1 CPU et 2 Go de RAM devraient suffire.

L'utilisateur qu'Ansible va utiliser pour se connecter aux machines doit avoir les droits `sudo`. Le moyen le plus simple pour y parvenir est d'ajouter l'utilisateur au groupe adéquat. Sur un OS à base RHEL (donc incluant AlmaLinux et CentOS), la commande est `usermod -aG wheel <utilisateur>`. Sur un OS à base Debian (donc incluant Ubuntu), la commande est `usermod -aG sudo <utilisateur>`.

# Les TPs

Chaque TP est conçu pour introduire un nombre limité de concepts afin de ne pas vous surcharger d'informations.

## TP 01 : Installation d'Ansible et premières commandes

[Ce TP](TP_01) a pour but d'apprendre à :
- installer Ansible
- valider le prérequis des clés SSH
- configurer un inventaire
- exécuter des commandes ad-hoc

## TP 02 : Utiliser un playbook

[Ce TP](TP_02) a pour but d'introduire les concepts suivants :
- les variables
- Ansible Vault
- les playbooks
- les plays
- les tasks
- les fichiers statiques

## TP 03 : Différencier et contrôler l'exécution d'un playbook

[Ce TP](TP_03) a pour but d'introduire les concepts suivants :
- les templates
- les magic variables
- les handlers
- les filters
- les register
- les conditionnelles
- les tags

## TP 04 : Utiliser un rôle

[Ce TP](TP_04) a pour but d'introduire les concepts suivants :
- les roles
- les imports/includes
- les facts
- les loops
- les blocks

## TP 05 : Synthèse

[Ce TP](TP_05) a pour but de réutiliser l'ensemble des connaissances acquises pour écrire un rôle de zéro.

# Pour aller plus loin

Pour aller plus loin, vous pouvez vous renseigner sur les sujets suivants :
- le module [`ansible.builtin.meta`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/meta_module.html), qui permet de provoquer des actions "spéciales" d'Ansible
- le module [`ansible.builtin.assert`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/assert_module.html), qui permet de vérifier des conditions et d'afficher un message en fonction de leur résultat
- le module [`ansible.builtin.fail`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fail_module.html), qui permet d'interrompre un play avec un message particulier
- le fichier [`ansible.cfg`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html), qui permet de modifier la configuration d'Ansible
- la structuration des inventaires en dossiers, qui permet de [scinder ses inventaires en plusieurs fichiers](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html#organizing-inventory-in-a-directory), ou de [reproduire la structure des groupes dans un système de fichiers](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html#organizing-host-and-group-variables)
- les instructions [`rescue` et `always`](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_blocks.html#handling-errors-with-blocks), qui permettent de gérer les erreurs dans les `blocks`
- les [`lookups`](https://docs.ansible.com/ansible/latest/plugins/lookup.html), qui permettent de récupérer des informations de sources variées, et dont [la liste exhaustive](https://docs.ansible.com/ansible/latest/collections/index_lookup.html) est présente dans la documentation officielle
- [`Molecule`](https://ansible.readthedocs.io/projects/molecule/), qui permet de créer des tests automatisés pour des rôles Ansible
- le mot-clé [`async`](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_async.html), qui permet de jouer des tâches de façon asynchrone
- le mode [`check`](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_checkmode.html), qui permet de simuler l'exécution d'un playbook
- le mot-clé [`delegate_to`](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_delegation.html), qui permet de modifier ponctuellement la machine sur laquelle le code Ansible s'exécute
- les [`prompts`](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_prompts.html), qui permettent de récupérer des informations de façon interactive avec l'utilisateur au début de l'exécution d'un playbook
- les mots-clés [`start-at-task` et `step`](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_startnstep.html), qui permettent de commencer un playbook à une tâche donnée, et de jouer un playbook de façon interactive
- le [`debugger`](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_debugger.html), à ne pas confondre avec le module `ansible.builtin.debug`, qui permet d'interrompre l'exécution d'un playbook et de corriger les erreurs à la volée
- les spécificités du [`fonctionnement d'Ansible avec Windows`](https://docs.ansible.com/ansible/latest/os_guide/windows_usage.html), et le module [`ansible.windows`](https://docs.ansible.com/ansible/latest/collections/ansible/windows/index.html), pour adresser des machines Windows avec Ansible
- les [ancres YAML](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_advanced_syntax.html#yaml-anchors-and-aliases-sharing-variable-values) qui permettent de réutiliser des valeurs déjà définies dans un inventaire

# Crédits

- Boussad A., Julien B., Baptiste M., Romain P. pour leur relecture et leurs retours
- [Jeff Geerling](https://github.com/geerlingguy/) pour son [rôle Apache](https://github.com/geerlingguy/ansible-role-apache) dont je me suis largement inspiré dans le TP 04
- GitHub Copilot (GPT 4o) pour sa description de quelques concepts sur lesquels ma prose ne m'apportait pas satisfaction

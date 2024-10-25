#!/bin/bash

# Variables
liste_utilisateur="utilisateurs.txt"

# Fonction d'ajout ou modification d'utilisateur
ajouter_modifier_utilisateur(){
    local utilisateur=$1 # $1 est le premier argument passé à la fonction, local permet est visible que dans la fonction.
    local groupe=$2
    local shell=$3
    local repertoire=$4

    if id "$utilisateur" &>/dev/null; then # qu’il s’agisse d’un résultat ou d’une erreur, ne sera pas affiché et sera “jeté” dans /dev/null.
        echo "L'utilisateur $utilisateur existe déjà. Modification des informations."
        sudo usermod -g "$groupe" -s "$shell" -d "$repertoire" "$utilisateur" &>/dev/null;
        if [ $? -eq 0 ]; then #si la fonction usermod a réussi, le code de retour sera 0.
            echo "Les informations de l'utilisateur $utilisateur ont bien été modifiées."
        else
            echo "Une erreur est survenue lors de la modification des informations de l'utilisateur $utilisateur."
        fi
    else
        echo "Ajout de l'utilisateur $utilisateur."
        sudo useradd -g "$groupe" -s "$shell" -d "$repertoire" -m "$utilisateur"
        if [ $? -eq 0 ]; then
            echo "L'utilisateur $utilisateur a été ajouté avec succès."
        else
            echo "Echec de l'ajout de l'utilisateur $utilisateur."
        fi

        mot_de_passe=$(openssl rand -base64 12) #openssl est une commande qui permet de générer des mots de passe aléatoires. rand = octet aléatoire et -base64 = encodage(maj minuscule etc) de 12 caractères.
        echo "Nom d'utilisateur : $utilisateur | Mot de passe : $mot_de_passe"
        echo "$utilisateur:$mot_de_passe" | sudo chpasswd #chpasswd permet de changer le mot de passe d'un utilisateur.
        sudo chage -d 0 "$utilisateur" #permet de forcer l'utilisateur à changer son mot de passe lors de sa prochaine connexion.
        echo "L'utilisateur $utilisateur devra définir un nouveau mot de passe lors de sa prochaine connexion."
    fi

}

# Fonction de gestion des utilisateurs inactifs
backup_home_directory() {  #fonction pour sauvegarder le répertoire personnel de l'utilisateur avant de le supprimer. 
    user=$1 # $1 est le premier argument car c'est le nom de l'utilisateur dans passwd
    if [ ! -d "/backup" ]; then # ! -d permet de vérifier si le répertoire n'existe pas.
        sudo mkdir /backup
        echo "Répertoire de sauvegarde /backup créé."
    fi
    
    if [ -d "/home/$user" ]; then # -d permet de vérifier si le répertoire existe.
        echo "Sauvegarde du répertoire personnel de l'utilisateur $user..."
        tar -czf "/backup/$user-home-$(date +%Y%m%d).tar.gz" "/home/$user" #tar permet de compresser des fichiers et répertoires, -c pour créer une archive, -z pour compresser avec gzip, -f pour spécifier le nom du fichier d'archive.
        echo "Sauvegarde terminée : /backup/$user-home-$(date +%Y%m%d).tar.gz"
    else
        echo "Répertoire personnel de l'utilisateur $user introuvable."
    fi
}
gestion_user_inactif(){
    inactive_users=$(lastlog | grep "Never logged in" | awk '{print $1}') #lastlog permet d'afficher les informations de connexion des utilisateurs, -b 0 pour afficher les utilisateurs qui ne se sont jamais connectés, grep pour filtrer les utilisateurs qui ne se sont jamais connectés, awk pour afficher le nom de l'utilisateur.
    for user in $inactive_users; do
        echo "L'utilisateur $user ne s'est jamais connecté."
    echo "ALERTE : L'utilisateur $user est inactif."

        # Proposer des options à l'administrateur
        echo "Que souhaitez-vous faire avec le compte de $user ?"
        echo "1) Verrouiller le compte"
        echo "2) Supprimer le compte"
        echo "3) Ne rien faire"
        read -p "Entrez votre choix (1, 2, 3) : " choice

        case $choice in
            1)
                # Verrouiller le compte
                sudo usermod -L $user #-L pour verrouiller le compte
                echo "Le compte de l'utilisateur $user a été verrouillé."
                ;;
            2)
                # Sauvegarder le répertoire personnel avant suppression
                backup_home_directory $user

                # Supprimer le compte
                sudo userdel $user
                echo "Le compte de l'utilisateur $user a été supprimé."
                ;;
            3)
                echo "Aucune action n'a été effectuée pour $user."
                ;;
            *)
                echo "Choix invalide. Aucune action n'a été effectuée pour $user."
                ;;
        esac
    done
}

# Fonctions de gestion des groupes
creer_groupe() {
    # Demander à l'utilisateur d'entrer un nom de groupe
    echo "Entrez le nom du groupe à créer :"
    read groupe

    # Vérifier si le groupe existe déjà
    if getent group "$groupe" &> /dev/null; then  #getent interroge des bases de données administratives (comme les groupes, les utilisateurs, etc.).
        echo "Le groupe $groupe existe déjà."
    else
        sudo groupadd "$groupe"
        if [ $? -eq 0 ]; then  #Après la tentative de création du groupe, cette condition vérifie si la commande précédente (groupadd) a réussi. Le code $? contient le code de retour de la dernière commande exécutée. Si ce code est égal à 0 (-eq 0), cela signifie que la commande a réussi.

            echo "Le groupe $groupe a été créé avec succès."
        else
            echo "Erreur lors de la création du groupe $groupe."
        fi
    fi
}

# Fonction pour ajouter un utilisateur à un groupe
ajouter_utilisateur_groupe() {
    # Demander le nom de l'utilisateur et du groupe
    echo "Entrez le nom de l'utilisateur à ajouter :"
    read utilisateur
    echo "Entrez le nom du groupe auquel l'ajouter :"
    read groupe

    # Vérifier si l'utilisateur existe, puis l'ajouter au groupe
    if id "$utilisateur" &>/dev/null; then
        sudo usermod -a -G "$groupe" "$utilisateur" # usermod(modifier les informations d'un utilisateur sur un système) -a (ajouter) -G (groupe)
        echo "L'utilisateur $utilisateur a été ajouté au groupe $groupe."
    else
        echo "L'utilisateur $utilisateur n'existe pas."
    fi
}

# Fonction pour retirer un utilisateur d'un groupe
retirer_utilisateur_groupe() {
    # Demander le nom de l'utilisateur et du groupe
    echo "Entrez le nom de l'utilisateur à retirer :"
    read utilisateur
    echo "Entrez le nom du groupe duquel le retirer :"
    read groupe

    # Vérifier si l'utilisateur existe, puis le retirer du groupe
    if id "$utilisateur" &>/dev/null; then
        sudo gpasswd -d "$utilisateur" "$groupe" #gpasswd permet de gérer les groupes, -d pour supprimer l'utilisateur du groupe.
        echo "L'utilisateur $utilisateur a été retiré du groupe $groupe."
    else
        echo "L'utilisateur $utilisateur n'existe pas."
    fi
}

# Fonction pour supprimer un groupe vide
supprimer_groupe() {
    # Demander le nom du groupe à supprimer
    echo "Entrez le nom du groupe à supprimer :"
    read groupe

# Vérifier si le groupe existe et s'il est vide, puis le supprimer
if getent group "$groupe" > /dev/null 2>&1; then
    gid=$(getent group "$groupe" | cut -d: -f3)  # Récupérer le GID du groupe
    if [ -z "$(getent passwd | awk -F: -v gid="$gid" '$4 == gid')" ]; then #awk est un outil de traitement de texte qui permet de rechercher et de remplacer des données dans un fichier texte. -v pour définir une variable.
        sudo groupdel "$groupe"
        echo "Le groupe $groupe a été supprimé car il est vide."
    else
        echo "Le groupe $groupe contient encore des utilisateurs."
    fi
else
    echo "Le groupe $groupe n'existe pas."
fi
}

# Partie 4

# Fonction pour gérer les ACL sur des répertoires partagés
#ACL acces control list pour permission avancés
gerer_acl() {
    echo "Entrez le répertoire pour lequel vous souhaitez configurer les ACL :"
    read repertoire

    # Vérifier si le répertoire existe
    if [ -d "$repertoire" ]; then #L’option -d dans Bash est utilisée pour vérifier si un chemin donné correspond à un répertoire.
        echo "1. Ajouter une ACL pour un utilisateur ou un groupe"
        echo "2. Supprimer une ACL pour un utilisateur ou un groupe"
        echo "3. Afficher les ACL actuelles"
        read -p "Choisissez une option (1-3) : " choix_acl

        case $choix_acl in
            1)
                echo "Voulez-vous ajouter une ACL pour un utilisateur ou un groupe ? (u/g)"
                read type_entite
                echo "Entrez le nom de l'utilisateur ou du groupe :"
                read entite
                echo "Entrez les permissions (r pour lecture, w pour écriture, x pour exécution) :"
                read permissions

                if [[ "$type_entite" == "u" ]]; then
                    sudo setfacl -m u:$entite:$permissions "$repertoire" #setfacl permet de définir les permissions ACL, -m pour modifier les permissions.
                    echo "Les permissions ACL ont été appliquées à l'utilisateur $entite pour le répertoire $repertoire."
                elif [[ "$type_entite" == "g" ]]; then
                    sudo setfacl -m g:$entite:$permissions "$repertoire"
                    echo "Les permissions ACL ont été appliquées au groupe $entite pour le répertoire $repertoire."
                else
                    echo "Type d'entité non valide, veuillez choisir 'u' pour utilisateur ou 'g' pour groupe."
                fi
                ;;
            2)
                echo "Voulez-vous supprimer une ACL pour un utilisateur ou un groupe ? (u/g)"
                read type_entite
                echo "Entrez le nom de l'utilisateur ou du groupe :"
                read entite

                if [[ "$type_entite" == "u" ]]; then
                    sudo setfacl -x u:$entite "$repertoire" # -x pour supprimer les permissions ACL.
                    echo "Les permissions ACL pour l'utilisateur $entite ont été supprimées."
                elif [[ "$type_entite" == "g" ]]; then
                    sudo setfacl -x g:$entite "$repertoire"
                    echo "Les permissions ACL pour le groupe $entite ont été supprimées."
                else
                    echo "Type d'entité non valide, veuillez choisir 'u' pour utilisateur ou 'g' pour groupe."
                fi
                ;;
            3)
                sudo getfacl "$repertoire"
                ;;
            *)
                echo "Option non valide."
                ;;
        esac
    else
        echo "Le répertoire spécifié n'existe pas."
    fi
}

# Fonction pour appliquer des ACL par défaut sur les fichiers créés dans un répertoire
appliquer_acl_defaut() {
    echo "Entrez le répertoire pour lequel vous souhaitez appliquer des ACL par défaut :"
    read repertoire

    if [ -d "$repertoire" ]; then
        echo "Voulez-vous appliquer des ACL par défaut pour un utilisateur ou un groupe ? (u/g)"
        read type_entite
        echo "Entrez le nom de l'utilisateur ou du groupe :"
        read entite
        echo "Entrez les permissions par défaut (r pour lecture, w pour écriture, x pour exécution) :"
        read permissions

        if [[ "$type_entite" == "u" ]]; then
            sudo setfacl -d -m u:$entite:$permissions "$repertoire" # -d pour les ACL par défaut.
            echo "Les ACL par défaut ont été appliquées à l'utilisateur $entite pour le répertoire $repertoire."
        elif [[ "$type_entite" == "g" ]]; then
            sudo setfacl -d -m g:$entite:$permissions "$repertoire"
            echo "Les ACL par défaut ont été appliquées au groupe $entite pour le répertoire $repertoire."
        else
            echo "Type d'entité non valide, veuillez choisir 'u' pour utilisateur ou 'g' pour groupe."
        fi
    else
        echo "Le répertoire spécifié n'existe pas."
    fi
}

# Menu principal
echo "Gestion des utilisateurs et des groupes"
echo "1. Ajouter ou modifier un utilisateur"
echo "2. Gérer les utilisateurs inactifs"
echo "3. Créer un groupe"
echo "4. Ajouter un utilisateur à un groupe"
echo "5. Retirer un utilisateur d'un groupe"
echo "6. Supprimer un groupe"
echo "7. Configurer les ACL sur un répertoire"
echo "8. Appliquer des ACL par défaut pour les nouveaux fichiers"
echo "9. Quitter"
read -p "Choisissez une option (1-9) : " choix

case $choix in
    1)
        while IFS=":" read -r utilisateur groupe shell repertoire; do #IFS variable qui va séparer les mots dans les chaines de textes avec des :, read -r pour lire le fichier ligne par ligne.
            ajouter_modifier_utilisateur "$utilisateur" "$groupe" "$shell" "$repertoire"
        done < "$liste_utilisateur"
        ;;
    2)
        gestion_user_inactif
        ;;
    3)
        creer_groupe
        ;;
    4)
        ajouter_utilisateur_groupe
        ;;
    5)
        retirer_utilisateur_groupe
        ;;
    6)
        supprimer_groupe
        ;;
        
    7)
        gerer_acl
        ;;
    8)
        appliquer_acl_defaut
        ;;
    9)
        echo "Quitter..."
        exit 0
        ;;
    *)
        echo "Option non valide"
        ;;
esac



#! /bin/bash
#Prérequis :
# - nmap
# - xsltproc
# - être en root

#Déclaration des variables de couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#Déclaration des variables
BOLD='\e[1m'
NORMAL='\e[0m'
DATE=$(date '+%Y-%m-%d')

#Définition des fonctions
fonction_prerequis_scan() {
    #Vérifier si Nmap et Xsltproc sont installé
    dpkg -s nmap &>/dev/null
    echo ""
    echo -e "${BOLD}Etat des paquets à installer : "
    echo ""
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Nmap est installé !!!${NC}"
    else
        echo -e "${RED}Nmap n'est pas installé !!!${NC}"
        sudo apt install nmap -y &>/dev/null
    fi

    dpkg -s xsltproc &>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}xsltproc est installé !!!${NC}"
    else
        echo -e "${RED}xsltproc n'est pas installé !!!${NC}"
        sudo apt install xsltproc -y &>/dev/null
    fi
}

fonction_menu() {

    echo -e "${BOLD} __  ____     __   _____ _    _  ____ _____ _____ ______ ${NORMAL}"
    echo -e "${BOLD}|  \/  \ \   / /  / ____| |  | |/ __ \_   _/ ____|  ____|${NORMAL}"
    echo -e "${BOLD}| \  / |\ \_/ /  | |    | |__| | |  | || || |    | |__   ${NORMAL}"
    echo -e "${BOLD}| |\/| | \   /   | |    |  __  | |  | || || |    |  __|  ${NORMAL}"
    echo -e "${BOLD}| |  | |  | |    | |____| |  | | |__| || || |____| |____ ${NORMAL}"
    echo -e "${BOLD}|_|  |_|  |_|     \_____|_|  |_|\____/_____\_____|______|${NORMAL}"
    echo ""
    echo ""

    echo -e "Pentest d'une IP ou d'un domaine               [1]"
    echo -e "Pentest de mon réseau                          [2]"
    echo -e "Scan de l'arborescence d'un site web avec Dirb [3]"
    echo -e "Quitter                                        [4]"
    read -p "Votre choix : " choix
    case $choix in
    1)
        fonction_prerequis_scan
        echo ""
        echo -e "${BOLD}L'option 1 à été sélectionnée,Pentesting d'un domaine ou d'une IP${NORMAL}"
        fonction_scan_ip_domain
        ;;
    2)
        fonction_prerequis_scan
        echo ""
        echo -e "${BOLD}L'option 2 à été sélectionnée, le pentesting du réseau local va débuter !!!${NORMAL}"
        echo ""
        fonction_scan_network
        ;;
    3)
        echo ""
        echo -e "${BOLD}L'option 3 à été sélectionnée, le scan du site web avec Dirb va commencer !!!${NORMAL}"
        echo ""
        fonction_arborescence_site
        ;;
    4)
        echo ""
        echo -e "${BOLD}Merci d'avoir utilisé ce script${NORMAL}"
        exit
        ;;
    esac
}
fonction_progress_bar() {
    dico_count=$(cat dictionnary/dictionnary.txt | wc -l)
    for pc in $(seq 1 $dico_count); do
        echo -ne "$pc / $dico_count\r"
        sleep 1
    done
}

fonction_arborescence_site() {
    #Vérifier si le paquet Dirb est installé
    dpkg -s dirb &>/dev/null
    echo ""
    echo -e "${BOLD}Etat du paquets Dirb : ${NC}"
    echo ""
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Dirb est installé !!!${NC}"
    else
        echo -e "${RED}Dirb n'est pas installé !!!${NC}"
        sudo apt install nmap -y &>/dev/null
    fi

    #Execution de Dirb
    mkdir Dirb &>/dev/null
    mkdir Dirb/dictionnary
    wget https://raw.githubusercontent.com/v0re/dirb/master/wordlists/big.txt &>/dev/null
    mv big.txt Dirb/dictionnary/dictionnary.txt
    echo ""
    read -p "$(echo -e "${BOLD}Entrer le site à scanner (ex : https://www.monsite.com): ${NORMAL}")" site
    echo ""
    dirb $site Dirb/dictionnary/dictionnary.txt -o Dirb/dictionnary/directory.txt
    echo ""
    echo -e "${BOLD}Tâche terminée !!!${NORMAL}"
    echo ""
}

fonction_scan_network() {
    #réseau de l'user en automatique
    ip_with_mask=$(ip a | sed -n '9p' | cut -d' ' -f6)
    host_interface=$(ip a | sed -n '7p' | cut -d: -f2 | cut -d' ' -f2)
    arp-scan --interface=$host_interface --localnet | cut -f 1 | tail -n +3 | head -n -3 >ip_machines.txt
    nb_host=$(cat ip_machines.txt | wc -l)

    #Affichege du nombre de machines sur le réseau
    echo -e "${GREEN}${BOLD}"$nb_host" Hosts connectés ${NC}"

    #début du décompte du nombre de machines
    nb_iteration=$(echo $nb_host)

    #Scan des machines découvertes
    for line in $(cat ip_machines.txt); do
        #Création du dossier pour stocker les rapports
        mkdir -p pentest/$DATE/$line

        #Mise en page
        echo -e "${GREEN}${BOLD}"$nb_iteration" Hôtes restants à scanner${NC}${NORMAL}"
        echo " "
        echo -e "L'IP ${PURPLE}${BOLD}"$line" à été ${GREEN}${BOLD}DECOUVERTE ${NC}"

        #Scan nmap générant un rapport
        echo -e "Début du scan pour l'IP : ${PURPLE}${BOLD}"$line"${NC}"
        nmap -sV --script=exploit,external,vuln,auth,default -oX $(pwd)/pentest/$DATE/$line/"$line".xml $line >/dev/null
        echo -e "Scan Terminé pour l'IP : ${PURPLE}${BOLD}"$line"${NC}"

        #Convertion du rapport en de XML vers HTML
        echo -e "${BOLD}Conversion du rapport en HTML"
        xsltproc $(pwd)/pentest/$DATE/$line/"$line".xml -o $(pwd)/pentest/$DATE/$line/"$line".html
        echo -e "${BOLD}Conversion terminée"

        #Mise en page
        echo -e "${BOLD}-------------------------------------------------------------------------"
        echo ""
        nb_iteration=$(($nb_iteration - 1))
    done

    #Resultat
    echo -e "Tout les rapports sont stockés dans ""$(pwd)""/pentest/date/"
    echo -e "Tout les rapports en version ""${BOLD}HTML "$(pwd)"/pentest/date/"
    echo ""
    echo -e "${RED}${BOLD}/ATTENTION\ - TOUT LES FICHIERS CREE AVEC CE SCRIPT ONT ETE CREE AVEC L'UTILISATEUR ROOT POUR TRAITER LES FICHIER FAITE UN CHMOD SUR LES FICHIERS"
    echo ""

    #Netoyage du fichier temporaire
    rm -f ip_machines.txt
}

fonction_scan_ip_domain() {
    #Mise en page
    echo ""
    echo -e "${BOLD}-------------------------------------------------------------------------"
    echo ""

    #Variable
    read -p "$(echo -e "${BOLD}IP ou domaine cible : ${NORMAL}")" cible

    #Mise en page
    echo ""

    #Scan nmap générant un rapport
    mkdir -p pentest/$DATE/$cible
    echo -e "Début du scan de ${PURPLE}${BOLD}"$cible"${NC}"
    nmap -sV --script=exploit,external,vuln,auth,default -oX $(pwd)/pentest/$DATE/"$cible"/report_"$cible".xml $cible >/dev/null
    echo -e "Scan terminé du scan de ${PURPLE}${BOLD}"$cible"${NC}"

    #Mise en page
    echo ""

    #Convertion du rapport en de XML vers HTML
    echo -e "${BOLD}Conversion du rapport en HTML"
    xsltproc pentest/$DATE/$cible/report_"$cible".xml -o pentest/$DATE/$cible/"$cible".html
    echo -e "${BOLD}Conversion terminée"

    #Mise en page
    echo ""
    echo -e "${BOLD}-------------------------------------------------------------------------"
    echo ""

    echo -e "Tout les rapports sont stockés dans ""$(pwd)""/pentest/date/"
    echo -e "Tout les rapports en version ""${BOLD}HTML "$(pwd)"/pentest/date/"
    echo ""
    echo -e "${RED}${BOLD}/ATTENTION\ - TOUT LES FICHIERS CREE AVEC CE SCRIPT ONT ETE CREE AVEC L'UTILISATEUR ROOT POUR TRAITER LES FICHIER FAITE UN CHMOD SUR LES FICHIERS${NC}"
    echo ""
}

#Appel des fonctions
if [ $(whoami) = "root" ]; then
    clear
    fonction_menu
    read -p "$(echo -e "Souhaitez vous retouner au menu principal ? [y/n]   ")" reset
    if [ $(echo $reset) == y ]; then
        while [ $(echo $reset) == y ]; do
            clear
            fonction_menu
            read -p "$(echo -e "Souhaitez vous retouner au menu principal ? [y/n]   ")" reset
        done
    fi
    echo ""
    echo -e "${BOLD}Merci d'avoir utilisé ce script"
else
    echo -e "${RED}${BOLD}Merci d'utiliser la commande sudo pour exécuter ce script"
fi

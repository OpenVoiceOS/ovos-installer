#!/usr/bin/env bash
CONTENT="
Open Voice OS transforme ce que vous dites en texte (reconnaissance vocale) et lit ses réponses à voix haute (synthèse vocale). Cette machine est assez puissante pour faire les deux elle-même.

- local : tout fonctionne sur cette machine. Votre voix reste ici, et rien ne dépend d'Internet ni de la charge des serveurs. L'installateur télécharge les modèles vocaux de votre langue, de quelques centaines de mégaoctets à quelques gigaoctets, et la reconnaissance occupe le processeur pendant que vous parlez.
- public : les serveurs publics d'Open Voice OS font le travail. Rien à télécharger, mais chaque requête passe par Internet vers des serveurs partagés par toute la communauté, ce qui ajoute du délai réseau et ralentit quand beaucoup de monde les utilise en même temps. Vos enregistrements et les réponses sont traités sur ces serveurs.

Si la reconnaissance locale échoue ou n'entend rien, cet enregistrement-là est envoyé aux serveurs publics à la place.

Veuillez sélectionner où la parole est traitée :
"
TITLE="Open Voice OS Installation - Traitement de la parole"
LOCAL_DESCRIPTION="Traiter la parole sur cette machine"
PUBLIC_DESCRIPTION="Utiliser les serveurs publics d'Open Voice OS"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

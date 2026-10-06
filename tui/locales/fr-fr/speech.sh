#!/usr/bin/env bash
CONTENT="
Open Voice OS transforme ce que vous dites en texte (reconnaissance vocale) et lit ses réponses à voix haute (synthèse vocale). Cette machine est assez puissante pour faire les deux elle-même.

- local : tout fonctionne sur cette machine. Votre voix reste ici, et rien ne dépend d'Internet ni de la charge des serveurs. L'installateur télécharge les modèles vocaux de votre langue, de quelques centaines de mégaoctets à quelques gigaoctets, et la reconnaissance occupe le processeur pendant que vous parlez.
- public : des serveurs communautaires font le travail. Ils sont fournis de bonne volonté, comme solution de secours et comme exemple de traitement de la parole auto-hébergé, pas comme un service de production : les réponses ralentissent quand beaucoup de monde les utilise, et ils peuvent s'arrêter à tout moment. Rien à télécharger, mais vos enregistrements et les réponses passent par Internet et sont traités sur ces serveurs.

Si la reconnaissance locale échoue ou n'entend rien, cet enregistrement-là est envoyé aux serveurs publics à la place.

Veuillez sélectionner où la parole est traitée :
"
TITLE="Open Voice OS Installation - Traitement de la parole"
LOCAL_DESCRIPTION="Traiter la parole sur cette machine"
PUBLIC_DESCRIPTION="Serveurs publics (je sais qu'ils peuvent tomber)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

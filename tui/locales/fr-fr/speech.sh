#!/usr/bin/env bash
CONTENT="
Open Voice OS transforme la parole en texte (reconnaissance) et lit les réponses à voix haute (synthèse).

  - local : cette machine avec des serveurs publics en secours. Télécharge des modèles vocaux (de quelques centaines de mégaoctets à quelques gigaoctets). Si la reconnaissance locale échoue ou ne renvoie aucun texte, cet enregistrement est envoyé aux serveurs publics. Si la reconnaissance ou la synthèse locale ne peut pas être configurée, cette partie utilise les serveurs publics ; l'installateur le signale.
  - public : les serveurs communautaires traitent vos enregistrements et les réponses vocales via Internet. Ces serveurs de secours, gérés par des bénévoles, ne sont pas un service de production : ils peuvent ralentir ou s'arrêter à tout moment.

Veuillez sélectionner où la parole est traitée :
"
TITLE="Open Voice OS Installation - Traitement de la parole"
LOCAL_DESCRIPTION="Cette machine avec des serveurs publics en secours"
PUBLIC_DESCRIPTION="Serveurs publics (je sais qu'ils peuvent tomber)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

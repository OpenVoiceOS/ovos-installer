#!/usr/bin/env bash
CONTENT="
Open Voice OS-k esaten duzuna testu bihurtzen du (ahots-ezagutza) eta bere erantzunak ozen irakurtzen ditu (ahots-sintesia). Makina honek bi lanak berak egiteko adina indar du.

  - local: dena makina honetan exekutatzen da. Zure ahotsa hemen geratzen da, eta ezer ez dago Interneten edo zerbitzarien lan-kargaren mende. Instalatzaileak zure hizkuntzako ahots-ereduak deskargatzen ditu, ehunka megabytetik gigabyte gutxi batzuetara, eta ezagutzak prozesadorea lanpetuta mantentzen du hitz egiten duzun bitartean.
  - public: komunitatearen zerbitzariek egiten dute lana. Borondate onez eskaintzen dira, babes gisa eta norberak ostatatutako ahotsaren adibide gisa, ez produkzio-zerbitzu gisa: erantzunak motelago iristen dira jende askok aldi berean erabiltzen dituenean, eta edozein unetan gelditu daitezke. Ez dago ezer deskargatu beharrik, baina zure grabazioak eta erantzunak Internet bidez doaz eta zerbitzari horietan prozesatzen dira.

Ezagutza lokalak huts egiten badu edo ezer entzuten ez badu, grabazio hori zerbitzari publikoetara bidaltzen da.

Aukeratu non prozesatzen den ahotsa:
"
TITLE="Open Voice OS instalazioa - Ahotsa"
LOCAL_DESCRIPTION="Prozesatu ahotsa makina honetan"
PUBLIC_DESCRIPTION="Zerbitzari publikoak (badakit eror daitezkeela)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

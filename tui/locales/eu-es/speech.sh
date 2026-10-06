#!/usr/bin/env bash
CONTENT="
Open Voice OS-k esaten duzuna testu bihurtzen du (ahots-ezagutza) eta bere erantzunak ozen irakurtzen ditu (ahots-sintesia). Makina honek bi lanak berak egiteko adina indar du.

  - local: dena makina honetan exekutatzen da. Zure ahotsa hemen geratzen da, eta ezer ez dago Interneten edo zerbitzarien lan-kargaren mende. Instalatzaileak zure hizkuntzako ahots-ereduak deskargatzen ditu, ehunka megabytetik gigabyte gutxi batzuetara, eta ezagutzak prozesadorea lanpetuta mantentzen du hitz egiten duzun bitartean.
  - public: Open Voice OS-en zerbitzari publikoek egiten dute lana. Ez dago ezer deskargatu beharrik, baina eskaera bakoitza Internet bidez komunitate osoak partekatzen dituen zerbitzarietara doa. Horrek sareko atzerapena gehitzen du, eta motelago doa jende askok aldi berean erabiltzen dituenean. Zure grabazioak eta erantzunak zerbitzari horietan prozesatzen dira.

Ezagutza lokalak huts egiten badu edo ezer entzuten ez badu, grabazio hori zerbitzari publikoetara bidaltzen da.

Aukeratu non prozesatzen den ahotsa:
"
TITLE="Open Voice OS instalazioa - Ahotsa"
LOCAL_DESCRIPTION="Prozesatu ahotsa makina honetan"
PUBLIC_DESCRIPTION="Erabili Open Voice OS-en zerbitzari publikoak"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

#!/usr/bin/env bash
CONTENT="
Open Voice OS-k ahotsa testu bihurtzen du (ezagutza) eta erantzunak ozen irakurtzen ditu (sintesia).

  - local: makina hau, zerbitzari publikoak ordezko gisa erabiliz. Ahots-ereduak deskargatzen ditu (ehunka megabytetik gigabyte gutxi batzuetara). Ezagutza lokalak huts egiten badu edo testurik itzultzen ez badu, grabazioa zerbitzari publikoetara bidaltzen da. Ezagutza edo sintesi lokala ezin bada konfiguratu, zati horrek zerbitzari publikoak erabiltzen ditu; instalatzaileak horren berri ematen du.
  - public: komunitatearen zerbitzariek zure grabazioak eta ahots-erantzunak Internet bidez prozesatzen dituzte. Boluntarioek mantendutako ordezko zerbitzari hauek ez dira produkzio-zerbitzu bat: edozein unetan moteldu edo gelditu daitezke.

Aukeratu non prozesatzen den ahotsa:
"
TITLE="Open Voice OS instalazioa - Ahotsa"
LOCAL_DESCRIPTION="Makina hau, zerbitzari publikoak ordezko gisa"
PUBLIC_DESCRIPTION="Zerbitzari publikoak (badakit eror daitezkeela)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

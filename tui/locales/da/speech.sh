#!/usr/bin/env bash
CONTENT="
Open Voice OS omsætter tale til tekst (genkendelse) og læser svar højt (syntese).

  - local: denne maskine med offentlige servere som reserve. Henter talemodeller (hundredvis af megabyte til nogle få gigabyte). Hvis lokal genkendelse fejler eller ikke giver tekst, sendes optagelsen til offentlige servere. Hvis lokal genkendelse eller syntese ikke kan sættes op, bruger den del offentlige servere; installationsprogrammet oplyser det.
  - public: fællesskabets servere behandler dine optagelser og talte svar over internettet. Disse frivilligt drevne reserveservere er ikke en produktionstjeneste: de kan blive langsomme eller gå ned når som helst.

Vælg, hvor tale skal behandles:
"
TITLE="Open Voice OS Installation - Tale"
LOCAL_DESCRIPTION="Denne maskine med offentlige servere som reserve"
PUBLIC_DESCRIPTION="Offentlige servere (jeg ved, de kan gå ned)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

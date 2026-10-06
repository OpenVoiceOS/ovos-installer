#!/usr/bin/env bash
CONTENT="
Open Voice OS omsætter det, du siger, til tekst (talegenkendelse) og læser sine svar højt (talesyntese). Denne maskine er kraftig nok til selv at klare begge dele.

- local: alt kører på denne maskine. Din stemme bliver her, og intet afhænger af internettet eller af, hvor travlt serverne har. Installationsprogrammet henter talemodellerne til dit sprog, fra et par hundrede megabyte til et par gigabyte, og genkendelsen holder processoren beskæftiget, mens du taler.
- public: de offentlige Open Voice OS-servere klarer arbejdet. Der skal ikke hentes noget, men hver forespørgsel går over internettet til servere, som hele fællesskabet deler. Det giver netværksforsinkelse og bliver langsommere, når mange bruger dem på samme tid. Dine optagelser og svarene behandles på de servere.

Hvis den lokale genkendelse fejler eller ikke hører noget, sendes netop den optagelse til de offentlige servere i stedet.

Vælg venligst, hvor tale skal behandles:
"
TITLE="Open Voice OS Installation - Tale"
LOCAL_DESCRIPTION="Behandl tale på denne maskine"
PUBLIC_DESCRIPTION="Brug de offentlige Open Voice OS-servere"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

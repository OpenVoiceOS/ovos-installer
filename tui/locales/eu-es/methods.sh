#!/usr/bin/env bash
CONTENT="
Open Voice OS instalatzeko, bi metodo nagusi dituzu:

    - Docker bezalako edukiontzien motorra
    - Python ingurune birtualean konfiguratzea

Edukiontziek isolamendua eta inplementazio erraza eskaintzen dituzte, eta Python ingurune birtual batek instalazioaren gaineko malgutasun eta kontrol gehiago eskaintzen du.

Edukiontzien metodoa hautatzen bada, Docker automatikoki instalatuko da sisteman ez badago.

Mesedez, hautatu instalazio metodo bat:
"
LOCKED_CONTENT="
Open Voice OS-en lehendik dagoen instalazio bat hauteman da, beraz, dagoeneko erabiltzen duen metodoa baino ez dago erabilgarri:

    - Hautemandako metodoa: $INSTANCE_TYPE

Beste metodo batekin instalatzeko, desinstalatu lehenik lehendik dagoen instantzia eta exekutatu instalatzailea berriro.

Berretsi instalazio-metodoa:
"
TITLE="Ireki Voice OS Instalazioa - Metodoak"

export CONTENT LOCKED_CONTENT TITLE

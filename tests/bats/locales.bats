#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
}

@test "locales_detection_scripts_are_sourceable" {
    for f in tui/locales/*/detection.sh; do
        run bash -euc "
            DISTRO_NAME=debian
            DISTRO_VERSION='Debian 12'
            DISTRO_LABEL='macOS 15.7.2'
            KERNEL='6.0.0'
            RASPBERRYPI_MODEL='N/A'
            PYTHON='3.11'
            CPU_IS_CAPABLE='true'
            HARDWARE_DETECTED='N/A'
            VENV_PATH='/tmp/venv'
            SOUND_SERVER='PipeWire'
            DISPLAY_SERVER='wayland'
            source '$f'
            test -n \"\$HARDWARE_CONFIRMATION_TITLE\"
            test -n \"\$HARDWARE_CONFIRMATION_MARK2_CONTENT\"
            test -n \"\$HARDWARE_CONFIRMATION_DEVKIT_CONTENT\"
            test -n \"\$HARDWARE_CONFIRMATION_GENERIC_NOTE\"
            printf '%s\n' \"\$CONTENT\"
        "

        if [ "$status" -ne 0 ]; then
            echo \"Failed to source $f\" >&2
            echo \"$output\" >&2
            return 1
        fi
        assert_output --partial "macOS 15.7.2"
    done
}

@test "locales_llm_scripts_are_sourceable" {
    for f in tui/locales/*/llm.sh; do
        run bash -euc "
            source '$f'
            test -n \"\$LLM_TITLE_SETUP\"
            test -n \"\$LLM_TITLE_EXISTING\"
            test -n \"\$LLM_CONTENT_HAVE_DETAILS\"
            test -n \"\$LLM_CONTENT_EXISTING\"
            test -n \"\$LLM_TITLE_URL\"
            test -n \"\$LLM_CONTENT_URL\"
            test -n \"\$LLM_TITLE_KEY\"
            test -n \"\$LLM_CONTENT_KEY\"
            test -n \"\$LLM_CONTENT_KEY_KEEP_EXISTING\"
            test -n \"\$LLM_TITLE_MODEL\"
            test -n \"\$LLM_CONTENT_MODEL\"
            test -n \"\$LLM_TITLE_PERSONA\"
            test -n \"\$LLM_DEFAULT_PERSONA\"
            test -n \"\$LLM_CONTENT_PERSONA\"
            test -n \"\$LLM_TITLE_MAX_TOKENS\"
            test -n \"\$LLM_CONTENT_MAX_TOKENS\"
            test -n \"\$LLM_TITLE_TEMPERATURE\"
            test -n \"\$LLM_CONTENT_TEMPERATURE\"
            test -n \"\$LLM_TITLE_TOP_P\"
            test -n \"\$LLM_CONTENT_TOP_P\"
            test -n \"\$LLM_TITLE_INVALID\"
            test -n \"\$LLM_CONTENT_MISSING_INFO\"
            test -n \"\$LLM_CONTENT_INVALID_URL\"
            test -n \"\$LLM_CONTENT_INVALID_MAX_TOKENS\"
            test -n \"\$LLM_CONTENT_INVALID_TEMPERATURE\"
            test -n \"\$LLM_CONTENT_INVALID_TOP_P\"
            printf '%s\n' \"\$LLM_TITLE_SETUP\"
        "

        if [ "$status" -ne 0 ]; then
            echo \"Failed to source $f\" >&2
            echo \"$output\" >&2
            return 1
        fi
        assert_output --partial "LLM"
    done
}

@test "locales_features_scripts_are_sourceable" {
    for f in tui/locales/*/features.sh; do
        run bash -euc "
            source '$f'
            test -n \"\$TITLE\"
            test -n \"\$CONTENT\"
            test -n \"\$SKILL_DESCRIPTION\"
            test -n \"\$EXTRA_SKILL_DESCRIPTION\"
            test -n \"\$GUI_DESCRIPTION\"
            test -n \"\$HOMEASSISTANT_DESCRIPTION\"
            test -n \"\$LLM_DESCRIPTION\"
            printf '%s\n' \"\$TITLE\"
        "

        if [ "$status" -ne 0 ]; then
            echo \"Failed to source $f\" >&2
            echo \"$output\" >&2
            return 1
        fi
        [ -n "$output" ]
    done
}

@test "locales_summary_scripts_are_sourceable" {
    for f in tui/locales/*/summary.sh; do
        run bash -euc "
            METHOD='virtualenv'
            CHANNEL='alpha'
            PROFILE='ovos'
            FEATURE_SKILLS_SUMMARY_STATE='enabled'
            FEATURE_EXTRA_SKILLS_SUMMARY_STATE='disabled'
            HOMEASSISTANT_SUMMARY_STATE='enabled'
            LLM_SUMMARY_STATE='enabled'
            TUNING_SUMMARY_STATE='enabled'
            BACK_BUTTON='Back'
            source '$f'
            test -n \"\$TITLE\"
            test -n \"\$CONTENT\"
            printf '%s\n' \"\$CONTENT\"
        "

        if [ "$status" -ne 0 ]; then
            echo \"Failed to source $f\" >&2
            echo \"$output\" >&2
            return 1
        fi

        assert_output --partial "virtualenv"
    done
}

@test "locales_speech_scripts_are_complete_and_sourceable" {
    for locale_dir in tui/locales/*; do
        local locale_file="$locale_dir/speech.sh"

        if [ ! -f "$locale_file" ]; then
            echo "Missing speech locale: $locale_file" >&2
            return 1
        fi

        run bash -euc "
            source '$locale_file'
            test -n \"\$TITLE\"
            test -n \"\$CONTENT\"
            test -n \"\$LOCAL_DESCRIPTION\"
            test -n \"\$PUBLIC_DESCRIPTION\"
        "
        assert_success
    done
}

@test "locales_summary_scripts_show_where_speech_runs" {
    for f in tui/locales/*/summary.sh; do
        run bash -euc "
            METHOD='virtualenv'
            CHANNEL='alpha'
            PROFILE='ovos'
            SPEECH_SUMMARY_STATE='speech-state-marker'
            BACK_BUTTON='Back'
            source '$f'
            test -n \"\$SUMMARY_SPEECH_LOCAL\"
            test -n \"\$SUMMARY_SPEECH_PUBLIC\"
            test -n \"\$SUMMARY_SPEECH_PUBLIC_HARDWARE\"
            test -n \"\$SUMMARY_SPEECH_PUBLIC_SETUP\"
            test -n \"\$SUMMARY_SPEECH_UNUSED\"
            printf '%s\\n' \"\$CONTENT\"
        "

        if [ "$status" -ne 0 ]; then
            echo "Failed to source $f" >&2
            echo "$output" >&2
            return 1
        fi
        assert_output --partial "speech-state-marker"
    done
}

@test "locales_usage_telemetry_scripts_are_complete_and_sourceable" {
    for locale_dir in tui/locales/*; do
        local locale_file="$locale_dir/usage_telemetry.sh"

        if [ ! -f "$locale_file" ]; then
            echo "Missing usage telemetry locale: $locale_file" >&2
            return 1
        fi

        run bash -euc "
            source '$locale_file'
            test -n \"\$TITLE\"
            test -n \"\$CONTENT\"
        "
        assert_success
    done
}

@test "locales_methods_scripts_expose_locked_content" {
    for locale_dir in tui/locales/*; do
        local locale_file="$locale_dir/methods.sh"

        if [ ! -f "$locale_file" ]; then
            echo "Missing methods locale: $locale_file" >&2
            return 1
        fi

        # Mirror the load order in tui/methods.sh: English first, then the
        # selected locale. A locale contributed by hand, or not translated yet,
        # still resolves the locked description that way.
        run bash -euc "
            INSTANCE_TYPE=containers
            source tui/locales/en-us/methods.sh
            source '$locale_file'
            test -n \"\$TITLE\"
            test -n \"\$CONTENT\"
            test -n \"\$LOCKED_CONTENT\"
            printf '%s\\n' \"\$LOCKED_CONTENT\"
        "
        assert_success
        assert_output --partial "containers"
    done
}

@test "locales_are_sourceable_under_nounset" {
    # The installer runs under "set -u". A locale that interpolates a bare name
    # kills it on that screen the moment the variable happens to be unset, which
    # is how #567 shipped: detect_existing_instance() unsets INSTANCE_TYPE, so
    # every fresh install died on the methods screen.
    #
    # Whether a given variable "is always set by then" is not something a test
    # can know, so the rule here is absolute: every locale file has to source
    # with nothing set at all. That means every interpolation carries a default.
    for locale_file in tui/locales/*/*.sh; do
        run env -i PATH="$PATH" bash -euc "source '$locale_file'"

        if [ "$status" -ne 0 ]; then
            echo "$locale_file is not sourceable under nounset:" >&2
            echo "$output" >&2
            echo "Use \${VARIABLE:-} rather than \$VARIABLE in the locale string." >&2
        fi
        assert_success
    done
}

@test "locales_methods_scripts_are_nounset_safe" {
    # detect_existing_instance() unsets INSTANCE_TYPE when it finds nothing, and
    # the installer runs under "set -u". A locale that interpolates the bare name
    # aborts the install on the methods screen, see issue #567.
    for locale_dir in tui/locales/*; do
        local locale_file="$locale_dir/methods.sh"

        if [ ! -f "$locale_file" ]; then
            echo "Missing methods locale: $locale_file" >&2
            return 1
        fi

        run bash -euc "
            unset INSTANCE_TYPE
            source '$locale_file'
            printf '%s' \"\$LOCKED_CONTENT\"
        "
        if [ "$status" -ne 0 ]; then
            echo "$locale_file is not sourceable with INSTANCE_TYPE unset" >&2
            echo "$output" >&2
        fi
        assert_success
    done
}

@test "locales_summary_renders_every_computed_state" {
    # tui/summary.sh computes five states. A locale that leaves one out of
    # CONTENT hides that choice from the user on the confirmation screen.
    for locale_dir in tui/locales/*; do
        local locale_file="$locale_dir/summary.sh"

        if [ ! -f "$locale_file" ]; then
            echo "Missing summary locale: $locale_file" >&2
            return 1
        fi

        # Only CONTENT reaches the screen. A state named in a comment, or in
        # the export line, must not stand in for a row the user never sees.
        local rendered
        rendered="$(sed -n '/^CONTENT="/,/^"$/p' "$locale_file")"

        local state
        for state in FEATURE_SKILLS FEATURE_EXTRA_SKILLS HOMEASSISTANT LLM TUNING; do
            run grep -qF "${state}_SUMMARY_STATE" <<<"$rendered"
            if [ "$status" -ne 0 ]; then
                echo "$locale_file does not render ${state}_SUMMARY_STATE in CONTENT" >&2
            fi
            assert_success
        done
    done
}

@test "locales_are_regenerated_by_sync_translations_without_changes" {
    if ! command -v python3 >/dev/null 2>&1; then
        skip "python3 is not available"
    fi

    # scripts/sync_translations.py runs on every gitlocalize-app merge to main
    # and commits what it produces. Anything the templates cannot emit is lost
    # at that point, so regenerating has to be a no-op against what is checked in.
    local workdir
    workdir="$(mktemp -d)"
    cp -R scripts translations tui "$workdir/"

    run bash -c "cd '$workdir' && python3 scripts/sync_translations.py"
    assert_success

    for locale_dir in tui/locales/*; do
        local locale="${locale_dir##*/}"

        run diff -r "$locale_dir" "$workdir/tui/locales/$locale"
        if [ "$status" -ne 0 ]; then
            echo "sync_translations.py would rewrite $locale_dir:" >&2
            echo "$output" >&2
        fi
        assert_success
    done

    rm -rf "$workdir"
}

@test "locales_llm_model_strings_are_localized_outside_en_us" {
    for f in tui/locales/*/llm.sh; do
        if [ "$f" = "tui/locales/en-us/llm.sh" ]; then
            continue
        fi

        run bash -euc "
            source tui/locales/en-us/llm.sh
            en_title_model=\$LLM_TITLE_MODEL
            en_content_model=\$LLM_CONTENT_MODEL
            en_default_persona=\$LLM_DEFAULT_PERSONA
            source '$f'
            [ \"\$LLM_TITLE_MODEL\" != \"\$en_title_model\" ]
            [ \"\$LLM_CONTENT_MODEL\" != \"\$en_content_model\" ]
            [ \"\$LLM_DEFAULT_PERSONA\" != \"\$en_default_persona\" ]
        "
        assert_success
    done
}

@test "locales_feature_strings_are_localized_outside_en_us" {
    for f in tui/locales/*/features.sh; do
        if [ "$f" = "tui/locales/en-us/features.sh" ]; then
            continue
        fi

        run bash -euc "
            source tui/locales/en-us/features.sh
            en_gui_description=\$GUI_DESCRIPTION
            en_llm_description=\$LLM_DESCRIPTION
            en_homeassistant_description=\$HOMEASSISTANT_DESCRIPTION
            source '$f'
            [ \"\$GUI_DESCRIPTION\" != \"\$en_gui_description\" ]
            [ \"\$LLM_DESCRIPTION\" != \"\$en_llm_description\" ]
            [ \"\$HOMEASSISTANT_DESCRIPTION\" != \"\$en_homeassistant_description\" ]
        "
        assert_success
    done
}

@test "locales_speech_strings_are_localized_outside_en_us" {
    for f in tui/locales/*/speech.sh; do
        if [ "$f" = "tui/locales/en-us/speech.sh" ]; then
            continue
        fi

        run bash -euc "
            source tui/locales/en-us/speech.sh
            en_content=\$CONTENT
            en_local_description=\$LOCAL_DESCRIPTION
            en_public_description=\$PUBLIC_DESCRIPTION
            source '$f'
            [ \"\$CONTENT\" != \"\$en_content\" ]
            [ \"\$LOCAL_DESCRIPTION\" != \"\$en_local_description\" ]
            [ \"\$PUBLIC_DESCRIPTION\" != \"\$en_public_description\" ]
        "
        assert_success
    done
}

@test "english_llm_locale_explains reply tuning in plain language" {
    local file="tui/locales/en-us/llm.sh"

    run grep -F -q "This lets OVOS use an AI assistant when normal skills do not have a good answer." "$file"
    assert_success

    run grep -F -q "API URL: where OVOS sends AI requests" "$file"
    assert_success

    run grep -F -q "Reply length: how much room the model gets to answer" "$file"
    assert_success

    run grep -F -q "Creativity: lower is safer, higher is more imaginative" "$file"
    assert_success

    run grep -F -q "Focus: lower keeps answers tighter and more predictable" "$file"
    assert_success

    run grep -F -q "Recommended for voice use: 300" "$file"
    assert_success

    run grep -F -q "Recommended for voice use: 0.2" "$file"
    assert_success

    run grep -F -q "Recommended for voice use: 0.1" "$file"
    assert_success
}

@test "hindi_llm_locale_avoids leftover English UI terms" {
    local file="tui/locales/hi-in/llm.sh"

    run grep -Eq '\b(default|provider|summary|voice-friendly|tuning)\b' "$file"
    assert_failure
}

@test "locales_speech_disclose_public_fallback_in_choices_and_summaries" {
    run python3 - <<'PY'
import json
import subprocess
from pathlib import Path

# Check what users see after sourcing the generated locales, including both
# fallback triggers. A translated heading alone must not satisfy disclosure.
expected = {
    "en-us": (
        "with public fallback", "Downloads speech models",
        "fails or returns no text, that recording is sent to public servers",
        "recognition or synthesis cannot be set up, that part uses public servers",
        "the installer reports it", "go offline at any time",
    ),
    "ca-es": (
        "amb servidors públics de reserva", "Baixa models de veu",
        "falla o no retorna text, aquella gravació s'envia als servidors públics",
        "reconeixement o la síntesi local, aquella part fa servir servidors públics",
        "l'instal·lador ho indica", "deixar de funcionar en qualsevol moment",
    ),
    "da": (
        "med offentlige servere som reserve", "Henter talemodeller",
        "fejler eller ikke giver tekst, sendes optagelsen til offentlige servere",
        "genkendelse eller syntese ikke kan sættes op, bruger den del offentlige servere",
        "installationsprogrammet oplyser det", "gå ned når som helst",
    ),
    "de-de": (
        "mit öffentlichen Servern als Ersatz", "Lädt Sprachmodelle herunter",
        "fehlschlägt oder keinen Text liefert, wird die Aufnahme an öffentliche Server gesendet",
        "Erkennung oder Synthese nicht einrichten, nutzt dieser Teil öffentliche Server",
        "der Installer weist darauf hin", "jederzeit langsamer werden oder ausfallen",
    ),
    "es-es": (
        "con servidores públicos de respaldo", "Descarga modelos de voz",
        "falla o no devuelve texto, esa grabación se envía a servidores públicos",
        "reconocimiento o la síntesis local, esa parte usa servidores públicos",
        "el instalador lo indica", "dejar de funcionar en cualquier momento",
    ),
    "eu-es": (
        "zerbitzari publikoak ordezko gisa", "Ahots-ereduak deskargatzen ditu",
        "huts egiten badu edo testurik itzultzen ez badu, grabazioa zerbitzari publikoetara bidaltzen da",
        "Ezagutza edo sintesi lokala ezin bada konfiguratu, zati horrek zerbitzari publikoak erabiltzen ditu",
        "instalatzaileak horren berri ematen du", "edozein unetan moteldu edo gelditu daitezke",
    ),
    "fr-fr": (
        "avec des serveurs publics en secours", "Télécharge des modèles vocaux",
        "échoue ou ne renvoie aucun texte, cet enregistrement est envoyé aux serveurs publics",
        "reconnaissance ou la synthèse locale ne peut pas être configurée, cette partie utilise les serveurs publics",
        "l'installateur le signale", "s'arrêter à tout moment",
    ),
    "gl-es": (
        "con servidores públicos de respaldo", "Descarga modelos de voz",
        "falla ou non devolve texto, esa gravación envíase a servidores públicos",
        "recoñecemento ou a síntese local, esa parte usa servidores públicos",
        "o instalador indícao", "deixar de funcionar en calquera momento",
    ),
    "hi-in": (
        "सार्वजनिक सर्वरों की मदद से", "वाक् मॉडल डाउनलोड होते हैं",
        "विफल हो या कोई टेक्स्ट न लौटाए, तो वह रिकॉर्डिंग सार्वजनिक सर्वरों पर भेजी जाती है",
        "पहचान या संश्लेषण स्थापित नहीं हो पाता, तो उस हिस्से के लिए सार्वजनिक सर्वर इस्तेमाल होते हैं",
        "इंस्टॉलर इसकी जानकारी देता है", "कभी भी बंद हो सकते हैं",
    ),
    "it-it": (
        "con server pubblici di riserva", "Scarica modelli vocali",
        "fallisce o non restituisce testo, quella registrazione viene inviata ai server pubblici",
        "riconoscimento o la sintesi locale, quella parte usa i server pubblici",
        "l'installer lo segnala", "andare offline in qualsiasi momento",
    ),
    "kab-dz": (
        "s yiqeddacen izayazen d tallalt", "Ad d-yessader timudmin n taɣect",
        "yecceḍ uɛqal adigan neɣ ur d-yerri ara aḍris, asekles-nni ad yettwazen ɣer yiqeddacen izayazen",
        "aɛqal neɣ asuddes adigan, aḥric-nni ad yesseqdec iqeddacen izayazen",
        "amesbeddi ad d-yefk talɣut ɣef waya", "ad ḥbesen melmi tebɣu tili",
    ),
    "nl-nl": (
        "met openbare servers als reserve", "Downloadt spraakmodellen",
        "mislukt of geen tekst oplevert, gaat die opname naar openbare servers",
        "herkenning of synthese niet kan worden ingesteld, gebruikt dat onderdeel openbare servers",
        "het installatieprogramma meldt dit", "op elk moment traag worden of uitvallen",
    ),
    "pl-pl": (
        "z serwerami publicznymi w rezerwie", "Pobiera modele mowy",
        "zawiedzie lub nie zwróci tekstu, nagranie jest wysyłane do serwerów publicznych",
        "rozpoznawania lub syntezy, ta część używa serwerów publicznych",
        "instalator o tym informuje", "przestać działać w każdej chwili",
    ),
    "pt-pt": (
        "com servidores públicos de reserva", "Descarrega modelos de voz",
        "falhar ou não devolver texto, essa gravação é enviada para servidores públicos",
        "reconhecimento ou a síntese local, essa parte usa servidores públicos",
        "o instalador informa-o", "indisponíveis a qualquer momento",
    ),
}
locale_paths = list(Path("translations").glob("*/strings.json"))
assert {path.parent.name for path in locale_paths} == set(expected)
for path in locale_paths:
    locale = path.parent.name
    data = json.loads(path.read_text())
    result = subprocess.run(
        ["bash", "-euc", 'source "$1"; printf "%s\\0%s\\0" "$CONTENT" "$LOCAL_DESCRIPTION"; '
         'source "$2"; printf "%s" "$SUMMARY_SPEECH_LOCAL"', "bash",
         f"tui/locales/{locale}/speech.sh", f"tui/locales/{locale}/summary.sh"],
        check=True, capture_output=True, text=True,
    )
    content, choice, summary = result.stdout.split("\0")
    fallback, *disclosures = expected[locale]
    for field, value in (("content", content), ("choice", choice), ("summary", summary)):
        assert fallback in value, f"{locale}: missing public fallback in {field}"
    for disclosure in disclosures:
        assert disclosure in content, f"{locale}: missing speech disclosure: {disclosure}"
    assert choice == data["speech.sh"]["local_description"]
    assert summary == data["summary.sh"]["speech_local"]
PY
    assert_success
}

@test "english_speech_locale_does_not_promise_private_or_offline_processing" {
    run bash -euc '
        source tui/locales/en-us/speech.sh
        printf "%s\n" "$CONTENT" "$LOCAL_DESCRIPTION"
        source tui/locales/en-us/summary.sh
        printf "%s\n" "$SUMMARY_SPEECH_LOCAL"
    '
    assert_success
    refute_output --partial "everything runs on this machine"
    refute_output --partial "Your voice stays here"
    refute_output --partial "nothing depends on the internet"
    assert_output --partial "not a production service"
}

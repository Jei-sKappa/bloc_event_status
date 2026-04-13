set shell := ["bash", "-euo", "pipefail", "-c"]

# Directories

bes := "packages/bloc_event_status"
bes_generator := "packages/bloc_event_status_generator"

# Comandi di default
default:
    @just --list

test-and-report:
    just test-and-report-bes
    just test-and-report-generator

test-and-report-bes:
    cd {{bes}} && fvm dart test --coverage=coverage
    @echo ""
    @echo "---"
    @echo ""
    cd {{bes}} && dart pub global run coverage:format_coverage \
        --lcov \
        --in=coverage \
        --out=coverage/lcov.info \
        --packages=../../.dart_tool/package_config.json \
        --report-on=lib
    @echo ""
    @echo "---"
    @echo ""
    cd {{bes}} && buggy report


test-and-report-generator:
    cd {{bes_generator}} && fvm dart test --coverage=coverage
    @echo ""
    @echo "---"
    @echo ""
    cd {{bes_generator}} && dart pub global run coverage:format_coverage \
        --lcov \
        --in=coverage \
        --out=coverage/lcov.info \
        --packages=../../.dart_tool/package_config.json \
        --report-on=lib
    @echo ""
    @echo "---"
    @echo ""
    cd {{bes_generator}} && buggy report

try-publish-bes:
    cd {{bes}} && fvm dart pub publish --dry-run

try-publish-generator:
    cd {{bes_generator}} && fvm dart pub publish --dry-run

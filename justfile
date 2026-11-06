set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

default:
    @just --list

# Build and launch the development app.
dev:
    & './scripts/build.ps1' -Configuration Debug -Run

# Compile and publish the self-contained x64 app.
build:
    & './scripts/build.ps1' -Configuration Release -Publish

# Build and install for the current Windows user.
install: build
    & './scripts/install.ps1' -Launch

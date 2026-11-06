set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

default:
    @just --list

# Build bin/WindowsIconToolkit.App.exe and launch it.
dev:
    & './scripts/build.ps1' -Configuration Debug -Run

# Publish one self-contained EXE to artifacts.
build:
    & './scripts/build.ps1' -Configuration Release -Publish

# Build and install for the current Windows user.
install: build
    & './scripts/install.ps1' -Launch

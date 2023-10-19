#!/usr/bin/make

# Package
pkg_name:=license
pkg_version:=0.0.1
pkg_vversion:=v$(pkg_version)
pkg_distname:=$(pkg_name)-$(pkg_vversion)

# Make configurations
SHELL:=/usr/bin/bash
DEFAULT_GOAL:=all
.ONESHELL:
.EXPORT_ALL_VARIABLES:
.SECONDEXPANSION:
.DELETE_ON_ERROR:

# Directories
pgkdir:=.
srcdir:=.
bindir:=$(HOME)/bin

# Sources
source:=license.sh

# Output
executable:=license

all: build

build: $(executable)
install: $(bindir)/$(executable)

$(bindir)/$(executable): $(executable)
	install $< $@

$(executable): $(source)
	cp --force $< $@

clean:
	rm --force $(executable)

.PHONY: all install build clean


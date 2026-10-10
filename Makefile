ROOT     := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ENV_FILE := $(ROOT).env
STACKS   := $(sort $(patsubst $(ROOT)stacks/%/docker-compose.yml,%,$(shell find $(ROOT)stacks -name docker-compose.yml -not -path '*/data/*' 2>/dev/null)))
STACK    ?=
SVC      ?=

dc = docker compose --env-file $(ENV_FILE) -f $(ROOT)stacks/$(1)/docker-compose.yml

.PHONY: help check network up down ps logs pull lint backup

help:
	@echo "Uso: make <target> [STACK=nombre] [SVC=servicio]"
	@echo "  up        Levanta un stack (o todos si no pasas STACK)"
	@echo "  down      Detiene un stack (o todos)"
	@echo "  ps        Estado de los servicios"
	@echo "  logs      Logs en vivo (requiere STACK, SVC opcional)"
	@echo "  pull      Descarga imagenes nuevas"
	@echo "  lint      Valida la sintaxis de todos los compose"
	@echo "  backup    Ejecuta scripts/backup.sh"
	@echo "Stacks: $(STACKS)"

check:
	@test -f $(ENV_FILE) || { echo "Falta $(ENV_FILE). Crealo con: cp env/.env.example .env"; exit 1; }

network:
	@docker network inspect homelab >/dev/null 2>&1 || docker network create homelab

up: check network
	@for s in $(or $(STACK),$(STACKS)); do echo "==> up $$s"; $(call dc,$$s) up -d || exit 1; done

down: check
	@for s in $(or $(STACK),$(STACKS)); do echo "==> down $$s"; $(call dc,$$s) down; done

ps: check
	@for s in $(or $(STACK),$(STACKS)); do echo "==> $$s"; $(call dc,$$s) ps; done

pull: check
	@for s in $(or $(STACK),$(STACKS)); do echo "==> pull $$s"; $(call dc,$$s) pull; done

logs: check
	@test -n "$(STACK)" || { echo "Usa: make logs STACK=productivity SVC=vikunja"; exit 1; }
	$(call dc,$(STACK)) logs -f --tail=100 $(SVC)

lint: check
	@for s in $(STACKS); do printf "%s: " $$s; $(call dc,$$s) config -q && echo ok || exit 1; done

backup: check
	@bash $(ROOT)scripts/backup.sh

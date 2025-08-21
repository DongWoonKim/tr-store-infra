#!/bin/bash
set -euo pipefail

DATA_FILE="docker-compose.data.yml"
SVC_FILE="docker-compose.service.yml"
FE_FILE="docker-compose.front.yml"

POSTGRES_SVC="postgres"         # docker-compose.data.yml의 서비스 이름
ELASTIC_SVC="elasticsearch"     # 동일

wait_healthy () {
  local cid="$1"
  local name="$2"
  echo "⏳ Waiting for '$name' to be healthy..."

  # healthcheck가 정의된 컨테이너의 상태를 polling
  while true; do
    status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}unknown{{end}}' "$cid")"
    if [[ "$status" == "healthy" ]]; then
      echo "✅ '$name' is healthy."
      break
    fi
    echo "  - $name status: $status (retry in 2s)"
    sleep 2
  done
}

echo "▶ Starting data stack..."
docker compose -f "$DATA_FILE" up -d

# 컨테이너 ID 조회
PG_CID="$(docker compose -f "$DATA_FILE" ps -q "$POSTGRES_SVC")"
ES_CID="$(docker compose -f "$DATA_FILE" ps -q "$ELASTIC_SVC")"

if [[ -z "$PG_CID" || -z "$ES_CID" ]]; then
  echo "❌ Failed to find data containers. Check service names in $DATA_FILE"
  exit 1
fi

# Healthcheck 대기 (compose에 이미 정의되어 있음)
wait_healthy "$PG_CID" "$POSTGRES_SVC"
wait_healthy "$ES_CID" "$ELASTIC_SVC"

echo "▶ Starting backend services..."
docker compose -f "$SVC_FILE" up -d

echo "▶ Starting frontend..."
docker compose -f "$FE_FILE" up -d

echo "🎉 All containers started successfully."
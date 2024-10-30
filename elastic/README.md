1. mkdir data && chmod 775 -R data
2. docker compose up -d
3. docker exec -it elastic /usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive
# Hotel Booking Pipeline

Pipeline Postgres + dbt + Airflow (Docker) sur le dataset [Hotel Booking Demand](https://www.kaggle.com/datasets/jessemostipak/hotel-booking-demand).

Reprend le dataset et la logique de nettoyage explorés dans [Hotel_Booking_Analysis](https://github.com/JBaptisteAll/Hotel_Booking_Analysis), pour construire un pipeline productionisé, orchestré en Docker.

## Stack
- Postgres (data warehouse)
- dbt (transformation, architecture médaillon : seed → staging → mart)
- Airflow (orchestration)

## Note sur les secrets

Les identifiants Postgres sont volontairement en dur dans `docker-compose.yml` / `profiles.yml` : environnement de dev local, base non exposée, aucune donnée sensible. En production, ces valeurs seraient externalisées via `.env` / secrets manager.
# Hotel Booking Pipeline

```mermaid
flowchart TD
    subgraph Sources["Sources"]
        CSV["hotel_bookings.csv<br/>(Kaggle dataset)"]
        SEASONS["seed_hotel_seasons.csv<br/>(manual mapping)"]
    end

    subgraph Seed["dbt seed"]
        CSV -->|dbt seed| RAW["hotel_bookings<br/>(raw table)"]
        SEASONS -->|dbt seed| SEASON_TABLE["seed_hotel_seasons<br/>(reference table)"]
    end

    subgraph Staging["Staging"]
        RAW --> STG["stg_bookings<br/>(cleaned, typed, deduped)"]
    end

    subgraph Intermediate["Intermediate"]
        STG --> INT["int_bookings_with_season<br/>(+ season column)"]
        SEASON_TABLE --> INT
    end

    subgraph Tests["dbt tests"]
        STG -->|ADR >= 0| T1["accepted_range<br/>severity: error"]
        INT -->|ADR > 4x median<br/>by hotel + season| T2["assert_no_extreme_adr_outliers<br/>severity: warn"]
        INT -->|season not_null +<br/>accepted_values| T3["schema tests on season<br/>severity: error"]
        INT -->|row count preserved<br/>after season LEFT JOIN| T4["assert_no_row_duplication_after_season_join<br/>severity: warn"]
    end

    subgraph Marts["Marts"]
        INT --> MART_PRICE["mart_pricing_consistency<br/>(ADR vs hotel+season+customer_type median)"]
        INT --> MART_CANCEL["mart_cancellation_rate<br/>(cancellation % by hotel/deposit/season/lead-time band)"]
    end

    subgraph MartTests["dbt tests (marts)"]
        MART_PRICE -->|median_adr_by_group<br/>not_null| T5["schema test<br/>severity: error"]
        MART_PRICE -->|row count preserved<br/>after median JOIN| T6["assert_no_row_duplication_after_median_join<br/>severity: warn"]
        MART_CANCEL -->|rate <= 100% +<br/>share sums to 100%| T7["assert_cancellation_rate_consistency<br/>severity: warn"]
    end

    subgraph Orchestration["Airflow (planned)"]
        DAG["DAG: dbt seed → dbt run → dbt test"]
    end

    Orchestration -.orchestrates.-> Seed
    Orchestration -.orchestrates.-> Staging
    Orchestration -.orchestrates.-> Intermediate
    Orchestration -.orchestrates.-> Tests
    Orchestration -.orchestrates.-> Marts
    Orchestration -.orchestrates.-> MartTests
```

Postgres + dbt + Airflow (Docker) pipeline built on the [Hotel Booking Demand](https://www.kaggle.com/datasets/jessemostipak/hotel-booking-demand) dataset.

Builds on the dataset and cleaning logic explored in [Hotel_Booking_Analysis](https://github.com/JBaptisteAll/Hotel_Booking_Analysis), to build a productionized pipeline, orchestrated with Docker.

📄 See [docs/decisions.md](docs/decisions.md) for the full reasoning behind these architecture and testing decisions.

## Stack
- Postgres (data warehouse)
- dbt (transformation, medallion architecture: seed → staging → intermediate → mart)
- Airflow (orchestration)

## Architecture decisions

### Ingestion: direct load instead of a cloud landing zone
`hotel_bookings.csv` is loaded directly via `dbt seed`, without an
intermediate cloud storage layer. A simulated S3 landing zone (LocalStack)
is a possible v2 evolution to demonstrate a more realistic ingestion
pattern. [Details →](docs/decisions.md#ingestion-direct-load-instead-of-a-cloud-landing-zone)

### Data quality & seasonality tests
The source dataset has no native booking ID, so `stg_bookings` exposes a
technical `booking_id` (row number) alongside a non-unique surrogate hash
kept only for investigation. ADR outliers are guarded by an
`accepted_range` test (no negative prices) and a singular test flagging
ADR beyond 4x the median for its `hotel` + `season` group, using a
seasonality seed (`seed_hotel_seasons`) and the `int_bookings_with_season`
model. [Details →](docs/decisions.md#data-quality-notes)

### Marts
`mart_pricing_consistency` compares each booking's ADR to the median of its
`hotel` + `season` + `customer_type` group, surfacing pricing deviations for
revenue management review. `mart_cancellation_rate` aggregates cancellation
rate and each group's share of bookings by `hotel` + `deposit_type` +
`season` + lead-time band (Last minute / Standard / Early / Xtra early).
Both are guarded by warn-severity singular tests checking row-count parity
and result sanity (rate ≤ 100%, shares sum to 100%).
[Details →](docs/decisions.md#marts)

## Note on secrets

Postgres credentials are intentionally hardcoded in `docker-compose.yml` / `profiles.yml`: local dev environment, database not exposed, no sensitive data involved. In a production context, these would be moved to environment variables or a secrets manager (e.g. Docker secrets, AWS Secrets Manager) rather than committed in plain text.

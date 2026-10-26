"""Create the baseline Sarathy schema.

Revision ID: 0001_initial_schema
Revises:
Create Date: 2026-10-17
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "0001_initial_schema"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "operators",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("hashed_password", sa.String(length=255), nullable=False),
        sa.Column(
            "subscription_tier",
            sa.Enum("STARTER", "GROWTH", "FLEET", name="subscriptiontier"),
            nullable=False,
        ),
        sa.Column("subscription_active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_operators_email", "operators", ["email"], unique=True)

    op.create_table(
        "crew",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("operator_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("phone", sa.String(length=32), nullable=False),
        sa.Column("hashed_password", sa.String(length=255), nullable=False),
        sa.Column("role", sa.String(length=32), nullable=False),
        sa.ForeignKeyConstraint(["operator_id"], ["operators.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_crew_phone", "crew", ["phone"], unique=True)

    op.create_table(
        "buses",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("operator_id", sa.Integer(), nullable=False),
        sa.Column("registration_number", sa.String(length=32), nullable=False),
        sa.Column("capacity", sa.Integer(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(["operator_id"], ["operators.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_buses_registration_number",
        "buses",
        ["registration_number"],
        unique=True,
    )

    op.create_table(
        "routes",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("operator_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("origin", sa.String(length=255), nullable=False),
        sa.Column("destination", sa.String(length=255), nullable=False),
        sa.ForeignKeyConstraint(["operator_id"], ["operators.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "stops",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("route_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("sequence", sa.Integer(), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=False),
        sa.Column("longitude", sa.Float(), nullable=False),
        sa.ForeignKeyConstraint(["route_id"], ["routes.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "trips",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("bus_id", sa.Integer(), nullable=False),
        sa.Column("route_id", sa.Integer(), nullable=False),
        sa.Column("crew_id", sa.Integer(), nullable=True),
        sa.Column(
            "status",
            sa.Enum("SCHEDULED", "ACTIVE", "COMPLETED", "CANCELLED", name="tripstatus"),
            nullable=False,
        ),
        sa.Column("started_at", sa.DateTime(), nullable=True),
        sa.Column("ended_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["bus_id"], ["buses.id"]),
        sa.ForeignKeyConstraint(["route_id"], ["routes.id"]),
        sa.ForeignKeyConstraint(["crew_id"], ["crew.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "trip_pings",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("trip_id", sa.Integer(), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=False),
        sa.Column("longitude", sa.Float(), nullable=False),
        sa.Column("speed_kmh", sa.Float(), nullable=True),
        sa.Column("recorded_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["trip_id"], ["trips.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "incidents",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("trip_id", sa.Integer(), nullable=False),
        sa.Column(
            "type",
            sa.Enum("BREAKDOWN", "TRAFFIC", "EMERGENCY", name="incidenttype"),
            nullable=False,
        ),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("reported_at", sa.DateTime(), nullable=False),
        sa.Column("admin_verified", sa.Boolean(), nullable=False),
        sa.Column("verified_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["trip_id"], ["trips.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "stop_search_logs",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("stop_id", sa.Integer(), nullable=True),
        sa.Column("query_text", sa.String(length=255), nullable=False),
        sa.Column("searched_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["stop_id"], ["stops.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "ads",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("image_url", sa.String(length=512), nullable=False),
        sa.Column("target_stop_id", sa.Integer(), nullable=True),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("impressions", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["target_stop_id"], ["stops.id"]),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("ads")
    op.drop_table("stop_search_logs")
    op.drop_table("incidents")
    op.drop_table("trip_pings")
    op.drop_table("trips")
    op.drop_table("stops")
    op.drop_table("routes")
    op.drop_index("ix_buses_registration_number", table_name="buses")
    op.drop_table("buses")
    op.drop_index("ix_crew_phone", table_name="crew")
    op.drop_table("crew")
    op.drop_index("ix_operators_email", table_name="operators")
    op.drop_table("operators")

"""Add trip progress and the ping history index.

Revision ID: 0002_trip_progress
Revises: 0001_initial_schema
Create Date: 2026-10-26
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "0002_trip_progress"
down_revision: Union[str, None] = "0001_initial_schema"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "trips",
        sa.Column("last_stop_sequence", sa.Integer(), nullable=True),
    )
    op.create_index(
        "ix_trip_pings_trip_id_recorded_at",
        "trip_pings",
        ["trip_id", "recorded_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_trip_pings_trip_id_recorded_at", table_name="trip_pings")
    op.drop_column("trips", "last_stop_sequence")

"""Merge calendar integration

Revision ID: 277687f44262
Revises: 001, calendar_integration_001
Create Date: 2025-12-21 23:00:19.660604

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '277687f44262'
down_revision: Union[str, None] = ('001', 'calendar_integration_001')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
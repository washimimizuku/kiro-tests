"""Add calendar integration tables

Revision ID: calendar_integration_001
Revises: 
Create Date: 2024-12-21 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'calendar_integration_001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create calendar_connections table
    op.create_table('calendar_connections',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('provider', sa.Enum('google', 'outlook', name='calendarprovider'), nullable=False),
        sa.Column('status', sa.Enum('connected', 'disconnected', 'error', 'expired', name='calendarconnectionstatus'), nullable=False),
        sa.Column('access_token', sa.Text(), nullable=True),
        sa.Column('refresh_token', sa.Text(), nullable=True),
        sa.Column('token_expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('provider_user_id', sa.String(length=255), nullable=True),
        sa.Column('provider_email', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # Create calendar_events table
    op.create_table('calendar_events',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('connection_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('provider_event_id', sa.String(length=255), nullable=False),
        sa.Column('title', sa.String(length=500), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('start_time', sa.DateTime(timezone=True), nullable=False),
        sa.Column('end_time', sa.DateTime(timezone=True), nullable=False),
        sa.Column('attendees', postgresql.ARRAY(sa.String()), nullable=False),
        sa.Column('location', sa.String(length=500), nullable=True),
        sa.Column('meeting_url', sa.Text(), nullable=True),
        sa.Column('organizer', sa.String(length=255), nullable=True),
        sa.Column('event_metadata', sa.JSON(), nullable=False),
        sa.Column('last_synced_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['connection_id'], ['calendar_connections.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # Create activity_suggestions table
    op.create_table('activity_suggestions',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('connection_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('calendar_event_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('suggested_title', sa.String(length=500), nullable=False),
        sa.Column('suggested_description', sa.Text(), nullable=True),
        sa.Column('suggested_category', sa.String(length=100), nullable=False),
        sa.Column('suggested_tags', postgresql.ARRAY(sa.String()), nullable=False),
        sa.Column('confidence_score', sa.Float(), nullable=False),
        sa.Column('reasoning', sa.Text(), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False),
        sa.Column('activity_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['activity_id'], ['activities.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['calendar_event_id'], ['calendar_events.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['connection_id'], ['calendar_connections.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # Create calendar_integration_settings table
    op.create_table('calendar_integration_settings',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('auto_sync_enabled', sa.Boolean(), nullable=False),
        sa.Column('sync_frequency_hours', sa.Integer(), nullable=False),
        sa.Column('suggestion_threshold', sa.Float(), nullable=False),
        sa.Column('excluded_calendars', postgresql.ARRAY(sa.String()), nullable=False),
        sa.Column('excluded_keywords', postgresql.ARRAY(sa.String()), nullable=False),
        sa.Column('include_declined_events', sa.Boolean(), nullable=False),
        sa.Column('include_all_day_events', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id')
    )


def downgrade() -> None:
    op.drop_table('calendar_integration_settings')
    op.drop_table('activity_suggestions')
    op.drop_table('calendar_events')
    op.drop_table('calendar_connections')
    op.execute('DROP TYPE IF EXISTS calendarconnectionstatus')
    op.execute('DROP TYPE IF EXISTS calendarprovider')
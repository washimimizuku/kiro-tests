"""OAuth clients for calendar providers."""

import json
import secrets
from datetime import datetime, timedelta
from typing import Dict, Optional, Tuple
from urllib.parse import urlencode

import httpx
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import Flow
from googleapiclient.discovery import build
from msal import ConfidentialClientApplication

from app.core.config import get_settings
from app.services.calendar.schemas import CalendarProvider, CalendarEvent

settings = get_settings()


class GoogleCalendarOAuthClient:
    """Google Calendar OAuth client."""
    
    def __init__(self):
        self.client_id = settings.GOOGLE_CLIENT_ID
        self.client_secret = settings.GOOGLE_CLIENT_SECRET
        self.redirect_uri = settings.GOOGLE_REDIRECT_URI
        self.scopes = [
            'https://www.googleapis.com/auth/calendar.readonly',
            'https://www.googleapis.com/auth/userinfo.email'
        ]
    
    def get_authorization_url(self) -> Tuple[str, str]:
        """Get OAuth authorization URL and state."""
        flow = Flow.from_client_config(
            {
                "web": {
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                    "token_uri": "https://oauth2.googleapis.com/token",
                }
            },
            scopes=self.scopes
        )
        flow.redirect_uri = self.redirect_uri
        
        authorization_url, state = flow.authorization_url(
            access_type='offline',
            include_granted_scopes='true',
            prompt='consent'
        )
        
        return authorization_url, state
    
    async def exchange_code_for_tokens(self, authorization_code: str, state: str) -> Dict:
        """Exchange authorization code for access and refresh tokens."""
        flow = Flow.from_client_config(
            {
                "web": {
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                    "token_uri": "https://oauth2.googleapis.com/token",
                }
            },
            scopes=self.scopes,
            state=state
        )
        flow.redirect_uri = self.redirect_uri
        
        flow.fetch_token(code=authorization_code)
        
        credentials = flow.credentials
        
        # Get user info
        user_info = await self._get_user_info(credentials.token)
        
        return {
            'access_token': credentials.token,
            'refresh_token': credentials.refresh_token,
            'expires_at': credentials.expiry,
            'provider_user_id': user_info.get('id'),
            'provider_email': user_info.get('email')
        }
    
    async def refresh_access_token(self, refresh_token: str) -> Dict:
        """Refresh access token using refresh token."""
        credentials = Credentials(
            token=None,
            refresh_token=refresh_token,
            token_uri="https://oauth2.googleapis.com/token",
            client_id=self.client_id,
            client_secret=self.client_secret
        )
        
        credentials.refresh(Request())
        
        return {
            'access_token': credentials.token,
            'expires_at': credentials.expiry
        }
    
    async def get_calendar_events(
        self, 
        access_token: str, 
        start_time: datetime, 
        end_time: datetime
    ) -> list[CalendarEvent]:
        """Fetch calendar events from Google Calendar."""
        credentials = Credentials(token=access_token)
        service = build('calendar', 'v3', credentials=credentials)
        
        # Get events from primary calendar
        events_result = service.events().list(
            calendarId='primary',
            timeMin=start_time.isoformat(),
            timeMax=end_time.isoformat(),
            singleEvents=True,
            orderBy='startTime'
        ).execute()
        
        events = events_result.get('items', [])
        calendar_events = []
        
        for event in events:
            # Skip events without start time
            if 'start' not in event:
                continue
                
            start = event['start'].get('dateTime', event['start'].get('date'))
            end = event['end'].get('dateTime', event['end'].get('date'))
            
            # Parse datetime
            if 'T' in start:
                start_dt = datetime.fromisoformat(start.replace('Z', '+00:00'))
                end_dt = datetime.fromisoformat(end.replace('Z', '+00:00'))
            else:
                # All-day event
                start_dt = datetime.fromisoformat(f"{start}T00:00:00+00:00")
                end_dt = datetime.fromisoformat(f"{end}T23:59:59+00:00")
            
            # Extract attendees
            attendees = []
            if 'attendees' in event:
                attendees = [attendee.get('email', '') for attendee in event['attendees']]
            
            # Extract meeting URL
            meeting_url = None
            if 'conferenceData' in event and 'entryPoints' in event['conferenceData']:
                for entry_point in event['conferenceData']['entryPoints']:
                    if entry_point.get('entryPointType') == 'video':
                        meeting_url = entry_point.get('uri')
                        break
            
            calendar_event = CalendarEvent(
                id=event['id'],
                title=event.get('summary', 'No Title'),
                description=event.get('description', ''),
                start_time=start_dt,
                end_time=end_dt,
                attendees=attendees,
                location=event.get('location'),
                meeting_url=meeting_url,
                organizer=event.get('organizer', {}).get('email'),
                provider=CalendarProvider.GOOGLE,
                provider_event_id=event['id']
            )
            calendar_events.append(calendar_event)
        
        return calendar_events
    
    async def _get_user_info(self, access_token: str) -> Dict:
        """Get user information from Google."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                'https://www.googleapis.com/oauth2/v2/userinfo',
                headers={'Authorization': f'Bearer {access_token}'}
            )
            response.raise_for_status()
            return response.json()


class OutlookCalendarOAuthClient:
    """Microsoft Outlook Calendar OAuth client."""
    
    def __init__(self):
        self.client_id = settings.MICROSOFT_CLIENT_ID
        self.client_secret = settings.MICROSOFT_CLIENT_SECRET
        self.redirect_uri = settings.MICROSOFT_REDIRECT_URI
        self.authority = "https://login.microsoftonline.com/common"
        self.scopes = [
            "https://graph.microsoft.com/Calendars.Read",
            "https://graph.microsoft.com/User.Read"
        ]
        
        self.app = ConfidentialClientApplication(
            client_id=self.client_id,
            client_credential=self.client_secret,
            authority=self.authority
        )
    
    def get_authorization_url(self) -> Tuple[str, str]:
        """Get OAuth authorization URL and state."""
        state = secrets.token_urlsafe(32)
        
        auth_url = self.app.get_authorization_request_url(
            scopes=self.scopes,
            redirect_uri=self.redirect_uri,
            state=state
        )
        
        return auth_url, state
    
    async def exchange_code_for_tokens(self, authorization_code: str, state: str) -> Dict:
        """Exchange authorization code for access and refresh tokens."""
        result = self.app.acquire_token_by_authorization_code(
            code=authorization_code,
            scopes=self.scopes,
            redirect_uri=self.redirect_uri
        )
        
        if "error" in result:
            raise Exception(f"OAuth error: {result.get('error_description', result['error'])}")
        
        # Get user info
        user_info = await self._get_user_info(result['access_token'])
        
        expires_at = None
        if 'expires_in' in result:
            expires_at = datetime.utcnow() + timedelta(seconds=result['expires_in'])
        
        return {
            'access_token': result['access_token'],
            'refresh_token': result.get('refresh_token'),
            'expires_at': expires_at,
            'provider_user_id': user_info.get('id'),
            'provider_email': user_info.get('mail') or user_info.get('userPrincipalName')
        }
    
    async def refresh_access_token(self, refresh_token: str) -> Dict:
        """Refresh access token using refresh token."""
        result = self.app.acquire_token_by_refresh_token(
            refresh_token=refresh_token,
            scopes=self.scopes
        )
        
        if "error" in result:
            raise Exception(f"Token refresh error: {result.get('error_description', result['error'])}")
        
        expires_at = None
        if 'expires_in' in result:
            expires_at = datetime.utcnow() + timedelta(seconds=result['expires_in'])
        
        return {
            'access_token': result['access_token'],
            'expires_at': expires_at
        }
    
    async def get_calendar_events(
        self, 
        access_token: str, 
        start_time: datetime, 
        end_time: datetime
    ) -> list[CalendarEvent]:
        """Fetch calendar events from Microsoft Graph."""
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        }
        
        # Format dates for Microsoft Graph API
        start_str = start_time.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
        end_str = end_time.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
        
        url = f"https://graph.microsoft.com/v1.0/me/events"
        params = {
            '$filter': f"start/dateTime ge '{start_str}' and end/dateTime le '{end_str}'",
            '$orderby': 'start/dateTime',
            '$select': 'id,subject,body,start,end,attendees,location,onlineMeeting,organizer'
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers=headers, params=params)
            response.raise_for_status()
            data = response.json()
        
        events = data.get('value', [])
        calendar_events = []
        
        for event in events:
            # Parse datetime
            start_dt = datetime.fromisoformat(event['start']['dateTime'].replace('Z', '+00:00'))
            end_dt = datetime.fromisoformat(event['end']['dateTime'].replace('Z', '+00:00'))
            
            # Extract attendees
            attendees = []
            if 'attendees' in event:
                attendees = [attendee['emailAddress']['address'] for attendee in event['attendees']]
            
            # Extract meeting URL
            meeting_url = None
            if 'onlineMeeting' in event and event['onlineMeeting']:
                meeting_url = event['onlineMeeting'].get('joinUrl')
            
            calendar_event = CalendarEvent(
                id=event['id'],
                title=event.get('subject', 'No Title'),
                description=event.get('body', {}).get('content', ''),
                start_time=start_dt,
                end_time=end_dt,
                attendees=attendees,
                location=event.get('location', {}).get('displayName'),
                meeting_url=meeting_url,
                organizer=event.get('organizer', {}).get('emailAddress', {}).get('address'),
                provider=CalendarProvider.OUTLOOK,
                provider_event_id=event['id']
            )
            calendar_events.append(calendar_event)
        
        return calendar_events
    
    async def _get_user_info(self, access_token: str) -> Dict:
        """Get user information from Microsoft Graph."""
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                'https://graph.microsoft.com/v1.0/me',
                headers=headers
            )
            response.raise_for_status()
            return response.json()


class CalendarOAuthClientFactory:
    """Factory for creating OAuth clients."""
    
    @staticmethod
    def create_client(provider: CalendarProvider):
        """Create OAuth client for the specified provider."""
        if provider == CalendarProvider.GOOGLE:
            return GoogleCalendarOAuthClient()
        elif provider == CalendarProvider.OUTLOOK:
            return OutlookCalendarOAuthClient()
        else:
            raise ValueError(f"Unsupported calendar provider: {provider}")
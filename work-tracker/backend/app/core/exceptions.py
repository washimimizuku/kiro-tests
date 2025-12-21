"""
Custom Exceptions

Application-specific exceptions for error handling.
"""


class WorkTrackerException(Exception):
    """Base exception for Work Tracker application."""
    pass


class NotFoundError(WorkTrackerException):
    """Exception raised when a requested resource is not found."""
    pass


class ValidationError(WorkTrackerException):
    """Exception raised when data validation fails."""
    pass


class AuthenticationError(WorkTrackerException):
    """Exception raised when authentication fails."""
    pass


class AuthorizationError(WorkTrackerException):
    """Exception raised when authorization fails."""
    pass


class ExternalServiceError(WorkTrackerException):
    """Exception raised when external service calls fail."""
    pass
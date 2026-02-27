import firebase_admin
from firebase_admin import credentials, messaging
import os

# Initialize Firebase Admin SDK
_firebase_initialized = False


def _initialize_firebase():
    global _firebase_initialized
    if not _firebase_initialized:
        cred_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            'serviceAccountKey.json'
        )
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True


class NotificationService:
    def __init__(self):
        _initialize_firebase()

    def send_to_token(self, token: str, title: str, body: str, data: dict = None) -> dict:
        """
        Send notification to a specific device token.

        Args:
            token: FCM device token
            title: Notification title
            body: Notification body
            data: Optional data payload

        Returns:
            dict with success status and message_id or error
        """
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                token=token,
            )

            response = messaging.send(message)
            return {'success': True, 'message_id': response}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def send_to_multiple_tokens(self, tokens: list, title: str, body: str, data: dict = None) -> dict:
        """
        Send notification to multiple device tokens.

        Args:
            tokens: List of FCM device tokens
            title: Notification title
            body: Notification body
            data: Optional data payload

        Returns:
            dict with success count, failure count, and responses
        """
        if not tokens:
            return {'success': True, 'success_count': 0, 'failure_count': 0, 'responses': []}

        try:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                tokens=tokens,
            )

            response = messaging.send_each_for_multicast(message)

            responses = []
            for idx, send_response in enumerate(response.responses):
                if send_response.success:
                    responses.append({
                        'token': tokens[idx],
                        'success': True,
                        'message_id': send_response.message_id
                    })
                else:
                    responses.append({
                        'token': tokens[idx],
                        'success': False,
                        'error': str(send_response.exception)
                    })

            return {
                'success': True,
                'success_count': response.success_count,
                'failure_count': response.failure_count,
                'responses': responses
            }
        except Exception as e:
            return {'success': False, 'error': str(e)}

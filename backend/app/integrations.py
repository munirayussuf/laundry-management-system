import base64
import os
from datetime import datetime, timedelta, timezone
from typing import Any
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

import httpx


class IntegrationError(RuntimeError):
    pass


def normalise_ke_phone(raw: str) -> str:
    digits = ''.join(character for character in raw if character.isdigit())
    if digits.startswith('0'):
        digits = '254' + digits[1:]
    if len(digits) == 9 and digits[0] in ('1', '7'):
        digits = '254' + digits
    if len(digits) != 12 or not digits.startswith('254') or digits[3] not in ('1', '7'):
        raise ValueError('Enter a valid Kenyan mobile number.')
    return digits


def sms_is_configured() -> bool:
    return bool(os.getenv('AT_USERNAME') and os.getenv('AT_API_KEY'))


def send_sms(phone: str, message: str) -> dict[str, Any]:
    username = os.getenv('AT_USERNAME')
    api_key = os.getenv('AT_API_KEY')
    if not username or not api_key:
        raise IntegrationError('SMS gateway is not configured.')

    try:
        recipient = '+' + normalise_ke_phone(phone)
    except ValueError as error:
        raise IntegrationError(str(error)) from error

    form = {'username': username, 'to': recipient, 'message': message}
    sender_id = os.getenv('AT_SENDER_ID')
    if sender_id:
        form['from'] = sender_id

    try:
        response = httpx.post(
            os.getenv('AT_SMS_URL') or 'https://api.africastalking.com/version1/messaging',
            data=form,
            headers={
                'apiKey': api_key,
                'Accept': 'application/json',
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            timeout=15,
        )
        response.raise_for_status()
        payload = response.json()
    except (httpx.HTTPError, ValueError) as error:
        raise IntegrationError('SMS gateway request failed.') from error

    if not isinstance(payload, dict):
        raise IntegrationError('SMS gateway returned an invalid response.')
    message_data = payload.get('SMSMessageData')
    if not isinstance(message_data, dict):
        raise IntegrationError('SMS gateway returned an invalid response.')
    recipients = message_data.get('Recipients', [])
    if not isinstance(recipients, list) or not recipients or not isinstance(recipients[0], dict):
        raise IntegrationError('SMS gateway did not accept the message.')
    try:
        status_code = int(recipients[0].get('statusCode', 0))
    except (TypeError, ValueError) as error:
        raise IntegrationError('SMS gateway returned an invalid delivery status.') from error
    if status_code not in (101, 102):
        raise IntegrationError(
            recipients[0].get('status', 'SMS gateway rejected the message.')
        )
    return {
        'success': True,
        'detail': message_data.get('Message', 'Message accepted.'),
    }


def mpesa_is_configured() -> bool:
    return all(
        os.getenv(name)
        for name in (
            'MPESA_CONSUMER_KEY',
            'MPESA_CONSUMER_SECRET',
            'MPESA_SHORTCODE',
            'MPESA_PASSKEY',
            'MPESA_CALLBACK_URL',
            'MPESA_CALLBACK_TOKEN',
        )
    )


def initiate_mpesa_stk(phone: str, amount: float, payment_id: str) -> tuple[str, str]:
    required = (
        'MPESA_CONSUMER_KEY',
        'MPESA_CONSUMER_SECRET',
        'MPESA_SHORTCODE',
        'MPESA_PASSKEY',
        'MPESA_CALLBACK_URL',
        'MPESA_CALLBACK_TOKEN',
    )
    if not all(os.getenv(name) for name in required):
        raise IntegrationError('Mobile-money gateway is not configured.')

    try:
        phone_number = normalise_ke_phone(phone)
    except ValueError as error:
        raise IntegrationError(str(error)) from error

    environment = os.getenv('MPESA_ENV', 'sandbox').lower()
    if environment not in ('sandbox', 'production'):
        raise IntegrationError('MPESA_ENV must be sandbox or production.')
    base_url = (
        'https://api.safaricom.co.ke'
        if environment == 'production'
        else 'https://sandbox.safaricom.co.ke'
    )
    callback = _callback_url()
    shortcode = os.environ['MPESA_SHORTCODE']
    stamp = datetime.now(timezone(timedelta(hours=3))).strftime('%Y%m%d%H%M%S')
    password = base64.b64encode(
        f"{shortcode}{os.environ['MPESA_PASSKEY']}{stamp}".encode()
    ).decode()
    transaction_type = os.getenv('MPESA_TRANSACTION_TYPE', 'CustomerPayBillOnline')
    if transaction_type not in ('CustomerPayBillOnline', 'CustomerBuyGoodsOnline'):
        raise IntegrationError('Unsupported MPESA_TRANSACTION_TYPE.')
    party_b = os.getenv('MPESA_PARTY_B') or shortcode

    try:
        with httpx.Client(timeout=20) as client:
            token_response = client.get(
                f'{base_url}/oauth/v1/generate',
                params={'grant_type': 'client_credentials'},
                auth=(
                    os.environ['MPESA_CONSUMER_KEY'],
                    os.environ['MPESA_CONSUMER_SECRET'],
                ),
            )
            token_response.raise_for_status()
            token_payload = token_response.json()
            if not isinstance(token_payload, dict):
                raise IntegrationError('Mobile-money gateway returned an invalid token response.')
            access_token = token_payload.get('access_token')
            if not access_token:
                raise IntegrationError('Mobile-money gateway did not issue an access token.')
            response = client.post(
                f'{base_url}/mpesa/stkpush/v1/processrequest',
                headers={'Authorization': f'Bearer {access_token}'},
                json={
                    'BusinessShortCode': shortcode,
                    'Password': password,
                    'Timestamp': stamp,
                    'TransactionType': transaction_type,
                    'Amount': max(1, round(amount)),
                    'PartyA': phone_number,
                    'PartyB': party_b,
                    'PhoneNumber': phone_number,
                    'CallBackURL': callback,
                    'AccountReference': payment_id[:12],
                    'TransactionDesc': 'Laundry service payment',
                },
            )
            response.raise_for_status()
            payload = response.json()
    except httpx.HTTPError as error:
        raise IntegrationError('Mobile-money gateway request failed.') from error
    except ValueError as error:
        raise IntegrationError('Mobile-money gateway returned an invalid response.') from error

    if not isinstance(payload, dict):
        raise IntegrationError('Mobile-money gateway returned an invalid response.')
    checkout_id = payload.get('CheckoutRequestID')
    if str(payload.get('ResponseCode')) != '0' or not checkout_id:
        raise IntegrationError(
            payload.get('CustomerMessage')
            or payload.get('errorMessage')
            or 'Mobile-money gateway rejected the payment request.'
        )
    return checkout_id, payload.get('CustomerMessage', 'Payment prompt sent.')


def _callback_url() -> str:
    parts = urlsplit(os.environ['MPESA_CALLBACK_URL'])
    if parts.scheme != 'https' or not parts.netloc:
        raise IntegrationError('MPESA_CALLBACK_URL must be a public HTTPS URL.')
    query = dict(parse_qsl(parts.query, keep_blank_values=True))
    query['token'] = os.environ['MPESA_CALLBACK_TOKEN']
    return urlunsplit(
        (parts.scheme, parts.netloc, parts.path, urlencode(query), parts.fragment)
    )


def mpesa_callback_token() -> str | None:
    return os.getenv('MPESA_CALLBACK_TOKEN')

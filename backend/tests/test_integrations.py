import os
import unittest
from unittest.mock import Mock, patch

from app.integrations import (
    IntegrationError,
    initiate_mpesa_stk,
    normalise_ke_phone,
    send_sms,
)


class KenyanPhoneTests(unittest.TestCase):
    def test_normalises_local_and_international_mobile_numbers(self):
        self.assertEqual(normalise_ke_phone('0712345678'), '254712345678')
        self.assertEqual(normalise_ke_phone('+254 112 345 678'), '254112345678')

    def test_rejects_non_mobile_or_incomplete_numbers(self):
        for phone in ('123', '254212345678', '071234567'):
            with self.subTest(phone=phone), self.assertRaises(ValueError):
                normalise_ke_phone(phone)


class SmsIntegrationTests(unittest.TestCase):
    @patch.dict(os.environ, {'AT_USERNAME': 'sandbox', 'AT_API_KEY': 'test-key'}, clear=True)
    @patch('app.integrations.httpx.post')
    def test_sends_form_encoded_message_and_checks_provider_acceptance(self, post):
        response = Mock()
        response.json.return_value = {
            'SMSMessageData': {
                'Message': 'Sent to 1/1',
                'Recipients': [{'statusCode': 101, 'status': 'Success'}],
            },
        }
        post.return_value = response

        result = send_sms('0712345678', 'Order received')

        self.assertTrue(result['success'])
        self.assertEqual(
            post.call_args.args[0],
            'https://api.africastalking.com/version1/messaging',
        )
        self.assertEqual(post.call_args.kwargs['data']['to'], '+254712345678')
        self.assertEqual(post.call_args.kwargs['data']['username'], 'sandbox')
        self.assertEqual(post.call_args.kwargs['headers']['apiKey'], 'test-key')

    @patch.dict(os.environ, {}, clear=True)
    def test_requires_credentials(self):
        with self.assertRaises(IntegrationError):
            send_sms('0712345678', 'Order received')


class MpesaIntegrationTests(unittest.TestCase):
    @patch.dict(
        os.environ,
        {
            'MPESA_ENV': 'sandbox',
            'MPESA_CONSUMER_KEY': 'consumer-key',
            'MPESA_CONSUMER_SECRET': 'consumer-secret',
            'MPESA_SHORTCODE': '174379',
            'MPESA_PASSKEY': 'passkey',
            'MPESA_CALLBACK_URL': 'https://api.example.test/api/payments/mpesa/callback',
            'MPESA_CALLBACK_TOKEN': 'callback-secret',
        },
        clear=True,
    )
    @patch('app.integrations.httpx.Client')
    def test_stk_push_uses_server_credentials_and_signed_callback_url(self, client_factory):
        client = client_factory.return_value.__enter__.return_value
        token_response = Mock()
        token_response.json.return_value = {'access_token': 'access-token'}
        stk_response = Mock()
        stk_response.json.return_value = {
            'ResponseCode': '0',
            'CheckoutRequestID': 'checkout-123',
            'CustomerMessage': 'Prompt sent',
        }
        client.get.return_value = token_response
        client.post.return_value = stk_response

        checkout_id, message = initiate_mpesa_stk('0712345678', 250, 'payment-reference')

        self.assertEqual(checkout_id, 'checkout-123')
        self.assertEqual(message, 'Prompt sent')
        self.assertEqual(client.post.call_args.kwargs['json']['PhoneNumber'], '254712345678')
        self.assertEqual(
            client.post.call_args.kwargs['json']['CallBackURL'],
            'https://api.example.test/api/payments/mpesa/callback?token=callback-secret',
        )
        self.assertEqual(
            client.post.call_args.kwargs['headers']['Authorization'],
            'Bearer access-token',
        )

    @patch.dict(os.environ, {}, clear=True)
    def test_requires_provider_configuration(self):
        with self.assertRaises(IntegrationError):
            initiate_mpesa_stk('0712345678', 250, 'payment-reference')


if __name__ == '__main__':
    unittest.main()

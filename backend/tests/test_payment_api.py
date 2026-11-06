import os
import tempfile
import unittest
import uuid
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from fastapi.testclient import TestClient


_database_file = tempfile.NamedTemporaryFile(suffix='.sqlite', delete=False)
_database_file.close()
os.environ['DATABASE_URL'] = f"sqlite:///{Path(_database_file.name).as_posix()}"
os.environ['JWT_SECRET'] = 'test-secret'
for _name in (
    'MPESA_CONSUMER_KEY',
    'MPESA_CONSUMER_SECRET',
    'MPESA_SHORTCODE',
    'MPESA_PASSKEY',
    'MPESA_CALLBACK_URL',
    'MPESA_CALLBACK_TOKEN',
    'AT_USERNAME',
    'AT_API_KEY',
):
    os.environ.pop(_name, None)

from app import main as backend  # noqa: E402


class PaymentApiTests(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(backend.app)
        self.uid = str(uuid.uuid4())
        self.provider_id = str(uuid.uuid4())
        self.service_id = str(uuid.uuid4())
        with backend.Session(backend.engine) as db:
            user = backend.User(
                uid=self.uid,
                name='Test Customer',
                email=f'{self.uid}@example.test',
                password_hash='unused',
                phone='0712345678',
            )
            provider = backend.Provider(
                id=self.provider_id,
                ownerId=str(uuid.uuid4()),
                providerName='Test Laundry',
                providerType='formalLaundry',
                washingMethod='machineWashing',
                ironingMethod='electricIron',
                phone='0712345679',
                email=f'{self.provider_id}@example.test',
                isActive=True,
            )
            service = backend.Service(
                id=self.service_id,
                providerId=self.provider_id,
                name='Wash',
                description='',
                price=100,
                pricingUnit='load',
                isAvailable=True,
            )
            db.add_all((user, provider, service))
            db.commit()
        token = backend.token_for(SimpleNamespace(uid=self.uid))
        self.headers = {'Authorization': f'Bearer {token}'}

    def tearDown(self):
        with backend.Session(backend.engine) as db:
            db.query(backend.Payment).delete()
            db.query(backend.Order).delete()
            db.query(backend.Service).delete()
            db.query(backend.Provider).delete()
            db.query(backend.User).delete()
            db.commit()

    def create_order(self):
        response = self.client.post(
            '/api/orders',
            headers=self.headers,
            json={
                'providerId': self.provider_id,
                'providerName': 'Untrusted client name',
                'items': [{
                    'serviceId': self.service_id,
                    'quantity': 1,
                    'unitPrice': 0.01,
                    'serviceName': 'Forged service',
                }],
                'washingMethod': 'machineWashing',
                'ironingMethod': 'electricIron',
                'pickupLocation': {'label': 'Home', 'latitude': 0, 'longitude': 0},
                'deliveryLocation': {'label': 'Home', 'latitude': 0, 'longitude': 0},
                'scheduledDate': '2026-11-07T10:00:00+00:00',
                'scheduledTime': '10:00',
                'paymentMethod': 'mobileMoney',
            },
        )
        self.assertEqual(response.status_code, 200)
        return response.json()

    def test_order_and_payment_use_server_side_service_price(self):
        order = self.create_order()
        self.assertEqual(order['totalAmount'], 100)
        self.assertEqual(order['items'][0]['unitPrice'], 100)
        response = self.client.post(
            '/api/payments',
            headers=self.headers,
            json={
                'id': f'payment-{self.uid}',
                'orderId': order['id'],
                'providerId': self.provider_id,
                'method': 'mobileMoney',
                'amount': 0.01,
                'customerPhone': '0712345678',
            },
        )
        self.assertEqual(response.status_code, 503)
        payment = self.client.get(
            f"/api/payments/payment-{self.uid}",
            headers=self.headers,
        ).json()
        self.assertEqual(payment['amount'], 100)
        self.assertEqual(payment['status'], 'failed')

    def test_customer_cannot_mark_an_order_paid(self):
        order = self.create_order()
        response = self.client.put(
            f"/api/orders/{order['id']}/payment-status",
            headers=self.headers,
            json={'status': 'paid'},
        )
        self.assertEqual(response.status_code, 403)

    def test_mobile_money_callback_requires_shared_secret(self):
        response = self.client.post(
            '/api/payments/mpesa/callback?token=wrong',
            json={},
        )
        self.assertEqual(response.status_code, 403)

    def test_valid_payment_callback_marks_payment_and_order_paid(self):
        order = self.create_order()
        payment_id = f'payment-{self.uid}'
        with backend.Session(backend.engine) as db:
            db.add(backend.Payment(
                id=payment_id,
                orderId=order['id'],
                customerId=self.uid,
                providerId=self.provider_id,
                amount=100,
                method='mobileMoney',
                providerReference='checkout-123',
                status='pending',
            ))
            db.commit()
        callback = {
            'Body': {
                'stkCallback': {
                    'CheckoutRequestID': 'checkout-123',
                    'ResultCode': 0,
                    'CallbackMetadata': {
                        'Item': [
                            {'Name': 'Amount', 'Value': 100},
                            {'Name': 'MpesaReceiptNumber', 'Value': 'QWE123'},
                        ],
                    },
                },
            },
        }
        with patch.dict(os.environ, {'MPESA_CALLBACK_TOKEN': 'callback-secret'}):
            response = self.client.post(
                '/api/payments/mpesa/callback?token=callback-secret',
                json=callback,
            )
        self.assertEqual(response.status_code, 200)
        payment = self.client.get(
            f'/api/payments/{payment_id}',
            headers=self.headers,
        ).json()
        updated_order = self.client.get(
            f"/api/orders/{order['id']}",
            headers=self.headers,
        ).json()
        self.assertEqual(payment['status'], 'paid')
        self.assertEqual(payment['providerReference'], 'QWE123')
        self.assertEqual(updated_order['paymentStatus'], 'paid')

    def test_callback_with_wrong_amount_does_not_confirm_payment(self):
        order = self.create_order()
        with backend.Session(backend.engine) as db:
            db.add(backend.Payment(
                id=f'payment-{self.uid}',
                orderId=order['id'],
                customerId=self.uid,
                providerId=self.provider_id,
                amount=100,
                method='mobileMoney',
                providerReference='checkout-amount-mismatch',
                status='pending',
            ))
            db.commit()
        callback = {
            'Body': {
                'stkCallback': {
                    'CheckoutRequestID': 'checkout-amount-mismatch',
                    'ResultCode': 0,
                    'CallbackMetadata': {'Item': [{'Name': 'Amount', 'Value': 1}]},
                },
            },
        }
        with patch.dict(os.environ, {'MPESA_CALLBACK_TOKEN': 'callback-secret'}):
            response = self.client.post(
                '/api/payments/mpesa/callback?token=callback-secret',
                json=callback,
            )
        self.assertEqual(response.status_code, 200)
        payment = self.client.get(
            f'/api/payments/payment-{self.uid}',
            headers=self.headers,
        ).json()
        self.assertEqual(payment['status'], 'failed')


def tearDownModule():
    backend.engine.dispose()
    Path(_database_file.name).unlink(missing_ok=True)


if __name__ == '__main__':
    unittest.main()

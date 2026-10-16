"""Import a Firebase/Firestore JSON export into PostgreSQL.
Expected directory: firebase_export/{users,providers,services,orders,payments,notifications,reviews}.json
Each file may contain a JSON array of documents. Timestamps may be ISO strings or Firestore REST timestamp objects.
Usage: DATABASE_URL=postgresql+psycopg://... python tools/firebase_to_postgres.py firebase_export
"""
import json, sys, os
from pathlib import Path
from datetime import datetime, timezone
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'backend'))
from app.main import engine, Base, User, Provider, Service, Order, Payment, Notification, Review
from sqlalchemy.orm import Session

def ts(v):
    if isinstance(v,dict) and 'timestampValue' in v:v=v['timestampValue']
    if not v:return datetime.now(timezone.utc)
    if isinstance(v,str):return datetime.fromisoformat(v.replace('Z','+00:00'))
    return datetime.now(timezone.utc)
def load(path):
    if not path.exists():return []
    raw=json.loads(path.read_text())
    if isinstance(raw,list):return raw
    return raw.get('documents',raw.get('items',[]))
def clean(d):
    if 'fields' in d:d={k:v.get('stringValue',v.get('integerValue',v.get('doubleValue',v.get('booleanValue',v.get('timestampValue',v.get('arrayValue',v.get('mapValue',v))))))) for k,v in d['fields'].items()}
    return d
Base.metadata.create_all(engine)
root=Path(sys.argv[1] if len(sys.argv)>1 else 'firebase_export')
with Session(engine) as db:
    for filename,cls in [('users',User),('providers',Provider),('services',Service),('orders',Order),('payments',Payment),('notifications',Notification),('reviews',Review)]:
        for raw in load(root/f'{filename}.json'):
            d=clean(raw); did=d.get('uid') or d.get('id') or d.get('name')
            if not did:continue
            if cls is User:
                # Firebase Auth password hashes cannot be imported as plaintext. Existing users must reset passwords.
                obj=User(uid=did,name=d.get('name',''),email=d.get('email',''),password_hash='!MIGRATED_PASSWORD_RESET_REQUIRED!',phone=d.get('phone',''),role=d.get('role','customer'),profileImage=d.get('profileImage',''),location=d.get('location',''),latitude=d.get('latitude'),longitude=d.get('longitude'),createdAt=ts(d.get('createdAt')),updatedAt=ts(d.get('updatedAt')),isActive=d.get('isActive',True))
            elif cls is Provider: obj=Provider(id=did,ownerId=d.get('ownerId',''),providerName=d.get('providerName',''),providerType=d.get('providerType','formalLaundry'),washingMethod=d.get('washingMethod','machineWashing'),ironingMethod=d.get('ironingMethod','electricIron'),phone=d.get('phone',''),email=d.get('email',''),description=d.get('description',''),location=d.get('location',''),latitude=d.get('latitude',0),longitude=d.get('longitude',0),profileImage=d.get('profileImage',''),rating=d.get('rating',0),reviewCount=d.get('reviewCount',0),capacity=d.get('capacity',0),workingHours=d.get('workingHours',{'open':'07:00','close':'19:00'}),availability=d.get('availability',True),isVerified=d.get('isVerified',False),isActive=d.get('isActive',True),startingPrice=d.get('startingPrice',0),turnaroundHours=d.get('turnaroundHours',24),createdAt=ts(d.get('createdAt')),updatedAt=ts(d.get('updatedAt')))
            elif cls is Service: obj=Service(id=did,providerId=d.get('providerId',''),name=d.get('name',''),description=d.get('description',''),price=d.get('price',0),pricingUnit=d.get('pricingUnit','per kilogram'),isAvailable=d.get('isAvailable',True),createdAt=ts(d.get('createdAt')),updatedAt=ts(d.get('updatedAt')))
            elif cls is Order: obj=Order(id=did,customerId=d.get('customerId',''),customerName=d.get('customerName',''),providerId=d.get('providerId',''),providerName=d.get('providerName',''),items=d.get('items',[]),washingMethod=d.get('washingMethod','machineWashing'),ironingMethod=d.get('ironingMethod','electricIron'),pickupRequested=d.get('pickupRequested',True),deliveryRequested=d.get('deliveryRequested',True),pickupLocation=d.get('pickupLocation',{}),deliveryLocation=d.get('deliveryLocation',{}),scheduledDate=ts(d.get('scheduledDate')),scheduledTime=d.get('scheduledTime',''),totalAmount=d.get('totalAmount',0),paymentMethod=d.get('paymentMethod','mobileMoney'),paymentStatus=d.get('paymentStatus','pending'),orderStatus=d.get('orderStatus','pending'),notes=d.get('notes',''),createdAt=ts(d.get('createdAt')),updatedAt=ts(d.get('updatedAt')))
            elif cls is Payment: obj=Payment(id=did,orderId=d.get('orderId',''),customerId=d.get('customerId',''),providerId=d.get('providerId',''),amount=d.get('amount',0),method=d.get('method','mobileMoney'),status=d.get('status','pending'),providerReference=d.get('providerReference'),failureReason=d.get('failureReason'),createdAt=ts(d.get('createdAt')),updatedAt=ts(d.get('updatedAt')))
            elif cls is Notification: obj=Notification(id=did,userId=d.get('userId',''),title=d.get('title',''),body=d.get('body',''),type=d.get('type','general'),relatedOrderId=d.get('relatedOrderId'),isRead=d.get('isRead',False),createdAt=ts(d.get('createdAt')))
            else: obj=Review(id=did,orderId=d.get('orderId',''),customerId=d.get('customerId',''),customerName=d.get('customerName',''),providerId=d.get('providerId',''),rating=d.get('rating',0),comment=d.get('comment',''),createdAt=ts(d.get('createdAt')))
            if db.get(cls,did): continue
            db.add(obj)
        db.commit(); print('Imported',filename)

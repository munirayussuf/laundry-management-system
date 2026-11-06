import os, uuid, hashlib, math, logging, secrets
from datetime import datetime, timedelta, timezone
from typing import Optional
from urllib.parse import parse_qs
from fastapi import FastAPI, Depends, HTTPException, Query, Request
from fastapi.responses import PlainTextResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import create_engine, String, Boolean, DateTime, Float, Integer, Text, ForeignKey, JSON, select, desc, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, Session
from app.integrations import IntegrationError, initiate_mpesa_stk, mpesa_callback_token, mpesa_is_configured, normalise_ke_phone, send_sms, sms_is_configured

DATABASE_URL=os.getenv('DATABASE_URL','postgresql+psycopg://laundry:laundry@localhost:5432/laundry')
JWT_SECRET=os.getenv('JWT_SECRET','change-this-in-production')
JWT_ALG='HS256'; ACCESS_MINUTES=60*24*7
if DATABASE_URL.startswith('postgres://'):
    DATABASE_URL=DATABASE_URL.replace('postgres://','postgresql+psycopg://',1)
elif DATABASE_URL.startswith('postgresql://'):
    DATABASE_URL=DATABASE_URL.replace('postgresql://','postgresql+psycopg://',1)
engine=create_engine(DATABASE_URL, pool_pre_ping=True)
pwd=CryptContext(schemes=['bcrypt'],deprecated='auto'); oauth2=OAuth2PasswordBearer(tokenUrl='/api/auth/login')
class Base(DeclarativeBase): pass

def now(): return datetime.now(timezone.utc)
class User(Base):
    __tablename__='users'; uid:Mapped[str]=mapped_column(String(36),primary_key=True); name:Mapped[str]=mapped_column(String(160)); email:Mapped[str]=mapped_column(String(255),unique=True,index=True); password_hash:Mapped[str]=mapped_column(String(255)); phone:Mapped[str]=mapped_column(String(32),default=''); role:Mapped[str]=mapped_column(String(20),default='customer'); profileImage:Mapped[str]=mapped_column(Text,default=''); location:Mapped[str]=mapped_column(String(255),default=''); latitude:Mapped[Optional[float]]=mapped_column(Float,nullable=True); longitude:Mapped[Optional[float]]=mapped_column(Float,nullable=True); createdAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now); updatedAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now); isActive:Mapped[bool]=mapped_column(Boolean,default=True)
class Provider(Base):
    __tablename__='providers'; id:Mapped[str]=mapped_column(String(36),primary_key=True); ownerId:Mapped[str]=mapped_column(String(36),index=True); providerName:Mapped[str]=mapped_column(String(200)); providerType:Mapped[str]=mapped_column(String(30)); washingMethod:Mapped[str]=mapped_column(String(40)); ironingMethod:Mapped[str]=mapped_column(String(40)); phone:Mapped[str]=mapped_column(String(32)); email:Mapped[str]=mapped_column(String(255)); description:Mapped[str]=mapped_column(Text,default=''); location:Mapped[str]=mapped_column(String(255),default=''); latitude:Mapped[float]=mapped_column(Float,default=0); longitude:Mapped[float]=mapped_column(Float,default=0); profileImage:Mapped[str]=mapped_column(Text,default=''); rating:Mapped[float]=mapped_column(Float,default=0); reviewCount:Mapped[int]=mapped_column(Integer,default=0); capacity:Mapped[int]=mapped_column(Integer,default=0); workingHours:Mapped[dict]=mapped_column(JSON,default=lambda:{'open':'07:00','close':'19:00'}); availability:Mapped[bool]=mapped_column(Boolean,default=True); isVerified:Mapped[bool]=mapped_column(Boolean,default=False); isActive:Mapped[bool]=mapped_column(Boolean,default=True); startingPrice:Mapped[float]=mapped_column(Float,default=0); turnaroundHours:Mapped[int]=mapped_column(Integer,default=24); createdAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now); updatedAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now)
class Service(Base):
    __tablename__='services'; id:Mapped[str]=mapped_column(String(36),primary_key=True); providerId:Mapped[str]=mapped_column(ForeignKey('providers.id',ondelete='CASCADE'),index=True); name:Mapped[str]=mapped_column(String(160)); description:Mapped[str]=mapped_column(Text,default=''); price:Mapped[float]=mapped_column(Float); pricingUnit:Mapped[str]=mapped_column(String(80)); isAvailable:Mapped[bool]=mapped_column(Boolean,default=True); createdAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now); updatedAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now)
class Order(Base):
    __tablename__='orders'; id:Mapped[str]=mapped_column(String(36),primary_key=True); customerId:Mapped[str]=mapped_column(String(36),index=True); customerName:Mapped[str]=mapped_column(String(160)); providerId:Mapped[str]=mapped_column(String(36),index=True); providerName:Mapped[str]=mapped_column(String(200)); items:Mapped[list]=mapped_column(JSON); washingMethod:Mapped[str]=mapped_column(String(40)); ironingMethod:Mapped[str]=mapped_column(String(40)); pickupRequested:Mapped[bool]=mapped_column(Boolean,default=True); deliveryRequested:Mapped[bool]=mapped_column(Boolean,default=True); pickupLocation:Mapped[dict]=mapped_column(JSON); deliveryLocation:Mapped[dict]=mapped_column(JSON); scheduledDate:Mapped[datetime]=mapped_column(DateTime(timezone=True)); scheduledTime:Mapped[str]=mapped_column(String(80)); totalAmount:Mapped[float]=mapped_column(Float); paymentMethod:Mapped[str]=mapped_column(String(30)); paymentStatus:Mapped[str]=mapped_column(String(30),default='pending'); orderStatus:Mapped[str]=mapped_column(String(30),default='pending'); notes:Mapped[str]=mapped_column(Text,default=''); createdAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now); updatedAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now)
class Payment(Base):
    __tablename__='payments'; id:Mapped[str]=mapped_column(String(36),primary_key=True); orderId:Mapped[str]=mapped_column(String(36),index=True); customerId:Mapped[str]=mapped_column(String(36)); providerId:Mapped[str]=mapped_column(String(36)); amount:Mapped[float]=mapped_column(Float); method:Mapped[str]=mapped_column(String(30)); status:Mapped[str]=mapped_column(String(30),default='pending'); providerReference:Mapped[Optional[str]]=mapped_column(String(160),nullable=True); failureReason:Mapped[Optional[str]]=mapped_column(Text,nullable=True); createdAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now); updatedAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now)
class Notification(Base):
    __tablename__='notifications'; id:Mapped[str]=mapped_column(String(36),primary_key=True); userId:Mapped[str]=mapped_column(String(36),index=True); title:Mapped[str]=mapped_column(String(200)); body:Mapped[str]=mapped_column(Text); type:Mapped[str]=mapped_column(String(50)); relatedOrderId:Mapped[Optional[str]]=mapped_column(String(36),nullable=True); isRead:Mapped[bool]=mapped_column(Boolean,default=False); createdAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now)
class SupportMessage(Base):
    __tablename__='support_messages'; id:Mapped[str]=mapped_column(String(36),primary_key=True); userId:Mapped[str]=mapped_column(String(36),index=True); name:Mapped[str]=mapped_column(String(160)); email:Mapped[str]=mapped_column(String(255)); subject:Mapped[str]=mapped_column(String(200)); message:Mapped[str]=mapped_column(Text); status:Mapped[str]=mapped_column(String(20),default='open'); createdAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now)
class UssdSession(Base):
    __tablename__='ussd_sessions'; sessionId:Mapped[str]=mapped_column(String(160),primary_key=True); phoneNumber:Mapped[str]=mapped_column(String(32)); lastInput:Mapped[str]=mapped_column(Text,default=''); updatedAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now)
class Review(Base):
    __tablename__='reviews'; id:Mapped[str]=mapped_column(String(36),primary_key=True); orderId:Mapped[str]=mapped_column(String(36),index=True); customerId:Mapped[str]=mapped_column(String(36)); customerName:Mapped[str]=mapped_column(String(160)); providerId:Mapped[str]=mapped_column(String(36),index=True); rating:Mapped[int]=mapped_column(Integer); comment:Mapped[str]=mapped_column(Text,default=''); createdAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now)
Base.metadata.create_all(engine)
app=FastAPI(title='Laundry Service API',version='2.0.0')
allowed_origins=[origin.strip() for origin in os.getenv('FRONTEND_ORIGINS','http://localhost:8080,http://127.0.0.1:8080').split(',') if origin.strip()]
app.add_middleware(CORSMiddleware,allow_origins=allowed_origins,allow_credentials=True,allow_methods=['*'],allow_headers=['*'])

def public(obj):
    d={c.name:getattr(obj,c.name) for c in obj.__table__.columns}; return d

def token_for(user): return jwt.encode({'sub':user.uid,'exp':datetime.now(timezone.utc)+timedelta(minutes=ACCESS_MINUTES)},JWT_SECRET,algorithm=JWT_ALG)
def user_from_token(token,db):
    try: uid=jwt.decode(token,JWT_SECRET,algorithms=[JWT_ALG]).get('sub')
    except JWTError: raise HTTPException(401,'Invalid or expired token')
    user=db.get(User,uid)
    if not user or not user.isActive: raise HTTPException(403,'Account is disabled or unavailable')
    return user
def current(token:str=Depends(oauth2)):
    with Session(engine) as db:return user_from_token(token,db)

class Register(BaseModel): name:str; email:EmailStr; password:str=Field(min_length=6); phone:str; role:str='customer'
class Login(BaseModel): email:EmailStr; password:str
class ProfileUpdate(BaseModel):
    name:str
    phone:str=''
    location:str=''
    profileImage:Optional[str]=None
    latitude:Optional[float]=None
    longitude:Optional[float]=None

class SupportRequest(BaseModel):
    subject:str=Field(min_length=3,max_length=200)
    message:str=Field(min_length=10,max_length=10000)
class PaymentRequest(BaseModel):
    id:Optional[str]=None
    orderId:str
    providerId:str
    method:str
    customerPhone:str=''
class SmsRequest(BaseModel):
    phone:str
    message:str=Field(min_length=1,max_length=480)
@app.get('/api/health')
def health(): return {'status':'ok','database':'postgresql'}
@app.post('/api/auth/register')
def register(body:Register):
    with Session(engine) as db:
        if db.scalar(select(User).where(User.email==body.email)): raise HTTPException(409,'An account already exists with that email address.')
        role=body.role if body.role in ('customer','provider') else 'customer'; u=User(uid=str(uuid.uuid4()),name=body.name,email=body.email,password_hash=pwd.hash(body.password),phone=body.phone,role=role); db.add(u); db.commit(); db.refresh(u); return {'access_token':token_for(u),'token_type':'bearer','user':public(u)}
@app.post('/api/auth/login')
def login(body:Login):
    with Session(engine) as db:
        u=db.scalar(select(User).where(User.email==body.email));
        if not u or not pwd.verify(body.password,u.password_hash): raise HTTPException(401,'The email or password you entered is incorrect.')
        return {'access_token':token_for(u),'token_type':'bearer','user':public(u)}
@app.get('/api/auth/me')
def me(u=Depends(current)): return public(u)
@app.post('/api/auth/forgot-password')
def forgot(body:dict): return {'success':True,'message':'If that email exists, a password reset can be issued by the configured email service.'}
@app.put('/api/users/me')
def update_me(body:ProfileUpdate,u=Depends(current)):
    with Session(engine) as db:
        x=db.get(User,u.uid);x.name=body.name;x.phone=body.phone;x.location=body.location
        if 'profileImage' in body.model_fields_set: x.profileImage=body.profileImage or ''
        if 'latitude' in body.model_fields_set: x.latitude=body.latitude
        if 'longitude' in body.model_fields_set: x.longitude=body.longitude
        x.updatedAt=now();db.commit();db.refresh(x);return public(x)

@app.post('/api/support/messages')
def create_support_message(body:SupportRequest,u=Depends(current)):
    with Session(engine) as db:
        x=SupportMessage(id=str(uuid.uuid4()),userId=u.uid,name=u.name,email=u.email,subject=body.subject.strip(),message=body.message.strip())
        db.add(x);db.commit();db.refresh(x);return public(x)

@app.get('/api/support/messages')
def support_messages(u=Depends(current)):
    if u.role!='admin': raise HTTPException(403,'Admin access required')
    with Session(engine) as db:return [public(x) for x in db.scalars(select(SupportMessage).order_by(desc(SupportMessage.createdAt)).limit(500))]

@app.put('/api/support/messages/{message_id}')
def update_support_message(message_id:str,body:dict,u=Depends(current)):
    if u.role!='admin': raise HTTPException(403,'Admin access required')
    if body.get('status') not in ('open','resolved'): raise HTTPException(400,'Status must be open or resolved')
    with Session(engine) as db:
        x=db.get(SupportMessage,message_id)
        if not x: raise HTTPException(404,'Support message not found')
        x.status=body['status'];db.commit();db.refresh(x);return public(x)

@app.get('/api/users')
def users(u=Depends(current)):
    if u.role!='admin': raise HTTPException(403,'Admin access required')
    with Session(engine) as db: return [public(x) for x in db.scalars(select(User).order_by(User.name))]
@app.put('/api/users/{uid}')
def update_user(uid:str,body:dict,u=Depends(current)):
    if u.role!='admin': raise HTTPException(403,'Admin access required')
    with Session(engine) as db:
        x=db.get(User,uid)
        if not x: raise HTTPException(404,'User not found')
        if 'isActive' in body: x.isActive=body['isActive']
        if 'role' in body and body['role'] in ('customer','provider','admin'): x.role=body['role']
        x.updatedAt=now(); db.commit(); db.refresh(x); return public(x)
@app.delete('/api/users/{uid}')
def delete_user(uid:str,u=Depends(current)):
    if u.role!='admin': raise HTTPException(403,'Admin access required')
    with Session(engine) as db:
        x=db.get(User,uid)
        if not x: raise HTTPException(404,'User not found')
        db.delete(x); db.commit(); return {'success':True}
@app.get('/api/providers')
def providers(search:Optional[str]=None,provider_type:Optional[str]=None,washing_method:Optional[str]=None,ironing_method:Optional[str]=None,only_active:bool=True,only_available:bool=False,near_lat:Optional[float]=None,near_lon:Optional[float]=None):
    with Session(engine) as db:
        q=select(Provider).order_by(desc(Provider.rating))
        if only_active:q=q.where(Provider.isActive==True)
        if only_available:q=q.where(Provider.availability==True)
        if provider_type:q=q.where(Provider.providerType==provider_type)
        if washing_method:q=q.where(Provider.washingMethod==washing_method)
        if ironing_method:q=q.where(Provider.ironingMethod==ironing_method)
        rows=list(db.scalars(q));
        if search: rows=[x for x in rows if search.lower() in x.providerName.lower() or search.lower() in x.location.lower()]
        if near_lat is not None and near_lon is not None:
            def distance(provider):
                if provider.latitude == 0 and provider.longitude == 0:
                    return float('inf')
                lat1,lat2=math.radians(near_lat),math.radians(provider.latitude)
                dlat=lat2-lat1;dlon=math.radians(provider.longitude-near_lon)
                a=math.sin(dlat/2)**2+math.cos(lat1)*math.cos(lat2)*math.sin(dlon/2)**2
                return 6371*2*math.atan2(math.sqrt(a),math.sqrt(1-a))
            rows.sort(key=distance)
        return [public(x) for x in rows]
@app.get('/api/providers/{pid}')
def provider(pid:str):
    with Session(engine) as db:
        x=db.get(Provider,pid)
        if not x: raise HTTPException(404,'Provider not found')
        return public(x)
@app.post('/api/providers')
def create_provider(body:dict,u=Depends(current)):
    with Session(engine) as db:
        x=Provider(id=u.uid,ownerId=u.uid,providerName=body['providerName'],providerType=body['providerType'],washingMethod=body['washingMethod'],ironingMethod=body['ironingMethod'],phone=body['phone'],email=body['email'],description=body.get('description',''),location=body.get('location',''),latitude=body.get('latitude',0),longitude=body.get('longitude',0),startingPrice=body.get('startingPrice',0),turnaroundHours=body.get('turnaroundHours',24),capacity=body.get('dailyCapacity',0));db.add(x);db.commit();db.refresh(x);return public(x)
@app.put('/api/providers/{pid}')
def update_provider(pid:str,body:dict,u=Depends(current)):
    with Session(engine) as db:
        x=db.get(Provider,pid)
        if not x: raise HTTPException(404,'Provider not found')
        if u.role!='admin' and x.ownerId!=u.uid: raise HTTPException(403,'Not allowed')
        for k,v in body.items():
            if hasattr(x,k) and k not in ('id','ownerId'): setattr(x,k,v)
        x.updatedAt=now();db.commit();db.refresh(x);return public(x)
@app.delete('/api/providers/{pid}')
def delete_provider(pid:str,u=Depends(current)):
    with Session(engine) as db:
        x=db.get(Provider,pid)
        if not x: raise HTTPException(404,'Provider not found')
        if u.role!='admin' and x.ownerId!=u.uid: raise HTTPException(403,'Not allowed')
        db.delete(x);db.commit();return {'success':True}
@app.get('/api/providers/{pid}/services')
def services(pid:str):
    with Session(engine) as db:return [public(x) for x in db.scalars(select(Service).where(Service.providerId==pid).order_by(Service.createdAt))]
@app.post('/api/providers/{pid}/services')
def add_service(pid:str,body:dict,u=Depends(current)):
    with Session(engine) as db:
        p=db.get(Provider,pid)
        if not p or (u.role!='admin' and p.ownerId!=u.uid): raise HTTPException(403,'Not allowed')
        x=Service(id=body.get('id',str(uuid.uuid4())),providerId=pid,name=body['name'],description=body.get('description',''),price=body['price'],pricingUnit=body['pricingUnit']);db.add(x);db.commit();db.refresh(x);return public(x)
@app.put('/api/providers/{pid}/services/{sid}')
def edit_service(pid:str,sid:str,body:dict,u=Depends(current)):
    with Session(engine) as db:
        p=db.get(Provider,pid);x=db.get(Service,sid)
        if not p or not x or x.providerId!=pid or (u.role!='admin' and p.ownerId!=u.uid):raise HTTPException(403,'Not allowed')
        for k,v in body.items():
            if hasattr(x,k) and k not in ('id','providerId'):setattr(x,k,v)
        x.updatedAt=now();db.commit();db.refresh(x);return public(x)
@app.delete('/api/providers/{pid}/services/{sid}')
def delete_service(pid:str,sid:str,u=Depends(current)):
    with Session(engine) as db:
        p=db.get(Provider,pid);x=db.get(Service,sid)
        if not p or not x or x.providerId!=pid or (u.role!='admin' and p.ownerId!=u.uid):raise HTTPException(403,'Not allowed')
        db.delete(x);db.commit();return {'success':True}

@app.get('/api/orders')
def orders(customer_id:Optional[str]=None,provider_id:Optional[str]=None,status:Optional[str]=None,u=Depends(current)):
    with Session(engine) as db:
        q=select(Order).order_by(desc(Order.createdAt));
        if u.role!='admin':
            if u.role=='provider': q=q.where(Order.providerId==u.uid)
            else:q=q.where(Order.customerId==u.uid)
        if customer_id:q=q.where(Order.customerId==customer_id)
        if provider_id:q=q.where(Order.providerId==provider_id)
        if status:q=q.where(Order.orderStatus==status)
        return [public(x) for x in db.scalars(q.limit(500))]
@app.get('/api/orders/{oid}')
def get_order(oid:str,u=Depends(current)):
    with Session(engine) as db:
        x=db.get(Order,oid)
        if not x:raise HTTPException(404,'Order not found')
        if u.role!='admin' and x.customerId!=u.uid and x.providerId!=u.uid:raise HTTPException(403,'Not allowed')
        return public(x)
@app.post('/api/orders')
def create_order(body:dict,u=Depends(current)):
    with Session(engine) as db:
        provider=db.get(Provider,body.get('providerId'))
        if not provider or not provider.isActive:raise HTTPException(404,'Provider not found or unavailable.')
        if body.get('paymentMethod') not in ('mobileMoney','cashOnDelivery'):raise HTTPException(400,'Unsupported payment method.')
        requested_items=body.get('items',[])
        if not requested_items:raise HTTPException(400,'An order must contain at least one laundry service.')
        items=[]
        for requested in requested_items:
            service=db.get(Service,requested.get('serviceId'))
            if not service or service.providerId!=provider.id or not service.isAvailable:raise HTTPException(400,'An order contains an unavailable service.')
            try:quantity=float(requested.get('quantity',0))
            except (TypeError,ValueError):quantity=0
            if not math.isfinite(quantity) or quantity<=0:raise HTTPException(400,'Service quantity must be greater than zero.')
            if not math.isfinite(service.price) or service.price<0:raise HTTPException(400,'Service has an invalid price.')
            items.append({'serviceId':service.id,'serviceName':service.name,'quantity':quantity,'pricingUnit':service.pricingUnit,'unitPrice':service.price})
        total=sum(item['quantity']*item['unitPrice'] for item in items)
        if not math.isfinite(total) or total<=0:raise HTTPException(400,'Order total must be greater than zero.')
        x=Order(id=str(uuid.uuid4()),customerId=u.uid,customerName=u.name,providerId=provider.id,providerName=provider.providerName,items=items,washingMethod=body['washingMethod'],ironingMethod=body['ironingMethod'],pickupRequested=body.get('pickupRequested',True),deliveryRequested=body.get('deliveryRequested',True),pickupLocation=body['pickupLocation'],deliveryLocation=body['deliveryLocation'],scheduledDate=datetime.fromisoformat(body['scheduledDate'].replace('Z','+00:00')),scheduledTime=body['scheduledTime'],totalAmount=total,paymentMethod=body['paymentMethod'],notes=body.get('notes',''));db.add(x);db.commit();db.refresh(x);return public(x)
@app.put('/api/orders/{oid}/status')
def status(oid:str,body:dict,u=Depends(current)):
    with Session(engine) as db:
        x=db.get(Order,oid)
        if not x:raise HTTPException(404,'Order not found')
        if u.role!='admin' and x.providerId!=u.uid and x.customerId!=u.uid:raise HTTPException(403,'Not allowed')
        x.orderStatus=body['status'];x.updatedAt=now();db.commit();return public(x)
@app.put('/api/orders/{oid}/payment-status')
def payment_status(oid:str,body:dict,u=Depends(current)):
    if u.role!='admin':raise HTTPException(403,'Only an administrator can reconcile payment status.')
    if body.get('status') not in ('pending','paid','failed','cancelled'):raise HTTPException(400,'Invalid payment status.')
    with Session(engine) as db:
        x=db.get(Order,oid)
        if not x:raise HTTPException(404,'Order not found')
        x.paymentStatus=body['status'];x.updatedAt=now()
        for payment in db.scalars(select(Payment).where(Payment.orderId==oid)):
            payment.status=body['status'];payment.updatedAt=now()
        db.commit();return public(x)
@app.delete('/api/orders/{oid}')
def delete_order(oid:str,u=Depends(current)):
    with Session(engine) as db:
        x=db.get(Order,oid)
        if not x or (u.role!='admin' and x.customerId!=u.uid):raise HTTPException(403,'Not allowed')
        db.delete(x);db.commit();return {'success':True}

@app.get('/api/notifications')
def notifications(user_id:Optional[str]=None,u=Depends(current)):
    uid=u.uid if u.role!='admin' else (user_id or u.uid)
    with Session(engine) as db:return [public(x) for x in db.scalars(select(Notification).where(Notification.userId==uid).order_by(desc(Notification.createdAt)))]
@app.post('/api/notifications')
def create_notification(body:dict,u=Depends(current)):
    with Session(engine) as db:x=Notification(id=body.get('id',str(uuid.uuid4())),userId=body['userId'],title=body['title'],body=body['body'],type=body['type'],relatedOrderId=body.get('relatedOrderId'));db.add(x);db.commit();db.refresh(x);return public(x)
@app.put('/api/notifications/{nid}/read')
def read_notification(nid:str,u=Depends(current)):
    with Session(engine) as db:x=db.get(Notification,nid); x.isRead=True;db.commit();return {'success':True}
@app.put('/api/notifications/read-all')
def read_all(body:dict,u=Depends(current)):
    with Session(engine) as db:
        for x in db.scalars(select(Notification).where(Notification.userId==u.uid,Notification.isRead==False)):x.isRead=True
        db.commit();return {'success':True}
@app.delete('/api/notifications/{nid}')
def delete_notification(nid:str,u=Depends(current)):
    with Session(engine) as db:x=db.get(Notification,nid);db.delete(x);db.commit();return {'success':True}
@app.delete('/api/notifications/user/{uid}')
def clear_notifications(uid:str,u=Depends(current)):
    if u.role!='admin' and uid!=u.uid:raise HTTPException(403,'Not allowed')
    with Session(engine) as db:
        for x in db.scalars(select(Notification).where(Notification.userId==uid)):db.delete(x)
        db.commit();return {'success':True}
@app.get('/api/reviews')
def reviews(provider_id:Optional[str]=None):
    with Session(engine) as db:
        q=select(Review).order_by(desc(Review.createdAt));
        if provider_id:q=q.where(Review.providerId==provider_id)
        return [public(x) for x in db.scalars(q)]
@app.post('/api/reviews')
def create_review(body:dict,u=Depends(current)):
    with Session(engine) as db:
        if db.scalar(select(Review).where(Review.orderId==body['orderId'],Review.customerId==u.uid)):raise HTTPException(409,'You have already reviewed this order.')
        x=Review(id=body.get('id',str(uuid.uuid4())),orderId=body['orderId'],customerId=u.uid,customerName=body.get('customerName',u.name),providerId=body['providerId'],rating=body['rating'],comment=body.get('comment',''));db.add(x);db.commit();
        avg,count=db.execute(select(func.avg(Review.rating),func.count(Review.id)).where(Review.providerId==x.providerId)).one();p=db.get(Provider,x.providerId);p.rating=float(avg or 0);p.reviewCount=int(count or 0);db.commit();db.refresh(x);return public(x)
@app.delete('/api/reviews/{rid}')
def delete_review(rid:str,u=Depends(current)):
    with Session(engine) as db:x=db.get(Review,rid); 
    return {'success':True}
@app.post('/api/payments')
def create_payment(body:PaymentRequest,u=Depends(current)):
    if body.method not in ('mobileMoney','cashOnDelivery'):
        raise HTTPException(400,'Unsupported payment method.')
    with Session(engine) as db:
        order=db.get(Order,body.orderId)
        if not order:raise HTTPException(404,'Order not found')
        if order.customerId!=u.uid:raise HTTPException(403,'Only the customer who placed the order can pay for it.')
        if order.providerId!=body.providerId:raise HTTPException(400,'The provider does not match this order.')
        if order.paymentMethod!=body.method:raise HTTPException(400,'The payment method does not match this order.')
        pending=db.scalar(select(Payment).where(Payment.orderId==order.id,Payment.status=='pending'))
        if pending:return public(pending)
        payment_id=body.id or str(uuid.uuid4())
        existing=db.get(Payment,payment_id)
        if existing:
            if existing.customerId!=u.uid:raise HTTPException(409,'Payment reference is already in use.')
            return public(existing)
        if order.paymentStatus=='paid':raise HTTPException(409,'This order has already been paid.')
        x=Payment(id=payment_id,orderId=order.id,customerId=u.uid,providerId=order.providerId,amount=order.totalAmount,method=body.method)
        db.add(x)
        db.commit()
        if body.method=='mobileMoney':
            try:
                phone=normalise_ke_phone(body.customerPhone or u.phone)
                checkout_id,_=initiate_mpesa_stk(phone,x.amount,x.id)
            except (IntegrationError,ValueError) as error:
                x.status='failed';x.failureReason=str(error);x.updatedAt=now()
                order.paymentStatus='failed';order.updatedAt=now()
                db.commit()
                raise HTTPException(503,str(error)) from error
            x.providerReference=checkout_id;x.updatedAt=now()
        order.paymentStatus='pending';order.updatedAt=now()
        db.commit();db.refresh(x);return public(x)
@app.get('/api/payments/{pid}')
def payment(pid:str,u=Depends(current)):
    with Session(engine) as db:
        x=db.get(Payment,pid)
        if not x:raise HTTPException(404,'Payment not found')
        if u.role!='admin' and x.customerId!=u.uid and x.providerId!=u.uid:raise HTTPException(403,'Not allowed')
        return public(x)
@app.get('/api/payments')
def payments(order_id:Optional[str]=None,u=Depends(current)):
    with Session(engine) as db:
        q=select(Payment)
        if u.role!='admin':
            q=q.where(Payment.providerId==u.uid if u.role=='provider' else Payment.customerId==u.uid)
        if order_id:q=q.where(Payment.orderId==order_id)
        return [public(x) for x in db.scalars(q)]
@app.put('/api/payments/{pid}/cash-collected')
def cash_collected(pid:str,u=Depends(current)):
    with Session(engine) as db:
        x=db.get(Payment,pid)
        if not x:raise HTTPException(404,'Payment not found')
        order=db.get(Order,x.orderId)
        if not order:raise HTTPException(404,'Order not found')
        if x.method!='cashOnDelivery' or order.paymentMethod!='cashOnDelivery':raise HTTPException(400,'This is not a cash-on-delivery payment.')
        if u.role!='admin' and (u.role!='provider' or order.providerId!=u.uid):raise HTTPException(403,'Only the assigned provider can record cash collection.')
        x.status='paid';x.updatedAt=now();order.paymentStatus='paid';order.updatedAt=now()
        db.commit();db.refresh(x);return public(x)
@app.post('/api/payments/mpesa/callback')
async def mpesa_callback(request:Request):
    expected=mpesa_callback_token()
    supplied=request.query_params.get('token','')
    if not expected or not secrets.compare_digest(supplied,expected):
        raise HTTPException(403,'Invalid payment callback token.')
    try:payload=await request.json()
    except ValueError as error:raise HTTPException(400,'Malformed payment callback.') from error
    if not isinstance(payload,dict):raise HTTPException(400,'Malformed payment callback.')
    callback_body=payload.get('Body')
    callback=callback_body.get('stkCallback') if isinstance(callback_body,dict) else None
    if not isinstance(callback,dict) or not callback.get('CheckoutRequestID'):
        raise HTTPException(400,'Malformed payment callback.')
    checkout_id=callback['CheckoutRequestID']
    try: result_code=int(callback.get('ResultCode'))
    except (TypeError,ValueError):raise HTTPException(400,'Malformed payment result.')
    with Session(engine) as db:
        payment=db.scalar(select(Payment).where(Payment.providerReference==checkout_id))
        if not payment:return {'ResultCode':0,'ResultDesc':'Accepted'}
        if payment.status!='pending':return {'ResultCode':0,'ResultDesc':'Accepted'}
        order=db.get(Order,payment.orderId)
        if result_code==0:
            metadata_container=callback.get('CallbackMetadata')
            items=metadata_container.get('Item',[]) if isinstance(metadata_container,dict) else []
            if not isinstance(items,list):items=[]
            metadata={item.get('Name'):item.get('Value') for item in items if isinstance(item,dict)}
            try:paid_amount=round(float(metadata.get('Amount')))
            except (TypeError,ValueError):paid_amount=-1
            if paid_amount!=round(payment.amount):
                payment.status='failed';payment.failureReason='Payment amount did not match the order.'
                if order:order.paymentStatus='failed';order.updatedAt=now()
                logging.error('M-Pesa callback amount mismatch for payment %s',payment.id)
            else:
                payment.status='paid';payment.failureReason=None
                payment.providerReference=str(metadata.get('MpesaReceiptNumber') or checkout_id)
                if order:
                    order.paymentStatus='paid';order.updatedAt=now()
                    db.add(Notification(id=str(uuid.uuid4()),userId=payment.customerId,title='Payment Confirmed',body=f'Your payment of KES {payment.amount:.0f} has been received.',type='paymentConfirmation',relatedOrderId=payment.orderId))
        else:
            payment.status='failed'
            payment.failureReason=str(callback.get('ResultDesc') or 'The payment was not completed.')[:1000]
            if order:order.paymentStatus='failed';order.updatedAt=now()
        payment.updatedAt=now()
        db.commit()
    return {'ResultCode':0,'ResultDesc':'Accepted'}
@app.post('/api/notifications/sms')
def sms(body:SmsRequest,u=Depends(current)):
    try:
        recipient=normalise_ke_phone(body.phone)
        if u.role!='admin' and recipient!=normalise_ke_phone(u.phone):
            raise HTTPException(403,'You can only send messages to your own verified account phone.')
        return send_sms(recipient,body.message)
    except ValueError as error:
        raise HTTPException(400,str(error)) from error
    except IntegrationError as error:
        raise HTTPException(503,str(error)) from error

@app.get('/api/integrations/status')
def integration_status(u=Depends(current)):
    if u.role!='admin':raise HTTPException(403,'Admin access required')
    return {
        'sms':{'provider':'africas_talking','configured':sms_is_configured()},
        'mobileMoney':{'provider':'safaricom_daraja','configured':mpesa_is_configured()},
        'ussd':{'callbackAuthenticationEnabled':bool(os.getenv('USSD_CALLBACK_TOKEN'))},
    }

def _normalise_phone(raw:str)->str:
    digits=''.join(c for c in raw if c.isdigit())
    if digits.startswith('0'): return '254'+digits[1:]
    return digits

def _ussd_reply(message:str,continue_session:bool=True)->PlainTextResponse:
    return PlainTextResponse(('CON ' if continue_session else 'END ')+message)

@app.post('/ussd',response_class=PlainTextResponse)
async def ussd(request:Request):
    """Africa's Talking-compatible callback; text carries the accumulated menu choices."""
    try:
        ussd_token=os.getenv('USSD_CALLBACK_TOKEN')
        if ussd_token and not secrets.compare_digest(request.query_params.get('token',''),ussd_token):
            raise HTTPException(403,'Invalid USSD callback token.')
        body=await request.body()
        fields=parse_qs(body.decode('utf-8'),keep_blank_values=True)
        session_id=(fields.get('sessionId') or [''])[0].strip()
        phone=_normalise_phone((fields.get('phoneNumber') or [''])[0])
        text=(fields.get('text') or [''])[0].strip()
        if not session_id or not phone:
            return _ussd_reply('Invalid USSD request. Please try again later.',False)
        steps=text.split('*') if text else []
        with Session(engine) as db:
            session=db.get(UssdSession,session_id)
            if session is None:
                session=UssdSession(sessionId=session_id,phoneNumber=phone,lastInput=text)
                db.add(session)
            else:
                session.phoneNumber=phone;session.lastInput=text;session.updatedAt=now()
            db.commit()
            phone_values=[phone,'+'+phone]
            if phone.startswith('254'): phone_values.append('0'+phone[3:])
            user=next((x for x in db.scalars(select(User).where(User.phone.in_(phone_values))) if _normalise_phone(x.phone)==phone),None)
            providers=list(db.scalars(select(Provider).where(Provider.isActive==True).order_by(desc(Provider.rating)).limit(5)))

            if not steps:
                greeting=f"Welcome {user.name.split()[0]}" if user else 'Welcome to Laundry Service'
                return _ussd_reply(f"{greeting}\n1. Find Laundry\n2. Book Service\n3. My Orders\n4. Check Order Status\n5. Register\n6. Help")

            choice=steps[0]
            if choice=='1':
                if not providers:return _ussd_reply('No providers are available right now.',False)
                if len(steps)==1:
                    return _ussd_reply('Providers near you\n'+'\n'.join(f'{i+1}. {p.providerName} KES {p.startingPrice:g}' for i,p in enumerate(providers)))
                index=int(steps[1])-1 if steps[1].isdigit() else -1
                if index<0 or index>=len(providers):return _ussd_reply('Invalid selection. Dial again.',False)
                p=providers[index]
                kind='Mama Fua / Jua Kali' if p.providerType=='mamaFua' else 'Formal Laundry'
                return _ussd_reply(f'{p.providerName}\nType: {kind}\nLocation: {p.location}\nFrom KES {p.startingPrice:g}\nCall {p.phone}',False)

            if choice=='2':
                if user is None:return _ussd_reply('Register first using option 5, then dial again to book.',False)
                if not providers:return _ussd_reply('No providers are available right now.',False)
                if len(steps)==1:
                    return _ussd_reply('Choose provider\n'+'\n'.join(f'{i+1}. {p.providerName}' for i,p in enumerate(providers)))
                provider_index=int(steps[1])-1 if steps[1].isdigit() else -1
                if provider_index<0 or provider_index>=len(providers):return _ussd_reply('Invalid provider selection.',False)
                provider=providers[provider_index]
                services=list(db.scalars(select(Service).where(Service.providerId==provider.id,Service.isAvailable==True).limit(5)))
                if not services:return _ussd_reply('This provider has no services available.',False)
                if len(steps)==2:
                    return _ussd_reply('Choose service\n'+'\n'.join(f'{i+1}. {s.name} KES {s.price:g} {s.pricingUnit}' for i,s in enumerate(services)))
                service_index=int(steps[2])-1 if steps[2].isdigit() else -1
                if service_index<0 or service_index>=len(services):return _ussd_reply('Invalid service selection.',False)
                service=services[service_index]
                if len(steps)==3:return _ussd_reply(f'Enter quantity ({service.pricingUnit})')
                try: quantity=float(steps[3])
                except ValueError: quantity=0
                if not math.isfinite(quantity) or quantity<=0:return _ussd_reply('Enter a valid quantity greater than zero.',False)
                if len(steps)==4:return _ussd_reply('Enter your pickup location')
                pickup=steps[4].strip()
                if not pickup:return _ussd_reply('Pickup location is required.',False)
                if len(steps)==5:return _ussd_reply('Payment method\n1. Mobile Money\n2. Cash on Delivery')
                if steps[5] not in ('1','2'):return _ussd_reply('Choose 1 for Mobile Money or 2 for Cash.',False)
                total=quantity*service.price
                order=Order(id=str(uuid.uuid4()),customerId=user.uid,customerName=user.name,providerId=provider.id,providerName=provider.providerName,items=[{'serviceId':service.id,'serviceName':service.name,'quantity':quantity,'pricingUnit':service.pricingUnit,'unitPrice':service.price}],washingMethod=provider.washingMethod,ironingMethod=provider.ironingMethod,pickupRequested=True,deliveryRequested=True,pickupLocation={'label':pickup,'latitude':0,'longitude':0},deliveryLocation={'label':pickup,'latitude':0,'longitude':0},scheduledDate=now(),scheduledTime='As soon as possible',totalAmount=total,paymentMethod='mobileMoney' if steps[5]=='1' else 'cashOnDelivery',notes='Order placed through USSD')
                db.add(order)
                db.add(Notification(id=str(uuid.uuid4()),userId=provider.ownerId,title='New USSD Order',body=f'{user.name} placed a USSD order worth KES {total:.0f}.',type='newOrder',relatedOrderId=order.id))
                payment=None
                if steps[5]=='1':
                    payment=Payment(id=str(uuid.uuid4()),orderId=order.id,customerId=user.uid,providerId=provider.id,amount=total,method='mobileMoney')
                    db.add(payment)
                db.commit()
                if payment is not None:
                    try:
                        checkout_id,_=initiate_mpesa_stk(phone,total,payment.id)
                        payment.providerReference=checkout_id;payment.updatedAt=now();db.commit()
                    except (IntegrationError,ValueError) as error:
                        payment.status='failed';payment.failureReason=str(error);payment.updatedAt=now()
                        order.paymentStatus='failed';order.updatedAt=now();db.commit()
                        return _ussd_reply(f'Order {order.id[:8].upper()} was created, but the payment prompt could not be started. Contact support with this reference.',False)
                return _ussd_reply(f'Order confirmed.\nProvider: {provider.providerName}\nTotal: KES {total:.0f}\nReference: {order.id[:8].upper()}',False)

            if choice=='3':
                if user is None:return _ussd_reply('No account found for this number.',False)
                recent=list(db.scalars(select(Order).where(Order.customerId==user.uid).order_by(desc(Order.createdAt)).limit(5)))
                if not recent:return _ussd_reply('You have no orders yet.',False)
                return _ussd_reply('Recent orders\n'+'\n'.join(f'{o.providerName} KES {o.totalAmount:.0f} {o.orderStatus}' for o in recent),False)

            if choice=='4':
                if user is None:return _ussd_reply('No account found for this number.',False)
                if len(steps)==1:return _ussd_reply('Enter your order reference')
                reference=steps[1].strip().lower()
                order=next((o for o in db.scalars(select(Order).where(Order.customerId==user.uid)) if o.id.lower().startswith(reference)),None)
                if order is None:return _ussd_reply('Order not found. Check your reference.',False)
                return _ussd_reply(f'Order {order.id[:8].upper()}\nProvider: {order.providerName}\nStatus: {order.orderStatus}\nAmount: KES {order.totalAmount:.0f}',False)

            if choice=='5':
                if user:return _ussd_reply('This number is already registered.',False)
                if len(steps)==1:return _ussd_reply('Enter your full name')
                if len(steps)==2:
                    name=steps[1].strip()
                    if len(name)<2:return _ussd_reply('Please enter your full name.',False)
                    new_user=User(uid=str(uuid.uuid4()),name=name,email=f'{phone}@ussd.local',password_hash=pwd.hash(uuid.uuid4().hex),phone=phone,role='customer',location='')
                    db.add(new_user);db.commit()
                    return _ussd_reply(f'Welcome {name}. Your account is ready. Dial again to book.',False)

            if choice=='6':return _ussd_reply('For help, send a message through Help and Support in the Laundry Service app.',False)
            return _ussd_reply('Invalid choice. Dial again.',False)
    except HTTPException:
        raise
    except Exception:
        logging.exception('USSD callback failed')
        return _ussd_reply('The service is temporarily unavailable. Please try again shortly.',False)

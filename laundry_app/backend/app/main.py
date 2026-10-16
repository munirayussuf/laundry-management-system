import os, uuid, hashlib
from datetime import datetime, timedelta, timezone
from typing import Optional
from fastapi import FastAPI, Depends, HTTPException, Query
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import create_engine, String, Boolean, DateTime, Float, Integer, Text, ForeignKey, JSON, select, desc, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, Session

DATABASE_URL=os.getenv('DATABASE_URL','postgresql+psycopg://laundry:laundry@localhost:5432/laundry')
JWT_SECRET=os.getenv('JWT_SECRET','change-this-in-production')
JWT_ALG='HS256'; ACCESS_MINUTES=60*24*7
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
class Review(Base):
    __tablename__='reviews'; id:Mapped[str]=mapped_column(String(36),primary_key=True); orderId:Mapped[str]=mapped_column(String(36),index=True); customerId:Mapped[str]=mapped_column(String(36)); customerName:Mapped[str]=mapped_column(String(160)); providerId:Mapped[str]=mapped_column(String(36),index=True); rating:Mapped[int]=mapped_column(Integer); comment:Mapped[str]=mapped_column(Text,default=''); createdAt:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=now)
Base.metadata.create_all(engine)
app=FastAPI(title='Laundry Service API',version='2.0.0')

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
class ProfileUpdate(BaseModel): name:str; phone:str=''; location:str=''
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
    with Session(engine) as db: x=db.get(User,u.uid); x.name=body.name;x.phone=body.phone;x.location=body.location;x.updatedAt=now();db.commit();db.refresh(x);return public(x)

@app.get('/api/providers')
def providers(search:Optional[str]=None,provider_type:Optional[str]=None,washing_method:Optional[str]=None,ironing_method:Optional[str]=None,only_active:bool=True,only_available:bool=False):
    with Session(engine) as db:
        q=select(Provider).order_by(desc(Provider.rating))
        if only_active:q=q.where(Provider.isActive==True)
        if only_available:q=q.where(Provider.availability==True)
        if provider_type:q=q.where(Provider.providerType==provider_type)
        if washing_method:q=q.where(Provider.washingMethod==washing_method)
        if ironing_method:q=q.where(Provider.ironingMethod==ironing_method)
        rows=list(db.scalars(q));
        if search: rows=[x for x in rows if search.lower() in x.providerName.lower() or search.lower() in x.location.lower()]
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
        return [public(x) for x in db.scalars(q).limit(500)]
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
        items=body.get('items',[])
        if not items:raise HTTPException(400,'An order must contain at least one laundry service.')
        total=sum(float(i['quantity'])*float(i['unitPrice']) for i in items)
        x=Order(id=str(uuid.uuid4()),customerId=u.uid,customerName=body.get('customerName',u.name),providerId=body['providerId'],providerName=body['providerName'],items=items,washingMethod=body['washingMethod'],ironingMethod=body['ironingMethod'],pickupRequested=body.get('pickupRequested',True),deliveryRequested=body.get('deliveryRequested',True),pickupLocation=body['pickupLocation'],deliveryLocation=body['deliveryLocation'],scheduledDate=datetime.fromisoformat(body['scheduledDate'].replace('Z','+00:00')),scheduledTime=body['scheduledTime'],totalAmount=total,paymentMethod=body['paymentMethod'],notes=body.get('notes',''));db.add(x);db.commit();db.refresh(x);return public(x)
@app.put('/api/orders/{oid}/status')
def status(oid:str,body:dict,u=Depends(current)):
    with Session(engine) as db:
        x=db.get(Order,oid)
        if not x:raise HTTPException(404,'Order not found')
        if u.role!='admin' and x.providerId!=u.uid and x.customerId!=u.uid:raise HTTPException(403,'Not allowed')
        x.orderStatus=body['status'];x.updatedAt=now();db.commit();return public(x)
@app.put('/api/orders/{oid}/payment-status')
def payment_status(oid:str,body:dict,u=Depends(current)):
    with Session(engine) as db:
        x=db.get(Order,oid)
        if not x:raise HTTPException(404,'Order not found')
        if u.role!='admin' and x.customerId!=u.uid and x.providerId!=u.uid:raise HTTPException(403,'Not allowed')
        x.paymentStatus=body['status'];x.updatedAt=now();db.commit();return public(x)
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
def create_payment(body:dict,u=Depends(current)):
    with Session(engine) as db:
        x=Payment(id=body.get('id',str(uuid.uuid4())),orderId=body['orderId'],customerId=u.uid,providerId=body['providerId'],amount=body['amount'],method=body['method']);db.add(x);db.commit();db.refresh(x);return public(x)
@app.get('/api/payments/{pid}')
def payment(pid:str,u=Depends(current)):
    with Session(engine) as db:x=db.get(Payment,pid);return public(x) if x else (_ for _ in ()).throw(HTTPException(404,'Payment not found'))
@app.get('/api/payments')
def payments(order_id:Optional[str]=None,u=Depends(current)):
    with Session(engine) as db:
        q=select(Payment); 
        if order_id:q=q.where(Payment.orderId==order_id)
        return [public(x) for x in db.scalars(q)]
@app.put('/api/payments/{pid}/cash-collected')
def cash_collected(pid:str,u=Depends(current)):
    with Session(engine) as db:x=db.get(Payment,pid);x.status='paid';x.updatedAt=now();db.commit();return public(x)
@app.post('/api/notifications/sms')
def sms(body:dict,u=Depends(current)):
    # Gateway adapter hook: configure SMS_PROVIDER_URL/API credentials in production.
    return {'success':False,'detail':'SMS gateway is not configured. Configure it in the FastAPI environment.'}

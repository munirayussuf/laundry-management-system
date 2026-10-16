import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/order_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminDashboardScreen extends ConsumerWidget { const AdminDashboardScreen({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final repo=ref.watch(orderRepositoryProvider); return SafeArea(child:FutureBuilder<List<OrderModel>>(future:repo.allOrdersOnce(),builder:(context,s){final orders=s.data??[]; final pending=orders.where((o)=>o.orderStatus==OrderStatus.pending).length; final completed=orders.where((o)=>o.orderStatus==OrderStatus.completed).length; final cancelled=orders.where((o)=>o.orderStatus==OrderStatus.cancelled).length; final revenue=orders.where((o)=>o.paymentStatus==PaymentStatus.paid).fold<double>(0,(a,o)=>a+o.totalAmount); return ListView(padding:const EdgeInsets.all(20),children:[Text('Administrator Dashboard',style:AppTextStyles.heading2()),const SizedBox(height:16),Wrap(spacing:12,runSpacing:12,children:[_StatCard('Total Orders','${orders.length}'),_StatCard('Pending','$pending'),_StatCard('Completed','$completed'),_StatCard('Cancelled','$cancelled')]),const SizedBox(height:20),Card(child:Padding(padding:const EdgeInsets.all(16),child:Text('Confirmed Revenue: KES ${revenue.toStringAsFixed(0)}',style:AppTextStyles.heading2(color:AppColors.primaryPink))))];});})); }}
class _StatCard extends StatelessWidget { const _StatCard(this.label,this.value); final String label,value; @override Widget build(BuildContext c)=>SizedBox(width:160,height:100,child:Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:AppTextStyles.heading2()),Text(label,style:AppTextStyles.bodySmall())])))); }

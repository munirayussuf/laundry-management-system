import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/provider_model.dart';
import '../../../core/models/service_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/models/notification_model.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.providerId});
  final String providerId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final Map<String, double> _selectedQuantities = {}; // serviceId -> quantity
  WashingMethod _washingMethod = WashingMethod.machineWashing;
  IroningMethod _ironingMethod = IroningMethod.electricIron;
  bool _pickupRequested = true;
  bool _deliveryRequested = true;
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  bool _isSubmitting = false;

  double _total(List<ServiceModel> services) {
    double total = 0;
    for (final service in services) {
      final qty = _selectedQuantities[service.id] ?? 0;
      total += qty * service.price;
    }
    return total;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Future<void> _submit(ProviderModel provider, List<ServiceModel> services) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final chosenItems = <OrderItem>[];
    for (final service in services) {
      final qty = _selectedQuantities[service.id] ?? 0;
      if (qty > 0) {
        chosenItems.add(OrderItem(
          serviceId: service.id,
          serviceName: service.name,
          quantity: qty,
          pricingUnit: service.pricingUnit,
          unitPrice: service.price,
        ));
      }
    }

    if (chosenItems.isEmpty) {
      showErrorSnackBar(context, 'Please select at least one service and quantity.');
      return;
    }
    if (_pickupRequested && _pickupController.text.trim().isEmpty) {
      showErrorSnackBar(context, 'Please enter a pickup location.');
      return;
    }
    if (_deliveryRequested && _deliveryController.text.trim().isEmpty) {
      showErrorSnackBar(context, 'Please enter a delivery location.');
      return;
    }
    if (_scheduledDate == null || _scheduledTime == null) {
      showErrorSnackBar(context, 'Please choose a preferred date and time.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final scheduledDateTime = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
      );
      final timeLabel = _scheduledTime!.format(context);

      final orderRepo = ref.read(orderRepositoryProvider);
      final order = await orderRepo.createOrder(
        customerId: user.uid,
        customerName: user.name,
        providerId: provider.id,
        providerName: provider.providerName,
        items: chosenItems,
        washingMethod: _washingMethod,
        ironingMethod: _ironingMethod,
        pickupRequested: _pickupRequested,
        deliveryRequested: _deliveryRequested,
        pickupAddress: OrderAddress(label: _pickupController.text.trim()),
        deliveryAddress: OrderAddress(label: _deliveryController.text.trim()),
        scheduledDate: scheduledDateTime,
        scheduledTime: timeLabel,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim(),
      );

      final paymentService = ref.read(paymentServiceProvider);
      await paymentService.createPayment(
        orderId: order.id,
        customerId: user.uid,
        providerId: provider.id,
        amount: order.totalAmount,
        method: _paymentMethod,
        customerPhone: user.phone,
      );

      await ref.read(notificationRepositoryProvider).create(
            userId: provider.ownerId,
            title: 'New Order Received',
            body: '${user.name} booked ${chosenItems.length} service(s) worth KES ${order.totalAmount.toStringAsFixed(0)}.',
            type: NotificationType.newOrder,
            relatedOrderId: order.id,
          );

      await ref.read(smsServiceProvider).sendOrderConfirmation(user.phone, order.id, order.totalAmount);

      if (mounted) {
        showSuccessSnackBar(context, 'Your order has been placed successfully.');
        context.go('${AppRoutes.customerHome}/order/${order.id}');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Could not place your order. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _deliveryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerRepo = ref.watch(providerRepositoryProvider);

    return Scaffold(
      appBar: const PinkAppBar(title: 'Book Service', subtitle: 'Choose your services and schedule'),
      body: StreamBuilder<ProviderModel?>(
        stream: providerRepo.watchProvider(widget.providerId),
        builder: (context, providerSnapshot) {
          final provider = providerSnapshot.data;
          if (provider == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<ServiceModel>>(
            stream: providerRepo.watchServices(widget.providerId),
            builder: (context, serviceSnapshot) {
              final services = serviceSnapshot.data ?? [];
              final total = _total(services);
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text('Select Services', style: AppTextStyles.heading3()),
                        const SizedBox(height: 8),
                        if (services.isEmpty)
                          const EmptyStateView(
                            icon: Icons.list_alt,
                            title: 'No Services Available',
                            message: 'This provider has not added any services yet.',
                          )
                        else
                          ...services.map((service) => _ServiceQuantityTile(
                                service: service,
                                quantity: _selectedQuantities[service.id] ?? 0,
                                onChanged: (qty) => setState(() => _selectedQuantities[service.id] = qty),
                              )),
                        const SizedBox(height: 20),
                        Text('Washing Method', style: AppTextStyles.heading3()),
                        const SizedBox(height: 8),
                        Wrap(spacing: 10, children: WashingMethod.values.map((m) {
                          return ChoiceChip(
                            label: Text(m.label),
                            selected: _washingMethod == m,
                            onSelected: (_) => setState(() => _washingMethod = m),
                          );
                        }).toList()),
                        const SizedBox(height: 20),
                        Text('Ironing Method', style: AppTextStyles.heading3()),
                        const SizedBox(height: 8),
                        Wrap(spacing: 10, children: IroningMethod.values.map((m) {
                          return ChoiceChip(
                            label: Text(m.label),
                            selected: _ironingMethod == m,
                            onSelected: (_) => setState(() => _ironingMethod = m),
                          );
                        }).toList()),
                        const SizedBox(height: 20),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Request Pickup'),
                          value: _pickupRequested,
                          onChanged: (v) => setState(() => _pickupRequested = v),
                        ),
                        if (_pickupRequested)
                          TextField(
                            controller: _pickupController,
                            decoration: const InputDecoration(
                              labelText: 'Pickup Location',
                              prefixIcon: Icon(Icons.my_location),
                            ),
                          ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Request Delivery'),
                          value: _deliveryRequested,
                          onChanged: (v) => setState(() => _deliveryRequested = v),
                        ),
                        if (_deliveryRequested)
                          TextField(
                            controller: _deliveryController,
                            decoration: const InputDecoration(
                              labelText: 'Delivery Location',
                              prefixIcon: Icon(Icons.flag_outlined),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Text('Preferred Date And Time', style: AppTextStyles.heading3()),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickDate,
                              child: Text(_scheduledDate == null
                                  ? 'Choose Date'
                                  : '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickTime,
                              child: Text(_scheduledTime == null
                                  ? 'Choose Time'
                                  : _scheduledTime!.format(context)),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Additional Instructions',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Payment Method', style: AppTextStyles.heading3()),
                        const SizedBox(height: 8),
                        Wrap(spacing: 10, children: PaymentMethod.values.map((m) {
                          return ChoiceChip(
                            label: Text(m.label),
                            selected: _paymentMethod == m,
                            onSelected: (_) => setState(() => _paymentMethod = m),
                          );
                        }).toList()),
                      ],
                    ),
                  ),
                  SafeArea(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        border: Border(top: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Amount', style: AppTextStyles.bodySmall()),
                              Text('KES ${total.toStringAsFixed(0)}',
                                  style: AppTextStyles.heading3(color: AppColors.primaryPink)),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 180,
                            child: PremiumButton(
                              label: 'Place Order',
                              isLoading: _isSubmitting,
                              onPressed: total > 0 ? () => _submit(provider, services) : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ServiceQuantityTile extends StatelessWidget {
  const _ServiceQuantityTile({required this.service, required this.quantity, required this.onChanged});
  final ServiceModel service;
  final double quantity;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: AppTextStyles.bodyLarge()),
                  Text('KES ${service.price.toStringAsFixed(0)} / ${service.pricingUnit}',
                      style: AppTextStyles.bodySmall(color: AppColors.primaryPink)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null,
            ),
            Text(quantity.toStringAsFixed(0), style: AppTextStyles.bodyLarge()),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryPink),
              onPressed: () => onChanged(quantity + 1),
            ),
          ],
        ),
      ),
    );
  }
}

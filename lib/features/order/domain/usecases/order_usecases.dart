import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:joyjoy/features/order/domain/order_repository.dart';

class CreateOrder implements UseCase<Order, CheckoutRequest> {
  CreateOrder(this._repository);
  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(CheckoutRequest params) =>
      _repository.createOrder(params);
}

class GetOrder implements UseCase<Order, String> {
  GetOrder(this._repository);
  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(String params) => _repository.getOrder(params);
}

class ConfirmOrder implements UseCase<Order, String> {
  ConfirmOrder(this._repository);
  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(String code) => _repository.confirmOrder(code);
}

class CancelOrder implements UseCase<Order, String> {
  CancelOrder(this._repository);
  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(String code) => _repository.cancelOrder(code);
}

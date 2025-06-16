import 'package:memora/domain/entities/account.dart';

abstract class AccountRepository {
  Future<List<Account>> getAccounts();
  Future<void> saveAccount(Account account);
  Future<void> deleteAccount(String accountId);
  Future<Account?> getAccountById(String accountId);
  Future<Account?> getAccountByEmail(String email);
}
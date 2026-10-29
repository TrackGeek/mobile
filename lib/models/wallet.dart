class Wallet {
  const Wallet({
    required this.balance,
    required this.lifetimeEarned,
    required this.lifetimeSpent,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    balance: json['balance'] as int? ?? 0,
    lifetimeEarned: json['lifetimeEarned'] as int? ?? 0,
    lifetimeSpent: json['lifetimeSpent'] as int? ?? 0,
  );

  final int balance;
  final int lifetimeEarned;
  final int lifetimeSpent;
}

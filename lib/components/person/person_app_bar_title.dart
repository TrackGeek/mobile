import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';
import '../../models/person.dart';

class PersonAppBarTitle extends StatelessWidget {
  const PersonAppBarTitle({super.key, required this.future});

  final Future<Person>? future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Person>(
      future: future,
      builder: (context, snapshot) =>
          Text(snapshot.data?.name ?? context.t('common:types.cast')),
    );
  }
}
